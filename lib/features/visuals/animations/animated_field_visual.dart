import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedFieldVisual extends StatefulWidget {
  final String visualId;
  final String recommendationStatus;
  final bool isRaining;

  const AnimatedFieldVisual({
    super.key,
    required this.visualId,
    required this.recommendationStatus,
    this.isRaining = false,
  });

  @override
  State<AnimatedFieldVisual> createState() => _AnimatedFieldVisualState();
}

class _AnimatedFieldVisualState extends State<AnimatedFieldVisual> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox.expand(
          child: CustomPaint(
            painter: _PixelFarmPainter(
              animationValue: _controller.value,
              recommendationStatus: widget.recommendationStatus,
              isRaining: widget.isRaining,
            ),
          ),
        );
      },
    );
  }
}

class _PixelFarmPainter extends CustomPainter {
  final double animationValue;
  final String recommendationStatus;
  final bool isRaining;

  _PixelFarmPainter({
    required this.animationValue,
    required this.recommendationStatus,
    required this.isRaining,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // --- Layer 1: Sky (top 45%) ---
    final skyHeight = size.height * 0.45;
    final skyRect = Rect.fromLTWH(0, 0, size.width, skyHeight);
    final skyGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF1A1A2E), Color(0xFFFFB347)],
    ).createShader(skyRect);
    canvas.drawRect(skyRect, Paint()..shader = skyGradient);

    // Sun
    if (!isRaining) {
      final sunX = animationValue * size.width;
      final sunY = skyHeight * 0.4;
      _drawSun(canvas, Offset(sunX, sunY));
    }

    // Clouds
    final cloudColor = isRaining ? const Color(0xFF555566) : const Color(0xFFEEEEEE);
    // Cloud 1
    final cloud1X = (animationValue * 1.5 % 1.0) * size.width;
    _drawCloud(canvas, Offset(cloud1X, skyHeight * 0.2), cloudColor);
    // Cloud 2
    final cloud2X = (animationValue * 0.8 % 1.0) * size.width;
    _drawCloud(canvas, Offset(cloud2X, skyHeight * 0.5), cloudColor);

    if (isRaining) {
      // Multiply to 4 clouds
      final cloud3X = (animationValue * 1.2 % 1.0) * size.width;
      _drawCloud(canvas, Offset(cloud3X, skyHeight * 0.35), cloudColor);
      final cloud4X = (animationValue * 1.8 % 1.0) * size.width;
      _drawCloud(canvas, Offset(cloud4X, skyHeight * 0.6), cloudColor);
    }

    // Birds (Layer 4 parts in sky)
    if (!isRaining) {
      final bird1X = (animationValue * 3.0 % 1.0) * size.width;
      final bird1Y = skyHeight * 0.3 + sin(animationValue * 2 * pi * (60 / 1.8)) * 10;
      _drawBird(canvas, Offset(bird1X, bird1Y));

      final bird2X = ((animationValue * 2.5 % 1.0) * size.width + size.width / 2) % size.width;
      final bird2Y = skyHeight * 0.5 + sin(animationValue * 2 * pi * (60 / 1.8) + pi) * 15;
      _drawBird(canvas, Offset(bird2X, bird2Y));
    }

    // --- Layer 2: Ground (bottom 55%) ---
    final groundTop = size.height * 0.45;
    final soilHeight = size.height * 0.18;
    final soilTop = size.height - soilHeight;

    // Background Ground between sky and soil (optional, but needed to fill gap)
    canvas.drawRect(Rect.fromLTWH(0, groundTop, size.width, size.height - groundTop), Paint()..color = const Color(0xFF8D6E63));

    // Soil Band
    _drawSoilBand(canvas, Rect.fromLTWH(0, soilTop, size.width, soilHeight));

    // Grass Band
    canvas.drawRect(Rect.fromLTWH(0, soilTop - 3, size.width, 3), Paint()..color = const Color(0xFF4CAF50));

    // Crop Rows
    final stalksCount = 8;
    final spacing = size.width / (stalksCount + 1);
    for (int i = 0; i < stalksCount; i++) {
      final baseX = spacing * (i + 1);
      final phaseOffset = i * 0.4;
      final sway = sin(animationValue * 2 * pi * 24 + phaseOffset) * 4;
      _drawCropStalk(canvas, Offset(baseX, soilTop - 3), sway, recommendationStatus);
    }

    // Insects
    if (!isRaining) {
      for (int i = 0; i < 3; i++) {
        final insectBaseX = size.width * 0.2 + (i * size.width * 0.3);
        final phaseOffset = i * 2.0;
        final insectY = soilTop - 30;
        final flutter = sin(animationValue * 2 * pi * 150 + phaseOffset) * 3;
        _drawInsect(canvas, Offset(insectBaseX + flutter, insectY + flutter), i);
      }
    }

    // --- Layer 3: Rain ---
    if (isRaining) {
      final rainPaint = Paint()
        ..color = const Color(0xFF90CAF9).withOpacity(0.2)
        ..strokeWidth = 2;
      for (int i = 0; i < 40; i++) {
        final startX = (i * size.width / 40 + (i % 5) * 15) % size.width;
        final startYOffset = (i * size.height / 40);
        final dropY = ((animationValue * 50) * size.height + startYOffset) % size.height;
        final dropX = startX + dropY * 0.05; // slight rightward lean
        canvas.drawLine(Offset(dropX, dropY), Offset(dropX + 2, dropY + 8), rainPaint);
      }
    }
  }

  void _drawSun(Canvas canvas, Offset center) {
    final paint = Paint()..color = const Color(0xFFFFD700);
    // 5x5 grid of 8px squares -> 40x40 total roughly
    final mask = [
      [0, 1, 1, 1, 0],
      [1, 1, 1, 1, 1],
      [1, 1, 1, 1, 1],
      [1, 1, 1, 1, 1],
      [0, 1, 1, 1, 0],
    ];
    for (int r = 0; r < 5; r++) {
      for (int c = 0; c < 5; c++) {
        if (mask[r][c] == 1) {
          canvas.drawRect(Rect.fromLTWH(center.dx + (c - 2) * 8, center.dy + (r - 2) * 8, 8, 8), paint);
        }
      }
    }
  }

  void _drawCloud(Canvas canvas, Offset pos, Color color) {
    final paint = Paint()..color = color;
    // Irregular cluster of 6x4 pixel blocks
    // Wait, the prompt says "irregular cluster of 6x4 pixel blocks in white/light grey"
    // Does it mean 6 blocks wide, 4 blocks high? Let's use 6x6 pixel blocks.
    final mask = [
      [0, 1, 1, 0],
      [1, 1, 1, 1],
      [1, 1, 1, 1],
      [0, 1, 1, 0],
    ];
    // We'll draw 6x4 rects, wait, let's use 8px squares for visibility
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (mask[r][c] == 1) {
          // Add some offsets to make it look like 6x4 irregular shapes
          canvas.drawRect(Rect.fromLTWH(pos.dx + c * 10 - r * 2, pos.dy + r * 6, 12, 8), paint);
        }
      }
    }
  }

  void _drawBird(Canvas canvas, Offset pos) {
    final paint = Paint()..color = const Color(0xFF333344);
    // 5px wide V-shape, 2 pixel blocks per wing
    canvas.drawRect(Rect.fromLTWH(pos.dx, pos.dy, 2, 2), paint);
    canvas.drawRect(Rect.fromLTWH(pos.dx + 4, pos.dy, 2, 2), paint);
    canvas.drawRect(Rect.fromLTWH(pos.dx + 2, pos.dy + 2, 2, 2), paint);
  }

  void _drawSoilBand(Canvas canvas, Rect bounds) {
    final color1 = Paint()..color = const Color(0xFF6B4226);
    final color2 = Paint()..color = const Color(0xFF7D4F2A);
    final rows = (bounds.height / 4).ceil();
    for (int i = 0; i < rows; i++) {
      canvas.drawRect(
        Rect.fromLTWH(bounds.left, bounds.top + i * 4, bounds.width, 4),
        i % 2 == 0 ? color1 : color2,
      );
    }
  }

  void _drawCropStalk(Canvas canvas, Offset bottomCenter, double sway, String status) {
    // Stem: 3px wide, 24px tall
    final stemPaint = Paint()..color = const Color(0xFF654321);
    final segments = 4;
    final segHeight = 24 / segments;

    for (int i = 0; i < segments; i++) {
      final move = sway * (i / (segments - 1));
      canvas.drawRect(
        Rect.fromLTWH(bottomCenter.dx + move - 1.5, bottomCenter.dy - (i + 1) * segHeight, 3, segHeight + 0.5),
        stemPaint,
      );
    }

    Color mainLeaf, tipLeaf;
    if (status == 'GOOD') {
      mainLeaf = const Color(0xFF56AB2F);
      tipLeaf = const Color(0xFFA8E063);
    } else if (status == 'IRRIGATE') {
      mainLeaf = const Color(0xFFB5C918);
      tipLeaf = const Color(0xFF8B7355);
    } else { // WAIT
      mainLeaf = const Color(0xFF388E3C);
      tipLeaf = const Color(0xFF388E3C);
    }

    final topX = bottomCenter.dx + sway;
    final topY = bottomCenter.dy - 24;

    canvas.drawRect(Rect.fromLTWH(topX - 6, topY - 3, 5, 5), Paint()..color = mainLeaf);
    canvas.drawRect(Rect.fromLTWH(topX + 1, topY - 3, 5, 5), Paint()..color = tipLeaf);
    canvas.drawRect(Rect.fromLTWH(topX - 2.5, topY - 8, 5, 5), Paint()..color = mainLeaf);
  }

  void _drawInsect(Canvas canvas, Offset pos, int index) {
    Color c1, c2;
    if (index % 3 == 0) {
      c1 = const Color(0xFFFFD54F);
      c2 = const Color(0xFFFF8A65);
    } else if (index % 3 == 1) {
      c1 = const Color(0xFF80DEEA);
      c2 = const Color(0xFFFFD54F);
    } else {
      c1 = const Color(0xFFFF8A65);
      c2 = const Color(0xFF80DEEA);
    }
    
    final p1 = Paint()..color = c1;
    final p2 = Paint()..color = c2;
    
    canvas.drawRect(Rect.fromLTWH(pos.dx, pos.dy, 2, 2), p1);
    canvas.drawRect(Rect.fromLTWH(pos.dx + 2, pos.dy + 2, 2, 2), p1);
    canvas.drawRect(Rect.fromLTWH(pos.dx + 2, pos.dy, 2, 2), p2);
    canvas.drawRect(Rect.fromLTWH(pos.dx, pos.dy + 2, 2, 2), p2);
  }

  @override
  bool shouldRepaint(covariant _PixelFarmPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.recommendationStatus != recommendationStatus ||
           oldDelegate.isRaining != isRaining;
  }
}
