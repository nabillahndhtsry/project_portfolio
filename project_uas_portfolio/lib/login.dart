import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'register.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    // Validasi input
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Peringatan'),
          content: const Text('Username dan password harus diisi'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Panggil API login
    final result = await ApiService.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    // Untuk debugging: Cetak respons mentah dari API untuk melihat apa yang sebenarnya diterima.
    debugPrint('Respons dari API Login: ${jsonEncode(result)}');

    setState(() {
      _isLoading = false;
    });

    // Handle response
    if (result['success'] == true && result.containsKey('token') && result['token'] != null) {
      // Simpan data ke SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final userData = result['user'] ?? {};

      // [FIX] Mengonversi ID pengguna dari String ke int dengan aman.
      final userId = int.tryParse(userData['id']?.toString() ?? '0') ?? 0;
      final username = userData['username'] ?? _usernameController.text;
      final fullName = userData['full_name'] ?? 'User';

      await prefs.setString('token', result['token']); // Simpan token
      await prefs.setString('username', username);
      await prefs.setString('full_name', fullName); // Simpan nama lengkap
      await prefs.setString('nama', fullName); // Untuk kompatibilitas
      await prefs.setString('email', userData['email'] ?? '');
      await prefs.setInt('user_id', userId); // Simpan ID yang sudah menjadi integer

      // ✅ TAMBAHKAN: Simpan pesan selamat datang
      final welcomeMessage = 'Selamat datang, $fullName!';
      await prefs.setString('welcome_message', welcomeMessage);
      await prefs.setString('last_login_time', DateTime.now().toIso8601String());

      debugPrint('Pesan selamat datang disimpan: $welcomeMessage');

      // Tampilkan snackbar sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Login berhasil'),
          backgroundColor: Colors.green,
        ),
      );

      // Kembali ke home screen
      Navigator.pop(context, true); // Kirim nilai true untuk menandakan login sukses
    } else {
      // Logika error yang lebih baik untuk membantu debugging
      String errorMessage = result['message'] ?? 'Terjadi error yang tidak diketahui.';

      if (result['success'] == true && (!result.containsKey('token') || result['token'] == null)) {
        errorMessage = 'Server merespons login berhasil, tetapi tidak mengirimkan "token" autentikasi. Navigasi dibatalkan. Pastikan file login.php Anda mengirimkan kembali token.';
      }

      // Tampilkan dialog error
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Gagal'),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Colors.pinkAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Gambar
              Image.network(
                'https://cdn-icons-png.flaticon.com/512/847/847969.png',
                height: 120,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.person, size: 100, color: Colors.pinkAccent);
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Login Portfolio',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Masukkan username dan password untuk mengakses fitur lengkap',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // Input username
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 20),

              // Input password
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 30),

              // Tombol login
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.pinkAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'LOGIN',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Tombol Register
              TextButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                  );
                  if (result == true) {
                    Navigator.pop(context, true); // Kembali ke home dengan status login
                  }
                },
                child: const Text(
                  'Belum punya akun? Daftar di sini',
                  style: TextStyle(
                    color: Colors.pinkAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}