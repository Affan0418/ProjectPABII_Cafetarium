import 'package:cafetarium/screens/main_screen.dart';
import 'package:cafetarium/screens/sign_in_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  final String role;

  const SignUpScreen({super.key, required this.role});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController usernameController = TextEditingController();

  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  bool isHidden = true;

  static const Color primaryBrown = Color(0xff6f4e37);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7efe8),

      appBar: AppBar(
        backgroundColor: primaryBrown,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Create Account'),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),

        child: Column(
          children: [
            const SizedBox(height: 20),

            const Icon(Icons.coffee, size: 90, color: primaryBrown),

            const SizedBox(height: 20),

            const Text(
              'Join Cafetarium',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: primaryBrown,
              ),
            ),

            const SizedBox(height: 40),

            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                hintText: 'Username',
                prefixIcon: const Icon(Icons.person),

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: emailController,
              decoration: InputDecoration(
                hintText: 'Email',
                prefixIcon: const Icon(Icons.email),

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: passwordController,
              obscureText: isHidden,

              decoration: InputDecoration(
                hintText: 'Password',
                prefixIcon: const Icon(Icons.lock),

                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      isHidden = !isHidden;
                    });
                  },

                  icon: Icon(
                    isHidden ? Icons.visibility_off : Icons.visibility,
                  ),
                ),

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 35),

            SizedBox(
              width: double.infinity,
              height: 58,

              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBrown,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),

                onPressed: () async {
                  try {
                    final credential = await FirebaseAuth.instance
                        .createUserWithEmailAndPassword(
                          email: emailController.text.trim(),
                          password: passwordController.text.trim(),
                        );

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(credential.user!.uid)
                        .set({
                          'fullName': usernameController.text.trim(),
                          'email': emailController.text.trim(),
                          'role': widget.role,
                          'createdAt': Timestamp.now(),
                        });

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account Created Successfully'),
                      ),
                    );

                    Navigator.pushReplacementNamed(context, '/signin');
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sign up gagal: $e')),
                    );
                  }
                },

                child: const Text(
                  'SIGN UP',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
