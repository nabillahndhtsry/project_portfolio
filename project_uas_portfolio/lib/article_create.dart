import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ByteData sudah ada di sini
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart'; // Import ini
import 'package:path/path.dart' as path;
import '../services/api_service.dart';

class ArticleCreateScreen extends StatefulWidget {
  const ArticleCreateScreen({super.key});

  @override
  State<ArticleCreateScreen> createState() => _ArticleCreateScreenState();
}

class _ArticleCreateScreenState extends State<ArticleCreateScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _selectedAssetImage;
  File? _imageFile;

  // Daftar gambar dari assets lokal
  final List<String> _localImages = [
    'assets/images/artikel1.jpg',
    'assets/images/artikel2.jpg',
    'assets/images/artikel3.jpg',
    'assets/images/artikel4.jpg',
    'assets/images/artikel5.jpg',
    'assets/images/default_article.jpg',
  ];

  // Fungsi untuk mengonversi asset ke File
  Future<File> _convertAssetToFile(String assetPath) async {
    try {
      debugPrint('Converting asset: $assetPath');

      // Load asset dari bundle
      final ByteData data = await rootBundle.load(assetPath);

      // Dapatkan directory temporary - FIX: await harus di sini
      final directory = await getTemporaryDirectory();

      // Buat nama file unik
      final filename = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(assetPath)}';
      final file = File('${directory.path}/$filename');

      // Tulis data ke file
      await file.writeAsBytes(data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      ));

      debugPrint('Asset converted to: ${file.path}');
      debugPrint('File size: ${await file.length()} bytes');

      return file;
    } catch (e) {
      debugPrint('Error converting asset: $e');
      rethrow;
    }
  }

  void _selectAssetImage(String assetPath) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Konversi asset ke File
      final file = await _convertAssetToFile(assetPath);

      // Check mounted sebelum setState
      if (!mounted) return;

      setState(() {
        _selectedAssetImage = assetPath;
        _imageFile = file;
        _isLoading = false;
        _imageUrlController.clear();
      });

      // Check mounted sebelum showSnackBar
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gambar siap diupload: ${path.basename(assetPath)}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat gambar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createArticle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int userId = prefs.getInt('user_id') ?? 1;

    try {
      final result = await ApiService.createArticle(
        userId: userId,
        title: _titleController.text,
        content: _contentController.text,
        imageUrl: _imageUrlController.text.isNotEmpty &&
            _imageUrlController.text.startsWith('http')
            ? _imageUrlController.text
            : null,
        imageFile: _imageFile,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Artikel berhasil dibuat'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal membuat artikel'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearSelectedImage() {
    setState(() {
      _selectedAssetImage = null;
      _imageFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Artikel Baru'),
        backgroundColor: Colors.pinkAccent,
        actions: [
          if (_selectedAssetImage != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : _clearSelectedImage,
              tooltip: 'Hapus gambar',
            ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _createArticle,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Judul
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul Artikel',
                  border: OutlineInputBorder(),
                  hintText: 'Masukkan judul artikel',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Judul harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Konten
              TextFormField(
                controller: _contentController,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Konten Artikel',
                  border: OutlineInputBorder(),
                  hintText: 'Masukkan konten artikel',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Konten harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Pilih Gambar dari Assets Lokal
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih Gambar dari Assets',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Pilih salah satu gambar dari assets lokal:',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),

                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                          itemCount: _localImages.length,
                          itemBuilder: (context, index) {
                            final assetPath = _localImages[index];
                            return GestureDetector(
                              onTap: () => _selectAssetImage(assetPath),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _selectedAssetImage == assetPath
                                        ? Colors.pinkAccent
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: Image.asset(
                                    assetPath,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: Icon(Icons.image, color: Colors.grey),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Preview gambar yang dipilih
                      if (_selectedAssetImage != null && _imageFile != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Gambar yang dipilih:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                Text(
                                  'File siap diupload',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              height: 150,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _imageFile!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.error, color: Colors.red),
                                            SizedBox(height: 8),
                                            Text('Gagal memuat file'),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'File: ${path.basename(_imageFile!.path)}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              'Size: ${(_imageFile!.lengthSync() / 1024).toStringAsFixed(2)} KB',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Atau masukkan URL eksternal
                      TextFormField(
                        controller: _imageUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Atau masukkan URL Gambar Eksternal',
                          border: OutlineInputBorder(),
                          hintText: 'https://example.com/image.jpg',
                          prefixIcon: Icon(Icons.link),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && value.startsWith('http')) {
                            setState(() {
                              _selectedAssetImage = null;
                              _imageFile = null;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _createArticle,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Simpan Artikel'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}