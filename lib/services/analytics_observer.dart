import 'package:flutter/widgets.dart';

/// Reports a `screen_view` for every full-page route that is pushed, replaced
/// or revealed again by a pop. Dialogs and sheets are ignored. The screen name
/// comes from [registry] (widget type -> name), found by looking into the
/// route's built subtree; the root route is reported through [rootScreen]
/// because its content (language, onboarding, auth, tabs) changes in place.
class ScreenViewObserver extends NavigatorObserver {
  final void Function(String screenName) onScreen;
  final Map<Type, String> registry;
  final String? Function()? rootScreen;

  ScreenViewObserver({
    required this.onScreen,
    required this.registry,
    this.rootScreen,
  });

  static const _maxDepth = 24;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _report(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _report(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Closing a dialog / sheet does not change the visible screen.
    if (route is PageRoute && previousRoute != null) {
      _report(previousRoute, fromPop: true);
    }
  }

  void _report(Route<dynamic> route, {bool fromPop = false}) {
    if (route is! PageRoute) return;
    // The root route's content changes in place and is tracked by the app
    // itself; only a pop back to it needs a fresh view.
    if (route.settings.name == '/' && !fromPop) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final name = route.settings.name == '/'
            ? rootScreen?.call()
            : screenNameOf(route);
        if (name != null) onScreen(name);
      } catch (_) {}
    });
  }

  /// First registered screen widget inside the route's subtree, or null.
  String? screenNameOf(Route<dynamic> route) {
    final context = (route is ModalRoute) ? route.subtreeContext : null;
    if (context is! Element) return null;
    String? found;
    void visit(Element element, int depth) {
      if (found != null || depth > _maxDepth) return;
      final name = registry[element.widget.runtimeType];
      if (name != null) {
        found = name;
        return;
      }
      element.visitChildren((child) => visit(child, depth + 1));
    }

    context.visitChildren((child) => visit(child, 0));
    return found;
  }
}
