import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../theme.dart';
import 'common.dart';

class LogViewer extends StatefulWidget {
  const LogViewer({
    required this.service,
    required this.stream,
    super.key,
  });

  final GokrazyService service;
  final Stream<String> stream;

  @override
  State<LogViewer> createState() => _LogViewerState();
}

class _LogViewerState extends State<LogViewer> {
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<String>? _subscription;
  String _text = '';
  bool _streaming = true;
  bool _autoFollow = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _subscription = widget.stream.listen(
      (next) {
        if (!mounted) {
          return;
        }
        setState(() => _text = next);
        if (_autoFollow) {
          _scheduleScrollToBottom();
        }
      },
      onError: (error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _error = error.toString();
          _streaming = false;
        });
      },
      onDone: () {
        if (!mounted) {
          return;
        }
        setState(() => _streaming = false);
      },
      cancelOnError: false,
    );
    _scrollController.addListener(_handleUserScroll);
  }

  void _handleUserScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    final atBottom = position.pixels >= position.maxScrollExtent - 32;
    if (atBottom != _autoFollow) {
      setState(() => _autoFollow = atBottom);
    }
  }

  void _scheduleScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  Future<void> _copyAll() async {
    if (_text.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: _text));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs copied to clipboard')),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final hasContent = _text.isNotEmpty;
    final tone = _error != null
        ? StatusTone.error
        : _streaming
            ? StatusTone.success
            : StatusTone.neutral;
    final toneLabel = _error != null
        ? 'Error'
        : _streaming
            ? 'Streaming'
            : 'Closed';
    final toneIcon = _error != null
        ? Icons.error_rounded
        : _streaming
            ? Icons.podcasts_rounded
            : Icons.power_settings_new_rounded;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              AppSpacing.s,
              AppSpacing.l,
              AppSpacing.l,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
                children: [
                  GradientIconBadge(
                    icon: Icons.terminal_rounded,
                    size: 44,
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.service.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.service.path,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                                color: dark
                                    ? Colors.white.withValues(alpha: 0.55)
                                    : Colors.black.withValues(alpha: 0.5),
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusPill(
                    label: toneLabel,
                    icon: toneIcon,
                    tone: tone,
                    dense: true,
                  ),
                  StatusPill(
                    label: _autoFollow ? 'Auto-follow on' : 'Auto-follow off',
                    icon: _autoFollow
                        ? Icons.vertical_align_bottom_rounded
                        : Icons.pause_circle_outline_rounded,
                    tone: _autoFollow ? StatusTone.info : StatusTone.neutral,
                    dense: true,
                    onTap: () {
                      setState(() => _autoFollow = !_autoFollow);
                      if (_autoFollow) {
                        _scheduleScrollToBottom();
                      }
                    },
                  ),
                  StatusPill(
                    label: 'Copy',
                    icon: Icons.copy_rounded,
                    tone: StatusTone.primary,
                    dense: true,
                    onTap: hasContent ? _copyAll : null,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s),
              if (_error != null) ...[
                ErrorBanner(message: _error!),
                const SizedBox(height: AppSpacing.s),
              ],
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: dark
                        ? const Color(0xFF050816)
                        : const Color(0xFF0E1530),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: dark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s),
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const ClampingScrollPhysics(),
                        child: SelectableText(
                          hasContent ? _text : 'Connecting...',
                          style: TextStyle(
                            color: hasContent
                                ? const Color(0xFFC7D2FE)
                                : Colors.white.withValues(alpha: 0.6),
                            fontFamily: 'monospace',
                            fontSize: 12.5,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          ),
        );
      },
    );
  }
}
