import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:civic_watch/views/citizen/dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _firebaseError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() {
      _firebaseError = null;
    });
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      } on FirebaseAuthException catch (e) {
        setState(() {
          _firebaseError = e.message;
        });
      } catch (e) {
        debugPrint("Registration Error: $e"); // Log the actual error
        setState(() {
          _firebaseError = 'Registration failed: $e';
        });
      }
    }
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
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.person_add,
                            size: 80, color: Colors.white),
                        const SizedBox(height: 20),

                        _title("Create Account"),
                        _subtitle("Sign up to get started"),
                        const SizedBox(height: 32),

                        _field(
                          controller: _nameController,
                          label: "Full Name",
                          icon: Icons.person,
                        ),

                        const SizedBox(height: 18),

                        _field(
                          controller: _emailController,
                          label: "Email Address",
                          icon: Icons.email_outlined,
                          keyboard: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 18),

                        _field(
                          controller: _phoneController,
                          label: "Phone Number",
                          icon: Icons.phone,
                          keyboard: TextInputType.phone,
                        ),

                        const SizedBox(height: 18),

                        _field(
                          controller: _cityController,
                          label: "City",
                          icon: Icons.location_city,
                        ),

                        const SizedBox(height: 18),

                        _passwordField(
                          controller: _passwordController,
                          label: "Password",
                          obscure: _obscurePassword,
                          toggle: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),

                        const SizedBox(height: 18),

                        _passwordField(
                          controller: _confirmPasswordController,
                          label: "Confirm Password",
                          obscure: _obscureConfirmPassword,
                          toggle: () => setState(() =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword),
                          confirm: true,
                        ),

                        const SizedBox(height: 28),

                        if (_firebaseError != null) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              _firebaseError!,
                              style: const TextStyle(color: Colors.redAccent),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366f1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              "Register",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Already have an account? "),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Text(
                                "Login",
                                style: TextStyle(
                                    color: Color(0xFF36D1C4),
                                    fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  // ---------- UI HELPERS ----------

  Widget _title(String text) => Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );

  Widget _subtitle(String text) => Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFF94a3b8)),
      );

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: _decoration(label, icon),
      validator: (v) =>
          v == null || v.isEmpty ? "$label is required" : null,
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback toggle,
    bool confirm = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: _decoration(
        label,
        Icons.lock_outline,
        suffix: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: toggle,
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return "$label is required";
        if (confirm && v != _passwordController.text) {
          return "Passwords do not match";
        }
        if (!confirm && v.length < 6) {
          return "Password must be at least 6 characters";
        }
        return null;
      },
    );
  }

  InputDecoration _decoration(String label, IconData icon,
      {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFF0f172a),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// ---------- BACKGROUND ----------

class GradientBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0f172a), Color(0xFF1e293b)],
      ).createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
