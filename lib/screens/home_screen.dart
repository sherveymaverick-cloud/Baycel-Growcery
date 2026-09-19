import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../widgets/app_notification.dart';
import 'login_screen.dart';
import 'owner_dashboard.dart';
import 'manager_dashboard.dart';
import 'floor_staff_dashboard.dart';
import 'inventory_screen.dart';
import 'delivery_screen.dart';
import 'attendance_screen.dart';
import 'employee_screen.dart';
import 'payroll_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _currentRole = 'cashier';
  String _userName = 'User';
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  late List<NavigationItem> _navItems = [];
  String _cachedRole = '';
  final _session = SessionService();
  final Map<int, Widget> _pageCache = {};

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _loadSession() async {
    final session = await _session.loadSession();
    if (session != null && mounted) {
      setState(() {
        _currentRole = session['role']!;
        _userName = session['name']!;
        _navItems = _getNavItemsForRole(_currentRole);
        _cachedRole = _currentRole;
      });
    }
    _fetchRoleFromFirestore();
  }

  void _fetchRoleFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (!mounted) return;
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final role = data['role'] as String? ?? 'cashier';
          final name = data['name'] as String? ?? user.email?.split('@').first ?? 'User';
          final email = user.email ?? '';
          await _session.saveSession(uid: user.uid, role: role, name: name, email: email);
          if (!mounted) return;
          setState(() {
            _currentRole = role;
            _userName = name;
            if (_cachedRole != role) {
              _navItems = _getNavItemsForRole(role);
              _cachedRole = role;
            }
          });
        }
      } catch (_) {
        if (!mounted) return;
        final email = user.email ?? '';
        if (email.contains('owner')) {
          setState(() => _currentRole = 'owner');
        } else if (email.contains('manager')) {
          setState(() => _currentRole = 'manager');
        }
        final name = email.split('@').first;
        setState(() {
          _userName = name;
          _navItems = _getNavItemsForRole(_currentRole);
          _cachedRole = _currentRole;
        });
      }
    }
  }

  List<NavigationItem> _getNavItemsForRole(String role) {
    switch (role) {
      case 'owner':
        return [
          NavigationItem(icon: Icons.dashboard, label: 'Dashboard', page: const OwnerDashboard()),
          NavigationItem(icon: Icons.inventory_2, label: 'Inventory', page: const InventoryScreen()),
          NavigationItem(icon: Icons.local_shipping, label: 'Deliveries', page: const DeliveryScreen()),
          NavigationItem(icon: Icons.access_time, label: 'Attendance', page: const AttendanceScreen()),
          NavigationItem(icon: Icons.people, label: 'Employees', page: const EmployeeScreen()),
          NavigationItem(icon: Icons.payments, label: 'Payroll', page: const PayrollScreen()),
          NavigationItem(icon: Icons.assessment, label: 'Reports', page: const ReportsScreen()),
          NavigationItem(icon: Icons.settings, label: 'Settings', page: const SettingsScreen()),
        ];
      case 'manager':
        return [
          NavigationItem(icon: Icons.dashboard, label: 'Dashboard', page: const ManagerDashboard()),
          NavigationItem(icon: Icons.inventory_2, label: 'Inventory', page: const InventoryScreen()),
          NavigationItem(icon: Icons.local_shipping, label: 'Deliveries', page: const DeliveryScreen()),
          NavigationItem(icon: Icons.access_time, label: 'Attendance', page: const AttendanceScreen()),
          NavigationItem(icon: Icons.people, label: 'Employees', page: const EmployeeScreen()),
          NavigationItem(icon: Icons.assessment, label: 'Reports', page: const ReportsScreen()),
        ];
      default:
        final cacheKey = 'floor_$role'.hashCode;
        _pageCache.putIfAbsent(cacheKey, () => FloorStaffDashboard(role: role));
        final dashboard = _pageCache[cacheKey]!;
        final items = [
          NavigationItem(icon: Icons.home, label: 'Home', page: dashboard),
          NavigationItem(icon: Icons.access_time, label: 'Attendance', page: const AttendanceScreen()),
          NavigationItem(icon: Icons.person, label: 'Profile', page: const ProfileScreen()),
          NavigationItem(icon: Icons.settings, label: 'Settings', page: const SettingsScreen()),
        ];
        if (role == 'delivery_checker' || role == 'merchandiser' || role == 'bodegero') {
          items.insert(1, NavigationItem(icon: Icons.inventory_2, label: 'Inventory', page: const InventoryScreen()));
        }
        if (role == 'delivery_checker' || role == 'bodegero') {
          items.insert(2, NavigationItem(icon: Icons.local_shipping, label: 'Deliveries', page: const DeliveryScreen()));
        }
        return items;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_navItems.isEmpty) {
      _navItems = _getNavItemsForRole(_currentRole);
    }
    if (_currentIndex >= _navItems.length) _currentIndex = 0;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: BaycelColors.surface,
      body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(child: _navItems[_currentIndex].page),
        NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          destinations: _navItems.map((item) => NavigationDestination(icon: Icon(item.icon), label: item.label)).toList(),
          backgroundColor: BaycelColors.card,
          indicatorColor: BaycelColors.crimsonWithAlpha,
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return BaycelTypography.labelSm.copyWith(color: BaycelColors.crimson, fontSize: 11);
            }
            return BaycelTypography.labelSm.copyWith(color: BaycelColors.textMuted, fontSize: 11);
          }),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Container(
          width: 256,
          decoration: BoxDecoration(
            color: BaycelColors.card,
            boxShadow: [const BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.04), blurRadius: 8, offset: Offset(1, 0))],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [BaycelColors.crimson, BaycelColors.crimsonDark],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, boxShadow: [const BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.04), blurRadius: 8, offset: Offset(1, 0))]),
                          child: ClipOval(child: Image.asset('assets/images/store-logo.jpg', fit: BoxFit.cover, width: 34, height: 34)),
                        ),
                        SizedBox(width: BaycelSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Baycel Growcery', style: BaycelTypography.titleLg.copyWith(color: Colors.white)),
                              Text('Store Management', style: BaycelTypography.labelSm.copyWith(color: Colors.white.withValues(alpha: 0.75), fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: BaycelSpacing.base),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: Text(_userName.substring(0, 1).toUpperCase(), style: BaycelTypography.label.copyWith(color: Colors.white, fontSize: 13)),
                        ),
                        SizedBox(width: BaycelSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_userName, style: BaycelTypography.bodyMd.copyWith(color: Colors.white)),
                              Container(
                                margin: const EdgeInsets.only(top: 3),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(BaycelRadius.lg)),
                                child: Text(_currentRole[0].toUpperCase() + _currentRole.substring(1), style: BaycelTypography.labelSm.copyWith(color: Colors.white, fontSize: 10)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  itemCount: _navItems.length,
                  itemBuilder: (context, index) {
                    final item = _navItems[index];
                    final isSelected = index == _currentIndex;
                    return _SidebarTile(
                      icon: item.icon,
                      label: item.label,
                      isSelected: isSelected,
                      onTap: () => setState(() => _currentIndex = index),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: BaycelColors.divider.withValues(alpha: 0.5)))),
                child: GestureDetector(
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Log out?', style: BaycelTypography.title),
                        content: Text('You will be returned to the login screen.',
                          style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textSecondary)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: Text('Cancel', style: BaycelTypography.label.copyWith(color: BaycelColors.textSecondary)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: Text('Log out', style: BaycelTypography.label.copyWith(color: BaycelColors.error, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true) return;
                    try {
                      await _session.clearSession();
                      await AuthService().signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Unable to log out. Please try again.'), backgroundColor: BaycelColors.error),
                        );
                      }
                    }
                  },
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 17, color: BaycelColors.error),
                      SizedBox(width: BaycelSpacing.sm),
                      Text('Log out', style: BaycelTypography.body.copyWith(color: BaycelColors.error, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              _buildTopbar(),
              Expanded(child: _navItems[_currentIndex].page),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopbar() {
    final now = DateTime.now();
    const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    final dateStr = '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: BaycelColors.card,
        borderRadius: BorderRadius.circular(BaycelRadius.lg),
        boxShadow: [const BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.04), blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 360),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: BaycelColors.surface,
                borderRadius: BorderRadius.circular(BaycelRadius.md),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 16, color: BaycelColors.textDisabled),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      style: BaycelTypography.body.copyWith(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search products, employees, suppliers\u2026',
                        hintStyle: BaycelTypography.body.copyWith(color: BaycelColors.textDisabled, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (query) => _handleSearch(query),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 16),
          Text(dateStr, style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textMuted, fontSize: 12)),
          SizedBox(width: 16),
          NotificationBell(),
        ],
      ),
    );
  }

  void _handleSearch(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return;

    final labels = _navItems.map((item) => item.label.toLowerCase()).toList();
    for (int i = 0; i < labels.length; i++) {
      if (labels[i].contains(q) || q.contains(labels[i])) {
        setState(() => _currentIndex = i);
        _searchController.clear();
        _searchFocusNode.unfocus();
        return;
      }
    }

    final keywords = {
      'product': 1,
      'stock': 1,
      'item': 1,
      'inventory': 1,
      'delivery': 2,
      'supplier': 2,
      'receive': 2,
      'shipping': 2,
      'attendance': 3,
      'clock': 3,
      'shift': 3,
      'employee': 4,
      'staff': 4,
      'payroll': 5,
      'salary': 5,
      'pay': 5,
      'report': 6,
      'analytics': 6,
      'chart': 6,
      'setting': 7,
      'profile': 8,
    };

    for (final entry in keywords.entries) {
      if (q.contains(entry.key)) {
        final idx = entry.value.clamp(0, _navItems.length - 1);
        setState(() => _currentIndex = idx);
        _searchController.clear();
        _searchFocusNode.unfocus();
        return;
      }
    }

    _searchController.clear();
    _searchFocusNode.unfocus();
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final Widget page;
  NavigationItem({required this.icon, required this.label, required this.page});
}

class _SidebarTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarTile({required this.icon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: isSelected ? BaycelColors.crimsonWithAlpha : Colors.transparent,
        borderRadius: BorderRadius.circular(BaycelRadius.xl),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(BaycelRadius.xl),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(BaycelRadius.xl),
              border: Border(left: BorderSide(color: isSelected ? BaycelColors.crimson : Colors.transparent, width: 4)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: isSelected ? BaycelColors.crimson : BaycelColors.textMuted),
                SizedBox(width: 11),
                Text(label, style: BaycelTypography.body.copyWith(
                  color: isSelected ? BaycelColors.crimson : BaycelColors.textMuted,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopbarIconBtn extends StatefulWidget {
  final IconData icon;
  final bool hasBadge;
  final VoidCallback onTap;
  final String? tooltip;

  const _TopbarIconBtn({required this.icon, required this.hasBadge, required this.onTap, this.tooltip});

  @override
  State<_TopbarIconBtn> createState() => _TopbarIconBtnState();
}

class _TopbarIconBtnState extends State<_TopbarIconBtn> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final btn = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) {
          _scaleController.forward();
          setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          _scaleController.reverse();
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () {
          _scaleController.reverse();
          setState(() => _isPressed = false);
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _isHovered
                  ? BaycelColors.crimson.withValues(alpha: 0.08)
                  : _isPressed
                      ? BaycelColors.crimson.withValues(alpha: 0.14)
                      : BaycelColors.surface,
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: 17,
                  color: _isHovered ? BaycelColors.crimson : BaycelColors.textSecondary,
                ),
                if (widget.hasBadge)
                  Positioned(
                    top: 7, right: 7,
                    child: Container(
                      width: 7, height: 7,
                      decoration: BoxDecoration(
                        color: BaycelColors.crimson,
                        shape: BoxShape.circle,
                        border: Border.all(color: BaycelColors.card, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    return btn;
  }
}
