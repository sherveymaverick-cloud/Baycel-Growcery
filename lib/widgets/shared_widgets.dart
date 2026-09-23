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

  static bool _isLive(Color c) =>
      c == BaycelColors.marigold || c == BaycelColors.marigoldDark || c == BaycelColors.blue;

  @override
  Widget build(BuildContext context) {
    final bg = bgColor ?? color;
    final reduced = MediaQuery.of(context).disableAnimations;
    final pill = Container(
      padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.sm, vertical: BaycelSpacing.xxs + 1),
      decoration: BoxDecoration(color: bg.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(BaycelRadius.full)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isLive(color) && !reduced)
            _PulseDot(color: color)
          else
            Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          SizedBox(width: BaycelSpacing.xxs + 2),
          Text(label, style: BaycelTypography.labelXs.copyWith(color: _pillTextColor(color))),
        ],
      ),
    );
    return AnimatedSwitcher(
      duration: reduced ? Duration.zero : const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
      child: SizedBox(
        key: ValueKey('$label-${color.toARGB32()}'),
        child: pill,
      ),
    );
  }
}

Color _pillTextColor(Color color) {
  if (color == BaycelColors.marigold || color == BaycelColors.marigoldDark) {
    return BaycelColors.warningText;
  }
  return color;
}

/// Breathing dot for live/pending statuses (pending, in-transit, in-progress).
class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
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
        final t = Curves.easeInOut.transform(_controller.value);
        return Opacity(
          opacity: 1 - t * 0.55,
          child: Transform.scale(scale: 1 + t * 0.35, child: child),
        );
      },
      child: Container(
        width: 5,
        height: 5,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

class BaycelStatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const BaycelStatusPill({super.key, required this.label, required this.color});

  static bool _isLive(Color c) =>
      c == BaycelColors.marigold || c == BaycelColors.marigoldDark || c == BaycelColors.blue;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.of(context).disableAnimations;
    final textColor = _pillTextColor(color);
    final pill = Container(
      padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.sm, vertical: BaycelSpacing.xxs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(BaycelRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isLive(color) && !reduced)
            _PulseDot(color: color)
          else
            Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          SizedBox(width: BaycelSpacing.xxs + 2),
          Text(label, style: BaycelTypography.labelSm.copyWith(color: textColor, fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    );
    return AnimatedSwitcher(
      duration: reduced ? Duration.zero : const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
      child: SizedBox(
        key: ValueKey('$label-${color.toARGB32()}'),
        child: pill,
      ),
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

/// Provides one shared shimmer controller to every `_SkeletonBlock` beneath it,
/// so a whole skeleton surface shares a single ticker and one coherent sweep.
class _ShimmerScope extends InheritedWidget {
  final Animation<double> progress;
  const _ShimmerScope({required this.progress, required super.child});

  static Animation<double>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ShimmerScope>()?.progress;

  @override
  bool updateShouldNotify(_ShimmerScope oldWidget) => progress != oldWidget.progress;
}

class _ShimmerHost extends StatefulWidget {
  final Widget child;
  const _ShimmerHost({required this.child});

  @override
  State<_ShimmerHost> createState() => _ShimmerHostState();
}

class _ShimmerHostState extends State<_ShimmerHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.of(context).disableAnimations;
    if (reduced == _reduced) return;
    _reduced = reduced;
    if (reduced) {
      _controller.stop();
      _controller.value = 0.5;
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _reduced
        ? const AlwaysStoppedAnimation<double>(0.5)
        : _controller;
    return _ShimmerScope(progress: progress, child: widget.child);
  }
}

class _SkeletonBlock extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const _SkeletonBlock({required this.width, required this.height, this.radius = BaycelRadius.md});

  Widget _paint(double t) {
    final s1 = (t - 0.45).clamp(0.0, 1.0);
    final s3 = (t + 0.45).clamp(0.0, 1.0);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [
            BaycelColors.skeletonBase,
            BaycelColors.skeletonShimmer,
            BaycelColors.skeletonBase,
          ],
          stops: [s1, t.clamp(0.0, 1.0), s3],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _ShimmerScope.maybeOf(context);
    if (progress == null) return _paint(0.5);
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) => _paint(progress.value),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _ShimmerHost(
      child: Container(
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
      ),
    );
  }
}

class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return _ShimmerHost(
      child: Padding(
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
      ),
    );
  }
}

class SkeletonTable extends StatelessWidget {
  final int rows;
  const SkeletonTable({super.key, this.rows = 5});

  @override
  Widget build(BuildContext context) {
    return _ShimmerHost(
      child: Column(
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
      ),
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
          childAspectRatio: 2.0,
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
    return _ShimmerHost(
      child: Column(
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
      ),
    );
  }
}

class SkeletonSettings extends StatelessWidget {
  const SkeletonSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return _ShimmerHost(
      child: Column(
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
      ),
    );
  }
}

// ── Page skeletons (top-aligned, match tab layout) ────────

class _SkeletonHeader extends StatelessWidget {
  final double titleWidth;
  final double subtitleWidth;
  final bool trailingButton;

  const _SkeletonHeader({
    this.titleWidth = 160,
    this.subtitleWidth = 200,
    this.trailingButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBlock(width: titleWidth, height: 26, radius: BaycelRadius.sm),
              SizedBox(height: BaycelSpacing.xs),
              _SkeletonBlock(width: subtitleWidth, height: 12, radius: BaycelRadius.sm),
            ],
          ),
        ),
        if (trailingButton) ...[
          SizedBox(width: BaycelSpacing.md),
          _SkeletonBlock(width: 120, height: 40, radius: BaycelRadius.md),
        ],
      ],
    );
  }
}

class _SkeletonChips extends StatelessWidget {
  final int count;
  const _SkeletonChips({this.count = 5});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(count, (i) {
          final widths = [72.0, 96.0, 88.0, 72.0, 84.0, 90.0];
          return Padding(
            padding: EdgeInsets.only(right: BaycelSpacing.sm),
            child: _SkeletonBlock(
              width: widths[i % widths.length],
              height: 32,
              radius: BaycelRadius.full,
            ),
          );
        }),
      ),
    );
  }
}

class _SkeletonCardShell extends StatelessWidget {
  final Widget child;
  final double height;
  const _SkeletonCardShell({required this.child, this.height = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: height > 0 ? BoxConstraints.tightFor(height: height) : null,
      padding: EdgeInsets.all(BaycelSpacing.base),
      decoration: BaycelComponents.card,
      child: child,
    );
  }
}

class _SkeletonStatGrid extends StatelessWidget {
  final int count;
  const _SkeletonStatGrid({this.count = 4});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoByTwo = count == 4 && constraints.maxWidth < 500;
        Widget box() => const Expanded(child: _SkeletonStatBox());

        if (twoByTwo) {
          return Column(
            children: [
              Row(children: [box(), SizedBox(width: BaycelSpacing.sm), box()]),
              SizedBox(height: BaycelSpacing.sm),
              Row(children: [box(), SizedBox(width: BaycelSpacing.sm), box()]),
            ],
          );
        }
        return Row(
          children: [
            for (var i = 0; i < count; i++) ...[
              if (i > 0) SizedBox(width: BaycelSpacing.sm),
              box(),
            ],
          ],
        );
      },
    );
  }
}

/// Compact stat placeholder — matches Present/Late/Absent/On Leave boxes.
class _SkeletonStatBox extends StatelessWidget {
  const _SkeletonStatBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: BaycelSpacing.md,
        vertical: BaycelSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: BaycelColors.surface,
        borderRadius: BorderRadius.circular(BaycelRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SkeletonBlock(width: 28, height: 20, radius: BaycelRadius.sm),
          SizedBox(height: BaycelSpacing.xxs),
          _SkeletonBlock(width: 56, height: 10, radius: BaycelRadius.sm),
        ],
      ),
    );
  }
}

class _SkeletonTableCard extends StatelessWidget {
  final int rows;
  final String? title;
  const _SkeletonTableCard({this.rows = 6, this.title});

  @override
  Widget build(BuildContext context) {
    return _SkeletonCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            _SkeletonBlock(width: 140, height: 16, radius: BaycelRadius.sm),
            SizedBox(height: BaycelSpacing.md),
            Container(height: 1, color: BaycelColors.divider),
            SizedBox(height: BaycelSpacing.sm),
          ],
          ...List.generate(rows, (i) => Padding(
            padding: EdgeInsets.symmetric(vertical: BaycelSpacing.sm),
            child: Row(
              children: [
                Expanded(flex: 3, child: _SkeletonBlock(width: double.infinity, height: 12)),
                SizedBox(width: BaycelSpacing.sm),
                Expanded(flex: 2, child: _SkeletonBlock(width: double.infinity, height: 12)),
                SizedBox(width: BaycelSpacing.sm),
                Expanded(flex: 2, child: _SkeletonBlock(width: double.infinity, height: 12)),
                SizedBox(width: BaycelSpacing.sm),
                Expanded(flex: 1, child: _SkeletonBlock(width: double.infinity, height: 12)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _SkeletonListCard extends StatelessWidget {
  final int tiles;
  final String? title;
  const _SkeletonListCard({this.tiles = 3, this.title});

  @override
  Widget build(BuildContext context) {
    return _SkeletonCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            _SkeletonBlock(width: 150, height: 16, radius: BaycelRadius.sm),
            SizedBox(height: BaycelSpacing.md),
          ],
          Container(height: 1, color: BaycelColors.divider),
          ...List.generate(tiles, (_) => const SkeletonListTile()),
        ],
      ),
    );
  }
}

class _SkeletonEmployeeCard extends StatelessWidget {
  const _SkeletonEmployeeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(BaycelSpacing.base),
      decoration: BaycelComponents.card,
      child: Row(
        children: [
          _SkeletonBlock(width: 44, height: 44, radius: BaycelRadius.full),
          SizedBox(width: BaycelSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBlock(width: 120, height: 12),
                SizedBox(height: BaycelSpacing.xs),
                _SkeletonBlock(width: 80, height: 10),
                SizedBox(height: BaycelSpacing.xs),
                _SkeletonBlock(width: 100, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonEmployeeGrid extends StatelessWidget {
  const _SkeletonEmployeeGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 1024
            ? 3
            : constraints.maxWidth > 600
                ? 2
                : 1;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: BaycelSpacing.md,
          mainAxisSpacing: BaycelSpacing.md,
          childAspectRatio: 2.8,
          children: List.generate(columns * 2, (_) => const _SkeletonEmployeeCard()),
        );
      },
    );
  }
}

class _SkeletonPage extends StatelessWidget {
  final Widget child;
  const _SkeletonPage({required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(BaycelSpacing.lg),
          child: child,
        ),
      ),
    );
  }
}

/// Inventory: header + category chips + products table card.
class SkeletonInventoryPage extends StatelessWidget {
  const SkeletonInventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _ShimmerHost(
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: double.infinity,
          child: _SkeletonPage(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonHeader(titleWidth: 140, subtitleWidth: 220, trailingButton: true),
                SizedBox(height: BaycelSpacing.lg),
                const _SkeletonChips(count: 8),
                SizedBox(height: BaycelSpacing.lg),
                const _SkeletonTableCard(rows: 8, title: 'Products'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Payroll: header + compact stats + payslip list.
class SkeletonPayrollPage extends StatelessWidget {
  const SkeletonPayrollPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _ShimmerHost(
      child: _SkeletonPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkeletonHeader(titleWidth: 150, subtitleWidth: 180, trailingButton: true),
            SizedBox(height: BaycelSpacing.lg),
            const _SkeletonStatGrid(count: 4),
            SizedBox(height: BaycelSpacing.lg),
            const _SkeletonListCard(tiles: 4, title: 'Payroll Records'),
          ],
        ),
      ),
    );
  }
}

/// Reports: header + sales graph + report card grid.
class SkeletonReportsPage extends StatelessWidget {
  const SkeletonReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _ShimmerHost(
      child: _SkeletonPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkeletonHeader(titleWidth: 130, subtitleWidth: 260),
            SizedBox(height: BaycelSpacing.lg),
            _SkeletonCardShell(
              height: 280,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SkeletonBlock(width: 130, height: 16),
                      _SkeletonBlock(width: 80, height: 32, radius: BaycelRadius.md),
                    ],
                  ),
                  SizedBox(height: BaycelSpacing.base),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(7, (i) {
                        final heights = [48.0, 72.0, 56.0, 96.0, 64.0, 88.0, 70.0];
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: _SkeletonBlock(
                              width: double.infinity,
                              height: heights[i],
                              radius: BaycelRadius.sm,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: BaycelSpacing.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                final cross = constraints.maxWidth > 900 ? 3 : constraints.maxWidth > 600 ? 2 : 1;
                return GridView.count(
                  crossAxisCount: cross,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: BaycelSpacing.md,
                  mainAxisSpacing: BaycelSpacing.md,
                  childAspectRatio: 1.8,
                  children: List.generate(cross * 2, (_) {
                    return Container(
                      padding: EdgeInsets.all(BaycelSpacing.base),
                      decoration: BaycelComponents.card,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _SkeletonBlock(width: 32, height: 32, radius: BaycelRadius.lg),
                              SizedBox(width: BaycelSpacing.sm),
                              Expanded(child: _SkeletonBlock(width: double.infinity, height: 12)),
                            ],
                          ),
                          SizedBox(height: BaycelSpacing.sm),
                          _SkeletonBlock(width: double.infinity, height: 10),
                          SizedBox(height: BaycelSpacing.xs),
                          _SkeletonBlock(width: 140, height: 10),
                          Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _SkeletonBlock(width: 90, height: 28, radius: BaycelRadius.md),
                              _SkeletonBlock(width: 70, height: 28, radius: BaycelRadius.md),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Employees: header + role chips + employee card grid.
class SkeletonEmployeePage extends StatelessWidget {
  const SkeletonEmployeePage({super.key});

  @override
  Widget build(BuildContext context) {
    return _ShimmerHost(
      child: _SkeletonPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkeletonHeader(titleWidth: 150, subtitleWidth: 160, trailingButton: true),
            SizedBox(height: BaycelSpacing.lg),
            const _SkeletonChips(count: 7),
            SizedBox(height: BaycelSpacing.lg),
            const _SkeletonEmployeeGrid(),
          ],
        ),
      ),
    );
  }
}

/// Deliveries: header + status chips + deliveries table.
class SkeletonDeliveryPage extends StatelessWidget {
  const SkeletonDeliveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _ShimmerHost(
      child: _SkeletonPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkeletonHeader(titleWidth: 150, subtitleWidth: 160),
            SizedBox(height: BaycelSpacing.lg),
            const _SkeletonChips(count: 4),
            SizedBox(height: BaycelSpacing.lg),
            const _SkeletonTableCard(rows: 7, title: 'Deliveries'),
          ],
        ),
      ),
    );
  }
}

/// Attendance: header + date button + stat boxes + log table.
class SkeletonAttendancePage extends StatelessWidget {
  const SkeletonAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return _ShimmerHost(
      child: _SkeletonPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonBlock(width: 150, height: 26, radius: BaycelRadius.sm),
                      SizedBox(height: BaycelSpacing.xs),
                      _SkeletonBlock(width: 200, height: 12, radius: BaycelRadius.sm),
                    ],
                  ),
                ),
                _SkeletonBlock(width: 140, height: 40, radius: BaycelRadius.md),
              ],
            ),
            SizedBox(height: BaycelSpacing.lg),
            const _SkeletonStatGrid(count: 4),
            SizedBox(height: BaycelSpacing.lg),
            const _SkeletonTableCard(rows: 8, title: 'Attendance Log'),
          ],
        ),
      ),
    );
  }
}

/// Settings: header + section cards.
class SkeletonSettingsPage extends StatelessWidget {
  const SkeletonSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _ShimmerHost(
      child: _SkeletonPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SkeletonHeader(titleWidth: 140, subtitleWidth: 200, trailingButton: true),
            SizedBox(height: BaycelSpacing.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                final card = _SkeletonCardShell(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonBlock(width: 120, height: 14),
                      SizedBox(height: BaycelSpacing.md),
                      ...List.generate(3, (_) => Padding(
                        padding: EdgeInsets.only(bottom: BaycelSpacing.sm),
                        child: _SkeletonBlock(width: double.infinity, height: 44, radius: BaycelRadius.md),
                      )),
                    ],
                  ),
                );
                if (constraints.maxWidth < 600) {
                  return Column(
                    children: [
                      card,
                      SizedBox(height: BaycelSpacing.base),
                      card,
                      SizedBox(height: BaycelSpacing.base),
                      _SkeletonListCard(tiles: 3, title: 'Roles'),
                    ],
                  );
                }
                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: card),
                        SizedBox(width: BaycelSpacing.base),
                        Expanded(child: card),
                      ],
                    ),
                    SizedBox(height: BaycelSpacing.base),
                    _SkeletonListCard(tiles: 3, title: 'Roles'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Profile: header + avatar card + info cards.
class SkeletonProfilePage extends StatelessWidget {
  const SkeletonProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return _ShimmerHost(
      child: _SkeletonPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SkeletonBlock(width: 140, height: 26, radius: BaycelRadius.sm),
                _SkeletonBlock(width: 36, height: 36, radius: BaycelRadius.full),
              ],
            ),
            SizedBox(height: BaycelSpacing.lg),
            _SkeletonCardShell(
              child: Row(
                children: [
                  _SkeletonBlock(width: 72, height: 72, radius: BaycelRadius.full),
                  SizedBox(width: BaycelSpacing.base),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkeletonBlock(width: 140, height: 16),
                        SizedBox(height: BaycelSpacing.xs),
                        _SkeletonBlock(width: 90, height: 12),
                        SizedBox(height: BaycelSpacing.xs),
                        _SkeletonBlock(width: 180, height: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: BaycelSpacing.lg),
            const _SkeletonListCard(tiles: 4, title: 'Account'),
            SizedBox(height: BaycelSpacing.lg),
            const _SkeletonListCard(tiles: 2, title: 'Shift'),
          ],
        ),
      ),
    );
  }
}

/// Profile & Settings: header + stacked section cards.
class SkeletonProfileSettingsPage extends StatelessWidget {
  const SkeletonProfileSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _ShimmerHost(
      child: _SkeletonPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SkeletonHeader(titleWidth: 200, subtitleWidth: 160),
            SizedBox(height: BaycelSpacing.lg),
            ...List.generate(3, (i) => Padding(
              padding: EdgeInsets.only(bottom: BaycelSpacing.base),
              child: _SkeletonCardShell(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBlock(width: 130, height: 14),
                    SizedBox(height: BaycelSpacing.md),
                    ...List.generate(2, (_) => Padding(
                      padding: EdgeInsets.only(bottom: BaycelSpacing.sm),
                      child: _SkeletonBlock(width: double.infinity, height: 44, radius: BaycelRadius.md),
                    )),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

/// Dashboard (owner/manager): greeting + clock + stats + content cards.
class SkeletonDashboardPage extends StatelessWidget {
  const SkeletonDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _ShimmerHost(
      child: _SkeletonPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkeletonHeader(titleWidth: 220, subtitleWidth: 240),
            SizedBox(height: BaycelSpacing.lg),
            _SkeletonCardShell(
              height: 120,
              child: Row(
                children: [
                  _SkeletonBlock(width: 56, height: 56, radius: BaycelRadius.full),
                  SizedBox(width: BaycelSpacing.base),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SkeletonBlock(width: 160, height: 14),
                        SizedBox(height: BaycelSpacing.sm),
                        _SkeletonBlock(width: 100, height: 20),
                      ],
                    ),
                  ),
                  _SkeletonBlock(width: 100, height: 40, radius: BaycelRadius.md),
                ],
              ),
            ),
            SizedBox(height: BaycelSpacing.lg),
            const _SkeletonStatGrid(count: 4),
            SizedBox(height: BaycelSpacing.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 900;
                final chart = _SkeletonCardShell(
                  height: 220,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonBlock(width: 120, height: 14),
                      SizedBox(height: BaycelSpacing.md),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(6, (i) {
                            final heights = [40.0, 70.0, 55.0, 90.0, 60.0, 80.0];
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: _SkeletonBlock(width: double.infinity, height: heights[i], radius: BaycelRadius.sm),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                );
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: chart),
                      SizedBox(width: BaycelSpacing.base),
                      Expanded(
                        child: const _SkeletonListCard(tiles: 3, title: 'Deliveries'),
                      ),
                    ],
                  );
                }
                return Column(
                  children: [
                    chart,
                    SizedBox(height: BaycelSpacing.base),
                    const _SkeletonListCard(tiles: 3, title: 'Deliveries'),
                  ],
                );
              },
            ),
            SizedBox(height: BaycelSpacing.lg),
            const _SkeletonListCard(tiles: 3, title: 'Requests'),
          ],
        ),
      ),
    );
  }
}

/// Floor staff home: gradient header + clock + role content cards.
class SkeletonFloorHomePage extends StatelessWidget {
  const SkeletonFloorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return _ShimmerHost(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(BaycelSpacing.base, BaycelSpacing.lg, BaycelSpacing.base, BaycelSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [BaycelColors.crimson.withValues(alpha: 0.35), BaycelColors.crimsonDark.withValues(alpha: 0.35)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(BaycelRadius.xl),
                bottomRight: Radius.circular(BaycelRadius.xl),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _SkeletonBlock(width: 18, height: 18, radius: BaycelRadius.sm),
                    SizedBox(width: BaycelSpacing.sm),
                    _SkeletonBlock(width: 100, height: 14, radius: BaycelRadius.sm),
                    Spacer(),
                    _SkeletonBlock(width: 70, height: 10, radius: BaycelRadius.sm),
                    SizedBox(width: BaycelSpacing.md),
                    _SkeletonBlock(width: 22, height: 22, radius: BaycelRadius.full),
                  ],
                ),
                SizedBox(height: BaycelSpacing.lg),
                _SkeletonBlock(width: 160, height: 24, radius: BaycelRadius.sm),
                SizedBox(height: BaycelSpacing.sm),
                _SkeletonBlock(width: 90, height: 12, radius: BaycelRadius.sm),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: BaycelSpacing.base),
                _SkeletonCardShell(
                  height: 120,
                  child: Row(
                    children: [
                      _SkeletonBlock(width: 56, height: 56, radius: BaycelRadius.full),
                      SizedBox(width: BaycelSpacing.base),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _SkeletonBlock(width: 140, height: 14),
                            SizedBox(height: BaycelSpacing.sm),
                            _SkeletonBlock(width: 90, height: 20),
                          ],
                        ),
                      ),
                      _SkeletonBlock(width: 90, height: 40, radius: BaycelRadius.md),
                    ],
                  ),
                ),
                SizedBox(height: BaycelSpacing.md),
                const _SkeletonStatGrid(count: 4),
                SizedBox(height: BaycelSpacing.md),
                const _SkeletonListCard(tiles: 3, title: 'Tasks'),
                SizedBox(height: BaycelSpacing.lg),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
