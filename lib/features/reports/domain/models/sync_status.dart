enum SyncStatus {
  draft('DRAFT'),
  menungguSinyal('MENUNGGU_SINYAL'),
  mengirim('MENGIRIM'),
  gagalTerkirim('GAGAL_TERKIRIM'),
  terkirim('TERKIRIM');

  const SyncStatus(this.databaseValue);
  final String databaseValue;

  static SyncStatus fromDatabase(String value) =>
      values.firstWhere((status) => status.databaseValue == value);
}
