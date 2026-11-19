import 'dart:collection';

import '../../domain/repositories/account_local_data_gateway.dart';

/// Implementasi gabungan gateway data lokal untuk mengagregasi
/// pengecekan antrean dan pembersihan data dari berbagai modul anggota tim.
class CompositeAccountLocalDataGateway implements AccountLocalDataGateway {
  CompositeAccountLocalDataGateway([List<AccountLocalDataGateway>? gateways])
      : _gateways = gateways != null
            ? List<AccountLocalDataGateway>.from(gateways)
            : <AccountLocalDataGateway>[];

  final List<AccountLocalDataGateway> _gateways;

  UnmodifiableListView<AccountLocalDataGateway> get gateways =>
      UnmodifiableListView(_gateways);

  void registerGateway(AccountLocalDataGateway gateway) {
    if (!_gateways.contains(gateway)) {
      _gateways.add(gateway);
    }
  }

  void unregisterGateway(AccountLocalDataGateway gateway) {
    _gateways.remove(gateway);
  }

  void clearGateways() {
    _gateways.clear();
  }

  @override
  Future<int> getUnsentItemCount(String userId) async {
    var total = 0;
    for (final gateway in _gateways) {
      total += await gateway.getUnsentItemCount(userId);
    }
    return total;
  }

  @override
  Future<void> clearUserData(String userId) async {
    for (final gateway in _gateways) {
      await gateway.clearUserData(userId);
    }
  }
}

/// Implementasi Mock in-memory dari [AccountLocalDataGateway]
/// untuk keperluan unit test dan demonstrasi alur FR-03 sebelum
/// database SQLite Hasyfi & Daffa siap diintegrasikan.
class MockAccountLocalDataGateway implements AccountLocalDataGateway {
  MockAccountLocalDataGateway({
    Map<String, int>? initialUnsentCounts,
  }) : _unsentCounts = initialUnsentCounts != null
            ? Map<String, int>.from(initialUnsentCounts)
            : <String, int>{};

  final Map<String, int> _unsentCounts;
  final Set<String> clearedUsers = <String>{};

  void setUnsentCount(String userId, int count) {
    _unsentCounts[userId] = count;
  }

  @override
  Future<int> getUnsentItemCount(String userId) async {
    return _unsentCounts[userId] ?? 0;
  }

  @override
  Future<void> clearUserData(String userId) async {
    clearedUsers.add(userId);
    _unsentCounts[userId] = 0;
  }
}
