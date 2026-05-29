import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

class ReviewScreen extends StatefulWidget {
  final String cafeId;

  const ReviewScreen({super.key, required this.cafeId});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _image;
  String? _base64Image;

  int _selectedRating = 0;
  bool _isSubmitting = false;

  static const Color primaryBrown = Color(0xff9b6a43);
  static const Color bgColor = Color(0xfff3e8ec);
  static const Color boxColor = Color(0xffeee4e8);

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
    });

    await _compressAndEncodeImage();
  }

  Future<void> _compressAndEncodeImage() async {
    if (_image == null) return;

    final compressedImage = await FlutterImageCompress.compressWithFile(
      _image!.path,
      quality: 55,
    );

    if (compressedImage == null) return;

    setState(() {
      _base64Image = base64Encode(compressedImage);
    });
  }

  Future<void> _submitReview() async {
    if (_selectedRating == 0) {
      _showMessage('Silakan pilih rating terlebih dahulu');
      return;
    }

    if (_commentController.text.trim().isEmpty) {
      _showMessage('Komentar tidak boleh kosong');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final cafeRef = FirebaseFirestore.instance
          .collection('cafes')
          .doc(widget.cafeId);

      await cafeRef.collection('reviews').add({
        'userId': 'guest_user',
        'userName': 'Guest',
        'rating': _selectedRating,
        'comment': _commentController.text.trim(),
        'image': _base64Image,
        'createdAt': Timestamp.now(),
      });

      await _updateCafeRating(cafeRef);

      if (!mounted) return;

      _showMessage('Review berhasil dikirim');
      Navigator.pop(context);
    } catch (e) {
      _showMessage('Gagal mengirim review: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _updateCafeRating(DocumentReference cafeRef) async {
    final reviewsSnapshot = await cafeRef.collection('reviews').get();

    if (reviewsSnapshot.docs.isEmpty) {
      await cafeRef.update({'rating': 0.0, 'reviewCount': 0});
      return;
    }

    double totalRating = 0;

    for (final doc in reviewsSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      totalRating += (data['rating'] ?? 0).toDouble();
    }

    final double averageRating = totalRating / reviewsSnapshot.docs.length;

    await cafeRef.update({
      'rating': double.parse(averageRating.toStringAsFixed(1)),
      'reviewCount': reviewsSnapshot.docs.length,
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(5, (index) {
        final starValue = index + 1;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedRating = starValue;
            });
          },
          child: Icon(
            starValue <= _selectedRating ? Icons.star : Icons.star_border,
            color: Colors.orange,
            size: 36,
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      'Beri Review',
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
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: boxColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 82,
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
                                    Icon(
                                      Icons.add,
                                      size: 34,
                                      color: Colors.black,
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Unggah Foto',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    _buildStarRating(),

                    const SizedBox(height: 12),

                    Container(
                      height: 150,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: TextField(
                        controller: _commentController,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Tulis Komentar.....',
                        ),
                      ),
                    ),

                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBrown,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Kirim Review',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
