import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';

import '../app_navigator_key.dart';
import '../providers/ai_chat_service.dart';
import '../providers/theme_provider.dart';

MarkdownStyleSheet _markdownStyleForBotBubble(ThemeData theme) {
  final scheme = theme.colorScheme;
  final body = TextStyle(
    fontSize: 15.5,
    height: 1.52,
    color: scheme.onSurface,
    fontWeight: FontWeight.w400,
  );
  return MarkdownStyleSheet(
    p: body,
    pPadding: const EdgeInsets.only(bottom: 8),
    h1: body.copyWith(fontSize: 19, fontWeight: FontWeight.w800, height: 1.25),
    h2: body.copyWith(fontSize: 17, fontWeight: FontWeight.w800, height: 1.3),
    h3: body.copyWith(fontSize: 16, fontWeight: FontWeight.w700, height: 1.35),
    strong: body.copyWith(fontWeight: FontWeight.w700, color: scheme.primary),
    em: body.copyWith(fontStyle: FontStyle.italic),
    listBullet: body,
    listIndent: 22,
    blockSpacing: 8,
    blockquote: body.copyWith(color: scheme.onSurface.withValues(alpha: 0.8)),
    code: body.copyWith(
      fontFamily: 'monospace',
      backgroundColor: scheme.onSurface.withValues(alpha: 0.06),
      fontSize: 13.5,
    ),
  );
}

class FloatingAiChatWidget extends StatefulWidget {
  const FloatingAiChatWidget({
    super.key,
    this.geminiApiKey,
    this.openRouteServiceApiKey,
  });

  final String? geminiApiKey;
  final String? openRouteServiceApiKey;

  @override
  State<FloatingAiChatWidget> createState() => _FloatingAiChatWidgetState();
}

class _FloatingAiChatWidgetState extends State<FloatingAiChatWidget> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final key = widget.geminiApiKey?.trim();
    if (key != null && key.isNotEmpty) {
      final ors = widget.openRouteServiceApiKey?.trim();
      context.read<AiChatService>().configure(
        geminiApiKey: key,
        openRouteServiceApiKey: (ors == null || ors.isEmpty) ? null : ors,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return _WajeehChatPillButton(
      isDark: themeProvider.isDarkMode,
      onTap: _openChatSheet,
    );
  }

  Future<void> _openChatSheet() async {
    final navContext = wajeehRootNavigatorKey.currentContext;
    if (navContext == null) {
      debugPrint('FloatingAiChatWidget: navigator not ready yet.');
      return;
    }
    final themeProvider = Provider.of<ThemeProvider>(navContext, listen: false);
    final theme = Theme.of(navContext);

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
        return LayoutBuilder(
          builder: (context, constraints) {
            final orientation = MediaQuery.orientationOf(context);
            final heightFrac =
                orientation == Orientation.landscape ? 0.92 : 0.78;
            final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
            final availableHeight =
                (constraints.maxHeight - keyboardInset).clamp(0.0, constraints.maxHeight);
            final sheetHeight = (availableHeight * heightFrac)
                .clamp(280.0, availableHeight * 0.98);

            const edgePad = 12.0;
            final innerMaxW = (constraints.maxWidth - edgePad * 2)
                .clamp(0.0, double.infinity);
            // dash_chat_2 adds hidden avatar gutters (~10 each side) inside rows.
            final bubbleMaxWidth =
                (innerMaxW - 24).clamp(160.0, innerMaxW > 0 ? innerMaxW : 280.0);

            final scheme = Theme.of(context).colorScheme;
            final sheetBg = scheme.surface;

            return AnimatedPadding(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.only(bottom: keyboardInset),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: edgePad),
                child: SizedBox(
                  height: sheetHeight,
                  width: double.infinity,
                  child: Material(
                    color: sheetBg,
                    elevation: 16,
                    shadowColor: Colors.black26,
                    clipBehavior: Clip.antiAlias,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
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
                                padding:
                                    const EdgeInsets.fromLTRB(12, 10, 12, 10),
                                child: Text(
                                  'Gemini API key is missing. Run with:\n'
                                  'flutter run --dart-define=GEMINI_API_KEY=your_key',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onErrorContainer,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        _WajeehChatHeader(
                          isDark: themeProvider.isDarkMode,
                          onBack: () => Navigator.of(ctx).pop(),
                          onDeleteHistory: () async {
                            final chat = context.read<AiChatService>();
                            final ok = await showDialog<bool>(
                              context: ctx,
                              builder: (dCtx) {
                                final t = Theme.of(dCtx);
                                return AlertDialog(
                                  title: const Text('Delete chat history'),
                                  content: const Text(
                                    'Do you want to delete chat history?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(dCtx).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.of(dCtx).pop(true),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: t.colorScheme.error,
                                        foregroundColor:
                                            t.colorScheme.onError,
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                );
                              },
                            );
                            if (ok == true) {
                              await chat.clearChatHistory();
                            }
                          },
                        ),
                        Expanded(
                          child: Consumer<AiChatService>(
                            builder: (context, chat, _) {
                              final typingUsers = chat.isTyping
                                  ? <ChatUser>[chat.wajeeh]
                                  : <ChatUser>[];

                              return ColoredBox(
                                color: sheetBg,
                                child: DashChat(
                                  currentUser: chat.me,
                                  typingUsers: typingUsers,
                                  onSend: (m) => chat.sendText(m.text),
                                  messages: chat.messages,
                                  messageListOptions: MessageListOptions(
                                    showDateSeparator: true,
                                    scrollPhysics:
                                        const AlwaysScrollableScrollPhysics(
                                      parent: ClampingScrollPhysics(),
                                    ),
                                    dateSeparatorBuilder: (date) =>
                                        _WajeehDateSeparator(date: date),
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
                                    markdownStyleSheet:
                                        _markdownStyleForBotBubble(theme),
                                    currentUserContainerColor: scheme.primary,
                                    currentUserTextColor: scheme.onPrimary,
                                    currentUserTimeTextColor:
                                        scheme.onPrimary.withValues(alpha: 0.8),
                                    containerColor: scheme.surface,
                                    textColor: scheme.onSurface,
                                    timeTextColor:
                                        scheme.onSurface.withValues(alpha: 0.7),
                                    timeFontSize: 11,
                                    showTime: true,
                                    messageDecorationBuilder: (message,
                                        previousMessage, nextMessage) {
                                      final own =
                                          message.user.id == chat.me.id;
                                      if (own) {
                                        return defaultMessageDecoration(
                                          color: scheme.primary,
                                          borderTopLeft: 14,
                                          borderTopRight: 14,
                                          borderBottomLeft: 14,
                                          borderBottomRight: 14,
                                        );
                                      }
                                      return BoxDecoration(
                                        color: scheme.surface,
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        border: Border.all(
                                          color: scheme.secondary
                                              .withValues(alpha: 0.75),
                                          width: 1.1,
                                        ),
                                      );
                                    },
                                    messageTimeBuilder:
                                        (message, isOwnMessage) {
                                      final time = intl.DateFormat('HH.mm')
                                          .format(message.createdAt);
                                      if (isOwnMessage) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 6),
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              '$time  ✓',
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: scheme.onPrimary
                                                    .withValues(alpha: 0.8),
                                                fontSize: 11,
                                                height: 1.2,
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(top: 6),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: scheme.surface
                                                  .withValues(alpha: 0.92),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: scheme.onSurface
                                                    .withValues(alpha: 0.08),
                                              ),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              child: Text(
                                                time,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: scheme.onSurface
                                                      .withValues(alpha: 0.7),
                                                  fontSize: 11,
                                                  height: 1.2,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  inputOptions: InputOptions(
                                    alwaysShowSend: true,
                                    inputToolbarPadding:
                                        EdgeInsets.fromLTRB(
                                      8,
                                      8,
                                      8,
                                      10 + MediaQuery.paddingOf(context).bottom,
                                    ),
                                    inputToolbarMargin: EdgeInsets.zero,
                                    inputToolbarStyle: const BoxDecoration(
                                      color: Colors.transparent,
                                    ),
                                    inputDecoration: InputDecoration(
                                      hintText: 'Type here...',
                                      hintStyle: TextStyle(
                                        color: scheme.onSurface
                                            .withValues(alpha: 0.55),
                                        fontSize: 15,
                                        height: 1.35,
                                      ),
                                      filled: true,
                                      fillColor: scheme.surface,
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
                                          color: scheme.onSurface
                                              .withValues(alpha: 0.10),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: scheme.primary,
                                          width: 1.2,
                                        ),
                                      ),
                                    ),
                                    inputTextStyle: TextStyle(
                                      color: scheme.onSurface,
                                      fontSize: 15,
                                      height: 1.35,
                                    ),
                                    sendButtonBuilder: (onSend) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(left: 6),
                                        child: Material(
                                          color: scheme.primary,
                                          shape: const CircleBorder(),
                                          child: InkWell(
                                            customBorder:
                                                const CircleBorder(),
                                            onTap: onSend,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(10),
                                              child: Icon(
                                                Icons.send_rounded,
                                                color: scheme.onPrimary,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Pill-shaped floating entry (reference: white bar + avatar + title + Online).
/// Pill-shaped floating entry.
class _WajeehChatPillButton extends StatelessWidget {
  const _WajeehChatPillButton({
    required this.isDark,
    required this.onTap,
  });

  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pillBg = scheme.surface;
    final titleColor = scheme.onSurface;
    final subtitleColor = scheme.secondary;

    return IntrinsicWidth(
      child: Material(
        elevation: 10,
        shadowColor: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        color: pillBg,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PillAvatar(isDark: isDark),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 130,
                  ),
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
      ),
    );
  }
}

class _PillAvatar extends StatelessWidget {
  const _PillAvatar({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = scheme.primary;
    final iconColor = scheme.onPrimary;

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
                color: scheme.secondary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: scheme.surface,
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
    required this.isDark,
    required this.onBack,
    required this.onDeleteHistory,
  });

  final bool isDark;
  final VoidCallback onBack;
  final VoidCallback onDeleteHistory;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = scheme.surface;
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
                color: scheme.onSurface,
                size: 20,
              ),
              tooltip: 'Back',
            ),
            _PillAvatar(isDark: isDark),
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
                      color: scheme.onSurface,
                    ),
                  ),
                  Text(
                    'Online',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: scheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDeleteHistory,
              tooltip: 'Delete history',
              icon: Icon(
                Icons.delete_outline_rounded,
                color: scheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WajeehDateSeparator extends StatelessWidget {
  const _WajeehDateSeparator({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final label = isToday ? 'Today' : intl.DateFormat.yMMMd().format(date);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              height: 1,
              color: scheme.onSurface.withValues(alpha: 0.25),
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Expanded(
            child: Divider(
              height: 1,
              color: scheme.onSurface.withValues(alpha: 0.25),
            ),
          ),
        ],
      ),
    );
  }
}
