import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/animated_widgets.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';
import 'register_screen.dart';

class EmployeeScreen extends StatefulWidget {
  const EmployeeScreen({super.key});

  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  UserRole? _selectedRole;
  UserRole? _currentUserRole;

  static const _filterRoles = <UserRole?>[
    null,
    UserRole.manager,
    UserRole.cashier,
    UserRole.bagger,
    UserRole.bodegero,
    UserRole.deliveryChecker,
    UserRole.merchandiser,
  ];

  static const _filterLabels = <String>[
    'All',
    'Manager',
    'Cashier',
    'Bagger',
    'Bodegero',
    'Delivery Checker',
    'Merchandiser',
  ];

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.owner:
      case UserRole.manager:
        return BaycelColors.crimson;
      case UserRole.cashier:
        return BaycelColors.blue;
      case UserRole.bagger:
        return const Color(0xFF7B1FA2);
      case UserRole.bodegero:
        return BaycelColors.marigoldDark;
      case UserRole.deliveryChecker:
        return const Color(0xFF0D47A1);
      case UserRole.merchandiser:
        return BaycelColors.success;
    }
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.manager:
        return 'Manager';
      case UserRole.cashier:
        return 'Cashier';
      case UserRole.bagger:
        return 'Bagger';
      case UserRole.bodegero:
        return 'Bodegero';
      case UserRole.deliveryChecker:
        return 'Delivery Checker';
      case UserRole.merchandiser:
        return 'Merchandiser';
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  final _firestore = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  void _loadCurrentUser() async {
    final user = await _firestore.getCurrentUser();
    if (user != null && mounted) {
      setState(() => _currentUserRole = user.role);
    }
  }

  Stream<List<StoreUser>> _usersStream() {
    return _firestore.getUsers();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StoreUser>>(
      stream: _usersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: SkeletonTable(rows: 6));
        }

        final allUsers = snapshot.data ?? [];
        final filtered = _selectedRole == null
            ? allUsers
            : allUsers.where((u) => u.role == _selectedRole).toList();

        return SingleChildScrollView(
          padding: EdgeInsets.all(BaycelSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: BaycelSpacing.lg),
              _buildFilterChips(),
              SizedBox(height: BaycelSpacing.lg),
              LayoutBuilder(
                builder: (context, constraints) {
                  int columns;
                  if (constraints.maxWidth > 1024) {
                    columns = 3;
                  } else if (constraints.maxWidth > 600) {
                    columns = 2;
                  } else {
                    columns = 1;
                  }
                  return _buildGrid(filtered, columns);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return StreamBuilder<List<StoreUser>>(
      stream: _usersStream(),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Employees', style: BaycelTypography.display),
                SizedBox(height: BaycelSpacing.xxs),
                Text('$count team members across 7 roles',
                  style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textSecondary, fontSize: 12.5)),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Add Employee'),
              style: BaycelComponents.buttonPrimary,
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: BaycelSpacing.sm,
      runSpacing: BaycelSpacing.sm,
      children: List.generate(_filterRoles.length, (index) {
        final role = _filterRoles[index];
        final selected = _selectedRole == role;
        return ChoiceChip(
          label: Text(_filterLabels[index]),
          selected: selected,
          onSelected: (_) => setState(() => _selectedRole = role),
          selectedColor: BaycelColors.crimson,
          backgroundColor: BaycelColors.card,
          labelStyle: BaycelTypography.labelSm.copyWith(
            color: selected ? Colors.white : BaycelColors.textPrimary,
          ),
          side: BorderSide(
            color: selected ? BaycelColors.crimson : BaycelColors.divider,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BaycelRadius.full),
          ),
          showCheckmark: false,
        );
      }),
    );
  }

  Widget _buildGrid(List<StoreUser> users, int columns) {
    if (users.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(BaycelSpacing.xxl),
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 48, color: BaycelColors.textDisabled),
              SizedBox(height: BaycelSpacing.md),
              Text('No employees found', style: BaycelTypography.body.copyWith(color: BaycelColors.textMuted)),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: BaycelSpacing.md,
        mainAxisSpacing: BaycelSpacing.md,
        childAspectRatio: 2.8,
      ),
      itemCount: users.length,
      itemBuilder: (context, index) => StaggeredItem(
        index: index,
        child: _EmployeeCard(
          user: users[index],
          roleColor: _roleColor(users[index].role),
          roleLabel: _roleLabel(users[index].role),
          initials: _initials(users[index].name),
          canEdit: _currentUserRole == UserRole.owner || _currentUserRole == UserRole.manager,
        ),
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final StoreUser user;
  final Color roleColor;
  final String roleLabel;
  final String initials;
  final bool canEdit;

  const _EmployeeCard({
    required this.user,
    required this.roleColor,
    required this.roleLabel,
    required this.initials,
    this.canEdit = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canEdit ? () => _showEditDialog(context) : null,
      child: Container(
        padding: EdgeInsets.all(BaycelSpacing.base),
        decoration: BaycelComponents.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: roleColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: BaycelTypography.title.copyWith(color: Colors.white, fontSize: 14),
                  ),
                ),
                SizedBox(width: BaycelSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: BaycelTypography.body.copyWith(fontWeight: FontWeight.w600, fontSize: 13.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 3),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: BaycelSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(BaycelRadius.lg),
                        ),
                        child: Text(
                          roleLabel,
                          style: BaycelTypography.labelSm.copyWith(color: roleColor, fontSize: 10.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                if (canEdit)
                  Icon(Icons.chevron_right, color: BaycelColors.textDisabled, size: 20),
              ],
            ),
            SizedBox(height: BaycelSpacing.sm),
            Row(
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(color: BaycelColors.success, shape: BoxShape.circle),
                ),
                SizedBox(width: 5),
                Text('Active', style: BaycelTypography.bodySm.copyWith(fontSize: 11, color: BaycelColors.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final rateController = TextEditingController(text: user.rate > 0 ? user.rate.toStringAsFixed(2) : '');
    int selectedPayday = user.payday;
    final firestore = FirestoreService();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Edit ${user.name}'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hourly Rate (\u20B1)', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textSecondary, fontSize: 12)),
                SizedBox(height: BaycelSpacing.xs),
                TextField(
                  controller: rateController,
                  keyboardType: TextInputType.number,
                  style: BaycelTypography.body.copyWith(fontSize: 13),
                  decoration: InputDecoration(
                    filled: true, fillColor: BaycelColors.card, hintText: '0.00',
                    contentPadding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(BaycelRadius.md), borderSide: BorderSide(color: BaycelColors.divider)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(BaycelRadius.md), borderSide: BorderSide(color: BaycelColors.divider)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(BaycelRadius.md), borderSide: BorderSide(color: BaycelColors.crimson, width: 2)),
                  ),
                ),
                SizedBox(height: BaycelSpacing.base),
                Text('Payday', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textSecondary, fontSize: 12)),
                SizedBox(height: BaycelSpacing.xs),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base),
                  decoration: BoxDecoration(
                    color: BaycelColors.card,
                    border: Border.all(color: BaycelColors.divider),
                    borderRadius: BorderRadius.circular(BaycelRadius.md),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: selectedPayday,
                      isExpanded: true,
                      style: BaycelTypography.body.copyWith(fontSize: 13),
                      dropdownColor: BaycelColors.card,
                      items: const [
                        DropdownMenuItem(value: 15, child: Text('Every 15th')),
                        DropdownMenuItem(value: 30, child: Text('Every 30th (End of month)')),
                      ],
                      onChanged: (v) => setDialogState(() => selectedPayday = v ?? 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                final rate = double.tryParse(rateController.text.trim()) ?? 0;
                try {
                  await firestore.updateUser(user.uid, {
                    'rate': rate,
                    'payday': selectedPayday,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('${user.name} updated')),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: BaycelColors.error),
                    );
                  }
                }
              },
              style: BaycelComponents.buttonPrimary,
              child: Text('Save', style: BaycelTypography.label.copyWith(color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
