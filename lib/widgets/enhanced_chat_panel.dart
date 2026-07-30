import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncy/controllers/room_controller.dart';
import 'package:syncy/models/room_preset.dart';

class ChatPanel extends StatefulWidget {
  const ChatPanel({super.key});

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final RoomController controller = Get.find<RoomController>();
  final TextEditingController _text = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (!_focus.hasFocus) controller.stopTyping();
  }

  @override
  void dispose() {
    controller.stopTyping();
    _focus.removeListener(_handleFocusChange);
    _text.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send() {
    final value = _text.text.trim();
    if (value.isEmpty) return;
    controller.sendChatMessage(value);
    _text.clear();
    controller.chatInputChanged('');
    setState(() {});
  }

  void _scrollToLatest() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final preset = controller.room.value.mode.preset;
    final accent = preset.accent;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF100B19).withValues(alpha: .9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: .1)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 12, 11),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(preset.icon, color: accent, size: 19),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preset.chatTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Obx(
                        () => Text(
                          controller.wsService.isJoined.value
                              ? '${controller.users.where((user) => user.online).length} online'
                              : 'Messages will send after reconnecting',
                          style: TextStyle(
                            color: controller.wsService.isJoined.value
                                ? Colors.white54
                                : const Color(0xFFFFC857),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.white.withValues(alpha: .08)),
          Expanded(
            child: Obx(() {
              final messages = controller.chatMessages;
              final typingNames = controller.typingUserNames;
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _scrollToLatest(),
              );
              if (messages.isEmpty && typingNames.isEmpty) {
                return _EmptyChat(
                  title: preset.emptyChatTitle,
                  icon: preset.icon,
                  accent: accent,
                );
              }
              return ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
                itemCount: messages.length + (typingNames.isEmpty ? 0 : 1),
                itemBuilder: (context, index) {
                  if (index == messages.length) {
                    return _TypingIndicator(names: typingNames, accent: accent);
                  }
                  final message = messages[index];
                  final isMine =
                      message['userId']?.toString() == controller.currentUserId;
                  final previous = index > 0 ? messages[index - 1] : null;
                  final next = index + 1 < messages.length
                      ? messages[index + 1]
                      : null;
                  final followsSameSender =
                      previous != null && _sameSender(previous, message);
                  final hasSameSenderAfter =
                      next != null && _sameSender(message, next);
                  return _MessageBubble(
                    message: message['message']?.toString() ?? '',
                    userName: message['userName']?.toString() ?? 'Unknown',
                    timestamp: message['timestamp']?.toString(),
                    isMine: isMine,
                    followsSameSender: followsSameSender,
                    hasSameSenderAfter: hasSameSenderAfter,
                    showSenderIdentity: !isMine && !hasSameSenderAfter,
                    accent: accent,
                  );
                },
              );
            }),
          ),
          Divider(height: 1, color: Colors.white.withValues(alpha: .08)),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 9, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    focusNode: _focus,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 500,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.newline,
                    onChanged: (value) {
                      controller.chatInputChanged(value);
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: preset.chatHint,
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: .07),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 11,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: _text.text.trim().isEmpty
                        ? Colors.white.withValues(alpha: .08)
                        : accent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: IconButton(
                    tooltip: 'Send message',
                    onPressed: _text.text.trim().isEmpty ? null : _send,
                    icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _sameSender(Map<String, dynamic> first, Map<String, dynamic> second) {
    final firstId = first['userId']?.toString() ?? '';
    final secondId = second['userId']?.toString() ?? '';
    if (firstId.isNotEmpty && secondId.isNotEmpty) return firstId == secondId;
    return first['userName']?.toString() == second['userName']?.toString();
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({
    required this.title,
    required this.icon,
    required this.accent,
  });

  final String title;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: accent.withValues(alpha: .8), size: 30),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text(
              'New messages and recent history stay synced.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.userName,
    required this.timestamp,
    required this.isMine,
    required this.followsSameSender,
    required this.hasSameSenderAfter,
    required this.showSenderIdentity,
    required this.accent,
  });

  final String message;
  final String userName;
  final String? timestamp;
  final bool isMine;
  final bool followsSameSender;
  final bool hasSameSenderAfter;
  final bool showSenderIdentity;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final parsedTime = DateTime.tryParse(timestamp ?? '')?.toLocal();
    final timeLabel = parsedTime == null
        ? ''
        : '${parsedTime.hour.toString().padLeft(2, '0')}:${parsedTime.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: EdgeInsets.only(
        top: followsSameSender ? 0 : 4,
        bottom: hasSameSenderAfter ? 3 : 10,
      ),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            SizedBox(
              width: 26,
              child: showSenderIdentity
                  ? CircleAvatar(
                      radius: 13,
                      backgroundColor: accent.withValues(alpha: .2),
                      child: Text(
                        userName.isEmpty ? '?' : userName[0].toUpperCase(),
                        style: TextStyle(color: accent, fontSize: 11),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 7),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (showSenderIdentity)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 3),
                    child: Text(
                      userName,
                      style: TextStyle(
                        color: accent.withValues(alpha: .9),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: isMine
                        ? accent.withValues(alpha: .82)
                        : Colors.white.withValues(alpha: .08),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(
                        !isMine && followsSameSender ? 5 : 16,
                      ),
                      topRight: Radius.circular(
                        isMine && followsSameSender ? 5 : 16,
                      ),
                      bottomLeft: Radius.circular(
                        !isMine && hasSameSenderAfter ? 5 : 16,
                      ),
                      bottomRight: Radius.circular(
                        isMine && hasSameSenderAfter ? 5 : 16,
                      ),
                    ),
                  ),
                  child: Text(message),
                ),
                if (timeLabel.isNotEmpty && !hasSameSenderAfter)
                  Padding(
                    padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                    child: Text(
                      timeLabel,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 9,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator({required this.names, required this.accent});

  final List<String> names;
  final Color accent;

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  String get _label {
    if (widget.names.length == 1) return '${widget.names.first} is typing';
    if (widget.names.length == 2) {
      return '${widget.names.first} and ${widget.names.last} are typing';
    }
    return 'Several people are typing';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: _label,
      child: Padding(
        padding: const EdgeInsets.only(left: 33, top: 2, bottom: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    final phase =
                        (_animation.value - index * .14) * 2 * math.pi;
                    final opacity = .25 + ((math.sin(phase) + 1) * .375);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: widget.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
