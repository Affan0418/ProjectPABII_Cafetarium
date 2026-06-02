import 'dart:convert';

import 'package:cafetarium/screens/detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FavoriteScreen extends StatelessWidget {
  final bool showBackButton;

  const FavoriteScreen({
    super.key,
    this.showBackButton = false,
  });

  static const Color primaryBrown = Color(0xff9b6a43);
  static const Color lightBgColor = Color(0xfff3e8ec);

  Future<DocumentSnapshot> _getCafeData(String cafeId) {
    return FirebaseFirestore.instance.collection('cafes').doc(cafeId).get();
  }

  Widget buildCafeImage(String? imageBase64) {
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      return Image.memory(
        base64Decode(imageBase64),
        width: 78,
        height: 78,
        fit: BoxFit.cover,
      );
    }

    return Container(
      width: 78,
      height: 78,
      color: Colors.grey.shade400,
      child: const Icon(
        Icons.local_cafe,
        size: 34,
        color: Colors.black87,
      ),
    );
  }

  Widget buildHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: primaryBrown,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          if (showBackButton)
            InkWell(
              onTap: () => Navigator.pop(context),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
            )
          else
            const SizedBox(width: 24),
          const Expanded(
            child: Center(
              child: Text(
                'Favorite Cafe',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor = isDark ? const Color(0xff121212) : lightBgColor;
    final Color cardColor =
        isDark ? const Color(0xff1E1E1E) : Colors.grey.shade300;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white70 : Colors.grey.shade700;
    final Color loadingCardColor =
        isDark ? const Color(0xff242424) : Colors.grey.shade300;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBrown,
            ),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/signin',
                (route) => false,
              );
            },
            child: const Text(
              'Login terlebih dahulu',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            buildHeader(context),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('favorites')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: primaryBrown,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: TextStyle(color: textColor),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'Belum ada cafe favorite',
                        style: TextStyle(color: textColor),
                      ),
                    );
                  }

                  final favorites = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: favorites.length,
                    itemBuilder: (context, index) {
                      final favoriteData =
                          favorites[index].data() as Map<String, dynamic>;

                      final String cafeId =
                          favoriteData['cafeId'] ?? favorites[index].id;

                      return FutureBuilder<DocumentSnapshot>(
                        future: _getCafeData(cafeId),
                        builder: (context, cafeSnapshot) {
                          if (cafeSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: loadingCardColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Memuat cafe...',
                                style: TextStyle(color: textColor),
                              ),
                            );
                          }

                          if (cafeSnapshot.hasError) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.red.shade900
                                    : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Gagal memuat cafe: ${cafeSnapshot.error}',
                                style: TextStyle(color: textColor),
                              ),
                            );
                          }

                          if (!cafeSnapshot.hasData ||
                              !cafeSnapshot.data!.exists) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: loadingCardColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Cafe sudah tidak tersedia',
                                style: TextStyle(color: textColor),
                              ),
                            );
                          }

                          final cafeData = cafeSnapshot.data!.data()
                              as Map<String, dynamic>;

                          final String name =
                              cafeData['name'] ?? 'Nama Cafe';
                          final String description =
                              cafeData['description'] ?? '';
                          final double rating =
                              (cafeData['rating'] ?? 0).toDouble();
                          final String? imageBase64 = cafeData['image'];

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailScreen(
                                    cafeId: cafeId,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(9),
                                    child: buildCafeImage(imageBase64),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        if (description.isNotEmpty)
                                          Text(
                                            description,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: subTextColor,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.orange,
                                        size: 22,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        rating.toStringAsFixed(1),
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
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