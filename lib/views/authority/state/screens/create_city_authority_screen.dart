import 'package:civic_watch/services/state_authority_service.dart';
import 'package:civic_watch/utils/admin_validators.dart';
import 'package:civic_watch/utils/password_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CreateCityAuthorityScreen extends StatefulWidget {
  const CreateCityAuthorityScreen({super.key});

  @override
  State<CreateCityAuthorityScreen> createState() => _CreateCityAuthorityScreenState();
}

class _CreateCityAuthorityScreenState extends State<CreateCityAuthorityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = StateAuthorityService();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _ward = TextEditingController();
  final _employeeId = TextEditingController();
  final _department = TextEditingController();
  final _office = TextEditingController();
  final _password = TextEditingController();
  bool _autoPassword = true;
  bool _sendEmail = true;
  bool _sendSms = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _password.text = PasswordGenerator.generate(length: 12);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _city.dispose();
    _ward.dispose();
    _employeeId.dispose();
    _department.dispose();
    _office.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create City Authority')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _field(_name, 'Full Name', validator: (v) => AdminValidators.requiredField(v, 'Full Name')),
            _field(_email, 'Email', keyboard: TextInputType.emailAddress, validator: AdminValidators.email),
            _field(_phone, 'Phone (+91)', keyboard: TextInputType.phone, validator: AdminValidators.phone10),
            _field(_city, 'City', validator: (v) => AdminValidators.requiredField(v, 'City')),
            _field(_ward, 'Ward/Zone (optional)', required: false),
            _field(_employeeId, 'Government Employee ID', validator: (v) => AdminValidators.requiredField(v, 'Government Employee ID')),
            _field(_department, 'Department/Designation', validator: (v) => AdminValidators.requiredField(v, 'Department')),
            _field(_office, 'Office Address', validator: (v) => AdminValidators.requiredField(v, 'Office Address'), lines: 2),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _autoPassword,
              onChanged: (v) {
                setState(() {
                  _autoPassword = v;
                  if (v) {
                    _password.text = PasswordGenerator.generate(length: 12);
                  } else {
                    _password.clear();
                  }
                });
              },
              title: const Text('Auto-generate password'),
            ),
            _field(_password, 'Password', validator: AdminValidators.strongPassword, obscure: true),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _password.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password copied')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Password'),
                ),
              ],
            ),
            CheckboxListTile(
              value: _sendEmail,
              onChanged: (v) => setState(() => _sendEmail = v ?? false),
              title: const Text('Send credentials via Email'),
            ),
            CheckboxListTile(
              value: _sendSms,
              onChanged: (v) => setState(() => _sendSms = v ?? false),
              title: const Text('Send credentials via SMS'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _saving
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate()) return;
                      setState(() => _saving = true);
                      try {
                        await _service.createCityAuthorityAccount(
                          name: _name.text.trim(),
                          email: _email.text.trim(),
                          password: _password.text.trim(),
                          phone: _phone.text.trim(),
                          city: _city.text.trim(),
                          wardZone: _ward.text.trim(),
                          governmentId: _employeeId.text.trim(),
                          department: _department.text.trim(),
                          officeAddress: _office.text.trim(),
                          emailSent: _sendEmail,
                          smsSent: _sendSms,
                        );

                        if (!context.mounted) return;
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: const Color(0xFF1E293B),
                            title: const Text('City Authority Created'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Name: ${_name.text.trim()}'),
                                Text('Email: ${_email.text.trim()}'),
                                Text('Password: ${_password.text.trim()}'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                },
                                child: const Text('View City Authorities'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _formKey.currentState?.reset();
                                  _name.clear();
                                  _email.clear();
                                  _phone.clear();
                                  _city.clear();
                                  _ward.clear();
                                  _employeeId.clear();
                                  _department.clear();
                                  _office.clear();
                                  _password.text = PasswordGenerator.generate(length: 12);
                                },
                                child: const Text('Create Another'),
                              ),
                            ],
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Create failed: $e')),
                        );
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
              icon: _saving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_add_alt_1),
              label: Text(_saving ? 'Creating...' : 'Create City Authority'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
    bool obscure = false,
    bool required = true,
    int lines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        obscureText: obscure,
        maxLines: lines,
        validator: validator ??
            (required ? (v) => AdminValidators.requiredField(v, label) : null),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
