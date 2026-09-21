import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

class PermissionsScreen extends StatefulWidget {
  final String role;
  const PermissionsScreen({super.key, required this.role});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _notificationsEnabled = true;

  bool get _usesCamera =>
      widget.role == 'owner' ||
      widget.role == 'manager' ||
      widget.role == 'cashier' ||
      widget.role == 'bodegero' ||
      widget.role == 'delivery_checker' ||
      widget.role == 'merchandiser';

  bool get _usesNotifications => true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Notification permission denied. Enable it in device settings.'),
              backgroundColor: BaycelColors.error,
            ),
          );
        }
        return;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);
    setState(() => _notificationsEnabled = value);
  }

  String _cameraReason() {
    switch (widget.role) {
      case 'owner':
      case 'manager':
        return 'Used for scanning product barcodes in the inventory and delivery management.';
      case 'cashier':
        return 'Used for capturing receipt photos when submitting sales.';
      case 'bodegero':
        return 'Used for scanning product barcodes during stock-in and stock-out.';
      case 'delivery_checker':
        return 'Used for scanning delivery documents and product barcodes.';
      case 'merchandiser':
        return 'Used for scanning product barcodes to check stock levels.';
      default:
        return 'Used for barcode scanning and receipt capture.';
    }
  }

  String _notificationReason() {
    switch (widget.role) {
      case 'owner':
      case 'manager':
        return 'Receive alerts for low stock, cash advance requests, and absence forms.';
      case 'cashier':
        return 'Receive alerts for sales submission confirmations and absence form updates.';
      case 'bagger':
        return 'Receive alerts for schedule changes and absence form updates.';
      case 'bodegero':
        return 'Receive alerts for low stock warnings, delivery updates, and cash advance requests.';
      case 'delivery_checker':
        return 'Receive alerts for new deliveries and stock update confirmations.';
      case 'merchandiser':
        return 'Receive alerts for low stock on assigned products and cash advance updates.';
      default:
        return 'Receive important app notifications.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('App Permissions', style: BaycelTypography.headlineMd),
        backgroundColor: BaycelColors.card,
        elevation: 0,
        iconTheme: IconThemeData(color: BaycelColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(BaycelSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage the permissions this app uses. Some features require specific permissions to function.',
              style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textSecondary),
            ),
            SizedBox(height: BaycelSpacing.lg),
            if (_usesNotifications)
              _buildPermissionCard(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                reason: _notificationReason(),
                isEnabled: _notificationsEnabled,
                onToggle: _toggleNotifications,
              ),
            if (_usesNotifications && _usesCamera) SizedBox(height: BaycelSpacing.md),
            if (_usesCamera)
              _buildPermissionCard(
                icon: Icons.camera_alt_outlined,
                title: 'Camera',
                reason: _cameraReason(),
                isEnabled: null,
                onToggle: null,
                isInfoOnly: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String reason,
    bool? isEnabled,
    ValueChanged<bool>? onToggle,
    bool isInfoOnly = false,
  }) {
    return Container(
      decoration: BaycelComponents.card,
      padding: EdgeInsets.all(BaycelSpacing.base),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: BaycelColors.crimson.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(BaycelRadius.md),
            ),
            child: Icon(icon, color: BaycelColors.crimson, size: 22),
          ),
          SizedBox(width: BaycelSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: BaycelTypography.headlineMd.copyWith(fontSize: 15)),
                SizedBox(height: BaycelSpacing.xs),
                Text(reason, style: BaycelTypography.bodySm.copyWith(
                  color: BaycelColors.textSecondary, fontSize: 12.5, height: 1.4)),
                SizedBox(height: BaycelSpacing.sm),
                if (isInfoOnly)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.sm, vertical: BaycelSpacing.xs),
                    decoration: BoxDecoration(
                      color: BaycelColors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(BaycelRadius.sm),
                    ),
                    child: Text('Requested when needed',
                      style: BaycelTypography.labelSm.copyWith(color: BaycelColors.blue, fontSize: 11)),
                  )
                else
                  Row(
                    children: [
                      Icon(
                        (isEnabled ?? false) ? Icons.check_circle : Icons.cancel_outlined,
                        size: 16,
                        color: (isEnabled ?? false) ? BaycelColors.success : BaycelColors.textDisabled,
                      ),
                      SizedBox(width: BaycelSpacing.xs),
                      Text(
                        (isEnabled ?? false) ? 'Enabled' : 'Disabled',
                        style: BaycelTypography.labelSm.copyWith(
                          color: (isEnabled ?? false) ? BaycelColors.success : BaycelColors.textDisabled,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (!isInfoOnly && onToggle != null)
            Switch(
              value: isEnabled ?? false,
              onChanged: onToggle,
              activeThumbColor: BaycelColors.crimson,
            ),
        ],
      ),
    );
  }
}
