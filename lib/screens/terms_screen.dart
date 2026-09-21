import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

class TermsOverlay extends StatefulWidget {
  final Widget child;
  const TermsOverlay({super.key, required this.child});

  @override
  State<TermsOverlay> createState() => _TermsOverlayState();
}

class _TermsOverlayState extends State<TermsOverlay> {
  bool _agreed = false;
  bool _reachedEnd = false;
  final _scrollController = ScrollController();
  bool _showOverlay = true;
  double _scrollProgress = 0;


  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final maxScroll = pos.maxScrollExtent;
    if (maxScroll > 0) {
      final progress = (pos.pixels / maxScroll).clamp(0.0, 1.0);
      if (progress != _scrollProgress) {
        setState(() => _scrollProgress = progress);
      }
    }
    if (pos.pixels >= maxScroll - 50 && !_reachedEnd) {
      setState(() => _reachedEnd = true);
    }
  }

  void _onCheckboxTap() {
    if (!_reachedEnd) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BaycelRadius.md)),
          margin: EdgeInsets.all(BaycelSpacing.base),
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white, size: 18),
              SizedBox(width: BaycelSpacing.sm),
              Expanded(
                child: Text('Please scroll to the end of the Terms & Conditions first.',
                  style: BaycelTypography.bodySm.copyWith(color: Colors.white)),
              ),
            ],
          ),
          backgroundColor: BaycelColors.marigoldDark,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    setState(() => _agreed = !_agreed);
  }

  Future<void> _continue() async {
    if (!_agreed) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasAgreedToTerms', true);
    if (mounted) setState(() => _showOverlay = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showOverlay)
          AnimatedOpacity(
            opacity: _showOverlay ? 1.0 : 0.0,
            duration: Duration(milliseconds: 300),
            child: Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(BaycelSpacing.lg),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 440,
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: BaycelColors.card,
                        borderRadius: BorderRadius.circular(BaycelRadius.xl),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 30,
                            offset: Offset(0, 12),
                            spreadRadius: -4,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(BaycelRadius.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildHeader(),
                            _buildScrollProgress(),
                            Flexible(child: _buildContent()),
                            _buildFooter(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(BaycelSpacing.lg, BaycelSpacing.lg, BaycelSpacing.lg, BaycelSpacing.base),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BaycelColors.crimson,
            BaycelColors.crimsonDark,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(BaycelRadius.md),
            ),
            child: Icon(Icons.gavel_rounded, color: Colors.white, size: 22),
          ),
          SizedBox(width: BaycelSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Terms & Conditions',
                  style: BaycelTypography.headlineMd.copyWith(
                    color: Colors.white,
                    fontSize: 17,
                    decoration: TextDecoration.none,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Baycel Growcery',
                  style: BaycelTypography.bodySm.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollProgress() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      height: 3,
      child: Stack(
        children: [
          Container(color: BaycelColors.divider),
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            width: MediaQuery.of(context).size.width * _scrollProgress * 0.9,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _reachedEnd
                    ? [BaycelColors.success, BaycelColors.success]
                    : [BaycelColors.crimson, BaycelColors.crimsonLight],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.lg, vertical: BaycelSpacing.base),
      child: DefaultTextStyle(
        style: TextStyle(decoration: TextDecoration.none),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('1. Purpose', [
              'Baycel Growcery is a grocery store management system designed to help store owners, managers, and floor staff manage daily operations including inventory, deliveries, attendance, payroll, and sales tracking.',
            ]),
            _buildSection('2. User Roles & Responsibilities', [
              'The app supports the following roles: Owner, Manager, Cashier, Bagger, Bodegero, Delivery Checker, and Merchandiser. Each role has specific permissions and responsibilities. Users must only perform actions within their assigned role.',
            ]),
            _buildSection('3. Data Collection & Storage', [
              'The app collects and stores the following data using Firebase (Google Cloud):',
          ], bullets: [
            'Employee information (name, email, role, hourly rate, schedule)',
            'Attendance records (clock-in/out times, break times)',
            'Inventory data (product names, stock levels, prices)',
            'Delivery records (suppliers, items, dates, status)',
            'Sales transactions and stock movements',
            'Cash advance requests and payroll records',
            'Notification tokens for push notifications',
          ]),
          _buildSection('4. Data Usage', [
            'All data collected is used solely for grocery store management purposes. Data is not shared with third parties or used for advertising. Store owners and managers have access to all data within their store. Floor staff can only view data relevant to their role.',
          ]),
          _buildSection('5. Account Security', [
            'Users are responsible for keeping their login credentials secure. Do not share your password with others. Contact your store owner or manager immediately if you suspect unauthorized access.',
          ]),
          _buildSection('6. Notification Permissions', [
            'The app may request notification permissions to send important alerts such as low stock warnings, cash advance request updates, and absence form status changes. You can manage notification settings in your device settings.',
          ]),
          _buildSection('7. Camera Permissions', [
            'The app may request camera permissions for barcode scanning and receipt photo capture. Camera access is only used within the app for these specific purposes.',
          ]),
          _buildSection('8. Data Retention', [
            'Your data is retained as long as your account is active. If your account is deleted by the store owner, your personal data will be removed from the active system.',
          ]),
          _buildSection('9. Limitations', [
            'This system is a management tool and does not replace official company records. Payroll calculations are estimates and may require manual verification. Always refer to official company documents for employment and compensation matters.',
          ]),
          _buildSection('10. Contact', [
            'For questions about these Terms & Conditions or your data, contact your store owner or system administrator.',
          ]),
          SizedBox(height: BaycelSpacing.sm),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> paragraphs, {List<String>? bullets}) {
    return Padding(
      padding: EdgeInsets.only(bottom: BaycelSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: BaycelTypography.body.copyWith(
              fontWeight: FontWeight.w700,
              color: BaycelColors.textPrimary,
              fontSize: 13.5,
            ),
          ),
          SizedBox(height: BaycelSpacing.xs),
          ...paragraphs.map((p) => Padding(
            padding: EdgeInsets.only(bottom: BaycelSpacing.xs),
            child: Text(
              p,
              style: BaycelTypography.bodySm.copyWith(
                color: BaycelColors.textSecondary,
                height: 1.55,
                fontSize: 12.5,
              ),
            ),
          )),
          if (bullets != null)
            ...bullets.map((b) => Padding(
              padding: EdgeInsets.only(left: BaycelSpacing.base, bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: BaycelTypography.bodySm.copyWith(
                    color: BaycelColors.crimson, fontWeight: FontWeight.w700, fontSize: 12.5)),
                  Expanded(
                    child: Text(b, style: BaycelTypography.bodySm.copyWith(
                      color: BaycelColors.textSecondary, height: 1.55, fontSize: 12.5)),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.fromLTRB(BaycelSpacing.lg, BaycelSpacing.md, BaycelSpacing.lg, BaycelSpacing.lg),
      decoration: BoxDecoration(
        color: BaycelColors.surface,
        border: Border(top: BorderSide(color: BaycelColors.divider)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _onCheckboxTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _agreed ? BaycelColors.crimson : Colors.transparent,
                    border: Border.all(
                      color: _agreed
                          ? BaycelColors.crimson
                          : _reachedEnd ? BaycelColors.textDisabled : BaycelColors.divider,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(BaycelRadius.sm),
                  ),
                  child: _agreed
                      ? Icon(Icons.check, size: 16, color: Colors.white)
                      : !_reachedEnd
                          ? Icon(Icons.lock_outline, size: 14, color: BaycelColors.textDisabled)
                          : null,
                ),
                SizedBox(width: BaycelSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'I have read and agree to the Terms & Conditions',
                        style: BaycelTypography.bodySm.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _reachedEnd ? BaycelColors.textPrimary : BaycelColors.textDisabled,
                          fontSize: 13,
                        ),
                      ),
                      if (!_reachedEnd)
                        Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text(
                            'Scroll to the end to enable',
                            style: BaycelTypography.bodySm.copyWith(
                              color: BaycelColors.textDisabled,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: BaycelSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _agreed ? _continue : null,
              style: BaycelComponents.buttonPrimary.copyWith(
                backgroundColor: WidgetStatePropertyAll(
                  _agreed ? BaycelColors.crimson : BaycelColors.textDisabled,
                ),
                padding: WidgetStatePropertyAll(
                  EdgeInsets.symmetric(vertical: 14),
                ),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(BaycelRadius.md),
                  ),
                ),
              ),
              child: Text(
                'Continue',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
