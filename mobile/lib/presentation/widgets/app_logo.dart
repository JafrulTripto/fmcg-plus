import 'package:flutter/material.dart';

/// Pixel-perfect DokanPOS / FMCG+ App Logo from the Stitch design system.
///
/// Supports high-resolution asset loading with an automatic built-in vector
/// fallback ([AppLogoPainter]) for crisp rendering at any scale and offline reliability.
class AppLogo extends StatelessWidget {
  final double size;
  final double? borderRadius;
  final bool showShadow;
  final VoidCallback? onTap;

  const AppLogo({
    super.key,
    this.size = 40.0,
    this.borderRadius,
    this.showShadow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? (size * 0.24);

    Widget logoContent = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        'assets/images/app_logo.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Robust vector canvas fallback matching Stitch SVG specifications
          return SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: AppLogoPainter(),
              size: Size(size, size),
            ),
          );
        },
      ),
    );

    if (showShadow) {
      logoContent = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1D4ED8).withValues(alpha: 0.25),
              blurRadius: size * 0.2,
              offset: Offset(0, size * 0.08),
            ),
          ],
        ),
        child: logoContent,
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: logoContent,
      );
    }

    return logoContent;
  }
}

/// Pure vector CustomPainter replicating the DokanPOS Stitch SVG.
class AppLogoPainter extends CustomPainter {
  const AppLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final s = w / 100.0;

    // 1. Background Rounded Rect with Gradient (#1D4ED8 to #2563EB)
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final bgRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(24.0 * s),
    );
    canvas.drawRRect(bgRRect, bgPaint);

    // 2. Register Canopy / Display (#DBEAFE)
    final canopyPaint = Paint()..color = const Color(0xFFDBEAFE);
    final canopyPath = Path()
      ..moveTo(28 * s, 32 * s)
      ..arcToPoint(Offset(32 * s, 28 * s), radius: Radius.circular(4 * s))
      ..lineTo(68 * s, 28 * s)
      ..arcToPoint(Offset(72 * s, 32 * s), radius: Radius.circular(4 * s))
      ..lineTo(72 * s, 42 * s)
      ..lineTo(28 * s, 42 * s)
      ..close();
    canvas.drawPath(canopyPath, canopyPaint);

    // 3. Register White Body (#FFFFFF)
    final bodyPaint = Paint()..color = Colors.white;
    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(28 * s, 44 * s, 44 * s, 28 * s),
      Radius.circular(6 * s),
    );
    canvas.drawRRect(bodyRRect, bodyPaint);

    // 4. Register Circle Key (#1D4ED8)
    final circlePaint = Paint()..color = const Color(0xFF1D4ED8);
    canvas.drawCircle(Offset(42 * s, 58 * s), 4 * s, circlePaint);

    // 5. Register Receipt Slot (#93C5FD)
    final slotPaint = Paint()..color = const Color(0xFF93C5FD);
    final slotRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(52 * s, 55 * s, 12 * s, 6 * s),
      Radius.circular(3 * s),
    );
    canvas.drawRRect(slotRRect, slotPaint);

    // 6. Register Base Stand (#93C5FD)
    final basePaint = Paint()..color = const Color(0xFF93C5FD);
    final baseRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(22 * s, 74 * s, 56 * s, 4 * s),
      Radius.circular(2 * s),
    );
    canvas.drawRRect(baseRRect, basePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
