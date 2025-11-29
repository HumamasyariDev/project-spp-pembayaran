import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class SignUpIllustrationWidget extends StatelessWidget {
  final double width;
  final double height;

  const SignUpIllustrationWidget({
    super.key,
    this.width = 154,
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: SignUpIllustrationPainter(),
      ),
    );
  }
}

class SignUpIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Background decorative circles
    paint.color = const Color(0xFF17907C).withOpacity(0.08);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), 35, paint);
    
    paint.color = const Color(0xFF17907C).withOpacity(0.06);
    canvas.drawCircle(Offset(size.width * 0.18, size.height * 0.75), 28, paint);
    
    // Form paper/document
    final formRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.55),
        width: size.width * 0.6,
        height: size.height * 0.75,
      ),
      const Radius.circular(18),
    );
    
    // Shadow
    paint.color = const Color(0xFF17907C).withOpacity(0.12);
    canvas.drawRRect(
      formRect.shift(const Offset(0, 6)),
      paint,
    );
    
    // Form body
    paint.color = Colors.white;
    canvas.drawRRect(formRect, paint);
    
    // Form border
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.5;
    paint.color = const Color(0xFF17907C).withOpacity(0.3);
    canvas.drawRRect(formRect, paint);
    
    paint.style = PaintingStyle.fill;
    
    // User add icon circle
    final iconCenter = Offset(size.width * 0.5, size.height * 0.35);
    
    // Icon background circle
    paint.color = const Color(0xFF17907C).withOpacity(0.1);
    canvas.drawCircle(iconCenter, 30, paint);
    
    // Icon gradient circle
    final iconGradient = RadialGradient(
      colors: [
        const Color(0xFF17907C),
        const Color(0xFF17907C).withOpacity(0.85),
      ],
    );
    
    paint.shader = iconGradient.createShader(
      Rect.fromCircle(center: iconCenter, radius: 24),
    );
    canvas.drawCircle(iconCenter, 24, paint);
    paint.shader = null;
    
    // Person icon (white)
    paint.color = Colors.white;
    // Head
    canvas.drawCircle(Offset(iconCenter.dx - 4, iconCenter.dy - 3), 4.5, paint);
    
    // Body
    final personBody = Path();
    personBody.addArc(
      Rect.fromCenter(
        center: Offset(iconCenter.dx - 4, iconCenter.dy + 6),
        width: 14,
        height: 11,
      ),
      3.14,
      3.14,
    );
    canvas.drawPath(personBody, paint);
    
    // Plus sign
    paint.strokeWidth = 2.5;
    paint.style = PaintingStyle.stroke;
    paint.strokeCap = StrokeCap.round;
    
    // Horizontal line
    canvas.drawLine(
      Offset(iconCenter.dx + 6, iconCenter.dy),
      Offset(iconCenter.dx + 14, iconCenter.dy),
      paint,
    );
    
    // Vertical line
    canvas.drawLine(
      Offset(iconCenter.dx + 10, iconCenter.dy - 4),
      Offset(iconCenter.dx + 10, iconCenter.dy + 4),
      paint,
    );
    
    paint.style = PaintingStyle.fill;
    
    // Form fields
    final formCenter = Offset(size.width * 0.5, size.height * 0.58);
    
    final field1 = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(formCenter.dx, formCenter.dy),
        width: size.width * 0.45,
        height: 6,
      ),
      const Radius.circular(3),
    );
    
    final field2 = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(formCenter.dx, formCenter.dy + 10),
        width: size.width * 0.45,
        height: 6,
      ),
      const Radius.circular(3),
    );
    
    final field3 = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(formCenter.dx, formCenter.dy + 20),
        width: size.width * 0.38,
        height: 6,
      ),
      const Radius.circular(3),
    );
    
    paint.color = const Color(0xFF17907C).withOpacity(0.15);
    canvas.drawRRect(field1, paint);
    canvas.drawRRect(field2, paint);
    canvas.drawRRect(field3, paint);
    
    // Register button
    final buttonRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(formCenter.dx, formCenter.dy + 38),
        width: size.width * 0.45,
        height: 20,
      ),
      const Radius.circular(6),
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
    
    // Floating email icon (left)
    final emailCircle = Offset(size.width * 0.18, size.height * 0.28);
    paint.color = Colors.white;
    canvas.drawCircle(emailCircle, 15, paint);
    
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    paint.color = const Color(0xFF17907C);
    canvas.drawCircle(emailCircle, 15, paint);
    
    // Email icon
    paint.style = PaintingStyle.fill;
    final emailRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: emailCircle,
        width: 16,
        height: 11,
      ),
      const Radius.circular(2),
    );
    
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.5;
    canvas.drawRRect(emailRect, paint);
    
    // Email flap
    final emailFlap = Path();
    emailFlap.moveTo(emailCircle.dx - 8, emailCircle.dy - 5.5);
    emailFlap.lineTo(emailCircle.dx, emailCircle.dy);
    emailFlap.lineTo(emailCircle.dx + 8, emailCircle.dy - 5.5);
    canvas.drawPath(emailFlap, paint);
    
    // Shield/verified icon (right bottom)
    final shieldCenter = Offset(size.width * 0.82, size.height * 0.72);
    paint.style = PaintingStyle.fill;
    paint.color = Colors.white;
    canvas.drawCircle(shieldCenter, 15, paint);
    
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    paint.color = const Color(0xFF17907C);
    canvas.drawCircle(shieldCenter, 15, paint);
    
    // Shield shape
    paint.style = PaintingStyle.fill;
    final shieldPath = Path();
    shieldPath.moveTo(shieldCenter.dx, shieldCenter.dy - 7);
    shieldPath.lineTo(shieldCenter.dx - 5, shieldCenter.dy - 4);
    shieldPath.lineTo(shieldCenter.dx - 5, shieldCenter.dy + 2);
    shieldPath.quadraticBezierTo(
      shieldCenter.dx - 5,
      shieldCenter.dy + 5,
      shieldCenter.dx,
      shieldCenter.dy + 7,
    );
    shieldPath.quadraticBezierTo(
      shieldCenter.dx + 5,
      shieldCenter.dy + 5,
      shieldCenter.dx + 5,
      shieldCenter.dy + 2,
    );
    shieldPath.lineTo(shieldCenter.dx + 5, shieldCenter.dy - 4);
    shieldPath.close();
    canvas.drawPath(shieldPath, paint);
    
    // Check inside shield
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.5;
    paint.color = Colors.white;
    paint.strokeCap = StrokeCap.round;
    
    final checkPath = Path();
    checkPath.moveTo(shieldCenter.dx - 3, shieldCenter.dy);
    checkPath.lineTo(shieldCenter.dx - 1, shieldCenter.dy + 2);
    checkPath.lineTo(shieldCenter.dx + 3, shieldCenter.dy - 2);
    canvas.drawPath(checkPath, paint);
    
    // Add icon (top right small)
    final addCenter = Offset(size.width * 0.78, size.height * 0.38);
    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFF17907C).withOpacity(0.2);
    canvas.drawCircle(addCenter, 13, paint);
    
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    paint.color = const Color(0xFF17907C);
    paint.strokeCap = StrokeCap.round;
    
    // Plus
    canvas.drawLine(
      Offset(addCenter.dx - 4, addCenter.dy),
      Offset(addCenter.dx + 4, addCenter.dy),
      paint,
    );
    canvas.drawLine(
      Offset(addCenter.dx, addCenter.dy - 4),
      Offset(addCenter.dx, addCenter.dy + 4),
      paint,
    );
    
    // Decorative dots
    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFF17907C).withOpacity(0.25);
    
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.55), 3, paint);
    canvas.drawCircle(Offset(size.width * 0.08, size.height * 0.48), 2.5, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
