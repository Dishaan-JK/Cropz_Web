import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({
    super.key,
    required this.compact,
    required this.veryCompact,
    required this.onHome,
    required this.onAbout,
    required this.onHelp,
    required this.onOpenApp,
  });

  final bool compact;
  final bool veryCompact;
  final VoidCallback onHome;
  final VoidCallback onAbout;
  final VoidCallback onHelp;
  final VoidCallback onOpenApp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxWidth = compact ? 960.0 : 1120.0;
    return ListView(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 28, 8, compact ? 16 : 28, 28),
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
                  onAbout: onAbout,
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
                      'The web app uses the record data to render the public card, route users to the correct card page, support deep links into the app, and let viewers copy contact details or open the card in the native experience.',
                  child: const _BulletList(
                    items: [
                      'Serve the public card view from the backend record.',
                      'Navigate users between the home, about, help, and privacy pages.',
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
                      'The current implementation fetches card data from PocketBase and is served through Netlify hosting. No analytics, ad networks, or social tracking integrations are defined in this repository at the moment.',
                  child: const _BulletList(
                    items: [
                      'PocketBase stores and serves the card records.',
                      'Netlify serves the web app and function endpoints.',
                      'The browser may store standard session state required by the platform itself.',
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _PolicySection(
                  compact: compact,
                  veryCompact: veryCompact,
                  title: 'Retention and control',
                  body:
                      'Card data stays in the connected backend until it is updated or removed by the account owner or administrator. If you want a card to stop showing information publicly, remove or restrict the source record that feeds the page.',
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
                        child: const Text('Open in App'),
                      ),
                      OutlinedButton(
                        onPressed: onHelp,
                        child: const Text('Go to Help'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'This page is a product privacy notice for the current Cropz Card web implementation. It is not legal advice.',
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
    required this.onAbout,
    required this.onHelp,
  });

  final bool compact;
  final bool veryCompact;
  final VoidCallback onHome;
  final VoidCallback onAbout;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(veryCompact ? 24 : 32),
        color: theme.colorScheme.surface.withValues(alpha: 0.96),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.18),
        ),
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
              color: const Color(0xFF1A7A5C),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(veryCompact ? 18 : (compact ? 22 : 30)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Policy',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF1A7A5C),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'How Cropz Card handles public card data',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Text(
                    'This page explains the app-specific data flow: what is shown on public cards, what the web app reads from the backend, and how link navigation and app handoff work.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      height: 1.55,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.74),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    TextButton(
                      onPressed: onHome,
                      child: const Text('Home'),
                    ),
                    TextButton(
                      onPressed: onAbout,
                      child: const Text('About'),
                    ),
                    TextButton(
                      onPressed: onHelp,
                      child: const Text('Help'),
                    ),
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
    return Container(
      padding: EdgeInsets.all(veryCompact ? 18 : (compact ? 20 : 28)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(veryCompact ? 22 : 28),
        color: theme.colorScheme.surface.withValues(alpha: 0.88),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.55,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
          if (child != null) ...[
            const SizedBox(height: 16),
            child!,
          ],
        ],
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
