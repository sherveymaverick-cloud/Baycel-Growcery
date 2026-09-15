import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rateController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String _selectedRole = 'cashier';
  int _selectedPayday = 15;

  static const _roles = [
    ('owner', 'Owner'),
    ('manager', 'Manager'),
    ('cashier', 'Cashier'),
    ('bagger', 'Bagger'),
    ('bodegero', 'Bodegero'),
    ('delivery_checker', 'Delivery Checker'),
    ('merchandiser', 'Merchandiser'),
  ];

  void _validateAndRegister() {
    bool valid = true;
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
    });

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Enter your full name.');
      valid = false;
    }

    final email = _emailController.text.trim();
    if (email.isEmpty || !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      setState(() => _emailError = 'Enter a valid email address.');
      valid = false;
    }

    final password = _passwordController.text;
    if (password.length < 6) {
      setState(() => _passwordError = 'Password must be at least 6 characters.');
      valid = false;
    }

    if (valid) _register();
  }

  Future<void> _register() async {
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    // Save current user info before creating new account (owner/manager adding employee)
    final previousUser = FirebaseAuth.instance.currentUser;
    final previousEmail = previousUser?.email;

    try {
      final result = await AuthService().registerWithEmail(email, password);

      if (result == null || result.user == null) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration failed. Please try again.')),
          );
        }
        return;
      }

    await FirebaseFirestore.instance.collection('users').doc(result.user!.uid).set({
      'name': name,
      'email': email,
      'role': _selectedRole,
      'position': '',
      'rate': double.tryParse(_rateController.text.trim()) ?? 0,
      'payday': _selectedPayday,
      'schedule': {'start': '08:00', 'end': '17:00'},
      'rfidCardUID': '',
      'assignedProducts': [],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // If an owner/manager was logged in, re-authenticate them
    if (previousUser != null && previousEmail != null && mounted) {
      final passwordController = TextEditingController();
      final reAuth = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Re-enter your password'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Your password'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );

      if (reAuth == true && passwordController.text.isNotEmpty) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: previousEmail,
          password: passwordController.text,
        );
      }
      passwordController.dispose();
    }

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created. You can now log in.')),
      );
      Navigator.of(context).pop();
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BaycelColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: BaycelColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
            padding: EdgeInsets.all(BaycelSpacing.xl),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BaycelComponents.card,
              child: Padding(
                padding: EdgeInsets.all(BaycelSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Create Account', style: BaycelTypography.headlineMd.copyWith(fontSize: 20, letterSpacing: -0.01)),
                    SizedBox(height: BaycelSpacing.xs),
                    Text('Register a new staff account for Baycel Growcery.',
                      style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textMuted, fontSize: 13)),
                    SizedBox(height: BaycelSpacing.xl * 1.5),
                    _buildNameField(),
                    SizedBox(height: BaycelSpacing.base),
                    _buildEmailField(),
                    SizedBox(height: BaycelSpacing.base),
                    _buildPasswordField(),
                    SizedBox(height: BaycelSpacing.base),
                    _buildRoleSelector(),
                    SizedBox(height: BaycelSpacing.base),
                    _buildRateField(),
                    SizedBox(height: BaycelSpacing.base),
                    _buildPaydaySelector(),
                    SizedBox(height: BaycelSpacing.lg),
                    _buildRegisterButton(),
                    SizedBox(height: BaycelSpacing.lg),
                    Center(child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Text.rich(TextSpan(children: [
                        TextSpan(text: 'Already have an account? ', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textMuted, fontSize: 12)),
                        TextSpan(text: 'Log in', style: BaycelTypography.label.copyWith(color: BaycelColors.crimson, fontSize: 12, fontWeight: FontWeight.w600)),
                      ])),
                    )),
                  ],
                ),
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildNameField() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Full Name', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textSecondary, fontSize: 12, letterSpacing: 0.02)),
      SizedBox(height: BaycelSpacing.xs),
      TextFormField(
        controller: _nameController,
        textCapitalization: TextCapitalization.words,
        style: BaycelTypography.body.copyWith(fontSize: 13),
        decoration: InputDecoration(
          filled: true, fillColor: BaycelColors.card, hintText: 'Juan Dela Cruz',
          hintStyle: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled, fontSize: 13),
          contentPadding: EdgeInsets.symmetric(horizontal: BaycelSpacing.lg, vertical: BaycelSpacing.lg),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(BaycelRadius.md), borderSide: BorderSide(color: BaycelColors.divider)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(BaycelRadius.md), borderSide: BorderSide(color: BaycelColors.divider)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(BaycelRadius.md), borderSide: BorderSide(color: BaycelColors.crimson, width: 2)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(BaycelRadius.md), borderSide: BorderSide(color: BaycelColors.error)),
        ),
        onChanged: (_) => setState(() => _nameError = null),
      ),
      if (_nameError != null) ...[SizedBox(height: BaycelSpacing.xs), Text(_nameError!, style: BaycelTypography.bodySm.copyWith(color: BaycelColors.error, fontSize: 11))],
    ]);
  }

  Widget _buildEmailField() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Email address', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textSecondary, fontSize: 12, letterSpacing: 0.02)),
      SizedBox(height: BaycelSpacing.xs),
      TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        textCapitalization: TextCapitalization.none,
        style: BaycelTypography.body.copyWith(fontSize: 13),
        decoration: InputDecoration(
          filled: true, fillColor: BaycelColors.card, hintText: 'name@baycel.com',
          hintStyle: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled, fontSize: 13),
          contentPadding: EdgeInsets.symmetric(horizontal: BaycelSpacing.lg, vertical: BaycelSpacing.lg),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(BaycelRadius.md), borderSide: BorderSide(color: BaycelColors.divider)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(BaycelRadius.md), borderSide: BorderSide(color: BaycelColors.divider)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(BaycelRadius.md), borderSide: BorderSide(color: BaycelColors.crimson, width: 2)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(BaycelRadius.md), borderSide: BorderSide(color: BaycelColors.error)),
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
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: BaycelTypography.body.copyWith(fontSize: 13),
          decoration: InputDecoration(
            filled: true, fillColor: BaycelColors.card, hintText: 'At least 6 characters',
            hintStyle: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled, fontSize: 13),
            contentPadding: EdgeInsets.symmetric(horizontal: BaycelSpacing.lg, vertical: BaycelSpacing.lg),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(BaycelRadius.md), borderSide: BorderSide(color: BaycelColors.divider)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(BaycelRadius.md), borderSide: BorderSide(color: BaycelColors.divider)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(BaycelRadius.md), borderSide: BorderSide(color: BaycelColors.crimson, width: 2)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(BaycelRadius.md), borderSide: BorderSide(color: BaycelColors.error)),
          ),
          onChanged: (_) => setState(() => _passwordError = null),
        ),
        Positioned(right: BaycelSpacing.md, top: BaycelSpacing.lg, child: IconButton(
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: BaycelColors.textMuted, size: 20),
        )),
      ]),
      if (_passwordError != null) ...[SizedBox(height: BaycelSpacing.xs), Text(_passwordError!, style: BaycelTypography.bodySm.copyWith(color: BaycelColors.error, fontSize: 11))],
    ]);
  }

  Widget _buildRoleSelector() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Role', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textSecondary, fontSize: 12, letterSpacing: 0.02)),
      SizedBox(height: BaycelSpacing.xs),
      Container(
        padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.lg),
        decoration: BoxDecoration(
          color: BaycelColors.card,
          border: Border.all(color: BaycelColors.divider),
          borderRadius: BorderRadius.circular(BaycelRadius.md),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedRole,
            isExpanded: true,
            style: BaycelTypography.body.copyWith(fontSize: 13),
            dropdownColor: BaycelColors.card,
            items: _roles.map((r) => DropdownMenuItem(value: r.$1, child: Text(r.$2))).toList(),
            onChanged: (v) => setState(() => _selectedRole = v ?? 'cashier'),
          ),
        ),
      ),
    ]);
  }

  Widget _buildRateField() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Hourly Rate (\u20B1)', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textSecondary, fontSize: 12, letterSpacing: 0.02)),
      SizedBox(height: BaycelSpacing.xs),
      TextFormField(
        controller: _rateController,
        keyboardType: TextInputType.number,
        style: BaycelTypography.body.copyWith(fontSize: 13),
        decoration: InputDecoration(
          filled: true, fillColor: BaycelColors.card, hintText: '0.00',
          hintStyle: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled, fontSize: 13),
          contentPadding: EdgeInsets.symmetric(horizontal: BaycelSpacing.lg, vertical: BaycelSpacing.lg),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(BaycelRadius.md), borderSide: BorderSide(color: BaycelColors.divider)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(BaycelRadius.md), borderSide: BorderSide(color: BaycelColors.divider)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(BaycelRadius.md), borderSide: BorderSide(color: BaycelColors.crimson, width: 2)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(BaycelRadius.md), borderSide: BorderSide(color: BaycelColors.error)),
        ),
      ),
    ]);
  }

  Widget _buildPaydaySelector() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Payday', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textSecondary, fontSize: 12, letterSpacing: 0.02)),
      SizedBox(height: BaycelSpacing.xs),
      Container(
        padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.lg),
        decoration: BoxDecoration(
          color: BaycelColors.card,
          border: Border.all(color: BaycelColors.divider),
          borderRadius: BorderRadius.circular(BaycelRadius.md),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: _selectedPayday,
            isExpanded: true,
            style: BaycelTypography.body.copyWith(fontSize: 13),
            dropdownColor: BaycelColors.card,
            items: const [
              DropdownMenuItem(value: 15, child: Text('Every 15th')),
              DropdownMenuItem(value: 30, child: Text('Every 30th (End of month)')),
            ],
            onChanged: (v) => setState(() => _selectedPayday = v ?? 15),
          ),
        ),
      ),
    ]);
  }

  Widget _buildRegisterButton() {
    return SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
      onPressed: _isLoading ? null : _validateAndRegister,
      style: BaycelComponents.buttonPrimary,
      child: _isLoading
        ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
        : Text('Create Account', style: BaycelTypography.label.copyWith(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    ));
  }
}
