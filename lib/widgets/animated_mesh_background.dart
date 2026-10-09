import 'dart:math' as math;
import 'package:flutter/material.dart';

/// پس‌زمینه قرآنی و کم‌هزینه: گرادیان ثابت + نقش هندسی تذهیب.
/// عمداً از blur، ذرات متعدد و چندین لایه متحرک استفاده نمی‌کند تا مصرف GPU پایین بماند.
class AnimatedMeshBackground extends StatefulWidget {
  final Color primary;
  final Color secondary;
  final Widget? child;
  final bool showParticles;
  final bool enabled;

  const AnimatedMeshBackground({
    super.key,
    required this.primary,
    required this.secondary,
    this.child,
    this.showParticles = false,
    this.enabled = true,
  });

  @override
  State<AnimatedMeshBackground> createState() => _AnimatedMeshBackgroundState();
}

class _AnimatedMeshBackgroundState extends State<AnimatedMeshBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
      value: 0.5,
    );
    if (widget.enabled) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant AnimatedMeshBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deep = Color.lerp(widget.primary, const Color(0xFF03140F), 0.68)!;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [deep, widget.primary, Color.lerp(widget.primary, widget.secondary, 0.16)!],
            ),
          ),
        ),
        // نقوش ثابتة؛ فقط مقدار شفافیت به‌آرامی تغییر می‌کند.
        if (widget.enabled)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => IgnorePointer(
              child: CustomPaint(
                painter: _IslamicPatternPainter(
                  color: widget.secondary.withOpacity(0.045 + _controller.value * 0.025),
                ),
                size: Size.infinite,
              ),
            ),
          )
        else
          IgnorePointer(
            child: CustomPaint(
              painter: _IslamicPatternPainter(color: widget.secondary.withOpacity(0.055)),
              size: Size.infinite,
            ),
          ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _IslamicPatternPainter extends CustomPainter {
  final Color color;
  const _IslamicPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const spacing = 76.0;
    for (double y = -spacing; y < size.height + spacing; y += spacing) {
      for (double x = -spacing; x < size.width + spacing; x += spacing) {
        final path = Path();
        const radius = 20.0;
        for (int i = 0; i < 16; i++) {
          final angle = (i * math.pi / 8) - math.pi / 2;
          final r = i.isEven ? radius : radius * 0.62;
          final point = Offset(x + math.cos(angle) * r, y + math.sin(angle) * r);
          if (i == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
        canvas.drawCircle(Offset(x, y), 7, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _IslamicPatternPainter oldDelegate) => oldDelegate.color != color;
}
