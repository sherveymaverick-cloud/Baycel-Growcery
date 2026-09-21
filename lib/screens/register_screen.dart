import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _rateController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = 'cashier';
  int _selectedPayday = 7;
  String _scheduleStart = '08:00';
  String _scheduleEnd = '17:00';
  List<String> _selectedProducts = [];

  static const _roles = [
    ('owner', 'Owner', Color(0xFFC62828)),
    ('manager', 'Manager', Color(0xFFC62828)),
    ('cashier', 'Cashier', Color(0xFF006AB8)),
    ('bagger', 'Bagger', Color(0xFF7B1FA2)),
    ('bodegero', 'Bodegero', Color(0xFFF57F17)),
    ('delivery_checker', 'Delivery Checker', Color(0xFF0D47A1)),
    ('merchandiser', 'Merchandiser', Color(0xFF2E7D32)),
  ];

  int get _passwordStrength {
    final p = _passwordController.text;
    if (p.isEmpty) return 0;
    int s = 0;
    if (p.length >= 6) s++;
    if (p.length >= 10) s++;
    if (RegExp(r'[A-Z]').hasMatch(p)) s++;
    if (RegExp(r'[0-9]').hasMatch(p)) s++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) s++;
    return s;
  }

  Color get _passwordStrengthColor {
    final s = _passwordStrength;
    if (s <= 1) return BaycelColors.error;
    if (s <= 2) return BaycelColors.marigold;
    if (s <= 3) return BaycelColors.marigoldDark;
    return BaycelColors.success;
  }

  String get _passwordStrengthLabel {
    final s = _passwordStrength;
    if (s <= 1) return 'Weak';
    if (s <= 2) return 'Fair';
    if (s <= 3) return 'Good';
    return 'Strong';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _register();
  }

  Future<void> _register() async {
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    final previousUser = FirebaseAuth.instance.currentUser;
    final previousEmail = previousUser?.email;

    try {
      final result = await AuthService().registerWithEmail(email, password);

      if (result == null || result.user == null) {
        setState(() => _isLoading = false);
        if (mounted) {
          _showErrorDialog('Registration Failed', 'Unable to create account. Please try again.');
        }
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(result.user!.uid).set({
        'name': name,
        'email': email,
        'role': _selectedRole,
        'rate': double.tryParse(_rateController.text.trim()) ?? 0,
        'payday': _selectedPayday,
        'schedule': {'start': _scheduleStart, 'end': _scheduleEnd},
        'rfidCardUID': '',
        'assignedProducts': _selectedRole == 'merchandiser' ? _selectedProducts : [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (previousUser != null && previousEmail != null && mounted) {
        try {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: previousEmail,
            password: _confirmPasswordController.text,
          );
        } catch (e) {
          setState(() => _isLoading = false);
          if (mounted) {
            _showWarningDialog('Password Needed', 'Employee added successfully, but we couldn\'t sign you back in. Please sign in manually.');
          }
          return;
        }
      }

      setState(() => _isLoading = false);

      if (mounted) {
        _showSuccessDialog('Account Created', '$name has been added as ${_selectedRole[0].toUpperCase() + _selectedRole.substring(1)}.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorDialog('Registration Failed', e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BaycelRadius.lg)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BaycelColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, color: BaycelColors.success, size: 56),
            ),
            SizedBox(height: BaycelSpacing.md),
            Text(title, style: BaycelTypography.headlineMd, textAlign: TextAlign.center),
            SizedBox(height: BaycelSpacing.sm),
            Text(message, style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).pop();
              },
              style: BaycelComponents.buttonPrimary,
              child: Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BaycelRadius.lg)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BaycelColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, color: BaycelColors.error, size: 56),
            ),
            SizedBox(height: BaycelSpacing.md),
            Text(title, style: BaycelTypography.headlineMd, textAlign: TextAlign.center),
            SizedBox(height: BaycelSpacing.sm),
            Text(message, style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: BaycelComponents.buttonPrimary.copyWith(
                backgroundColor: WidgetStatePropertyAll(BaycelColors.error),
              ),
              child: Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showWarningDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BaycelRadius.lg)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BaycelColors.marigoldDark.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber_rounded, color: BaycelColors.marigoldDark, size: 56),
            ),
            SizedBox(height: BaycelSpacing.md),
            Text(title, style: BaycelTypography.headlineMd, textAlign: TextAlign.center),
            SizedBox(height: BaycelSpacing.sm),
            Text(message, style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).pop();
              },
              style: BaycelComponents.buttonPrimary,
              child: Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            final formMaxWidth = isWide ? 560.0 : constraints.maxWidth;
            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? BaycelSpacing.xl : BaycelSpacing.base,
                  vertical: BaycelSpacing.lg,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: formMaxWidth),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPageHeader(),
                        SizedBox(height: BaycelSpacing.xl),
                        _buildAccountSection(),
                        SizedBox(height: BaycelSpacing.lg),
                        _buildRoleSection(),
                        SizedBox(height: BaycelSpacing.lg),
                        _buildEmploymentSection(),
                        SizedBox(height: BaycelSpacing.lg),
                        _buildScheduleSection(),
                        SizedBox(height: BaycelSpacing.xl),
                        _buildRegisterButton(),
                        SizedBox(height: BaycelSpacing.lg),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add Employee', style: BaycelTypography.headline),
        SizedBox(height: BaycelSpacing.xs),
        Text(
          'Create a new staff account.',
          style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return _SectionCard(
      title: 'Account',
      children: [
        _label('Full Name'),
        SizedBox(height: BaycelSpacing.xs),
        _buildNameField(),
        SizedBox(height: BaycelSpacing.base),
        _label('Email'),
        SizedBox(height: BaycelSpacing.xs),
        _buildEmailField(),
        SizedBox(height: BaycelSpacing.base),
        _label('Password'),
        SizedBox(height: BaycelSpacing.xs),
        _buildPasswordField(),
        _buildPasswordStrengthBar(),
        SizedBox(height: BaycelSpacing.base),
        _label('Re-enter Password'),
        SizedBox(height: BaycelSpacing.xs),
        _buildConfirmPasswordField(),
      ],
    );
  }

  Widget _buildRoleSection() {
    return _SectionCard(
      title: 'Role',
      children: [
        _buildRoleChips(),
      ],
    );
  }

  Widget _buildEmploymentSection() {
    if (_selectedRole == 'owner') return const SizedBox.shrink();
    if (_selectedRole == 'merchandiser') return _buildProductAssignmentSection();
    return _SectionCard(
      title: 'Employment',
      children: [
        _label('Hourly Rate (₱)'),
        SizedBox(height: BaycelSpacing.xs),
        _buildRateField(),
        SizedBox(height: BaycelSpacing.base),
        _label('Payday'),
        SizedBox(height: BaycelSpacing.xs),
        _buildPaydaySelector(),
      ],
    );
  }

  Widget _buildProductAssignmentSection() {
    return _SectionCard(
      title: 'Product Assignment',
      children: [
        _label('Select products this merchandiser is assigned to'),
        SizedBox(height: BaycelSpacing.xs),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirestoreService().getProducts().map((products) =>
            products.map((p) => {'id': p.id, 'name': p.name}).toList()),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator(color: BaycelColors.crimson);
            }
            final products = snapshot.data ?? [];
            if (products.isEmpty) {
              return Text('No products available', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled));
            }
            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 200),
              child: Container(
                padding: EdgeInsets.all(BaycelSpacing.sm),
                decoration: BoxDecoration(
                  color: BaycelColors.surface,
                  borderRadius: BorderRadius.circular(BaycelRadius.md),
                  border: Border.all(color: BaycelColors.divider),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final isSelected = _selectedProducts.contains(product['id']);
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selectedProducts.add(product['id']!);
                          } else {
                            _selectedProducts.remove(product['id']);
                          }
                        });
                      },
                      title: Text(product['name']!, style: BaycelTypography.bodySm.copyWith(fontSize: 12.5)),
                      activeColor: BaycelColors.crimson,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    );
                  },
                ),
              ),
            );
          },
        ),
        SizedBox(height: BaycelSpacing.xs),
        Text('${_selectedProducts.length} products selected',
          style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textMuted, fontSize: 11)),
      ],
    );
  }

  Widget _buildScheduleSection() {
    return _SectionCard(
      title: 'Schedule',
      children: [
        _buildScheduleRow(),
      ],
    );
  }

  Widget _label(String text) => Text(
    text,
    style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textSecondary, fontSize: 11),
  );

  InputDecoration _fieldDeco({String? hintText, Widget? suffixIcon, Widget? prefixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: BaycelColors.card,
      hintText: hintText,
      hintStyle: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled, fontSize: 13),
      contentPadding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: BaycelSpacing.md),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(BaycelRadius.md), borderSide: BorderSide(color: BaycelColors.divider)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(BaycelRadius.md), borderSide: BorderSide(color: BaycelColors.divider)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(BaycelRadius.md), borderSide: BorderSide(color: BaycelColors.crimson, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(BaycelRadius.md), borderSide: BorderSide(color: BaycelColors.error)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(BaycelRadius.md), borderSide: BorderSide(color: BaycelColors.error, width: 2)),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      textCapitalization: TextCapitalization.words,
      style: BaycelTypography.body.copyWith(fontSize: 13),
      maxLength: 100,
      decoration: _fieldDeco(
        hintText: 'Juan Dela Cruz',
        prefixIcon: Padding(
          padding: EdgeInsets.only(left: BaycelSpacing.md, right: BaycelSpacing.xs),
          child: Icon(Icons.person_outline, size: 18, color: BaycelColors.textDisabled),
        ),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Enter the employee\'s full name.';
        if (v.trim().length < 2) return 'Name must be at least 2 characters';
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textCapitalization: TextCapitalization.none,
      style: BaycelTypography.body.copyWith(fontSize: 13),
      maxLength: 100,
      decoration: _fieldDeco(
        hintText: 'name@baycel.com',
        prefixIcon: Padding(
          padding: EdgeInsets.only(left: BaycelSpacing.md, right: BaycelSpacing.xs),
          child: Icon(Icons.email_outlined, size: 18, color: BaycelColors.textDisabled),
        ),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Enter an email address.';
        if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())) return 'Enter a valid email address.';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: BaycelTypography.body.copyWith(fontSize: 13),
      maxLength: 128,
      onChanged: (_) => setState(() {}),
      decoration: _fieldDeco(
        hintText: 'At least 6 characters',
        prefixIcon: Padding(
          padding: EdgeInsets.only(left: BaycelSpacing.md, right: BaycelSpacing.xs),
          child: Icon(Icons.lock_outline, size: 18, color: BaycelColors.textDisabled),
        ),
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: BaycelColors.textMuted, size: 20),
        ),
      ),
      validator: (v) {
        if (v == null || v.length < 6) return 'Password must be at least 6 characters.';
        if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Include at least 1 uppercase letter.';
        if (!RegExp(r'[0-9]').hasMatch(v)) return 'Include at least 1 number.';
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      style: BaycelTypography.body.copyWith(fontSize: 13),
      maxLength: 128,
      decoration: _fieldDeco(
        hintText: 'Re-enter your password',
        prefixIcon: Padding(
          padding: EdgeInsets.only(left: BaycelSpacing.md, right: BaycelSpacing.xs),
          child: Icon(Icons.lock_outline, size: 18, color: BaycelColors.textDisabled),
        ),
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: BaycelColors.textMuted, size: 20),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Please re-enter your password.';
        if (v != _passwordController.text) return 'Passwords do not match.';
        return null;
      },
    );
  }

  Widget _buildPasswordStrengthBar() {
    final strength = _passwordStrength;
    if (strength == 0 && _passwordController.text.isEmpty) return SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: BaycelSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: strength / 5,
              backgroundColor: BaycelColors.divider,
              valueColor: AlwaysStoppedAnimation(_passwordStrengthColor),
              minHeight: 3,
            ),
          ),
          SizedBox(height: BaycelSpacing.xs),
          Text(_passwordStrengthLabel, style: BaycelTypography.labelXs.copyWith(
            color: _passwordStrengthColor, fontWeight: FontWeight.w600, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildRoleChips() {
    return Wrap(
      spacing: BaycelSpacing.xs,
      runSpacing: BaycelSpacing.xs,
      children: _roles.map((r) {
        final isSelected = _selectedRole == r.$1;
        return GestureDetector(
          onTap: () => setState(() => _selectedRole = r.$1),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 150),
            padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: BaycelSpacing.xs),
            decoration: BoxDecoration(
              color: isSelected ? r.$3.withValues(alpha: 0.12) : BaycelColors.card,
              border: Border.all(
                color: isSelected ? r.$3 : BaycelColors.divider,
                width: isSelected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(BaycelRadius.full),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: r.$3, shape: BoxShape.circle),
                ),
                SizedBox(width: 6),
                Text(r.$2, style: BaycelTypography.labelXs.copyWith(
                  color: isSelected ? r.$3 : BaycelColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 11,
                )),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRateField() {
    return TextFormField(
      controller: _rateController,
      keyboardType: TextInputType.number,
      style: BaycelTypography.body.copyWith(fontSize: 13),
      maxLength: 10,
      decoration: _fieldDeco(
        hintText: '0.00',
        prefixIcon: Padding(
          padding: EdgeInsets.only(left: BaycelSpacing.md, right: BaycelSpacing.xs),
          child: Icon(Icons.payments_outlined, size: 18, color: BaycelColors.textDisabled),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Enter hourly rate.';
        final rate = double.tryParse(v);
        if (rate == null) return 'Enter valid number.';
        if (rate < 0) return 'Rate cannot be negative.';
        if (rate > 1000) return 'Rate too high. Max \u20B11,000/hr.';
        return null;
      },
    );
  }

  Widget _buildPaydaySelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base),
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
            DropdownMenuItem(value: 7, child: Text('Every 7th')),
            DropdownMenuItem(value: 15, child: Text('Every 15th')),
          ],
          onChanged: (v) => setState(() => _selectedPayday = v ?? 7),
        ),
      ),
    );
  }

  TimeOfDay _parseTime(String s) {
    final parts = s.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime({required bool isStart}) async {
    final current = _parseTime(isStart ? _scheduleStart : _scheduleEnd);
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked != null) {
      final pickedTime = _formatTime(picked);
      if (isStart) {
        setState(() => _scheduleStart = pickedTime);
      } else {
        final startParts = _scheduleStart.split(':');
        final endParts = pickedTime.split(':');
        final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
        final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
        if (endMin <= startMin) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('End time must be after start time'), backgroundColor: BaycelColors.error),
          );
          return;
        }
        setState(() => _scheduleEnd = pickedTime);
      }
    }
  }

  Widget _buildScheduleRow() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Start'),
              SizedBox(height: BaycelSpacing.xs),
              _timePickerButton(_scheduleStart, () => _pickTime(isStart: true)),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: BaycelSpacing.lg, left: BaycelSpacing.sm, right: BaycelSpacing.sm),
          child: Icon(Icons.arrow_forward, size: 16, color: BaycelColors.textDisabled),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('End'),
              SizedBox(height: BaycelSpacing.xs),
              _timePickerButton(_scheduleEnd, () => _pickTime(isStart: false)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _timePickerButton(String time, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: BaycelSpacing.md),
        decoration: BoxDecoration(
          color: BaycelColors.card,
          border: Border.all(color: BaycelColors.divider),
          borderRadius: BorderRadius.circular(BaycelRadius.md),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, size: 18, color: BaycelColors.textDisabled),
            SizedBox(width: BaycelSpacing.sm),
            Text(time, style: BaycelTypography.body.copyWith(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: BaycelComponents.buttonPrimary,
        child: _isLoading
            ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add_outlined, size: 18, color: Colors.white),
                  SizedBox(width: BaycelSpacing.sm),
                  Text('Add Employee', style: BaycelTypography.label.copyWith(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(BaycelSpacing.base),
      decoration: BaycelComponents.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: BaycelTypography.labelSm.copyWith(
              color: BaycelColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.05,
            ),
          ),
          SizedBox(height: BaycelSpacing.md),
          ...children,
        ],
      ),
    );
  }
}
