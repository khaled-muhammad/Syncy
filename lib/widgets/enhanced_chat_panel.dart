import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncy/controllers/room_controller.dart';
import 'package:syncy/models/room.dart';

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
  void dispose() {
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
    final coupleMode = controller.room.value.mode == RoomMode.couple;
    final accent = coupleMode
        ? const Color(0xFFFF6FAE)
        : const Color(0xFF9A72FF);
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
                  child: Icon(
                    coupleMode
                        ? Icons.favorite_outline_rounded
                        : Icons.forum_outlined,
                    color: accent,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coupleMode ? 'Our chat' : 'Room chat',
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
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _scrollToLatest(),
              );
              if (messages.isEmpty) {
                return _EmptyChat(coupleMode: coupleMode, accent: accent);
              }
              return ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return _MessageBubble(
                    message: message['message']?.toString() ?? '',
                    userName: message['userName']?.toString() ?? 'Unknown',
                    timestamp: message['timestamp']?.toString(),
                    isMine:
                        message['userId']?.toString() ==
                        controller.currentUserId,
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
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: coupleMode
                          ? 'Say something sweet…'
                          : 'Message everyone…',
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
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.coupleMode, required this.accent});

  final bool coupleMode;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              coupleMode ? Icons.favorite_rounded : Icons.waving_hand_rounded,
              color: accent.withValues(alpha: .8),
              size: 30,
            ),
            const SizedBox(height: 10),
            Text(
              coupleMode ? 'Start your private moment' : 'Break the silence',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
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
    required this.accent,
  });

  final String message;
  final String userName;
  final String? timestamp;
  final bool isMine;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final parsedTime = DateTime.tryParse(timestamp ?? '')?.toLocal();
    final timeLabel = parsedTime == null
        ? ''
        : '${parsedTime.hour.toString().padLeft(2, '0')}:${parsedTime.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              radius: 13,
              backgroundColor: accent.withValues(alpha: .2),
              child: Text(
                userName.isEmpty ? '?' : userName[0].toUpperCase(),
                style: TextStyle(color: accent, fontSize: 11),
              ),
            ),
            const SizedBox(width: 7),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMine)
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
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMine ? 16 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 16),
                    ),
                  ),
                  child: Text(message),
                ),
                if (timeLabel.isNotEmpty)
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
