import 'package:flutter/material.dart';

/// 웹이 아닌 플랫폼에서는 아무것도 렌더링하지 않는다.
class GoogleSignInWebButton extends StatelessWidget {
  const GoogleSignInWebButton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
