import 'package:flutter/material.dart';

class JellyfishTheme {
  static const Color bg = Color(0xFF0F172A);
  static const Color panel = Color(0xFF1E293B);
  static const Color panelSoft = Color(0xFF334155);
  static const Color primary = Color(0xFF6366F1);
  static const Color accent = Color(0xFFEC4899);
  static const Color textMuted = Color(0xFF94A3B8);

  static ThemeData darkTheme() {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: bg,
      cardColor: panel,
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: panel,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bg,
        labelStyle: const TextStyle(color: textMuted),
        hintStyle: const TextStyle(color: textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: primary),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: panel,
        contentTextStyle: TextStyle(color: Colors.white),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: panelSoft,
        selectedColor: primary.withValues(alpha: 0.25),
        side: BorderSide.none,
        labelStyle: const TextStyle(color: Colors.white),
      ),
      dividerColor: Colors.white12,
    );
  }
}

class JellyfishBackground extends StatelessWidget {
  const JellyfishBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF111827)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: CustomPaint(painter: JellyfishBackgroundPainter()),
          ),
        ),
        child,
      ],
    );
  }
}

class JellyfishBackgroundPainter extends CustomPainter {
  const JellyfishBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.shader = RadialGradient(
      colors: [
        const Color(0xFF6366F1).withValues(alpha: 0.15),
        Colors.transparent,
      ],
    ).createShader(
      Rect.fromCircle(
        center: Offset(size.width * 0.2, size.height * 0.3),
        radius: size.width * 0.4,
      ),
    );
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.3),
      size.width * 0.4,
      paint,
    );

    paint.shader = RadialGradient(
      colors: [
        const Color(0xFFEC4899).withValues(alpha: 0.1),
        Colors.transparent,
      ],
    ).createShader(
      Rect.fromCircle(
        center: Offset(size.width * 0.8, size.height * 0.7),
        radius: size.width * 0.4,
      ),
    );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.7),
      size.width * 0.4,
      paint,
    );

    paint.shader = RadialGradient(
      colors: [
        const Color(0xFFF59E0B).withValues(alpha: 0.08),
        Colors.transparent,
      ],
    ).createShader(
      Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.5),
        radius: size.width * 0.5,
      ),
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.5,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
