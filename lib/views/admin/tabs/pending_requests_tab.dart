import 'package:civic_watch/models/user_model.dart';
import 'package:civic_watch/services/admin_service.dart';
import 'package:civic_watch/utils/admin_validators.dart';
import 'package:civic_watch/utils/password_generator.dart';
import 'package:flutter/material.dart';

class PendingRequestsTab extends StatefulWidget {
  const PendingRequestsTab({super.key});

  @override
  State<PendingRequestsTab> createState() => _PendingRequestsTabState();
}

class _PendingRequestsTabState extends State<PendingRequestsTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _stateController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _departmentController = TextEditingController();
  final _officeAddressController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _autoGeneratePassword = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _passwordController.text = PasswordGenerator.generate(length: 12);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _stateController.dispose();
    _employeeIdController.dispose();
    _departmentController.dispose();
    _officeAddressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminService = AdminService();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create State Authority',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'State authorities are now created only by Admin.',
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Colors.white10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _field(_nameController, 'Full Name', Icons.person),
                    const SizedBox(height: 10),
                    _field(_emailController, 'Official Email', Icons.email,
                        keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 10),
                    _field(_phoneController, 'Phone', Icons.phone,
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 10),
                    _field(_stateController, 'State', Icons.map),
                    const SizedBox(height: 10),
                    _field(_employeeIdController, 'Employee/Government ID',
                        Icons.badge),
                    const SizedBox(height: 10),
                    _field(_departmentController, 'Department/Designation',
                        Icons.apartment),
                    const SizedBox(height: 10),
                    _field(_officeAddressController, 'Office Address',
                        Icons.location_on,
                        maxLines: 2),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      value: _autoGeneratePassword,
                      onChanged: (value) {
                        setState(() {
                          _autoGeneratePassword = value;
                          if (_autoGeneratePassword) {
                            _passwordController.text =
                                PasswordGenerator.generate(length: 12);
                          }
                        });
                      },
                      title: const Text('Auto-generate secure password'),
                    ),
                    const SizedBox(height: 6),
                    _field(_passwordController, 'Temporary Password', Icons.lock,
                        obscureText: true,
                        validatorOverride: AdminValidators.strongPassword),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isCreating
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;
                                setState(() => _isCreating = true);
                                try {
                                  await adminService.createStateAuthorityAccount(
                                    name: _nameController.text.trim(),
                                    email: _emailController.text.trim(),
                                    password: _passwordController.text.trim(),
                                    phone: _phoneController.text.trim(),
                                    state: _stateController.text.trim(),
                                    governmentId: _employeeIdController.text.trim(),
                                    department: _departmentController.text.trim(),
                                    officeAddress:
                                        _officeAddressController.text.trim(),
                                    emailSent: true,
                                  );

                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'State Authority account created successfully.',
                                      ),
                                    ),
                                  );

                                  _nameController.clear();
                                  _emailController.clear();
                                  _phoneController.clear();
                                  _stateController.clear();
                                  _employeeIdController.clear();
                                  _departmentController.clear();
                                  _officeAddressController.clear();
                                  _passwordController.clear();
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Create failed: $e')),
                                  );
                                } finally {
                                  if (mounted) setState(() => _isCreating = false);
                                }
                              },
                        icon: _isCreating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.person_add),
                        label: Text(_isCreating ? 'Creating...' : 'Create Account'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Recently Created State Authorities',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<UserModel>>(
            stream: adminService.getAllStateAuthorities(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Could not load state authorities: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                );
              }
              final users = snapshot.data ?? [];
              if (users.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('No state authority accounts created yet.',
                      style: TextStyle(color: Colors.white70)),
                );
              }

              return ListView.builder(
                itemCount: users.length > 5 ? 5 : users.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Card(
                    color: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.white10),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF334155),
                        child: Text(
                          (user.name?.isNotEmpty ?? false)
                              ? user.name![0].toUpperCase()
                              : 'S',
                        ),
                      ),
                      title: Text(
                        user.name ?? 'Unknown',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        '${user.state ?? 'N/A'} • ${user.email}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    int maxLines = 1,
    String? Function(String?)? validatorOverride,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blueAccent),
        ),
      ),
      validator: validatorOverride ??
          (value) {
            if (label.contains('Email')) return AdminValidators.email(value);
            if (label == 'Phone') return AdminValidators.phone10(value);
            if (label.contains('Password')) {
              return AdminValidators.strongPassword(value);
            }
            return AdminValidators.requiredField(value, label);
          },
    );
  }
}