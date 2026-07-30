import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncy/controllers/room_controller.dart';
import 'package:syncy/models/room_preset.dart';

class SessionScorecard extends StatefulWidget {
  const SessionScorecard({
    super.key,
    required this.controller,
    required this.onClose,
  });

  final RoomController controller;
  final VoidCallback onClose;

  @override
  State<SessionScorecard> createState() => _SessionScorecardState();
}

class _SessionScorecardState extends State<SessionScorecard> {
  int? _selectedRating;

  @override
  Widget build(BuildContext context) {
    final preset = widget.controller.room.value.mode.preset;
    return Material(
      color: const Color(0xF20B0613),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Obx(() {
                final ratings = widget.controller.ratings.values;
                final average = ratings.isEmpty
                    ? null
                    : ratings.reduce((a, b) => a + b) / ratings.length;
                final moment = widget.controller.crowdFavoriteMoment;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: preset.accent,
                      size: 42,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Watch party complete',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.controller.room.value.currentVideoTitle ??
                          'That movie',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white60),
                    ),
                    const SizedBox(height: 22),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _StatTile(
                          icon: Icons.favorite_rounded,
                          value: widget.controller.mostUsedReaction,
                          label: 'Most used',
                          accent: preset.accent,
                        ),
                        _StatTile(
                          icon: Icons.forum_rounded,
                          value: widget.controller.biggestChatter,
                          label: 'Biggest chatter',
                          accent: preset.accent,
                        ),
                        _StatTile(
                          icon: Icons.bookmark_rounded,
                          value: moment == null ? 'No marker' : _format(moment),
                          label: 'Crowd favorite',
                          accent: preset.accent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      average == null
                          ? 'What did the room think?'
                          : 'Room average · ${average.toStringAsFixed(1)} / 5',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var star = 1; star <= 5; star++)
                          IconButton(
                            onPressed: () {
                              setState(() => _selectedRating = star);
                              widget.controller.submitRating(star);
                            },
                            icon: Icon(
                              star <= (_selectedRating ?? 0)
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: preset.accent,
                              size: 32,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: widget.onClose,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: preset.accent.withValues(alpha: .5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text('Back to room'),
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

  String _format(Duration value) {
    final minutes = value.inMinutes;
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 142,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: accent.withValues(alpha: .2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: accent, size: 21),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .45),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
