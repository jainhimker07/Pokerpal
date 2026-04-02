import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  bool _googleLoading = false;
  bool _appleLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _googleLoading = true);
    try {
      final userCredential = await _authService.signInWithGoogle();
      if (!mounted) return;
      if (userCredential != null) {
        Navigator.pushReplacementNamed(context, '/');
      } else {
        _showError('Google Sign-In failed. Please try again.');
      }
    } catch (e) {
      if (mounted) _showError('Google Sign-In failed. Please try again.');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() => _appleLoading = true);
    try {
      final userCredential = await _authService.signInWithApple();
      if (!mounted) return;
      if (userCredential != null) {
        Navigator.pushReplacementNamed(context, '/');
      } else {
        _showError('Apple Sign-In failed. Please try again.');
      }
    } catch (e) {
      if (mounted) _showError('Apple Sign-In failed. Please try again.');
    } finally {
      if (mounted) setState(() => _appleLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool get _showAppleSignIn =>
      !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Background gradient blob
          Positioned(
            top: -120,
            left: -80,
            child: _GlowBlob(
              color: AppTheme.primaryColor.withValues(alpha: 0.25),
              size: 380,
            ),
          ),
          Positioned(
            bottom: -100,
            right: -60,
            child: _GlowBlob(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.18),
              size: 320,
            ),
          ),
          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),

                      // Icon/Logo
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(alpha: 0.4),
                              blurRadius: 32,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.casino_rounded,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Title
                      Text(
                        'Casino Split',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Track wins, splits & settlements\nwith your crew.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white54,
                              height: 1.5,
                            ),
                      ),

                      const Spacer(flex: 2),

                      // Divider text
                      Text(
                        'Sign in to continue',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Colors.white38,
                              letterSpacing: 0.5,
                            ),
                      ),
                      const SizedBox(height: 20),

                      // Google Sign-In Button
                      _SSOButton(
                        id: 'google_sign_in_btn',
                        isLoading: _googleLoading,
                        onPressed: _handleGoogleSignIn,
                        icon: _GoogleIcon(),
                        label: 'Continue with Google',
                        backgroundColor: AppTheme.surfaceColor,
                        foregroundColor: Colors.white,
                        borderColor: AppTheme.surfaceHighlight,
                      ),

                      if (_showAppleSignIn) ...[
                        const SizedBox(height: 14),
                        // Apple Sign-In Button
                        _SSOButton(
                          id: 'apple_sign_in_btn',
                          isLoading: _appleLoading,
                          onPressed: _handleAppleSignIn,
                          icon: const Icon(
                            Icons.apple,
                            color: Colors.white,
                            size: 22,
                          ),
                          label: 'Continue with Apple',
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          borderColor: Colors.white,
                          darkIcon: false,
                        ),
                      ],

                      const Spacer(flex: 1),

                      // Footer
                      Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: Text(
                          'By continuing, you agree to our Terms & Privacy Policy.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white24,
                                    height: 1.5,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Glow blob background decoration ───────────────────────────────────────────
class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

// ── SSO button ─────────────────────────────────────────────────────────────
class _SSOButton extends StatefulWidget {
  final String id;
  final bool isLoading;
  final VoidCallback onPressed;
  final Widget icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final bool darkIcon;

  const _SSOButton({
    required this.id,
    required this.isLoading,
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    this.darkIcon = true,
  });

  @override
  State<_SSOButton> createState() => _SSOButtonState();
}

class _SSOButtonState extends State<_SSOButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          key: Key(widget.id),
          height: 56,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: widget.backgroundColor == Colors.white
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: widget.foregroundColor,
                  ),
                )
              else ...[
                SizedBox(
                  width: 22,
                  height: 22,
                  child: widget.icon,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.foregroundColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Google 'G' icon painted manually ──────────────────────────────────────────
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GoogleIconPainter(),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;

    // Blue arc (top-right, bottom-right, bottom-left partial)
    final paintBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.22
      ..strokeCap = StrokeCap.butt;

    final paintRed = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.22
      ..strokeCap = StrokeCap.butt;

    final paintYellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.22
      ..strokeCap = StrokeCap.butt;

    final paintGreen = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.22
      ..strokeCap = StrokeCap.butt;

    final arcR = r * 0.72;
    final rect =
        Rect.fromCircle(center: Offset(cx, cy), radius: arcR);

    // Red: top-left
    canvas.drawArc(rect, -2.36, 1.2, false, paintRed);
    // Blue: top-right to mid-right
    canvas.drawArc(rect, -1.16, 1.78, false, paintBlue);
    // Yellow: bottom-right
    canvas.drawArc(rect, 0.62, 0.86, false, paintYellow);
    // Green: bottom-left to top-left
    canvas.drawArc(rect, 1.48, 0.88, false, paintGreen);

    // Blue horizontal bar (the "shelf")
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.22
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + arcR, cy),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
