import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BarberLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const BarberLogo({super.key, required this.size, this.showText = false});

  @override
  Widget build(BuildContext context) {
    final double lettersSize = size * 0.55;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. The Gold Circular Ring with gap
              Positioned.fill(child: CustomPaint(painter: _LogoRingPainter())),

              // 2. Overlapping "S" and "O" in center
              Positioned(
                child: SizedBox(
                  width: size * 0.8,
                  height: size * 0.8,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Letter S (Slightly left and top)
                      Positioned(
                        left: size * 0.12,
                        top: size * 0.08,
                        child: ShaderMask(
                          shaderCallback: (bounds) =>
                              AppTheme.goldGradient.createShader(
                                Rect.fromLTWH(
                                  0,
                                  0,
                                  bounds.width,
                                  bounds.height,
                                ),
                              ),
                          child: Text(
                            'S',
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: lettersSize,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                      // Letter O (Slightly right and bottom, overlapping S)
                      Positioned(
                        right: size * 0.12,
                        bottom: size * 0.08,
                        child: ShaderMask(
                          shaderCallback: (bounds) =>
                              AppTheme.goldGradient.createShader(
                                Rect.fromLTWH(
                                  0,
                                  0,
                                  bounds.width,
                                  bounds.height,
                                ),
                              ),
                          child: Text(
                            'O',
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: lettersSize,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Scissor Icon at the gap (bottom-right)
              Positioned(
                right: size * 0.08,
                bottom: size * 0.15,
                child: Transform.rotate(
                  angle: -math.pi / 6,
                  child: ShaderMask(
                    shaderCallback: (bounds) =>
                        AppTheme.goldGradient.createShader(
                          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                        ),
                    child: Icon(
                      Icons.content_cut, // Scissors icon
                      size: size * 0.22,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // 4. Sparkle Star at bottom-right
              Positioned(
                right: size * 0.02,
                bottom: size * 0.35,
                child: ShaderMask(
                  shaderCallback: (bounds) =>
                      AppTheme.goldGradient.createShader(
                        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                      ),
                  child: Icon(
                    Icons.auto_awesome, // Sparkle / Star icon
                    size: size * 0.1,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 16),
          ShaderMask(
            shaderCallback: (bounds) => AppTheme.goldGradient.createShader(
              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
            ),
            child: const Text(
              'YILMAZ',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 6.0,
                color: Colors.white,
              ),
            ),
          ),
          const Text(
            'HAIR BARBER',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 4.0,
              color: AppTheme.goldMedium,
            ),
          ),
        ],
      ],
    );
  }
}

class _LogoRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = size.width * 0.04;
    final Rect rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: (size.width - strokeWidth) / 2,
    );

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Create a gold/black gradient shader for the ring
    paint.shader = AppTheme.goldGradient.createShader(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );

    // Draw the circle with a gap on the bottom right (from 15 degrees to 80 degrees)
    // 0 rad is at 3 o'clock. We want gap from approx 15 to 80 deg.
    // In radians:
    // startAngle = 80 deg in rad = 80 * pi / 180 = 1.396 rad
    // sweepAngle = 295 deg in rad = 295 * pi / 180 = 5.148 rad (leaves 65 deg gap)
    const double startAngle = 80 * math.pi / 180;
    const double sweepAngle = 295 * math.pi / 180;

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
