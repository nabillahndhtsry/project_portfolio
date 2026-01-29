// File: lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Ganti dengan URL API PHP Anda
  static const String _baseUrl = 'https://tifaw.my.id/nabillah_portfolio_uas/portfolio_api_uasproject/';

  // Fungsi untuk mendapatkan token dari SharedPreferences
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Tambahkan fungsi untuk test connection
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/articles/list.php'),
      );

      debugPrint('Test Connection Status: ${response.statusCode}');
      debugPrint('Test Connection Response: ${response.body}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Connection successful',
          'data': jsonDecode(response.body)
        };
      } else {
        return {
          'success': false,
          'message': 'Connection failed: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e'
      };
    }
  }

  // ✅ FIXED: Fungsi register yang benar
  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('=== REGISTER API CALL ===');
      debugPrint('URL: ${_baseUrl}register.php'); // PERHATIKAN: TANPA SLASH
      debugPrint('Data: full_name=$fullName, username=$username, email=$email, password=$password');

      // ✅ PERBAIKAN 1: Gunakan JSON bukan form-urlencoded
      final Map<String, dynamic> requestBody = {
        'full_name': fullName,
        'username': username,
        'email': email,
        'password': password,
      };

      debugPrint('Request Body: $requestBody');

      final response = await http.post(
        // ✅ PERBAIKAN 2: URL yang benar
        Uri.parse('${_baseUrl}register.php'),
        headers: {
          'Content-Type': 'application/json', // ✅ HEADER JSON
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody), // ✅ ENCODE KE JSON
      );

      debugPrint('Response Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final Map<String, dynamic> data = jsonDecode(response.body);
          return data;
        } catch (e) {
          debugPrint('JSON Parse Error: $e');
          return {
            'success': false,
            'message': 'Format respons tidak valid: ${response.body}'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}'
        };
      }
    } catch (e) {
      debugPrint('Register Error: $e');
      return {
        'success': false,
        'message': 'Koneksi gagal: ${e.toString()}',
      };
    }
  }

  // Fungsi untuk mendapatkan header otorisasi
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getToken();
    return {
      'Authorization': 'Bearer $token',
    };
  }

  // Fungsi untuk mendapatkan header JSON
  static Future<Map<String, String>> _getJsonHeaders() async {
    final authHeaders = await _getAuthHeaders();
    return {
      ...authHeaders,
      'Content-Type': 'application/json; charset=UTF-8',
    };
  }

  // ========== AUTH API ==========
  // API untuk login
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login.php'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Gagal terhubung ke server'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }


  // ========== ARTIKEL API ==========
  // API untuk mengambil semua artikel
  static Future<List<dynamic>> getArticles() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/articles/list.php'),
        headers: await _getAuthHeaders(),
      );

      debugPrint('Get Articles Status: ${response.statusCode}');
      debugPrint('Get Articles Response: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          return decoded['data'] ?? [];
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching articles: $e');
      return [];
    }
  }

  // API untuk membuat artikel baru (dengan upload file atau URL)
  static Future<Map<String, dynamic>> createArticle({
    required int userId,
    required String title,
    required String content,
    String? imageUrl,
    File? imageFile, // Tambah parameter untuk file
  }) async {
    try {
      debugPrint('=== CREATE ARTICLE REQUEST ===');
      debugPrint('User ID: $userId, Title: $title');

      // Jika ada file gambar, gunakan multipart/form-data
      if (imageFile != null) {
        debugPrint('Using multipart with image file');

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$_baseUrl/articles/create.php'),
        );

        // Tambahkan fields
        request.fields['user_id'] = userId.toString();
        request.fields['title'] = title;
        request.fields['content'] = content;
        if (imageUrl != null) {
          request.fields['image_url'] = imageUrl;
        }

        // Add file
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          filename: 'article_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ));

        debugPrint('Sending multipart request with file: ${imageFile.path}');

        var response = await request.send();
        var responseData = await response.stream.bytesToString();

        debugPrint('Create Article Response: $responseData');

        try {
          return jsonDecode(responseData);
        } catch (e) {
          return {
            'success': false,
            'message': 'Invalid JSON response: $responseData'
          };
        }
      }
      // Jika tanpa file, gunakan JSON biasa
      else {
        debugPrint('Using JSON without file');

        final Map<String, dynamic> requestBody = {
          'user_id': userId,
          'title': title,
          'content': content,
        };

        if (imageUrl != null && imageUrl.isNotEmpty) {
          requestBody['image_url'] = imageUrl;
        }

        debugPrint('Request Body: $requestBody');

        final response = await http.post(
          Uri.parse('$_baseUrl/articles/create.php'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(requestBody),
        );

        debugPrint('Create Article Status: ${response.statusCode}');
        debugPrint('Create Article Response: ${response.body}');

        try {
          return jsonDecode(response.body);
        } catch (e) {
          debugPrint('JSON Parse Error: $e');
          return {
            'success': false,
            'message': 'Invalid response: ${response.body.substring(0, 100)}...'
          };
        }
      }
    } catch (e) {
      debugPrint('Create Article Error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e'
      };
    }
  }

  // API untuk mengupdate artikel
  // Versi updateArticle tanpa parameter File? yang tidak terpakai:
  static Future<Map<String, dynamic>> updateArticle({
    required int id,
    required String title,
    required String content,
    String? imageUrl,
  }) async {
    try {
      debugPrint('=== UPDATE ARTICLE REQUEST ===');
      debugPrint('Article ID: $id, Title: $title');

      final Map<String, dynamic> requestBody = {
        'id': id,
        'title': title,
        'content': content,
      };

      if (imageUrl != null && imageUrl.isNotEmpty) {
        requestBody['image_url'] = imageUrl;
      }

      debugPrint('Request Body: $requestBody');

      final response = await http.post(
        Uri.parse('$_baseUrl/articles/update.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('Update Article Status: ${response.statusCode}');
      debugPrint('Update Article Response: ${response.body}');

      try {
        return jsonDecode(response.body);
      } catch (e) {
        debugPrint('JSON Parse Error: $e');
        return {
          'success': false,
          'message': 'Invalid response: ${response.body.substring(0, 100)}...'
        };
      }
    } catch (e) {
      debugPrint('Update Article Error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e'
      };
    }
  }

  // API untuk menghapus artikel
  static Future<Map<String, dynamic>> deleteArticle(int id) async {
    try {
      debugPrint('=== DELETE ARTICLE REQUEST ===');
      debugPrint('Deleting article ID: $id');

      final Map<String, dynamic> requestBody = {
        'id': id, // PHP mengharapkan 'id'
      };

      debugPrint('Request Body: $requestBody');

      final response = await http.post(
        Uri.parse('$_baseUrl/articles/delete.php'),
        headers: await _getJsonHeaders(),
        body: jsonEncode(requestBody),
      );

      debugPrint('Delete Article Status: ${response.statusCode}');
      debugPrint('Delete Article Response: ${response.body}');

      try {
        return jsonDecode(response.body);
      } catch (e) {
        debugPrint('JSON Parse Error: $e');
        return {
          'success': false,
          'message': 'Invalid response: ${response.body.substring(0, 100)}...'
        };
      }
    } catch (e) {
      debugPrint('Delete Article Error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e'
      };
    }
  }

  // API untuk mengambil detail artikel
  static Future<Map<String, dynamic>> getArticleDetail(int id) async {
    try {
      debugPrint('=== GET ARTICLE DETAIL ===');
      debugPrint('Article ID: $id');

      final response = await http.get(
        Uri.parse('$_baseUrl/articles/detail.php?id=$id'),
        headers: await _getAuthHeaders(),
      );

      debugPrint('Get Detail Status: ${response.statusCode}');
      debugPrint('Get Detail Response: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch article detail'
        };
      }
    } catch (e) {
      debugPrint('Get Article Detail Error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e'
      };
    }
  }

  // ========== SKILLS API ==========
  // API untuk mengambil data skills
  static Future<List<dynamic>> getSkills() async {
    try {
      // **PERBAIKAN: Gunakan endpoint yang benar**
      final response = await http.get(
        Uri.parse('$_baseUrl/skills/list.php'), // <-- INI YANG BENAR
        headers: await _getAuthHeaders(),
      );

      debugPrint('Get Skills Status: ${response.statusCode}');
      debugPrint('Get Skills Response: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          return decoded['data'] ?? [];
        } else {
          debugPrint('API returned error: ${decoded['message']}');
          return [];
        }
      } else {
        debugPrint('Failed to fetch skills: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching skills: $e');
      return [];
    }
  }

  // ========== SKILLS API (CRUD) ==========

// Create skill
  static Future<Map<String, dynamic>> createSkill({
    required int userId,
    required String skillName,
    required int level,
  }) async {
    try {
      debugPrint('=== CREATE SKILL ===');

      final response = await http.post(
        Uri.parse('$_baseUrl/skills/create.php'),
        headers: await _getJsonHeaders(),
        body: jsonEncode({
          'user_id': userId,
          'skill_name': skillName,
          'level': level,
        }),
      );

      debugPrint('Create Skill Response: ${response.body}');
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('Create Skill Error: $e');
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

// Delete skill
  static Future<Map<String, dynamic>> deleteSkill(int id) async {
    try {
      debugPrint('=== DELETE SKILL ===');

      final response = await http.post(
        Uri.parse('$_baseUrl/skills/delete.php'),
        headers: await _getJsonHeaders(),
        body: jsonEncode({'id': id}),
      );

      debugPrint('Delete Skill Response: ${response.body}');
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('Delete Skill Error: $e');
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

// Update skill
  // Di ApiService, pastikan updateSkill seperti ini:
  // Di file api_service.dart, pastikan updateSkill seperti ini:
  static Future<Map<String, dynamic>> updateSkill({
    required int id,
    required String skillName,
    required int level,
  }) async {
    try {
      debugPrint('=== UPDATE SKILL API CALL ===');
      debugPrint('URL: $_baseUrl/skills/updates.php'); // PASTIKAN INI BENAR

      // Ambil token
      final token = await _getToken();
      debugPrint('Token: ${token != null ? "Available" : "Missing"}');

      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      };

      // Jika token ada, tambahkan Authorization
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      debugPrint('Headers: $headers');

      final body = jsonEncode({
        'id': id,
        'skill_name': skillName,
        'level': level,
      });
      debugPrint('Request Body: $body');

      final response = await http.post(
        Uri.parse('$_baseUrl/skills/updates.php'), // HARUS SAMA DENGAN FILE PHP
        headers: headers,
        body: body,
      );

      debugPrint('Response Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      try {
        final decoded = jsonDecode(response.body);
        return decoded;
      } catch (e) {
        debugPrint('JSON Parse Error: $e');
        return {
          'success': false,
          'message': 'Invalid JSON response: ${response.body}'
        };
      }
    } catch (e) {
      debugPrint('Update Skill API Error: $e');
      return {
        'success': false,
        'message': 'API Error: $e'
      };
    }
  }

  // Tambahkan fungsi ini di ApiService.dart

// API untuk mengambil profile user
  // Tambahkan fungsi ini di ApiService.dart
  // File: lib/services/api_service.dart
// Tambahkan fungsi-fungsi ini di class ApiService

// ========== PROFILE API ==========

// Fungsi untuk mendapatkan profile user (VERSI SIMPLE tanpa auth)
  static Future<Map<String, dynamic>> getProfile({int userId = 1}) async {
    try {
      debugPrint('=== GET PROFILE API CALL ===');
      debugPrint('Base URL: $_baseUrl');
      debugPrint('User ID: $userId');

      // URL endpoint profile.php
      final url = '$_baseUrl/users/profile.php?user_id=$userId';
      debugPrint('Calling URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      debugPrint('Response Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final decoded = jsonDecode(response.body);
          return decoded;
        } catch (e) {
          debugPrint('JSON Parse Error: $e');
          return {
            'success': false,
            'message': 'Invalid JSON response: ${response.body}'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch profile. Status: ${response.statusCode}'
        };
      }
    } catch (e) {
      debugPrint('Get Profile API Error: $e');
      return {
        'success': false,
        'message': 'Network error: $e'
      };
    }
  }

// Fungsi untuk update profile (VERSI SIMPLE tanpa auth)
  static Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required String fullName,
    required String email,
    String? bio,
    String? photoUrl,
  }) async {
    try {
      debugPrint('=== UPDATE PROFILE API CALL ===');

      final Map<String, dynamic> requestBody = {
        'user_id': userId,
        'full_name': fullName,
        'email': email,
      };

      if (bio != null && bio.isNotEmpty) {
        requestBody['bio'] = bio;
      }

      if (photoUrl != null && photoUrl.isNotEmpty) {
        requestBody['photo_url'] = photoUrl;
      }

      debugPrint('Request Body: $requestBody');
      debugPrint('URL: $_baseUrl/users/update.php');

      final response = await http.post(
        Uri.parse('$_baseUrl/users/update.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('Response Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final decoded = jsonDecode(response.body);
          return decoded;
        } catch (e) {
          debugPrint('JSON Parse Error: $e');
          return {
            'success': false,
            'message': 'Invalid JSON response: ${response.body}'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to update profile. Status: ${response.statusCode}'
        };
      }
    } catch (e) {
      debugPrint('Update Profile API Error: $e');
      return {
        'success': false,
        'message': 'Network error: $e'
      };
    }
  }

// Fungsi untuk test koneksi ke API profile
  static Future<Map<String, dynamic>> testProfileConnection({int userId = 1}) async {
    try {
      debugPrint('=== TEST PROFILE CONNECTION ===');

      final url = '$_baseUrl/users/profile.php?user_id=$userId';
      debugPrint('Testing URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        // Timeout 10 detik
      ).timeout(const Duration(seconds: 10));

      debugPrint('Test Response Status: ${response.statusCode}');
      debugPrint('Test Response Body: ${response.body.substring(0, 200)}...');

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'message': response.statusCode == 200 ? 'Connection successful' : 'Connection failed',
        'data': response.body
      };
    } catch (e) {
      debugPrint('Test Connection Error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e'
      };
    }
  }

  // Pastikan fungsi ini sudah ada di ApiService.dart
// Jika belum, tambahkan:

// Fungsi untuk mendapatkan data user dari database
  static Future<Map<String, dynamic>> getUserProfileData({int userId = 1}) async {
    try {
      debugPrint('=== GET USER PROFILE DATA ===');

      final response = await http.get(
        Uri.parse('$_baseUrl/users/profile.php?user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed: ${response.statusCode}'
        };
      }
    } catch (e) {
      debugPrint('Get User Profile Error: $e');
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }
}