import 'package:civic_watch/views/admin/admin_dashboard.dart'; // Import this
import 'package:cloud_firestore/cloud_firestore.dart'; // Import this
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:civic_watch/views/authority/city/city_dashboard_screen.dart';
import 'package:civic_watch/views/authority/state/state_dashboard_screen.dart';
import 'package:civic_watch/views/citizen/dashboard_screen.dart';
import 'package:civic_watch/views/authentication/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _firebaseError;
  bool _isLoading = false;

  @override
  void dispose() {
    // ✅ FIX 2 (important)
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _firebaseError = null;
      _isLoading = true;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() => _isLoading = false);
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // ----------------------------------------------------
    // HARDCODED ADMIN BYPASS
    // ----------------------------------------------------
    if (email == 'admin.civicwatch@gmail.com' &&
        password == 'civicwatchAdmin') {
      try {
        // Try to login normally
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (e) {
        // If user not found, create it
        try {
          final cred =
              await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          
          // Try to set Firestore doc (might fail due to permissions but that's ok for local access)
          await FirebaseFirestore.instance
              .collection('users')
              .doc(cred.user!.uid)
              .set({
            'uid': cred.user!.uid,
            'email': email,
            'name': 'System Administrator',
            'role': 'admin',
            'status': 'approved',
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
          }).catchError((e) {
             debugPrint("Admin Firestore setup failed (permissions?): $e");
          });

        } catch (createError) {
           debugPrint("Admin creation failed: $createError");
           // Proceed if user exists but login failed previously for some reason
        }
      }

      // FORCE NAVIGATE TO ADMIN DASHBOARD
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        (_) => false,
      );
      return;
    }
    // ----------------------------------------------------

    try {
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      final uid = userCredential.user!.uid;

      // Fetch user role from Firestore
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        // Handle case where user is authenticated but has no Firestore document
        // Optionally create one or show error. For now, assume citizen.
         if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
            (_) => false,
          );
        }
        return;
      }

      final userData = userDoc.data()!;
      final userRole = userData['role'] ?? 'citizen';
      final userStatus = userData['status'] ?? 'approved';
      final isActive = userData['isActive'] != false;

      if (!mounted) return;

      if (!isActive) {
        setState(() => _firebaseError = 'Account is deactivated. Contact admin.');
        await FirebaseAuth.instance.signOut();
      } else
      if (userRole == 'admin') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          (_) => false,
        );
      } else if (userStatus == 'pending_approval') {
        setState(() => _firebaseError = 'Account is pending approval.');
        await FirebaseAuth.instance.signOut();
      } else if (userStatus == 'rejected') {
        setState(() => _firebaseError = 'Account registration rejected.');
        await FirebaseAuth.instance.signOut();
      } else if (userRole == 'state_authority' && userStatus == 'approved') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const StateDashboardScreen()),
          (_) => false,
        );
      } else if (userRole == 'city_authority' && userStatus == 'approved') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const CityDashboardScreen()),
          (_) => false,
        );
      } else {
        // Default to Citizen Dashboard
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (_) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _firebaseError = e.message);
    } catch (e) {
      if (!mounted) return;
      debugPrint("Login Error: $e");
      setState(() => _firebaseError = 'Login failed: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: GradientBackgroundPainter(),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Card(
                color: const Color(0xFF1e293b),
                elevation: 12,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: const BorderSide(color: Color(0xFF334155)),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.account_circle,
                            size: 80, color: Colors.white),
                        const SizedBox(height: 18),

                        const Text(
                          'Welcome Back!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Login to continue',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF94a3b8)),
                        ),

                        const SizedBox(height: 28),

                        if (_firebaseError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              _firebaseError!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.redAccent,
                              ),
                            ),
                          ),

                        TextFormField(
                          controller: _emailController,
                          style: const TextStyle(color: Color(0xFFf1f5f9)),
                          decoration: _inputDecoration(
                            'Email',
                            Icons.email_outlined,
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty
                                  ? 'Email is required'
                                  : null,
                        ),

                        const SizedBox(height: 18),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          style: const TextStyle(color: Color(0xFFf1f5f9)),
                          decoration: _inputDecoration(
                            'Password',
                            Icons.lock_outline,
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty
                                  ? 'Password is required'
                                  : null,
                        ),

                        const SizedBox(height: 24),

                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF6366f1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account? "),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const RegisterScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Create Account',
                                style: TextStyle(
                                  color: Color(0xFF36D1C4),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFF0f172a),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// ---------------- BACKGROUND ----------------

class GradientBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0f172a), Color(0xFF1e293b)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
