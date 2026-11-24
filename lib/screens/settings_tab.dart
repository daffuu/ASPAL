import 'package:flutter/material.dart';

import '../features/auth/auth_module.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key, this.controller});

  final AuthController? controller;

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool _logoutPending = false;

  AuthController _getController() {
    return widget.controller ?? context.maybeAuthController ?? AuthModule.controller;
  }

  @override
  void initState() {
    super.initState();
    // Cache-first: UI langsung membaca cache yang ada di AuthController.
    // Kemudian secara asinkron memperbarui profil jika online.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getController().refreshProfile();
    });
  }

  Future<void> _handleLogout(BuildContext context, AuthController controller) async {
    if (_logoutPending) return;
    setState(() => _logoutPending = true);
    try {
      await _checkQueueAndLogout(context, controller);
    } finally {
      if (mounted) setState(() => _logoutPending = false);
    }
  }

  Future<void> _checkQueueAndLogout(BuildContext context, AuthController controller) async {
    // 1. Periksa jumlah item (laporan dan tindak lanjut) yang belum terkirim
    final int unsentCount;
    try {
      unsentCount = await controller.getUnsentItemCount();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memeriksa antrean. Coba keluar lagi.')),
      );
      return;
    }

    if (!context.mounted) return;

    if (unsentCount > 0) {
      // 2. Tampilkan dialog peringatan FR-03 jika ada item belum terkirim
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) {
          return AlertDialog(
            key: const Key('logout-warning-dialog'),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                SizedBox(width: 8),
                Text(
                  'Perhatian',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            content: Text(
              'Terdapat $unsentCount laporan / tindak lanjut yang belum terkirim ke server '
              '(status Draft, Menunggu Sinyal, atau Gagal).\n\n'
              'Jika Anda keluar sekarang, data lokal tersebut akan dihapus secara permanen dari perangkat.',
              style: const TextStyle(height: 1.4, fontSize: 14),
            ),
            actions: [
              TextButton(
                key: const Key('cancel-logout-btn'),
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                key: const Key('confirm-logout-btn'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                ),
                onPressed: () => Navigator.pop(dialogCtx, true),
                child: const Text('Tetap Keluar & Hapus'),
              ),
            ],
          );
        },
      );

      // Jika pengguna membatalkan, jangan ubah sesi atau data
      if (confirmed != true) {
        return;
      }
    }

    if (!context.mounted) return;

    // 3. Lakukan logout dan pembersihan data lokal akun
    final LogoutResult result;
    try {
      result = await controller.logout();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembersihan data lokal gagal. Coba keluar lagi.')),
      );
      return;
    }

    if (!context.mounted) return;

    // Jika pencabutan sesi di server belum terkonfirmasi (misal saat offline)
    if (result.hasUnconfirmedServerRevocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Keluar secara lokal berhasil. Pencabutan token di server belum terkonfirmasi (sedang offline).',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _getController();

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final user = controller.currentUser;
        final displayName = user?.displayName.isNotEmpty == true
            ? user!.displayName
            : 'Pengguna ASPAL';
        final email = user?.email.isNotEmpty == true ? user!.email : '-';

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            children: [
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    // Item Profil Pengguna (Edit Nama)
                    _SettingsItem(
                      key: const Key('settings-profile-item'),
                      icon: Icons.person_outline,
                      label: 'Profil Pengguna',
                      sub: '$displayName · $email',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute<bool>(
                            builder: (_) => EditProfileScreen(
                              controller: widget.controller,
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, color: AppColors.border),

                    // Item Ubah Kata Sandi
                    _SettingsItem(
                      key: const Key('settings-change-password-item'),
                      icon: Icons.lock_outline,
                      label: 'Ubah Kata Sandi',
                      sub: 'Perbarui kata sandi akun Anda',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute<bool>(
                            builder: (_) => ChangePasswordScreen(
                              controller: widget.controller,
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, color: AppColors.border),

                    // Item Pengaturan Tambahan (Legacy preserved)
                    _SettingsItem(
                      icon: Icons.cloud_off_outlined,
                      label: 'Mode Offline',
                      sub: controller.isOffline
                          ? 'Aktif (Sesi lokal valid)'
                          : 'Simpan laporan tanpa koneksi',
                      onTap: () {},
                    ),
                    const Divider(height: 1, color: AppColors.border),

                    _SettingsItem(
                      icon: Icons.photo_camera_outlined,
                      label: 'Kualitas Foto',
                      sub: 'Tinggi (Kompresi ≤ 2 MB)',
                      onTap: () {},
                    ),
                    const Divider(height: 1, color: AppColors.border),

                    _SettingsItem(
                      icon: Icons.notifications_none_outlined,
                      label: 'Notifikasi',
                      sub: 'Aktif',
                      onTap: () {},
                    ),
                    const Divider(height: 1, color: AppColors.border),

                    _SettingsItem(
                      icon: Icons.info_outline,
                      label: 'Tentang Aplikasi',
                      sub: 'ASPAL v1.0.0 (Modul Autentikasi)',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Tombol Logout dengan penanganan konfirmasi data antrean (FR-03)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  key: const Key('settings-logout-btn'),
                  onPressed: _logoutPending ? null : () => _handleLogout(context, controller),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    backgroundColor: const Color(0xFFFEF2F2),
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Keluar dari Akun'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    super.key,
    required this.icon,
    required this.label,
    required this.sub,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
