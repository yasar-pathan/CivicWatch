import 'package:civic_watch/services/state_authority_service.dart';
import 'package:civic_watch/utils/admin_validators.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            TextFormField(
              controller: _current,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
              validator: (v) => AdminValidators.requiredField(v, 'Current Password'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _next,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
              validator: AdminValidators.strongPassword,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _confirm,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Confirm password is required';
                if (v != _next.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _saving
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate()) return;
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null || user.email == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Not authenticated.')),
                        );
                        return;
                      }

                      setState(() => _saving = true);
                      try {
                        final cred = EmailAuthProvider.credential(
                          email: user.email!,
                          password: _current.text.trim(),
                        );
                        await user.reauthenticateWithCredential(cred);
                        await user.updatePassword(_next.text.trim());

                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .update({'passwordChangedAt': FieldValue.serverTimestamp()});

                        await StateAuthorityService().logActivity(
                          action: 'changed_own_password',
                          targetUserId: user.uid,
                          targetUserRole: 'state_authority',
                        );

                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password changed successfully.')),
                        );
                        Navigator.pop(context);
                      } on FirebaseAuthException catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Password change failed: ${e.message}')),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Password change failed: $e')),
                        );
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
              child: Text(_saving ? 'Updating...' : 'Update Password'),
            ),
          ],
        ),
      ),
    );
  }
}
