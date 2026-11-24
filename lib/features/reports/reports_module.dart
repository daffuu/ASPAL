import '../../core/database/app_database.dart';
import '../auth/domain/repositories/token_provider.dart';
import 'data/report_local_data_gateway.dart';
import 'data/report_local_data_source.dart';
import 'data/report_repository_impl.dart';
import 'domain/repositories/report_repository.dart';

class ReportsModule {
  ReportsModule(AppDatabase database, TokenProvider auth)
    : this._(ReportLocalDataSource(database), auth);

  ReportsModule._(ReportLocalDataSource local, TokenProvider auth)
    : repository = ReportRepositoryImpl(local, auth),
      gateway = ReportLocalDataGateway(local);

  final ReportRepository repository;
  final ReportLocalDataGateway gateway;
}
