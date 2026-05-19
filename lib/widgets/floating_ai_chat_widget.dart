import 'dart:async';
import 'dart:convert';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_navigator_key.dart';
import '../localization/app_localizations.dart';
import '../providers/ai_chat_service.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/travel_provider.dart';

const _kFabPosPrefsKey = 'wajeeh_ai_chat_fab_pos_v1';
const _kFabTouchSlop = 12.0;
const _kFabWidth = 172.0;
const _kFabHeight = 60.0;
const _kOnlineGreen = Color(0xFF34C759);

String _localizedAiChatWelcome(BuildContext context, String? sessionName) {
  final n = sessionName?.trim();
  if (n != null && n.isNotEmpty) {
    return context.tr('ai_chat_welcome_named', {'name': n});
  }
  return context.tr('ai_chat_welcome_generic');
}

String _cleanMarkdownForChatBubble(String raw) {
  var t = raw.replaceAll(RegExp(r'\$\d+'), '');
  t = t.replaceAll('**', '').replaceAll('__', '').replaceAll('`', '');
  final out = <String>[];
  for (final rawLine in t.split('\n')) {
    var line = rawLine.trimRight();
    line = line.replaceFirst(RegExp(r'^#+\s*'), '');
    line = line.replaceFirst(RegExp(r'^\s*[\-*•]\s+'), '');
    line = line.replaceFirst(RegExp(r'^\s*\d+[\.)]\s+'), '');
    out.add(line);
  }
  return out.join('\n').trimRight();
}

Widget _messageTimeRow(ChatMessage message, bool isOwnMessage, ThemeData theme) {
  final time = intl.DateFormat('HH.mm').format(message.createdAt);
  if (isOwnMessage) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          '$time  ✓',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            height: 1.2,
          ),
        ),
      ),
    );
  }
  return Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            time,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.brightness == Brightness.dark
                  ? Colors.white70
                  : const Color(0xFF6B6B6B),
              fontSize: 11,
              height: 1.2,
            ),
          ),
        ),
      ),
    ),
  );
}

void _showChatCopiedFeedback(BuildContext messengerContext) {
  ScaffoldMessenger.of(messengerContext).hideCurrentSnackBar();
  ScaffoldMessenger.of(messengerContext).showSnackBar(
    const SnackBar(
      content: Text('Copied to clipboard'),
      duration: Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

Future<void> _copyChatMessageToClipboard(
  BuildContext messengerContext,
  String text,
) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!messengerContext.mounted) return;
  _showChatCopiedFeedback(messengerContext);
}

void _openChatMessageLongPressSheet({
  required BuildContext modalContext,
  required BuildContext snackbarContext,
  required ChatMessage message,
  required ChatUser me,
  required ThemeData theme,
  required TextEditingController inputController,
  required FocusNode inputFocus,
}) {
  final own = message.user.id == me.id;
  showModalBottomSheet<void>(
    context: modalContext,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetCtx) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.copy_rounded,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(sheetCtx);
                unawaited(
                  _copyChatMessageToClipboard(snackbarContext, message.text),
                );
              },
            ),
            if (own)
              ListTile(
                leading: Icon(
                  Icons.edit_rounded,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  inputController.value = TextEditingValue(
                    text: message.text,
                    selection: TextSelection.collapsed(
                      offset: message.text.length,
                    ),
                  );
                  inputFocus.requestFocus();
                },
              ),
          ],
        ),
      );
    },
  );
}

Widget _messageBubbleActionStrip({
  required ChatMessage message,
  required bool isOwn,
  required ThemeData theme,
  required BuildContext snackbarContext,
  required TextEditingController inputController,
  required FocusNode inputFocus,
}) {
  final iconColor = theme.colorScheme.onSurface.withValues(alpha: 0.7);

  Widget smallIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(icon, size: 17, color: iconColor),
          ),
        ),
      ),
    );
  }

  return Material(
    color: theme.colorScheme.surface.withValues(alpha: 0.55),
    borderRadius: BorderRadius.circular(20),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isOwn)
          smallIconButton(
            icon: Icons.edit_outlined,
            tooltip: 'Edit',
            onTap: () {
              inputController.value = TextEditingValue(
                text: message.text,
                selection: TextSelection.collapsed(
                  offset: message.text.length,
                ),
              );
              inputFocus.requestFocus();
            },
          ),
        smallIconButton(
          icon: Icons.copy_rounded,
          tooltip: 'Copy',
          onTap: () => unawaited(
            _copyChatMessageToClipboard(snackbarContext, message.text),
          ),
        ),
      ],
    ),
  );
}

/// Static intro shown above the list when there are no messages (not a chat bubble).
class _WajeehChatWelcomeBanner extends StatelessWidget {
  const _WajeehChatWelcomeBanner({
    required this.theme,
    required this.text,
  });

  final ThemeData theme;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.22),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.45,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

MarkdownStyleSheet markdownStyleForChat(ThemeData theme) {
  final onSurface = theme.colorScheme.onSurface;
  final primary = theme.colorScheme.primary;
  final body = TextStyle(
    fontSize: 15.5,
    height: 1.52,
    color: onSurface,
    fontWeight: FontWeight.w400,
  );
  return MarkdownStyleSheet(
    p: body,
    pPadding: const EdgeInsets.only(bottom: 8),
    h1: body.copyWith(fontSize: 19, fontWeight: FontWeight.w800, height: 1.25),
    h2: body.copyWith(fontSize: 17, fontWeight: FontWeight.w800, height: 1.3),
    h3: body.copyWith(fontSize: 16, fontWeight: FontWeight.w700, height: 1.35),
    strong: body.copyWith(fontWeight: FontWeight.w700, color: primary),
    em: body.copyWith(fontStyle: FontStyle.italic),
    listBullet: body,
    listIndent: 22,
    blockSpacing: 8,
    blockquote: body.copyWith(
      color: theme.brightness == Brightness.dark
          ? Colors.white70
          : const Color(0xFF4A4A4A),
    ),
    code: body.copyWith(
      fontFamily: 'monospace',
      backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.08),
      fontSize: 13.5,
    ),
  );
}

class FloatingAiChatWidget extends StatefulWidget {
  const FloatingAiChatWidget({
    super.key,
    this.geminiApiKey,
    this.openRouteServiceApiKey,
    this.fabBottomReserve = 96,
  });

  final String? geminiApiKey;
  final String? openRouteServiceApiKey;

  /// Extra space above system bottom inset (nav bar, home indicator).
  final double fabBottomReserve;

  @override
  State<FloatingAiChatWidget> createState() => _FloatingAiChatWidgetState();
}

class _FloatingAiChatWidgetState extends State<FloatingAiChatWidget>
    with WidgetsBindingObserver {
  bool _boundSave = false;
  bool _sheetOpen = false;
  double? _fabLeft;
  double? _fabTop;
  bool _fabLoadedFromPrefs = false;
  bool _fabLayoutPending = false;
  bool _fabDidLayoutClamp = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadFabPosition());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final chat = context.read<AiChatService>();
    final key = widget.geminiApiKey?.trim();
    if (key != null && key.isNotEmpty) {
      final ors = widget.openRouteServiceApiKey?.trim();
      chat.configure(
        geminiApiKey: key,
        openRouteServiceApiKey: (ors == null || ors.isEmpty) ? null : ors,
      );
    } else if (!chat.isConfigured) {
      chat.maybeConfigureFromEnvironment();
    }
    if (!_boundSave) {
      _boundSave = true;
      context.read<AiChatService>().bindTripSaveHandler(
            (parsed) async => context
                .read<TravelProvider>()
                .saveAiGeneratedTripFromParsed(parsed),
          );
    }
    context.read<AiChatService>().syncChatUserIdentity(
          authProfileFullName: context.read<AuthProvider>().fullName,
        );
  }

  Future<void> _loadFabPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kFabPosPrefsKey);
      if (raw != null && raw.isNotEmpty) {
        final m = jsonDecode(raw);
        if (m is Map) {
          final l = (m['l'] as num?)?.toDouble();
          final t = (m['t'] as num?)?.toDouble();
          if (l != null && t != null && mounted) {
            setState(() {
              _fabLeft = l;
              _fabTop = t;
              _fabLoadedFromPrefs = true;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('FloatingAiChatWidget._loadFabPosition: $e');
    }
  }

  Future<void> _saveFabPosition() async {
    final l = _fabLeft;
    final t = _fabTop;
    if (l == null || t == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kFabPosPrefsKey,
        jsonEncode(<String, double>{'l': l, 't': t}),
      );
    } catch (e) {
      debugPrint('FloatingAiChatWidget._saveFabPosition: $e');
    }
  }

  Rect _fabSafeRect(Size screen, EdgeInsets padding) {
    final bottom = padding.bottom + widget.fabBottomReserve;
    return Rect.fromLTRB(
      padding.left + 6,
      padding.top + 6,
      screen.width - padding.right - _kFabWidth - 6,
      screen.height - bottom - _kFabHeight - 6,
    );
  }

  void _defaultFabBottomRight(Rect r) {
    _fabLeft = r.right;
    _fabTop = r.bottom;
  }

  /// Returns true if [l],[t] is clearly invalid (off-screen).
  bool _fabNeedsReset(double l, double t, Rect r) {
    return l < r.left - 80 ||
        l > r.right + 80 ||
        t < r.top - 120 ||
        t > r.bottom + 120;
  }

  void _ensureFabInSafeArea(Size screen, EdgeInsets padding) {
    final r = _fabSafeRect(screen, padding);
    if (_fabLeft == null || _fabTop == null) {
      _defaultFabBottomRight(r);
      return;
    }
    if (!_fabLoadedFromPrefs || _fabNeedsReset(_fabLeft!, _fabTop!, r)) {
      _fabLoadedFromPrefs = false;
      _defaultFabBottomRight(r);
    }
    _fabLeft = _fabLeft!.clamp(r.left, r.right);
    _fabTop = _fabTop!.clamp(r.top, r.bottom);
  }

  Future<void> _confirmDeleteHistory(BuildContext sheetContext) async {
    final chat = sheetContext.read<AiChatService>();
    final go = await showDialog<bool>(
          context: sheetContext,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete chat history'),
            content: const Text('Do you want to delete chat history?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!go || !mounted) return;
    await chat.clearChatHistory();
  }

  Future<void> _openChatSheet() async {
    final navContext = wajeehRootNavigatorKey.currentContext;
    if (navContext == null) {
      debugPrint('FloatingAiChatWidget: navigator not ready yet.');
      return;
    }
    setState(() => _sheetOpen = true);
    final themeProvider = Provider.of<ThemeProvider>(navContext, listen: false);
    final theme = Theme.of(navContext);

    final sheetInputController = TextEditingController();
    final sheetInputFocus = FocusNode();

    try {
      await showModalBottomSheet<void>(
        context: navContext,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) {
          return AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(ctx).bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: SafeArea(
                minimum: EdgeInsets.zero,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final orientation = MediaQuery.orientationOf(context);
                    final heightFrac =
                        orientation == Orientation.landscape ? 0.92 : 0.78;
                    final sheetHeight = (constraints.maxHeight * heightFrac)
                        .clamp(280.0, constraints.maxHeight * 0.98);

                    final innerMaxW =
                        constraints.maxWidth.clamp(0.0, double.infinity);
                    final bubbleMaxWidth = (innerMaxW - 24)
                        .clamp(160.0, innerMaxW > 0 ? innerMaxW : 280.0);

                    final sheetBg = theme.colorScheme.surface;
                    final creamTint = theme.brightness == Brightness.light
                        ? const Color(0xFFFFF9F2)
                        : theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.85);
                    final navyUser =
                        theme.brightness == Brightness.dark
                            ? theme.colorScheme.primary
                            : const Color(0xFF1A2B49);
                    final botBubbleBorder = theme.colorScheme.primary;
                    final botBubbleFill = creamTint;

                    return SizedBox(
                      height: sheetHeight,
                      width: double.infinity,
                      child: Material(
                        color: sheetBg,
                        elevation: 16,
                        shadowColor: Colors.black26,
                        clipBehavior: Clip.antiAlias,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Consumer<AiChatService>(
                              builder: (context, chat, _) {
                                if (chat.isConfigured) {
                                  return const SizedBox.shrink();
                                }
                                return Material(
                                  color: theme.colorScheme.errorContainer,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        12, 10, 12, 10),
                                    child: Text(
                                      'Gemini API key is missing. Run with:\n'
                                      'flutter run --dart-define=GEMINI_API_KEY=your_key',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: theme
                                            .colorScheme.onErrorContainer,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            _WajeehChatHeader(
                              theme: theme,
                              isDark: themeProvider.isDarkMode,
                              onBack: () => Navigator.of(ctx).pop(),
                              onDeleteHistory: () =>
                                  _confirmDeleteHistory(ctx),
                            ),
                            Expanded(
                              child: Consumer<AiChatService>(
                                builder: (context, chat, _) {
                                  final typingUsers = chat.isTyping
                                      ? <ChatUser>[chat.wajeeh]
                                      : <ChatUser>[];

                                  return ColoredBox(
                                    color: theme.brightness ==
                                            Brightness.light
                                        ? const Color(0xFFFFF9F2)
                                        : theme.colorScheme.surface,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        if (chat.messages.isEmpty)
                                          _WajeehChatWelcomeBanner(
                                            theme: theme,
                                            text: _localizedAiChatWelcome(
                                              context,
                                              chat.sessionGreetingName,
                                            ),
                                          ),
                                        Expanded(
                                          child: DashChat(
                                  currentUser: chat.me,
                                  typingUsers: typingUsers,
                                  onSend: (m) => chat.sendText(m.text),
                                  messages: chat.messages,
                                  messageListOptions: MessageListOptions(
                                    showDateSeparator: true,
                                    scrollPhysics:
                                        const ClampingScrollPhysics(),
                                    dateSeparatorBuilder: (date) =>
                                        _WajeehDateSeparator(
                                          date: date,
                                          theme: theme,
                                        ),
                                  ),
                                  messageOptions: MessageOptions(
                                    showCurrentUserAvatar: false,
                                    showOtherUsersAvatar: false,
                                    showOtherUsersName: false,
                                    spaceWhenAvatarIsHidden: 8,
                                    maxWidth: bubbleMaxWidth,
                                    borderRadius: 14,
                                    messagePadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    onLongPressMessage: (m) {
                                      _openChatMessageLongPressSheet(
                                        modalContext: context,
                                        snackbarContext: navContext,
                                        message: m,
                                        me: chat.me,
                                        theme: theme,
                                        inputController: sheetInputController,
                                        inputFocus: sheetInputFocus,
                                      );
                                    },
                                    messageTextBuilder: (message, prev, next) {
                                      final own =
                                          message.user.id == chat.me.id;
                                      final Widget inner;
                                      if (own || !message.isMarkdown) {
                                        inner = Text(
                                          message.text,
                                          style: TextStyle(
                                            color: own
                                                ? Colors.white
                                                : theme.colorScheme.onSurface,
                                            fontSize: 15.5,
                                            height: 1.52,
                                          ),
                                        );
                                      } else {
                                        final cleaned =
                                            _cleanMarkdownForChatBubble(
                                          message.text,
                                        );
                                        inner = MarkdownBody(
                                          data: cleaned.isEmpty
                                              ? message.text
                                              : cleaned,
                                          styleSheet:
                                              markdownStyleForChat(theme),
                                          shrinkWrap: true,
                                        );
                                      }
                                      final body = Column(
                                        crossAxisAlignment: own
                                            ? CrossAxisAlignment.end
                                            : CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          inner,
                                          _messageTimeRow(
                                              message, own, theme),
                                        ],
                                      );
                                      return Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 22,
                                            ),
                                            child: body,
                                          ),
                                          Positioned(
                                            top: 0,
                                            right: own ? 0 : null,
                                            left: own ? null : 0,
                                            child: _messageBubbleActionStrip(
                                              message: message,
                                              isOwn: own,
                                              theme: theme,
                                              snackbarContext: navContext,
                                              inputController:
                                                  sheetInputController,
                                              inputFocus: sheetInputFocus,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                    markdownStyleSheet:
                                        markdownStyleForChat(theme),
                                    currentUserContainerColor: navyUser,
                                    currentUserTextColor: Colors.white,
                                    currentUserTimeTextColor: Colors.white70,
                                    containerColor: botBubbleFill,
                                    textColor: theme.colorScheme.onSurface,
                                    timeTextColor: theme.brightness ==
                                            Brightness.dark
                                        ? Colors.white70
                                        : const Color(0xFF6B6B6B),
                                    timeFontSize: 11,
                                    showTime: false,
                                    messageDecorationBuilder: (message,
                                        previousMessage, nextMessage) {
                                      final own =
                                          message.user.id == chat.me.id;
                                      if (own) {
                                        return defaultMessageDecoration(
                                          color: navyUser,
                                          borderTopLeft: 14,
                                          borderTopRight: 14,
                                          borderBottomLeft: 14,
                                          borderBottomRight: 14,
                                        );
                                      }
                                      return BoxDecoration(
                                        color: botBubbleFill,
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        border: Border.all(
                                          color: botBubbleBorder,
                                          width: 1.2,
                                        ),
                                      );
                                    },
                                  ),
                                  inputOptions: InputOptions(
                                    textController: sheetInputController,
                                    focusNode: sheetInputFocus,
                                    alwaysShowSend: true,
                                    inputToolbarPadding:
                                        const EdgeInsets.fromLTRB(8, 8, 8, 8),
                                    inputToolbarMargin: EdgeInsets.zero,
                                    inputToolbarStyle: const BoxDecoration(
                                      color: Colors.transparent,
                                    ),
                                    inputDecoration: InputDecoration(
                                      hintText: 'Type here...',
                                      hintStyle: TextStyle(
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.45),
                                        fontSize: 15,
                                        height: 1.35,
                                      ),
                                      filled: true,
                                      fillColor: theme.brightness ==
                                              Brightness.dark
                                          ? theme.colorScheme
                                              .surfaceContainerHighest
                                          : Colors.white,
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: theme.colorScheme.outline
                                              .withValues(alpha: 0.25),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: theme.colorScheme.primary,
                                          width: 1.2,
                                        ),
                                      ),
                                    ),
                                    inputTextStyle: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                      fontSize: 15,
                                      height: 1.35,
                                    ),
                                    sendButtonBuilder: (onSend) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(left: 6),
                                        child: Material(
                                          color: navyUser,
                                          shape: const CircleBorder(),
                                          child: InkWell(
                                            customBorder: const CircleBorder(),
                                            onTap: onSend,
                                            child: const Padding(
                                              padding: EdgeInsets.all(10),
                                              child: Icon(
                                                Icons.send_rounded,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      );
    } finally {
      sheetInputController.dispose();
      sheetInputFocus.dispose();
      if (mounted) setState(() => _sheetOpen = false);
    }
  }

  @override
  void didChangeMetrics() {
    _fabDidLayoutClamp = false;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final mq = MediaQuery.of(context);
    final screen = mq.size;
    final padding = mq.padding;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (_fabLeft == null || _fabTop == null) {
          if (!_fabLayoutPending) {
            _fabLayoutPending = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fabLayoutPending = false;
              if (!mounted) return;
              final mq = MediaQuery.of(context);
              setState(() {
                _ensureFabInSafeArea(mq.size, mq.padding);
              });
            });
          }
          return const SizedBox.shrink();
        }

        final left = _fabLeft!;
        final top = _fabTop!;

        if (!_fabDidLayoutClamp) {
          _fabDidLayoutClamp = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _fabLeft == null || _fabTop == null) return;
            final mq = MediaQuery.of(context);
            final beforeL = _fabLeft;
            final beforeT = _fabTop;
            setState(() {
              _ensureFabInSafeArea(mq.size, mq.padding);
            });
            if (beforeL != _fabLeft || beforeT != _fabTop) {
              unawaited(_saveFabPosition());
            }
          });
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (!_sheetOpen)
              Positioned(
                left: left,
                top: top,
                child: _WajeehChatPillButton(
                  isDark: themeProvider.isDarkMode,
                  theme: Theme.of(context),
                  onOpen: _openChatSheet,
                  onDragDelta: (dx, dy) {
                    final r = _fabSafeRect(screen, padding);
                    setState(() {
                      _fabLeft = (_fabLeft! + dx).clamp(r.left, r.right);
                      _fabTop = (_fabTop! + dy).clamp(r.top, r.bottom);
                    });
                  },
                  onDragEndSave: _saveFabPosition,
                  dragSlop: _kFabTouchSlop,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _WajeehChatPillButton extends StatefulWidget {
  const _WajeehChatPillButton({
    required this.isDark,
    required this.theme,
    required this.onOpen,
    required this.onDragDelta,
    required this.onDragEndSave,
    required this.dragSlop,
  });

  final bool isDark;
  final ThemeData theme;
  final VoidCallback onOpen;
  final void Function(double dx, double dy) onDragDelta;
  final VoidCallback onDragEndSave;
  final double dragSlop;

  @override
  State<_WajeehChatPillButton> createState() => _WajeehChatPillButtonState();
}

class _WajeehChatPillButtonState extends State<_WajeehChatPillButton> {
  double _panAccum = 0;

  @override
  Widget build(BuildContext context) {
    final primary = widget.theme.colorScheme.primary;
    final onSurface = widget.theme.colorScheme.onSurface;
    final surface = widget.theme.colorScheme.surface;
    final pillBg = widget.isDark ? surface.withValues(alpha: 0.92) : Colors.white;
    final titleColor = widget.isDark ? onSurface : const Color(0xFF1A2B49);
    final subtitleColor = primary;

    return GestureDetector(
      onPanStart: (_) {
        _panAccum = 0;
      },
      onPanUpdate: (details) {
        _panAccum += details.delta.distance;
        if (_panAccum > widget.dragSlop) {
          widget.onDragDelta(details.delta.dx, details.delta.dy);
        }
      },
      onPanEnd: (_) {
        if (_panAccum <= widget.dragSlop) {
          widget.onOpen();
        } else {
          widget.onDragEndSave();
        }
        _panAccum = 0;
      },
      child: Material(
        elevation: 10,
        shadowColor: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        color: pillBg,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PillAvatar(isDark: widget.isDark, theme: widget.theme),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 130),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Wajeeh Chatbot',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: titleColor,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Online',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillAvatar extends StatelessWidget {
  const _PillAvatar({required this.isDark, required this.theme});

  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;
    final navy = theme.brightness == Brightness.dark
        ? theme.colorScheme.surface
        : const Color(0xFF1A2B49);
    final fill = isDark ? primary : navy;
    final iconColor = isDark ? navy : Colors.white;

    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: fill,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_rounded,
                color: iconColor,
                size: 26,
              ),
            ),
          ),
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: _kOnlineGreen,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? theme.colorScheme.surface.withValues(alpha: 0.92)
                      : Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WajeehChatHeader extends StatelessWidget {
  const _WajeehChatHeader({
    required this.theme,
    required this.isDark,
    required this.onBack,
    required this.onDeleteHistory,
  });

  final ThemeData theme;
  final bool isDark;
  final VoidCallback onBack;
  final VoidCallback onDeleteHistory;

  @override
  Widget build(BuildContext context) {
    final bg = theme.colorScheme.surface;
    final titleColor =
        isDark ? theme.colorScheme.onSurface : const Color(0xFF1A2B49);

    return Material(
      color: bg,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 12, 10),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: theme.colorScheme.onSurface,
                size: 20,
              ),
              tooltip: 'Back',
            ),
            _PillAvatar(isDark: isDark, theme: theme),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wajeeh Chatbot',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                      color: titleColor,
                    ),
                  ),
                  Text(
                    'Online',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDeleteHistory,
              icon: Icon(
                Icons.delete_outline_rounded,
                color: theme.colorScheme.onSurface,
              ),
              tooltip: 'Delete chat history',
            ),
          ],
        ),
      ),
    );
  }
}

class _WajeehDateSeparator extends StatelessWidget {
  const _WajeehDateSeparator({required this.date, required this.theme});

  final DateTime date;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final label = isToday ? 'Today' : intl.DateFormat.yMMMd().format(date);
    final lineColor = theme.colorScheme.onSurface.withValues(alpha: 0.22);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        children: [
          Expanded(child: Divider(height: 1, color: lineColor)),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Expanded(child: Divider(height: 1, color: lineColor)),
        ],
      ),
    );
  }
}
