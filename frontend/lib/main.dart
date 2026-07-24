import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'pages/help_page.dart';
import 'pages/privacy_policy_page.dart';
import 'web_bridge_stub.dart'
    if (dart.library.html) 'web_bridge_web.dart'
    as web_bridge;

void main() {
  usePathUrlStrategy();
  runApp(const CropzWebApp());
}

class CropzWebApp extends StatelessWidget {
  const CropzWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF194F32); // New agricultural green from landing page
    final lightScheme =
        ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ).copyWith(
          surface: const Color(0xFFF4F7F3), // Cream background
          surfaceContainer: const Color(0xFFE8F1EC),
          surfaceContainerHighest: const Color(0xFFDCE6DD),
          outline: const Color(0xFFDCE6DD), // Line color
          primary: const Color(0xFF194F32), // Primary green
          secondary: const Color(0xFF2D7A48), // Medium green
        );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cropz Card',
      theme: ThemeData(
        colorScheme: lightScheme,
        scaffoldBackgroundColor: const Color(0xFFF4F7F3),
        useMaterial3: true,
        textTheme: Typography.material2021().black,
        dividerTheme: const DividerThemeData(
          color: Color(0xFFDCE6DD),
          thickness: 1,
        ),
      ),
      home: const PreviewPage(),
    );
  }
}

enum _PageMode { home, help, privacy, preview }

class PreviewPage extends StatefulWidget {
  const PreviewPage({super.key});

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage>
    with SingleTickerProviderStateMixin {
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=in.cropz.cropz_app';
  Future<Map<String, dynamic>>? _future;
  String? _cardId;
  late _PreviewFilters _filters;
  late _PageMode _mode;
  late AnimationController _bgController;
  StreamSubscription<void>? _navigationSub;
  final ScrollController _homeScrollController = ScrollController();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _howKey = GlobalKey();
  final GlobalKey _contactKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _applyUri(kIsWeb ? Uri.base : Uri(path: '/'));

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _navigationSub = web_bridge.watchNavigation(() {
      if (!mounted) {
        return;
      }
      setState(() {
        _applyUri(Uri.base);
      });
    });
  }

  @override
  void dispose() {
    _navigationSub?.cancel();
    _bgController.dispose();
    _homeScrollController.dispose();
    super.dispose();
  }

  void _applyUri(Uri uri) {
    final path = uri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList();
    _cardId = null;
    _future = null;
    if (path.isEmpty) {
      _mode = _PageMode.home;
    } else if (path.first.toLowerCase() == 'help') {
      _mode = _PageMode.help;
    } else if (path.first.toLowerCase() == 'privacy') {
      _mode = _PageMode.privacy;
    } else {
      _mode = _PageMode.preview;
      _cardId = path.first;
      _future = _fetchCard(_cardId!);
    }
    _filters = _PreviewFilters.fromUri(uri);
  }

  Future<Map<String, dynamic>> _fetchCard(String cardId) async {
    final apiBase = const String.fromEnvironment('API_BASE');
    final uri = apiBase.isEmpty
        ? Uri.base.resolve('/api/cards/$cardId')
        : Uri.parse(apiBase).resolve('/api/cards/$cardId');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Could not load card: ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> _openInApp() async {
    final deepLink = _mode == _PageMode.help
        ? 'cropzcard://help'
        : _cardId == null
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
      web_bridge.openExternalUrl(_playStoreUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cropz Card is not installed. Opening Google Play.'),
        ),
      );
    }
  }

  Future<void> _copyPhone(String phone) async {
    final copied = await web_bridge.copyText(phone);
    if (!copied || !mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Phone number copied')));
  }

  void _navigateTo(String path) {
    web_bridge.navigateTo(path);
    setState(() {
      _applyUri(Uri.parse(path));
    });
  }

  void _navigateHomeAndScroll(GlobalKey sectionKey) {
    if (_mode != _PageMode.home) {
      web_bridge.navigateTo('/');
      setState(() {
        _applyUri(Uri.parse('/'));
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sectionContext = sectionKey.currentContext;
      if (sectionContext == null) {
        return;
      }
      Scrollable.ensureVisible(
        sectionContext,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        alignment: 0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 900;
    final veryCompact = width < 600;

    return Scaffold(
      body: Stack(
        children: [
          if (_mode == _PageMode.preview)
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
            )
          else
            const ColoredBox(color: Colors.white),
          SafeArea(
            child: Column(
              children: [
                _TopBar(
                  compact: compact,
                  veryCompact: veryCompact,
                  currentMode: _mode,
                  onHome: () => _navigateTo('/'),
                  onHelp: () => _navigateTo('/help'),
                  onPrivacy: () => _navigateTo('/privacy'),
                  onOpenApp: () => _launchUrl(_playStoreUrl),
                ),
                Expanded(
                  child: switch (_mode) {
                    _PageMode.home => _buildHomePage(
                      compact: compact,
                      veryCompact: veryCompact,
                    ),
                    _PageMode.help => HelpPage(
                      compact: compact,
                      veryCompact: veryCompact,
                      onHome: () => _navigateTo('/'),
                      onPrivacy: () => _navigateTo('/privacy'),
                      onOpenApp: _openInApp,
                    ),
                    _PageMode.privacy => PrivacyPolicyPage(
                      compact: compact,
                      veryCompact: veryCompact,
                      onHome: () => _navigateTo('/'),
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
                        final addresses =
                            ((data['addresses'] as List?) ?? const <dynamic>[])
                                .map(
                                  (entry) =>
                                      (entry as Map).cast<String, dynamic>(),
                                )
                                .toList();
                        final visibleAddresses = addresses.isNotEmpty
                            ? addresses
                            : (address.isEmpty
                                  ? const <Map<String, dynamic>>[]
                                  : [address]);
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
                          addresses: visibleAddresses,
                          documents: documents,
                          filters: _filters,
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

  Widget _buildHomePage({required bool compact, required bool veryCompact}) {
    return ListView(
      controller: _homeScrollController,
      padding: EdgeInsets.zero,
      children: [
        _landingHero(compact: compact, veryCompact: veryCompact),
        KeyedSubtree(
          key: _featuresKey,
          child: _landingFeatures(compact: compact),
        ),
        KeyedSubtree(
          key: _howKey,
          child: _landingHowItWorks(compact: compact),
        ),
        _landingCta(compact: compact),
        KeyedSubtree(
          key: _contactKey,
          child: _landingFooter(compact: compact),
        ),
      ],
    );
  }

  Widget _landingHero({required bool compact, required bool veryCompact}) {
    return Container(
      constraints: BoxConstraints(minHeight: compact ? 0 : 720),
      padding: EdgeInsets.symmetric(
        vertical: veryCompact ? 48 : (compact ? 60 : 76),
        horizontal: veryCompact ? 14 : 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF7FAF6), Colors.white],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1140),
          child: compact
              ? Column(
                  crossAxisAlignment: veryCompact
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    _landingHeroCopy(
                      compact: compact,
                      veryCompact: veryCompact,
                    ),
                    SizedBox(height: veryCompact ? 46 : 42),
                    _heroVisual(compact: compact, veryCompact: veryCompact),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 104,
                      child: _landingHeroCopy(
                        compact: compact,
                        veryCompact: veryCompact,
                      ),
                    ),
                    const SizedBox(width: 58),
                    Expanded(
                      flex: 96,
                      child: _heroVisual(
                        compact: compact,
                        veryCompact: veryCompact,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _landingHeroCopy({required bool compact, required bool veryCompact}) {
    final align = veryCompact
        ? CrossAxisAlignment.start
        : (compact ? CrossAxisAlignment.center : CrossAxisAlignment.start);
    return Column(
      crossAxisAlignment: align,
      children: [
        const _LandingEyebrow(text: 'Made for agricultural product dealers'),
        SizedBox(height: veryCompact ? 0 : 2),
        Text(
          'Your professional agri business card, always ready to share.',
          style: TextStyle(
            fontSize: veryCompact ? 46 : (compact ? 54 : 76),
            fontWeight: FontWeight.w800,
            height: 0.99,
            letterSpacing: veryCompact ? -2.6 : -4,
            color: const Color(0xFF13251A),
          ),
          textAlign: compact && !veryCompact
              ? TextAlign.center
              : TextAlign.left,
        ),
        const SizedBox(height: 25),
        Text(
          'Create a digital business card in seconds, showcase your professional identity, and help farmers and customers save your details instantly.',
          style: TextStyle(
            fontSize: veryCompact ? 17 : 18.5,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF617066),
            height: 1.6,
          ),
          textAlign: compact && !veryCompact
              ? TextAlign.center
              : TextAlign.left,
        ),
        const SizedBox(height: 30),
        Wrap(
          spacing: 22,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: compact && !veryCompact
              ? WrapAlignment.center
              : WrapAlignment.start,
          children: [
            FilledButton(
              onPressed: () => _launchUrl(_playStoreUrl),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF194F32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _GooglePlayMark(),
                    SizedBox(width: 10),
                    Text('Download on Google Play'),
                  ],
                ),
              ),
            ),
            TextButton(
              onPressed: () => _navigateHomeAndScroll(_featuresKey),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2D7A48),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Explore features'),
                  SizedBox(width: 4),
                  Text('→'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 22,
          runSpacing: 12,
          alignment: compact && !veryCompact
              ? WrapAlignment.center
              : WrapAlignment.start,
          children: const [
            _TrustIndicator(text: 'Easy to create'),
            _TrustIndicator(text: 'QR-enabled'),
            _TrustIndicator(text: 'Easy to share'),
          ],
        ),
      ],
    );
  }

  Widget _heroVisual({required bool compact, required bool veryCompact}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          left: compact ? 30 : 70,
          top: 40,
          right: compact ? 10 : -40,
          bottom: -20,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF83C341).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(240),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF83C341).withValues(alpha: 0.16),
                  blurRadius: 60,
                  spreadRadius: 15,
                ),
              ],
            ),
          ),
        ),
        Transform.rotate(
          angle: veryCompact ? 0 : 0.021,
          child: _GlossyInteractive(
            borderRadius: BorderRadius.circular(veryCompact ? 20 : 30),
            hoverScale: 1.012,
            shadowColor: const Color(0xFF0D341F),
            child: Container(
              constraints: BoxConstraints(maxWidth: compact ? 430 : 480),
              padding: EdgeInsets.all(veryCompact ? 5 : 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(veryCompact ? 20 : 30),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(veryCompact ? 15 : 22),
                child: Image.asset(
                  'assets/images/cropzcard-poster.png',
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Retained temporarily for compatibility with older preview layouts.
  // ignore: unused_element
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
              _heroPreview(card, compact: compact, veryCompact: veryCompact),
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
        borderRadius: BorderRadius.circular(
          veryCompact ? 24 : (compact ? 28 : 40),
        ),
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
          _eyebrow('Verified identity for agricultural businesses'),
          const SizedBox(height: 14),
          body,
        ],
      ),
    );
  }

  Widget _heroCopy(TextStyle? headlineStyle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Professional identity for agricultural businesses.',
          style: headlineStyle,
        ),
        const SizedBox(height: 18),
        const Text(
          'Create one trusted card, share a clean link, and keep important business details easy to find.',
        ),
      ],
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
    final panelBorder = isDark
        ? const Color(0xFF304338)
        : const Color(0xFFD3C8AF);
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.38)
        : const Color(0xFFB9A98C).withValues(alpha: 0.16);
    final accent = isDark ? const Color(0xFF74E0AE) : const Color(0xFF1C936B);
    final accentBorder = isDark
        ? const Color(0xFF2E6C53)
        : const Color(0xFF0D5F44);
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
                        borderRadius: BorderRadius.circular(
                          veryCompact ? 16 : 18,
                        ),
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
                _PreviewLine(label: 'Status', value: card['whatsapp']!),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'A polished introduction outside, with the practical business details inside.',
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

  Widget _landingFeatures({required bool compact}) {
    const features = [
      (
        icon: '👤',
        title: 'Professional identity',
        description:
            'Present your name, role, business details and contact information in a clean digital format.',
      ),
      (
        icon: '▦',
        title: 'QR code enabled',
        description:
            'Let customers open your card quickly by scanning a QR code.',
      ),
      (
        icon: '↗',
        title: 'Easy to share',
        description:
            'Share your card through messaging apps and digital channels in a few taps.',
      ),
      (
        icon: '☎',
        title: 'Save to contacts',
        description:
            'Help farmers, retailers and partners save your contact details instantly.',
      ),
      (
        icon: '🌿',
        title: 'Built for agri retailers',
        description:
            'Designed specifically for agricultural product dealers and rural business networks.',
      ),
      (
        icon: '✓',
        title: 'Simple and focused',
        description:
            'Create your card in seconds with the information you publicise most.',
      ),
    ];

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        vertical: compact ? 76 : 100,
        horizontal: compact ? 14 : 20,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 760,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LandingEyebrow(text: 'Everything in one card'),
                    _LandingSectionTitle(
                      text:
                          'A simple way to present and share your agri business.',
                    ),
                    SizedBox(height: 20),
                    Text(
                      'CropzCard keeps your most important business details together, so customers can connect with you without searching through paper cards or messages.',
                      style: TextStyle(
                        fontSize: 17,
                        color: Color(0xFF617066),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth <= 600
                      ? 1
                      : (constraints.maxWidth <= 900 ? 2 : 3);
                  const gap = 20.0;
                  final cardWidth =
                      (constraints.maxWidth - (columns - 1) * gap) / columns;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final feature in features)
                        SizedBox(
                          width: cardWidth,
                          child: _LandingFeatureCard(
                            icon: feature.icon,
                            title: feature.title,
                            description: feature.description,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _landingHowItWorks({required bool compact}) {
    return Container(
      color: const Color(0xFFF4F7F3),
      padding: EdgeInsets.symmetric(
        vertical: compact ? 76 : 100,
        horizontal: compact ? 14 : 20,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1140),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth <= 900;
              final copy = const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LandingEyebrow(text: 'How it works'),
                  _LandingSectionTitle(
                    text: 'From download to sharing in three simple steps.',
                  ),
                  SizedBox(height: 20),
                  Text(
                    'No complicated setup. Add your details, create your digital card, and start sharing it with customers.',
                    style: TextStyle(
                      fontSize: 17,
                      color: Color(0xFF617066),
                      height: 1.6,
                    ),
                  ),
                ],
              );
              final steps = Column(
                children: const [
                  _LandingStep(
                    number: '1',
                    title: 'Download CropzCard',
                    description: 'Install the Android app from Google Play.',
                  ),
                  SizedBox(height: 16),
                  _LandingStep(
                    number: '2',
                    title: 'Create your profile',
                    description:
                        'Add your professional and business contact details.',
                  ),
                  SizedBox(height: 16),
                  _LandingStep(
                    number: '3',
                    title: 'Share your card',
                    description:
                        'Send your digital card or let customers scan its QR code.',
                  ),
                ],
              );
              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [copy, const SizedBox(height: 38), steps],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 88, child: copy),
                  const SizedBox(width: 80),
                  Expanded(flex: 112, child: steps),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _landingCta({required bool compact}) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        vertical: compact ? 60 : 90,
        horizontal: compact ? 14 : 20,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1140),
          child: _GlossyInteractive(
            borderRadius: BorderRadius.circular(28),
            hoverScale: 1.01,
            shadowColor: const Color(0xFF0D341F),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 26 : 54,
                vertical: compact ? 34 : 54,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF103923), Color(0xFF256941)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth <= 760;
                  final copy = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _LandingEyebrow(
                        text: 'Connecting Farmers. Growing Together.',
                        light: true,
                      ),
                      Text(
                        'Make your business easier to discover and remember.',
                        style: TextStyle(
                          fontSize: compact ? 36 : 52,
                          height: 1.06,
                          letterSpacing: -2,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  );
                  final button = FilledButton(
                    onPressed: () => _launchUrl(_playStoreUrl),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF194F32),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 21,
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Get CropzCard'),
                  );
                  if (stacked) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [copy, const SizedBox(height: 28), button],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: copy),
                      const SizedBox(width: 40),
                      button,
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _landingFooter({required bool compact}) {
    final year = DateTime.now().year;
    const footerText = Color(0xFFC8D3CC);
    return Container(
      color: const Color(0xFF0F2418),
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 20,
        60,
        compact ? 14 : 20,
        22,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1140),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final oneColumn = constraints.maxWidth <= 600;
              final twoColumns =
                  constraints.maxWidth > 600 && constraints.maxWidth <= 900;
              final brand = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _CropzBrand(light: true),
                  SizedBox(height: 12),
                  Text(
                    'Digital business cards for agricultural product dealers.',
                    style: TextStyle(color: footerText, height: 1.6),
                  ),
                ],
              );
              final contact = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FooterHeading('Contact'),
                  const SizedBox(height: 10),
                  _footerLink(
                    'cropzdigitalservices@gmail.com',
                    () => _launchEmail('cropzdigitalservices@gmail.com'),
                  ),
                ],
              );
              final links = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FooterHeading('Links'),
                  const SizedBox(height: 10),
                  _footerLink('Google Play', () => _launchUrl(_playStoreUrl)),
                  _footerLink('Help', () => _navigateTo('/help')),
                  _footerLink('Privacy Policy', () => _navigateTo('/privacy')),
                ],
              );
              late final Widget columns;
              if (oneColumn) {
                columns = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    brand,
                    const SizedBox(height: 22),
                    contact,
                    const SizedBox(height: 22),
                    links,
                  ],
                );
              } else if (twoColumns) {
                columns = Wrap(
                  spacing: 40,
                  runSpacing: 32,
                  children: [
                    SizedBox(
                      width: (constraints.maxWidth - 40) / 2,
                      child: brand,
                    ),
                    SizedBox(
                      width: (constraints.maxWidth - 40) / 2,
                      child: contact,
                    ),
                    SizedBox(
                      width: (constraints.maxWidth - 40) / 2,
                      child: links,
                    ),
                  ],
                );
              } else {
                columns = Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: brand),
                    const SizedBox(width: 40),
                    Expanded(flex: 2, child: contact),
                    const SizedBox(width: 40),
                    Expanded(flex: 2, child: links),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  columns,
                  const SizedBox(height: 46),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 20),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    child: Text(
                      '© $year Cropz Digital Services. All rights reserved.',
                      style: const TextStyle(fontSize: 13, color: footerText),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _footerLink(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFFC8D3CC)),
        ),
      ),
    );
  }

  // ignore: unused_element
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
            title: 'Trust at first sight',
            body:
                'Replace forwarded screenshots with a profile that feels like a real business page.',
          ),
          _StatementBlock(
            title: 'Built for field speed',
            body:
                'Open, verify, call, and continue the conversation without requiring an app install first.',
          ),
          _StatementBlock(
            title: 'Complete, organized details',
            body:
                'Licenses, banking details, business identity, and addresses stay organized when viewers need more.',
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _operationsSection({required bool compact}) {
    final theme = Theme.of(context);
    final content = [
      const _ProcessStep(
        index: '01',
        title: 'Publish the identity',
        body:
            'Create a professional card from business information already saved in the app.',
      ),
      const _ProcessStep(
        index: '02',
        title: 'Share a clean link',
        body:
            'Anyone opening the card sees a polished presentation instead of a raw data list.',
      ),
      const _ProcessStep(
        index: '03',
        title: 'Move to the next action',
        body:
            'Viewers can open the app, contact the owner, or confirm operational details with ease.',
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
                  title: 'How this page should work',
                  body:
                      'Use the calm, organized feel and clear hierarchy of a focused product site.',
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
                    title: 'How this page should work',
                    body:
                        'Use the calm, organized feel and clear hierarchy of a focused product site.',
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

  // ignore: unused_element
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
              _darkTag('Trust-building headline'),
              _darkTag('Easy-to-read details'),
              _darkTag('Quickly understood layout'),
            ],
          ),
        ],
      ),
    );

    final notes = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(
          title: 'Design direction',
          body:
              'This version presents a polished public product page rather than a demo box.',
        ),
        const SizedBox(height: 16),
        const _NoteRow(
          title: 'Brand first',
          body:
              'The first screen works like a poster: one strong message paired with a direct preview.',
        ),
        const SizedBox(height: 12),
        const _NoteRow(
          title: 'Less unnecessary decoration',
          body:
              'Spacing, contrast, and readable hierarchy carry more weight than excessive borders and cards.',
        ),
        const SizedBox(height: 12),
        const _NoteRow(
          title: 'Clear product motion',
          body:
              'Subtle entrance and background motion support the page without decorative noise.',
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

  // ignore: unused_element
  Widget _finalCta({required bool compact, required bool veryCompact}) {
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
          'A stronger first impression is now the default experience.',
          style: TextStyle(
            color: headlineColor,
            fontSize: 28,
            height: 1.1,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Use the same web address, keep the current card flow, and present it with modern product polish.',
          style: TextStyle(color: bodyColor, fontSize: 15.5, height: 1.55),
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
            backgroundColor: isDark
                ? theme.colorScheme.surface
                : const Color(0xFFF8F4EC),
            foregroundColor: isDark
                ? theme.colorScheme.onSurface
                : const Color(0xFF153E39),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
          child: const Text('Launch app link'),
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
    required List<Map<String, dynamic>> addresses,
    required List<Map<String, dynamic>> documents,
    required _PreviewFilters filters,
    required bool compact,
    required bool veryCompact,
  }) {
    final visibleBanks = filters.filterIndexed(banks);
    final visibleAddresses = filters.filterAddress(addresses);
    final showDigitalPanel = _hasVisibleDataEntries(digital);
    final showBusinessPanel =
        filters.showBusiness && _hasVisibleDataEntries(business);
    final showLicensePanel =
        filters.showLicenseInfo && _hasVisibleDataEntries(license);
    final showDocumentPanel = documents.any(_hasDocumentData);
    final showAddressPanel =
        filters.showAddress && visibleAddresses.any(_hasAddressData);
    final showBankPanel = filters.showBanks && visibleBanks.any(_hasMapData);

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
                            if (showDigitalPanel)
                              _DataPanel(title: 'Digital card', data: digital),
                            if (showBusinessPanel) ...[
                              const SizedBox(height: 14),
                              _DataPanel(title: 'Business', data: business),
                            ],
                            if (showLicensePanel) ...[
                              const SizedBox(height: 14),
                              _DataPanel(title: 'License info', data: license),
                            ],
                            if (showDocumentPanel) ...[
                              const SizedBox(height: 14),
                              _DocumentPanel(documents: documents),
                            ],
                            if (showAddressPanel) ...[
                              const SizedBox(height: 14),
                              _AddressPanel(addresses: visibleAddresses),
                            ],
                            if (showBankPanel) ...[
                              const SizedBox(height: 14),
                              _BankPanel(banks: visibleBanks),
                            ],
                          ],
                        )
                      : Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            if (showDigitalPanel)
                              SizedBox(
                                width: panelWidth,
                                child: _DataPanel(
                                  title: 'Digital card',
                                  data: digital,
                                ),
                              ),
                            if (showBusinessPanel)
                              SizedBox(
                                width: panelWidth,
                                child: _DataPanel(
                                  title: 'Business',
                                  data: business,
                                ),
                              ),
                            if (showLicensePanel)
                              SizedBox(
                                width: panelWidth,
                                child: _DataPanel(
                                  title: 'License info',
                                  data: license,
                                ),
                              ),
                            if (showDocumentPanel)
                              SizedBox(
                                width: panelWidth,
                                child: _DocumentPanel(documents: documents),
                              ),
                            if (showAddressPanel)
                              SizedBox(
                                width: panelWidth,
                                child: _AddressPanel(
                                  addresses: visibleAddresses,
                                ),
                              ),
                            if (showBankPanel)
                              SizedBox(
                                width: panelWidth,
                                child: _BankPanel(banks: visibleBanks),
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
                colors: [
                  Color(0xFF0C1713),
                  Color(0xFF10221B),
                  Color(0xFF17372F),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF102017),
                  Color(0xFF153727),
                  Color(0xFF173D5A),
                ],
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
                  color: isDark
                      ? const Color(0xFFBDE9D3)
                      : const Color(0xFFD4EBDD),
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
                  children: [if (email.isNotEmpty) _darkTag(email)],
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
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
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

class _LandingEyebrow extends StatelessWidget {
  const _LandingEyebrow({required this.text, this.light = false});

  final String text;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.6,
          color: light ? const Color(0xFFB9ED80) : const Color(0xFF2D7A48),
        ),
      ),
    );
  }
}

class _LandingSectionTitle extends StatelessWidget {
  const _LandingSectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Text(
      text,
      style: TextStyle(
        fontSize: width <= 600 ? 36 : (width <= 900 ? 44 : 56),
        height: 1.06,
        letterSpacing: width <= 600 ? -1.6 : -2.8,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF13251A),
      ),
    );
  }
}

class _LandingFeatureCard extends StatelessWidget {
  const _LandingFeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final String icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return _GlossyInteractive(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        constraints: const BoxConstraints(minHeight: 245),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFDCE6DD)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7F3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                icon,
                style: const TextStyle(fontSize: 21, color: Color(0xFF194F32)),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF13251A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF617066),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LandingStep extends StatelessWidget {
  const _LandingStep({
    required this.number,
    required this.title,
    required this.description,
  });

  final String number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return _GlossyInteractive(
      borderRadius: BorderRadius.circular(18),
      hoverScale: 1.008,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(23),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFDCE6DD)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFF194F32),
                shape: BoxShape.circle,
              ),
              child: Text(
                number,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF13251A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF617066),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CropzBrand extends StatelessWidget {
  const _CropzBrand({this.light = false});

  final bool light;

  @override
  Widget build(BuildContext context) {
    final wordColor = light ? Colors.white : const Color(0xFF13251A);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 37,
          height: 37,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: light
                  ? Colors.white.withValues(alpha: 0.22)
                  : const Color(0xFFDCE6DD),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/images/cropzcard-hd-logo.png',
            width: 37,
            height: 37,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF83C341), Color(0xFF2D7A48)],
                  ),
                ),
                child: const Text(
                  'C',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Cropz',
                style: TextStyle(fontWeight: FontWeight.w800, color: wordColor),
              ),
              TextSpan(
                text: 'Card',
                style: TextStyle(color: wordColor),
              ),
            ],
          ),
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 21, letterSpacing: -0.6),
        ),
      ],
    );
  }
}

class _FooterHeading extends StatelessWidget {
  const _FooterHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }
}

class _GooglePlayMark extends StatelessWidget {
  const _GooglePlayMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 22,
      child: CustomPaint(painter: _GooglePlayPainter()),
    );
  }
}

class _GooglePlayPainter extends CustomPainter {
  const _GooglePlayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.48, size.height * 0.5);
    canvas.drawPath(
      Path()
        ..moveTo(1, 1)
        ..lineTo(center.dx, center.dy)
        ..lineTo(1, size.height - 1)
        ..close(),
      Paint()..color = const Color(0xFF42D3FF),
    );
    canvas.drawPath(
      Path()
        ..moveTo(1, 1)
        ..lineTo(size.width * 0.7, size.height * 0.34)
        ..lineTo(center.dx, center.dy)
        ..close(),
      Paint()..color = const Color(0xFF64E572),
    );
    canvas.drawPath(
      Path()
        ..moveTo(1, size.height - 1)
        ..lineTo(center.dx, center.dy)
        ..lineTo(size.width * 0.7, size.height * 0.66)
        ..close(),
      Paint()..color = const Color(0xFFFFD23F),
    );
    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(size.width - 1, size.height * 0.5)
        ..lineTo(size.width * 0.7, size.height * 0.34)
        ..lineTo(size.width * 0.7, size.height * 0.66)
        ..close(),
      Paint()..color = const Color(0xFFFF5468),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TrustIndicator extends StatelessWidget {
  const _TrustIndicator({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, size: 16, color: Color(0xFF194F32)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF617066),
          ),
        ),
      ],
    );
  }
}

class _PreviewFilters {
  const _PreviewFilters({
    required this.sections,
    required this.bankIndexes,
    required this.addressIndexes,
  });

  final Set<String> sections;
  final Set<int>? bankIndexes;
  final Set<int>? addressIndexes;

  factory _PreviewFilters.fromUri(Uri uri) {
    final sections = _parseCsv(
      uri.queryParameters['sections'],
    ).map((value) => value.toLowerCase()).toSet();
    return _PreviewFilters(
      sections: sections,
      bankIndexes: _parseCsv(
        uri.queryParameters['banks'],
      ).map(int.tryParse).whereType<int>().toSet(),
      addressIndexes: _parseCsv(
        uri.queryParameters['addresses'],
      ).map(int.tryParse).whereType<int>().toSet(),
    );
  }

  bool get showBusiness => sections.isEmpty || sections.contains('business');

  bool get showLicenseInfo => sections.isEmpty || sections.contains('license');

  bool get showBanks => sections.isEmpty || sections.contains('banks');

  bool get showAddress => sections.isEmpty || sections.contains('address');

  List<Map<String, dynamic>> filterIndexed(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return const [];
    }
    if (bankIndexes == null || bankIndexes!.isEmpty) {
      return items;
    }
    return items
        .asMap()
        .entries
        .where((entry) => bankIndexes!.contains(entry.key))
        .map((entry) => entry.value)
        .toList(growable: false);
  }

  List<Map<String, dynamic>> filterAddress(
    List<Map<String, dynamic>> addresses,
  ) {
    if (addresses.isEmpty) {
      return const [];
    }
    if (addressIndexes == null || addressIndexes!.isEmpty) {
      return addresses;
    }
    return addresses
        .asMap()
        .entries
        .where((entry) => addressIndexes!.contains(entry.key))
        .map((entry) => entry.value)
        .toList(growable: false);
  }
}

List<String> _parseCsv(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return const [];
  }
  return raw
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
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
                  ? theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.92,
                    )
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
  const _GlossyInteractive({
    required this.child,
    required this.borderRadius,
    this.hoverScale = 1.015,
    this.shadowColor = Colors.black,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final double hoverScale;
  final Color shadowColor;

  @override
  State<_GlossyInteractive> createState() => _GlossyInteractiveState();
}

class _GlossyInteractiveState extends State<_GlossyInteractive> {
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
          scale: _pressed ? 0.985 : (active ? widget.hoverScale : 1),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedSlide(
            offset: Offset(0, active && !_pressed ? -0.01 : 0),
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: widget.borderRadius,
                boxShadow: [
                  BoxShadow(
                    color: widget.shadowColor.withValues(
                      alpha: active ? 0.18 : 0.08,
                    ),
                    blurRadius: active ? 32 : 18,
                    spreadRadius: active ? 1 : 0,
                    offset: Offset(0, active ? 16 : 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: widget.borderRadius,
                child: Stack(
                  children: [
                    widget.child,
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedOpacity(
                          opacity: active ? 1 : 0.62,
                          duration: const Duration(milliseconds: 180),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(
                                    alpha: active ? 0.34 : 0.18,
                                  ),
                                  Colors.white.withValues(alpha: 0.06),
                                  Colors.white.withValues(alpha: 0),
                                ],
                                stops: const [0, 0.34, 0.78],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 1,
                      top: 1,
                      right: 1,
                      height: 22,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(
                                  alpha: active ? 0.56 : 0.32,
                                ),
                                Colors.white.withValues(alpha: 0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
    required this.onHelp,
    required this.onPrivacy,
    required this.onOpenApp,
  });

  final bool compact;
  final bool veryCompact;
  final _PageMode currentMode;
  final VoidCallback onHome;
  final VoidCallback onHelp;
  final VoidCallback onPrivacy;
  final VoidCallback onOpenApp;

  @override
  Widget build(BuildContext context) {
    final appButton = FilledButton(
      onPressed: onOpenApp,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF194F32),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text('Get the app'),
    );

    Widget navButtons() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact) ...[
            _NavLink(
              label: 'Home',
              selected: currentMode == _PageMode.home,
              onTap: onHome,
            ),
            const SizedBox(width: 18),
            _NavLink(
              label: 'Help',
              selected: currentMode == _PageMode.help,
              onTap: onHelp,
            ),
            const SizedBox(width: 18),
            _NavLink(
              label: 'Privacy Policy',
              selected: currentMode == _PageMode.privacy,
              onTap: onPrivacy,
            ),
            const SizedBox(width: 18),
          ],
          if (!veryCompact) appButton,
          if (compact) ...[
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              tooltip: 'Menu',
              onSelected: (value) {
                if (value == 'home') {
                  onHome();
                } else if (value == 'help') {
                  onHelp();
                } else if (value == 'privacy') {
                  onPrivacy();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'home', child: Text('Home')),
                PopupMenuItem(value: 'help', child: Text('Help')),
                PopupMenuItem(value: 'privacy', child: Text('Privacy Policy')),
              ],
            ),
          ],
        ],
      );
    }

    return Container(
      height: veryCompact ? 66 : 74,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: veryCompact ? 14 : 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        border: const Border(bottom: BorderSide(color: Color(0xFFDCE6DD))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1140),
          child: Row(
            children: [
              InkWell(
                onTap: onHome,
                borderRadius: BorderRadius.circular(12),
                child: const _CropzBrand(),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: navButtons(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: selected
            ? const Color(0xFF194F32)
            : const Color(0xFF405248),
        backgroundColor: selected
            ? const Color(0xFF83C341).withValues(alpha: 0.13)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: TextStyle(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 14,
        ),
      ),
      child: Text(label),
    );
  }
}

// ignore: unused_element
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final labelColor = isDark
        ? const Color(0xFFE7F3ED)
        : Colors.black.withValues(alpha: 0.78);
    final valueColor = isDark ? const Color(0xFFF7FBF8) : Colors.black;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: TextStyle(color: labelColor, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor, fontWeight: FontWeight.w600),
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

class _DataPanel extends StatelessWidget {
  const _DataPanel({required this.title, required this.data});

  final String title;
  final Map<String, dynamic> data;
  static const Set<String> _hiddenKeys = {'id', 'cardId', 'recordId'};

  @override
  Widget build(BuildContext context) {
    final visibleEntries = data.entries
        .where((entry) {
          if (_hiddenKeys.contains(entry.key)) {
            return false;
          }
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
        color: _panelSurfaceColor(theme),
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
              color: _panelPrimaryTextColor(theme),
            ),
          ),
          const SizedBox(height: 16),
          if (visibleEntries.isEmpty)
            Text(
              'No data entered',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _panelSecondaryTextColor(theme),
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
                          color: _panelMutedTextColor(theme),
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
                          color: _panelPrimaryTextColor(theme),
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
        color: _panelSurfaceColor(theme),
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
              color: _panelPrimaryTextColor(theme),
            ),
          ),
          const SizedBox(height: 16),
          if (populatedDocuments.isEmpty)
            Text(
              'No data entered',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _panelSecondaryTextColor(theme),
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
                  color: _panelInsetColor(theme),
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
                              color: _panelPrimaryTextColor(theme),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fileName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: _panelSecondaryTextColor(theme),
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
        color: _panelSurfaceColor(theme),
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
              color: _panelPrimaryTextColor(theme),
            ),
          ),
          const SizedBox(height: 16),
          if (populatedBanks.isEmpty)
            Text(
              'No data entered',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _panelSecondaryTextColor(theme),
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
                  color: _panelInsetColor(theme),
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
                                    color: _panelMutedTextColor(theme),
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
                                    color: _panelPrimaryTextColor(theme),
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

class _AddressPanel extends StatelessWidget {
  const _AddressPanel({required this.addresses});

  final List<Map<String, dynamic>> addresses;

  @override
  Widget build(BuildContext context) {
    final populatedAddresses = addresses
        .where(_hasAddressData)
        .toList(growable: false);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: _panelSurfaceColor(theme),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.85),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Address',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: _panelPrimaryTextColor(theme),
            ),
          ),
          const SizedBox(height: 16),
          if (populatedAddresses.isEmpty)
            Text(
              'No data entered',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _panelSecondaryTextColor(theme),
              ),
            )
          else
            ...populatedAddresses.asMap().entries.map((entry) {
              final address = entry.value;
              final title = (address['type'] ?? '').toString().trim();
              final label = title.isEmpty ? 'Address ${entry.key + 1}' : title;
              final lines = _addressLines(address);
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: _panelInsetColor(theme),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.7),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _panelPrimaryTextColor(theme),
                      ),
                    ),
                    if (lines.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        lines.join('\n'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _panelSecondaryTextColor(theme),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

Color _panelSurfaceColor(ThemeData theme) {
  final isDark = theme.brightness == Brightness.dark;
  return isDark
      ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.92)
      : theme.colorScheme.surface.withValues(alpha: 0.94);
}

Color _panelInsetColor(ThemeData theme) {
  final isDark = theme.brightness == Brightness.dark;
  return isDark
      ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.96)
      : theme.colorScheme.surfaceContainer.withValues(alpha: 0.8);
}

Color _panelPrimaryTextColor(ThemeData theme) {
  final isDark = theme.brightness == Brightness.dark;
  return theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.98 : 0.92);
}

Color _panelSecondaryTextColor(ThemeData theme) {
  final isDark = theme.brightness == Brightness.dark;
  return theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.88 : 0.72);
}

Color _panelMutedTextColor(ThemeData theme) {
  final isDark = theme.brightness == Brightness.dark;
  return theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.78 : 0.58);
}

// ignore: unused_element
class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.transparent,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          'https://maas-log-prod.cn-wlcb.ufileos.com/anthropic/ebcb8b1f-eac5-42ad-b3bb-0063b80c9125/fe173fa39f8e06cc75db0f539afa3fb5.png?UCloudPublicKey=TOKEN_e15ba47a-d098-4fbd-9afc-a0dcf0e4e621&Expires=1784814352&Signature=8Eu6JKbikenMt1IW0qj0T4%2BtmXg=',
          width: 42,
          height: 42,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFF194F32),
              ),
              child: const Icon(Icons.eco_rounded, color: Colors.white),
            );
          },
        ),
      ),
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
  const englishLabels = {
    'gst': 'GST',
    'gstNumber': 'GST Number',
    'ifsc': 'IFSC',
    'pincode': 'PIN code',
    'whatsapp': 'WhatsApp',
  };
  final label = englishLabels[key];
  if (label != null) {
    return label;
  }
  final out = key
      .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
      .trim();
  return out.isEmpty ? key : out[0].toUpperCase() + out.substring(1);
}

bool _hasVisibleDataEntries(Map<String, dynamic> data) {
  return data.entries.any((entry) {
    if (_DataPanel._hiddenKeys.contains(entry.key)) {
      return false;
    }
    final value = entry.value;
    if (value == null) {
      return false;
    }
    final text = value.toString().trim();
    return text.isNotEmpty && text.toLowerCase() != 'null';
  });
}

bool _hasDocumentData(Map<String, dynamic> document) {
  final label = (document['label'] ?? '').toString().trim();
  final fileName = (document['fileName'] ?? '').toString().trim();
  final downloadUrl = (document['downloadUrl'] ?? '').toString().trim();
  return label.isNotEmpty && fileName.isNotEmpty && downloadUrl.isNotEmpty;
}

List<String> _addressLines(Map<String, dynamic> address) {
  final lines = <String>[];
  for (final key in const [
    'line1',
    'line2',
    'line3',
    'city',
    'district',
    'state',
    'pincode',
  ]) {
    final value = (address[key] ?? '').toString().trim();
    if (value.isNotEmpty && value.toLowerCase() != 'null') {
      lines.add(value);
    }
  }
  return lines;
}

bool _hasAddressData(Map<String, dynamic> address) {
  return _addressLines(address).isNotEmpty;
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
