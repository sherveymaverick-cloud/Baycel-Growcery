import 'package:flutter/material.dart';

/// Global page-scoped search query. HomeScreen search bar writes here;
/// pages below [SearchScope] rebuild and filter when it changes.
class SearchQueryNotifier extends ValueNotifier<String> {
  SearchQueryNotifier() : super('');

  static final SearchQueryNotifier instance = SearchQueryNotifier();

  set query(String value) {
    if (this.value == value) return;
    this.value = value;
  }
}

class SearchScope extends StatefulWidget {
  const SearchScope({
    super.key,
    required this.notifier,
    required this.child,
  });

  final SearchQueryNotifier notifier;
  final Widget child;

  static SearchQueryNotifier of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_SearchScopeInherited>();
    return scope?.notifier ?? SearchQueryNotifier.instance;
  }

  @override
  State<SearchScope> createState() => _SearchScopeState();
}

class _SearchScopeState extends State<SearchScope> {
  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_onQueryChanged);
  }

  @override
  void didUpdateWidget(covariant SearchScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notifier != widget.notifier) {
      oldWidget.notifier.removeListener(_onQueryChanged);
      widget.notifier.addListener(_onQueryChanged);
    }
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_onQueryChanged);
    super.dispose();
  }

  void _onQueryChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _SearchScopeInherited(
      notifier: widget.notifier,
      child: widget.child,
    );
  }
}

class _SearchScopeInherited extends InheritedWidget {
  const _SearchScopeInherited({
    required this.notifier,
    required super.child,
  });

  final SearchQueryNotifier notifier;

  @override
  bool updateShouldNotify(covariant _SearchScopeInherited oldWidget) =>
      notifier != oldWidget.notifier;
}

extension SearchQueryContext on BuildContext {
  /// Lowercased, trimmed current search query. Registers rebuild dependency.
  String get searchQuery {
    final value = SearchScope.of(this).value;
    return value.trim().toLowerCase();
  }
}
