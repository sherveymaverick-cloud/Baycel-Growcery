import 'package:flutter/material.dart';

/// Fade-through page transition (300ms easeInOut) — respects Reduce Motion.
/// Forward: 300ms fade in; reverse: 250ms (exit faster than entrance).
class BaycelPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  BaycelPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final reduced = MediaQuery.of(context).disableAnimations;
            if (reduced) return child;
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              child: child,
            );
          },
        );
}
