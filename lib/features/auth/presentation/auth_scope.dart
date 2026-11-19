import 'package:flutter/widgets.dart';

import 'controllers/auth_controller.dart';

/// InheritedNotifier untuk membagikan `AuthController` ke seluruh pohon widget.
class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    super.key,
    required AuthController controller,
    required super.child,
  }) : super(notifier: controller);

  static AuthController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope tidak ditemukan dalam BuildContext');
    return scope!.notifier!;
  }

  static AuthController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AuthScope>()?.notifier;
  }
}

extension AuthContextX on BuildContext {
  AuthController get authController => AuthScope.of(this);
  AuthController? get maybeAuthController => AuthScope.maybeOf(this);
}
