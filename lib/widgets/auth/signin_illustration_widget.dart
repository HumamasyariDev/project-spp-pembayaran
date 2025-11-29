import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class SignInIllustrationWidget extends StatelessWidget {
  final double width;
  final double height;

  const SignInIllustrationWidget({
    super.key,
    this.width = 229,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: SignInIllustrationPainter(),
      ),
    );
  }
}

class SignInIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Background circle decoration
    paint.color = const Color(0xFF17907C).withOpacity(0.08);
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.25), 50, paint);
    
    paint.color = const Color(0xFF17907C).withOpacity(0.06);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.7), 35, paint);
    
    // Mobile phone frame
    final phoneRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.55),
        width: size.width * 0.55,
        height: size.height * 0.75,
      ),
      const Radius.circular(25),
    );
    
    // Phone shadow
    paint.color = const Color(0xFF17907C).withOpacity(0.15);
    canvas.drawRRect(
      phoneRect.shift(const Offset(0, 8)),
      paint,
    );
    
    // Phone body
    paint.color = Colors.white;
    canvas.drawRRect(phoneRect, paint);
    
    // Phone border
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;
    paint.color = const Color(0xFF17907C).withOpacity(0.3);
    canvas.drawRRect(phoneRect, paint);
    
    paint.style = PaintingStyle.fill;
    
    // Screen content area
    final screenCenter = Offset(size.width * 0.5, size.height * 0.58);
    
    // Lock circle background
    paint.color = const Color(0xFF17907C).withOpacity(0.1);
    canvas.drawCircle(
      Offset(screenCenter.dx, screenCenter.dy - 30),
      35,
      paint,
    );
    
    // Lock icon circle
    final lockGradient = RadialGradient(
      colors: [
        const Color(0xFF17907C),
        const Color(0xFF17907C).withOpacity(0.8),
      ],
    );
    
    paint.shader = lockGradient.createShader(
      Rect.fromCircle(
        center: Offset(screenCenter.dx, screenCenter.dy - 30),
        radius: 28,
      ),
    );
    canvas.drawCircle(
      Offset(screenCenter.dx, screenCenter.dy - 30),
      28,
      paint,
    );
    paint.shader = null;
    
    // Lock icon
    paint.color = Colors.white;
    paint.strokeWidth = 2.5;
    paint.style = PaintingStyle.stroke;
    
    // Lock body
    final lockBodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(screenCenter.dx, screenCenter.dy - 25),
        width: 20,
        height: 15,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(lockBodyRect, paint);
    
    // Lock shackle
    final lockPath = Path();
    lockPath.addArc(
      Rect.fromCenter(
        center: Offset(screenCenter.dx, screenCenter.dy - 35),
        width: 14,
        height: 14,
      ),
      3.14,
      3.14,
    );
    canvas.drawPath(lockPath, paint);
    
    paint.style = PaintingStyle.fill;
    
    // Form fields
    final field1 = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(screenCenter.dx, screenCenter.dy + 15),
        width: size.width * 0.35,
        height: 8,
      ),
      const Radius.circular(4),
    );
    
    final field2 = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(screenCenter.dx, screenCenter.dy + 28),
        width: size.width * 0.3,
        height: 8,
      ),
      const Radius.circular(4),
    );
    
    paint.color = const Color(0xFF17907C).withOpacity(0.15);
    canvas.drawRRect(field1, paint);
    canvas.drawRRect(field2, paint);
    
    // Login button
    final buttonRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(screenCenter.dx, screenCenter.dy + 50),
        width: size.width * 0.35,
        height: 25,
      ),
      const Radius.circular(8),
    );
    
    final buttonGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF17907C),
        const Color(0xFF17907C).withOpacity(0.85),
      ],
    );
    
    paint.shader = buttonGradient.createShader(buttonRect.outerRect);
    canvas.drawRRect(buttonRect, paint);
    paint.shader = null;
    
    // Floating person icon (left)
    final personCircle = Offset(size.width * 0.22, size.height * 0.25);
    paint.color = Colors.white;
    canvas.drawCircle(personCircle, 18, paint);
    
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    paint.color = const Color(0xFF17907C);
    canvas.drawCircle(personCircle, 18, paint);
    
    // Person icon
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(personCircle.dx, personCircle.dy - 3), 5, paint);
    
    final personBody = Path();
    personBody.addArc(
      Rect.fromCenter(
        center: Offset(personCircle.dx, personCircle.dy + 8),
        width: 16,
        height: 12,
      ),
      3.14,
      3.14,
    );
    canvas.drawPath(personBody, paint);
    
    // Check icon (right bottom)
    final checkCircle = Offset(size.width * 0.78, size.height * 0.75);
    paint.style = PaintingStyle.fill;
    paint.color = Colors.white;
    canvas.drawCircle(checkCircle, 16, paint);
    
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    paint.color = const Color(0xFF17907C);
    canvas.drawCircle(checkCircle, 16, paint);
    
    // Check mark
    paint.strokeWidth = 2.5;
    paint.style = PaintingStyle.stroke;
    paint.strokeCap = StrokeCap.round;
    
    final checkPath = Path();
    checkPath.moveTo(checkCircle.dx - 5, checkCircle.dy);
    checkPath.lineTo(checkCircle.dx - 2, checkCircle.dy + 4);
    checkPath.lineTo(checkCircle.dx + 5, checkCircle.dy - 4);
    canvas.drawPath(checkPath, paint);
    
    // Decorative dots
    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFF17907C).withOpacity(0.3);
    
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.5), 3, paint);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.45), 4, paint);
    canvas.drawCircle(Offset(size.width * 0.12, size.height * 0.85), 3.5, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
