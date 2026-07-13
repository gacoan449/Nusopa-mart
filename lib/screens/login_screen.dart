Future<void> _prosesLoginFirebase() async {
  if (_hpController.text.isEmpty || _passController.text.isEmpty) {
    _notif("Harap isi semua kolom!");
    return;
  }

  setState(() => _isLoading = true);

  await Future.delayed(const Duration(seconds: 1));

  if (!mounted) return;

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const HomeScreen(),
    ),
  );
}
