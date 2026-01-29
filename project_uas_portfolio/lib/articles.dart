import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'article_create.dart';
import 'article_edit.dart';

class ArticlesScreen extends StatefulWidget {
  const ArticlesScreen({super.key});

  @override
  State<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> {
  List<dynamic> _articles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    setState(() {
      _isLoading = true;
    });

    final articles = await ApiService.getArticles();
    setState(() {
      _articles = articles;
      _isLoading = false;
    });
  }

  void _navigateToCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ArticleCreateScreen()),
    );

    if (result == true) {
      _loadArticles(); // Refresh list
    }
  }

  void _navigateToEdit(Map<String, dynamic> article) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleEditScreen(article: article),
      ),
    );

    if (result == true) {
      _loadArticles(); // Refresh list
    }
  }

  // Fungsi untuk menampilkan gambar (dari URL atau asset)
  // Fungsi untuk menampilkan gambar (dari URL atau asset)
  Widget _buildArticleImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        height: 180,
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.article, size: 60, color: Colors.grey),
        ),
      );
    }

    // Jika imageUrl adalah path asset lokal
    if (imageUrl.startsWith('assets/')) {
      return Container(
        height: 180,
        color: Colors.grey[200],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning, size: 40, color: Colors.orange),
              SizedBox(height: 8),
              Text('Gambar asset lokal'),
              Text('(hanya preview)'),
            ],
          ),
        ),
      );
    }

    // ✅ PERBAIKAN: Jika imageUrl adalah path relatif server
    // Contoh: "uploads/articles/filename.jpg" atau "articles/filename.jpg"
    if (imageUrl.contains('uploads/') || imageUrl.contains('articles/')) {
      // ✅ BENAR: Gunakan base URL server Anda
      final baseUrl = 'https://tifaw.my.id/nabillah_portfolio_uas/portfolio_api_uasproject/';

      // Handle berbagai format path:
      String fullUrl;

      if (imageUrl.startsWith('uploads/')) {
        // Format: "uploads/articles/filename.jpg"
        fullUrl = baseUrl + imageUrl;
      } else if (imageUrl.startsWith('articles/')) {
        // Format: "articles/filename.jpg"
        fullUrl = baseUrl + 'uploads/' + imageUrl;
      } else if (imageUrl.startsWith('/')) {
        // Format: "/uploads/articles/filename.jpg"
        fullUrl = baseUrl + imageUrl.substring(1);
      } else {
        // Default
        fullUrl = baseUrl + 'uploads/articles/' + imageUrl;
      }

      debugPrint('Loading image from: $fullUrl');

      return ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(8),
        ),
        child: Image.network(
          fullUrl,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error loading image: $error');
            return Container(
              height: 180,
              color: Colors.grey[200],
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 40, color: Colors.red),
                    SizedBox(height: 8),
                    Text('Gagal memuat gambar'),
                  ],
                ),
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 180,
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
        ),
      );
    }

    // Jika imageUrl adalah URL eksternal lengkap (http:// atau https://)
    if (imageUrl.startsWith('http')) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(8),
        ),
        child: Image.network(
          imageUrl,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 180,
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.broken_image, size: 40),
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 180,
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          },
        ),
      );
    }

    // Fallback untuk format lainnya
    return Container(
      height: 180,
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 60, color: Colors.grey),
            SizedBox(height: 8),
            Text('URL: ${imageUrl.length > 30 ? '${imageUrl.substring(0, 30)}...' : imageUrl}'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artikel'),

        backgroundColor: Colors.pinkAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadArticles,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreate,
        backgroundColor: Colors.pinkAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _articles.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Belum ada artikel',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 10),
            Text(
              'Tekan tombol + untuk membuat artikel baru',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadArticles,
        child: ListView.builder(
          itemCount: _articles.length,
          itemBuilder: (context, index) {
            final article = _articles[index];
            return Card(
              margin: const EdgeInsets.all(10),
              elevation: 3,
              child: InkWell(
                onTap: () => _navigateToEdit(article),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gambar
                    _buildArticleImage(article['image_url']),

                    // Konten
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            article['title'] ?? 'Tidak ada judul',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 8),

                          Text(
                            article['content'] ?? '',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.grey),
                          ),

                          const SizedBox(height: 8),

                          // Info tambahan
                          Row(
                            children: [
                              const Icon(Icons.person, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                'User ID: ${article['user_id'] ?? 'N/A'}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const Spacer(),
                              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                article['created_at']?.split(' ').first ?? '',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}