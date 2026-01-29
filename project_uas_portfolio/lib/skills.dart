import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  List<dynamic> _skills = [];
  bool _isLoading = true;
  final TextEditingController _skillController = TextEditingController();
  final TextEditingController _levelController = TextEditingController();
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _loadSkills();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('user_id');
    debugPrint('User ID loaded: $_userId');
  }

  Future<void> _loadSkills() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final skills = await ApiService.getSkills();
      if (mounted) {
        setState(() {
          _skills = skills;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Gagal memuat skills: ${e.toString()}');
      }
    }
  }

  Future<void> _addSkill() async {
    if (_skillController.text.isEmpty || _levelController.text.isEmpty) {
      _showSnackBar('Nama skill dan level harus diisi!');
      return;
    }

    final level = int.tryParse(_levelController.text) ?? 0;
    if (level < 0 || level > 100) {
      _showSnackBar('Level harus antara 0-100!');
      return;
    }

    if (_userId == null) {
      _showSnackBar('User ID tidak ditemukan. Silakan login ulang.');
      return;
    }

    try {
      final response = await ApiService.createSkill(
        userId: _userId!,
        skillName: _skillController.text,
        level: level,
      );

      if (response['success'] == true) {
        await _loadSkills(); // Reload data dari API
        _skillController.clear();
        _levelController.clear();
        _showSnackBar('Skill berhasil ditambahkan!');
      } else {
        _showSnackBar('Gagal menambah skill: ${response['message']}');
      }
    } catch (e) {
      _showSnackBar('Gagal menambah skill: ${e.toString()}');
    }
  }

  // Fungsi untuk delete skill
  // Fungsi untuk delete skill
  Future<void> _deleteSkill(int id, String skillName) async {
    debugPrint('=== DELETE SKILL DIALOG ===');
    debugPrint('ID: $id (Type: ${id.runtimeType})');
    debugPrint('Name: $skillName');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Skill'),
        content: Text('Yakin ingin menghapus skill "$skillName"?'),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('Delete cancelled');
              Navigator.pop(context);
            },
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              debugPrint('Delete confirmed');
              Navigator.pop(context);
              await _performDelete(id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

// Fungsi untuk melakukan delete ke API
  Future<void> _performDelete(int id) async {
    debugPrint('=== PERFORM DELETE ===');
    debugPrint('Deleting ID: $id');

    try {
      final response = await ApiService.deleteSkill(id);

      debugPrint('Delete Response: $response');

      if (response['success'] == true) {
        // Hapus dari state lokal
        if (mounted) {
          setState(() {
            _skills.removeWhere((skill) {
              final skillId = int.tryParse(skill['id'].toString()) ?? 0;
              return skillId == id;
            });
          });
        }
        _showSnackBar('Skill berhasil dihapus!');
      } else {
        _showSnackBar('Gagal menghapus skill: ${response['message']}');
      }
    } catch (e) {
      debugPrint('Delete Error: $e');
      _showSnackBar('Gagal menghapus skill: ${e.toString()}');
    }
  }

  // Fungsi untuk edit skill (opsional)
  void _editSkill(dynamic skill) {
    debugPrint('=== EDIT SKILL TRIGGERED ===');
    debugPrint('Skill Data: $skill');

    _skillController.text = skill['skill_name']?.toString() ?? '';
    _levelController.text = skill['level']?.toString() ?? '';

    // Konversi id dari String ke int
    final skillId = int.tryParse(skill['id'].toString()) ?? 0;
    debugPrint('Skill ID (converted to int): $skillId');

    // Tampilkan dialog konfirmasi edit
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Skill'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _skillController,
              decoration: const InputDecoration(
                labelText: 'Nama Skill',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _levelController,
              decoration: const InputDecoration(
                labelText: 'Level (0-100)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('Edit cancelled');
              Navigator.pop(context);
            },
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              debugPrint('Edit confirmed, calling _updateSkill');
              Navigator.pop(context);
              await _updateSkill(skillId);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateSkill(int id) async {
    debugPrint('=== _updateSkill CALLED ===');
    debugPrint('ID: $id (Type: ${id.runtimeType})');

    if (_skillController.text.isEmpty || _levelController.text.isEmpty) {
      debugPrint('Validation failed: Empty fields');
      _showSnackBar('Nama skill dan level harus diisi!');
      return;
    }

    final level = int.tryParse(_levelController.text) ?? 0;
    debugPrint('Level parsed: $level');

    if (level < 0 || level > 100) {
      debugPrint('Validation failed: Level out of range');
      _showSnackBar('Level harus antara 0-100!');
      return;
    }

    debugPrint('=== UPDATING SKILL ===');
    debugPrint('Skill ID: $id');
    debugPrint('New Name: ${_skillController.text}');
    debugPrint('New Level: $level');
    debugPrint('User ID: $_userId');

    try {
      debugPrint('Calling ApiService.updateSkill...');

      final response = await ApiService.updateSkill(
        id: id,
        skillName: _skillController.text,
        level: level,
      );

      debugPrint('=== UPDATE RESPONSE ===');
      debugPrint('Success: ${response['success']}');
      debugPrint('Message: ${response['message']}');
      debugPrint('Full Response: $response');

      if (response['success'] == true) {
        debugPrint('Update successful, reloading skills...');
        await _loadSkills(); // Reload data dari API
        _skillController.clear();
        _levelController.clear();
        _showSnackBar('Skill berhasil diupdate!');
      } else {
        debugPrint('Update failed: ${response['message']}');
        _showSnackBar('Update gagal: ${response['message']}');
      }
    } catch (e) {
      debugPrint('=== UPDATE ERROR ===');
      debugPrint('Error: $e');
      debugPrint('Stack Trace: ${e.toString()}');
      _showSnackBar('Gagal mengupdate skill: ${e.toString()}');
    }
  }

// Metode alternatif jika update tidak bekerja
  Future<void> _tryAlternativeUpdate(int id, int level) async {
    try {
      debugPrint('Trying alternative update method...');

      // Opsi 1: Coba dengan approach yang berbeda
      if (_userId != null) {
        debugPrint('Using delete + create method...');

        // 1. Hapus skill lama
        final deleteResponse = await ApiService.deleteSkill(id);
        debugPrint('Delete Response: $deleteResponse');

        if (deleteResponse['success'] == true) {
          // 2. Buat skill baru
          final createResponse = await ApiService.createSkill(
            userId: _userId!,
            skillName: _skillController.text,
            level: level,
          );

          debugPrint('Create Response: $createResponse');

          if (createResponse['success'] == true) {
            await _loadSkills();
            _skillController.clear();
            _levelController.clear();
            _showSnackBar('Skill berhasil diupdate (via delete+create)!');
          } else {
            _showSnackBar('Gagal membuat skill baru: ${createResponse['message']}');
          }
        } else {
          _showSnackBar('Gagal menghapus skill lama: ${deleteResponse['message']}');
        }
      }
    } catch (e) {
      debugPrint('Alternative update error: $e');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _skillController.dispose();
    _levelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skills'),
        backgroundColor: Colors.pinkAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSkills,
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Form input
            Card(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    const Text(
                      'Tambah Skill Baru',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _skillController,
                      decoration: InputDecoration(
                        labelText: 'Nama Skill',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _levelController,
                      decoration: InputDecoration(
                        labelText: 'Level (0-100)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addSkill,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                        ),
                        child: const Text('TAMBAH', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // List skills
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _skills.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.list, size: 60, color: Colors.grey),
                    SizedBox(height: 10),
                    Text(
                      'Belum ada skills',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      'Tambahkan skill pertama Anda!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: _skills.length,
                itemBuilder: (context, index) {
                  final skill = _skills[index];
                  final level = int.tryParse(skill['level'].toString()) ?? 0;
                  final skillName = skill['skill_name']?.toString() ?? 'Unknown';
                  final skillId = int.tryParse(skill['id'].toString()) ?? 0;

                  debugPrint('List Item - Skill ID: $skillId (Type: ${skillId.runtimeType})');

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.pinkAccent.withValues(alpha: 0.2),
                        child: Text('${index + 1}'),
                      ),
                      title: Text(skillName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 5),
                          LinearProgressIndicator(
                            value: level / 100,
                            backgroundColor: Colors.grey[300],
                            color: Colors.pinkAccent,
                          ),
                          const SizedBox(height: 5),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$level%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Tombol Edit
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _editSkill(skill),
                            tooltip: 'Edit Skill',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          // Tombol Delete
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                            onPressed: () => _deleteSkill(skillId, skillName),
                            tooltip: 'Hapus Skill',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(skillName),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Level: $level%'),
                                const SizedBox(height: 10),
                                LinearProgressIndicator(
                                  value: level / 100,
                                  backgroundColor: Colors.grey[300],
                                  color: Colors.pinkAccent,
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}