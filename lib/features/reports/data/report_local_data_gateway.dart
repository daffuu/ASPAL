import '../../auth/domain/repositories/account_local_data_gateway.dart';
import 'report_local_data_source.dart';

class ReportLocalDataGateway implements AccountLocalDataGateway {
  const ReportLocalDataGateway(this._local);
  final ReportLocalDataSource _local;

  @override
  Future<int> getUnsentItemCount(String userId) => _local.countUnsent(userId);
  @override
  Future<void> clearUserData(String userId) => _local.clearUserData(userId);
}
