import 'package:flutter/material.dart';

/// Round brand social button (Instagram / Threads / VK), matching the site footer.
class SocialBrandButton extends StatelessWidget {
  const SocialBrandButton({
    super.key,
    required this.brand,
    required this.label,
    required this.onPressed,
  });

  final SocialBrand brand;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: brand.gradient,
              color: brand.solidColor,
              border: brand.borderColor == null
                  ? null
                  : Border.all(color: brand.borderColor!),
              boxShadow: [
                BoxShadow(
                  color: (brand.solidColor ?? brand.gradient!.colors.last)
                      .withValues(alpha: 0.28),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: CustomPaint(
                size: const Size(24, 24),
                painter: _SocialIconPainter(brand),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum SocialBrand {
  instagram,
  threads,
  vk;

  static SocialBrand? fromKey(String key) {
    switch (key.toLowerCase()) {
      case 'instagram':
        return SocialBrand.instagram;
      case 'threads':
        return SocialBrand.threads;
      case 'vk':
      case 'vkontakte':
        return SocialBrand.vk;
      default:
        return null;
    }
  }

  LinearGradient? get gradient => switch (this) {
        SocialBrand.instagram => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
            stops: [0.0, 0.45, 1.0],
          ),
        SocialBrand.threads => null,
        SocialBrand.vk => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2787F5), Color(0xFF4A9CF7)],
          ),
      };

  Color? get solidColor => switch (this) {
        SocialBrand.threads => Colors.black,
        _ => null,
      };

  Color? get borderColor => switch (this) {
        SocialBrand.threads => Colors.black,
        _ => null,
      };
}

class _SocialIconPainter extends CustomPainter {
  const _SocialIconPainter(this.brand);

  final SocialBrand brand;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    switch (brand) {
      case SocialBrand.instagram:
        _paintInstagram(canvas, size, paint);
      case SocialBrand.threads:
        _paintThreads(canvas, size, paint);
      case SocialBrand.vk:
        _paintVk(canvas, size, paint);
    }
  }

  void _paintInstagram(Canvas canvas, Size size, Paint paint) {
    final s = size.shortestSide;
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.08
      ..isAntiAlias = true;

    final outer = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.12, s * 0.12, s * 0.76, s * 0.76),
      Radius.circular(s * 0.22),
    );
    canvas.drawRRect(outer, stroke);

    canvas.drawCircle(Offset(s * 0.5, s * 0.5), s * 0.22, stroke);
    canvas.drawCircle(Offset(s * 0.72, s * 0.28), s * 0.055, paint);
  }

  void _paintThreads(Canvas canvas, Size size, Paint paint) {
    final s = size.shortestSide;
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    // Stylized Threads glyph (looped @-like mark).
    final path = Path()
      ..moveTo(s * 0.62, s * 0.30)
      ..cubicTo(s * 0.52, s * 0.22, s * 0.34, s * 0.24, s * 0.30, s * 0.40)
      ..cubicTo(s * 0.26, s * 0.58, s * 0.38, s * 0.72, s * 0.52, s * 0.72)
      ..cubicTo(s * 0.66, s * 0.72, s * 0.74, s * 0.60, s * 0.72, s * 0.46)
      ..cubicTo(s * 0.70, s * 0.34, s * 0.58, s * 0.34, s * 0.52, s * 0.40)
      ..cubicTo(s * 0.46, s * 0.46, s * 0.48, s * 0.56, s * 0.56, s * 0.56)
      ..cubicTo(s * 0.64, s * 0.56, s * 0.68, s * 0.48, s * 0.66, s * 0.42);
    canvas.drawPath(path, stroke);
  }

  void _paintVk(Canvas canvas, Size size, Paint paint) {
    final s = size.shortestSide;
    // Simplified VK wordmark bubble (readable at 24px).
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'VK',
        style: TextStyle(
          color: Colors.white,
          fontSize: s * 0.42,
          fontWeight: FontWeight.w800,
          height: 1,
          letterSpacing: -0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset((s - textPainter.width) / 2, (s - textPainter.height) / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _SocialIconPainter oldDelegate) =>
      oldDelegate.brand != brand;
}
