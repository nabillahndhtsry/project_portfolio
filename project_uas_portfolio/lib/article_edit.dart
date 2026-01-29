import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../services/api_service.dart';

class ArticleEditScreen extends StatefulWidget {
  final Map<String, dynamic> article;

  const ArticleEditScreen({super.key, required this.article});

  @override
  State<ArticleEditScreen> createState() => _ArticleEditScreenState();
}

class _ArticleEditScreenState extends State<ArticleEditScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _imageUrlController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _selectedAssetImage;
  File? _imageFile; // ✅ SAMA SEPERTI DI CREATE

  // Daftar gambar dari assets lokal - SAMA DENGAN CREATE
  final List<String> _localImages = [
    'assets/images/artikel1.jpg',
    'assets/images/artikel2.jpg',
    'assets/images/artikel3.jpg',
    'assets/images/artikel4.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.article['title'] ?? '');
    _contentController = TextEditingController(text: widget.article['content'] ?? '');
    _imageUrlController = TextEditingController(text: widget.article['image_url'] ?? '');

    // Debug: print data artikel yang diterima
    debugPrint('=== ARTICLE DATA ===');
    debugPrint('ID: ${widget.article['id']}');
    debugPrint('Title: ${widget.article['title']}');
    debugPrint('Image URL: ${widget.article['image_url']}');
    debugPrint('==================');
  }

  // ✅ SAMA PERSIS DENGAN FUNGSI DI CREATE
  Future<File> _convertAssetToFile(String assetPath) async {
    try {
      debugPrint('Converting asset: $assetPath');

      // Load asset dari bundle
      final ByteData data = await rootBundle.load(assetPath);

      // Dapatkan directory temporary
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

  // ✅ SAMA DENGAN CREATE - PILIH GAMBAR DARI ASSETS
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
        _imageUrlController.clear(); // Clear URL karena pakai file
      });

      // Check mounted sebelum showSnackBar
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Gambar siap diupload: ${path.basename(assetPath)}'),
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
          content: Text('❌ Gagal memuat gambar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ FUNGSI UPDATE YANG BENAR - MENGGUNAKAN IMAGEFILE SEPERTI CREATE
  Future<void> _updateArticle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int userId = prefs.getInt('user_id') ?? 1;

      Map<String, dynamic> result;

      // KASUS 1: Ada file dari asset lokal yang dipilih
      if (_imageFile != null) {
        debugPrint('=== UPDATE WITH FILE UPLOAD ===');
        debugPrint('File path: ${_imageFile!.path}');
        debugPrint('File size: ${await _imageFile!.length()} bytes');

        // Gunakan createArticle API karena support file upload
        // Kita akan delete dulu yang lama, lalu create baru
        final deleteResult = await ApiService.deleteArticle(
          int.parse(widget.article['id'].toString()),
        );

        if (deleteResult['success'] == true) {
          // Create artikel baru dengan file
          result = await ApiService.createArticle(
            userId: userId,
            title: _titleController.text,
            content: _contentController.text,
            imageFile: _imageFile,
          );
        } else {
          result = {
            'success': false,
            'message': 'Gagal menghapus artikel lama'
          };
        }
      }
      // KASUS 2: Menggunakan URL eksternal
      else if (_imageUrlController.text.isNotEmpty &&
          _imageUrlController.text.startsWith('http')) {
        debugPrint('=== UPDATE WITH EXTERNAL URL ===');
        debugPrint('URL: ${_imageUrlController.text}');

        result = await ApiService.updateArticle(
          id: int.parse(widget.article['id'].toString()),
          title: _titleController.text,
          content: _contentController.text,
          imageUrl: _imageUrlController.text,
        );
      }
      // KASUS 3: Tidak ada perubahan gambar (pakai yang lama)
      else {
        debugPrint('=== UPDATE WITHOUT IMAGE CHANGE ===');

        result = await ApiService.updateArticle(
          id: int.parse(widget.article['id'].toString()),
          title: _titleController.text,
          content: _contentController.text,
          imageUrl: widget.article['image_url'], // Pakai URL lama
        );
      }

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result['message'] ?? 'Artikel berhasil diperbarui'}'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['message'] ?? 'Gagal memperbarui artikel'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteArticle() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Artikel'),
        content: const Text('Apakah Anda yakin ingin menghapus artikel ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      final result = await ApiService.deleteArticle(
        int.parse(widget.article['id'].toString()),
      );

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result['message'] ?? 'Artikel berhasil dihapus'}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['message'] ?? 'Gagal menghapus artikel'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ FUNGSI UNTUK CLEAR SELECTED IMAGE
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
        title: const Text('Edit Artikel'),
        backgroundColor: Colors.pinkAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _isLoading ? null : _deleteArticle,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _updateArticle,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // JUDUL
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul Artikel',
                  border: OutlineInputBorder(),
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

              // KONTEN
              TextFormField(
                controller: _contentController,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Konten',
                  border: OutlineInputBorder(),
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

              // ✅ KARTU PILIH GAMBAR - SAMA DENGAN CREATE
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih Gambar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // TAMPILKAN GAMBAR SAAT INI JIKA ADA
                      if (widget.article['image_url'] != null && widget.article['image_url'].isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Gambar saat ini:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              height: 150,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  'https://tifaw.my.id/nabillah_portfolio_uas/portfolio_api_uasproject/${widget.article['image_url']}',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.broken_image, size: 50),
                                            SizedBox(height: 8),
                                            Text('Gambar tidak dapat ditampilkan'),
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
                              'Path: ${widget.article['image_url']}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const Divider(),
                            const SizedBox(height: 16),
                          ],
                        ),

                      // PILIH GAMBAR BARU DARI ASSETS - SAMA DENGAN CREATE
                      const Text(
                        'Pilih gambar baru dari assets:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

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

                      // ✅ PREVIEW GAMBAR YANG DIPILIH - SAMA DENGAN CREATE
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
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: _clearSelectedImage,
                                  tooltip: 'Hapus pilihan',
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
                              'Status: ✅ Siap diupload ke server',
                              style: TextStyle(fontSize: 12, color: Colors.green),
                            ),
                          ],
                        ),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),

                      // ATAU MASUKKAN URL EKSTERNAL
                      TextFormField(
                        controller: _imageUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Atau masukkan URL Gambar Baru',
                          border: OutlineInputBorder(),
                          hintText: 'https://example.com/image.jpg',
                          prefixIcon: Icon(Icons.link),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
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
            ],
          ),
        ),
      ),
    );
  }
}