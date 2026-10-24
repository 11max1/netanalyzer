import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_state.dart';

class Logo extends StatelessWidget {
  final double size;
  const Logo({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(
          colors: [kBlue, kCyan],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CustomPaint(painter: LogoPainter()),
    );
  }
}

class LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.08;
    final center = Offset(size.width / 2, size.height * 0.72);
    for (final r in [0.18, 0.32, 0.46]) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: size.width * r),
        -pi * 0.85,
        pi * 0.7,
        false,
        p,
      );
    }
    canvas.drawCircle(center, size.width * 0.06, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class Brand extends StatelessWidget {
  const Brand({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Logo(size: 36),
        const SizedBox(width: 10),
        Text(
          'Abbas Abod',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 20),
        ),
      ],
    );
  }
}
