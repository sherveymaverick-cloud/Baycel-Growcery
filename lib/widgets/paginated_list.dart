import 'package:flutter/material.dart';
import '../theme.dart';

class PaginatedList extends StatefulWidget {
  final int itemCount;
  final bool hasMore;
  final VoidCallback? onLoadMore;
  final Widget Function(BuildContext, int) itemBuilder;
  final Widget? emptyWidget;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;

  const PaginatedList({
    super.key,
    required this.itemCount,
    required this.hasMore,
    this.onLoadMore,
    required this.itemBuilder,
    this.emptyWidget,
    this.padding,
    this.physics,
  });

  @override
  State<PaginatedList> createState() => _PaginatedListState();
}

class _PaginatedListState extends State<PaginatedList> {
  final _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _triggerLoadMore();
    }
  }

  void _triggerLoadMore() {
    if (_isLoadingMore || !widget.hasMore || widget.onLoadMore == null) return;
    setState(() => _isLoadingMore = true);
    widget.onLoadMore!();
  }

  @override
  void didUpdateWidget(covariant PaginatedList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isLoadingMore && oldWidget.itemCount < widget.itemCount) {
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount == 0) {
      return widget.emptyWidget ??
          Center(
            child: Padding(
              padding: EdgeInsets.all(BaycelSpacing.xl),
              child: Text(
                'No data',
                style: BaycelTypography.body.copyWith(
                  color: BaycelColors.textDisabled,
                ),
              ),
            ),
          );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
      padding: widget.padding,
      itemCount: widget.itemCount + (widget.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == widget.itemCount) {
          return _buildLoadMoreIndicator();
        }
        return widget.itemBuilder(context, index);
      },
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: BaycelSpacing.base),
      child: Center(
        child: _isLoadingMore
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: BaycelColors.crimson,
                ),
              )
            : GestureDetector(
                onTap: _triggerLoadMore,
                child: Text(
                  'Load More',
                  style: BaycelTypography.bodySm.copyWith(
                    color: BaycelColors.crimson,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
      ),
    );
  }
}
