import 'package:flutter/material.dart';

import '../models/road_report.dart';
import '../screens/home_shell.dart';
import '../screens/login_screen.dart';
import '../screens/note_form_screen.dart';
import '../screens/report_detail_screen.dart';
import '../screens/report_history.dart';

class ReportDetailArguments {
  const ReportDetailArguments({required this.report, required this.isOnline});

  final RoadReport report;
  final bool isOnline;
}

class NoteFormArguments {
  const NoteFormArguments({required this.report});

  final RoadReport report;
}

// Nama route dan pemeriksaan tipe argumen dipusatkan di sini.
class AppRoutes {
  static const login = '/login';
  static const home = '/home';
  static const detail = '/detail';
  static const note = '/note';
  static const reportHistory = '/report-history';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const LoginScreen(),
        );
      case home:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const HomeShell(),
        );
      case detail:
        final arguments = settings.arguments;
        if (arguments is! ReportDetailArguments) return _unknownRoute(settings);
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => ReportDetailScreen(
            report: arguments.report,
            isOnline: arguments.isOnline,
          ),
        );
      case note:
        final arguments = settings.arguments;
        if (arguments is! NoteFormArguments) return _unknownRoute(settings);
        return MaterialPageRoute<String>(
          settings: settings,
          builder: (_) => NoteFormScreen(report: arguments.report),
        );
      case reportHistory:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const RiwayatLaporanPage(),
        );
      default:
        return _unknownRoute(settings);
    }
  }

  static Route<dynamic> _unknownRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const Scaffold(
        body: Center(child: Text('Halaman tidak ditemukan.')),
      ),
    );
  }
}