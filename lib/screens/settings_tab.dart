import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../routes/app_routes.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  static const _items = [
    (label: 'Profil Pengguna', sub: 'Budi Santoso · budi@email.com'),
    (label: 'Mode Offline', sub: 'Simpan laporan tanpa koneksi'),
    (label: 'Kualitas Foto', sub: 'Tinggi (4 MP)'),
    (label: 'Notifikasi', sub: 'Aktif'),
    (label: 'Tentang Aplikasi', sub: 'ASPAL v1.0.0'),
  ];

  @override
  Widget build(BuildContext context) {
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
                for (var i = 0; i < _items.length; i++)
                  InkWell(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        border: i < _items.length - 1
                            ? const Border(
                                bottom: BorderSide(color: AppColors.border))
                            : null,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _items[i].label,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _items[i].sub,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              size: 18, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, AppRoutes.login),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                backgroundColor: const Color(0xFFFEF2F2),
                side: const BorderSide(color: Color(0xFFFECACA)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
  }
}
