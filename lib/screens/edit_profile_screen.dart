
import 'package:flutter/material.dart';

import '../features/auth/auth_module.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, this.controller});

  final AuthController? controller;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late AuthController _authController;

  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    // Inisialisasi controller input terlebih dahulu.
    // Jangan mengakses AuthScope atau InheritedWidget di sini.
    _nameController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Ambil AuthController setelah initState selesai.
    // Aman untuk mengakses AuthScope di sini.
    _authController = widget.controller ??
        context.maybeAuthController ??
        AuthModule.controller;

    // Isi nama pengguna hanya satu kali.
    // Agar perubahan yang sedang diketik tidak tertimpa
    // ketika dependency berubah.
    if (!_isInitialized) {
      final initialName =
          _authController.currentUser?.displayName ?? '';

      _nameController.text = initialName;

      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Gunakan AuthController yang sudah diperoleh
      // melalui didChangeDependencies().
      final success = await _authController.updateProfile(
        _nameController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui'),
            backgroundColor: AppColors.success,
          ),
        );

        Navigator.pop(context, true);
      } else {
        final error = _authController.errorMessage ??
            'Gagal memperbarui profil';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ubah Nama Profil',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.text,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('edit-name-field'),
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Nama Lengkap',
                    prefixIcon: const Icon(Icons.person_outline),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) => Validators.minLength(
                    v,
                    2,
                    fieldName: 'Nama Lengkap',
                  ),
                ),

                const SizedBox(height: 24),

                FilledButton(
                  key: const Key('save-profile-btn'),
                  onPressed: _isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Simpan Perubahan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
