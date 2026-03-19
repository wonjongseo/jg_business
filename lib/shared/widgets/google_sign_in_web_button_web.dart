import 'package:flutter/material.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';

/// 웹에서는 프로그램 방식 authenticate 대신 GIS 기본 버튼을 사용한다.
class GoogleSignInWebButton extends StatelessWidget {
  const GoogleSignInWebButton({super.key});

  @override
  Widget build(BuildContext context) {
    final platform = GoogleSignInPlatform.instance;
    if (platform is! GoogleSignInPlugin) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      height: 44,
      child: platform.renderButton(
        configuration: GSIButtonConfiguration(
          theme: GSIButtonTheme.outline,
          size: GSIButtonSize.large,
          text: GSIButtonText.signupWith,
          shape: GSIButtonShape.pill,
        ),
      ),
    );
  }
}
