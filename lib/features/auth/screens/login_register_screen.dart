import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_constants.dart';
import '../providers/firebase_auth_provider.dart';

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
    final muted = isDark ? DarkColors.onSurfaceMuted : LightColors.onSurfaceMuted;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────────
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
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in to your account or create a new one',
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                  textAlign: TextAlign.center,
                ),
              ]),
            ),

            // ── Tab bar ──────────────────────────────────────────────────────────
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

            // ── Tab views ────────────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _LoginTab(surface: surface, muted: muted, primary: primary,
                      isDark: isDark, theme: theme),
                  _RegisterTab(surface: surface, muted: muted, primary: primary,
                      isDark: isDark, theme: theme),
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
  final ThemeData theme;

  const _LoginTab({
    required this.surface,
    required this.muted,
    required this.primary,
    required this.isDark,
    required this.theme,
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
    final ok = await ref.read(firebaseAuthProvider.notifier).signInWithEmailPassword(
        _emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    if (!ok) {
      final err = ref.read(firebaseAuthProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err ?? 'Login failed'), backgroundColor: TagColors.missed));
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
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      child: Form(
        key: _formKey,
        child: Column(children: [
          const SizedBox(height: AppSizes.paddingMd),

          // Email
          _InputField(
            controller: _emailCtrl,
            hint: 'Email address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            surface: widget.surface,
            outline: outline,
            muted: widget.muted,
            theme: widget.theme,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter email';
              if (!v.contains('@')) return 'Invalid email';
              return null;
            },
          ),

          const SizedBox(height: AppSizes.paddingMd),

          // Password
          _InputField(
            controller: _passCtrl,
            hint: 'Password',
            icon: Icons.lock_outline_rounded,
            obscure: _obscure,
            surface: widget.surface,
            outline: outline,
            muted: widget.muted,
            theme: widget.theme,
            suffix: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: widget.muted, size: 20),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter password';
              return null;
            },
          ),

          const SizedBox(height: AppSizes.paddingXl),

          // Login button
          _PrimaryButton(
            label: 'Login',
            icon: Icons.login_rounded,
            primary: widget.primary,
            isLoading: isLoading,
            onPressed: _login,
          ),

          const SizedBox(height: AppSizes.paddingMd),
          _Divider(muted: widget.muted, theme: widget.theme),
          const SizedBox(height: AppSizes.paddingMd),

          // Google
          _GoogleButton(
            isLoading: isLoading,
            surface: widget.surface,
            muted: widget.muted,
            outline: outline,
            theme: widget.theme,
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
  final ThemeData theme;

  const _RegisterTab({
    required this.surface,
    required this.muted,
    required this.primary,
    required this.isDark,
    required this.theme,
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
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err ?? 'Registration failed'), backgroundColor: TagColors.missed));
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
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      child: Form(
        key: _formKey,
        child: Column(children: [
          const SizedBox(height: AppSizes.paddingMd),

          // Name
          _InputField(
            controller: _nameCtrl,
            hint: 'Full name',
            icon: Icons.person_outline_rounded,
            keyboardType: TextInputType.name,
            surface: widget.surface,
            outline: outline,
            muted: widget.muted,
            theme: widget.theme,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter your name';
              return null;
            },
          ),

          const SizedBox(height: AppSizes.paddingMd),

          // Email
          _InputField(
            controller: _emailCtrl,
            hint: 'Email address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            surface: widget.surface,
            outline: outline,
            muted: widget.muted,
            theme: widget.theme,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter email';
              if (!v.contains('@')) return 'Invalid email';
              return null;
            },
          ),

          const SizedBox(height: AppSizes.paddingMd),

          // Password
          _InputField(
            controller: _passCtrl,
            hint: 'Password (min 6 chars)',
            icon: Icons.lock_outline_rounded,
            obscure: _obscure,
            surface: widget.surface,
            outline: outline,
            muted: widget.muted,
            theme: widget.theme,
            suffix: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: widget.muted, size: 20),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter password';
              if (v.length < 6) return 'Minimum 6 characters';
              return null;
            },
          ),

          const SizedBox(height: AppSizes.paddingMd),

          // Confirm password
          _InputField(
            controller: _confirmCtrl,
            hint: 'Confirm password',
            icon: Icons.lock_outline_rounded,
            obscure: _obscureConfirm,
            surface: widget.surface,
            outline: outline,
            muted: widget.muted,
            theme: widget.theme,
            suffix: IconButton(
              icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: widget.muted, size: 20),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            validator: (v) {
              if (v != _passCtrl.text) return 'Passwords do not match';
              return null;
            },
          ),

          const SizedBox(height: AppSizes.paddingXl),

          _PrimaryButton(
            label: 'Create Account',
            icon: Icons.person_add_rounded,
            primary: widget.primary,
            isLoading: isLoading,
            onPressed: _register,
          ),

          const SizedBox(height: AppSizes.paddingMd),
          _Divider(muted: widget.muted, theme: widget.theme),
          const SizedBox(height: AppSizes.paddingMd),

          _GoogleButton(
            isLoading: isLoading,
            surface: widget.surface,
            muted: widget.muted,
            outline: outline,
            theme: widget.theme,
            onPressed: _googleSignIn,
          ),

          const SizedBox(height: AppSizes.paddingMd),
        ]),
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;
  final Color surface, outline, muted;
  final ThemeData theme;
  final String? Function(String?)? validator;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.surface,
    required this.outline,
    required this.muted,
    required this.theme,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: outline),
        ),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: muted),
            prefixIcon: Icon(icon, color: muted, size: 20),
            suffixIcon: suffix,
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          ),
        ),
      );
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color primary;
  final bool isLoading;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.primary,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : Icon(icon),
          label: Text(isLoading ? 'Please wait…' : label,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: primary.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusPill)),
          ),
        ),
      );
}

class _GoogleButton extends StatelessWidget {
  final bool isLoading;
  final Color surface, muted, outline;
  final ThemeData theme;
  final VoidCallback onPressed;

  const _GoogleButton({
    required this.isLoading,
    required this.surface,
    required this.muted,
    required this.outline,
    required this.theme,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: surface,
            side: BorderSide(color: outline),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusPill)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            // Google "G" logo
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: const Text(
                'G',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4285F4)),
              ),
            ),
            const SizedBox(width: 10),
            Text('Continue with Google',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600, color: muted)),
          ]),
        ),
      );
}

class _Divider extends StatelessWidget {
  final Color muted;
  final ThemeData theme;
  const _Divider({required this.muted, required this.theme});

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Divider(color: muted.withValues(alpha: 0.3))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or',
              style: theme.textTheme.bodySmall?.copyWith(color: muted)),
        ),
        Expanded(child: Divider(color: muted.withValues(alpha: 0.3))),
      ]);
}
