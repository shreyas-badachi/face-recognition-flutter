import 'package:face_recognition_app/register_screen.dart';
import 'package:face_recognition_app/verify_screen.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Recognition'),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.black,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.white,
              AppTheme.lightGray,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.face_retouching_natural,
                  size: 120,
                  color: AppTheme.primaryBlue.withOpacity(0.8),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Welcome to Face Recognition',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Register or verify faces securely',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.darkGray,
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('Register New Face'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: AppTheme.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VerifyScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.verified_user),
                    label: const Text('Verify Face'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      side: BorderSide(color: AppTheme.primaryBlue),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}