import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miningguard/core/router/app_router.dart';
import 'package:miningguard/features/auth/providers/auth_providers.dart';
import 'package:miningguard/features/auth/services/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Email tab
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _emailLoading = false;
  String? _emailError;

  // Phone tab
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _phoneLoading = false;
  String? _phoneError;
  String? _verificationId;
  int? _resendToken;
  int _resendCountdown = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  // ── Email sign-in ─────────────────────────────────────────────────────────

  Future<void> _signInWithEmail() async {
    setState(() {
      _emailLoading = true;
      _emailError = null;
    });
    try {
      await ref.read(authServiceProvider).signInWithEmail(
            _emailController.text,
            _passwordController.text,
          );
      await _navigateAfterAuth();
    } on AuthException catch (e) {
      setState(() => _emailError = e.message);
    } finally {
      if (mounted) setState(() => _emailLoading = false);
    }
  }

  // ── Phone OTP sign-in ─────────────────────────────────────────────────────

  Future<void> _sendOtp() async {
    setState(() {
      _phoneLoading = true;
      _phoneError = null;
    });
    final phone = '+91${_phoneController.text.trim()}';
    await ref.read(authServiceProvider).sendOtp(
      phoneNumber: phone,
      resendToken: _resendToken,
      onAutoVerified: (credential) async {
        try {
          await FirebaseAuth.instance.signInWithCredential(credential);
          await _navigateAfterAuth();
        } catch (_) {}
      },
      onCodeSent: (id, token) {
        setState(() {
          _verificationId = id;
          _resendToken = token;
          _otpSent = true;
          _phoneLoading = false;
        });
        _startResendCountdown();
      },
      onFailed: (e) {
        setState(() {
          _phoneError = 'Failed to send OTP. Check the number and try again.';
          _phoneLoading = false;
        });
      },
    );
  }

  Future<void> _verifyOtp() async {
    if (_verificationId == null) return;
    setState(() {
      _phoneLoading = true;
      _phoneError = null;
    });
    try {
      await ref.read(authServiceProvider).verifyOtp(
            _verificationId!,
            _otpController.text.trim(),
          );
      await _navigateAfterAuth();
    } on AuthException catch (e) {
      setState(() => _phoneError = e.message);
    } finally {
      if (mounted) setState(() => _phoneLoading = false);
    }
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _resendCountdown = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) t.cancel();
      });
    });
  }

  // ── Post-auth routing ─────────────────────────────────────────────────────

  Future<void> _navigateAfterAuth() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || !mounted) return;
    final user = await ref.read(userRepositoryProvider).getUser(uid);
    if (!mounted) return;
    if (user == null) {
      context.go(AppRoutes.signup);
    } else {
      switch (user.role) {
        case UserRole.admin:
          context.go(AppRoutes.adminPanel);
        case UserRole.supervisor:
          context.go(AppRoutes.supervisorDashboard);
        case UserRole.worker:
          context.go(AppRoutes.workerHome);
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF1A1A2E);
    const amber = Color(0xFFF5A623);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              const Icon(Icons.engineering, size: 64, color: amber),
              const SizedBox(height: 12),
              const Text(
                'MiningGuard',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'login.subtitle',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 32),
              TabBar(
                controller: _tabController,
                indicatorColor: amber,
                labelColor: amber,
                unselectedLabelColor: Colors.white54,
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'login.tab.email'),
                  Tab(text: 'login.tab.phone'),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _EmailTab(
                      emailController: _emailController,
                      passwordController: _passwordController,
                      passwordVisible: _passwordVisible,
                      onTogglePassword: () =>
                          setState(() => _passwordVisible = !_passwordVisible),
                      loading: _emailLoading,
                      error: _emailError,
                      onSignIn: _signInWithEmail,
                    ),
                    _PhoneTab(
                      phoneController: _phoneController,
                      otpController: _otpController,
                      otpSent: _otpSent,
                      loading: _phoneLoading,
                      error: _phoneError,
                      resendCountdown: _resendCountdown,
                      onSendOtp: _sendOtp,
                      onVerifyOtp: _verifyOtp,
                      onResend: _sendOtp,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Email Tab ─────────────────────────────────────────────────────────────────

class _EmailTab extends StatelessWidget {
  const _EmailTab({
    required this.emailController,
    required this.passwordController,
    required this.passwordVisible,
    required this.onTogglePassword,
    required this.loading,
    required this.error,
    required this.onSignIn,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool passwordVisible;
  final VoidCallback onTogglePassword;
  final bool loading;
  final String? error;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Field(
            controller: emailController,
            label: 'login.email',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _Field(
            controller: passwordController,
            label: 'login.password',
            obscure: !passwordVisible,
            suffix: IconButton(
              icon: Icon(
                passwordVisible ? Icons.visibility_off : Icons.visibility,
                color: Colors.white54,
              ),
              onPressed: onTogglePassword,
            ),
          ),
          const SizedBox(height: 8),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 14),
              ),
            ),
          const SizedBox(height: 8),
          _PrimaryButton(
            label: 'login.signIn',
            loading: loading,
            onPressed: loading ? null : onSignIn,
          ),
        ],
      ),
    );
  }
}

// ── Phone Tab ─────────────────────────────────────────────────────────────────

class _PhoneTab extends StatelessWidget {
  const _PhoneTab({
    required this.phoneController,
    required this.otpController,
    required this.otpSent,
    required this.loading,
    required this.error,
    required this.resendCountdown,
    required this.onSendOtp,
    required this.onVerifyOtp,
    required this.onResend,
  });

  final TextEditingController phoneController;
  final TextEditingController otpController;
  final bool otpSent;
  final bool loading;
  final String? error;
  final int resendCountdown;
  final VoidCallback onSendOtp;
  final VoidCallback onVerifyOtp;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white38),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '+91',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Field(
                  controller: phoneController,
                  label: 'login.phone',
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!otpSent) ...[
            _PrimaryButton(
              label: 'login.sendOtp',
              loading: loading,
              onPressed: loading ? null : onSendOtp,
            ),
          ] else ...[
            _Field(
              controller: otpController,
              label: 'login.enterOtp',
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            const SizedBox(height: 16),
            _PrimaryButton(
              label: 'login.verifyOtp',
              loading: loading,
              onPressed: loading ? null : onVerifyOtp,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: resendCountdown > 0 ? null : onResend,
              child: Text(
                resendCountdown > 0
                    ? 'login.resendIn $resendCountdown s'
                    : 'login.resend',
                style: TextStyle(
                  color:
                      resendCountdown > 0 ? Colors.white38 : const Color(0xFFF5A623),
                  fontSize: 16,
                ),
              ),
            ),
          ],
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Shared form widgets ────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
    this.maxLength,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: const TextStyle(color: Colors.white, fontSize: 18),
      decoration: InputDecoration(
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
        suffixIcon: suffix,
        counterText: '',
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF5A623),
          foregroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF1A1A2E),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
