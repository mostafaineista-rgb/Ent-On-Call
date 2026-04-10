import 'package:flame/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';

/// Universal doctor pixel sprite animation widget.
/// Uses a single 256×256 sprite sheet (4×4 grid = 16 frames).
class ResidentPixelSprite extends StatelessWidget {
  static const String _defaultAsset = 'pixel_residents/doctors.png';

  // 256×256 sheet, 4 cols × 4 rows, 16 frames, each frame 64×64
  static const int _frameCount = 16;
  static const int _amountPerRow = 4;
  static const double _frameW = 64;
  static const double _frameH = 64;

  final String assetPath;
  final double stepTime;
  final double size;
  final double scale;
  final bool useCircleBackground;

  const ResidentPixelSprite({
    super.key,
    this.assetPath = _defaultAsset,
    this.stepTime = 0.15,
    this.size = 165,
    this.scale = 2.0,
    this.useCircleBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: useCircleBackground ? BoxShape.circle : BoxShape.rectangle,
        gradient: useCircleBackground
            ? RadialGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
                  Theme.of(context).colorScheme.surface,
                ],
              )
            : null,
      ),
      child: ClipOval(
        child: OverflowBox(
          maxWidth: size * scale,
          maxHeight: size * scale,
          child: SpriteAnimationWidget.asset(
            path: assetPath,
            data: SpriteAnimationData.sequenced(
              amount: _frameCount,
              amountPerRow: _amountPerRow,
              stepTime: stepTime,
              textureSize: Vector2(_frameW, _frameH),
            ),
            playing: true,
            anchor: Anchor.center,
          ),
        ),
      ),
    );
  }
}
