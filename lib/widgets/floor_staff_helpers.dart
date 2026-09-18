import 'package:flutter/material.dart';
import '../theme.dart';
import 'shared_widgets.dart';

Widget buildFieldLabel(String label) {
  return Text(label, style: BaycelTypography.labelSm.copyWith(
    fontSize: 11, fontWeight: FontWeight.w500, color: BaycelColors.textMuted, letterSpacing: 0.03));
}

Widget buildSummaryRow(IconData icon, String title, String meta, {String? pillLabel, Color? pillColor}) {
  return Container(
    padding: EdgeInsets.symmetric(vertical: BaycelSpacing.cellVertical),
    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: BaycelColors.divider.withValues(alpha: 0.6), width: 0.5))),
    child: Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: BaycelColors.surface, borderRadius: BorderRadius.circular(BaycelRadius.lg)),
          child: Icon(icon, color: BaycelColors.textSecondary, size: 15),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: BaycelTypography.bodySm.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
              if (meta.isNotEmpty) ...[
                SizedBox(height: 1),
                Text(meta, style: BaycelTypography.labelSm.copyWith(fontSize: 11, color: BaycelColors.textMuted)),
              ],
            ],
          ),
        ),
        if (pillLabel != null && pillColor != null)
          BaycelPill(label: pillLabel, color: pillColor),
      ],
    ),
  );
}

Widget buildMovementRow(String title, String meta) {
  return Container(
    padding: EdgeInsets.symmetric(vertical: BaycelSpacing.cellVertical),
    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: BaycelColors.divider.withValues(alpha: 0.6), width: 0.5))),
    child: Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: BaycelColors.surface, borderRadius: BorderRadius.circular(BaycelRadius.lg)),
          child: Icon(Icons.swap_horiz, color: BaycelColors.textSecondary, size: 15),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: BaycelTypography.bodySm.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
              SizedBox(height: 1),
              Text(meta, style: BaycelTypography.labelSm.copyWith(fontSize: 11, color: BaycelColors.textMuted)),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget buildStatBox(String value, String label) {
  return Container(
    padding: EdgeInsets.all(BaycelSpacing.md),
    decoration: BoxDecoration(
      color: BaycelColors.card,
      borderRadius: BorderRadius.circular(BaycelRadius.lg),
      border: Border.all(color: BaycelColors.divider.withValues(alpha: 0.5)),
      boxShadow: [BaycelShadows.shadowSm],
    ),
    child: Column(
      children: [
        Text(value, style: BaycelTypography.display.copyWith(fontSize: 17), textAlign: TextAlign.center),
        SizedBox(height: BaycelSpacing.xxs),
        Text(label, style: BaycelTypography.labelSm.copyWith(fontSize: 10, color: BaycelColors.textMuted), textAlign: TextAlign.center),
      ],
    ),
  );
}

Widget buildAbsenceRequestRow(String title, String meta, String status, Color statusColor) {
  return Container(
    padding: EdgeInsets.symmetric(vertical: BaycelSpacing.cellVertical),
    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: BaycelColors.divider.withValues(alpha: 0.6), width: 0.5))),
    child: Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: BaycelColors.surface, borderRadius: BorderRadius.circular(BaycelRadius.lg)),
          child: Icon(Icons.calendar_today_outlined, color: BaycelColors.textSecondary, size: 15),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: BaycelTypography.bodySm.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
              SizedBox(height: 1),
              Text(meta, style: BaycelTypography.labelSm.copyWith(fontSize: 11, color: BaycelColors.textMuted)),
            ],
          ),
        ),
        BaycelPill(label: status, color: statusColor),
      ],
    ),
  );
}

Widget buildSubmissionRow(String title, String meta, String value, {double? shortOver}) {
  return Container(
    padding: EdgeInsets.symmetric(vertical: BaycelSpacing.cellVertical),
    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: BaycelColors.divider.withValues(alpha: 0.6), width: 0.5))),
    child: Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: BaycelColors.surface, borderRadius: BorderRadius.circular(BaycelRadius.lg)),
          child: Icon(Icons.attach_money, color: BaycelColors.textSecondary, size: 15),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: BaycelTypography.bodySm.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
              SizedBox(height: 1),
              Text(meta, style: BaycelTypography.labelSm.copyWith(fontSize: 11, color: BaycelColors.textMuted)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value, style: BaycelTypography.dataMono.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
            if (shortOver != null && shortOver != 0)
              Container(
                margin: EdgeInsets.only(top: 2),
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: shortOver > 0
                      ? BaycelColors.error.withValues(alpha: 0.1)
                      : BaycelColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(BaycelRadius.full),
                ),
                child: Text(
                  shortOver > 0 ? 'Short \u20B1${shortOver.toStringAsFixed(2)}' : 'Over \u20B1${(-shortOver).toStringAsFixed(2)}',
                  style: BaycelTypography.labelSm.copyWith(
                    fontSize: 10,
                    color: shortOver > 0 ? BaycelColors.error : BaycelColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

Widget buildProductStockOutRow(String title, String meta, {VoidCallback? onTap}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(BaycelRadius.md),
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 9, horizontal: BaycelSpacing.xs),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: BaycelColors.divider.withValues(alpha: 0.6), width: 0.5))),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: BaycelColors.surface, borderRadius: BorderRadius.circular(BaycelRadius.lg)),
            child: Icon(Icons.inventory_outlined, color: BaycelColors.textSecondary, size: 15),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: BaycelTypography.bodySm.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
                SizedBox(height: 1),
                Text(meta, style: BaycelTypography.labelSm.copyWith(fontSize: 11, color: BaycelColors.textMuted)),
              ],
            ),
          ),
          SizedBox(width: BaycelSpacing.sm),
          OutlinedButton(
            onPressed: onTap,
            style: BaycelComponents.buttonOutlined.copyWith(
              padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: 7)),
            ),
            child: Text('Stock Out', style: BaycelTypography.label.copyWith(fontSize: 11.5)),
          ),
        ],
      ),
    ),
  );
}
