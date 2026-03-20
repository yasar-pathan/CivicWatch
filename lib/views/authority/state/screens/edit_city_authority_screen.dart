import 'package:civic_watch/models/user_model.dart';
import 'package:civic_watch/services/state_authority_service.dart';
import 'package:civic_watch/utils/admin_validators.dart';
import 'package:flutter/material.dart';

class EditCityAuthorityScreen extends StatefulWidget {
  const EditCityAuthorityScreen({super.key, required this.user});

  final UserModel user;

  @override
  State<EditCityAuthorityScreen> createState() => _EditCityAuthorityScreenState();
}

class _EditCityAuthorityScreenState extends State<EditCityAuthorityScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _city;
  late final TextEditingController _ward;
  late final TextEditingController _employeeId;
  late final TextEditingController _department;
  late final TextEditingController _office;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.name ?? '');
    _email = TextEditingController(text: widget.user.email);
    _phone = TextEditingController(text: widget.user.phone ?? '');
    _city = TextEditingController(text: widget.user.city ?? '');
    _ward = TextEditingController(text: '');
    _employeeId = TextEditingController(text: widget.user.governmentId ?? '');
    _department = TextEditingController(text: widget.user.department ?? '');
    _office = TextEditingController(text: widget.user.officeAddress ?? '');
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit City Authority')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _field(_name, 'Full Name', validator: (v) => AdminValidators.requiredField(v, 'Full Name')),
            _field(_email, 'Email', validator: AdminValidators.email),
            _field(_phone, 'Phone', validator: AdminValidators.phone10),
            _field(_city, 'City', validator: (v) => AdminValidators.requiredField(v, 'City')),
            _field(_ward, 'Ward/Zone (optional)', required: false),
            _field(_employeeId, 'Government Employee ID', validator: (v) => AdminValidators.requiredField(v, 'Employee ID')),
            _field(_department, 'Department', validator: (v) => AdminValidators.requiredField(v, 'Department')),
            _field(_office, 'Office Address', validator: (v) => AdminValidators.requiredField(v, 'Office Address'), lines: 2),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _saving
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate()) return;
                      setState(() => _saving = true);
                      try {
                        await StateAuthorityService().updateCityAuthority(
                          widget.user.uid,
                          name: _name.text.trim(),
                          email: _email.text.trim(),
                          phone: _phone.text.trim(),
                          city: _city.text.trim(),
                          wardZone: _ward.text.trim(),
                          governmentId: _employeeId.text.trim(),
                          department: _department.text.trim(),
                          officeAddress: _office.text.trim(),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('City Authority updated successfully')),
                        );
                        Navigator.pop(context);
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Update failed: $e')),
                        );
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
              child: Text(_saving ? 'Saving...' : 'Save Changes'),
            )
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    String? Function(String?)? validator,
    bool required = true,
    int lines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: c,
        maxLines: lines,
        validator: validator ??
            (required ? (v) => AdminValidators.requiredField(v, label) : null),
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }
}
