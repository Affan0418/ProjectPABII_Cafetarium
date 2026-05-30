import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? userData;
  bool isLoading = true;

  int favoriteCount = 0;
  int reviewCount = 0;
  int postCount = 0;

  static const Color brown = Color(0xff9B6B43);
  static const Color background = Color(0xffF5ECE9);

  @override
  void initState() {
    super.initState();
    getProfileData();
  }

  Future<void> getProfileData() async {
    try {
      final User? user = _auth.currentUser;

      if (user == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      final favSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .get();

      final cafeSnapshot = await _firestore
          .collection('cafes')
          .where('ownerId', isEqualTo: user.uid)
          .get();

      final reviewSnapshot = await _firestore
          .collectionGroup('reviews')
          .where('userId', isEqualTo: user.uid)
          .get();

      setState(() {
        userData = userDoc.data() ??
            {
              'fullName': user.displayName ?? 'User',
              'email': user.email ?? '-',
              'role': 'user',
              'profileImage': '',
            };

        favoriteCount = favSnapshot.docs.length;
        postCount = cafeSnapshot.docs.length;
        reviewCount = reviewSnapshot.docs.length;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Profile error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text("Keluar"),
        content: const Text("Apakah kamu yakin ingin logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: brown,
            ),
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: background,
        body: Center(
          child: CircularProgressIndicator(color: brown),
        ),
      );
    }

    final User? user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: background,
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

    final String name =
        userData?['fullName'] ??
        userData?['name'] ??
        user.displayName ??
        'User';

    final String email = userData?['email'] ?? user.email ?? '-';
    final String image = userData?['profileImage'] ?? '';
    final String role = userData?['role'] ?? 'user';

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 78,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: brown,
                borderRadius: BorderRadius.circular(12),
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
                    child: Center(
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
                  const SizedBox(width: 40),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    CircleAvatar(
                      radius: 68,
                      backgroundColor: Colors.white,
                      backgroundImage: image.isNotEmpty
                          ? CachedNetworkImageProvider(image)
                          : null,
                      child: image.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 68,
                              color: Colors.grey,
                            )
                          : null,
                    ),

                    const SizedBox(height: 18),

                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: brown,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      email,
                      style: const TextStyle(
                        color: brown,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: role == "owner"
                            ? Colors.amber.shade700
                            : Colors.green.shade600,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        role == "owner" ? "Pemilik Cafe" : "User",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    Divider(color: Colors.brown.shade200),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          statItem(
                            Icons.favorite,
                            favoriteCount.toString(),
                            "Favorit",
                          ),
                          divider(),
                          statItem(
                            Icons.star,
                            reviewCount.toString(),
                            "Review",
                          ),
                          divider(),
                          statItem(
                            Icons.add_circle,
                            postCount.toString(),
                            "Postingan",
                          ),
                        ],
                      ),
                    ),

                    Divider(color: Colors.brown.shade200),

                    menuTile(Icons.account_circle, "Akun Saya", () {}),
                    menuTile(Icons.history, "Riwayat Postingan", () {}),
                    menuTile(Icons.info, "Tentang Aplikasi", () {}),

                    const SizedBox(height: 50),

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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget divider() {
    return Container(
      height: 58,
      width: 1,
      color: Colors.brown.shade200,
    );
  }

  Widget statItem(IconData icon, String value, String title) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 34, color: brown),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: brown,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: brown,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget menuTile(IconData icon, String title, VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: brown,
            child: Icon(icon, color: Colors.white),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: brown,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: brown,
          ),
        ),
        Divider(color: Colors.brown.shade200),
      ],
    );
  }
}