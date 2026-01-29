import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _register() async {
    // Validasi
    if (_fullNameController.text.isEmpty) {
      _showError('Nama lengkap harus diisi');
      return;
    }
    if (_usernameController.text.isEmpty) {
      _showError('Username harus diisi');
      return;
    }
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      _showError('Email harus valid');
      return;
    }
    if (_passwordController.text.isEmpty || _passwordController.text.length < 6) {
      _showError('Password minimal 6 karakter');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Password dan konfirmasi password tidak sama');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ HAPUS parameter profileImage
      final result = await ApiService.register(
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        // profileImage: _profileImage, // ← DIHAPUS
      );

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        // Auto login setelah registrasi berhasil
        final loginResult = await ApiService.login(
          _usernameController.text.trim(),
          _passwordController.text.trim(),
        );

        if (loginResult['success'] == true && loginResult['token'] != null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          final userData = loginResult['user'] ?? {};

          await prefs.setString('token', loginResult['token']);
          await prefs.setString('full_name', userData['full_name'] ?? _fullNameController.text);
          await prefs.setString('username', userData['username'] ?? _usernameController.text);
          await prefs.setString('email', userData['email'] ?? _emailController.text);
          await prefs.setInt('user_id', int.tryParse(userData['id']?.toString() ?? '0') ?? 0);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Registrasi berhasil!'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pop(context, true); // Kembali ke home dengan status sukses
        } else {
          // Registrasi berhasil tapi login gagal
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Registrasi berhasil! Silakan login manual.'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context); // Kembali ke login
        }
      } else {
        _showError(result['message'] ?? 'Registrasi gagal');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrasi'),
        backgroundColor: Colors.pinkAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Judul
            const Text(
              'Buat Akun Baru',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.pinkAccent,
              ),
            ),
            const SizedBox(height: 30),

            // Form Input
            _buildTextField(
              controller: _fullNameController,
              label: 'Nama Lengkap',
              icon: Icons.person,
              hint: 'Masukkan nama lengkap',
            ),
            const SizedBox(height: 15),

            _buildTextField(
              controller: _usernameController,
              label: 'Username',
              icon: Icons.alternate_email,
              hint: 'Masukkan username',
            ),
            const SizedBox(height: 15),

            _buildTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email,
              hint: 'Masukkan email',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 15),

            _buildPasswordField(
              controller: _passwordController,
              label: 'Password',
              obscure: _obscurePassword,
              onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            const SizedBox(height: 15),

            _buildPasswordField(
              controller: _confirmPasswordController,
              label: 'Konfirmasi Password',
              obscure: _obscureConfirmPassword,
              onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
            const SizedBox(height: 30),

            // Tombol Register
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
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
                  'DAFTAR',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Link ke Login
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Sudah punya akun? '),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Login di sini',
                    style: TextStyle(
                      color: Colors.pinkAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }
}