import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/animated_widgets.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
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
                        style: BaycelTypography.bodyMd.copyWith(fontWeight: FontWeight.w600),
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
                          style: BaycelTypography.labelXs.copyWith(color: roleColor, fontWeight: FontWeight.w600),
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
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final rateController = TextEditingController(text: user.rate > 0 ? user.rate.toStringAsFixed(0) : '');
    int selectedPayday = user.payday;
    UserRole selectedRole = user.role;
    String scheduleStart = user.schedule.start;
    String scheduleEnd = user.schedule.end;
    final firestore = FirestoreService();

    InputDecoration _fieldDeco(String hint) => BaycelComponents.input.copyWith(
      hintText: hint,
      filled: true,
      fillColor: BaycelColors.card,
      contentPadding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 10),
    );

    Widget _label(String text) => Padding(
      padding: EdgeInsets.only(bottom: BaycelSpacing.xxs),
      child: Text(text, style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textSecondary, fontSize: 11)),
    );

    Widget _sectionTitle(String text) => Padding(
      padding: EdgeInsets.only(top: BaycelSpacing.md, bottom: BaycelSpacing.xs),
      child: Text(text, style: BaycelTypography.labelSm.copyWith(
        color: BaycelColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.05)),
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Edit ${user.name}'),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Account'),
                  _label('Name'),
                  TextField(controller: nameController, style: BaycelTypography.body.copyWith(fontSize: 13), decoration: _fieldDeco('Full name')),
                  SizedBox(height: BaycelSpacing.sm),
                  _label('Email'),
                  TextField(controller: emailController, style: BaycelTypography.body.copyWith(fontSize: 13), decoration: _fieldDeco('Email address'), keyboardType: TextInputType.emailAddress),
                  SizedBox(height: BaycelSpacing.sm),
                  _label('Role'),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base),
                    decoration: BoxDecoration(color: BaycelColors.card, border: Border.all(color: BaycelColors.divider), borderRadius: BorderRadius.circular(BaycelRadius.md)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<UserRole>(
                        value: selectedRole,
                        isExpanded: true,
                        style: BaycelTypography.body.copyWith(fontSize: 13),
                        dropdownColor: BaycelColors.card,
                        items: const [
                          DropdownMenuItem(value: UserRole.manager, child: Text('Manager')),
                          DropdownMenuItem(value: UserRole.cashier, child: Text('Cashier')),
                          DropdownMenuItem(value: UserRole.bagger, child: Text('Bagger')),
                          DropdownMenuItem(value: UserRole.bodegero, child: Text('Bodegero')),
                          DropdownMenuItem(value: UserRole.deliveryChecker, child: Text('Delivery Checker')),
                          DropdownMenuItem(value: UserRole.merchandiser, child: Text('Merchandiser')),
                        ],
                        onChanged: (v) => setDialogState(() { if (v != null) selectedRole = v; }),
                      ),
                    ),
                  ),
                  _sectionTitle('Employment'),
                  _label('Hourly Rate (₱)'),
                  TextField(controller: rateController, style: BaycelTypography.body.copyWith(fontSize: 13), decoration: _fieldDeco('e.g. 75'), keyboardType: TextInputType.number),
                  SizedBox(height: BaycelSpacing.sm),
                  _label('Payday'),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base),
                    decoration: BoxDecoration(color: BaycelColors.card, border: Border.all(color: BaycelColors.divider), borderRadius: BorderRadius.circular(BaycelRadius.md)),
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
                  _sectionTitle('Schedule'),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Start'),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base),
                              decoration: BoxDecoration(color: BaycelColors.card, border: Border.all(color: BaycelColors.divider), borderRadius: BorderRadius.circular(BaycelRadius.md)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: scheduleStart,
                                  isExpanded: true,
                                  style: BaycelTypography.body.copyWith(fontSize: 13),
                                  dropdownColor: BaycelColors.card,
                                  items: List.generate(24, (i) => DropdownMenuItem(
                                    value: '${i.toString().padLeft(2, '0')}:00',
                                    child: Text('${i.toString().padLeft(2, '0')}:00'),
                                  )),
                                  onChanged: (v) => setDialogState(() => scheduleStart = v ?? scheduleStart),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: BaycelSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('End'),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base),
                              decoration: BoxDecoration(color: BaycelColors.card, border: Border.all(color: BaycelColors.divider), borderRadius: BorderRadius.circular(BaycelRadius.md)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: scheduleEnd,
                                  isExpanded: true,
                                  style: BaycelTypography.body.copyWith(fontSize: 13),
                                  dropdownColor: BaycelColors.card,
                                  items: List.generate(24, (i) => DropdownMenuItem(
                                    value: '${i.toString().padLeft(2, '0')}:00',
                                    child: Text('${i.toString().padLeft(2, '0')}:00'),
                                  )),
                                  onChanged: (v) => setDialogState(() => scheduleEnd = v ?? scheduleEnd),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final confirmDelete = await showDialog<bool>(
                  context: ctx,
                  builder: (dCtx) => AlertDialog(
                    title: Text('Delete ${user.name}?'),
                    content: Text('This will permanently remove ${user.name} from the system. This cannot be undone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(dCtx, false), child: Text('Cancel')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(dCtx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: BaycelColors.error),
                        child: Text('Delete', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (confirmDelete != true) return;
                try {
                  await firestore.deleteUser(user.uid);
                  await AuthService().deleteUser(user.uid);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('${user.name} deleted')),
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
              child: Text('Delete', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.error)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await firestore.updateUser(user.uid, {
                    'name': nameController.text.trim(),
                    'email': emailController.text.trim(),
                    'role': selectedRole.value,
                    'rate': double.tryParse(rateController.text) ?? 0,
                    'payday': selectedPayday,
                    'schedule': {'start': scheduleStart, 'end': scheduleEnd},
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
