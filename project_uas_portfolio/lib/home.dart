import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'articles.dart';
import 'skills.dart';
import 'profile.dart';
import 'article_create.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoggedIn = false;
  String _nama = '';
  String _email = '';
  String _photoUrl = '';
  bool _isLoading = true;
  bool _hasShownWelcome = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      setState(() {
        _isLoggedIn = token != null;
      });

      if (_isLoggedIn) {
        final userId = prefs.getInt('user_id') ?? 1;
        final response = await ApiService.getUserProfileData(userId: userId);

        if (response['success'] == true && response['data'] != null) {
          final userData = response['data'];

          await prefs.setString('full_name', userData['full_name']?.toString() ?? '');
          await prefs.setString('email', userData['email']?.toString() ?? '');
          if (userData['photo_url'] != null) {
            await prefs.setString('photo_url', userData['photo_url']!.toString());
          }

          setState(() {
            _nama = userData['full_name']?.toString() ?? 'Guest';
            _email = userData['email']?.toString() ?? '';

            final photoUrl = userData['photo_url']?.toString() ?? '';
            _photoUrl = (photoUrl.isNotEmpty && photoUrl.startsWith('http'))
                ? photoUrl
                : 'https://cdn-icons-png.flaticon.com/512/847/847969.png';

            _isLoading = false;
          });

          // Tampilkan alert selamat datang sederhana
          _showSimpleWelcomeAlert(_nama);

        } else {
          _loadFromSharedPreferences(prefs);
        }
      } else {
        _loadFromSharedPreferences(prefs);
      }

    } catch (e) {
      debugPrint('Error loading user data: $e');
      _loadDefaultData();
    }
  }

  void _loadFromSharedPreferences(SharedPreferences prefs) {
    final photoUrl = prefs.getString('photo_url') ?? '';

    setState(() {
      _nama = prefs.getString('full_name') ??
          prefs.getString('nama') ??
          'Guest';
      _email = prefs.getString('email') ?? '';

      _photoUrl = (photoUrl.isNotEmpty && photoUrl.startsWith('http'))
          ? photoUrl
          : 'https://cdn-icons-png.flaticon.com/512/847/847969.png';

      _isLoading = false;
    });

    // Tampilkan alert selamat datang jika user sudah login
    if (_isLoggedIn && !_hasShownWelcome) {
      _showSimpleWelcomeAlert(_nama);
    }
  }

  void _loadDefaultData() {
    setState(() {
      _nama = 'Guest';
      _email = '';
      _photoUrl = 'https://cdn-icons-png.flaticon.com/512/847/847969.png';
      _isLoading = false;
    });
  }

  // ✅ PERBAIKAN: Fungsi untuk menampilkan alert selamat datang SEDERHANA
  void _showSimpleWelcomeAlert(String nama) {
    if (_hasShownWelcome) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => AlertDialog(
          title: const Text(
            'Selamat Datang',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.pinkAccent,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Selamat datang, $nama!',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('OK'),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        ),
      );

      _hasShownWelcome = true;
    });
  }

  Future<void> _refreshData() async {
    await _loadUserData();
  }

  void _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    setState(() {
      _isLoggedIn = false;
      _nama = 'Guest';
      _email = '';
      _photoUrl = 'https://cdn-icons-png.flaticon.com/512/847/847969.png';
      _hasShownWelcome = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Anda telah logout'),
        backgroundColor: Colors.pink,
      ),
    );
  }

  void _navigateToLogin() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
    if (result == true) {
      await _loadUserData();
    }
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio Digital'),
        backgroundColor: Colors.pinkAccent,
        actions: [
          if (_isLoggedIn)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshData,
              tooltip: 'Refresh Data',
            ),
          if (_isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
            )
          else
            IconButton(
              icon: const Icon(Icons.login),
              onPressed: _navigateToLogin,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Colors.pinkAccent,
        ),
      )
          : Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan foto profil
            Row(
              children: [
                // Foto Profil
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.pinkAccent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pinkAccent.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.pinkAccent.withOpacity(0.1),
                    backgroundImage: (_photoUrl.isNotEmpty && _photoUrl.startsWith('http'))
                        ? NetworkImage(_photoUrl)
                        : null,
                    child: (_photoUrl.isEmpty || !_photoUrl.startsWith('http'))
                        ? const Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.pinkAccent,
                    )
                        : null,
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, $_nama!',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.pinkAccent,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      if (_isLoggedIn && _email.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      if (!_isLoggedIn) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Login untuk akses penuh',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Pesan jika belum login
            if (!_isLoggedIn)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFCC80)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.orange),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Anda belum login. Beberapa fitur terbatas.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                    TextButton(
                      onPressed: _navigateToLogin,
                      child: const Text('Login Sekarang'),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 30),

            const Text(
              'Menu Utama',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.pinkAccent,
              ),
            ),
            const SizedBox(height: 15),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                children: [
                  _buildMenuCard(context, 'Artikel', Icons.article, Colors.blue, () {
                    if (!_isLoggedIn) {
                      _showLoginDialog();
                      return;
                    }
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ArticlesScreen()
                        )
                    ).then((value) {
                      _refreshData();
                    });
                  }),

                  _buildMenuCard(context, 'Skills', Icons.code, Colors.green, () {
                    if (!_isLoggedIn) {
                      _showLoginSnackbar();
                      return;
                    }
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SkillsScreen()
                        )
                    ).then((value) {
                      _refreshData();
                    });
                  }),

                  _buildMenuCard(context, 'Profile', Icons.person, Colors.orange, () {
                    if (!_isLoggedIn) {
                      _showLoginDialog();
                      return;
                    }
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ProfileScreen()
                        )
                    ).then((value) {
                      _refreshData();
                    });
                  }),

                  _buildMenuCard(context, 'About', Icons.info, Colors.purple, () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text(
                          'Tentang Aplikasi',
                          style: TextStyle(color: Colors.pinkAccent),
                        ),
                        content: const Text(
                          'Portfolio Digital v1.0\n\n'
                              'Dibuat dengan Flutter & Dart.\n'
                              'Terhubung dengan REST API (PHP & MySQL).\n\n'
                              'Developer: Nabillah Indah Tsuraya\n'
                              'NIM: 2023230019\n'
                              'Mata Kuliah: Mobile Computing',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isLoggedIn
          ? FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ArticleCreateScreen()),
          );
          if (result == true) {
            _refreshData();
          }
        },
        backgroundColor: Colors.pinkAccent,
        tooltip: 'Tambah Artikel',
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
    );
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Akses Ditolak',
          style: TextStyle(color: Colors.pinkAccent),
        ),
        content: const Text('Anda harus login terlebih dahulu untuk mengakses fitur ini.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nanti'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToLogin();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
            ),
            child: const Text('Login Sekarang'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  void _showLoginSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Anda harus login untuk mengakses fitur ini.'),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
          label: 'LOGIN',
          textColor: Colors.white,
          onPressed: _navigateToLogin,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}