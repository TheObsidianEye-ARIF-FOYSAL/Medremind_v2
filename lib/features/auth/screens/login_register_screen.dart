import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_constants.dart';
import '../providers/firebase_auth_provider.dart';
import '../widgets/auth_form_widgets.dart';
import '../widgets/forgot_password_sheet.dart';

class LoginRegisterScreen extends ConsumerStatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  ConsumerState<LoginRegisterScreen> createState() =>
      _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends ConsumerState<LoginRegisterScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? DarkColors.background : LightColors.background;
    final surface = isDark ? DarkColors.surface : LightColors.surface;
    final muted =
        isDark ? DarkColors.onSurfaceMuted : LightColors.onSurfaceMuted;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.paddingLg, AppSizes.paddingXl,
                  AppSizes.paddingLg, AppSizes.paddingMd),
              child: Column(children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary.withValues(alpha: 0.13),
                    border: Border.all(
                        color: primary.withValues(alpha: 0.3), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.25),
                        blurRadius: 28,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(Icons.medication_rounded, color: primary, size: 40),
                ),
                const SizedBox(height: AppSizes.paddingMd),
                Text(
                  'Welcome to MedRemind',
                  style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800, letterSpacing: -0.3),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in to your account or create a new one',
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                  textAlign: TextAlign.center,
                ),
              ]),
            ),

            // ── Tab bar ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLg),
              child: Container(
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                ),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: _tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: muted,
                  indicator: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                  tabs: const [
                    Tab(text: 'Login'),
                    Tab(text: 'Register'),
                  ],
                ),
              ),
            ),

            // ── Tab views ────────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _LoginTab(surface: surface, muted: muted, primary: primary,
                      isDark: isDark),
                  _RegisterTab(surface: surface, muted: muted, primary: primary,
                      isDark: isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Login tab ─────────────────────────────────────────────────────────────────

class _LoginTab extends ConsumerStatefulWidget {
  final Color surface, muted, primary;
  final bool isDark;

  const _LoginTab({
    required this.surface,
    required this.muted,
    required this.primary,
    required this.isDark,
  });

  @override
  ConsumerState<_LoginTab> createState() => _LoginTabState();
}

class _LoginTabState extends ConsumerState<_LoginTab> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(firebaseAuthProvider.notifier)
        .signInWithEmailPassword(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    if (!ok) {
      final err = ref.read(firebaseAuthProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(err ?? 'Login failed'),
          backgroundColor: TagColors.missed));
    }
  }

  void _showForgotPassword() {
    final emailCtrl = TextEditingController(text: _emailCtrl.text.trim());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ForgotPasswordSheet(
        emailCtrl: emailCtrl,
        notifier: ref.read(firebaseAuthProvider.notifier),
      ),
    );
  }

  Future<void> _googleSignIn() async {
    final ok = await ref.read(firebaseAuthProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    if (!ok) {
      final err = ref.read(firebaseAuthProvider).error;
      if (err != null && !err.contains('cancelled')) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: TagColors.missed));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(firebaseAuthProvider).isLoading;
    final outline =
        widget.isDark ? DarkColors.outline : LightColors.outline;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      child: Form(
        key: _formKey,
        child: Column(children: [
          const SizedBox(height: AppSizes.paddingMd),

          AuthInputField(
            controller: _emailCtrl,
            hint: 'Email address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            surface: widget.surface,
            outline: outline,
            muted: widget.muted,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter email';
              if (!v.contains('@')) return 'Invalid email';
              return null;
            },
          ),

          const SizedBox(height: AppSizes.paddingMd),

          AuthInputField(
            controller: _passCtrl,
            hint: 'Password',
            icon: Icons.lock_outline_rounded,
            obscure: _obscure,
            surface: widget.surface,
            outline: outline,
            muted: widget.muted,
            suffix: IconButton(
              icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: widget.muted,
                  size: 20),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Enter password' : null,
          ),

          const SizedBox(height: AppSizes.paddingSm),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _showForgotPassword,
              style: TextButton.styleFrom(
                foregroundColor: widget.primary,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Forgot Password?',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),

          const SizedBox(height: AppSizes.paddingMd),

          AuthPrimaryButton(
            label: 'Login',
            icon: Icons.login_rounded,
            primary: widget.primary,
            isLoading: isLoading,
            onPressed: _login,
          ),

          const SizedBox(height: AppSizes.paddingMd),
          AuthOrDivider(muted: widget.muted),
          const SizedBox(height: AppSizes.paddingMd),

          AuthGoogleButton(
            isLoading: isLoading,
            surface: widget.surface,
            muted: widget.muted,
            outline: outline,
            onPressed: _googleSignIn,
          ),
        ]),
      ),
    );
  }
}

// ── Register tab ──────────────────────────────────────────────────────────────

class _RegisterTab extends ConsumerStatefulWidget {
  final Color surface, muted, primary;
  final bool isDark;

  const _RegisterTab({
    required this.surface,
    required this.muted,
    required this.primary,
    required this.isDark,
  });

  @override
  ConsumerState<_RegisterTab> createState() => _RegisterTabState();
}

class _RegisterTabState extends ConsumerState<_RegisterTab> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(firebaseAuthProvider.notifier)
        .registerWithEmailPassword(
            _nameCtrl.text.trim(), _emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    if (!ok) {
      final err = ref.read(firebaseAuthProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(err ?? 'Registration failed'),
          backgroundColor: TagColors.missed));
    }
  }

  Future<void> _googleSignIn() async {
    final ok = await ref.read(firebaseAuthProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    if (!ok) {
      final err = ref.read(firebaseAuthProvider).error;
      if (err != null && !err.contains('cancelled')) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: TagColors.missed));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(firebaseAuthProvider).isLoading;
    final outline = widget.isDark ? DarkColors.outline : LightColors.outline;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      child: Form(
        key: _formKey,
        child: Column(children: [
          const SizedBox(height: AppSizes.paddingMd),

          AuthInputField(
            controller: _nameCtrl,
            hint: 'Full name',
            icon: Icons.person_outline_rounded,
            keyboardType: TextInputType.name,
            surface: widget.surface,
            outline: outline,
            muted: widget.muted,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
          ),

          const SizedBox(height: AppSizes.paddingMd),

          AuthInputField(
            controller: _emailCtrl,
            hint: 'Email address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            surface: widget.surface,
            outline: outline,
            muted: widget.muted,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter email';
              if (!v.contains('@')) return 'Invalid email';
              return null;
            },
          ),

          const SizedBox(height: AppSizes.paddingMd),

          AuthInputField(
            controller: _passCtrl,
            hint: 'Password (min 6 chars)',
            icon: Icons.lock_outline_rounded,
            obscure: _obscure,
            surface: widget.surface,
            outline: outline,
            muted: widget.muted,
            suffix: IconButton(
              icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: widget.muted,
                  size: 20),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter password';
              if (v.length < 6) return 'Minimum 6 characters';
              return null;
            },
          ),

          const SizedBox(height: AppSizes.paddingMd),

          AuthInputField(
            controller: _confirmCtrl,
            hint: 'Confirm password',
            icon: Icons.lock_outline_rounded,
            obscure: _obscureConfirm,
            surface: widget.surface,
            outline: outline,
            muted: widget.muted,
            suffix: IconButton(
              icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: widget.muted,
                  size: 20),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            validator: (v) =>
                v != _passCtrl.text ? 'Passwords do not match' : null,
          ),

          const SizedBox(height: AppSizes.paddingXl),

          AuthPrimaryButton(
            label: 'Create Account',
            icon: Icons.person_add_rounded,
            primary: widget.primary,
            isLoading: isLoading,
            onPressed: _register,
          ),

          const SizedBox(height: AppSizes.paddingMd),
          AuthOrDivider(muted: widget.muted),
          const SizedBox(height: AppSizes.paddingMd),

          AuthGoogleButton(
            isLoading: isLoading,
            surface: widget.surface,
            muted: widget.muted,
            outline: outline,
            onPressed: _googleSignIn,
          ),

          const SizedBox(height: AppSizes.paddingMd),
        ]),
      ),
    );
  }
}
