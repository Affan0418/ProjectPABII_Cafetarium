import 'dart:convert';
import 'dart:io';

import 'package:cafetarium/screens/favorite_screen.dart';
import 'package:cafetarium/screens/map_screen.dart';
import 'package:cafetarium/theme_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  static const Color brown = Color(0xff9B6B43);
  static const Color lightBackground = Color(0xffF5ECE9);

  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool isUploadingImage = false;

  int favoriteCount = 0;
  int reviewCount = 0;
  int postCount = 0;

  @override
  void initState() {
    super.initState();
    getProfileData();
  }

  Future<void> getProfileData() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final data = userDoc.data() ?? {};

      final favSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .get();

      final postSnapshot = await _firestore
          .collection('cafes')
          .where('ownerId', isEqualTo: user.uid)
          .get();

      int totalReviews = 0;
      final cafesSnapshot = await _firestore.collection('cafes').get();

      for (final cafeDoc in cafesSnapshot.docs) {
        final reviewsSnapshot = await cafeDoc.reference
            .collection('reviews')
            .where('userId', isEqualTo: user.uid)
            .get();

        totalReviews += reviewsSnapshot.docs.length;
      }

      if (!mounted) return;

      setState(() {
        userData = {
          'fullName': data['fullName'] ??
              data['username'] ??
              data['name'] ??
              user.displayName ??
              user.email?.split('@').first ??
              'User',
          'email': data['email'] ?? user.email ?? '-',
          'role': data['role'] ?? 'Customer',
          'profileImage': data['profileImage'] ?? '',
        };

        favoriteCount = favSnapshot.docs.length;
        reviewCount = totalReviews;
        postCount = postSnapshot.docs.length;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Profile error: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> pickProfileImage(ImageSource source) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final XFile? pickedImage = await _picker.pickImage(
        source: source,
        imageQuality: 45,
      );

      if (pickedImage == null) return;

      setState(() => isUploadingImage = true);

      final bytes = await File(pickedImage.path).readAsBytes();
      final base64Image = base64Encode(bytes);

      await _firestore.collection('users').doc(user.uid).set(
        {'profileImage': base64Image},
        SetOptions(merge: true),
      );

      if (!mounted) return;

      setState(() {
        userData?['profileImage'] = base64Image;
        isUploadingImage = false;
      });
    } catch (e) {
      debugPrint('Upload profile image error: $e');

      if (!mounted) return;

      setState(() => isUploadingImage = false);

      showInfoDialog(
        "Error",
        "Gagal mengganti foto profil.",
      );
    }
  }

  void showImagePickerOption() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xff121212) : lightBackground;
    final Color textColor = isDark ? Colors.white : brown;

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            children: [
              Center(
                child: Text(
                  "Pilih Foto Profil",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Icon(Icons.camera_alt, color: textColor),
                title: Text(
                  "Ambil dari Kamera",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  pickProfileImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: textColor),
                title: Text(
                  "Ambil dari Galeri",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  pickProfileImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> logout() async {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color dialogBg = isDark ? const Color(0xff1E1E1E) : lightBackground;
    final Color textColor = isDark ? Colors.white : brown;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          "Keluar",
          style: TextStyle(color: textColor),
        ),
        content: Text(
          "Apakah kamu yakin ingin logout?",
          style: TextStyle(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal", style: TextStyle(color: textColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: brown),
            onPressed: () async {
              await _auth.signOut();

              if (!context.mounted) return;

              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/signin',
                (route) => false,
              );
            },
            child: const Text(
              "Logout",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> showLatestReview() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final cafesSnapshot = await _firestore.collection('cafes').get();

      Map<String, dynamic>? latestReview;
      String cafeName = "-";
      Timestamp? latestTime;

      for (final cafeDoc in cafesSnapshot.docs) {
        final reviewSnapshot = await cafeDoc.reference
            .collection('reviews')
            .where('userId', isEqualTo: user.uid)
            .get();

        for (final reviewDoc in reviewSnapshot.docs) {
          final data = reviewDoc.data();
          final Timestamp? createdAt = data['createdAt'];

          if (createdAt != null) {
            if (latestTime == null ||
                createdAt.toDate().isAfter(latestTime.toDate())) {
              latestTime = createdAt;
              latestReview = data;
              cafeName = cafeDoc.data()['name'] ?? 'Cafe';
            }
          }
        }
      }

      if (!mounted) return;

      if (latestReview == null) {
        showInfoDialog(
          "Review Saya",
          "Kamu belum pernah memberikan review cafe.",
        );
        return;
      }

      showInfoDialog(
        "Review Terakhir",
        "Cafe: $cafeName\n\n"
        "Rating: ${latestReview['rating'] ?? '-'}\n\n"
        "Review: ${latestReview['comment'] ?? latestReview['review'] ?? latestReview['text'] ?? '-'}",
      );
    } catch (e) {
      debugPrint("Review error: $e");
      showInfoDialog("Error", "Gagal mengambil data review.");
    }
  }

  Future<void> showMyCafe() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final cafeSnapshot = await _firestore
          .collection('cafes')
          .where('ownerId', isEqualTo: user.uid)
          .get();

      if (!mounted) return;

      if (cafeSnapshot.docs.isEmpty) {
        showInfoDialog(
          "Kelola Cafe Saya",
          "Kamu belum memiliki cafe yang terdaftar.",
        );
        return;
      }

      final cafes = cafeSnapshot.docs.map((doc) {
        final data = doc.data();
        return "• ${data['name'] ?? 'Nama cafe tidak tersedia'}";
      }).join('\n');

      showInfoDialog("Cafe Saya", cafes);
    } catch (e) {
      debugPrint("Cafe owner error: $e");
      showInfoDialog("Error", "Gagal mengambil data cafe milikmu.");
    }
  }

  void showInfoDialog(String title, String message) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color dialogBg = isDark ? const Color(0xff1E1E1E) : lightBackground;
    final Color textColor = isDark ? Colors.white : brown;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Tutup",
              style: TextStyle(color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProfileImage(String image) {
    if (image.isNotEmpty) {
      try {
        return ClipOval(
          child: Image.memory(
            base64Decode(image),
            width: 136,
            height: 136,
            fit: BoxFit.cover,
          ),
        );
      } catch (e) {
        return const Icon(
          Icons.person,
          size: 68,
          color: Colors.grey,
        );
      }
    }

    return const Icon(
      Icons.person,
      size: 68,
      color: Colors.grey,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor = isDark ? const Color(0xff121212) : lightBackground;
    final Color cardColor = isDark ? const Color(0xff1E1E1E) : Colors.white;
    final Color softCardColor =
        isDark ? const Color(0xff242424) : Colors.white;
    final Color textColor = isDark ? Colors.white : brown;
    final Color subTextColor = isDark ? Colors.white70 : Colors.brown.shade400;
    final Color dividerColor = isDark ? Colors.white24 : Colors.brown.shade200;
    final Color avatarBg = isDark ? const Color(0xff2A2A2A) : Colors.white;

    if (isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(
          child: CircularProgressIndicator(color: brown),
        ),
      );
    }

    final user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: brown),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/signin',
                (route) => false,
              );
            },
            child: const Text(
              'Login kembali',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }

    final String name = userData?['fullName'] ?? 'User';
    final String email = userData?['email'] ?? '-';
    final String image = userData?['profileImage'] ?? '';

    final String roleRaw = (userData?['role'] ?? 'Customer').toString();
    final bool isOwner = roleRaw.toLowerCase() == 'owner';

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: themeController,
          builder: (context, _) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    height: 78,
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: brown,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        "Profile",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: showImagePickerOption,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 68,
                          backgroundColor: avatarBg,
                          child: isUploadingImage
                              ? const CircularProgressIndicator(color: brown)
                              : buildProfileImage(image),
                        ),
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: brown,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: avatarBg,
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Ketuk foto untuk mengganti",
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    email,
                    style: TextStyle(
                      color: subTextColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isOwner ? Colors.amber.shade700 : Colors.green.shade600,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isOwner ? "Pemilik Cafe" : "Customer",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: brown,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_cafe,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isOwner
                                ? "Kelola dan promosikan cafe milikmu."
                                : "Temukan dan simpan cafe favoritmu.",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Divider(color: dividerColor),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 14,
                    ),
                    child: Row(
                      children: isOwner
                          ? [
                              statItem(
                                Icons.favorite,
                                favoriteCount.toString(),
                                "Favorit",
                                textColor: textColor,
                              ),
                              divider(dividerColor),
                              statItem(
                                Icons.star,
                                reviewCount.toString(),
                                "Review",
                                textColor: textColor,
                              ),
                              divider(dividerColor),
                              statItem(
                                Icons.store,
                                postCount.toString(),
                                "Postingan",
                                textColor: textColor,
                              ),
                            ]
                          : [
                              statItem(
                                Icons.favorite,
                                favoriteCount.toString(),
                                "Favorit",
                                textColor: textColor,
                              ),
                              divider(dividerColor),
                              statItem(
                                Icons.star,
                                reviewCount.toString(),
                                "Review",
                                textColor: textColor,
                              ),
                            ],
                    ),
                  ),

                  Divider(color: dividerColor),

                  const SizedBox(height: 18),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        menuItem(
                          Icons.favorite,
                          "Cafe Favorit",
                          "Lihat cafe yang sudah kamu simpan",
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const FavoriteScreen(showBackButton: true),
                              ),
                            );
                          },
                          cardColor: cardColor,
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),
                        menuItem(
                          Icons.rate_review,
                          "Review Saya",
                          "Lihat review terakhir yang pernah kamu tulis",
                          () {
                            showLatestReview();
                          },
                          cardColor: cardColor,
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),
                        menuItem(
                          Icons.map,
                          "Cari Cafe Terdekat",
                          "Temukan cafe di sekitar lokasimu",
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const MapScreen(showBackButton: true),
                              ),
                            );
                          },
                          cardColor: cardColor,
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),

                        darkModeTile(
                          cardColor: softCardColor,
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),

                        if (isOwner)
                          menuItem(
                            Icons.store,
                            "Kelola Cafe Saya",
                            "Lihat cafe yang kamu kelola",
                            () {
                              showMyCafe();
                            },
                            cardColor: cardColor,
                            textColor: textColor,
                            subTextColor: subTextColor,
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brown,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: logout,
                        child: const Text(
                          "Keluar",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget divider(Color color) {
    return Container(
      height: 58,
      width: 1,
      color: color,
    );
  }

  Widget statItem(
    IconData icon,
    String value,
    String title, {
    required Color textColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 34, color: textColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget darkModeTile({
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        activeColor: brown,
        secondary: Icon(
          themeController.isDarkMode ? Icons.dark_mode : Icons.light_mode,
          color: textColor,
        ),
        title: Text(
          "Dark Mode",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          themeController.isDarkMode
              ? "Mode gelap sedang aktif"
              : "Mode terang sedang aktif",
          style: TextStyle(
            color: subTextColor,
            fontSize: 12,
          ),
        ),
        value: themeController.isDarkMode,
        onChanged: (value) {
          themeController.toggleTheme(value);
        },
      ),
    );
  }

  Widget menuItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: textColor),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: subTextColor,
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: textColor,
        ),
        onTap: onTap,
      ),
    );
  }
}