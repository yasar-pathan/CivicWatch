import 'package:civic_watch/models/user_model.dart';
import 'package:civic_watch/services/admin_service.dart';
import 'package:flutter/material.dart';

class EditStateAuthorityScreen extends StatefulWidget {
  const EditStateAuthorityScreen({super.key, required this.user});

  final UserModel user;

  @override
  State<EditStateAuthorityScreen> createState() => _EditStateAuthorityScreenState();
}

class _EditStateAuthorityScreenState extends State<EditStateAuthorityScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _stateController;
  late final TextEditingController _govIdController;
  late final TextEditingController _deptController;
  late final TextEditingController _officeController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name ?? '');
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _stateController = TextEditingController(text: widget.user.state ?? '');
    _govIdController = TextEditingController(text: widget.user.governmentId ?? '');
    _deptController = TextEditingController(text: widget.user.department ?? '');
    _officeController = TextEditingController(text: widget.user.officeAddress ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _stateController.dispose();
    _govIdController.dispose();
    _deptController.dispose();
    _officeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit State Authority')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _field(_nameController, 'Full Name'),
            _field(_emailController, 'Email'),
            _field(_phoneController, 'Phone'),
            _field(_stateController, 'State'),
            _field(_govIdController, 'Government ID'),
            _field(_deptController, 'Department/Designation'),
            _field(_officeController, 'Office Address', maxLines: 3),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _saving
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate()) return;
                      setState(() => _saving = true);
                      try {
                        await AdminService().updateStateAuthority(
                          widget.user.uid,
                          name: _nameController.text.trim(),
                          email: _emailController.text.trim(),
                          phone: _phoneController.text.trim(),
                          state: _stateController.text.trim(),
                          governmentId: _govIdController.text.trim(),
                          department: _deptController.text.trim(),
                          officeAddress: _officeController.text.trim(),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('State Authority updated successfully')),
                        );
                        Navigator.pop(context);
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('Update failed: $e')));
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
              child: Text(_saving ? 'Saving...' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: (value) => value == null || value.trim().isEmpty
            ? '$label is required'
            : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
