import 'dart:convert';
import 'dart:io';

import 'package:cafetarium/screens/main_screen.dart';
import 'package:cafetarium/screens/map_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final TextEditingController _cafeNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _image;
  String? _base64Image;

  bool _isUploading = false;
  bool _isGenerating = false;

  double? _latitude;
  double? _longitude;

  static const Color primaryBrown = Color(0xff9b6a43);
  static const Color bgColor = Color(0xfff3e8ec);
  static const Color boxColor = Color(0xffeee4e8);

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);

      if (pickedFile == null) return;

      setState(() {
        _image = File(pickedFile.path);
        _descriptionController.clear();
      });

      await _compressAndEncodeImage();
      await _generateDescriptionWithAI();
    } catch (e) {
      _showMessage('Gagal memilih gambar: $e');
    }
  }

  Future<void> _compressAndEncodeImage() async {
    if (_image == null) return;

    final compressedImage = await FlutterImageCompress.compressWithFile(
      _image!.path,
      quality: 55,
    );

    if (compressedImage == null) {
      _showMessage('Gagal mengompres gambar');
      return;
    }

    if (!mounted) return;

    setState(() {
      _base64Image = base64Encode(compressedImage);
    });
  }

  Future<void> _generateDescriptionWithAI() async {
    if (_image == null) return;

    setState(() => _isGenerating = true);

    try {
      final imageBytes = await _image!.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      const apiKey = 'AQ.Ab8RN6I-5qd_ZuC4of4fyuijppBaE-cpd0XVNK0hwDnZxEYSYQ';
      const url =
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent';

      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "inlineData": {
                  "mimeType": "image/jpeg",
                  "data": base64Image,
                },
              },
              {
                "text":
                    "Berdasarkan foto cafe ini, buat deskripsi singkat dan menarik untuk postingan cafe. "
                    "Gunakan bahasa Indonesia yang santai, natural, dan cocok untuk aplikasi rekomendasi cafe. "
                    "Jelaskan suasana, kenyamanan, dan daya tarik cafe yang terlihat dari foto. "
                    "Jangan terlalu panjang. Maksimal 250 karakter. "
                    "Output hanya deskripsi saja, tanpa judul dan tanpa format tambahan.",
              },
            ],
          },
        ],
      });

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'x-goog-api-key': apiKey,
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final text =
            jsonResponse['candidates']?[0]?['content']?['parts']?[0]?['text'];

        if (text != null && text.toString().trim().isNotEmpty) {
          setState(() {
            _descriptionController.text = text.toString().trim();
          });
        }
      } else {
        debugPrint('AI status code: ${response.statusCode}');
        debugPrint('AI response body: ${response.body}');
        _showMessage('AI gagal: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal generate AI description: $e');
      if (mounted) {
        _showMessage('Gagal generate deskripsi AI');
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _sendNotificationToTopic(String cafeName) async {
    try {
      const String vercelUrl =
          'https://cafetarium-cloud.vercel.app/send-to-topic';

      final response = await http.post(
        Uri.parse(vercelUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'topic': 'cafes',
          'title': '☕ Cafe Baru!',
          'body': '$cafeName baru saja ditambahkan di Cafetarium.',
          'senderName': 'Cafetarium',
        }),
      );

      debugPrint('Notification status: ${response.statusCode}');
      debugPrint('Notification response: ${response.body}');
    } catch (e) {
      debugPrint('Gagal mengirim notifikasi: $e');
    }
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MapScreen(isPickingLocation: true),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _latitude = result['latitude'];
        _longitude = result['longitude'];
      });

      _showMessage('Lokasi cafe berhasil dipilih');
    }
  }

  Future<void> _submitPost() async {
    if (_cafeNameController.text.trim().isEmpty) {
      _showMessage('Nama cafe tidak boleh kosong');
      return;
    }

    if (_image == null || _base64Image == null) {
      _showMessage('Foto cafe wajib diunggah');
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _showMessage('Deskripsi tidak boleh kosong');
      return;
    }

    if (_latitude == null || _longitude == null) {
      _showMessage('Tambahkan lokasi terlebih dahulu');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Silakan login terlebih dahulu');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final cafeName = _cafeNameController.text.trim();

      await FirebaseFirestore.instance.collection('cafes').add({
        'name': cafeName,
        'image': _base64Image,
        'caption': _descriptionController.text.trim(),
        'description': _descriptionController.text.trim(),
        'rating': 0.0,
        'reviewCount': 0,
        'latitude': _latitude,
        'longitude': _longitude,
        'ownerId': user.uid,
        'createdAt': Timestamp.now(),
      });

      await _sendNotificationToTopic(cafeName);

      if (!mounted) return;

      _showMessage('Postingan cafe berhasil dibuat');

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const MainScreen(role: 'Owner'),
        ),
        (route) => false,
      );
    } catch (e) {
      _showMessage('Gagal membuat postingan: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: primaryBrown),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: primaryBrown),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  void dispose() {
    _cafeNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final descriptionLength = _descriptionController.text.length;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: primaryBrown,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Buat Postingan',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: boxColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          height: 95,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: _image != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(9),
                                  child: Image.file(
                                    _image!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add, size: 38),
                                    SizedBox(height: 2),
                                    Text(
                                      'Unggah Foto',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(
                          'Nama Cafe',
                          'Tulis nama cafe tanpa kata "cafe" di depan',
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: TextField(
                            controller: _cafeNameController,
                            maxLength: 40,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              counterText: '',
                              hintText: 'Contoh: Senja Coffee',
                              hintStyle: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Container(
                      height: 135,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: boxColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _isGenerating
                          ? Shimmer.fromColors(
                              baseColor: Colors.grey.shade300,
                              highlightColor: Colors.grey.shade100,
                              child: Container(
                                height: 90,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            )
                          : TextField(
                              controller: _descriptionController,
                              maxLength: 250,
                              maxLines: 5,
                              onChanged: (_) => setState(() {}),
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                hintText:
                                    'Tulis caption menarik tentang cafe kamu',
                                border: InputBorder.none,
                                counterText: '',
                              ),
                            ),
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$descriptionLength/250',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(
                          'Lokasi Cafe',
                          'Pilih titik lokasi cafe melalui peta',
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _latitude == null
                                      ? 'Cari lokasi cafe di map'
                                      : 'Lokasi berhasil dipilih',
                                  style: TextStyle(
                                    color: _latitude == null
                                        ? Colors.grey
                                        : primaryBrown,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _openMapPicker,
                                child: const Text(
                                  'Cari',
                                  style: TextStyle(
                                    color: primaryBrown,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 48),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isUploading ? null : _submitPost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBrown,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        child: _isUploading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Post',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}