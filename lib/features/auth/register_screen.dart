import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../common/modern_app_bar.dart';
import 'auth_manager.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _districtController = TextEditingController();
  final _upazilaController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _districtController.dispose();
    _upazilaController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthManager>();
    final ok = await auth.register(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      district: _districtController.text.trim(),
      upazila: _upazilaController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('রেজিস্ট্রেশন সম্পন্ন হয়েছে')));
      Navigator.of(context).pop();
      return;
    }

    if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ModernAppBar(title: 'রেজিস্ট্রেশন', subtitle: 'নতুন একাউন্ট তৈরি করুন'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Consumer<AuthManager>(
            builder: (context, auth, child) => Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'নাম'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'এই ঘরটি পূরণ করুন' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'ফোন নম্বর'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'এই ঘরটি পূরণ করুন' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'ইমেইল (ঐচ্ছিক)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _districtController,
                    decoration: const InputDecoration(labelText: 'জেলা'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _upazilaController,
                    decoration: const InputDecoration(labelText: 'উপজেলা'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'পাসওয়ার্ড'),
                    validator: (v) => (v == null || v.length < 6) ? 'কমপক্ষে ৬ অক্ষর দিন' : null,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: auth.isLoading ? null : _submit,
                    child: auth.isLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('অ্যাকাউন্ট তৈরি'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
