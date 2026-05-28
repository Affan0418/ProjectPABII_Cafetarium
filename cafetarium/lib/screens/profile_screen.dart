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

//   @override
//   void initState() {
//     super.initState();
//     getUserData();
//   }

@override
void initState() {
  super.initState();

  // DATA DUMMY UNTUK TEST UI
  userData = {
    "name": "Ariq Cafe Owner",
    "email": "ariq@gmail.com",
    "role": "owner",
    "favoriteCount": 12,
    "reviewCount": 8,
    "postCount": 5,
    "profileImage": ""
  };

  isLoading = false;
}

  Future<void> getUserData() async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(user.uid).get();

        if (doc.exists) {
          setState(() {
            userData = doc.data() as Map<String, dynamic>;
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint(e.toString());
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xffF5ECE9),
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
              backgroundColor: const Color(0xff9B6B43),
            ),
            onPressed: () async {
              await _auth.signOut();

              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
              }
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
    const brown = Color(0xff9B6B43);
    const background = Color(0xffF5ECE9);

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    String name = userData?['name'] ?? "User";
    String email = userData?['email'] ?? "-";
    String image = userData?['profileImage'] ?? "";
    String role = userData?['role'] ?? "user";

    int fav = userData?['favoriteCount'] ?? 0;
    int review = userData?['reviewCount'] ?? 0;
    int post = role == "owner" ? (userData?['postCount'] ?? 0) : 0;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: const BoxDecoration(
                color: brown,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        "Profile",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
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
                    const SizedBox(height: 30),

                    // FOTO
                    CircleAvatar(
                      radius: 75,
                      backgroundColor: Colors.white,
                      backgroundImage: image.isNotEmpty
                          ? CachedNetworkImageProvider(image)
                          : null,
                      child: image.isEmpty
                          ? const Icon(Icons.person,
                              size: 70, color: Colors.grey)
                          : null,
                    ),

                    const SizedBox(height: 18),

                    // NAMA
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 30,
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
                        fontSize: 18,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 👇 ROLE BADGE
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
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

                    // STATISTIK
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      child: Row(
                        children: [
                          statItem(Icons.favorite, fav.toString(), "Favorit"),
                          divider(),
                          statItem(Icons.star, review.toString(), "Review"),
                          divider(),
                          statItem(Icons.add_circle, post.toString(),
                              "Postingan"),
                        ],
                      ),
                    ),

                    Divider(color: Colors.brown.shade200),

                    // MENU
                    menuTile(Icons.account_circle, "Akun Saya", () {
                      Navigator.pushNamed(context, '/akun');
                    }),

                    menuTile(Icons.history, "Riwayat Postingan", () {
                      Navigator.pushNamed(context, '/riwayat-postingan');
                    }),

                    menuTile(Icons.info, "Tentang Aplikasi", () {
                      Navigator.pushNamed(context, '/about');
                    }),

                    const SizedBox(height: 70),

                    // LOGOUT
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: SizedBox(
                        width: double.infinity,
                        height: 65,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brown,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          onPressed: logout,
                          child: const Text(
                            "Keluar",
                            style: TextStyle(
                              fontSize: 22,
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
      height: 60,
      width: 1,
      color: Colors.brown.shade200,
    );
  }

  Widget statItem(IconData icon, String value, String title) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 38, color: const Color(0xff9B6B43)),
          const SizedBox(height: 8),
          Text(
            "$value $title",
            style: const TextStyle(
              color: Color(0xff9B6B43),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          )
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
            backgroundColor: const Color(0xff9B6B43),
            child: Icon(icon, color: Colors.white),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Color(0xff9B6B43),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: Color(0xff9B6B43),
          ),
        ),
        Divider(color: Colors.brown.shade200),
      ],
    );
  }
}