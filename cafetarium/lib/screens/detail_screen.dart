import 'dart:convert';

import 'package:cafetarium/screens/review_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailScreen extends StatelessWidget {
  final String cafeId;

  const DetailScreen({super.key, required this.cafeId});

  static const Color primaryBrown = Color(0xff9b6a43);
  static const Color bgColor = Color(0xfff3e8ec);

  Future<void> _openGoogleMaps(double latitude, double longitude) async {
    final Uri url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Tidak bisa membuka Google Maps');
    }
  }

  Future<void> _toggleFavorite(BuildContext context, String cafeId) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu')),
      );
      return;
    }

    final favoriteRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(cafeId);

    final favoriteDoc = await favoriteRef.get();

    if (favoriteDoc.exists) {
      await favoriteRef.delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cafe dihapus dari favorite')),
        );
      }
    } else {
      await favoriteRef.set({'cafeId': cafeId, 'createdAt': Timestamp.now()});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cafe ditambahkan ke favorite')),
        );
      }
    }
  }

  Widget _buildFavoriteButton(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Silakan login terlebih dahulu')),
          );
        },
        child: const Icon(Icons.favorite_border, color: Colors.red, size: 30),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(cafeId)
          .snapshots(),
      builder: (context, snapshot) {
        final bool isFavorite = snapshot.data?.exists ?? false;

        return GestureDetector(
          onTap: () => _toggleFavorite(context, cafeId),
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.red,
              size: 27,
            ),
          ),
        );
      },
    );
  }

  void _showFullImage(BuildContext context, String imageBase64) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Image.memory(
                    base64Decode(imageBase64),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReplyDialog({
    required BuildContext context,
    required DocumentReference reviewRef,
    String? oldReply,
  }) {
    final TextEditingController replyController = TextEditingController(
      text: oldReply ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Balas Review',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: replyController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Tulis balasan owner...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryBrown),
              onPressed: () async {
                final replyText = replyController.text.trim();

                if (replyText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Balasan tidak boleh kosong')),
                  );
                  return;
                }

                final user = FirebaseAuth.instance.currentUser;

                await reviewRef.update({
                  'ownerReply': replyText,
                  'ownerReplyAt': Timestamp.now(),
                  'ownerReplyBy': user?.uid,
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Balasan berhasil dikirim')),
                  );
                }
              },
              child: const Text('Kirim', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReviewImage(BuildContext context, String imageBase64) {
    return GestureDetector(
      onTap: () {
        _showFullImage(context, imageBase64);
      },
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              base64Decode(imageBase64),
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.zoom_out_map,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerReply(String reply) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xfffff3e8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryBrown.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.store, color: primaryBrown, size: 16),
              SizedBox(width: 6),
              Text(
                'Balasan Owner',
                style: TextStyle(
                  color: primaryBrown,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            reply,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard({
    required BuildContext context,
    required QueryDocumentSnapshot doc,
    required bool isOwner,
  }) {
    final data = doc.data() as Map<String, dynamic>;
    final String? reviewImage = data['image']?.toString();
    final String ownerReply = data['ownerReply']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (reviewImage != null && reviewImage.isNotEmpty)
            _buildReviewImage(context, reviewImage),

          const SizedBox(height: 8),

          Row(
            children: [
              const CircleAvatar(
                radius: 14,
                child: Icon(Icons.person, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data['userName'] ?? 'Guest',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Row(
            children: List.generate(
              (data['rating'] ?? 0).toInt(),
              (index) => const Icon(Icons.star, color: Colors.orange, size: 16),
            ),
          ),

          const SizedBox(height: 6),

          Text(data['comment'] ?? ''),

          if (ownerReply.isNotEmpty) _buildOwnerReply(ownerReply),

          if (isOwner)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  _showReplyDialog(
                    context: context,
                    reviewRef: doc.reference,
                    oldReply: ownerReply.isEmpty ? null : ownerReply,
                  );
                },
                icon: const Icon(Icons.reply, size: 18, color: primaryBrown),
                label: Text(
                  ownerReply.isEmpty ? 'Balas' : 'Edit Balasan',
                  style: const TextStyle(
                    color: primaryBrown,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('cafes')
              .doc(cafeId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text('Cafe tidak ditemukan'));
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;

            final String name = data['name'] ?? 'Nama Cafe';
            final String description = data['description'] ?? '';
            final double rating = (data['rating'] ?? 0).toDouble();
            final double latitude = (data['latitude'] ?? 0).toDouble();
            final double longitude = (data['longitude'] ?? 0).toDouble();
            final String? imageBase64 = data['image'];
            final String ownerId = data['ownerId'] ?? '';

            final bool isOwner =
                currentUser != null && currentUser.uid == ownerId;

            return Column(
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
                          'Cafe Detail',
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
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (imageBase64 != null && imageBase64.isNotEmpty) {
                              _showFullImage(context, imageBase64);
                            }
                          },
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child:
                                    imageBase64 != null &&
                                        imageBase64.isNotEmpty
                                    ? Image.memory(
                                        base64Decode(imageBase64),
                                        width: double.infinity,
                                        height: 150,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: double.infinity,
                                        height: 150,
                                        color: Colors.grey.shade300,
                                        child: const Icon(
                                          Icons.local_cafe,
                                          size: 50,
                                        ),
                                      ),
                              ),
                              if (imageBase64 != null && imageBase64.isNotEmpty)
                                Positioned(
                                  right: 10,
                                  bottom: 10,
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.55),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.zoom_out_map,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _buildFavoriteButton(context),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.star,
                              color: Colors.orange,
                              size: 24,
                            ),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        GestureDetector(
                          onTap: () {
                            _openGoogleMaps(latitude, longitude);
                          },
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, size: 20),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  'Lihat Lokasi Cafe di Google Maps',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue.shade700,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        if (description.isNotEmpty)
                          Text(
                            description,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),

                        const SizedBox(height: 14),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Reviews',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ReviewScreen(cafeId: cafeId),
                                  ),
                                );
                              },
                              child: const Text(
                                'Beri Review',
                                style: TextStyle(
                                  color: primaryBrown,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('cafes')
                              .doc(cafeId)
                              .collection('reviews')
                              .orderBy('createdAt', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final reviews = snapshot.data!.docs;

                            if (reviews.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Belum ada review',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              );
                            }

                            return Column(
                              children: reviews.map((doc) {
                                return _buildReviewCard(
                                  context: context,
                                  doc: doc,
                                  isOwner: isOwner,
                                );
                              }).toList(),
                            );
                          },
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
