import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:http/http.dart' as http;
import 'pages/help_page.dart';
import 'pages/privacy_policy_page.dart';
import 'web_bridge_stub.dart'
    if (dart.library.html) 'web_bridge_web.dart'
    as web_bridge;

void main() {
  usePathUrlStrategy();
  runApp(const CropzWebApp());
}

class CropzWebApp extends StatefulWidget {
  const CropzWebApp({super.key});

  @override
  State<CropzWebApp> createState() => _CropzWebAppState();
}

class _CropzWebAppState extends State<CropzWebApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) {
      return;
    }
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF1A7A5C);
    final lightScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    ).copyWith(
      surface: const Color(0xFFF8F4EC),
      surfaceContainer: const Color(0xFFF0E8D8),
      surfaceContainerHighest: const Color(0xFFE6DBC4),
      outline: const Color(0xFFCDC2AA),
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF0D1511),
      surfaceContainer: const Color(0xFF13201A),
      surfaceContainerHighest: const Color(0xFF172722),
      outline: const Color(0xFF33463D),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cropz Card',
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: lightScheme,
        scaffoldBackgroundColor: const Color(0xFFF8F4EC),
        useMaterial3: true,
        textTheme: Typography.material2021().black,
        dividerTheme: const DividerThemeData(
          color: Color(0xFFD4C8AF),
          thickness: 1,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: darkScheme,
        scaffoldBackgroundColor: const Color(0xFF09130F),
        useMaterial3: true,
        textTheme: Typography.material2021().white,
        dividerTheme: const DividerThemeData(
          color: Color(0xFF33463D),
          thickness: 1,
        ),
      ),
      home: PreviewPage(
        themeMode: _themeMode,
        onThemeModeChanged: _setThemeMode,
      ),
    );
  }
}

enum _PageMode { home, about, help, privacy, preview }

class PreviewPage extends StatefulWidget {
  const PreviewPage({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage>
    with SingleTickerProviderStateMixin {
  Future<Map<String, dynamic>>? _future;
  String? _cardId;
  late _PageMode _mode;
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    final uri = Uri.base;
    final path = uri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (path.isEmpty) {
      _mode = _PageMode.home;
    } else if (path.first.toLowerCase() == 'about') {
      _mode = _PageMode.about;
    } else if (path.first.toLowerCase() == 'help') {
      _mode = _PageMode.help;
    } else if (path.first.toLowerCase() == 'privacy') {
      _mode = _PageMode.privacy;
    } else {
      _mode = _PageMode.preview;
      _cardId = path.first;
      _future = _fetchCard(_cardId!);
    }

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchCard(String cardId) async {
    final apiBase = const String.fromEnvironment('API_BASE');
    final uri = apiBase.isEmpty
        ? Uri.base.resolve('/api/cards/$cardId')
        : Uri.parse(apiBase).resolve('/api/cards/$cardId');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch card: ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> _openInApp() async {
    final deepLink = _cardId == null
        ? 'cropzcard://card'
        : 'cropzcard://card/$_cardId';
    var appOpened = false;
    final visibilitySub = web_bridge.watchDocumentVisibility(() {
      appOpened = true;
    });
    final cleanup = web_bridge.mountHiddenIframe(deepLink);

    await Future<void>.delayed(const Duration(milliseconds: 1200));
    cleanup();
    await visibilitySub.cancel();

    if (!appOpened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cropz Card not installed.')),
      );
    }
  }

  Future<void> _copyPhone(String phone) async {
    final copied = await web_bridge.copyText(phone);
    if (!copied || !mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Phone number copied')),
    );
  }

  void _navigateTo(String path) {
    web_bridge.navigateTo(path);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 860;
    final veryCompact = width < 560;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              final t = _bgController.value * 2 * math.pi;
              return CustomPaint(
                painter: _BackgroundPainter(
                  t,
                  brightness: Theme.of(context).brightness,
                ),
                size: Size.infinite,
              );
            },
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 14 : 24,
                    compact ? 10 : 14,
                    compact ? 14 : 24,
                    compact ? 6 : 10,
                  ),
                  child: _TopBar(
                    compact: compact,
                    veryCompact: veryCompact,
                    currentMode: _mode,
                    onHome: () => _navigateTo('/'),
                    onAbout: () => _navigateTo('/about'),
                    onHelp: () => _navigateTo('/help'),
                    onPrivacy: () => _navigateTo('/privacy'),
                    onOpenApp: _openInApp,
                    themeMode: widget.themeMode,
                    onThemeModeChanged: widget.onThemeModeChanged,
                  ),
                ),
                Expanded(
                  child: switch (_mode) {
                    _PageMode.home => _buildHomePage(
                      compact: compact,
                      veryCompact: veryCompact,
                    ),
                    _PageMode.about => _buildAboutPage(
                      compact: compact,
                      veryCompact: veryCompact,
                    ),
                    _PageMode.help => HelpPage(
                      compact: compact,
                      veryCompact: veryCompact,
                      onHome: () => _navigateTo('/'),
                      onAbout: () => _navigateTo('/about'),
                      onPrivacy: () => _navigateTo('/privacy'),
                      onOpenApp: _openInApp,
                    ),
                    _PageMode.privacy => PrivacyPolicyPage(
                      compact: compact,
                      veryCompact: veryCompact,
                      onHome: () => _navigateTo('/'),
                      onAbout: () => _navigateTo('/about'),
                      onHelp: () => _navigateTo('/help'),
                      onOpenApp: _openInApp,
                    ),
                    _PageMode.preview => FutureBuilder<Map<String, dynamic>>(
                      future: _future,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return _buildErrorState(snapshot.error.toString());
                        }
                        final data = snapshot.data!;
                        final profile =
                            (data['profile'] as Map?)
                                ?.cast<String, dynamic>() ??
                            <String, dynamic>{};
                        final digital =
                            (data['digitalBusinessCard'] as Map?)
                                ?.cast<String, dynamic>() ??
                            <String, dynamic>{};
                        final business =
                            (data['business'] as Map?)
                                ?.cast<String, dynamic>() ??
                            <String, dynamic>{};
                        final license =
                            (data['licenseInfo'] as Map?)
                                ?.cast<String, dynamic>() ??
                            <String, dynamic>{};
                        final address =
                            (data['address'] as Map?)
                                ?.cast<String, dynamic>() ??
                            <String, dynamic>{};
                        final banks =
                            ((data['bankAccounts'] as List?) ??
                                    const <dynamic>[])
                                .map(
                                  (entry) =>
                                      (entry as Map).cast<String, dynamic>(),
                                )
                                .toList();
                        final documents =
                            ((data['documents'] as List?) ?? const <dynamic>[])
                                .map(
                                  (entry) =>
                                      (entry as Map).cast<String, dynamic>(),
                                )
                                .toList();

                        return _buildPreviewContent(
                          profile: profile,
                          digital: digital,
                          business: business,
                          license: license,
                          banks: banks,
                          address: address,
                          documents: documents,
                          compact: compact,
                          veryCompact: veryCompact,
                        );
                      },
                    ),
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomePage({
    required bool compact,
    required bool veryCompact,
  }) {
    const sampleCard = {
      'firm': 'Aadhira Agro Ventures',
      'owner': 'Keerthi M',
      'mobile': '9952422147',
      'role': 'Agri Input Dealer',
      'location': 'Coimbatore, Tamil Nadu',
      'gst': 'Verified GST',
      'whatsapp': 'WhatsApp active',
      'license': 'License current',
    };

    return ListView(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 28, 8, compact ? 16 : 28, 28),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _heroSection(
                sampleCard,
                compact: compact,
                veryCompact: veryCompact,
              ),
              const SizedBox(height: 28),
              _editorialBand(compact: compact),
              const SizedBox(height: 20),
              _operationsSection(compact: compact),
              const SizedBox(height: 20),
              _showcaseSection(
                sampleCard,
                compact: compact,
                veryCompact: veryCompact,
              ),
              const SizedBox(height: 20),
              _finalCta(compact: compact, veryCompact: veryCompact),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heroSection(
    Map<String, String> card, {
    required bool compact,
    required bool veryCompact,
  }) {
    final theme = Theme.of(context);
    final headlineStyle = theme.textTheme.displayMedium?.copyWith(
      fontFamily: 'Georgia',
      fontWeight: FontWeight.w700,
      height: 0.95,
      letterSpacing: -1.6,
      fontSize: compact ? 48 : 78,
      color: theme.colorScheme.onSurface,
    );

    final body = compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _heroCopy(headlineStyle),
              const SizedBox(height: 24),
              _heroPreview(
                card,
                compact: compact,
                veryCompact: veryCompact,
              ),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 12, child: _heroCopy(headlineStyle)),
              const SizedBox(width: 28),
              Expanded(
                flex: 10,
                child: _heroPreview(
                  card,
                  compact: compact,
                  veryCompact: veryCompact,
                ),
              ),
            ],
          );

    return Container(
      padding: EdgeInsets.fromLTRB(
        veryCompact ? 18 : (compact ? 22 : 38),
        veryCompact ? 20 : (compact ? 24 : 34),
        veryCompact ? 18 : (compact ? 22 : 38),
        veryCompact ? 20 : (compact ? 24 : 30),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(veryCompact ? 24 : (compact ? 28 : 40)),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.82),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _eyebrow('Verified identity for agri business'),
          const SizedBox(height: 14),
          body,
        ],
      ),
    );
  }

  Widget _heroCopy(TextStyle? headlineStyle) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 28 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The public face of modern agricultural commerce.',
            style: headlineStyle,
          ),
          const SizedBox(height: 10),
          Text(
            'Farmers,\nagri-specialists',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
              height: 1.25,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(
              'Cropz Card turns dealer, distributor, and field-team identity into a clean link that feels credible at first glance and remains useful in daily operations.',
              style: theme.textTheme.titleMedium?.copyWith(
                height: 1.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.76),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: _openInApp,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 18,
                  ),
                  backgroundColor: const Color(0xFF1A7A5C),
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(Icons.arrow_outward_rounded),
                label: const Text('Open in Cropz Card'),
              ),
              OutlinedButton(
                onPressed: () => _navigateTo('/about'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 18,
                  ),
                  side: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.28),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('About the platform'),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _MetricPill(value: '10s', label: 'to share a verified link'),
              _MetricPill(value: '1', label: 'profile for field trust'),
              _MetricPill(value: '24/7', label: 'public availability'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroPreview(
    Map<String, String> card, {
    required bool compact,
    required bool veryCompact,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final panelGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0C1713), Color(0xFF10221B), Color(0xFF163129)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5F0E3), Color(0xFFEAE1C9), Color(0xFFF0E7D6)],
          );
    final panelBorder = isDark ? const Color(0xFF304338) : const Color(0xFFD3C8AF);
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.38)
        : const Color(0xFFB9A98C).withValues(alpha: 0.16);
    final accent = isDark ? const Color(0xFF74E0AE) : const Color(0xFF1C936B);
    final accentBorder = isDark ? const Color(0xFF2E6C53) : const Color(0xFF0D5F44);
    final titleColor = isDark ? const Color(0xFFF4F7F5) : Colors.black;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.72)
        : Colors.black.withValues(alpha: 0.78);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(38 * (1 - value), 0),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
          padding: EdgeInsets.all(veryCompact ? 18 : 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(veryCompact ? 24 : 30),
            gradient: panelGradient,
            border: Border.all(color: panelBorder, width: 1.1),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: veryCompact ? 44 : 52,
                      height: veryCompact ? 44 : 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(veryCompact ? 16 : 18),
                        color: accent,
                        border: Border.all(color: accentBorder, width: 1),
                      ),
                      child: const Icon(Icons.eco_rounded, color: Colors.white),
                    ),
                    SizedBox(width: veryCompact ? 12 : 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card['firm']!,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: veryCompact ? 22 : 26,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            card['location']!,
                            style: TextStyle(
                              color: subtitleColor,
                              fontWeight: FontWeight.w500,
                              fontSize: veryCompact ? 12.5 : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _darkTag(card['role']!),
                    _darkTag(card['gst']!),
                    _darkTag(card['license']!),
                  ],
                ),
                const SizedBox(height: 22),
                _PreviewLine(label: 'Owner', value: card['owner']!),
                _PreviewLine(label: 'Contact', value: card['mobile']!),
                _PreviewLine(label: 'Signal', value: card['whatsapp']!),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Editorial presentation outside, operational detail inside. That is the bar for the full web surface.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editorialBand({required bool compact}) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 18 : 28,
        vertical: compact ? 20 : 24,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.16),
          ),
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.16),
          ),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 18,
        spacing: 24,
        children: const [
          _StatementBlock(
            title: 'Trusted first glance',
            body:
                'Replace screenshot-heavy sharing with a profile that reads like a real business surface.',
          ),
          _StatementBlock(
            title: 'Built for field speed',
            body:
                'Open, verify, call, and continue the conversation without forcing app installation first.',
          ),
          _StatementBlock(
            title: 'Structured depth',
            body:
                'Licenses, bank details, business identity, and address remain organized when the viewer needs more.',
          ),
        ],
      ),
    );
  }

  Widget _operationsSection({required bool compact}) {
    final theme = Theme.of(context);
    final content = [
      const _ProcessStep(
        index: '01',
        title: 'Publish identity',
        body:
            'A professional card is created once with the same business fields already captured in the app.',
      ),
      const _ProcessStep(
        index: '02',
        title: 'Share a clean link',
        body:
            'Anyone opening the card gets a polished view first instead of a raw data dump or form-like preview.',
      ),
      const _ProcessStep(
        index: '03',
        title: 'Move to action',
        body:
            'The viewer can escalate into the app, contact the owner, or validate operational details without friction.',
      ),
    ];

    return Container(
      padding: EdgeInsets.all(compact ? 20 : 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: theme.colorScheme.surface.withValues(alpha: 0.92),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.82),
        ),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeading(
                  title: 'How the surface should behave',
                  body:
                      'Take cues from product sites that feel composed, calm, and obvious in their hierarchy.',
                ),
                const SizedBox(height: 18),
                ...content
                    .expand((widget) => [widget, const SizedBox(height: 18)])
                    .toList()
                  ..removeLast(),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 7,
                  child: _sectionHeading(
                    title: 'How the surface should behave',
                    body:
                        'Take cues from product sites that feel composed, calm, and obvious in their hierarchy.',
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 13,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var index = 0; index < content.length; index++) ...[
                        Expanded(child: content[index]),
                        if (index != content.length - 1)
                          VerticalDivider(
                            width: 28,
                            thickness: 1,
                            color: theme.colorScheme.outline.withValues(
                              alpha: 0.14,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _showcaseSection(
    Map<String, String> card, {
    required bool compact,
    required bool veryCompact,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final preview = Container(
      padding: EdgeInsets.all(veryCompact ? 18 : 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: isDark
            ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.88)
            : const Color(0xFFF1E8D9),
        border: Border.all(
          color: isDark
              ? theme.colorScheme.outline.withValues(alpha: 0.78)
              : const Color(0xFFCCBFA6),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Card preview language',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          _PreviewLine(label: 'Firm', value: card['firm']!),
          _PreviewLine(label: 'Owner', value: card['owner']!),
          _PreviewLine(label: 'Mobile', value: card['mobile']!),
          _PreviewLine(label: 'Role', value: card['role']!),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _darkTag('High-trust header'),
              _darkTag('Readable metadata'),
              _darkTag('Fast scanning'),
            ],
          ),
        ],
      ),
    );

    final notes = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(
          title: 'Design stance',
          body:
              'This version moves away from demo-box UI and toward a premium public-facing product surface.',
        ),
        const SizedBox(height: 16),
        const _NoteRow(
          title: 'Brand-first hero',
          body:
              'The first viewport now works like a poster with one dominant message and one live preview anchor.',
        ),
        const SizedBox(height: 12),
        const _NoteRow(
          title: 'Reduced chrome',
          body:
              'Sections rely on spacing, contrast, and editorial layout before borders and cards.',
        ),
        const SizedBox(height: 12),
        const _NoteRow(
          title: 'Clear product motion',
          body:
              'The page uses subtle entry transitions and animated atmospheric movement instead of decorative noise.',
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.all(compact ? 20 : 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: theme.colorScheme.surface.withValues(alpha: 0.7),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.78),
        ),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [notes, const SizedBox(height: 18), preview],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 9, child: notes),
                const SizedBox(width: 24),
                Expanded(flex: 8, child: preview),
              ],
            ),
    );
  }

  Widget _finalCta({
    required bool compact,
    required bool veryCompact,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF153C31), Color(0xFF0F2D25)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A7A5C), Color(0xFF145743)],
          );
    return Container(
        padding: EdgeInsets.symmetric(
          horizontal: veryCompact ? 18 : (compact ? 20 : 30),
          vertical: veryCompact ? 22 : (compact ? 24 : 28),
        ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: background,
        border: Border.all(
          color: isDark ? const Color(0xFF396C5A) : const Color(0xFF0F4E39),
          width: 1.2,
        ),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_ctaCopy(), const SizedBox(height: 18), _ctaActions()],
            )
          : Row(
              children: [
                Expanded(child: _ctaCopy()),
                const SizedBox(width: 24),
                _ctaActions(),
              ],
            ),
    );
  }

  Widget _ctaCopy() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final headlineColor = isDark ? const Color(0xFFF5FAF7) : Colors.white;
    final bodyColor = isDark
        ? Colors.white.withValues(alpha: 0.82)
        : const Color(0xD9FFFFFF);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'A stronger first impression is now the default surface.',
          style: TextStyle(
            color: headlineColor,
            fontSize: 28,
            height: 1.1,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Use the same web address, keep the current card flow, and present it with the polish expected from a modern product company.',
          style: TextStyle(
            color: bodyColor,
            fontSize: 15.5,
            height: 1.55,
          ),
        ),
      ],
    );
  }

  Widget _ctaActions() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        FilledButton(
          onPressed: _openInApp,
          style: FilledButton.styleFrom(
            backgroundColor:
                isDark ? theme.colorScheme.surface : const Color(0xFFF8F4EC),
            foregroundColor:
                isDark ? theme.colorScheme.onSurface : const Color(0xFF153E39),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
          child: const Text('Launch app link'),
        ),
        OutlinedButton(
          onPressed: () => _navigateTo('/about'),
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? Colors.white : Colors.white,
            side: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.72)
                  : const Color(0xE6FFFFFF),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
          child: const Text('Read about Cropz Card'),
        ),
      ],
    );
  }

  Widget _buildAboutPage({
    required bool compact,
    required bool veryCompact,
  }) {
    return ListView(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 28, 8, compact ? 16 : 28, 28),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Container(
            padding: EdgeInsets.all(veryCompact ? 18 : (compact ? 22 : 34)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.78),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.14),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _eyebrow('About the platform'),
                const SizedBox(height: 14),
                Text(
                  'Cropz Card is designed for business identity in the agriculture ecosystem.',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Text(
                    'It gives dealers, field agents, distributors, and agri-business operators one public page that can be shared quickly, scanned easily, and trusted immediately.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      height: 1.55,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.78),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                compact
                    ? Column(
                        children: const [
                          _AboutBlock(
                            title: 'Why it exists',
                            body:
                                'Agricultural commerce still depends on repeated calls, forwarded screenshots, and informal trust signals. Cropz Card creates one reliable surface for those first interactions.',
                          ),
                          SizedBox(height: 18),
                          _AboutBlock(
                            title: 'What it carries',
                            body:
                                'The platform organizes profile data, business details, licenses, bank information, and address references into a structure that remains useful in real operations.',
                          ),
                          SizedBox(height: 18),
                          _AboutBlock(
                            title: 'How it should feel',
                            body:
                                'The web experience should feel contemporary and assured, closer to a premium product site than a utilitarian form preview.',
                          ),
                        ],
                      )
                    : const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _AboutBlock(
                              title: 'Why it exists',
                              body:
                                  'Agricultural commerce still depends on repeated calls, forwarded screenshots, and informal trust signals. Cropz Card creates one reliable surface for those first interactions.',
                            ),
                          ),
                          SizedBox(width: 18),
                          Expanded(
                            child: _AboutBlock(
                              title: 'What it carries',
                              body:
                                  'The platform organizes profile data, business details, licenses, bank information, and address references into a structure that remains useful in real operations.',
                            ),
                          ),
                          SizedBox(width: 18),
                          Expanded(
                            child: _AboutBlock(
                              title: 'How it should feel',
                              body:
                                  'The web experience should feel contemporary and assured, closer to a premium product site than a utilitarian form preview.',
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewContent({
    required Map<String, dynamic> profile,
    required Map<String, dynamic> digital,
    required Map<String, dynamic> business,
    required Map<String, dynamic> license,
    required List<Map<String, dynamic>> banks,
    required Map<String, dynamic> address,
    required List<Map<String, dynamic>> documents,
    required bool compact,
    required bool veryCompact,
  }) {
    final sections = [
      _DataPanel(title: 'Digital card', data: digital),
      _DataPanel(title: 'Business', data: business),
      _DataPanel(title: 'License info', data: license),
      _DocumentPanel(documents: documents),
      _DataPanel(title: 'Address', data: address),
    ];

    return ListView(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 28, 8, compact ? 16 : 28, 28),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1220),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final panelWidth = compact
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 16) / 2;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _previewHero(
                    profile,
                    compact: compact,
                    veryCompact: veryCompact,
                  ),
                  const SizedBox(height: 20),
                  compact
                      ? Column(
                          children: [
                            for (final section in sections) ...[
                              section,
                              const SizedBox(height: 14),
                            ],
                            _BankPanel(banks: banks),
                          ],
                        )
                      : Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            for (final section in sections)
                              SizedBox(width: panelWidth, child: section),
                            SizedBox(
                              width: panelWidth,
                              child: _BankPanel(banks: banks),
                            ),
                          ],
                        ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _previewHero(
    Map<String, dynamic> profile, {
    required bool compact,
    required bool veryCompact,
  }) {
    final displayName = (profile['name'] ?? 'Unknown').toString();
    final role = (profile['role'] ?? 'Business Profile').toString();
    final phone = (profile['phone'] ?? '').toString();
    final email = (profile['email'] ?? '').toString();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final summary = Container(
      padding: EdgeInsets.all(veryCompact ? 18 : (compact ? 20 : 28)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(veryCompact ? 24 : 30),
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0C1713), Color(0xFF10221B), Color(0xFF17372F)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF102017), Color(0xFF153727), Color(0xFF173D5A)],
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: veryCompact ? 60 : (compact ? 68 : 86),
            height: veryCompact ? 60 : (compact ? 68 : 86),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(veryCompact ? 20 : 24),
              gradient: isDark
                  ? const LinearGradient(
                      colors: [Color(0xFF39DA9B), Color(0xFF8DD5FF)],
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF2AD28D), Color(0xFF87C1FF)],
                    ),
            ),
            alignment: Alignment.center,
            child: Text(
              displayName.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontSize: veryCompact ? 24 : (compact ? 28 : 34),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: veryCompact ? 12 : (compact ? 16 : 20)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _eyebrow(
                  'Public card preview',
                  color: isDark ? const Color(0xFFBDE9D3) : const Color(0xFFD4EBDD),
                ),
                const SizedBox(height: 10),
                Text(
                  displayName,
                  style: TextStyle(
                    color: isDark ? const Color(0xFFF4FAF7) : Colors.white,
                    fontSize: veryCompact ? 25 : (compact ? 30 : 42),
                    height: 1.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  role,
                  style: TextStyle(
                    color: (isDark ? Colors.white : Colors.white).withValues(
                      alpha: 0.74,
                    ),
                    fontSize: veryCompact ? 14 : (compact ? 15.5 : 17),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                if (phone.isNotEmpty) ...[
                  _PhoneCopyWidget(
                    phone: phone,
                    onCopy: () => _copyPhone(phone),
                  ),
                  const SizedBox(height: 10),
                ],
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (email.isNotEmpty) _darkTag(email),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return summary;
  }

  Widget _buildErrorState(String error) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: theme.colorScheme.surface.withValues(alpha: 0.88),
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Unable to load card',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                error,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _eyebrow(String text, {Color? color}) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        letterSpacing: 1.4,
        fontWeight: FontWeight.w700,
        fontSize: 12,
        color: color ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _sectionHeading({required String title, required String body}) {
    final theme = Theme.of(context);
    return Column(
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
      ],
    );
  }

  Widget _darkTag(String text) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return _GlossyInteractive(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: isDark
              ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.9)
              : const Color(0xFFF4EBDD),
          border: Border.all(
            color: isDark
                ? theme.colorScheme.outline.withValues(alpha: 0.78)
                : const Color(0xFFCBBFA7),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isDark ? theme.colorScheme.onSurface : Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }

}

class _PhoneCopyWidget extends StatelessWidget {
  const _PhoneCopyWidget({required this.phone, required this.onCopy});

  final String phone;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        InkWell(
          onTap: onCopy,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: isDark
                  ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.92)
                  : Colors.white.withValues(alpha: 0.08),
              border: Border.all(
                color: isDark
                    ? theme.colorScheme.outline.withValues(alpha: 0.72)
                    : Colors.white.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.phone_rounded,
                  size: 16,
                  color: isDark ? theme.colorScheme.onSurface : Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  phone,
                  style: TextStyle(
                    color: isDark ? theme.colorScheme.onSurface : Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        FilledButton.tonalIcon(
          onPressed: onCopy,
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: const Text('Copy number'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _GlossyInteractive extends StatefulWidget {
  const _GlossyInteractive({required this.child, required this.borderRadius});

  final Widget child;
  final BorderRadius borderRadius;

  @override
  State<_GlossyInteractive> createState() => _GlossyInteractiveState();
}

class _GlossyInteractiveState extends State<_GlossyInteractive> {
  bool _hovering = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = _hovering || _pressed;
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() {
        _hovering = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.975 : (active ? 1.015 : 1),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: active ? 0.9 : 0.72),
                  theme.colorScheme.primary.withValues(
                    alpha: active ? 0.12 : 0.04,
                  ),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: active ? 0.14 : 0.08),
                  blurRadius: active ? 20 : 12,
                  offset: Offset(0, active ? 10 : 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 1,
                  top: 1,
                  right: 1,
                  height: 16,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: widget.borderRadius,
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: active ? 0.74 : 0.52),
                          Colors.white.withValues(alpha: 0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                widget.child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.compact,
    required this.veryCompact,
    required this.currentMode,
    required this.onHome,
    required this.onAbout,
    required this.onHelp,
    required this.onPrivacy,
    required this.onOpenApp,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final bool compact;
  final bool veryCompact;
  final _PageMode currentMode;
  final VoidCallback onHome;
  final VoidCallback onAbout;
  final VoidCallback onHelp;
  final VoidCallback onPrivacy;
  final VoidCallback onOpenApp;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeLabel = switch (themeMode) {
      ThemeMode.system => 'Light',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };
    final themeIcon = switch (themeMode) {
      ThemeMode.system => Icons.light_mode_rounded,
      ThemeMode.light => Icons.light_mode_rounded,
      ThemeMode.dark => Icons.dark_mode_rounded,
    };
    final themeToggle = FilledButton.tonalIcon(
      onPressed: () {
        onThemeModeChanged(
          switch (themeMode) {
            ThemeMode.system => ThemeMode.dark,
            ThemeMode.light => ThemeMode.dark,
            ThemeMode.dark => ThemeMode.light,
          },
        );
      },
      icon: Icon(themeIcon, size: compact ? 18 : 20),
      label: Text(themeLabel),
      style: FilledButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: veryCompact ? 10 : (compact ? 12 : 14),
          vertical: compact ? 14 : 16,
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );

    final appButton = FilledButton(
      onPressed: onOpenApp,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF1A7A5C),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 18,
          vertical: compact ? 14 : 16,
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      child: Text(compact ? 'Open App' : 'Open in App'),
    );

    Widget navButtons() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          appButton,
          const SizedBox(width: 8),
          themeToggle,
          if (compact) ...[
            const SizedBox(width: 6),
            PopupMenuButton<String>(
              tooltip: 'Menu',
              onSelected: (value) {
                if (value == 'home') {
                  onHome();
                } else if (value == 'about') {
                  onAbout();
                } else if (value == 'help') {
                  onHelp();
                } else if (value == 'privacy') {
                  onPrivacy();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'home', child: Text('Home')),
                PopupMenuItem(value: 'about', child: Text('About')),
                PopupMenuItem(value: 'help', child: Text('Help')),
                PopupMenuItem(value: 'privacy', child: Text('Privacy')),
              ],
            ),
          ],
        ],
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 18,
        vertical: compact ? 12 : 14,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact && veryCompact ? 28 : 999),
        color: theme.colorScheme.surface.withValues(alpha: 0.94),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.85),
        ),
      ),
      child: veryCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: onHome,
                  borderRadius: BorderRadius.circular(999),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _LogoBadge(),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cropz Card',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Verified agricultural identity',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.62,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                navButtons(),
              ],
            )
          : Row(
              children: [
                InkWell(
                  onTap: onHome,
                  borderRadius: BorderRadius.circular(999),
                  child: Row(
                    children: [
                      const _LogoBadge(),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cropz Card',
                            style: TextStyle(
                              fontSize: compact ? 18 : 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Verified agricultural identity',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.62,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (!compact) ...[
                  _NavLink(
                    label: 'Home',
                    selected: currentMode == _PageMode.home,
                    onTap: onHome,
                  ),
                  const SizedBox(width: 8),
                  _NavLink(
                    label: 'About',
                    selected: currentMode == _PageMode.about,
                    onTap: onAbout,
                  ),
                  const SizedBox(width: 8),
                  _NavLink(
                    label: 'Help',
                    selected: currentMode == _PageMode.help,
                    onTap: onHelp,
                  ),
                  const SizedBox(width: 8),
                  _NavLink(
                    label: 'Privacy',
                    selected: currentMode == _PageMode.privacy,
                    onTap: onPrivacy,
                  ),
                  const SizedBox(width: 10),
                ],
                navButtons(),
              ],
            ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: selected
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onSurface.withValues(alpha: 0.66),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _GlossyInteractive(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.92),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.85),
          ),
        ),
        child: RichText(
          text: TextSpan(
            style: theme.textTheme.bodyMedium,
            children: [
              TextSpan(
                text: '$value  ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              TextSpan(
                text: label,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatementBlock extends StatelessWidget {
  const _StatementBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.55,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcessStep extends StatelessWidget {
  const _ProcessStep({
    required this.index,
    required this.title,
    required this.body,
  });

  final String index;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          index,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          body,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.6,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
          ),
        ),
      ],
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 7),
          decoration: const BoxDecoration(
            color: Color(0xFF1A7A5C),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
              children: [
                TextSpan(
                  text: '$title. ',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                TextSpan(
                  text: body,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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

class _AboutBlock extends StatelessWidget {
  const _AboutBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.82),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.75),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.6,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _DataPanel extends StatelessWidget {
  const _DataPanel({required this.title, required this.data});

  final String title;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final visibleEntries = data.entries
        .where((entry) {
          final value = entry.value;
          if (value == null) {
            return false;
          }
          final text = value.toString().trim();
          return text.isNotEmpty && text.toLowerCase() != 'null';
        })
        .toList(growable: false);

    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: theme.colorScheme.surface.withValues(alpha: 0.94),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.85),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          if (visibleEntries.isEmpty)
            Text(
              'No data entered',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            )
          else
            ...visibleEntries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _labelize(entry.key),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.58,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '${entry.value}',
                        textAlign: TextAlign.right,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DocumentPanel extends StatelessWidget {
  const _DocumentPanel({required this.documents});

  final List<Map<String, dynamic>> documents;

  @override
  Widget build(BuildContext context) {
    final populatedDocuments = documents
        .where((doc) {
          final label = (doc['label'] ?? '').toString().trim();
          final fileName = (doc['fileName'] ?? '').toString().trim();
          final downloadUrl = (doc['downloadUrl'] ?? '').toString().trim();
          return label.isNotEmpty &&
              fileName.isNotEmpty &&
              downloadUrl.isNotEmpty;
        })
        .toList(growable: false);

    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: theme.colorScheme.surface.withValues(alpha: 0.94),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.85),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Documents',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          if (populatedDocuments.isEmpty)
            Text(
              'No data entered',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            )
          else
            ...populatedDocuments.map((document) {
              final label = (document['label'] ?? '').toString();
              final fileName = (document['fileName'] ?? '').toString();
              final downloadUrl = (document['downloadUrl'] ?? '').toString();
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: theme.colorScheme.surfaceContainer.withValues(
                    alpha: 0.8,
                  ),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.7),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fileName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.72,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.tonalIcon(
                      onPressed: () => web_bridge.openExternalUrl(downloadUrl),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open'),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _BankPanel extends StatelessWidget {
  const _BankPanel({required this.banks});

  final List<Map<String, dynamic>> banks;

  @override
  Widget build(BuildContext context) {
    final populatedBanks = banks.where(_hasMapData).toList(growable: false);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: theme.colorScheme.surface.withValues(alpha: 0.74),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bank accounts',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          if (populatedBanks.isEmpty)
            Text(
              'No data entered',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            )
          else
            ...populatedBanks.map((bank) {
              final visibleEntries = bank.entries
                  .where((entry) {
                    final value = entry.value;
                    if (value == null) {
                      return false;
                    }
                    final text = value.toString().trim();
                    return text.isNotEmpty && text.toLowerCase() != 'null';
                  })
                  .toList(growable: false);
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: theme.colorScheme.surfaceContainer.withValues(
                    alpha: 0.8,
                  ),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.7),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: visibleEntries
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  _labelize(entry.key),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.58),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  '${entry.value}',
                                  textAlign: TextAlign.right,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark ? const Color(0xFF2EA97C) : const Color(0xFF1C936B),
        border: Border.all(
          color: isDark ? const Color(0xFF7EE0B4) : const Color(0xFF0D5F44),
          width: 1.2,
        ),
      ),
      child: const Icon(Icons.eco_rounded, color: Colors.white),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  _BackgroundPainter(this.t, {required this.brightness});

  final double t;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final dark = brightness == Brightness.dark;
    final base = Paint()
      ..color = dark ? const Color(0xFF09130F) : const Color(0xFFF8F4EC);
    canvas.drawRect(Offset.zero & size, base);

    final paintA = Paint()
      ..color = (dark ? const Color(0xFF244537) : const Color(0xFFDCE9DE))
          .withValues(alpha: dark ? 0.22 : 0.36)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 46);
    final paintB = Paint()
      ..color = (dark ? const Color(0xFF213B33) : const Color(0xFFE8DDCA))
          .withValues(alpha: dark ? 0.18 : 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 58);
    final paintC = Paint()
      ..color = (dark ? const Color(0xFF1A2F29) : const Color(0xFFCFE0D5))
          .withValues(alpha: dark ? 0.16 : 0.24)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 48);

    canvas.drawCircle(
      Offset(size.width * (0.16 + 0.06 * math.cos(t)), size.height * 0.14),
      180,
      paintA,
    );
    canvas.drawCircle(
      Offset(
        size.width * (0.84 + 0.05 * math.sin(t * 1.2)),
        size.height * 0.22,
      ),
      220,
      paintB,
    );
    canvas.drawCircle(
      Offset(
        size.width * (0.62 + 0.07 * math.cos(t * 0.8)),
        size.height * 0.82,
      ),
      200,
      paintC,
    );
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) {
    return oldDelegate.t != t;
  }
}

String _labelize(String key) {
  final out = key
      .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
      .trim();
  return out.isEmpty ? key : out[0].toUpperCase() + out.substring(1);
}

bool _hasMapData(Map<String, dynamic> data) {
  for (final value in data.values) {
    if (value == null) {
      continue;
    }
    final text = value.toString().trim();
    if (text.isNotEmpty && text.toLowerCase() != 'null') {
      return true;
    }
  }
  return false;
}
