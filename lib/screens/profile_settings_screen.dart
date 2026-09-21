import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/animated_widgets.dart';
import '../services/firestore_service.dart';
import '../models/user.dart';
import '../models/settings.dart';
import 'permissions_screen.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _firestore = FirestoreService();
  StoreUser? _user;
  StoreSettings? _settings;
  bool _isLoading = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final user = await _firestore.getCurrentUser();
    final settings = await _firestore.getSettings().first;
    if (mounted) {
      setState(() {
        _user = user;
        _settings = settings;
        _isLoading = false;
      });
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'owner':
        return 'Owner';
      case 'manager':
        return 'Manager';
      case 'cashier':
        return 'Cashier';
      case 'bagger':
        return 'Bagger';
      case 'bodegero':
        return 'Bodegero';
      case 'delivery_checker':
        return 'Delivery Checker';
      case 'merchandiser':
        return 'Merchandiser';
      default:
        return role;
    }
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: BaycelColors.crimson),
        SizedBox(width: BaycelSpacing.sm),
        Text(title, style: BaycelTypography.headlineMd),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool showBorder = true}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: BaycelSpacing.sm),
      decoration: showBorder ? BoxDecoration(
        border: Border(bottom: BorderSide(color: BaycelColors.divider.withValues(alpha: 0.5), width: 0.5)),
      ) : null,
      child: Row(
        children: [
          Icon(icon, size: 16, color: BaycelColors.textMuted),
          SizedBox(width: BaycelSpacing.sm),
          Text(label, style: BaycelTypography.body.copyWith(color: BaycelColors.textSecondary)),
          Spacer(),
          Text(value, style: BaycelTypography.body.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildEditableRow(IconData icon, String label, TextEditingController controller, {bool showBorder = true}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: BaycelSpacing.xs),
      decoration: showBorder ? BoxDecoration(
        border: Border(bottom: BorderSide(color: BaycelColors.divider.withValues(alpha: 0.5), width: 0.5)),
      ) : null,
      child: Row(
        children: [
          Icon(icon, size: 16, color: BaycelColors.textMuted),
          SizedBox(width: BaycelSpacing.sm),
          Text(label, style: BaycelTypography.body.copyWith(color: BaycelColors.textSecondary)),
          Spacer(),
          SizedBox(
            width: 180,
            child: TextField(
              controller: controller,
              style: BaycelTypography.body.copyWith(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: BaycelSpacing.sm, vertical: BaycelSpacing.xs),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(BaycelRadius.md),
                  borderSide: BorderSide(color: BaycelColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(BaycelRadius.md),
                  borderSide: BorderSide(color: BaycelColors.crimson, width: 2),
                ),
              ),
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
    bool showBorder = true,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: BaycelSpacing.sm),
      decoration: showBorder ? BoxDecoration(
        border: Border(bottom: BorderSide(color: BaycelColors.divider.withValues(alpha: 0.5), width: 0.5)),
      ) : null,
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

  void _saveUserName(String name) async {
    if (_user == null) return;
    await _firestore.updateUser(_user!.uid, {'name': name});
    setState(() {
      _user = StoreUser(
        uid: _user!.uid,
        name: name,
        email: _user!.email,
        role: _user!.role,
        rate: _user!.rate,
        payday: _user!.payday,
        schedule: _user!.schedule,
        rfidCardUID: _user!.rfidCardUID,
        assignedProducts: _user!.assignedProducts,
        createdAt: _user!.createdAt,
        updatedAt: DateTime.now(),
      );
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Name updated')),
      );
    }
  }

  void _saveSettings() async {
    if (_settings == null) return;
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Settings saved')),
      );
    }
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BaycelRadius.lg)),
        title: Text('Change Password', style: BaycelTypography.headlineMd),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: BaycelComponents.input.copyWith(hintText: 'Current password'),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              SizedBox(height: BaycelSpacing.sm),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: BaycelComponents.input.copyWith(hintText: 'New password'),
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Required';
                  if ((v?.length ?? 0) < 6) return 'Min 6 characters';
                  if (!RegExp(r'[A-Z]').hasMatch(v!)) return 'Include at least 1 uppercase letter';
                  if (!RegExp(r'[0-9]').hasMatch(v)) return 'Include at least 1 number';
                  return null;
                },
              ),
              SizedBox(height: BaycelSpacing.sm),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: BaycelComponents.input.copyWith(hintText: 'Confirm new password'),
                validator: (v) {
                  if (v != newPasswordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: BaycelTypography.body.copyWith(color: BaycelColors.textSecondary)),
          ),
          ElevatedButton(
            style: BaycelComponents.buttonPrimary,
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                final authUser = FirebaseAuth.instance.currentUser;
                if (authUser == null) return;
                final credential = EmailAuthProvider.credential(
                  email: authUser.email!,
                  password: currentPasswordController.text,
                );
                await authUser.reauthenticateWithCredential(credential);
                await authUser.updatePassword(newPasswordController.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Password updated')),
                  );
                }
              } on FirebaseAuthException catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.message ?? 'Failed to update password')),
                  );
                }
              }
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: SkeletonProfile());

    final role = _user?.role.value ?? 'cashier';
    final isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(BaycelSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaggeredItem(index: 0, child: _buildHeader()),
          SizedBox(height: BaycelSpacing.lg),
          if (role == 'owner') _buildOwnerSections(isMobile),
          if (role == 'manager') _buildManagerSections(isMobile),
          if (role != 'owner' && role != 'manager') _buildFloorStaffSections(role, isMobile),
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
            Text('Profile & Settings', style: BaycelTypography.display.copyWith(fontSize: 26)),
            Text(
              _user != null ? '${_getRoleLabel(_user!.role.value)} account' : 'Manage your profile',
              style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  // ── Owner ──────────────────────────────────────────────

  Widget _buildOwnerSections(bool isMobile) {
    final toggles = _settings?.values ?? {};
    final lowStockRoles = List<String>.from(toggles['lowStockAlertRoles'] ?? ['owner', 'manager', 'bodegero', 'delivery_checker', 'merchandiser']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // General
        StaggeredItem(index: 1, child: _buildOwnerGeneralCard()),
        SizedBox(height: BaycelSpacing.base),
        // Notifications
        StaggeredItem(index: 2, child: _buildOwnerNotificationsCard(toggles, lowStockRoles)),
        SizedBox(height: BaycelSpacing.base),
        // Security
        StaggeredItem(index: 3, child: _buildSecurityCard()),
        SizedBox(height: BaycelSpacing.base),
        // Roles & Permissions
        StaggeredItem(index: 4, child: _buildRolePermissionsCard()),
        SizedBox(height: BaycelSpacing.base),
        // App Permissions
        StaggeredItem(index: 5, child: _buildPermissionsCard('owner')),
      ],
    );
  }

  Widget _buildOwnerGeneralCard() {
    return Container(
      decoration: BaycelComponents.card,
      child: Padding(
        padding: EdgeInsets.all(BaycelSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.store_outlined, 'General'),
            SizedBox(height: BaycelSpacing.md),
            _buildInfoRow(Icons.label_outline, 'Store Name', _settings?.storeName ?? 'Baycel Growcery'),
            _buildInfoRow(Icons.attach_money_outlined, 'Currency', _settings?.currency == 'PHP' ? 'Philippine Peso (\u20B1)' : _settings?.currency ?? 'PHP'),
            _buildInfoRow(Icons.access_time_outlined, 'Timezone', _settings?.timezone == 'Asia/Manila' ? 'Asia/Manila (UTC+8)' : _settings?.timezone ?? 'Asia/Manila', showBorder: false),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerNotificationsCard(Map<String, dynamic> toggles, List<String> lowStockRoles) {
    return Container(
      decoration: BaycelComponents.card,
      child: Padding(
        padding: EdgeInsets.all(BaycelSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.notifications_outlined, 'Notifications'),
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
            if (toggles['lowStockAlerts'] ?? true) ...[
              SizedBox(height: BaycelSpacing.sm),
              Padding(
                padding: EdgeInsets.only(left: BaycelSpacing.base),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Alert Recipients', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textMuted, fontSize: 11)),
                    SizedBox(height: BaycelSpacing.sm),
                    _buildRoleCheckbox('Owner', 'owner', lowStockRoles, toggles),
                    _buildRoleCheckbox('Manager', 'manager', lowStockRoles, toggles),
                    _buildRoleCheckbox('Bodegero', 'bodegero', lowStockRoles, toggles),
                    _buildRoleCheckbox('Delivery Checker', 'delivery_checker', lowStockRoles, toggles),
                    _buildRoleCheckbox('Merchandiser', 'merchandiser', lowStockRoles, toggles),
                  ],
                ),
              ),
            ],
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
              showBorder: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCheckbox(String label, String roleKey, List<String> selectedRoles, Map<String, dynamic> toggles) {
    final isSelected = selectedRoles.contains(roleKey);
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedRoles.remove(roleKey);
          } else {
            selectedRoles.add(roleKey);
          }
          toggles['lowStockAlertRoles'] = selectedRoles;
        });
        _saveSettings();
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              size: 18,
              color: isSelected ? BaycelColors.crimson : BaycelColors.textDisabled,
            ),
            SizedBox(width: BaycelSpacing.sm),
            Text(label, style: BaycelTypography.body.copyWith(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildRolePermissionsCard() {
    final roles = [
      ('Owner', 'Full access to all modules', BaycelColors.crimson),
      ('Manager', 'Inventory, deliveries, reports', BaycelColors.marigoldDark),
      ('Cashier', 'Sales counter, attendance', BaycelColors.viz5),
      ('Bagger', 'Absence forms, attendance', BaycelColors.blue),
      ('Bodegero', 'Stock-in, stock-out, deliveries', BaycelColors.viz4),
      ('Delivery Checker', 'Create/verify deliveries', BaycelColors.viz2),
      ('Merchandiser', 'Assigned products, stock-out', BaycelColors.viz1),
    ];

    return Container(
      decoration: BaycelComponents.card,
      child: Padding(
        padding: EdgeInsets.all(BaycelSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.admin_panel_settings_outlined, 'Roles & Permissions'),
            SizedBox(height: BaycelSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 400;
                if (isWide) {
                  return Wrap(
                    spacing: BaycelSpacing.base,
                    runSpacing: BaycelSpacing.sm,
                    children: roles.map((r) => SizedBox(
                      width: (constraints.maxWidth - BaycelSpacing.base) / 2,
                      child: _buildRoleRow(r.$1, r.$2, r.$3),
                    )).toList(),
                  );
                }
                return Column(
                  children: [
                    for (int i = 0; i < roles.length; i++)
                      _buildRoleRow(roles[i].$1, roles[i].$2, roles[i].$3, showBorder: i < roles.length - 1),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleRow(String role, String permissions, Color color, {bool showBorder = true}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: BaycelSpacing.sm),
      decoration: showBorder ? BoxDecoration(
        border: Border(bottom: BorderSide(color: BaycelColors.divider.withValues(alpha: 0.5), width: 0.5)),
      ) : null,
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

  // ── Manager ──────────────────────────────────────────────

  Widget _buildManagerSections(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StaggeredItem(index: 1, child: _buildPersonalInfoCard()),
        SizedBox(height: BaycelSpacing.base),
        StaggeredItem(index: 2, child: _buildManagerNotificationsCard()),
        SizedBox(height: BaycelSpacing.base),
        StaggeredItem(index: 3, child: _buildSecurityCard()),
        SizedBox(height: BaycelSpacing.base),
        StaggeredItem(index: 4, child: _buildPermissionsCard('manager')),
      ],
    );
  }

  Widget _buildManagerNotificationsCard() {
    final toggles = _settings?.values ?? {};
    return Container(
      decoration: BaycelComponents.card,
      child: Padding(
        padding: EdgeInsets.all(BaycelSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.notifications_outlined, 'Notifications'),
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
            _buildToggleRow(
              title: 'Deliveries Pending',
              description: 'Alert when deliveries need verification',
              value: toggles['deliveriesPending'] ?? true,
              onChanged: (v) {
                setState(() {
                  toggles['deliveriesPending'] = v;
                });
                _saveSettings();
              },
            ),
            _buildToggleRow(
              title: 'Attendance Anomalies',
              description: 'Notify on tardiness and absences',
              value: toggles['attendanceNotifications'] ?? true,
              onChanged: (v) {
                setState(() {
                  toggles['attendanceNotifications'] = v;
                });
                _saveSettings();
              },
              showBorder: false,
            ),
          ],
        ),
      ),
    );
  }

  // ── Floor Staff ──────────────────────────────────────────────

  Widget _buildFloorStaffSections(String role, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StaggeredItem(index: 1, child: _buildPersonalInfoCard()),
        SizedBox(height: BaycelSpacing.base),
        StaggeredItem(index: 2, child: _buildFloorStaffNotificationsCard(role)),
        SizedBox(height: BaycelSpacing.base),
        StaggeredItem(index: 3, child: _buildSecurityCard()),
        SizedBox(height: BaycelSpacing.base),
        StaggeredItem(index: 4, child: _buildPermissionsCard(role)),
      ],
    );
  }

  Widget _buildFloorStaffNotificationsCard(String role) {
    final toggles = _settings?.values ?? {};
    String title;
    String description;
    String toggleKey;

    switch (role) {
      case 'cashier':
        title = 'Sales Alerts';
        description = 'Notify on sales transactions';
        toggleKey = 'cashierSalesAlerts';
        break;
      case 'bagger':
        title = 'Schedule Notifications';
        description = 'Notify on schedule changes';
        toggleKey = 'baggerScheduleNotifications';
        break;
      case 'bodegero':
        title = 'Stock Alerts';
        description = 'Notify on stock movements';
        toggleKey = 'bodegeroStockAlerts';
        break;
      case 'delivery_checker':
        title = 'Delivery Notifications';
        description = 'Notify on new deliveries';
        toggleKey = 'deliveryCheckerNotifications';
        break;
      case 'merchandiser':
        title = 'Product Alerts';
        description = 'Notify on assigned product changes';
        toggleKey = 'merchandiserProductAlerts';
        break;
      default:
        title = 'Notifications';
        description = 'General notifications';
        toggleKey = 'generalNotifications';
    }

    return Container(
      decoration: BaycelComponents.card,
      child: Padding(
        padding: EdgeInsets.all(BaycelSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.notifications_outlined, 'Notifications'),
            SizedBox(height: BaycelSpacing.md),
            _buildToggleRow(
              title: title,
              description: description,
              value: toggles[toggleKey] ?? true,
              onChanged: (v) {
                setState(() {
                  toggles[toggleKey] = v;
                });
                _saveSettings();
              },
              showBorder: false,
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared ──────────────────────────────────────────────

  Widget _buildPersonalInfoCard() {
    if (_user == null) return SizedBox.shrink();

    final nameController = TextEditingController(text: _user!.name);
    final initials = _user!.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join('').toUpperCase();

    return Container(
      decoration: BaycelComponents.card,
      child: Padding(
        padding: EdgeInsets.all(BaycelSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader(Icons.person_outline, 'Personal Info'),
                IconButton(
                  onPressed: () {
                    setState(() => _isEditing = !_isEditing);
                  },
                  icon: Icon(_isEditing ? Icons.close : Icons.edit_outlined, color: BaycelColors.crimson, size: 20),
                  tooltip: _isEditing ? 'Cancel' : 'Edit',
                ),
              ],
            ),
            SizedBox(height: BaycelSpacing.md),
            Center(
              child: Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: BaycelColors.crimson.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials.length > 2 ? initials.substring(0, 2) : initials,
                    style: BaycelTypography.headline.copyWith(color: BaycelColors.crimson),
                  ),
                ),
              ),
            ),
            SizedBox(height: BaycelSpacing.sm),
            Center(
              child: BaycelPill(
                label: _getRoleLabel(_user!.role.value),
                color: BaycelColors.crimson,
              ),
            ),
            SizedBox(height: BaycelSpacing.md),
            _isEditing
              ? _buildEditableRow(Icons.person_outline, 'Name', nameController, showBorder: true)
              : _buildInfoRow(Icons.person_outline, 'Name', _user!.name),
            _buildInfoRow(Icons.email_outlined, 'Email', _user!.email),
            if (_user!.role == UserRole.merchandiser)
              _buildInfoRow(Icons.inventory_2_outlined, 'Assigned Products', '${_user!.assignedProducts.length} products', showBorder: false),
            if (_user!.role != UserRole.merchandiser)
              SizedBox(height: BaycelSpacing.sm),
            if (_isEditing) ...[
              SizedBox(height: BaycelSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: BaycelComponents.buttonPrimary,
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Name is required'), backgroundColor: BaycelColors.error));
                      return;
                    }
                    if (name.length < 2) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Name must be at least 2 characters'), backgroundColor: BaycelColors.error));
                      return;
                    }
                    _saveUserName(name);
                    setState(() => _isEditing = false);
                  },
                  child: Text('Save Name'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityCard() {
    return Container(
      decoration: BaycelComponents.card,
      child: Padding(
        padding: EdgeInsets.all(BaycelSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.lock_outline, 'Security'),
            SizedBox(height: BaycelSpacing.md),
            InkWell(
              onTap: _showChangePasswordDialog,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: BaycelSpacing.sm),
                child: Row(
                  children: [
                    Icon(Icons.key_outlined, size: 16, color: BaycelColors.textMuted),
                    SizedBox(width: BaycelSpacing.sm),
                    Text('Change Password', style: BaycelTypography.body.copyWith(fontWeight: FontWeight.w600)),
                    Spacer(),
                    Icon(Icons.chevron_right, size: 20, color: BaycelColors.textMuted),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsCard(String role) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PermissionsScreen(role: role)),
      ),
      child: Container(
        decoration: BaycelComponents.card,
        padding: EdgeInsets.all(BaycelSpacing.base),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: BaycelColors.crimson.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(BaycelRadius.md),
              ),
              child: Icon(Icons.security_outlined, color: BaycelColors.crimson, size: 20),
            ),
            SizedBox(width: BaycelSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('App Permissions', style: BaycelTypography.headlineMd.copyWith(fontSize: 15)),
                  SizedBox(height: BaycelSpacing.xxs),
                  Text('Manage camera and notification permissions',
                    style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: BaycelColors.textMuted),
          ],
        ),
      ),
    );
  }
}
