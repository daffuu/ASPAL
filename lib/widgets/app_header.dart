import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.subtitle,
    required this.isOnline,
    this.onToggleOnline,
  });

  final String subtitle;
  final bool isOnline;
  final VoidCallback? onToggleOnline;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    final pillBg = isOnline
        ? const Color(0xFF1E40AF).withOpacity(0.5)
        : AppColors.accent.withOpacity(0.2);
    final pillBorder = isOnline
        ? const Color(0xFF60A5FA)
        : const Color(0xFFFB923C).withOpacity(0.5);
    final pillText =
        isOnline ? const Color(0xFFDBEAFE) : const Color(0xFFFFEDD5);

    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ASPAL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFFBFDBFE),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: onToggleOnline,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: pillBg,
                border: Border.all(color: pillBorder),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isOnline ? Icons.wifi : Icons.wifi_off,
                    size: 14,
                    color: pillText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      color: pillText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
