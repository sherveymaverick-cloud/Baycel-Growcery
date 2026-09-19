import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  int _unreadCount = 0;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: uid)
          .where('read', isEqualTo: false)
          .limit(20)
          .get();

      if (mounted) {
        setState(() {
          _notifications = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
          _unreadCount = _notifications.length;
        });
      }
    } catch (e) {
      debugPrint('Load notifications failed: $e');
    }
  }

  void _markAsRead(String id) async {
    await FirebaseFirestore.instance.collection('notifications').doc(id).update({'read': true});
    setState(() {
      _notifications.removeWhere((n) => n['id'] == id);
      _unreadCount = _notifications.length;
    });
  }

  void _markAllAsRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final n in _notifications) {
      batch.update(FirebaseFirestore.instance.collection('notifications').doc(n['id']), {'read': true});
    }
    await batch.commit();
    setState(() {
      _notifications.clear();
      _unreadCount = 0;
    });
  }

  void _showNotifications() {
    _loadNotifications();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(BaycelRadius.lg)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (ctx, controller) => Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(color: BaycelColors.divider, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: EdgeInsets.all(BaycelSpacing.base),
              child: Row(
                children: [
                  Text('Notifications', style: BaycelTypography.title),
                  Spacer(),
                  if (_notifications.isNotEmpty)
                    TextButton(
                      onPressed: () { _markAllAsRead(); Navigator.pop(ctx); },
                      child: Text('Mark all read', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.viz5)),
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: BaycelColors.divider),
            Expanded(
              child: _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_none, size: 48, color: BaycelColors.textDisabled),
                          SizedBox(height: BaycelSpacing.sm),
                          Text('No notifications', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled)),
                          SizedBox(height: BaycelSpacing.xxs),
                          Text("You're all caught up!", style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textDisabled, fontSize: 11)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: controller,
                      itemCount: _notifications.length,
                      itemBuilder: (ctx, i) {
                        final n = _notifications[i];
                        final type = n['type'] ?? '';
                        final icon = switch (type) {
                          'low_stock' => Icons.warning_amber_rounded,
                          'cash_advance' => Icons.request_quote_outlined,
                          'absence' => Icons.event_busy_outlined,
                          'payroll' => Icons.payments_outlined,
                          _ => Icons.notifications_outlined,
                        };
                        final color = switch (type) {
                          'low_stock' => BaycelColors.marigoldDark,
                          'cash_advance' => BaycelColors.viz5,
                          'absence' => BaycelColors.crimson,
                          'payroll' => BaycelColors.success,
                          _ => BaycelColors.textSecondary,
                        };
                        return ListTile(
                          leading: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, size: 18, color: color),
                          ),
                          title: Text(n['title'] ?? '', style: BaycelTypography.body.copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text(n['body'] ?? '', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textSecondary, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                          trailing: GestureDetector(
                            onTap: () => _markAsRead(n['id']),
                            child: Icon(Icons.close, size: 16, color: BaycelColors.textDisabled),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showNotifications,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_outlined, size: 22, color: BaycelColors.textSecondary),
          if (_unreadCount > 0)
            Positioned(
              top: -4, right: -4,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: BaycelColors.crimson,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _unreadCount > 9 ? '9+' : '$_unreadCount',
                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
