import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';

class SocialLoginButtons extends StatelessWidget {
  final VoidCallback? onGoogle;
  final VoidCallback? onApple;
  const SocialLoginButtons({this.onGoogle, this.onApple, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SignInButton(
          Buttons.Google,
          onPressed: onGoogle ?? () {},
          text: 'Sign in with Google',
        ),
        const SizedBox(height: 12),
        SignInButton(
          Buttons.Apple,
          onPressed: onApple ?? () {},
          text: 'Sign in with Apple',
        ),
      ],
    );
  }
}
