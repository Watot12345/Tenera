import 'package:flutter/material.dart';

class RoofLedgerLogo extends StatelessWidget {
  final double size;
  final bool isLight;
  final double progress;

  const RoofLedgerLogo({
    super.key,
    this.size = 120,
    this.isLight = true,
    this.progress = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RoofLedgerPainter(
          isLight: isLight,
          progress: progress.clamp(0.0, 1.0),
        ),
      ),
    );
  }
}

class _RoofLedgerPainter extends CustomPainter {
  final bool isLight;
  final double progress;

  _RoofLedgerPainter({
    required this.isLight,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    const double baseSize = 270.0;
    final double scale = size.width / baseSize;

    final primaryColor = isLight ? Colors.white : const Color(0xFF0E6B63);
    const accentColor = Color(0xFFF2A33A);

    final linePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 27.0 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final accentPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 27.0 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    Offset tf(double x, double y) => Offset(x * scale, y * scale);

    // 1. Roof chevron builds symmetrically from the ridge peak downward (0.0 -> 0.40)
    final double tRoof = (progress / 0.40).clamp(0.0, 1.0);
    if (tRoof > 0.02) {
      final pPeak = tf(134.5, 17.0);
      final pLeftTarget = tf(17.0, 106.0);
      final pRightTarget = tf(252.0, 106.0);

      final curLeft = Offset.lerp(pPeak, pLeftTarget, tRoof)!;
      final curRight = Offset.lerp(pPeak, pRightTarget, tRoof)!;

      final path = Path()
        ..moveTo(curLeft.dx, curLeft.dy)
        ..lineTo(pPeak.dx, pPeak.dy)
        ..lineTo(curRight.dx, curRight.dy);
      canvas.drawPath(path, linePaint);
    }

    // 2. Top ledger bar builds left to right (0.35 -> 0.60)
    final double tBar1 = ((progress - 0.35) / 0.25).clamp(0.0, 1.0);
    if (tBar1 > 0.02) {
      final start = tf(51.0, 160.0);
      final endTarget = tf(218.0, 160.0);
      final curEnd = Offset.lerp(start, endTarget, tBar1)!;
      canvas.drawLine(start, curEnd, linePaint);
    }

    // 3. Middle ledger bar builds left to right (0.55 -> 0.80)
    final double tBar2 = ((progress - 0.55) / 0.25).clamp(0.0, 1.0);
    if (tBar2 > 0.02) {
      final start = tf(51.0, 207.0);
      final endTarget = tf(218.0, 207.0);
      final curEnd = Offset.lerp(start, endTarget, tBar2)!;
      canvas.drawLine(start, curEnd, linePaint);
    }

    // 4. Bottom amber accent bar builds left to right (0.75 -> 1.00)
    final double tBar3 = ((progress - 0.75) / 0.25).clamp(0.0, 1.0);
    if (tBar3 > 0.02) {
      final start = tf(51.0, 254.0);
      final endTarget = tf(143.0, 254.0);
      final curEnd = Offset.lerp(start, endTarget, tBar3)!;
      canvas.drawLine(start, curEnd, accentPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RoofLedgerPainter oldDelegate) {
    return oldDelegate.isLight != isLight || oldDelegate.progress != progress;
  }
}
