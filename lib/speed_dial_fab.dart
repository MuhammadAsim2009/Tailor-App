import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────
//  Design System Constants
// ─────────────────────────────────────────────────────────────────
const Color _kAccent = Color(0xFF10B981); // Emerald Green
const Color _kText   = Color(0xFF0F172A); // Text Primary

// ─────────────────────────────────────────────────────────────────
//  SpeedDialOption — data model for each child button
// ─────────────────────────────────────────────────────────────────
class SpeedDialOption {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const SpeedDialOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

// ─────────────────────────────────────────────────────────────────
//  SpeedDialFAB — main reusable widget
//
//  Uses Flutter's Overlay to cover the FULL screen (body + bottom
//  nav) with a dark shade. Options are positioned diagonally upward
//  and to the left, each step moving further up & left.
//
//  Diagonal layout (bottom-right to top-left, bottom-to-top order):
//    option[0] (Add Order)    → 1 step up,  slight left
//    option[1] (Add Expense)  → 2 steps up, more left
//    option[2] (Add Customer) → 3 steps up, most left
//
//  Usage:
//    floatingActionButton: SpeedDialFAB(options: [ ... ]),
// ─────────────────────────────────────────────────────────────────
class SpeedDialFAB extends StatefulWidget {
  final List<SpeedDialOption> options;

  const SpeedDialFAB({super.key, required this.options});

  @override
  State<SpeedDialFAB> createState() => _SpeedDialFABState();
}

class _SpeedDialFABState extends State<SpeedDialFAB>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotationAnim; // + → ×
  late final Animation<double> _overlayAnim;  // dark shade opacity
  late final List<Animation<Offset>> _slideAnims;
  late final List<Animation<double>>  _fadeAnims;

  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    // FAB icon rotates 45° (0.125 turns)
    _rotationAnim = Tween<double>(begin: 0, end: 0.125).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    // Dark overlay fades from 0 → 60% opacity
    _overlayAnim = Tween<double>(begin: 0, end: 0.6).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Staggered slide + fade per option
    // Each option slides from slightly below-right to its final position
    _slideAnims = [];
    _fadeAnims  = [];
    for (int i = 0; i < widget.options.length; i++) {
      final start = 0.1 + i * 0.15;
      final end   = (start + 0.45).clamp(0.0, 1.0);

      // Diagonal slide: come from bottom-right (0.6, 0.6) to zero
      _slideAnims.add(
        Tween<Offset>(begin: const Offset(0.5, 0.8), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(start, end, curve: Curves.easeOutBack),
          ),
        ),
      );

      _fadeAnims.add(
        Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggle() {
    if (_isOpen) {
      _controller.reverse().then((_) {
        _removeOverlay();
        if (mounted) setState(() => _isOpen = false);
      });
    } else {
      setState(() => _isOpen = true);
      _insertOverlay();
      _controller.forward();
    }
  }

  void _close() {
    if (_isOpen) _toggle();
  }

  void _insertOverlay() {
    final renderBox = context.findRenderObject()! as RenderBox;
    final fabSize   = renderBox.size;
    final fabGlobal = renderBox.localToGlobal(Offset.zero);
    final screen    = MediaQuery.of(context).size;

    // Distance of FAB from the right/bottom edges of the screen
    final fabRight  = screen.width  - fabGlobal.dx - fabSize.width;
    final fabBottom = screen.height - fabGlobal.dy - fabSize.height;

    // Diagonal step offsets: each option moves up AND further left
    // Step values: (verticalStepPx, horizontalStepPx) per index
    // index 0 = lowest (Add Order), index 2 = highest (Add Customer)
    const double vertStep  = 72.0;   // px up per option
    const double horizStep = 20.0;   // px further right-edge per option (moves label left)

    _overlayEntry = OverlayEntry(
      builder: (overlayCtx) => Material(
        // Transparent Material fixes yellow debug underlines on Text
        type: MaterialType.transparency,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (overlayCtx, child) {
            return Stack(
              children: [
                // ── 1. Full-screen dark backdrop ──
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _close,
                    child: Container(
                      color: Colors.black.withValues(alpha: _overlayAnim.value),
                    ),
                  ),
                ),

                // ── 2. Option buttons positioned diagonally ──
                ...List.generate(widget.options.length, (i) {
                  final opt        = widget.options[i];
                  // i=0 is bottom (Add Order), i=N-1 is top (Add Customer)
                  final bottomPos  = fabBottom + (i + 1) * vertStep;
                  // Each higher option shifts slightly more to the right edge
                  // which pushes the label further left visually
                  final rightPos   = fabRight + i * horizStep;

                  return Positioned(
                    right:  rightPos,
                    bottom: bottomPos,
                    child: FadeTransition(
                      opacity: _fadeAnims[i],
                      child: SlideTransition(
                        position: _slideAnims[i],
                        child: _DialOptionButton(
                          option: opt,
                          onTap: () {
                            _close();
                            opt.onTap();
                          },
                        ),
                      ),
                    ),
                  );
                }),

                // ── 3. FAB clone rendered on top of the dark shade ──
                //    The real Scaffold FAB turns invisible (Opacity 0)
                //    so only this copy is visible.
                Positioned(
                  right:  fabRight,
                  bottom: fabBottom,
                  child: RotationTransition(
                    turns: _rotationAnim,
                    child: FloatingActionButton(
                      heroTag: 'speed_dial_overlay_fab',
                      onPressed: _toggle,
                      backgroundColor: _kAccent,
                      elevation: 6,
                      child: const Icon(Icons.add, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    // Hide the real FAB while overlay is active; the overlay shows its clone.
    return Opacity(
      opacity: _isOpen ? 0.0 : 1.0,
      child: RotationTransition(
        turns: _rotationAnim,
        child: FloatingActionButton(
          heroTag: 'speed_dial_main_fab',
          onPressed: _toggle,
          backgroundColor: _kAccent,
          elevation: 4,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  _DialOptionButton — mini circular FAB + label pill on the left
// ─────────────────────────────────────────────────────────────────
class _DialOptionButton extends StatelessWidget {
  final SpeedDialOption option;
  final VoidCallback onTap;

  const _DialOptionButton({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label pill (left side)
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _kText.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              option.label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Mini circular FAB (right side)
        FloatingActionButton.small(
          heroTag: 'speed_dial_${option.label}',
          onPressed: onTap,
          backgroundColor: _kAccent,
          elevation: 3,
          child: Icon(option.icon, color: Colors.white, size: 20),
        ),
      ],
    );
  }
}
