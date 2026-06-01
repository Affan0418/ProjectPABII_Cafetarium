import 'package:cached_network_image/cached_network_image.dart';
import 'package:cafetarium/screens/favorite_screen.dart';
import 'package:cafetarium/screens/map_screen.dart';
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

  static const Color brown = Color(0xff9B6B43);
  static const Color background = Color(0xffF5ECE9);

  Map<String, dynamic>? userData;
  bool isLoading = true;

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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: brown,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: brown,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Tutup",
              style: TextStyle(color: brown),
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

    final user = _auth.currentUser;

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

    final String name = userData?['fullName'] ?? 'User';
    final String email = userData?['email'] ?? '-';
    final String image = userData?['profileImage'] ?? '';

    final String roleRaw = (userData?['role'] ?? 'Customer').toString();
    final bool isOwner = roleRaw.toLowerCase() == 'owner';

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
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

              CircleAvatar(
                radius: 68,
                backgroundColor: Colors.white,
                backgroundImage:
                    image.isNotEmpty ? CachedNetworkImageProvider(image) : null,
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

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isOwner ? Colors.amber.shade700 : Colors.green.shade600,
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

              Divider(color: Colors.brown.shade200),

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
                          ),
                          divider(),
                          statItem(
                            Icons.star,
                            reviewCount.toString(),
                            "Review",
                          ),
                          divider(),
                          statItem(
                            Icons.store,
                            postCount.toString(),
                            "Postingan",
                          ),
                        ]
                      : [
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
                        ],
                ),
              ),

              Divider(color: Colors.brown.shade200),

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
                            builder: (_) => const FavoriteScreen(showBackButton: true),
                          ),
                        );
                      },
                    ),
                    menuItem(
                      Icons.rate_review,
                      "Review Saya",
                      "Lihat review terakhir yang pernah kamu tulis",
                      () {
                        showLatestReview();
                      },
                    ),
                    menuItem(
                      Icons.map,
                      "Cari Cafe Terdekat",
                      "Temukan cafe di sekitar lokasimu",
                      () {
                          Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MapScreen(showBackButton: true),
                          ),
                        );
                      },
                    ),
                    if (isOwner)
                      menuItem(
                        Icons.store,
                        "Kelola Cafe Saya",
                        "Lihat cafe yang kamu kelola",
                        () {
                          showMyCafe();
                        },
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
            textAlign: TextAlign.center,
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

  Widget menuItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: brown),
        title: Text(
          title,
          style: const TextStyle(
            color: brown,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.brown.shade400,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: brown,
        ),
        onTap: onTap,
      ),
    );
  }
}