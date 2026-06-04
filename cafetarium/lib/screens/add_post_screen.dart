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
  static const Color lightBgColor = Color(0xfff3e8ec);
  static const Color lightBoxColor = Color(0xffeee4e8);

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

      const apiKey = 'API_key';
      const url =
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent';

      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "inlineData": {"mimeType": "image/jpeg", "data": base64Image},
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
        headers: {'x-goog-api-key': apiKey, 'Content-Type': 'application/json'},
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
          'LINK_VERCEL';

      final response = await http.post(
        Uri.parse(vercelUrl),
        headers: {'Content-Type': 'application/json'},
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
        MaterialPageRoute(builder: (_) => const MainScreen(role: 'Owner')),
        (route) => false,
      );
    } catch (e) {
      _showMessage('Gagal membuat postingan: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showImageSourceDialog() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color sheetColor = isDark ? const Color(0xff1E1E1E) : lightBgColor;
    final Color textColor = isDark ? Colors.white : Colors.black87;

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: primaryBrown),
                title: Text(
                  'Ambil dari Kamera',
                  style: TextStyle(color: textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: primaryBrown),
                title: Text(
                  'Pilih dari Galeri',
                  style: TextStyle(color: textColor),
                ),
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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _sectionTitle(
    String title,
    String subtitle, {
    required Color textColor,
    required Color subTextColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 3),
        Text(subtitle, style: TextStyle(fontSize: 12, color: subTextColor)),
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor = isDark ? const Color(0xff121212) : lightBgColor;
    final Color boxColor = isDark ? const Color(0xff1E1E1E) : lightBoxColor;
    final Color fieldColor = isDark ? const Color(0xff242424) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white70 : Colors.grey;
    final Color borderColor = isDark ? Colors.white24 : Colors.grey.shade300;
    final Color uploadBoxColor = isDark ? const Color(0xff2A2A2A) : Colors.grey;
    final Color hintColor = isDark ? Colors.white60 : Colors.grey;

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
                            color: uploadBoxColor,
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
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add, size: 38, color: textColor),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Unggah Foto',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
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
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: fieldColor,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(color: borderColor),
                          ),
                          child: TextField(
                            controller: _cafeNameController,
                            maxLength: 40,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              counterText: '',
                              hintText: 'Contoh: Senja Coffee',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: hintColor,
                              ),
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
                              baseColor: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade300,
                              highlightColor: isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade100,
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
                              style: TextStyle(color: textColor),
                              onChanged: (_) => setState(() {}),
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText:
                                    'Tulis caption menarik tentang cafe kamu',
                                hintStyle: TextStyle(color: hintColor),
                                border: InputBorder.none,
                                counterText: '',
                              ),
                            ),
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$descriptionLength/250',
                        style: TextStyle(color: subTextColor),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(
                          'Lokasi Cafe',
                          'Pilih titik lokasi cafe melalui peta',
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: fieldColor,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(color: borderColor),
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
                                        ? hintColor
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
                          disabledBackgroundColor: primaryBrown.withOpacity(
                            0.5,
                          ),
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
