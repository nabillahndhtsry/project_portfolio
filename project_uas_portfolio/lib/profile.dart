import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _fullName = '';
  String _bio = '';
  String _username = '';
  String _email = '';
  String _photoUrl = '';
  bool _isLoading = true;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('Memulai load profile data...');

      SharedPreferences prefs = await SharedPreferences.getInstance();
      _userId = prefs.getInt('user_id') ?? 1;
      debugPrint('User ID yang login: $_userId');

      final testResult = await ApiService.testProfileConnection();
      debugPrint('Test connection result: ${testResult['success']}');

      if (testResult['success'] == true) {
        final response = await ApiService.getProfile(userId: _userId!);
        debugPrint('API Response: ${response['success']}');

        if (response['success'] == true && response['data'] != null) {
          final userData = response['data'];
          debugPrint('User Data from API: $userData');

          setState(() {
            _fullName = userData['full_name']?.toString() ?? 'Nabillah Indah Tsuraya';
            _username = userData['username']?.toString() ?? 'nabillah';
            _email = userData['email']?.toString() ?? 'nabillah@example.com';
            _bio = userData['bio']?.toString() ?? 'Tulis bio Anda di sini...';
            _photoUrl = userData['photo_url']?.toString() ??
                'https://cdn-icons-png.flaticon.com/512/847/847969.png';
            _isLoading = false;
          });

          _saveToSharedPreferences(userData);

        } else {
          _loadFromSharedPreferences();
        }
      } else {
        _loadFromSharedPreferences();
      }

    } catch (e) {
      debugPrint('Error loading profile: $e');
      _loadFromSharedPreferences();
    }
  }

  Future<void> _saveToSharedPreferences(Map<String, dynamic> userData) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('full_name', userData['full_name']?.toString() ?? '');
      await prefs.setString('username', userData['username']?.toString() ?? '');
      await prefs.setString('email', userData['email']?.toString() ?? '');
      await prefs.setString('bio', userData['bio']?.toString() ?? '');
      if (userData['photo_url'] != null && userData['photo_url']!.isNotEmpty) {
        await prefs.setString('photo_url', userData['photo_url']!.toString());
      }
    } catch (e) {
      debugPrint('Error saving to SharedPreferences: $e');
    }
  }

  Future<void> _loadFromSharedPreferences() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      setState(() {
        _fullName = prefs.getString('full_name') ?? 'Nabillah Indah Tsuraya';
        _username = prefs.getString('username') ?? 'nabillah';
        _email = prefs.getString('email') ?? 'nabillah@example.com';
        _bio = prefs.getString('bio') ?? 'Tulis bio Anda di sini...';

        final savedPhotoUrl = prefs.getString('photo_url') ?? '';
        _photoUrl = (savedPhotoUrl.isNotEmpty && savedPhotoUrl.startsWith('http'))
            ? savedPhotoUrl
            : 'https://cdn-icons-png.flaticon.com/512/847/847969.png';

        _isLoading = false;
      });

    } catch (e) {
      debugPrint('Error loading from SharedPreferences: $e');

      setState(() {
        _fullName = 'Nabillah Indah Tsuraya';
        _bio = 'Tulis bio Anda di sini...';
        _username = 'nabillah';
        _email = 'nabillah@example.com';
        _photoUrl = 'https://cdn-icons-png.flaticon.com/512/847/847969.png';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadProfileData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.pinkAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
            tooltip: 'Refresh Profile',
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Foto Profile dengan preview URL
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.pink.shade100,
                  backgroundImage: (_photoUrl.isNotEmpty && _photoUrl.startsWith('http'))
                      ? NetworkImage(_photoUrl)
                      : null,
                  child: (_photoUrl.isEmpty || !_photoUrl.startsWith('http'))
                      ? const Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.pinkAccent,
                  )
                      : null,
                ),
              ],
            ),



            const SizedBox(height: 10),

            Text(
              _fullName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.pinkAccent,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 5),

            Text(
              '@$_username',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 20),

            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildProfileItem('Nama', _fullName),
                    const Divider(),
                    _buildProfileItem('Bio', _bio),
                    const Divider(),
                    _buildProfileItem('Username', _username),
                    const Divider(),
                    _buildProfileItem('Email', _email),
                    const Divider(),
                    _buildProfileItem('Foto Profil',
                        _photoUrl.startsWith('http')
                            ? 'URL Gambar'
                            : 'Default'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                _showEditDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Edit Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.pinkAccent,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getInt('user_id') ?? 1;

    TextEditingController nameController = TextEditingController(text: _fullName);
    TextEditingController emailController = TextEditingController(text: _email);
    TextEditingController bioController = TextEditingController(text: _bio);
    TextEditingController photoUrlController = TextEditingController(text: _photoUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.pinkAccent),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // Nama Lengkap
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),

              const SizedBox(height: 10),

              // Email
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),

              const SizedBox(height: 10),

              // Bio
              TextField(
                controller: bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  hintText: 'Tulis bio Anda...',
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 10),

              // ✅ TAMBAHKAN: Input URL Foto Profil
              TextField(
                controller: photoUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL Foto Profil',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                  hintText: 'https://example.com/foto.jpg',
                  helperText: 'Masukkan URL gambar valid (jpg, png, etc)',
                ),
                onChanged: (value) {
                  // Optional: Validasi real-time
                  if (value.isNotEmpty && !value.startsWith('http')) {
                    photoUrlController.text = 'https://$value';
                  }
                },
              ),

              const SizedBox(height: 10),

              // Preview URL Foto (jika ada)
              if (photoUrlController.text.isNotEmpty &&
                  photoUrlController.text.startsWith('http'))
                Column(
                  children: [
                    const Text(
                      'Preview Foto:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: Colors.green),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Image.network(
                          photoUrlController.text,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.red,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Validasi URL foto
              final photoUrl = photoUrlController.text.trim();
              if (photoUrl.isNotEmpty && !photoUrl.startsWith('http')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('URL foto harus diawali dengan http:// atau https://'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              // Update via API
              final response = await ApiService.updateProfile(
                userId: currentUserId,
                fullName: nameController.text,
                email: emailController.text,
                bio: bioController.text,
                photoUrl: photoUrl.isEmpty ? null : photoUrl, // Kirim null jika kosong
              );

              if (response['success'] == true) {
                await _loadProfileData();
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile berhasil diperbarui!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal update: ${response['message']}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
            ),
            child: const Text(
              'Simpan',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}