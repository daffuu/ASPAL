// Aturan validasi terpusat untuk form aplikasi.
String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return 'Masukkan email yang valid.';
  }
  return null;
}

String? validatePassword(String? value) {
  if ((value ?? '').length < 8) return 'Kata sandi minimal 8 karakter.';
  return null;
}

String? validateNote(String? value) {
  if ((value ?? '').trim().isEmpty) return 'Catatan tidak boleh kosong.';
  return null;
}