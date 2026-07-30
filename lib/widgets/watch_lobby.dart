import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncy/controllers/room_controller.dart';
import 'package:syncy/models/room_preset.dart';

class WatchLobby extends StatefulWidget {
  const WatchLobby({
    super.key,
    required this.controller,
    required this.onStart,
  });

  final RoomController controller;
  final VoidCallback onStart;

  @override
  State<WatchLobby> createState() => _WatchLobbyState();
}

class _WatchLobbyState extends State<WatchLobby> {
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 80), (_) {
      final endsAt = widget.controller.countdownEndsAt.value;
      if (endsAt == null) {
        if (_remaining != Duration.zero && mounted) {
          setState(() => _remaining = Duration.zero);
        }
        return;
      }
      final next = endsAt.difference(DateTime.now());
      if (mounted)
        setState(() => _remaining = next.isNegative ? Duration.zero : next);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preset = widget.controller.room.value.mode.preset;
    return Material(
      color: const Color(0xF20B0613),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Obx(() {
                final users = widget.controller.users;
                final countdown =
                    widget.controller.countdownEndsAt.value != null;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedScale(
                      scale: countdown ? 1.08 : 1,
                      duration: const Duration(milliseconds: 250),
                      child: _LobbyPoster(
                        path: widget.controller.currentMediaPath,
                        title: widget.controller.room.value.currentVideoTitle,
                        accent: preset.accent,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      countdown
                          ? (_remaining.inMilliseconds <= 0
                                ? 'GO!'
                                : '${(_remaining.inMilliseconds / 1000).ceil()}')
                          : 'Everyone is here?',
                      style: TextStyle(
                        color: preset.accent,
                        fontSize: countdown ? 58 : 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: countdown ? 1 : -.5,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      countdown
                          ? 'Syncy is lining up the first frame'
                          : '${widget.controller.room.value.name} · ${preset.label}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white60),
                    ),
                    const SizedBox(height: 22),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final user in users)
                          _LobbyParticipant(
                            name: user.name,
                            online: user.online,
                            accent: preset.accent,
                          ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    if (widget.controller.isHost && !countdown)
                      FilledButton.icon(
                        onPressed: widget.onStart,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Start watch party'),
                        style: FilledButton.styleFrom(
                          backgroundColor: preset.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                      )
                    else if (!countdown)
                      const Text(
                        'Waiting for the host to start…',
                        style: TextStyle(color: Colors.white54),
                      ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _LobbyPoster extends StatelessWidget {
  const _LobbyPoster({
    required this.path,
    required this.title,
    required this.accent,
  });

  final String? path;
  final String? title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final hasFile =
        path != null && path!.isNotEmpty && File(path!).existsSync();
    return Container(
      width: 148,
      height: 198,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: .4),
            blurRadius: 34,
            spreadRadius: 4,
          ),
        ],
      ),
      child: hasFile
          ? Image.file(File(path!), fit: BoxFit.cover)
          : DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [accent, const Color(0xFF150A21)],
                ),
              ),
              child: const Icon(
                Icons.movie_creation_outlined,
                size: 56,
                color: Colors.white60,
              ),
            ),
    );
  }
}

class _LobbyParticipant extends StatelessWidget {
  const _LobbyParticipant({
    required this.name,
    required this.online,
    required this.accent,
  });

  final String name;
  final bool online;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: online ? .1 : .04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: online ? accent.withValues(alpha: .48) : Colors.white12,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: accent.withValues(alpha: .75),
            child: Text(
              name.isEmpty ? '?' : name[0].toUpperCase(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
          const SizedBox(width: 6),
          Icon(
            online ? Icons.circle : Icons.circle_outlined,
            size: 9,
            color: online ? const Color(0xFF55D6A7) : Colors.white30,
          ),
        ],
      ),
    );
  }
}
