import 'dart:ui';
import 'package:flutter/material.dart';

class TailorLineArtPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;
  final double progress; // 0.0 to 1.0 for drawing animation

  TailorLineArtPainter({
    required this.primaryColor,
    required this.accentColor,
    this.progress = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Paint accentPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double w = size.width;
    final double h = size.height;

    // Build the full paths
    final Path hangerPath = Path();
    hangerPath.moveTo(w * 0.5, h * 0.35);
    hangerPath.cubicTo(w * 0.5, h * 0.2, w * 0.65, h * 0.2, w * 0.6, h * 0.1);
    hangerPath.cubicTo(w * 0.55, h * 0.05, w * 0.45, h * 0.05, w * 0.45, h * 0.15);
    hangerPath.cubicTo(w * 0.45, h * 0.25, w * 0.5, h * 0.3, w * 0.5, h * 0.35);
    hangerPath.lineTo(w * 0.85, h * 0.6);
    hangerPath.lineTo(w * 0.15, h * 0.6);
    hangerPath.close();

    final Path needlePath = Path();
    needlePath.moveTo(w * 0.75, h * 0.8);
    needlePath.lineTo(w * 0.9, h * 0.3);

    final Path threadPath = Path();
    threadPath.moveTo(w * 0.89, h * 0.35); // Through the eye
    threadPath.quadraticBezierTo(w * 0.95, h * 0.5, w * 0.8, h * 0.6);
    threadPath.quadraticBezierTo(w * 0.7, h * 0.7, w * 0.6, h * 0.75);
    threadPath.quadraticBezierTo(w * 0.4, h * 0.85, w * 0.3, h * 0.75);
    threadPath.quadraticBezierTo(w * 0.2, h * 0.65, w * 0.35, h * 0.6);

    // Helper to draw a partial path based on progress
    void drawPartialPath(Path path, Paint paint, double sectionProgress) {
      if (sectionProgress <= 0) return;
      if (sectionProgress >= 1.0) {
        canvas.drawPath(path, paint);
        return;
      }

      for (PathMetric pathMetric in path.computeMetrics()) {
        Path extractPath = pathMetric.extractPath(
          0.0,
          pathMetric.length * sectionProgress,
        );
        canvas.drawPath(extractPath, paint);
      }
    }

    // Sequence the animation: Hanger (0.0-0.5), Needle (0.5-0.7), Thread (0.7-1.0)
    final double hangerProgress = (progress * 2).clamp(0.0, 1.0);
    final double needleProgress = ((progress - 0.5) * 5).clamp(0.0, 1.0);
    final double threadProgress = ((progress - 0.7) * 3.33).clamp(0.0, 1.0);

    drawPartialPath(hangerPath, paint, hangerProgress);

    // Only draw needle eye if needle has started drawing
    if (needleProgress > 0) {
      // Animate needle eye opacity or draw it
      canvas.drawOval(
        Rect.fromCenter(center: Offset(w * 0.89, h * 0.35), width: w * 0.03, height: h * 0.08),
        paint..strokeWidth = 1.5,
      );
    }
    drawPartialPath(needlePath, paint, needleProgress);

    drawPartialPath(threadPath, accentPaint, threadProgress);
  }

  @override
  bool shouldRepaint(covariant TailorLineArtPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor;
  }
}
