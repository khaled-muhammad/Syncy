import 'package:flutter/material.dart';
import 'package:syncy/models/room.dart';

enum ReactionMotion { float, hearts, burst, shiver, bounce, spotlight }

@immutable
class RoomPreset {
  const RoomPreset({
    required this.mode,
    required this.label,
    required this.tagline,
    required this.icon,
    required this.accent,
    required this.secondary,
    required this.reactions,
    required this.chatTitle,
    required this.chatHint,
    required this.emptyChatTitle,
    required this.motion,
  });

  final RoomMode mode;
  final String label;
  final String tagline;
  final IconData icon;
  final Color accent;
  final Color secondary;
  final List<String> reactions;
  final String chatTitle;
  final String chatHint;
  final String emptyChatTitle;
  final ReactionMotion motion;
}

const roomPresets = <RoomPreset>[
  RoomPreset(
    mode: RoomMode.friends,
    label: 'Friends',
    tagline: 'Easygoing reactions and group chat',
    icon: Icons.groups_2_rounded,
    accent: Color(0xFF9A72FF),
    secondary: Color(0xFF5A3ED1),
    reactions: ['😂', '🔥', '😮', '👏', '👍', '🎉'],
    chatTitle: 'Room chat',
    chatHint: 'Message everyone…',
    emptyChatTitle: 'Break the silence',
    motion: ReactionMotion.float,
  ),
  RoomPreset(
    mode: RoomMode.couple,
    label: 'Couple',
    tagline: 'A softer space for date night',
    icon: Icons.favorite_rounded,
    accent: Color(0xFFFF6FAE),
    secondary: Color(0xFFB73B78),
    reactions: ['❤️', '😘', '🥰', '💋', '🌹', '🫶'],
    chatTitle: 'Our chat',
    chatHint: 'Say something sweet…',
    emptyChatTitle: 'Start your private moment',
    motion: ReactionMotion.hearts,
  ),
  RoomPreset(
    mode: RoomMode.party,
    label: 'Party',
    tagline: 'Confetti, hype, and maximum energy',
    icon: Icons.celebration_rounded,
    accent: Color(0xFFFFC857),
    secondary: Color(0xFFFF6B35),
    reactions: ['🎉', '🥳', '🔥', '🕺', '💃', '📣'],
    chatTitle: 'Party chat',
    chatHint: 'Bring the noise…',
    emptyChatTitle: 'Start the party',
    motion: ReactionMotion.burst,
  ),
  RoomPreset(
    mode: RoomMode.horror,
    label: 'Horror',
    tagline: 'Dark atmosphere and scare reactions',
    icon: Icons.visibility_rounded,
    accent: Color(0xFFFF4D6D),
    secondary: Color(0xFF650D1B),
    reactions: ['😱', '🫣', '💀', '🩸', '👻', '🚪'],
    chatTitle: 'Survivors chat',
    chatHint: 'Did you hear that?…',
    emptyChatTitle: 'It is quiet. Too quiet.',
    motion: ReactionMotion.shiver,
  ),
  RoomPreset(
    mode: RoomMode.roast,
    label: 'Roast',
    tagline: 'For plot armor and cinematic crimes',
    icon: Icons.local_fire_department_rounded,
    accent: Color(0xFFFF715F),
    secondary: Color(0xFFA93324),
    reactions: ['🤡', '🗿', '💀', '🍅', '🚨', '🫠'],
    chatTitle: 'The roast',
    chatHint: 'Question every creative decision…',
    emptyChatTitle: 'The movie is getting away with it',
    motion: ReactionMotion.bounce,
  ),
  RoomPreset(
    mode: RoomMode.movieClub,
    label: 'Movie Club',
    tagline: 'Thoughtful chat and post-watch ratings',
    icon: Icons.local_movies_rounded,
    accent: Color(0xFF55D6A7),
    secondary: Color(0xFF147D64),
    reactions: ['🎬', '🤔', '💡', '👏', '⭐', '📝'],
    chatTitle: 'Club discussion',
    chatHint: 'Share an observation…',
    emptyChatTitle: 'Open the discussion',
    motion: ReactionMotion.spotlight,
  ),
];

extension RoomModePreset on RoomMode {
  RoomPreset get preset => roomPresets.firstWhere(
    (preset) => preset.mode == this,
    orElse: () => roomPresets.first,
  );
}
