import 'package:flutter/material.dart';

import '../../core/theme/theme_constants.dart';

// ── Intro page data ───────────────────────────────────────────────────────────

class _IntroPage {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _IntroPage({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}

const _pages = [
  _IntroPage(
    icon: Icons.alarm_rounded,
    color: Color(0xFF6C5CE7),
    title: 'Never Miss a Dose',
    body:
        'MedRemind rings an alarm exactly when it\'s time to take your medicine — '
        'even when your phone screen is off or you\'re using another app.',
  ),
  _IntroPage(
    icon: Icons.medication_liquid_rounded,
    color: Color(0xFF00B4D8),
    title: 'Your Medicine Cabinet',
    body:
        'Add all your medicines once. Then create dose groups — Morning, Afternoon, '
        'Evening or Night — and assign medicines to each group with the right quantity.',
  ),
  _IntroPage(
    icon: Icons.bar_chart_rounded,
    color: Color(0xFF00C896),
    title: 'Track Your Adherence',
    body:
        'Mark doses as Taken, Snoozed or Skipped right from the alarm screen or '
        'Home tab. The Daily Planner shows your full history so you stay on track.',
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class OnboardingIntroScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingIntroScreen({super.key, required this.onDone});

  @override
  State<OnboardingIntroScreen> createState() => _OnboardingIntroScreenState();
}

class _OnboardingIntroScreenState extends State<OnboardingIntroScreen> {
  final _controller = PageController();
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_current < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } else {
      widget.onDone();
    }
  }

  void _skip() => widget.onDone();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLast = _current == _pages.length - 1;

    return Scaffold(
      backgroundColor: isDark ? DarkColors.background : LightColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip button ───────────────────────────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 20, 0),
                child: TextButton(
                  onPressed: _skip,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            ),

            // ── Page view ─────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _current = i),
                itemBuilder: (_, i) => _IntroPageView(page: _pages[i]),
              ),
            ),

            // ── Dots ──────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _current ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _current
                        ? _pages[_current].color
                        : theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSizes.paddingXl),

            // ── Next / Get started button ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSizes.paddingLg, 0,
                  AppSizes.paddingLg, AppSizes.paddingLg),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _pages[_current].color,
                        _pages[_current].color.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    boxShadow: [
                      BoxShadow(
                        color: _pages[_current].color.withValues(alpha: 0.4),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusPill),
                      ),
                    ),
                    child: Text(
                      isLast ? 'Get Started' : 'Next',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Single intro page ─────────────────────────────────────────────────────────

class _IntroPageView extends StatelessWidget {
  final _IntroPage page;
  const _IntroPageView({required this.page});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingXl, vertical: AppSizes.paddingLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon circle
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  page.color.withValues(alpha: 0.25),
                  page.color.withValues(alpha: 0.06),
                ],
              ),
              border: Border.all(color: page.color.withValues(alpha: 0.3),
                  width: 2),
              boxShadow: [
                BoxShadow(
                  color: page.color.withValues(alpha: 0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(page.icon, size: 64, color: page.color),
          ),

          const SizedBox(height: 48),

          Text(
            page.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            page.body,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

