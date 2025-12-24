import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'social_login_buttons.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
    void _sendOtp() {
      setState(() {
        _sent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP sent (use 123456)')));
      for (final c in _otpControllers) {
        c.clear();
      }
      _otpFocus.first.requestFocus();
    }

    // Removed unused _otpField method
  final _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocus = List.generate(6, (_) => FocusNode());
  bool _sent = false;
  bool _verifying = false;
  final int _secondsLeft = 0;
  Timer? _timer;

  @override
  void dispose() {
    _phoneController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocus) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  // Removed duplicate/old unreachable code after build method

  void _resend() {
    if (_secondsLeft > 0) return;
    _sendOtp();
  }

  void _verifyOtp() async {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter 6 digit code')));
      return;
    }
    setState(() {
      _verifying = true;
    });
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _verifying = false;
    });
    if (code == '123456') {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP. Use 123456.')));
    }
  }

  Widget _buildOtpFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) {
        return SizedBox(
          width: 45,
          child: TextField(
            controller: _otpControllers[i],
            focusNode: _otpFocus[i],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: 2),
            decoration: const InputDecoration(counterText: ''),
            onChanged: (v) {
              if (v.isNotEmpty) {
                if (i + 1 < _otpFocus.length) {
                  _otpFocus[i + 1].requestFocus();
                } else {
                  _otpFocus[i].unfocus();
                }
              } else {
                if (i - 1 >= 0) _otpFocus[i - 1].requestFocus();
              }
            },
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF181A20), Color(0xFF232526), Color(0xFF2B2B2B)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 32,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Enhanced lock graphic with glow and glass reflection
                        Column(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [Colors.deepPurpleAccent.withValues(alpha: 0.5), Colors.transparent],
                                      radius: 0.8,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 86,
                                  height: 86,
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple,
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.deepPurpleAccent.withValues(alpha: 0.6),
                                        blurRadius: 32,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.lock_rounded, color: Colors.white, size: 44),
                                ),
                                Positioned(
                                  top: 18,
                                  left: 18,
                                  child: Container(
                                    width: 32,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      gradient: LinearGradient(
                                        colors: [Colors.white.withValues(alpha: 0.45), Colors.white.withValues(alpha: 0.05)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            const Text('Private Sambad', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5, shadows: [Shadow(color: Colors.black26, blurRadius: 4)])),
                            const SizedBox(height: 6),
                            const Text('Secure Chat Login', style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // OTP Section
                        if (!_sent) ...[
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, letterSpacing: 0.2),
                            decoration: InputDecoration(
                              labelText: 'Mobile number',
                              labelStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
                              prefixIcon: const Icon(Icons.phone, color: Colors.deepPurpleAccent),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.04),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white24)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.deepPurpleAccent)),
                            ),
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton(
                            onPressed: _sendOtp,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              backgroundColor: Colors.deepPurpleAccent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 6,
                              shadowColor: Colors.deepPurpleAccent.withValues(alpha: 0.3),
                            ),
                            child: const Text('Send OTP', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.7, shadows: [Shadow(color: Colors.black38, blurRadius: 2)])),
                          ),
                        ]
                        else ...[
                          const Text('Enter the 6-digit code sent to your number', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                          const SizedBox(height: 18),
                          _buildOtpFields(),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _verifying ? null : _verifyOtp,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              backgroundColor: Colors.deepPurpleAccent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 6,
                              shadowColor: Colors.deepPurpleAccent.withValues(alpha: 0.3),
                            ),
                            child: _verifying
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Verify & Continue', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.7, shadows: [Shadow(color: Colors.black38, blurRadius: 2)])),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: _secondsLeft == 0 ? _resend : null,
                                style: TextButton.styleFrom(foregroundColor: Colors.deepPurpleAccent, textStyle: const TextStyle(fontWeight: FontWeight.bold)),
                                child: Text(_secondsLeft == 0 ? 'Resend' : 'Resend in $_secondsLeft s'),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 28),
                        Row(
                          children: const [
                            Expanded(child: Divider(thickness: 1.2, color: Colors.white24)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text('or', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w600)),
                            ),
                            Expanded(child: Divider(thickness: 1.2, color: Colors.white24)),
                          ],
                        ),
                        const SizedBox(height: 22),
                        // Social login buttons
                        SocialLoginButtons(),
                        const SizedBox(height: 22),
                        const Text('By continuing, you agree to the Privacy Policy.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
