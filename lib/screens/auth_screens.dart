import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/shop_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'app_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.store, super.key});

  final ShopStore store;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isSigningIn = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_isSigningIn || !_formKey.currentState!.validate()) return;

    setState(() => _isSigningIn = true);

    try {
      final email = _email.text.trim();
      final password = _password.text;

      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (response.user == null) {
        _message('Login failed. Please check your account.');
        return;
      }

      final user = response.user!;
      final userMetadata = user.userMetadata ?? {};

      widget.store.updateProfile(
        name: userMetadata['full_name']?.toString() ??
            userMetadata['name']?.toString() ??
            email,
        emailAddress: user.email ?? email,
        phoneNumber: userMetadata['phone']?.toString() ?? '',
      );

      final navigator = Navigator.of(context);

      navigator.pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => AppShell(
            store: widget.store,
            onLogout: () => returnToLogin(navigator, widget.store),
          ),
        ),
        (_) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      _message(e.message);
    } catch (e) {
      if (!mounted) return;
      _message('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(25, 14, 25, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _BrandMark(),
              const SizedBox(height: 34),
              Text('Welcome Back', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 7),
              const Text('Sign in to continue your beauty journey'),
              const SizedBox(height: 30),
              AppTextField(
                label: 'Email or Phone Number',
                controller: _email,
                icon: Icons.person_outline,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter your email or phone number'
                    : null,
              ),
              const SizedBox(height: 15),
              AppTextField(
                label: 'Password',
                controller: _password,
                icon: Icons.lock_outline,
                obscureText: true,
                validator: (value) => value == null || value.length < 6
                    ? 'Password must be at least 6 characters'
                    : null,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _message('Password reset is coming soon.'),
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 4),
              PrimaryButton(
                label: _isSigningIn ? 'Signing in...' : 'Log In',
                isLoading: _isSigningIn,
                onPressed: _isSigningIn ? null : _continue,
              ),
              const SizedBox(height: 19),
              const _DividerLabel(),
              const SizedBox(height: 17),
              PrimaryButton(
                label: 'Continue with Google',
                icon: Icons.g_mobiledata,
                outlined: true,
                onPressed: () => _message('Google sign-in will be available soon.'),
              ),
              const SizedBox(height: 11),
              PrimaryButton(
                label: 'Continue with Apple',
                icon: Icons.apple,
                outlined: true,
                onPressed: () => _message('Apple sign-in will be available soon.'),
              ),
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SignUpScreen(store: widget.store),
                    ),
                  ),
                  child: const Text("Don't have an account?  Sign Up"),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({required this.store, super.key});

  final ShopStore store;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
  if (!_formKey.currentState!.validate()) return;

  try {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final phone = _phone.text.trim();
    final password = _password.text;

    final response = await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': name,
        'phone': phone,
      },
    );

    if (!mounted) return;

    widget.store.updateProfile(
      name: name,
      emailAddress: email,
      phoneNumber: phone,
    );

    if (response.session == null) {
      _message(
        'Account created! Please check your email to verify your account.',
      );
      return;
    }

    final navigator = Navigator.of(context);

    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => AppShell(
          store: widget.store,
          onLogout: () => returnToLogin(navigator, widget.store),
        ),
      ),
      (_) => false,
    );
  } on AuthException catch (e) {
    if (!mounted) return;
    _message(e.message);
  } catch (e) {
    if (!mounted) return;
    _message('Something went wrong. Please try again.');
  } 
}
void _message(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(25, 10, 25, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create Account', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 7),
              const Text('Join us and find your everyday glow'),
              const SizedBox(height: 25),
              AppTextField(
                label: 'Full Name',
                controller: _name,
                icon: Icons.person_outline,
                validator: _required,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Email Address',
                controller: _email,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value == null || !value.contains('@')
                    ? 'Enter a valid email address'
                    : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Phone Number',
                controller: _phone,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: _required,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Password',
                controller: _password,
                icon: Icons.lock_outline,
                obscureText: true,
                validator: (value) => value == null || value.length < 6
                    ? 'Use at least 6 characters'
                    : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Confirm Password',
                controller: _confirm,
                icon: Icons.lock_outline,
                obscureText: true,
                validator: (value) =>
                    value != _password.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 22),
              PrimaryButton(label: 'Create Account', onPressed: _createAccount),
              const SizedBox(height: 14),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Already have an account?  Log In'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      children: [
        const Icon(Icons.spa_outlined, size: 38, color: AppColors.rose),
        Text(
          'Lunéa Beauti',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontFamily: 'serif',
            color: AppColors.deepRose,
          ),
        ),
      ],
    ),
  );
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Expanded(child: Divider(color: AppColors.line)),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Text('OR', style: TextStyle(color: AppColors.muted, fontSize: 11)),
      ),
      Expanded(child: Divider(color: AppColors.line)),
    ],
  );
}

void returnToLogin(NavigatorState navigator, ShopStore store) {
  navigator.pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => LoginScreen(store: store)),
    (_) => false,
  );
}
