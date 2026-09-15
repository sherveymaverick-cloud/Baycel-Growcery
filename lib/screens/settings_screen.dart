import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/animated_widgets.dart';
import '../services/firestore_service.dart';
import '../models/settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _firestore = FirestoreService();
  StoreSettings? _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final settings = await _firestore.getSettings().first;
    if (mounted) {
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    }
  }

  void _saveSettings() async {
    final settings = StoreSettings(
      id: 'default',
      storeName: _settings?.storeName ?? 'Baycel Growcery',
      storeCode: _settings?.storeCode ?? '',
      currency: _settings?.currency ?? 'PHP',
      timezone: _settings?.timezone ?? 'Asia/Manila',
      values: _settings?.values ?? {},
      updatedAt: DateTime.now(),
    );
    await _firestore.saveSettings(settings);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Settings saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: SkeletonSettings());

    final isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(BaycelSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaggeredItem(index: 0, child: _buildHeader()),
          SizedBox(height: BaycelSpacing.lg),
          if (isMobile) ...[
            StaggeredItem(index: 1, child: _buildStoreSettingsCard()),
            SizedBox(height: BaycelSpacing.base),
            StaggeredItem(index: 2, child: _buildRolePermissionsCard()),
            SizedBox(height: BaycelSpacing.base),
            StaggeredItem(index: 3, child: _buildSystemTogglesCard()),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: StaggeredItem(index: 1, child: _buildStoreSettingsCard())),
                SizedBox(width: BaycelSpacing.base),
                Expanded(child: StaggeredItem(index: 2, child: _buildRolePermissionsCard())),
                SizedBox(width: BaycelSpacing.base),
                Expanded(child: StaggeredItem(index: 3, child: _buildSystemTogglesCard())),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: BaycelTypography.display.copyWith(fontSize: 26)),
            Text('Manage system configuration', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textSecondary)),
          ],
        ),
      ],
    );
  }

  Widget _buildStoreSettingsCard() {
    return Container(
      decoration: BaycelComponents.card,
      child: Padding(
        padding: EdgeInsets.all(BaycelSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.store_outlined, size: 20, color: BaycelColors.crimson),
                SizedBox(width: BaycelSpacing.sm),
                Text('Store Settings', style: BaycelTypography.headlineMd),
              ],
            ),
            SizedBox(height: BaycelSpacing.md),
            _buildStoreInfoRow('Store Name', _settings?.storeName ?? 'Baycel Growcery'),
            Divider(color: BaycelColors.divider.withValues(alpha: 0.5)),
            _buildStoreInfoRow('Default Currency', _settings?.currency == 'PHP' ? 'Philippine Peso (\u20B1)' : _settings?.currency ?? 'PHP'),
            Divider(color: BaycelColors.divider.withValues(alpha: 0.5)),
            _buildStoreInfoRow('Timezone', _settings?.timezone == 'Asia/Manila' ? 'Asia/Manila (UTC+8)' : _settings?.timezone ?? 'Asia/Manila'),
          ],
        ),
      ),
    );
  }

  Widget _buildRolePermissionsCard() {
    return Container(
      decoration: BaycelComponents.card,
      child: Padding(
        padding: EdgeInsets.all(BaycelSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.admin_panel_settings_outlined, size: 20, color: BaycelColors.crimson),
                SizedBox(width: BaycelSpacing.sm),
                Text('Role Permissions', style: BaycelTypography.headlineMd),
              ],
            ),
            SizedBox(height: BaycelSpacing.md),
            _buildRoleRow('Owner', 'Full access to all modules', BaycelColors.crimson),
            Divider(color: BaycelColors.divider.withValues(alpha: 0.5)),
            _buildRoleRow('Manager', 'Inventory, deliveries, reports', BaycelColors.marigoldDark),
            Divider(color: BaycelColors.divider.withValues(alpha: 0.5)),
            _buildRoleRow('Cashier', 'Sales counter, attendance', BaycelColors.viz5),
            Divider(color: BaycelColors.divider.withValues(alpha: 0.5)),
            _buildRoleRow('Bagger', 'Absence forms, attendance', BaycelColors.blue),
            Divider(color: BaycelColors.divider.withValues(alpha: 0.5)),
            _buildRoleRow('Bodegero', 'Stock-in, stock-out', BaycelColors.viz4),
            Divider(color: BaycelColors.divider.withValues(alpha: 0.5)),
            _buildRoleRow('Delivery Checker', 'Create/verify deliveries', BaycelColors.viz2),
            Divider(color: BaycelColors.divider.withValues(alpha: 0.5)),
            _buildRoleRow('Merchandiser', 'Assigned products, stock-out', BaycelColors.viz1),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemTogglesCard() {
    final toggles = _settings?.values ?? {};
    return Container(
      decoration: BaycelComponents.card,
      child: Padding(
        padding: EdgeInsets.all(BaycelSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, size: 20, color: BaycelColors.crimson),
                SizedBox(width: BaycelSpacing.sm),
                Text('System Toggles', style: BaycelTypography.headlineMd),
              ],
            ),
            SizedBox(height: BaycelSpacing.md),
            _buildToggleRow(
              title: 'Low Stock Alerts',
              description: 'Notify when products are below reorder level',
              value: toggles['lowStockAlerts'] ?? true,
              onChanged: (v) {
                setState(() {
                  toggles['lowStockAlerts'] = v;
                });
                _saveSettings();
              },
            ),
            Divider(color: BaycelColors.divider.withValues(alpha: 0.5)),
            _buildToggleRow(
              title: 'Attendance Notifications',
              description: 'Alert on tardiness and absences',
              value: toggles['attendanceNotifications'] ?? true,
              onChanged: (v) {
                setState(() {
                  toggles['attendanceNotifications'] = v;
                });
                _saveSettings();
              },
            ),
            Divider(color: BaycelColors.divider.withValues(alpha: 0.5)),
            _buildToggleRow(
              title: 'Auto Backup',
              description: 'Automatically backup data daily',
              value: toggles['autoBackup'] ?? false,
              onChanged: (v) {
                setState(() {
                  toggles['autoBackup'] = v;
                });
                _saveSettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: BaycelSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: BaycelTypography.body.copyWith(color: BaycelColors.textSecondary)),
          Text(value, style: BaycelTypography.body.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildRoleRow(String role, String permissions, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: BaycelSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: BaycelSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(role, style: BaycelTypography.body.copyWith(fontWeight: FontWeight.w600)),
                Text(permissions, style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: BaycelSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: BaycelTypography.title),
                SizedBox(height: BaycelSpacing.xxs),
                Text(description, style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textMuted)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            thumbColor: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.selected) ? Colors.white : Colors.grey),
            trackColor: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.selected) ? BaycelColors.crimson : BaycelColors.divider),
          ),
        ],
      ),
    );
  }
}
