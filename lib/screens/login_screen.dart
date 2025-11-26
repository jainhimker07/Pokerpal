import 'package:flutter/material.dart';
import 'package:myapp/services/auth_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final userCredential = await authService.signInWithGoogle();
            if (userCredential != null) {
              // Navigate to home screen on successful login
              Navigator.pushReplacementNamed(context, '/');
            } else {
              // Handle sign-in failure
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Google Sign-In Failed')),
              );
            }
          },
          child: const Text('Sign in with Google'),
        ),
      ),
    );
  }
}
