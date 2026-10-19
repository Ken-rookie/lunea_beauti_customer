import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    required this.onGetStarted,
    required this.onLogin,
    super.key,
  });

  final VoidCallback onGetStarted;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: LayoutBuilder(
      builder: (context, constraints) {
        const imageWidth = 768.0;
        const imageHeight = 1364.0;
        final widthScale = constraints.maxWidth / imageWidth;
        final heightScale = constraints.maxHeight / imageHeight;
        final imageScale = widthScale < heightScale ? widthScale : heightScale;
        final imageLeft = (constraints.maxWidth - imageWidth * imageScale) / 2;
        final imageTop = (constraints.maxHeight - imageHeight * imageScale) / 2;

        Rect imageRegion(double left, double top, double right, double bottom) {
          return Rect.fromLTRB(
            imageLeft + left * imageScale,
            imageTop + top * imageScale,
            imageLeft + right * imageScale,
            imageTop + bottom * imageScale,
          );
        }

        return ColoredBox(
          color: AppColors.palePink,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/welcome_reference.png', fit: BoxFit.contain),
              Positioned.fromRect(
                rect: imageRegion(120, 1080, 648, 1180),
                child: _ArtworkTapTarget(
                  label: 'Get Started',
                  onPressed: onGetStarted,
                ),
              ),
              Positioned.fromRect(
                rect: imageRegion(170, 1190, 598, 1265),
                child: _ArtworkTapTarget(
                  label: 'Already have an account? Log In',
                  onPressed: onLogin,
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _ArtworkTapTarget extends StatelessWidget {
  const _ArtworkTapTarget({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: const SizedBox.expand(),
    ),
  );
}
