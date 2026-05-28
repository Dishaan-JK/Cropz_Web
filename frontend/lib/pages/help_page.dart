import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({
    super.key,
    required this.compact,
    required this.veryCompact,
    required this.onHome,
    required this.onAbout,
    required this.onPrivacy,
    required this.onOpenApp,
  });

  final bool compact;
  final bool veryCompact;
  final VoidCallback onHome;
  final VoidCallback onAbout;
  final VoidCallback onPrivacy;
  final VoidCallback onOpenApp;

  @override
  Widget build(BuildContext context) {
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
                _FormHero(
                  compact: compact,
                  veryCompact: veryCompact,
                  onHome: onHome,
                  onAbout: onAbout,
                  onPrivacy: onPrivacy,
                ),
                const SizedBox(height: 20),
                _SectionCard(
                  compact: compact,
                  veryCompact: veryCompact,
                  title: 'Tell us what is happening',
                  subtitle:
                      'Use this support flow to describe what you are trying to do, where it broke, and what card or link is involved.',
                  child: Column(
                    children: [
                      const _FormFieldLine(
                        label: 'Your name',
                        hint: 'Enter the name on the support request',
                      ),
                      const SizedBox(height: 16),
                      const _FormFieldLine(
                        label: 'Email address',
                        hint: 'Where we should reply',
                      ),
                      const SizedBox(height: 16),
                      const _FormFieldLine(
                        label: 'Card link or ID',
                        hint: 'Paste the public card URL or record ID',
                      ),
                      const SizedBox(height: 16),
                      const _FormFieldLine(
                        label: 'What do you need help with?',
                        hint:
                            'Example: card will not load, profile is wrong, app link is not opening',
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _SectionCard(
                  compact: compact,
                  veryCompact: veryCompact,
                  title: 'Common issues',
                  subtitle:
                      'These are the most common support paths for the current web experience.',
                  child: Column(
                    children: const [
                      _FaqTile(
                        title: 'The page opens blank',
                        body:
                            'Refresh once, then check that the browser is loading the latest deploy. If the app shell loads but the content does not, the issue is usually in the web build or routing layer.',
                      ),
                      _FaqTile(
                        title: 'The card link is not opening in the app',
                        body:
                            'Use the Open in App action. If the app is not installed, the web surface stays available and the card still opens in the browser.',
                      ),
                      _FaqTile(
                        title: 'A business detail looks outdated',
                        body:
                            'The visible fields are read from the backend record. Ask the card owner to update the source profile and redeploy or resync the data.',
                      ),
                      _FaqTile(
                        title: 'I need to share a support report',
                        body:
                            'Copy the template below and paste it into email or chat so the issue is easier to reproduce.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _SectionCard(
                  compact: compact,
                  veryCompact: veryCompact,
                  title: 'Support template',
                  subtitle:
                      'A Google Form-style form block for collecting the minimum details needed to debug the issue.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SupportTemplate(
                        veryCompact: veryCompact,
                        compact: compact,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton(
                            onPressed: onOpenApp,
                            child: const Text('Open in App'),
                          ),
                          OutlinedButton(
                            onPressed: () async {
                              const template = '''
Cropz Card support request
- Name:
- Email:
- Card link or ID:
- Device/browser:
- What happened:
- What did you expect:
''';
                              await Clipboard.setData(
                                const ClipboardData(text: template),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Support template copied'),
                                  ),
                                );
                              }
                            },
                            child: const Text('Copy template'),
                          ),
                        ],
                      ),
                    ],
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

class _FormHero extends StatelessWidget {
  const _FormHero({
    required this.compact,
    required this.veryCompact,
    required this.onHome,
    required this.onAbout,
    required this.onPrivacy,
  });

  final bool compact;
  final bool veryCompact;
  final VoidCallback onHome;
  final VoidCallback onAbout;
  final VoidCallback onPrivacy;

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
                  'Help',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF1A7A5C),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Need help with Cropz Card?',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Text(
                    'Use this page like a form. Add the card ID, what happened, and which screen or link you were using so the issue can be reproduced quickly.',
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
                      onPressed: onPrivacy,
                      child: const Text('Privacy Policy'),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.compact,
    required this.veryCompact,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final bool compact;
  final bool veryCompact;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(veryCompact ? 18 : (compact ? 20 : 28)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(veryCompact ? 24 : 30),
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
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Text(
              subtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.55,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _FormFieldLine extends StatelessWidget {
  const _FormFieldLine({
    required this.label,
    required this.hint,
    this.maxLines = 1,
  });

  final String label;
  final String hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fieldHeight = maxLines > 1 ? 126.0 : 58.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: fieldHeight,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.86),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.22),
            ),
          ),
          alignment: Alignment.topLeft,
          child: Text(
            hint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.46),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.68),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.18),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        children: [
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.55,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.74),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportTemplate extends StatelessWidget {
  const _SupportTemplate({
    required this.compact,
    required this.veryCompact,
  });

  final bool compact;
  final bool veryCompact;

  @override
  Widget build(BuildContext context) {
    final items = const [
      ('Name', 'Who should we reply to?'),
      ('Email', 'Reply address'),
      ('Card / link', 'The exact page or ID'),
      ('Device', 'Browser or phone model'),
    ];
    if (veryCompact || compact) {
      return Column(
        children: [
          for (final item in items) ...[
            _SupportTile(title: item.$1, subtitle: item.$2),
            const SizedBox(height: 12),
          ],
        ],
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final item in items)
          SizedBox(
            width: (MediaQuery.sizeOf(context).width > 900 ? 240 : 220),
            child: _SupportTile(title: item.$1, subtitle: item.$2),
          ),
      ],
    );
  }
}

class _SupportTile extends StatelessWidget {
  const _SupportTile({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
            ),
          ),
        ],
      ),
    );
  }
}
