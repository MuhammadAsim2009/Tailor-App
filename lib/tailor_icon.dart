import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';
import 'tailor_icon_paths.dart';

class SvgPathData {
  final Path path;
  final Paint paint;

  SvgPathData(this.path, this.paint);
}

class TailorIconCache {
  static final TailorIconCache _instance = TailorIconCache._internal();
  factory TailorIconCache() => _instance;
  TailorIconCache._internal();

  List<SvgPathData>? _parsedPaths;

  List<SvgPathData> get paths {
    if (_parsedPaths == null) {
      _parsedPaths = [];
      for (var p in logoPaths) {
        Path parsedPath = parseSvgPathData(p.d);
        if (p.dx != 0 || p.dy != 0) {
          parsedPath = parsedPath.shift(Offset(p.dx, p.dy));
        }

        final Paint paint = Paint()
          ..color = p.color
          ..style = PaintingStyle.fill;
          
        _parsedPaths!.add(SvgPathData(parsedPath, paint));
      }

      // Sort paths from top-left to bottom-right so the sequential drawing looks natural
      _parsedPaths!.sort((a, b) {
        final centerA = a.path.getBounds().center;
        final centerB = b.path.getBounds().center;
        // Weight X and Y equally for a diagonal sweep
        return (centerA.dx + centerA.dy).compareTo(centerB.dx + centerB.dy);
      });
    }
    return _parsedPaths!;
  }
}

class TailorLineArtPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;
  final double progress;

  TailorLineArtPainter({
    required this.primaryColor,
    required this.accentColor,
    this.progress = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pathsData = TailorIconCache().paths;
    if (pathsData.isEmpty) return;

    Rect bounds = Rect.zero;
    for (var pd in pathsData) {
      if (bounds == Rect.zero) {
        bounds = pd.path.getBounds();
      } else {
        bounds = bounds.expandToInclude(pd.path.getBounds());
      }
    }

    final double scaleX = size.width / bounds.width;
    final double scaleY = size.height / bounds.height;
    final double scale = scaleX < scaleY ? scaleX : scaleY;

    final double offsetX = (size.width - bounds.width * scale) / 2.0 - bounds.left * scale;
    final double offsetY = (size.height - bounds.height * scale) / 2.0 - bounds.top * scale;

    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);

    // 0.0 to 0.7: Progressive outline drawing sequentially
    // 0.7 to 1.0: Fading in the fills
    double outlineProgress = (progress / 0.7).clamp(0.0, 1.0);
    double fillOpacity = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);

    // Calculate total length of all paths
    double totalLength = 0;
    List<double> pathLengths = [];
    List<List<PathMetric>> allMetrics = [];

    for (var pd in pathsData) {
      double pLength = 0;
      List<PathMetric> metrics = pd.path.computeMetrics().toList();
      for (var m in metrics) {
        pLength += m.length;
      }
      pathLengths.add(pLength);
      allMetrics.add(metrics);
      totalLength += pLength;
    }

    double currentDistance = totalLength * outlineProgress;

    for (int i = 0; i < pathsData.length; i++) {
      var pd = pathsData[i];
      var pLength = pathLengths[i];
      var metrics = allMetrics[i];

      // Draw outlines
      if (currentDistance > 0 && outlineProgress > 0) {
        if (currentDistance >= pLength) {
          // Draw fully
          Paint strokePaint = Paint()
            ..color = primaryColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5 / scale;
          canvas.drawPath(pd.path, strokePaint);
        } else {
          // Draw partially
          double remainingInPath = currentDistance;
          for (var metric in metrics) {
            if (remainingInPath <= 0) break;
            if (remainingInPath >= metric.length) {
              Path extractPath = metric.extractPath(0.0, metric.length);
              Paint strokePaint = Paint()
                ..color = primaryColor
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2.0 / scale;
              canvas.drawPath(extractPath, strokePaint);
              remainingInPath -= metric.length;
            } else {
              Path extractPath = metric.extractPath(0.0, remainingInPath);
              Paint strokePaint = Paint()
                ..color = primaryColor
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2.5 / scale; // Slightly thicker at the drawing tip
              canvas.drawPath(extractPath, strokePaint);
              remainingInPath = 0;
            }
          }
        }
      }

      currentDistance -= pLength;

      // Draw fills
      if (fillOpacity > 0.0) {
        Paint fillPaint = Paint()
          ..color = primaryColor.withValues(alpha: fillOpacity)
          ..style = PaintingStyle.fill;
        canvas.drawPath(pd.path, fillPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant TailorLineArtPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor;
  }
}
