import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/animated_widgets.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _emailError;
  String? _passwordError;

  void _handleAuth(Future<UserCredential?> authFuture) async {
    setState(() => _isLoading = true);
    try {
      final result = await authFuture;

      if (result != null && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
        return;
      }

      setState(() => _isLoading = false);

      if (result == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication failed. Please check your credentials.')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  void _validateAndLogin() {
    bool valid = true;
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    final email = _emailController.text.trim();
    if (email.isEmpty || !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      setState(() => _emailError = 'Enter a valid email address.');
      valid = false;
    }

    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _passwordError = 'Enter your password.');
      valid = false;
    }

    if (valid) {
      _handleAuth(AuthService().signInWithEmail(email, password));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 860;

    return Scaffold(
      backgroundColor: BaycelColors.surface,
      body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildBrandPanel() {
    final isMobile = MediaQuery.of(context).size.width < 860;
    return Container(
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(0.45, -1),
          end: Alignment(0.55, 1),
          colors: [BaycelColors.crimson, BaycelColors.crimsonDark],
        ),
      ),
      child: Stack(
        children: [
          Positioned(right: -90, top: -90, child: _decorCircle(280, Colors.white, 0.06)),
          Positioned(left: -60, bottom: 60, child: _decorCircle(180, Colors.white, 0.06)),
          Positioned(right: 20, bottom: -40, child: _decorCircle(120, BaycelColors.marigold, 0.10)),
          Positioned(
            right: -40, bottom: -30,
            child: Opacity(opacity: 0.08, child: SizedBox(width: 340, height: 340,
              child: CustomPaint(painter: _CartMotifPainter()))),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.xl, vertical: BaycelSpacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 88, height: 88,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, boxShadow: [BaycelShadows.shadowMd]),
                      child: ClipOval(child: Image.asset('assets/images/store-logo.jpg', fit: BoxFit.cover, width: 88, height: 88)),
                    ),
                    SizedBox(height: BaycelSpacing.base),
                    Text('Baycel Growcery', style: BaycelTypography.display.copyWith(color: Colors.white, fontSize: 26, height: 1.2, letterSpacing: -0.02)),
                    SizedBox(height: BaycelSpacing.sm),
                    Text('Run the store from one screen — orders, stock, riders, and vendors, all in one place.',
                      style: BaycelTypography.bodySm.copyWith(color: Colors.white.withValues(alpha: 0.82), fontSize: 14, height: 1.5),
                      maxLines: 3, overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                if (!isMobile) Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _featureRow('Live order and inventory tracking'),
                  SizedBox(height: BaycelSpacing.base),
                  _featureRow('Vendor payouts and settlement'),
                  SizedBox(height: BaycelSpacing.base),
                  _featureRow('Rider dispatch and delivery status'),
                ]),
                Text('© 2026 Baycel Growcery. All rights reserved.',
                  style: BaycelTypography.labelSm.copyWith(color: Colors.white.withValues(alpha: 0.55), fontSize: 11, letterSpacing: 0.03),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _decorCircle(double size, Color color, double opacity) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: opacity)));
  }

  Widget _featureRow(String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: BaycelColors.marigold)),
      SizedBox(width: BaycelSpacing.md),
      Text(text, style: BaycelTypography.bodySm.copyWith(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
    ]);
  }

  Widget _buildFormPanel() {
    return Container(constraints: const BoxConstraints(maxWidth: 360),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        StaggeredItem(
          index: 0,
          child: Text('Log in', style: BaycelTypography.headlineMd.copyWith(fontSize: 20, letterSpacing: -0.01)),
        ),
        SizedBox(height: BaycelSpacing.xs),
        StaggeredItem(
          index: 1,
          child: Text('Enter your operator credentials to open the dashboard.',
            style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textMuted, fontSize: 13)),
        ),
        SizedBox(height: BaycelSpacing.xl),
        StaggeredItem(index: 2, child: _buildEmailField()),
        SizedBox(height: BaycelSpacing.base),
        StaggeredItem(index: 3, child: _buildPasswordField()),
        SizedBox(height: BaycelSpacing.lg),
        StaggeredItem(
          index: 4,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildRememberMe(), _buildForgotPassword()]),
        ),
        SizedBox(height: BaycelSpacing.lg),
        StaggeredItem(index: 5, child: _buildLoginButton()),
        SizedBox(height: BaycelSpacing.xl),
        StaggeredItem(
          index: 6,
          child: Text.rich(TextSpan(children: [
            TextSpan(text: 'Need access? ', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textMuted, fontSize: 12)),
            TextSpan(text: 'Contact your store admin.', style: BaycelTypography.label.copyWith(color: BaycelColors.crimson, fontSize: 12, fontWeight: FontWeight.w600)),
          ]), textAlign: TextAlign.center),
        ),
      ]),
    );
  }

  Widget _buildEmailField() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Email address', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textSecondary, fontSize: 12, letterSpacing: 0.02)),
      SizedBox(height: BaycelSpacing.xs),
      TextFormField(controller: _emailController, keyboardType: TextInputType.emailAddress,
        textCapitalization: TextCapitalization.none,
        style: BaycelTypography.body.copyWith(fontSize: 13),
        decoration: InputDecoration(filled: true, fillColor: BaycelColors.card, hintText: 'name@baycel.com',
          hintStyle: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled, fontSize: 13),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(BaycelRadius.md), borderSide: BorderSide(color: BaycelColors.divider)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(BaycelRadius.md), borderSide: BorderSide(color: BaycelColors.divider)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(BaycelRadius.md), borderSide: BorderSide(color: BaycelColors.crimson, width: 2)),
        ),
        onChanged: (_) => setState(() => _emailError = null),
      ),
      if (_emailError != null) ...[SizedBox(height: BaycelSpacing.xs), Text(_emailError!, style: BaycelTypography.bodySm.copyWith(color: BaycelColors.error, fontSize: 11))],
    ]);
  }

  Widget _buildPasswordField() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Password', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textSecondary, fontSize: 12, letterSpacing: 0.02)),
      SizedBox(height: BaycelSpacing.xs),
      Stack(children: [
        TextFormField(controller: _passwordController, obscureText: _obscurePassword,
          keyboardType: TextInputType.visiblePassword, style: BaycelTypography.body.copyWith(fontSize: 13),
          decoration: InputDecoration(filled: true, fillColor: BaycelColors.card, hintText: 'Enter your password',
            hintStyle: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled, fontSize: 13),
            contentPadding: EdgeInsets.fromLTRB(16, 14, 44, 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(BaycelRadius.md), borderSide: BorderSide(color: BaycelColors.divider)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(BaycelRadius.md), borderSide: BorderSide(color: BaycelColors.divider)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(BaycelRadius.md), borderSide: BorderSide(color: BaycelColors.crimson, width: 2)),
          ),
          onChanged: (_) => setState(() => _passwordError = null),
        ),
        Positioned(right: 4, top: 0, bottom: 0, child: Center(child: IconButton(
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          icon: Text(_obscurePassword ? 'Show' : 'Hide',
            style: BaycelTypography.label.copyWith(color: BaycelColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
          padding: EdgeInsets.symmetric(horizontal: 12),
          constraints: BoxConstraints(minWidth: 44, minHeight: 44),
          splashRadius: 20,
          tooltip: _obscurePassword ? 'Show password' : 'Hide password',
        ))),
      ]),
      if (_passwordError != null) ...[SizedBox(height: BaycelSpacing.xs), Text(_passwordError!, style: BaycelTypography.bodySm.copyWith(color: BaycelColors.error, fontSize: 11))],
    ]);
  }

  Widget _buildRememberMe() {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Checkbox(value: _rememberMe, onChanged: (v) => setState(() => _rememberMe = v ?? false),
        checkColor: Colors.white,
        fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? BaycelColors.crimson : Colors.transparent),
        side: BorderSide(color: BaycelColors.divider)),
      Text('Remember me', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textSecondary, fontSize: 13)),
    ]);
  }

  Widget _buildForgotPassword() {
    return TextButton(
      onPressed: () {
        final emailController = TextEditingController();
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Reset Password', style: BaycelTypography.title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Enter your email to receive a reset link.', style: BaycelTypography.bodySm),
                SizedBox(height: BaycelSpacing.md),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: BaycelComponents.input.copyWith(hintText: 'Email address'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final email = emailController.text.trim();
                  if (email.isNotEmpty) {
                    await AuthService().resetPassword(email);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Password reset email sent')),
                      );
                    }
                  }
                },
                style: BaycelComponents.buttonPrimary,
                child: Text('Send Reset Link', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
      child: Text('Forgot password?', style: BaycelTypography.label.copyWith(color: BaycelColors.crimson, fontSize: 13)),
    );
  }

  Widget _buildLoginButton() {
    return PressScale(
      onTap: _isLoading ? null : _validateAndLogin,
      child: SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
        onPressed: _isLoading ? null : _validateAndLogin,
        style: BaycelComponents.buttonPrimary,
        child: _isLoading ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
          : Text('Log in', style: BaycelTypography.label.copyWith(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      )),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(children: [
        _buildBrandPanel(),
        Container(
          color: BaycelColors.surface,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: _buildFormPanel(),
        ),
      ]),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Expanded(flex: 42, child: _buildBrandPanel()),
      Expanded(flex: 58, child: Container(
        color: BaycelColors.surface,
        alignment: Alignment.center,
        padding: EdgeInsets.all(BaycelSpacing.xl),
        child: _buildFormPanel(),
      )),
    ]);
  }
}

class _CartMotifPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.10, size.height * 0.15)
      ..lineTo(size.width * 0.20, size.height * 0.15)
      ..lineTo(size.width * 0.28, size.height * 0.55)
      ..lineTo(size.width * 0.72, size.height * 0.55)
      ..lineTo(size.width * 0.80, size.height * 0.25)
      ..lineTo(size.width * 0.24, size.height * 0.25);

    canvas.drawPath(path, paint);
    canvas.drawCircle(Offset(size.width * 0.34, size.height * 0.70), 5, paint);
    canvas.drawCircle(Offset(size.width * 0.64, size.height * 0.70), 5, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
