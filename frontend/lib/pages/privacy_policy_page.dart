import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({
    super.key,
    required this.compact,
    required this.veryCompact,
    required this.onHome,
    required this.onHelp,
    required this.onOpenApp,
  });

  final bool compact;
  final bool veryCompact;
  final VoidCallback onHome;
  final VoidCallback onHelp;
  final VoidCallback onOpenApp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxWidth = compact ? 960.0 : 1140.0;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 20,
        veryCompact ? 18 : 32,
        compact ? 14 : 20,
        28,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PolicyHero(
                  compact: compact,
                  veryCompact: veryCompact,
                  onHome: onHome,
                  onHelp: onHelp,
                ),
                const SizedBox(height: 20),
                _PolicySection(
                  compact: compact,
                  veryCompact: veryCompact,
                  title: 'What this policy covers',
                  body:
                      'This privacy notice describes how the Cropz Card web experience handles business profile data, card records, and link interactions when a card is viewed or shared.',
                ),
                const SizedBox(height: 16),
                _PolicySection(
                  compact: compact,
                  veryCompact: veryCompact,
                  title: 'Information used by the app',
                  body:
                      'Cropz Card can display profile fields such as firm name, owner name, phone number, email address, business identity details, license numbers, bank information, address fields, and uploaded documents when those values exist in the underlying card record.',
                  child: const _BulletList(
                    items: [
                      'Profile and business identity data shown on the public card page.',
                      'License, address, bank, and document metadata stored with the card record.',
                      'Public URL path details and basic browser activity required to render the page.',
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _PolicySection(
                  compact: compact,
                  veryCompact: veryCompact,
                  title: 'How the data is used',
                  body:
                      'Cropz Card uses the record data to render the public card, route users to the correct page, support deep links into the app, and let viewers copy contact details or open the card in the app.',
                  child: const _BulletList(
                    items: [
                      'Show the public card view from the saved card record.',
                      'Navigate users between the Home, Help, and Privacy Policy pages.',
                      'Open the native app through the deep link when available.',
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _PolicySection(
                  compact: compact,
                  veryCompact: veryCompact,
                  title: 'Public sharing and visibility',
                  body:
                      'If a card is shared publicly, the information placed on that card can be viewed by anyone with the link. Do not include data on a card unless the owner intends to make it visible to viewers of that link.',
                ),
                const SizedBox(height: 16),
                _PolicySection(
                  compact: compact,
                  veryCompact: veryCompact,
                  title: 'Third-party services',
                  body:
                      'Cropz Card uses service providers to store card records and deliver the public card page. The public card page does not include advertising or social tracking features.',
                  child: const _BulletList(
                    items: [
                      'Card records are stored so shared links can display the selected information.',
                      'The web experience is delivered through hosting and support services.',
                      'The browser may store standard session state required to load and navigate the page.',
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _PolicySection(
                  compact: compact,
                  veryCompact: veryCompact,
                  title: 'Retention and control',
                  body:
                      'Card data remains available until it is updated, restricted, or removed by the account owner or administrator. If you want a card to stop showing information publicly, remove or restrict the card record that feeds the page.',
                ),
                const SizedBox(height: 16),
                _PolicySection(
                  compact: compact,
                  veryCompact: veryCompact,
                  title: 'Contact and requests',
                  body:
                      'If you want a correction, deletion, or a clarification about a specific card, use the Help page and include the card ID or link so the record can be identified quickly.',
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton(
                        onPressed: onOpenApp,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF194F32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Open in App'),
                      ),
                      OutlinedButton(
                        onPressed: onHelp,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF194F32),
                          side: const BorderSide(color: Color(0xFF83C341)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Go to Help'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'This page is a product privacy notice for Cropz Card. It is not legal advice.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PolicyHero extends StatelessWidget {
  const _PolicyHero({
    required this.compact,
    required this.veryCompact,
    required this.onHome,
    required this.onHelp,
  });

  final bool compact;
  final bool veryCompact;
  final VoidCallback onHome;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(veryCompact ? 24 : 32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7FAF6), Colors.white],
        ),
        border: Border.all(color: const Color(0xFFDCE6DD)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D341F).withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              gradient: const LinearGradient(
                colors: [Color(0xFF83C341), Color(0xFF2D7A48)],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(veryCompact ? 18 : (compact ? 22 : 30)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Policy',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF2D7A48),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'How Cropz Card handles public card data',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                    color: const Color(0xFF13251A),
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Text(
                    'This page explains what is shown on public cards, how shared links work, and how viewers can move from the web page into the app.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      height: 1.55,
                      color: const Color(0xFF617066),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _HeroLink(label: 'Home', onPressed: onHome),
                    _HeroLink(label: 'Help', onPressed: onHelp),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    required this.compact,
    required this.veryCompact,
    required this.title,
    required this.body,
    this.child,
  });

  final bool compact;
  final bool veryCompact;
  final String title;
  final String body;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _ActivePanel(
      borderRadius: BorderRadius.circular(veryCompact ? 22 : 28),
      child: Container(
        padding: EdgeInsets.all(veryCompact ? 18 : (compact ? 20 : 28)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(veryCompact ? 22 : 28),
          color: Colors.white.withValues(alpha: 0.96),
          border: Border.all(color: const Color(0xFFDCE6DD)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.1,
                color: const Color(0xFF13251A),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.55,
                color: const Color(0xFF617066),
              ),
            ),
            if (child != null) ...[const SizedBox(height: 16), child!],
          ],
        ),
      ),
    );
  }
}

class _HeroLink extends StatelessWidget {
  const _HeroLink({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF194F32),
        backgroundColor: const Color(0xFF83C341).withValues(alpha: 0.13),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    );
  }
}

class _ActivePanel extends StatefulWidget {
  const _ActivePanel({required this.child, required this.borderRadius});

  final Widget child;
  final BorderRadius borderRadius;

  @override
  State<_ActivePanel> createState() => _ActivePanelState();
}

class _ActivePanelState extends State<_ActivePanel> {
  bool _hovering = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = _hovering || _pressed;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() {
        _hovering = false;
        _pressed = false;
      }),
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.99 : (active ? 1.006 : 1),
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFF0D341F,
                  ).withValues(alpha: active ? 0.15 : 0.07),
                  blurRadius: active ? 30 : 18,
                  offset: Offset(0, active ? 16 : 8),
                ),
              ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '•',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.55,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
