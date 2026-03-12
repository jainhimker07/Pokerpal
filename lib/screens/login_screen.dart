import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/services/auth_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Scaffold(
      body: Center(
        child: kIsWeb
            ? buildWebGoogleSignInButton(context)
            : ElevatedButton(
                onPressed: () async {
                  final userCredential = await authService.signInWithGoogle();
                  if (userCredential != null) {
                    Navigator.pushReplacementNamed(context, '/');
                  } else {
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

  Widget buildWebGoogleSignInButton(BuildContext context) {
    // Attempt to use the google_sign_in_web package's renderButton.
    // However, it's easier to use the standard button but we just
    // call signIn explicitly after the user clicks. Wait, the logs say:
    // "Use signInSilently and renderButton..."
    // Let's import 'package:google_sign_in_web/web_only.dart' as web_only;
    // Actually, flutterfire documentation recommends using standard `signIn()`
    // but initializing gapi is necessary if we want to use the old way.
    // A simpler way for Flutter Web Firebase Auth is to use `signInWithPopup`.
    return ElevatedButton(
      onPressed: () async {
        try {
          final auth = FirebaseAuth.instance;
          final provider = GoogleAuthProvider();
          // Add scopes if needed: provider.addScope('email');
          final userCredential = await auth.signInWithPopup(provider);

          if (userCredential.user != null) {
            Navigator.pushReplacementNamed(context, '/');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Google Sign-In Failed (No User)')),
            );
          }
        } catch (e) {
          print('Sign in with Popup error: \$e');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Google Sign-In Failed: \$e')));
        }
      },
      child: const Text('Sign in with Google (Web)'),
    );
  }
}
