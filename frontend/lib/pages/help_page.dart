import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({
    super.key,
    required this.compact,
    required this.veryCompact,
    required this.onHome,
    required this.onPrivacy,
    required this.onOpenApp,
  });

  final bool compact;
  final bool veryCompact;
  final VoidCallback onHome;
  final VoidCallback onPrivacy;
  final VoidCallback onOpenApp;

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  static const _mailTo = 'cropzsupport@gmail.com';
  static const _issueTypes = <String>[
    'Page not loading',
    'Data looks wrong',
    'App handoff failed',
    'File preview issue',
    'Other',
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dateController = TextEditingController();
  final _pageController = TextEditingController();
  final _deviceController = TextEditingController();
  final _whatController = TextEditingController();
  final _expectedController = TextEditingController();
  final _stepsController = TextEditingController();
  final _detailsController = TextEditingController();

  DateTime _dateNoticed = DateTime.now();
  String _issueType = _issueTypes.first;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _dateController.text = _formatDate(_dateNoticed);
    _pageController.text = Uri.base.path.isEmpty ? '/' : Uri.base.path;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _dateController.dispose();
    _pageController.dispose();
    _deviceController.dispose();
    _whatController.dispose();
    _expectedController.dispose();
    _stepsController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Uri _saveEndpoint() {
    const apiBase = String.fromEnvironment('API_BASE');
    final relative = Uri.parse('/api/error-requests');
    return apiBase.isEmpty
        ? Uri.base.resolveUri(relative)
        : Uri.parse(apiBase).resolveUri(relative);
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  Map<String, dynamic> _buildPayload() {
    return {
      'requester_name': _nameController.text.trim(),
      'requester_email': _emailController.text.trim(),
      'issue_type': _issueType,
      'date_noticed': _formatDate(_dateNoticed),
      'page_or_screen': _pageController.text.trim(),
      'device_browser': _deviceController.text.trim(),
      'what_happened': _whatController.text.trim(),
      'expected_result': _expectedController.text.trim(),
      'steps_tried': _stepsController.text.trim(),
      'additional_details': _detailsController.text.trim(),
      'source_url': Uri.base.toString(),
      'source_path': Uri.base.path.isEmpty ? '/' : Uri.base.path,
      'status': 'open',
      'source': 'web',
    };
  }

  String _buildMailBody(Map<String, dynamic> payload, String? requestId) {
    final body = StringBuffer()
      ..writeln('Cropz Card error request')
      ..writeln('Request ID: ${requestId ?? 'pending'}')
      ..writeln('Name: ${payload['requester_name']}')
      ..writeln('Email: ${payload['requester_email']}')
      ..writeln('Issue type: ${payload['issue_type']}')
      ..writeln('Date noticed: ${payload['date_noticed']}')
      ..writeln('Page / screen: ${payload['page_or_screen']}')
      ..writeln('Device / browser: ${payload['device_browser']}')
      ..writeln('What happened: ${payload['what_happened']}')
      ..writeln('Expected result: ${payload['expected_result']}')
      ..writeln('Steps tried: ${payload['steps_tried']}')
      ..writeln('Additional details: ${payload['additional_details']}')
      ..writeln('Source URL: ${payload['source_url']}');
    return body.toString();
  }

  Uri _buildMailToUri(Map<String, dynamic> payload, String? requestId) {
    return Uri(
      scheme: 'mailto',
      path: _mailTo,
      queryParameters: {
        'subject': 'Cropz Card error request',
        'body': _buildMailBody(payload, requestId),
      },
    );
  }

  Uri _buildGmailComposeUri(Map<String, dynamic> payload, String? requestId) {
    return Uri.https('mail.google.com', '/mail/', {
      'view': 'cm',
      'fs': '1',
      'to': _mailTo,
      'su': 'Cropz Card error request',
      'body': _buildMailBody(payload, requestId),
    });
  }

  Uri _buildGmailAppUri(Map<String, dynamic> payload, String? requestId) {
    return Uri(
      scheme: 'googlegmail',
      host: 'co',
      queryParameters: {
        'to': _mailTo,
        'subject': 'Cropz Card error request',
        'body': _buildMailBody(payload, requestId),
      },
    );
  }

  Future<void> _openEmailDraft(
    Map<String, dynamic> payload,
    String? requestId,
  ) async {
    if (kIsWeb) {
      final launched = await launchUrl(
        _buildGmailComposeUri(payload, requestId),
        webOnlyWindowName: '_blank',
      );
      if (launched) {
        return;
      }
    } else if (await canLaunchUrl(_buildGmailAppUri(payload, requestId))) {
      final launched = await launchUrl(
        _buildGmailAppUri(payload, requestId),
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        return;
      }
    }

    final launched = await launchUrl(
      _buildMailToUri(payload, requestId),
      mode: LaunchMode.externalApplication,
    );
    if (launched) {
      return;
    }

    throw Exception('could not open email draft');
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dateNoticed,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      _dateNoticed = selected;
      _dateController.text = _formatDate(selected);
    });
  }

  Future<void> _submit() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _saving = true;
    });

    final payload = _buildPayload();
    try {
      final response = await http.post(
        _saveEndpoint(),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200 &&
          response.statusCode != 201 &&
          response.statusCode != 202) {
        throw Exception(
          'save failed with ${response.statusCode}: ${response.body.trim()}',
        );
      }

      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(response.body) as Map).cast<String, dynamic>();
      final requestId = decoded['id']?.toString();

      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      final warning = decoded['warning']?.toString().trim() ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(warning.isEmpty ? 'Opening email draft' : warning),
        ),
      );

      try {
        await _openEmailDraft(payload, requestId);
      } catch (error) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved, but could not open email: $error')),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save request: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = widget.compact ? 960.0 : 1140.0;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        widget.compact ? 14 : 20,
        widget.veryCompact ? 18 : 32,
        widget.compact ? 14 : 20,
        28,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FormHero(
                  compact: widget.compact,
                  veryCompact: widget.veryCompact,
                  onHome: widget.onHome,
                  onPrivacy: widget.onPrivacy,
                ),
                const SizedBox(height: 20),
                _SectionCard(
                  compact: widget.compact,
                  veryCompact: widget.veryCompact,
                  title: 'Report a problem',
                  subtitle:
                      'Use this simple report form. We only ask for details that help reproduce the issue and prepare a support email draft.',
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.compact) ...[
                          _InputField(
                            controller: _nameController,
                            label: 'Your name',
                            hint: 'Enter your full name',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _InputField(
                            controller: _emailController,
                            label: 'Email address',
                            hint: 'name@example.com',
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) {
                                return 'Email is required';
                              }
                              if (!text.contains('@') || !text.contains('.')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                        ] else ...[
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              SizedBox(
                                width: 320,
                                child: _InputField(
                                  controller: _nameController,
                                  label: 'Your name',
                                  hint: 'Enter your full name',
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Name is required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(
                                width: 320,
                                child: _InputField(
                                  controller: _emailController,
                                  label: 'Email address',
                                  hint: 'name@example.com',
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    final text = value?.trim() ?? '';
                                    if (text.isEmpty) {
                                      return 'Email is required';
                                    }
                                    if (!text.contains('@') ||
                                        !text.contains('.')) {
                                      return 'Enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        if (widget.compact) ...[
                          DropdownButtonFormField<String>(
                            initialValue: _issueType,
                            isExpanded: true,
                            decoration: _fieldDecoration(context, 'Issue type'),
                            items: [
                              for (final type in _issueTypes)
                                DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                            ],
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() {
                                _issueType = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          _InputField(
                            controller: _dateController,
                            label: 'Date noticed',
                            hint: 'Pick the date you first noticed the issue',
                            readOnly: true,
                            onTap: _pickDate,
                            suffixIcon: const Icon(Icons.calendar_month),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Date noticed is required';
                              }
                              return null;
                            },
                          ),
                        ] else ...[
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              SizedBox(
                                width: 320,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _issueType,
                                  isExpanded: true,
                                  decoration: _fieldDecoration(
                                    context,
                                    'Issue type',
                                  ),
                                  items: [
                                    for (final type in _issueTypes)
                                      DropdownMenuItem(
                                        value: type,
                                        child: Text(type),
                                      ),
                                  ],
                                  onChanged: (value) {
                                    if (value == null) {
                                      return;
                                    }
                                    setState(() {
                                      _issueType = value;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(
                                width: 320,
                                child: _InputField(
                                  controller: _dateController,
                                  label: 'Date noticed',
                                  hint:
                                      'Pick the date you first noticed the issue',
                                  readOnly: true,
                                  onTap: _pickDate,
                                  suffixIcon: const Icon(Icons.calendar_month),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Date noticed is required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        if (widget.compact) ...[
                          _InputField(
                            controller: _pageController,
                            label: 'Page or screen',
                            hint: 'Example: /help, card preview, form step 2',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Page or screen is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _InputField(
                            controller: _deviceController,
                            label: 'Device / browser',
                            hint: 'Example: Android Chrome, iPhone Safari',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Device or browser is required';
                              }
                              return null;
                            },
                          ),
                        ] else ...[
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              SizedBox(
                                width: 320,
                                child: _InputField(
                                  controller: _pageController,
                                  label: 'Page or screen',
                                  hint:
                                      'Example: /help, card preview, form step 2',
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Page or screen is required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(
                                width: 320,
                                child: _InputField(
                                  controller: _deviceController,
                                  label: 'Device / browser',
                                  hint:
                                      'Example: Android Chrome, iPhone Safari',
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Device or browser is required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        _InputField(
                          controller: _whatController,
                          label: 'What happened?',
                          hint: 'Describe the exact problem you saw',
                          maxLines: 4,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Describe what happened';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _InputField(
                          controller: _expectedController,
                          label: 'What did you expect?',
                          hint: 'Optional but useful for debugging',
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        _InputField(
                          controller: _stepsController,
                          label: 'Steps tried',
                          hint:
                              'Example: refreshed, signed out, opened another browser',
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        _InputField(
                          controller: _detailsController,
                          label: 'Additional details',
                          hint:
                              'Anything else that might help reproduce the issue',
                          maxLines: 4,
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            FilledButton.icon(
                              onPressed: _saving ? null : _submit,
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
                              icon: _saving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.send_rounded),
                              label: Text(_saving ? 'Sending...' : 'Send form'),
                            ),
                            OutlinedButton(
                              onPressed: widget.onOpenApp,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF194F32),
                                side: const BorderSide(
                                  color: Color(0xFF83C341),
                                ),
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
                              onPressed: () async {
                                const template = '''
Cropz Card error request
- Name
- Email
- Issue type
- Date noticed
- Page or screen
- Device / browser
- What happened
- What did you expect
- Steps tried
- Additional details
''';
                                await Clipboard.setData(
                                  const ClipboardData(text: template),
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Required fields copied'),
                                    ),
                                  );
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF194F32),
                                side: const BorderSide(
                                  color: Color(0xFF83C341),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Copy field list'),
                            ),
                          ],
                        ),
                      ],
                    ),
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
    required this.onPrivacy,
  });

  final bool compact;
  final bool veryCompact;
  final VoidCallback onHome;
  final VoidCallback onPrivacy;

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
                  'Help',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF2D7A48),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Need help with Cropz Card?',
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
                    'Fill the form with the date you noticed the issue, the page or screen where it happened, and the other details needed to reproduce it. The next step opens an email draft for Cropz support.',
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
                    _HeroLink(label: 'Privacy Policy', onPressed: onPrivacy),
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
    return _ActivePanel(
      borderRadius: BorderRadius.circular(veryCompact ? 24 : 30),
      child: Container(
        padding: EdgeInsets.all(veryCompact ? 18 : (compact ? 20 : 28)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(veryCompact ? 24 : 30),
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
                color: const Color(0xFF13251A),
              ),
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Text(
                subtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.55,
                  color: const Color(0xFF617066),
                ),
              ),
            ),
            const SizedBox(height: 18),
            child,
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

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
    this.maxLines = 1,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final FormFieldValidator<String>? validator;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: maxLines,
          minLines: maxLines > 1 ? maxLines : 1,
          decoration: _fieldDecoration(context, hint, suffixIcon: suffixIcon),
        ),
      ],
    );
  }
}

InputDecoration _fieldDecoration(
  BuildContext context,
  String hint, {
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFF7FAF6),
    suffixIcon: suffixIcon,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: const Color(0xFFDCE6DD)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: const Color(0xFFDCE6DD)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: const Color(0xFF83C341), width: 1.6),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}
