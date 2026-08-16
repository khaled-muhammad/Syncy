import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:syncy/controllers/room_controller.dart';
import 'package:syncy/services/player/sync_player.dart';
import 'package:syncy/utils/platform_utils.dart';
import 'package:syncy/widgets/reliable_reaction_overlay.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:window_manager/window_manager.dart';

// Add subtitle model
class SubtitleItem {
  final Duration start;
  final Duration end;
  final String text;

  SubtitleItem({required this.start, required this.end, required this.text});
}

class ControlsOverlay extends StatefulWidget {
  const ControlsOverlay({
    super.key,
    required this.controller,
    required this.roomController,
    this.onPlayToggle,
    this.onSeek,
    this.showReactionsInFullscreen = true,
  });

  final SyncPlayer controller;
  final RoomController roomController;
  final Function(bool isPlaying)? onPlayToggle;
  final Function(Duration position)? onSeek;
  final bool showReactionsInFullscreen;

  @override
  State<ControlsOverlay> createState() => ControlsOverlayState();
}

class ControlsOverlayState extends State<ControlsOverlay> {
  bool _controlsVisible = false;
  Timer? _hideTimer;
  List<SubtitleItem> _subtitles = [];
  String? _currentSubtitleText;
  StreamSubscription<String?>? _subtitlePathSubscription;
  StreamSubscription<int>? _subtitleDelaySubscription;
  StreamSubscription<dynamic>? _subtitleListSubscription;
  int _subtitleLoadGeneration = 0;

  // Double-tap-to-seek (YouTube-style: tap the left/right half of the player).
  // We detect the double tap manually so a single tap toggles the controls
  // instantly (no ~300ms gesture-arena delay from onDoubleTap).
  static const Duration _seekStep = Duration(seconds: 10);
  static const Duration _doubleTapWindow = Duration(milliseconds: 300);
  DateTime? _lastTapAt;
  bool _seekChainActive = false;
  bool _visibilityBeforeChain = false;

  int _seekIndicatorSide = 0; // -1 = rewind (left), 1 = forward (right)
  int _accumulatedSeekSeconds = 0;
  bool _seekIndicatorVisible = false;
  Timer? _seekIndicatorTimer;

  @override
  void initState() {
    super.initState();
    _loadSubtitles();
    widget.controller.addListener(_updateSubtitles);

    _subtitlePathSubscription = widget.roomController.currentSubtitlePath
        .listen((_) => _loadSubtitles());
    _subtitleDelaySubscription = widget.roomController.subtitleDelay.listen(
      (_) => _updateSubtitles(),
    );
    _subtitleListSubscription = widget.roomController.availableSubtitles.listen(
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  void _loadSubtitles() {
    final roomController = widget.roomController;
    final generation = ++_subtitleLoadGeneration;
    if (roomController.currentSubtitlePath.value != null) {
      _parseSubtitleFile(roomController.currentSubtitlePath.value!, generation);
    } else {
      if (mounted) {
        setState(() {
          _subtitles.clear();
          _currentSubtitleText = null;
        });
      }
    }
  }

  Future<void> _parseSubtitleFile(String filePath, int generation) async {
    try {
      final uri = Uri.tryParse(filePath);
      final isRemote =
          uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
      late String content;
      if (isRemote) {
        final response = await Dio().get<String>(
          filePath,
          options: Options(responseType: ResponseType.plain),
        );
        content = response.data ?? '';
      } else {
        final file = File(filePath);
        if (!await file.exists()) return;
        content = await file.readAsString();
      }
      content = content
          .replaceFirst('\uFEFF', '')
          .replaceAll('\r\n', '\n')
          .replaceAll('\r', '\n');
      final sourcePath = uri?.path.isNotEmpty == true ? uri!.path : filePath;
      final extension =
          uri?.queryParameters['format'] ??
          sourcePath.split('.').last.toLowerCase();

      List<SubtitleItem> parsed = const [];
      if (extension == 'srt') {
        parsed = _parseSRT(content);
      } else if (extension == 'vtt') {
        parsed = _parseVTT(content);
      }
      if (!mounted || generation != _subtitleLoadGeneration) return;
      setState(() {
        _subtitles = parsed;
        _currentSubtitleText = null;
      });
    } catch (_) {}
  }

  List<SubtitleItem> _parseSRT(String content) {
    final List<SubtitleItem> subtitles = [];
    final lines = content.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Check if this line is a subtitle number (sequence)
      if (RegExp(r'^\d+$').hasMatch(line)) {
        // Look for the timestamp on the next line
        if (i + 1 < lines.length) {
          final timeLine = lines[i + 1].trim();

          // Check if the next line contains timing information
          final timeMatch = RegExp(
            r'(\d{2}):(\d{2}):(\d{2})[,\.](\d{3}) --> (\d{2}):(\d{2}):(\d{2})[,\.](\d{3})',
          ).firstMatch(timeLine);

          if (timeMatch != null) {
            final start = Duration(
              hours: int.parse(timeMatch.group(1)!),
              minutes: int.parse(timeMatch.group(2)!),
              seconds: int.parse(timeMatch.group(3)!),
              milliseconds: int.parse(timeMatch.group(4)!),
            );

            final end = Duration(
              hours: int.parse(timeMatch.group(5)!),
              minutes: int.parse(timeMatch.group(6)!),
              seconds: int.parse(timeMatch.group(7)!),
              milliseconds: int.parse(timeMatch.group(8)!),
            );

            // Collect subtitle text lines
            final List<String> textLines = [];
            int textIndex = i + 2;

            // Read text lines until we hit an empty line or another subtitle number
            while (textIndex < lines.length) {
              final textLine = lines[textIndex].trim();

              // Stop if we hit an empty line or another subtitle number
              if (textLine.isEmpty || RegExp(r'^\d+$').hasMatch(textLine)) {
                break;
              }

              textLines.add(textLine);
              textIndex++;
            }

            if (textLines.isNotEmpty) {
              // Join all text lines and strip formatting tags
              final text = _stripFormattingTags(textLines.join('\n'));

              subtitles.add(SubtitleItem(start: start, end: end, text: text));
            }

            // Skip to the end of this subtitle block
            i = textIndex - 1;
          }
        }
      }
    }

    return subtitles;
  }

  String _stripFormattingTags(String text) {
    // Remove common SRT formatting tags
    String result = text;

    // Remove color tags like {\\c&HFFFFFF&}
    result = result.replaceAll(RegExp(r'\{\\[^}]*\}'), '');

    // Remove HTML-like tags like <i> or <b>
    result = result.replaceAll(RegExp(r'<[^>]*>'), '');

    // Remove other formatting like {\an8}
    result = result.replaceAll(RegExp(r'\{[^}]*\}'), '');

    // Clean up extra whitespace
    result = result.trim();

    // If after stripping formatting we have empty text, return the original
    if (result.isEmpty && text.isNotEmpty) {
      // Try a more conservative approach - just remove known problematic tags
      result = text.replaceAll(RegExp(r'\{\\[cf]&[^}]*\}'), '');
      result = result.replaceAll(RegExp(r'\{\\[fb][^}]*\}'), '');
      result = result.trim();
    }

    return result;
  }

  List<SubtitleItem> _parseVTT(String content) {
    final List<SubtitleItem> subtitles = [];

    // Skip WebVTT header if present
    if (content.trim().startsWith('WEBVTT')) {
      final headerEnd = content.indexOf('\n\n');
      if (headerEnd != -1) {
        content = content.substring(headerEnd + 2);
      }
    }

    final blocks = content.split('\n\n');

    for (final block in blocks) {
      final lines = block.trim().split('\n');
      if (lines.isNotEmpty) {
        // Find the timing line which contains " --> "
        int timeLineIndex = -1;
        for (int i = 0; i < lines.length; i++) {
          if (lines[i].contains(' --> ')) {
            timeLineIndex = i;
            break;
          }
        }

        if (timeLineIndex == -1) continue; // Skip if no timing found

        final timeLine = lines[timeLineIndex];
        final textLines = lines.sublist(timeLineIndex + 1);

        final timingParts = timeLine.split(' --> ');
        final start = timingParts.isEmpty
            ? null
            : _parseVttTimestamp(timingParts.first);
        final end = timingParts.length < 2
            ? null
            : _parseVttTimestamp(timingParts[1].split(' ').first);

        if (start != null && end != null) {
          // Join all lines and strip basic formatting tags
          final text = _stripFormattingTags(textLines.join('\n'));

          subtitles.add(SubtitleItem(start: start, end: end, text: text));
        }
      }
    }

    return subtitles;
  }

  Duration? _parseVttTimestamp(String value) {
    final match = RegExp(
      r'^(?:(\d{1,2}):)?(\d{2}):(\d{2})[\.,](\d{3})$',
    ).firstMatch(value.trim());
    if (match == null) return null;
    return Duration(
      hours: int.tryParse(match.group(1) ?? '0') ?? 0,
      minutes: int.parse(match.group(2)!),
      seconds: int.parse(match.group(3)!),
      milliseconds: int.parse(match.group(4)!),
    );
  }

  void _updateSubtitles() {
    if (_subtitles.isEmpty) return;

    final position = widget.controller.value.position;

    // Apply subtitle delay from room controller
    final roomController = widget.roomController;
    final delayMs = roomController.subtitleDelay.value;
    final adjustedPosition = Duration(
      milliseconds: position.inMilliseconds + delayMs,
    );

    String? newSubtitleText;

    for (final subtitle in _subtitles) {
      if (adjustedPosition >= subtitle.start &&
          adjustedPosition <= subtitle.end) {
        newSubtitleText = subtitle.text;
        break;
      }
    }

    if (newSubtitleText != _currentSubtitleText) {
      setState(() {
        _currentSubtitleText = newSubtitleText;
      });
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _seekIndicatorTimer?.cancel();
    widget.controller.removeListener(_updateSubtitles);

    _subtitlePathSubscription?.cancel();
    _subtitleDelaySubscription?.cancel();
    _subtitleListSubscription?.cancel();

    super.dispose();
  }

  void _showControls() {
    setState(() {
      _controlsVisible = true;
    });
    _resetHideTimer();
  }

  void _hideControls() {
    setState(() {
      _controlsVisible = false;
    });
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _hideControls();
      }
    });
  }

  void _togglePlayPause() {
    // The player is authoritative here. This also lets the same chrome drive
    // standalone LAN playback where there is deliberately no room state.
    final bool newIsPlaying = !widget.controller.value.isPlaying;
    final callback = widget.onPlayToggle;
    if (callback != null) {
      callback(newIsPlaying);
    } else if (newIsPlaying) {
      unawaited(widget.controller.play());
    } else {
      unawaited(widget.controller.pause());
    }

    // Force immediate UI update
    setState(() {});
  }

  void _seekBy(Duration offset) {
    final value = widget.controller.value;
    if (!value.isInitialized) return;
    var target = value.position + offset;
    if (target < Duration.zero) target = Duration.zero;
    if (target > value.duration) target = value.duration;
    final callback = widget.onSeek;
    if (callback == null) return;
    callback(target);
  }

  void _onSurfaceTapUp(double tapDx, double width) {
    final now = DateTime.now();
    final int side = (width <= 0 || tapDx < width / 2) ? -1 : 1;
    final bool consecutive =
        _lastTapAt != null && now.difference(_lastTapAt!) < _doubleTapWindow;
    _lastTapAt = now;

    if (consecutive) {
      if (widget.onSeek == null) return;
      // Second (or further) quick tap => this is a seek gesture, not a toggle.
      if (!_seekChainActive) {
        _seekChainActive = true;
        // Undo the toggle the first tap of this pair caused so a double tap
        // seeks without leaving the controls in a flipped state.
        if (_controlsVisible != _visibilityBeforeChain) {
          setState(() => _controlsVisible = _visibilityBeforeChain);
          if (_controlsVisible) {
            _resetHideTimer();
          } else {
            _hideTimer?.cancel();
          }
        }
      }
      _registerSeek(side);
    } else {
      // Fresh tap: toggle the controls immediately (no gesture delay).
      _seekChainActive = false;
      _visibilityBeforeChain = _controlsVisible;
      if (_controlsVisible) {
        _hideControls();
      } else {
        _showControls();
      }
    }
  }

  void _registerSeek(int side) {
    // side: -1 = rewind (left half), 1 = forward (right half)
    if (_seekIndicatorSide != side || !_seekIndicatorVisible) {
      _accumulatedSeekSeconds = 0;
    }
    _seekIndicatorSide = side;
    _accumulatedSeekSeconds += _seekStep.inSeconds;
    _seekIndicatorVisible = true;
    _seekBy(Duration(seconds: side * _seekStep.inSeconds));
    if (_controlsVisible) _resetHideTimer();
    setState(() {});

    _seekIndicatorTimer?.cancel();
    _seekIndicatorTimer = Timer(const Duration(milliseconds: 550), () {
      if (mounted) {
        setState(() => _seekIndicatorVisible = false);
      }
    });
  }

  Widget _buildSeekFeedback() {
    final bool isForward = _seekIndicatorSide > 0;
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _seekIndicatorVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: Align(
          alignment: isForward ? Alignment.centerRight : Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: 0.5,
            heightFactor: 1,
            child: Center(
              child: AnimatedScale(
                scale: _seekIndicatorVisible ? 1.0 : 0.8,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isForward
                            ? Icons.fast_forward_rounded
                            : Icons.fast_rewind_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_accumulatedSeekSeconds}s',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleFullScreen() {
    // Check if we're already in fullscreen by looking at the current route
    final isInFullScreen =
        ModalRoute.of(context)?.settings.name == '_FullScreenVideoPage';

    // On desktop the route alone only fills the app window; the window itself
    // has to be told to go fullscreen too.
    if (isDesktop) {
      unawaited(windowManager.setFullScreen(!isInFullScreen));
    }

    if (isInFullScreen) {
      // If already in fullscreen, pop to exit
      Navigator.of(context).pop();
    } else {
      // If not in fullscreen, push to enter fullscreen
      Navigator.of(context).push(
        MaterialPageRoute(
          settings: RouteSettings(name: '_FullScreenVideoPage'),
          builder: (context) => _FullScreenVideoPage(
            controller: widget.controller,
            roomController: widget.roomController,
            onPlayToggle: widget.onPlayToggle,
            onSeek: widget.onSeek,
            showReactions: widget.showReactionsInFullscreen,
          ),
        ),
      );
    }
  }

  void _showSubtitleDelayDialog(BuildContext context) {
    final roomController = widget.roomController;
    final currentDelay = roomController.subtitleDelay.value;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Subtitle Delay'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current delay: ${currentDelay}ms'),
              SizedBox(height: 16),
              Text('Quick adjustments:'),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (int delay in [
                    -2000,
                    -1000,
                    -500,
                    -250,
                    0,
                    250,
                    500,
                    1000,
                    2000,
                  ])
                    ElevatedButton(
                      onPressed: () {
                        roomController.setSubtitleDelay(delay);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: delay == currentDelay
                            ? Colors.purple
                            : null,
                      ),
                      child: Text('${delay}ms'),
                    ),
                ],
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Custom delay (ms)',
                  hintText: 'Enter delay in milliseconds',
                ),
                keyboardType: TextInputType.number,
                onSubmitted: (value) {
                  final delay = int.tryParse(value);
                  if (delay != null) {
                    roomController.setSubtitleDelay(delay);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final overlay = _buildOverlayStack();
    if (!isDesktop) return overlay;

    // Desktop expects hover to reveal controls and the keyboard to drive
    // playback; the touch gestures underneath stay active either way.
    return MouseRegion(
      onEnter: (_) => _showControls(),
      onHover: (_) {
        if (!_controlsVisible) {
          _showControls();
        } else {
          _resetHideTimer();
        }
      },
      onExit: (_) => _hideControls(),
      child: Focus(
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: overlay,
      ),
    );
  }

  /// Routes desktop key presses through the same handlers the on-screen
  /// controls use, so keyboard actions broadcast to the room identically.
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.mediaPlayPause:
        _showControls();
        _togglePlayPause();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        _showControls();
        _seekBy(const Duration(seconds: -10));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        _showControls();
        _seekBy(const Duration(seconds: 10));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyF:
        _toggleFullScreen();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
        // Escape only leaves fullscreen; it must not close the room.
        if (ModalRoute.of(context)?.settings.name == '_FullScreenVideoPage') {
          _toggleFullScreen();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      default:
        return KeyEventResult.ignored;
    }
  }

  Widget _buildOverlayStack() {
    return Stack(
      children: <Widget>[
        // Base interaction layer: a single full-area detector. A single tap
        // toggles the controls instantly; a quick second tap seeks (left half
        // back, right half forward, YouTube-style). Double taps are detected
        // manually so single taps have no gesture-arena delay. Sits at the
        // bottom so the play button, slider and top buttons stay tappable.
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) => _onSurfaceTapUp(
                details.localPosition.dx,
                constraints.maxWidth,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        // Subtitle Display Overlay
        if (_currentSubtitleText != null && _currentSubtitleText!.isNotEmpty)
          Positioned(
            bottom: 8,
            left: 16,
            right: 16,
            child: Text(
              _currentSubtitleText!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.normal,
                shadows: [
                  Shadow(
                    blurRadius: 2,
                    color: Colors.black,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
          ),
        IgnorePointer(
          ignoring: !_controlsVisible,
          child: AnimatedOpacity(
            opacity: _controlsVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Stack(
              children: [
                // Non-interactive dim gradient: taps on empty areas fall
                // through to the surface gesture layer below.
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.7),
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                          stops: const [0.0, 0.3, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                /*Align(
                    alignment: Alignment.topRight,
                    child: PopupMenuButton<double>(
                      initialValue: widget.controller.value.playbackSpeed,
                      tooltip: 'Playback speed',
                      onSelected: (double speed) {
                        widget.controller.setPlaybackSpeed(speed);
                        _resetHideTimer();
                      },
                      itemBuilder: (BuildContext context) {
                        return <PopupMenuItem<double>>[
                          for (final double speed in _examplePlaybackRates)
                            PopupMenuItem<double>(
                              value: speed,
                              child: Text('${speed}x'),
                            ),
                        ];
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${widget.controller.value.playbackSpeed}x',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),*/
                Align(
                  alignment: Alignment.topRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PopupMenuButton<String>(
                        icon: Icon(Icons.subtitles, color: Colors.white),
                        tooltip: 'Subtitle Options',
                        onSelected: (String value) {
                          final roomController = widget.roomController;
                          if (value.startsWith('track:')) {
                            final index = int.tryParse(value.substring(6));
                            if (index != null &&
                                index <
                                    roomController.availableSubtitles.length) {
                              roomController.selectSubtitleTrack(
                                roomController.availableSubtitles[index],
                              );
                            }
                          } else if (value == 'select') {
                            roomController.selectSubtitleFile();
                          } else if (value == 'clear') {
                            roomController.clearSubtitle();
                          } else if (value == 'delay') {
                            _showSubtitleDelayDialog(context);
                          }
                          _resetHideTimer();
                        },
                        itemBuilder: (BuildContext context) {
                          final roomController = widget.roomController;
                          return [
                            if (roomController
                                .availableSubtitles
                                .isNotEmpty) ...[
                              const PopupMenuItem<String>(
                                enabled: false,
                                child: Text(
                                  'AVAILABLE LANGUAGES',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              for (
                                var index = 0;
                                index <
                                    roomController.availableSubtitles.length;
                                index++
                              )
                                PopupMenuItem<String>(
                                  value: 'track:$index',
                                  child: Row(
                                    children: [
                                      Icon(
                                        roomController
                                                    .currentSubtitlePath
                                                    .value ==
                                                roomController
                                                    .availableSubtitles[index]
                                                    .source
                                            ? Icons.check_circle_rounded
                                            : Icons.language_rounded,
                                        size: 17,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          roomController
                                              .availableSubtitles[index]
                                              .label,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const PopupMenuDivider(),
                            ],
                            PopupMenuItem<String>(
                              value: 'select',
                              child: Row(
                                children: [
                                  Icon(Icons.file_upload, size: 16),
                                  SizedBox(width: 8),
                                  Text('Choose another file'),
                                ],
                              ),
                            ),
                            if (roomController.currentSubtitlePath.value !=
                                null) ...[
                              PopupMenuItem<String>(
                                value: 'delay',
                                child: Row(
                                  children: [
                                    Icon(Icons.schedule, size: 16),
                                    SizedBox(width: 8),
                                    Text(
                                      'Adjust Delay (${roomController.subtitleDelay.value}ms)',
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'clear',
                                child: Row(
                                  children: [
                                    Icon(Icons.clear, size: 16),
                                    SizedBox(width: 8),
                                    Text('Clear Subtitle'),
                                  ],
                                ),
                              ),
                            ],
                          ];
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.fullscreen, color: Colors.white),
                        onPressed: () {
                          _toggleFullScreen();
                          _resetHideTimer();
                        },
                      ),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: GestureDetector(
                              onTap: () {
                                _togglePlayPause();
                                _resetHideTimer();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  widget.controller.value.isPlaying
                                      ? HeroIcons.pause
                                      : HeroIcons.play,
                                  color: Colors.white,
                                  size: 50,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 0,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              //horizontal: 16.0,
                              // vertical: 6.0,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                              color: Colors.black.withValues(alpha: 0.7),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 2,
                                    horizontal: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.purple,
                                        Colors.deepPurpleAccent,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.only(
                                      bottomRight: Radius.circular(16),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _formatDuration(
                                          widget.controller.value.position,
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(" / "),
                                      Text(
                                        _formatDuration(
                                          widget.controller.value.duration,
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: Colors.deepPurpleAccent,
                                    inactiveTrackColor: Colors.deepPurpleAccent
                                        .withValues(alpha: 0.3),
                                    thumbColor: Colors.white,
                                    overlayColor: Colors.deepPurpleAccent
                                        .withValues(alpha: 0.2),
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 8,
                                    ),
                                    overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 16,
                                    ),
                                    trackHeight: 6,
                                  ),
                                  child: Slider(
                                    value:
                                        widget
                                                .controller
                                                .value
                                                .duration
                                                .inMilliseconds >
                                            0
                                        ? widget
                                              .controller
                                              .value
                                              .position
                                              .inMilliseconds
                                              .toDouble()
                                        : 0.0,
                                    min: 0.0,
                                    max: widget
                                        .controller
                                        .value
                                        .duration
                                        .inMilliseconds
                                        .toDouble(),
                                    onChanged: widget.onSeek == null
                                        ? null
                                        : (value) {
                                            final newPosition = Duration(
                                              milliseconds: value.toInt(),
                                            );
                                            widget.controller.seekTo(
                                              newPosition,
                                            );
                                            widget.onSeek!(newPosition);
                                            _resetHideTimer();
                                          },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Transient seek feedback (never absorbs touches).
        Positioned.fill(child: _buildSeekFeedback()),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }
}

class _FullScreenVideoPage extends StatefulWidget {
  final SyncPlayer controller;
  final RoomController roomController;
  final Function(bool)? onPlayToggle;
  final Function(Duration)? onSeek;
  final bool showReactions;

  const _FullScreenVideoPage({
    required this.controller,
    required this.roomController,
    this.onPlayToggle,
    this.onSeek,
    this.showReactions = true,
  });

  @override
  State<_FullScreenVideoPage> createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<_FullScreenVideoPage> {
  late VoidCallback _videoListener;
  Timer? _reactionDockTimer;
  bool _reactionDockVisible = true;
  double _reactionDragDistance = 0;
  bool _reactionDragHandled = false;

  @override
  void initState() {
    super.initState();

    // Enable wake lock for fullscreen video
    WakelockPlus.enable();

    // System UI modes and orientation locks are mobile concepts — on desktop
    // the window manager owns fullscreen, and rotating a monitor is not a
    // thing. _toggleFullScreen has already resized the window by this point.
    if (!isDesktop) {
      // Hide system UI and set orientation based on video aspect ratio
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

      // Check if video is portrait or landscape
      final isPortraitVideo = widget.controller.value.aspectRatio < 1.0;

      if (isPortraitVideo) {
        // For portrait videos, use portrait orientation
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      } else {
        // For landscape videos, use landscape orientation
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    }

    // Add listener to update state on controller changes
    _videoListener = () {
      if (mounted) setState(() {});
    };
    widget.controller.addListener(_videoListener);
    _scheduleReactionDockHide(const Duration(seconds: 3));
  }

  void _scheduleReactionDockHide([
    Duration delay = const Duration(seconds: 5),
  ]) {
    _reactionDockTimer?.cancel();
    _reactionDockTimer = Timer(delay, _hideReactionDock);
  }

  void _showReactionDock() {
    if (!_reactionDockVisible && mounted) {
      setState(() => _reactionDockVisible = true);
    }
    _scheduleReactionDockHide();
  }

  void _hideReactionDock() {
    _reactionDockTimer?.cancel();
    _reactionDockTimer = null;
    if (_reactionDockVisible && mounted) {
      setState(() => _reactionDockVisible = false);
    }
  }

  void _onReactionDragStart(DragStartDetails details) {
    _reactionDockTimer?.cancel();
    _reactionDragDistance = 0;
    _reactionDragHandled = false;
  }

  void _onReactionDragUpdate(DragUpdateDetails details) {
    if (_reactionDragHandled) return;
    _reactionDragDistance += details.delta.dy;
    if (_reactionDragDistance <= -18) {
      _reactionDragHandled = true;
      _showReactionDock();
    } else if (_reactionDragDistance >= 18) {
      _reactionDragHandled = true;
      _hideReactionDock();
    }
  }

  void _onReactionDragEnd(DragEndDetails details) {
    if (_reactionDragHandled) return;
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -180) {
      _showReactionDock();
    } else if (velocity > 180) {
      _hideReactionDock();
    } else if (_reactionDockVisible) {
      _scheduleReactionDockHide();
    }
  }

  void _onReactionSent() {
    _scheduleReactionDockHide(const Duration(milliseconds: 1100));
  }

  @override
  void dispose() {
    _reactionDockTimer?.cancel();
    // Remove the listener
    widget.controller.removeListener(_videoListener);
    if (isDesktop) {
      // Leaving this route by any path — Escape, the button, or a system back
      // gesture — must return the window to its normal size.
      unawaited(windowManager.setFullScreen(false));
    } else {
      // Restore system UI and orientation
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }

    // Disable wake lock when exiting fullscreen
    WakelockPlus.disable();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPortraitVideo = widget.controller.value.aspectRatio < 1.0;
    final screenSize = MediaQuery.of(context).size;

    final videoSurface = isPortraitVideo
        ? SizedBox(
            width: screenSize.width,
            height: screenSize.height,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: screenSize.width,
                height: screenSize.width / widget.controller.value.aspectRatio,
                child: Stack(
                  children: [
                    widget.controller.buildSurface(),
                    ControlsOverlay(
                      controller: widget.controller,
                      roomController: widget.roomController,
                      onPlayToggle: widget.onPlayToggle,
                      onSeek: widget.onSeek,
                      showReactionsInFullscreen: widget.showReactions,
                    ),
                  ],
                ),
              ),
            ),
          )
        : AspectRatio(
            aspectRatio: widget.controller.value.aspectRatio,
            child: Stack(
              children: [
                widget.controller.buildSurface(),
                ControlsOverlay(
                  controller: widget.controller,
                  roomController: widget.roomController,
                  onPlayToggle: widget.onPlayToggle,
                  onSeek: widget.onSeek,
                  showReactionsInFullscreen: widget.showReactions,
                ),
              ],
            ),
          );

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragStart: _onReactionDragStart,
        onVerticalDragUpdate: _onReactionDragUpdate,
        onVerticalDragEnd: _onReactionDragEnd,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(child: videoSurface),
            // Screen-level placement avoids clipping and FittedBox distortion.
            if (widget.showReactions)
              Positioned.fill(
                child: ReactionOverlay(
                  bottomInset: 125,
                  controller: widget.roomController,
                ),
              ),
            if (widget.showReactions)
              SafeArea(
                minimum: const EdgeInsets.only(bottom: 70),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Semantics(
                    container: true,
                    label: 'Reaction controls',
                    hint: _reactionDockVisible
                        ? 'Swipe down to hide'
                        : 'Swipe up or tap to show',
                    onTap: _reactionDockVisible ? null : _showReactionDock,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _reactionDockVisible ? null : _showReactionDock,
                      child: AnimatedSlide(
                        offset: _reactionDockVisible
                            ? Offset.zero
                            : const Offset(0, 1.85),
                        duration: _reactionDockVisible
                            ? const Duration(milliseconds: 180)
                            : const Duration(milliseconds: 280),
                        curve: _reactionDockVisible
                            ? Curves.easeOutBack
                            : Curves.easeInCubic,
                        child: AnimatedOpacity(
                          opacity: _reactionDockVisible ? 1 : .14,
                          duration: _reactionDockVisible
                              ? const Duration(milliseconds: 140)
                              : const Duration(milliseconds: 240),
                          curve: Curves.easeOut,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 38,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .72),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              const SizedBox(height: 7),
                              IgnorePointer(
                                ignoring: !_reactionDockVisible,
                                child: ReactionBar(
                                  controller: widget.roomController,
                                  onReactionSent: _onReactionSent,
                                ),
                              ),
                            ],
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
  }
}
