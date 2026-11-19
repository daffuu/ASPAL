import 'package:flutter/material.dart';

import '../features/auth/auth_module.dart';
import '../models/report.dart';
import '../screens/catatan_form_screen.dart';
import '../screens/change_password_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/home_shell.dart';
import '../screens/login_screen.dart';
import '../screens/merged_riwayat_screen.dart';
import '../screens/not_found_screen.dart';
import '../screens/register_screen.dart';
import '../screens/splash_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String detail = '/detail';
  static const String catatanForm = '/catatan-form';
  static const String editProfile = '/edit-profile';
  static const String changePassword = '/change-password';

  /// Hook opsional untuk memeriksa status autentikasi (berguna untuk testing).
  static bool Function()? authChecker;

  static bool isPublicRoute(String? routeName) {
    return routeName == splash || routeName == login || routeName == register;
  }

  static bool isAuthorized() {
    if (authChecker != null) {
      return authChecker!();
    }
    return AuthModule.controller.isAuthenticated;
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name;

    // --- AUTH GUARD ---
    // Seluruh fitur/route aplikasi dilindungi kecuali route publik (splash, login, register)
    if (!isPublicRoute(routeName) && !isAuthorized()) {
      return MaterialPageRoute<void>(
        builder: (_) => const LoginScreen(),
        settings: settings,
      );
    }

    switch (routeName) {
      case splash:
        return MaterialPageRoute<void>(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      case login:
        return MaterialPageRoute<void>(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case register:
        return MaterialPageRoute<void>(
          builder: (_) => const RegisterScreen(),
          settings: settings,
        );
      case home:
        return MaterialPageRoute<void>(
          builder: (_) => const HomeShell(),
          settings: settings,
        );
      case editProfile:
        return MaterialPageRoute<void>(
          builder: (_) => const EditProfileScreen(),
          settings: settings,
        );
      case changePassword:
        return MaterialPageRoute<void>(
          builder: (_) => const ChangePasswordScreen(),
          settings: settings,
        );
      case detail:
        final args = settings.arguments;
        if (args is Report) {
          return MaterialPageRoute<void>(
            builder: (_) => DetailScreen(report: args),
            settings: settings,
          );
        }
        return null; // data salah/kosong -> halaman 404
      case catatanForm:
        return MaterialPageRoute<String>(
          builder: (_) => const CatatanFormScreen(),
          settings: settings,
        );
      default:
        return null; // route tidak terdaftar -> halaman 404
    }
  }

  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      builder: (_) => NotFoundScreen(routeName: settings.name),
      settings: settings,
    );
  }
}
