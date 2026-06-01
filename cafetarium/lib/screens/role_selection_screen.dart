import 'package:cafetarium/screens/sign_up_screen.dart';
import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  static const Color primaryBrown = Color(0xff6f4e37);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7efe8),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              const Icon(Icons.coffee, size: 90, color: primaryBrown),

              const SizedBox(height: 20),

              const Text(
                'Welcome to Cafetarium',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: primaryBrown,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Choose how you want to continue',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),

              const SizedBox(height: 50),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const SignUpScreen(role: 'Customer'),
                    ),
                  );
                },

                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),

                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),

                    gradient: const LinearGradient(
                      colors: [Color(0xff6f4e37), Color(0xffa67b5b)],
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),

                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),

                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),

                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 35,
                        ),
                      ),

                      const SizedBox(width: 20),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text(
                              'Continue as Customer',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),

                            SizedBox(height: 5),

                            Text(
                              'Explore cafes and favorites',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),

                      const Icon(Icons.arrow_forward_ios, color: Colors.white),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignUpScreen(role: 'Owner'),
                    ),
                  );
                },

                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),

                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),

                    color: Colors.white,

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),

                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),

                        decoration: BoxDecoration(
                          color: primaryBrown.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),

                        child: const Icon(
                          Icons.store,
                          color: primaryBrown,
                          size: 35,
                        ),
                      ),

                      const SizedBox(width: 20),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text(
                              'Continue as Owner',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: primaryBrown,
                              ),
                            ),

                            SizedBox(height: 5),

                            Text(
                              'Manage your cafe business',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),

                      const Icon(Icons.arrow_forward_ios, color: primaryBrown),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
