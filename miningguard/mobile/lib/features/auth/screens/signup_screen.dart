import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miningguard/core/router/app_router.dart';
import 'package:miningguard/features/auth/providers/auth_providers.dart';
import 'package:miningguard/shared/models/user_model.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mineIdController = TextEditingController();

  String? _department;
  String _shift = 'morning';
  UserRole _role = UserRole.worker;
  bool _loading = false;

  static const _departments = [
    'Underground Operations',
    'Surface Operations',
    'Engineering',
    'Safety',
    'Administration',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _mineIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final now = DateTime.now();
      final user = UserModel(
        uid: uid,
        fullName: _nameController.text.trim(),
        mineId: _mineIdController.text.trim().toUpperCase(),
        role: _role,
        department: _department!,
        shift: _shift,
        preferredLanguage: 'en',
        riskScore: 0,
        riskLevel: 'low',
        complianceRate: 1.0,
        consecutiveMissedDays: 0,
        createdAt: now,
        lastActiveAt: now,
      );
      await ref.read(userRepositoryProvider).createUser(user);
      if (mounted) context.go(AppRoutes.languageSelect);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('signup.error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF1A1A2E);
    const amber = Color(0xFFF5A623);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('signup.title'),
        backgroundColor: bg,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Full Name
              _FormField(
                controller: _nameController,
                label: 'signup.fullName',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'signup.fullName.required'
                    : null,
              ),
              const SizedBox(height: 20),

              // Mine ID
              _FormField(
                controller: _mineIdController,
                label: 'signup.mineId',
                hint: 'signup.mineId.hint',
                maxLength: 6,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'signup.mineId.required';
                  }
                  if (!RegExp(r'^[A-Za-z0-9]{6}$').hasMatch(v.trim())) {
                    return 'signup.mineId.invalid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Department
              DropdownButtonFormField<String>(
                value: _department,
                decoration: _inputDecoration('signup.department'),
                dropdownColor: const Color(0xFF252545),
                style: const TextStyle(color: Colors.white, fontSize: 18),
                iconEnabledColor: Colors.white54,
                items: _departments
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setState(() => _department = v),
                validator: (v) =>
                    v == null ? 'signup.department.required' : null,
              ),
              const SizedBox(height: 20),

              // Shift
              Text(
                'signup.shift',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _ShiftChip(
                    label: 'Morning 🌅',
                    value: 'morning',
                    selected: _shift == 'morning',
                    onTap: () => setState(() => _shift = 'morning'),
                  ),
                  const SizedBox(width: 8),
                  _ShiftChip(
                    label: 'Afternoon 🌇',
                    value: 'afternoon',
                    selected: _shift == 'afternoon',
                    onTap: () => setState(() => _shift = 'afternoon'),
                  ),
                  const SizedBox(width: 8),
                  _ShiftChip(
                    label: 'Night 🌙',
                    value: 'night',
                    selected: _shift == 'night',
                    onTap: () => setState(() => _shift = 'night'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Role
              DropdownButtonFormField<UserRole>(
                value: _role,
                decoration: _inputDecoration('signup.role'),
                dropdownColor: const Color(0xFF252545),
                style: const TextStyle(color: Colors.white, fontSize: 18),
                iconEnabledColor: Colors.white54,
                items: [
                  DropdownMenuItem(
                    value: UserRole.worker,
                    child: const Text('Worker'),
                  ),
                  DropdownMenuItem(
                    value: UserRole.supervisor,
                    child: const Text('Supervisor'),
                  ),
                ],
                onChanged: (v) => setState(() => _role = v!),
                validator: (v) => v == null ? 'signup.role.required' : null,
              ),
              const SizedBox(height: 32),

              // Submit
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: amber,
                    foregroundColor: const Color(0xFF1A1A2E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF1A1A2E),
                          ),
                        )
                      : const Text(
                          'signup.submit',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60, fontSize: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white38),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF5A623)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    this.hint,
    this.maxLength,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int? maxLength;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white60, fontSize: 16),
        hintStyle: const TextStyle(color: Colors.white38),
        counterText: '',
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white38),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF5A623)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}

class _ShiftChip extends StatelessWidget {
  const _ShiftChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFF5A623).withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? const Color(0xFFF5A623)
                  : Colors.white38,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? const Color(0xFFF5A623) : Colors.white70,
              fontSize: 14,
              fontWeight:
                  selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
