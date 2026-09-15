import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/animated_widgets.dart';
import '../services/firestore_service.dart';
import '../models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firestore = FirestoreService();
  StoreUser? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    try {
      final user = await _firestore.getCurrentUser();
      if (user != null && mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getRoleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'owner': return 'Owner';
      case 'manager': return 'Manager';
      case 'cashier': return 'Cashier';
      case 'bagger': return 'Bagger';
      case 'bodegero': return 'Bodegero';
      case 'delivery_checker': return 'Delivery Checker';
      case 'merchandiser': return 'Merchandiser';
      default: return 'Staff';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: SkeletonProfile());
    }

    final user = _user;
    final firebaseUser = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      padding: EdgeInsets.all(BaycelSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaggeredItem(
            index: 0,
            child: Text('My Profile', style: BaycelTypography.display),
          ),
          SizedBox(height: BaycelSpacing.lg),
          StaggeredItem(index: 1, child: _buildProfileHeader(user, firebaseUser)),
          SizedBox(height: BaycelSpacing.lg),
          StaggeredItem(index: 2, child: _buildInfoCard(user, firebaseUser)),
          SizedBox(height: BaycelSpacing.lg),
          StaggeredItem(index: 3, child: _buildShiftInfo(user)),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(StoreUser? user, User? firebaseUser) {
    final name = user?.name ?? firebaseUser?.email?.split('@').first ?? 'Staff';
    final role = user?.role.value ?? 'cashier';
    final initials = name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').join('').toUpperCase();

    return Container(
      padding: EdgeInsets.all(BaycelSpacing.lg),
      decoration: BaycelComponents.card,
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: BaycelColors.crimson.withValues(alpha: 0.1),
            child: Text(
              initials.length >= 2 ? initials.substring(0, 2) : initials,
              style: BaycelTypography.headline.copyWith(color: BaycelColors.crimson, fontSize: 22),
            ),
          ),
          SizedBox(width: BaycelSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: BaycelTypography.headline.copyWith(fontSize: 20)),
                SizedBox(height: BaycelSpacing.xxs),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: BaycelColors.crimson.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(BaycelRadius.full),
                  ),
                  child: Text(
                    _getRoleLabel(role),
                    style: BaycelTypography.labelSm.copyWith(color: BaycelColors.crimson, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(StoreUser? user, User? firebaseUser) {
    return Container(
      padding: EdgeInsets.all(BaycelSpacing.base),
      decoration: BaycelComponents.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Account Details', style: BaycelTypography.headlineMd),
          SizedBox(height: BaycelSpacing.md),
          _buildInfoRow(Icons.email_outlined, 'Email', firebaseUser?.email ?? '—'),
          Divider(color: BaycelColors.divider.withValues(alpha: 0.5)),
          _buildInfoRow(Icons.person_outline, 'Full Name', user?.name ?? '—'),
          Divider(color: BaycelColors.divider.withValues(alpha: 0.5)),
          _buildInfoRow(Icons.badge_outlined, 'Role', _getRoleLabel(user?.role.value ?? 'cashier')),
          Divider(color: BaycelColors.divider.withValues(alpha: 0.5)),
          _buildInfoRow(Icons.payments_outlined, 'Hourly Rate', '\u20B1${(user?.rate ?? 0).toStringAsFixed(0)}/hr'),
        ],
      ),
    );
  }

  Widget _buildShiftInfo(StoreUser? user) {
    final assignedCount = user?.assignedProducts.length ?? 0;

    return Container(
      padding: EdgeInsets.all(BaycelSpacing.base),
      decoration: BaycelComponents.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Work Info', style: BaycelTypography.headlineMd),
          SizedBox(height: BaycelSpacing.md),
          _buildInfoRow(Icons.inventory_outlined, 'Assigned Products', '$assignedCount products'),
          Divider(color: BaycelColors.divider.withValues(alpha: 0.5)),
          _buildInfoRow(Icons.access_time, 'Default Shift', '7AM \u2013 3PM'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: BaycelSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: BaycelColors.textSecondary),
          SizedBox(width: BaycelSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textMuted, fontSize: 11)),
                SizedBox(height: 2),
                Text(value, style: BaycelTypography.body.copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
