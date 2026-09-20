import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/animated_widgets.dart';
import '../models/user.dart';
import '../models/product.dart';
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
  String? _currentUserId;

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
  final _db = FirebaseFirestore.instance;

  List<StoreUser> _allUsers = [];
  List<StoreUser> _displayedUsers = [];
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _isLoadingPage = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadInitialUsers();
  }

  void _loadCurrentUser() async {
    final user = await _firestore.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _currentUserRole = user.role;
        _currentUserId = user.uid;
      });
    }
  }

  Future<void> _loadInitialUsers() async {
    setState(() => _isLoadingPage = true);
    final snap = await _db.collection('users').limit(20).get();
    final users = snap.docs.map((d) => StoreUser.fromMap(d.id, d.data())).toList();
    _lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
    _hasMore = snap.docs.length >= 20;
    _applyFilters(users);
    setState(() => _isLoadingPage = false);
  }

  Future<void> _loadMoreUsers() async {
    if (_lastDoc == null || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    final snap = await _db.collection('users').startAfterDocument(_lastDoc!).limit(20).get();
    final more = snap.docs.map((d) => StoreUser.fromMap(d.id, d.data())).toList();
    _allUsers.addAll(more);
    _lastDoc = snap.docs.isNotEmpty ? snap.docs.last : _lastDoc;
    _hasMore = snap.docs.length >= 20;
    _applyFilters(_allUsers);
    setState(() => _isLoadingMore = false);
  }

  void _applyFilters(List<StoreUser> users) {
    List<StoreUser> filtered;
    if (_currentUserRole == UserRole.owner) {
      filtered = users.where((u) => u.role != UserRole.owner).toList();
    } else if (_currentUserRole == UserRole.manager) {
      filtered = users.where((u) =>
        u.uid == _currentUserId ||
        (u.role != UserRole.owner && u.role != UserRole.manager)
      ).toList();
    } else {
      filtered = users.where((u) => u.role != UserRole.owner).toList();
    }
    if (_selectedRole != null) {
      filtered = filtered.where((u) => u.role == _selectedRole).toList();
    }
    _displayedUsers = filtered;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPage) {
      return const Center(child: SkeletonTable(rows: 6));
    }

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
              return _buildGrid(_displayedUsers, columns);
            },
          ),
          if (_hasMore)
            Padding(
              padding: EdgeInsets.symmetric(vertical: BaycelSpacing.base),
              child: Center(
                child: _isLoadingMore
                    ? SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: BaycelColors.crimson))
                    : GestureDetector(
                        onTap: _loadMoreUsers,
                        child: Text('Load More',
                          style: BaycelTypography.bodySm.copyWith(
                            color: BaycelColors.crimson, fontWeight: FontWeight.w600)),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final count = _displayedUsers.length;
    final canAdd = _currentUserRole == UserRole.owner || _currentUserRole == UserRole.manager;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Employees', style: BaycelTypography.display),
            SizedBox(height: BaycelSpacing.xxs),
            Text('$count team members',
              style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textSecondary, fontSize: 12.5)),
          ],
        ),
        if (canAdd)
          ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Add Employee'),
            style: BaycelComponents.buttonPrimary,
          ),
      ],
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
          onSelected: (_) {
            setState(() => _selectedRole = role);
            _applyFilters(_allUsers);
            setState(() {});
          },
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
      itemBuilder: (context, index) {
        final user = users[index];
        bool canEdit = false;
        if (_currentUserRole == UserRole.owner) {
          canEdit = user.role != UserRole.owner;
        } else if (_currentUserRole == UserRole.manager) {
          canEdit = user.uid != _currentUserId && user.role != UserRole.owner && user.role != UserRole.manager;
        }
        return StaggeredItem(
          index: index,
          child: _EmployeeCard(
            user: user,
            roleColor: _roleColor(user.role),
            roleLabel: _roleLabel(user.role),
            initials: _initials(user.name),
            canEdit: canEdit,
          ),
        );
      },
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
    int selectedPayday = (user.payday == 7 || user.payday == 15) ? user.payday : 7;
    UserRole selectedRole = [UserRole.manager, UserRole.cashier, UserRole.bagger, UserRole.bodegero, UserRole.deliveryChecker, UserRole.merchandiser].contains(user.role) ? user.role : UserRole.cashier;
    String scheduleStart = user.schedule.start;
    String scheduleEnd = user.schedule.end;
    List<String> selectedProducts = List.from(user.assignedProducts);
    final firestore = FirestoreService();
    final formKey = GlobalKey<FormState>();

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

    TimeOfDay _parseTime(String s) {
      final parts = s.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    String _formatTime(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    Widget _timePickerButton(BuildContext ctx, StateSetter setDialogState, String time, ValueChanged<String> onPicked) {
      return GestureDetector(
        onTap: () async {
          final current = _parseTime(time);
          final picked = await showTimePicker(context: ctx, initialTime: current);
          if (picked != null) {
            setDialogState(() => onPicked(_formatTime(picked)));
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: BaycelSpacing.md),
          decoration: BoxDecoration(color: BaycelColors.card, border: Border.all(color: BaycelColors.divider), borderRadius: BorderRadius.circular(BaycelRadius.md)),
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

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Edit ${user.name}'),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Account'),
                    _label('Name'),
                    TextFormField(
                      controller: nameController,
                      style: BaycelTypography.body.copyWith(fontSize: 13),
                      decoration: _fieldDeco('Full name'),
                      maxLength: 100,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Name is required';
                        if (v.trim().length < 2) return 'Name must be at least 2 characters';
                        return null;
                      },
                    ),
                    SizedBox(height: BaycelSpacing.sm),
                    _label('Email'),
                    TextFormField(
                      controller: emailController,
                      style: BaycelTypography.body.copyWith(fontSize: 13),
                      decoration: _fieldDeco('Email address'),
                      keyboardType: TextInputType.emailAddress,
                      maxLength: 100,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())) return 'Enter a valid email';
                        return null;
                      },
                    ),
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
                    if (user.role != UserRole.owner) ...[
                      if (selectedRole == UserRole.merchandiser) ...[
                        _sectionTitle('Product Assignment'),
                        _label('Select assigned products'),
                        StreamBuilder<List<Product>>(
                          stream: firestore.getProducts(),
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
                                    final isSelected = selectedProducts.contains(product.id);
                                    return CheckboxListTile(
                                      value: isSelected,
                                      onChanged: (v) {
                                        setDialogState(() {
                                          if (v == true) {
                                            selectedProducts.add(product.id);
                                          } else {
                                            selectedProducts.remove(product.id);
                                          }
                                        });
                                      },
                                      title: Text(product.name, style: BaycelTypography.bodySm.copyWith(fontSize: 12.5)),
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
                        Text('${selectedProducts.length} products selected',
                          style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textMuted, fontSize: 11)),
                      ] else ...[
                        _sectionTitle('Employment'),
                        _label('Hourly Rate (₱)'),
                        TextFormField(
                          controller: rateController,
                          style: BaycelTypography.body.copyWith(fontSize: 13),
                          decoration: _fieldDeco('e.g. 75'),
                          keyboardType: TextInputType.number,
                          maxLength: 10,
                          onChanged: (v) => setDialogState(() {}),
                          validator: (v) {
                            if (v == null || v.isEmpty) return null;
                            final rate = double.tryParse(v);
                            if (rate == null) return 'Enter a valid number';
                            if (rate <= 0) return 'Rate must be greater than 0';
                            if (rate > 1000) return 'Max ₱1,000/hr lang po';
                            return null;
                          },
                        ),
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
                                DropdownMenuItem(value: 7, child: Text('Every 7th')),
                                DropdownMenuItem(value: 15, child: Text('Every 15th')),
                              ],
                              onChanged: (v) => setDialogState(() => selectedPayday = v ?? 7),
                            ),
                          ),
                        ),
                      ],
                    ],
                    _sectionTitle('Schedule'),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Start'),
                              _timePickerButton(ctx, setDialogState, scheduleStart, (t) => scheduleStart = t),
                            ],
                          ),
                        ),
                        SizedBox(width: BaycelSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('End'),
                              _timePickerButton(ctx, setDialogState, scheduleEnd, (t) => scheduleEnd = t),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
                if (!formKey.currentState!.validate()) return;
                if (scheduleStart.isNotEmpty && scheduleEnd.isNotEmpty) {
                  final startParts = scheduleStart.split(':');
                  final endParts = scheduleEnd.split(':');
                  final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
                  final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
                  if (endMin <= startMin) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('End time must be after start time'), backgroundColor: BaycelColors.error),
                    );
                    return;
                  }
                }
                final rate = double.tryParse(rateController.text) ?? 0;
                try {
                  await firestore.updateUser(user.uid, {
                    'name': nameController.text.trim(),
                    'email': emailController.text.trim(),
                    'role': selectedRole.value,
                    'rate': rate,
                    'payday': selectedPayday,
                    'schedule': {'start': scheduleStart, 'end': scheduleEnd},
                    'assignedProducts': selectedRole == UserRole.merchandiser ? selectedProducts : [],
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
