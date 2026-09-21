import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/attendance.dart';
import '../models/user.dart';
import '../theme.dart';
import '../widgets/animated_widgets.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  final _firestore = FirestoreService();
  int _visibleRows = 20;
  static const int _pageSize = 20;

  String get _dateKey {
    final y = _selectedDate.year;
    final m = _selectedDate.month.toString().padLeft(2, '0');
    final d = _selectedDate.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatDateDisplay(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  Widget _buildStatBox(String label, int count, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: BaycelSpacing.md,
        vertical: BaycelSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(BaycelRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count.toString(),
            style: BaycelTypography.display.copyWith(
              fontSize: 20,
              color: color,
            ),
          ),
          SizedBox(height: BaycelSpacing.xxs),
          Text(
            label,
            style: BaycelTypography.labelSm.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AttendanceStatus? status, int lateMinutes) {
    Color bgColor;
    Color fgColor;
    String text;

    switch (status) {
      case AttendanceStatus.complete:
      case AttendanceStatus.verified:
      case AttendanceStatus.present:
        bgColor = BaycelColors.success.withValues(alpha: 0.12);
        fgColor = BaycelColors.success;
        text = 'On Time';
        break;
      case AttendanceStatus.late:
        bgColor = BaycelColors.marigold.withValues(alpha: 0.12);
        fgColor = BaycelColors.marigoldDark;
        text = 'Late ${lateMinutes}m';
        break;
      case AttendanceStatus.inProgress:
        bgColor = BaycelColors.blue.withValues(alpha: 0.12);
        fgColor = BaycelColors.blue;
        text = 'In Progress';
        break;
      case AttendanceStatus.absent:
        bgColor = BaycelColors.error.withValues(alpha: 0.12);
        fgColor = BaycelColors.error;
        text = 'Absent';
        break;
      case AttendanceStatus.onLeave:
        bgColor = BaycelColors.textDisabled.withValues(alpha: 0.12);
        fgColor = BaycelColors.textMuted;
        text = 'On Leave';
        break;
      default:
        bgColor = BaycelColors.textDisabled.withValues(alpha: 0.12);
        fgColor = BaycelColors.textMuted;
        text = status?.value ?? 'Unknown';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: BaycelSpacing.sm,
        vertical: BaycelSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(BaycelRadius.full),
      ),
      child: Text(
        text,
        style: BaycelTypography.labelSm.copyWith(
          color: fgColor,
          fontSize: 11,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AttendanceRecord>>(
      stream: _firestore.getAttendance(),
      builder: (context, attendanceSnapshot) {
        return StreamBuilder<List<StoreUser>>(
          stream: _firestore.getUsers(),
          builder: (context, usersSnapshot) {
            final allRecords = attendanceSnapshot.data ?? [];
            final users = usersSnapshot.data ?? [];

            final userMap = <String, StoreUser>{};
            for (final u in users) {
              userMap[u.uid] = u;
            }

            final todayRecords =
                allRecords.where((r) => r.date == _dateKey).toList();

            final paginatedRecords = todayRecords.take(_visibleRows).toList();
            final hasMore = todayRecords.length > _visibleRows;

            int presentCount = 0;
            int lateCount = 0;
            int absentCount = 0;
            int onLeaveCount = 0;

            for (final r in todayRecords) {
              switch (r.status) {
                case AttendanceStatus.complete:
                case AttendanceStatus.verified:
                case AttendanceStatus.present:
                  presentCount++;
                  break;
                case AttendanceStatus.late:
                  lateCount++;
                  break;
                case AttendanceStatus.absent:
                  absentCount++;
                  break;
                case AttendanceStatus.onLeave:
                  onLeaveCount++;
                  break;
                default:
                  break;
              }
            }

            return SingleChildScrollView(
              padding: EdgeInsets.all(BaycelSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StaggeredItem(index: 0, child: _buildHeader()),
                  SizedBox(height: BaycelSpacing.lg),
                  StaggeredItem(
                    index: 1,
                    child: _buildStatRow(
                        presentCount, lateCount, absentCount, onLeaveCount),
                  ),
                  SizedBox(height: BaycelSpacing.lg),
                  StaggeredItem(
                    index: 2,
                    child: _buildAttendanceTable(paginatedRecords, userMap),
                  ),
                  if (hasMore)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: BaycelSpacing.base),
                      child: Center(
                        child: GestureDetector(
                          onTap: () => setState(() => _visibleRows += _pageSize),
                          child: Text('Load More',
                            style: BaycelTypography.bodySm.copyWith(
                              color: BaycelColors.crimson, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader() {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final dateLabel = '${days[_selectedDate.weekday - 1]}, ${months[_selectedDate.month - 1]} ${_selectedDate.day}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text('Attendance', style: BaycelTypography.display)),
            SizedBox(width: BaycelSpacing.md),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: Icon(Icons.calendar_today, size: 16),
              label: Text(_formatDateDisplay(_selectedDate)),
              style: BaycelComponents.buttonOutlined,
            ),
          ],
        ),
        SizedBox(height: BaycelSpacing.xxs),
        Text('$dateLabel \u00b7 all employees',
          style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textSecondary, fontSize: 12.5)),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: BaycelColors.crimson,
              onPrimary: Colors.white,
              surface: BaycelColors.card,
              onSurface: BaycelColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _visibleRows = _pageSize;
      });
    }
  }

  Widget _buildStatRow(
    int present,
    int late,
    int absent,
    int onLeave,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth < 500;
        if (useTwoColumns) {
          return Column(
            children: [
              Row(children: [
                Expanded(child: _buildStatBox('Present', present, BaycelColors.success)),
                SizedBox(width: BaycelSpacing.sm),
                Expanded(child: _buildStatBox('Late', late, BaycelColors.marigold)),
              ]),
              SizedBox(height: BaycelSpacing.sm),
              Row(children: [
                Expanded(child: _buildStatBox('Absent', absent, BaycelColors.error)),
                SizedBox(width: BaycelSpacing.sm),
                Expanded(child: _buildStatBox('On Leave', onLeave, BaycelColors.textDisabled)),
              ]),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: _buildStatBox('Present', present, BaycelColors.success)),
            SizedBox(width: BaycelSpacing.sm),
            Expanded(child: _buildStatBox('Late', late, BaycelColors.marigold)),
            SizedBox(width: BaycelSpacing.sm),
            Expanded(child: _buildStatBox('Absent', absent, BaycelColors.error)),
            SizedBox(width: BaycelSpacing.sm),
            Expanded(child: _buildStatBox('On Leave', onLeave, BaycelColors.textDisabled)),
          ],
        );
      },
    );
  }

  Widget _buildAttendanceTable(
    List<AttendanceRecord> records,
    Map<String, StoreUser> userMap,
  ) {
    return Container(
      width: double.infinity,
      decoration: BaycelComponents.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(BaycelSpacing.base),
            child: Text('Attendance Log', style: BaycelTypography.headlineMd),
          ),
          Divider(height: 1, color: BaycelColors.divider),
          if (records.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: BaycelSpacing.xl),
              child: Center(
                child: Text('No attendance records for this date.', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textMuted)),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2.5),
                        1: FlexColumnWidth(1.5),
                        2: FlexColumnWidth(1.5),
                        3: FlexColumnWidth(1.5),
                        4: FlexColumnWidth(1.5),
                        5: FlexColumnWidth(1.5),
                        6: FlexColumnWidth(1.5),
                        7: FlexColumnWidth(1.5),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(color: BaycelColors.surface),
                          children: [
                            _buildTh('Employee'),
                            _buildTh('Role'),
                            _buildTh('Time In'),
                            _buildTh('Time Out'),
                            _buildTh('Break In'),
                            _buildTh('Break Out'),
                            _buildTh('Hours'),
                            _buildTh('Status'),
                          ],
                        ),
                        ...records.map((r) {
                          final user = userMap[r.employeeId];
                          return _buildTr(r, user);
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTh(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: BaycelSpacing.sm),
      child: Text(text, style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textSecondary, letterSpacing: 0.03)),
    );
  }

  TableRow _buildTr(AttendanceRecord record, StoreUser? user) {
    final name = user?.name ?? 'Unknown';
    final role = user?.role.value ?? '—';
    final border = Border(bottom: BorderSide(color: BaycelColors.divider.withValues(alpha: 0.5), width: 0.5));

    return TableRow(
      decoration: BoxDecoration(border: border),
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 10),
          child: Text(name, style: BaycelTypography.body.copyWith(fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 10),
          child: Text(role[0].toUpperCase() + role.substring(1).replaceAll('_', ' '), style: BaycelTypography.body.copyWith(color: BaycelColors.textSecondary, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 10),
          child: Text(record.timeIn.isNotEmpty ? record.timeIn : '—', style: BaycelTypography.dataMono.copyWith(fontSize: 13)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 10),
          child: Text((record.timeOut?.isNotEmpty ?? false) ? record.timeOut! : '—', style: BaycelTypography.dataMono.copyWith(fontSize: 13)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 10),
          child: Text((record.timeIn2?.isNotEmpty ?? false) ? record.timeIn2! : '—', style: BaycelTypography.dataMono.copyWith(fontSize: 13)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 10),
          child: Text((record.timeOut2?.isNotEmpty ?? false) ? record.timeOut2! : '—', style: BaycelTypography.dataMono.copyWith(fontSize: 13)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 10),
          child: Text(record.totalHours > 0 ? record.totalHours.toStringAsFixed(1) : '—', style: BaycelTypography.dataMono.copyWith(fontSize: 13)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 10),
          child: _buildStatusBadge(record.status, record.lateMinutes),
        ),
      ],
    );
  }
}
