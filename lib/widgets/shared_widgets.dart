import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/delivery.dart';

class BaycelStatCard extends StatelessWidget {
  final String value;
  final String title;
  final String subtitle;
  final Color subtitleColor;
  final IconData icon;
  final Color iconColor;

  const BaycelStatCard({
    super.key,
    required this.value,
    required this.title,
    required this.subtitle,
    required this.subtitleColor,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.md, vertical: BaycelSpacing.sm),
      decoration: BaycelComponents.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(BaycelRadius.lg)),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          SizedBox(height: BaycelSpacing.xs),
          Text(value, style: BaycelTypography.headline.copyWith(fontSize: 20)),
          SizedBox(height: BaycelSpacing.xxs),
          Text(title, style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textSecondary, fontSize: 12)),
          SizedBox(height: BaycelSpacing.xxs),
          Text(subtitle, style: BaycelTypography.labelXs.copyWith(color: subtitleColor)),
        ],
      ),
    );
  }
}

class BaycelCompactStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const BaycelCompactStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.md, vertical: BaycelSpacing.sm),
      decoration: BoxDecoration(
        color: BaycelColors.card,
        borderRadius: BorderRadius.circular(BaycelRadius.md),
        boxShadow: [BaycelShadows.shadowSm],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(BaycelRadius.md)),
                child: Icon(icon, size: 15, color: color),
              ),
              SizedBox(width: BaycelSpacing.xs),
              Text(title, style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textSecondary, fontSize: 11)),
            ],
          ),
          SizedBox(height: BaycelSpacing.xs),
          Text(value, style: BaycelTypography.display.copyWith(fontSize: 17)),
        ],
      ),
    );
  }
}

class BaycelPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color? bgColor;

  const BaycelPill({super.key, required this.label, required this.color, this.bgColor});

  @override
  Widget build(BuildContext context) {
    final bg = bgColor ?? color;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.sm, vertical: BaycelSpacing.xxs + 1),
      decoration: BoxDecoration(color: bg.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(BaycelRadius.full)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          SizedBox(width: BaycelSpacing.xxs + 2),
          Text(label, style: BaycelTypography.labelXs.copyWith(color: color)),
        ],
      ),
    );
  }
}

class BaycelStatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const BaycelStatusPill({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.sm, vertical: BaycelSpacing.xxs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(BaycelRadius.full),
      ),
      child: Text(label, style: BaycelTypography.labelSm.copyWith(color: color, fontSize: 11), textAlign: TextAlign.center),
    );
  }
}

class DeliveryStatusPill extends StatelessWidget {
  final DeliveryStatus status;
  final String? overrideLabel;

  const DeliveryStatusPill({super.key, required this.status, this.overrideLabel});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case DeliveryStatus.delivered:
        color = BaycelColors.success;
        label = 'Verified';
      case DeliveryStatus.pending:
        color = BaycelColors.marigoldDark;
        label = 'Pending';
      case DeliveryStatus.inTransit:
        color = BaycelColors.blue;
        label = 'In Transit';
      case DeliveryStatus.discrepancy:
        color = BaycelColors.error;
        label = 'Discrepancy';
      case DeliveryStatus.cancelled:
        color = BaycelColors.textMuted;
        label = 'Cancelled';
    }

    return BaycelStatusPill(label: overrideLabel ?? label, color: color);
  }
}

class BaycelTableHeader extends StatelessWidget {
  final String text;
  const BaycelTableHeader({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: BaycelSpacing.sm),
      child: Text(text, style: BaycelTypography.labelSm.copyWith(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.03, color: BaycelColors.textMuted)),
    );
  }
}

class BaycelTableCell extends StatelessWidget {
  final String text;
  final bool bold;
  const BaycelTableCell({super.key, required this.text, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 9),
      child: Text(text, style: BaycelTypography.bodySm.copyWith(fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
    );
  }
}

// ── Skeleton Loaders ──────────────────────────────────────

class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.3 + (_controller.value * 0.4),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const _SkeletonBlock({required this.width, required this.height, this.radius = BaycelRadius.md});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: BaycelColors.divider,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(BaycelSpacing.base),
      decoration: BaycelComponents.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SkeletonBlock(width: 28, height: 28, radius: BaycelRadius.lg),
              SizedBox(width: BaycelSpacing.sm),
              Expanded(child: _SkeletonBlock(width: double.infinity, height: 12)),
            ],
          ),
          SizedBox(height: BaycelSpacing.sm),
          _SkeletonBlock(width: 60, height: 20),
          SizedBox(height: BaycelSpacing.xs),
          _SkeletonBlock(width: 100, height: 10),
        ],
      ),
    );
  }
}

class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: BaycelSpacing.sm),
      child: Row(
        children: [
          _SkeletonBlock(width: 36, height: 36, radius: BaycelRadius.md),
          SizedBox(width: BaycelSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBlock(width: double.infinity, height: 12),
                SizedBox(height: BaycelSpacing.xs),
                _SkeletonBlock(width: 140, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonTable extends StatelessWidget {
  final int rows;
  const SkeletonTable({super.key, this.rows = 5});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(rows, (i) => Padding(
        padding: EdgeInsets.symmetric(vertical: BaycelSpacing.sm),
        child: Row(
          children: [
            Expanded(flex: 3, child: _SkeletonBlock(width: double.infinity, height: 12)),
            SizedBox(width: BaycelSpacing.sm),
            Expanded(flex: 2, child: _SkeletonBlock(width: double.infinity, height: 12)),
            SizedBox(width: BaycelSpacing.sm),
            Expanded(flex: 1, child: _SkeletonBlock(width: double.infinity, height: 12)),
          ],
        ),
      )),
    );
  }
}

class SkeletonDashboard extends StatelessWidget {
  const SkeletonDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final crossCount = isMobile ? 2 : 4;
        return GridView.count(
          crossAxisCount: crossCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: BaycelSpacing.sm,
          mainAxisSpacing: BaycelSpacing.sm,
          childAspectRatio: 1.5,
          children: List.generate(crossCount, (_) => const SkeletonCard()),
        );
      },
    );
  }
}

class SkeletonProfile extends StatelessWidget {
  const SkeletonProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              _SkeletonBlock(width: 72, height: 72, radius: BaycelRadius.full),
              SizedBox(height: BaycelSpacing.md),
              _SkeletonBlock(width: 120, height: 16),
              SizedBox(height: BaycelSpacing.xs),
              _SkeletonBlock(width: 80, height: 12),
            ],
          ),
        ),
        SizedBox(height: BaycelSpacing.lg),
        _SkeletonBlock(width: double.infinity, height: 200, radius: BaycelRadius.lg),
        SizedBox(height: BaycelSpacing.md),
        _SkeletonBlock(width: double.infinity, height: 200, radius: BaycelRadius.lg),
      ],
    );
  }
}

class SkeletonSettings extends StatelessWidget {
  const SkeletonSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SkeletonBlock(width: 140, height: 20),
        SizedBox(height: BaycelSpacing.lg),
        ...List.generate(4, (_) => Padding(
          padding: EdgeInsets.only(bottom: BaycelSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBlock(width: 100, height: 10),
              SizedBox(height: BaycelSpacing.sm),
              _SkeletonBlock(width: double.infinity, height: 44, radius: BaycelRadius.md),
            ],
          ),
        )),
      ],
    );
  }
}
