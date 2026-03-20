import 'package:civic_watch/services/city_authority_service.dart';
import 'package:civic_watch/utils/admin_validators.dart';
import 'package:flutter/material.dart';

class CityChangePasswordScreen extends StatefulWidget {
  const CityChangePasswordScreen({super.key});

  @override
  State<CityChangePasswordScreen> createState() => _CityChangePasswordScreenState();
}

class _CityChangePasswordScreenState extends State<CityChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: const Text('Change Password'),
      ),
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
              controller: _new,
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
                if (v != _new.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _saving
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate()) return;
                      setState(() => _saving = true);
                      try {
                        await CityAuthorityService().changePassword(
                          currentPassword: _current.text.trim(),
                          newPassword: _new.text.trim(),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password changed successfully.')),
                        );
                        Navigator.pop(context);
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed: $e')),
                        );
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lock_reset),
              label: Text(_saving ? 'Updating...' : 'Update Password'),
            ),
          ],
        ),
      ),
    );
  }
}
