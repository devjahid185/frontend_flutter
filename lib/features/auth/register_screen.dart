import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_manager.dart';
import 'auth_form_shell.dart';
import 'otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  String _gender = 'male';
  bool _acceptedTerms = true;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('শর্তাবলী ও নীতিমালা মেনে নিন')),
      );
      return;
    }
    final auth = context.read<AuthManager>();
    final ok = await auth.requestOtp(
      phone: _phone.text.trim(),
      purpose: 'register',
    );
    if (!ok || !mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OtpScreen(
          phone: _phone.text.trim(),
          purpose: 'register',
          registerPayload: {
            'name': _name.text.trim(),
            'phone': _phone.text.trim(),
            'email': _email.text.trim(),
            'password': _password.text.trim(),
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AuthFormShell(
      title: 'নতুন অ্যাকাউন্ট তৈরি করুন',
      subtitle: 'সুপার অ্যাপের সব সুবিধা পেতে সঠিক তথ্য দিন',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'আপনার নাম'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'নাম দিন' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'মোবাইল নম্বর'),
              validator: (v) =>
                  (v == null || v.trim().length < 10) ? 'সঠিক নম্বর দিন' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'ইমেইল (ঐচ্ছিক)'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'পাসওয়ার্ড',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) => (v == null || v.trim().length < 6)
                  ? 'কমপক্ষে ৬ অক্ষর দিন'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirm,
              obscureText: _obscure,
              decoration: const InputDecoration(
                labelText: 'পাসওয়ার্ড নিশ্চিত করুন',
              ),
              validator: (v) => (v != _password.text) ? 'ম্যাচ করছে না' : null,
            ),
            const SizedBox(height: 16),
            _GenderSelector(
              value: _gender,
              onChanged: (value) => setState(() => _gender = value),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 20,
                    width: 20,
                    decoration: BoxDecoration(
                      color: _acceptedTerms
                          ? const Color(0xff006a4e)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _acceptedTerms
                            ? const Color(0xff006a4e)
                            : const Color(0xffd1d5db),
                      ),
                    ),
                    child: _acceptedTerms
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 15,
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'আমি অ্যাপের শর্তাবলী এবং নীতিমালা মেনে নিচ্ছি',
                      style: TextStyle(
                        color: Color(0xff6b7280),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Consumer<AuthManager>(
              builder: (context, auth, child) => SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: auth.isLoading ? null : _submit,
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: LogoLoader(size: 20),
                        )
                      : const Text('রেজিস্ট্রেশন সম্পূর্ণ করুন'),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Consumer<AuthManager>(
              builder: (context, auth, child) => auth.errorMessage == null
                  ? const SizedBox.shrink()
                  : Text(
                      auth.errorMessage!,
                      style: TextStyle(color: scheme.error),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenderSelector extends StatelessWidget {
  const _GenderSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = [
      ('male', 'পুরুষ'),
      ('female', 'মহিলা'),
      ('other', 'অন্যান্য'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'লিঙ্গ নির্বাচন করুন',
          style: TextStyle(
            color: Color(0xff1f2937),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final option in options) ...[
              Expanded(
                child: InkWell(
                  onTap: () => onChanged(option.$1),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: value == option.$1
                          ? const Color(0xffe6f1ee)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: value == option.$1
                            ? const Color(0xff006a4e)
                            : const Color(0xffe5e7eb),
                      ),
                    ),
                    child: Text(
                      option.$2,
                      style: TextStyle(
                        color: value == option.$1
                            ? const Color(0xff006a4e)
                            : const Color(0xff1f2937),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              if (option != options.last) const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }
}
