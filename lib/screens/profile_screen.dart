import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/animated_widgets.dart';
import '../services/firestore_service.dart';
import '../models/user.dart';

class ProfileScreen extends StatefulWidget {
  final StoreUser? targetUser;

  const ProfileScreen({super.key, this.targetUser});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firestore = FirestoreService();
  StoreUser? _user;
  bool _isLoading = true;
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _loadProfile() async {
    try {
      if (widget.targetUser != null) {
        _user = widget.targetUser;
      } else {
        _user = await _firestore.getCurrentUser();
      }
      if (_user != null && mounted) {
        setState(() {
          _nameController.text = _user!.name;
          _emailController.text = _user!.email;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _canEdit() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    if (widget.targetUser == null) return true;
    if (_user?.role == UserRole.owner) return false;
    return true;
  }

  void _saveProfile() async {
    if (_user == null) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Name cannot be empty')));
      return;
    }
    try {
      await _firestore.updateUser(_user!.uid, {'name': name, 'updatedAt': DateTime.now()});
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
        _isEditing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('My Profile', style: BaycelTypography.display),
                if (_canEdit())
                  IconButton(
                    onPressed: () {
                      setState(() => _isEditing = !_isEditing);
                      if (!_isEditing) {
                        _nameController.text = _user?.name ?? '';
                      }
                    },
                    icon: Icon(_isEditing ? Icons.close : Icons.edit_outlined, color: BaycelColors.crimson),
                  ),
              ],
            ),
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
    final isOwner = user?.role == UserRole.owner;
    final canEdit = _canEdit();

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
          _isEditing && canEdit
            ? _buildEditableRow(Icons.person_outline, 'Full Name', _nameController)
            : _buildInfoRow(Icons.person_outline, 'Full Name', user?.name ?? '—'),
          Divider(color: BaycelColors.divider.withValues(alpha: 0.5)),
          _buildInfoRow(Icons.badge_outlined, 'Role', _getRoleLabel(user?.role.value ?? 'cashier')),
          if (!isOwner) ...[
            Divider(color: BaycelColors.divider.withValues(alpha: 0.5)),
            _buildInfoRow(Icons.payments_outlined, 'Hourly Rate', '\u20B1${(user?.rate ?? 0).toStringAsFixed(0)}/hr'),
          ],
          if (_isEditing && canEdit) ...[
            SizedBox(height: BaycelSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: BaycelComponents.buttonPrimary,
                child: Text('Save Changes', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
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

  Widget _buildEditableRow(IconData icon, String label, TextEditingController controller) {
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
                TextField(
                  controller: controller,
                  style: BaycelTypography.body.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(BaycelRadius.md),
                      borderSide: BorderSide(color: BaycelColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(BaycelRadius.md),
                      borderSide: BorderSide(color: BaycelColors.crimson),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
