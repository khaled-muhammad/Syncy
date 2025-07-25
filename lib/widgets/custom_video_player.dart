import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:syncy/controllers/room_controller.dart';

// Add subtitle model
class SubtitleItem {
  final Duration start;
  final Duration end;
  final String text;

  SubtitleItem({
    required this.start,
    required this.end,
    required this.text,
  });
}

class ControlsOverlay extends StatefulWidget {
  const ControlsOverlay({super.key, 
    required this.controller,
    this.onPlayToggle,
    this.onSeek,
  });

  final VideoPlayerController controller;
  final Function(bool isPlaying)? onPlayToggle;
  final Function(Duration position)? onSeek;

  @override
  State<ControlsOverlay> createState() => ControlsOverlayState();
}

class ControlsOverlayState extends State<ControlsOverlay> {
  static const List<double> _examplePlaybackRates = <double>[
    0.25,
    0.5,
    1.0,
    1.5,
    2.0,
    3.0,
    5.0,
    10.0,
  ];

  bool _controlsVisible = false;
  Timer? _hideTimer;
  List<SubtitleItem> _subtitles = [];
  String? _currentSubtitleText;

  @override
  void initState() {
    super.initState();
    _loadSubtitles();
    widget.controller.addListener(_updateSubtitles);
    
    // Register for subtitle change notifications
    final RoomController roomController = Get.find<RoomController>();
    roomController.onSubtitleChanged = () {
      _loadSubtitles();
    };
  }

  void _loadSubtitles() {
    final RoomController roomController = Get.find<RoomController>();
    if (roomController.currentSubtitlePath.value != null) {
      print('Loading subtitles from: ${roomController.currentSubtitlePath.value}');
      _parseSubtitleFile(roomController.currentSubtitlePath.value!);
    } else {
      print('Clearing subtitles');
      setState(() {
        _subtitles.clear();
        _currentSubtitleText = null;
      });
    }
  }

  Future<void> _parseSubtitleFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        print('Subtitle file does not exist: $filePath');
        return;
      }

      final content = await file.readAsString();
      final extension = filePath.split('.').last.toLowerCase();

      print('Parsing subtitle file with extension: $extension');
      
      if (extension == 'srt') {
        _subtitles = _parseSRT(content);
      } else if (extension == 'vtt') {
        _subtitles = _parseVTT(content);
      }
      
      print('Parsed ${_subtitles.length} subtitle entries');
      
      // Debug: Print first few subtitles
      for (int i = 0; i < _subtitles.length && i < 3; i++) {
        final sub = _subtitles[i];
        print('Subtitle $i: ${sub.start} -> ${sub.end}: ${sub.text.substring(0, 
sub.text.length > 50 ? 50 : sub.text.length)}...');
      }
      
      setState(() {});
    } catch (e) {
      print('Error parsing subtitle file: $e');
    }
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
          final timeMatch = RegExp(r'(\d{2}):(\d{2}):(\d{2})[,\.](\d{3}) --> (\d{2}):(\d{2}):(\d{2})[,\.](\d{3})').firstMatch(timeLine);
          
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
              
              subtitles.add(SubtitleItem(
                start: start,
                end: end,
                text: text,
              ));
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
      print('Warning: Text became empty after formatting removal. Original: $text');
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
      if (lines.length >= 1) {
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
        
        // More flexible regex pattern for timestamps
        final timeMatch = RegExp(r'(\d{2}):(\d{2}):(\d{2})[\.,](\d{3}) --> (\d{2}):(\d{2}):(\d{2})[\.,](\d{3})').firstMatch(timeLine);
        
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
          
          // Join all lines and strip basic formatting tags
          final text = _stripFormattingTags(textLines.join('\n'));
          
          subtitles.add(SubtitleItem(
            start: start,
            end: end,
            text: text,
          ));
        }
      }
    }
    
    return subtitles;
  }

  void _updateSubtitles() {
    if (_subtitles.isEmpty) return;

    final position = widget.controller.value.position;
    
    // Apply subtitle delay from room controller
    final RoomController roomController = Get.find<RoomController>();
    final delayMs = roomController.subtitleDelay.value;
    final adjustedPosition = Duration(
      milliseconds: position.inMilliseconds + delayMs,
    );
    
    String? newSubtitleText;

    for (final subtitle in _subtitles) {
      if (adjustedPosition >= subtitle.start && adjustedPosition <= subtitle.end) {
        newSubtitleText = subtitle.text;
        // Debug: Print when we find a matching subtitle
        if (newSubtitleText != _currentSubtitleText) {
          print('Displaying subtitle at ${position.inSeconds}s (adjusted: ${adjustedPosition.inSeconds}s): ${newSubtitleText.substring(0, newSubtitleText.length > 50 ? 50 : newSubtitleText.length)}...');
        }
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
    widget.controller.removeListener(_updateSubtitles);
    
    // Clean up subtitle change callback
    final RoomController roomController = Get.find<RoomController>();
    roomController.onSubtitleChanged = null;
    
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
    final bool newIsPlaying = !widget.controller.value.isPlaying;
    if (newIsPlaying) {
      widget.controller.play();
    } else {
      widget.controller.pause();
    }
    widget.onPlayToggle?.call(newIsPlaying);
    
    // Force immediate UI update
    setState(() {});
  }

  void _toggleFullScreen() {
    // Check if we're already in fullscreen by looking at the current route
    final isInFullScreen = ModalRoute.of(context)?.settings.name == '_FullScreenVideoPage';
    
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
            onPlayToggle: widget.onPlayToggle,
            onSeek: widget.onSeek,
          ),
        ),
      );
    }
  }

  void _showSubtitleDelayDialog(BuildContext context) {
    final RoomController roomController = Get.find<RoomController>();
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
                  for (int delay in [-2000, -1000, -500, -250, 0, 250, 500, 1000, 2000])
                    ElevatedButton(
                      onPressed: () {
                        roomController.setSubtitleDelay(delay);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: delay == currentDelay ? Colors.purple : null,
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
    return Stack(
      children: <Widget>[
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
        AnimatedOpacity(
          opacity: _controlsVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            width: double.infinity,
            height: double.infinity,
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
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                if (_controlsVisible) {
                  _hideControls();
                } else {
                  _showControls();
                }
              },
              child: Stack(
                children: [
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
                            final RoomController roomController = Get.find<RoomController>();
                            if (value == 'select') {
                              roomController.selectSubtitleFile();
                            } else if (value == 'clear') {
                              roomController.clearSubtitle();
                            } else if (value == 'delay') {
                              _showSubtitleDelayDialog(context);
                            }
                            _resetHideTimer();
                          },
                          itemBuilder: (BuildContext context) {
                            final RoomController roomController = Get.find<RoomController>();
                            return [
                              PopupMenuItem<String>(
                                value: 'select',
                                child: Row(
                                  children: [
                                    Icon(Icons.file_upload, size: 16),
                                    SizedBox(width: 8),
                                    Text('Select Subtitle'),
                                  ],
                                ),
                              ),
                              if (roomController.currentSubtitlePath.value != null) ...[
                                PopupMenuItem<String>(
                                  value: 'delay',
                                  child: Row(
                                    children: [
                                      Icon(Icons.schedule, size: 16),
                                      SizedBox(width: 8),
                                      Text('Adjust Delay (${roomController.subtitleDelay.value}ms)'),
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
                              padding: const EdgeInsets.only(top:16),
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
                                      onChanged: (value) {
                                        final newPosition = Duration(
                                          milliseconds: value.toInt(),
                                        );
                                        widget.controller.seekTo(newPosition);
                                        if (widget.onSeek != null) {
                                          widget.onSeek!(newPosition);
                                        }
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
        ),
        if (!_controlsVisible)
          GestureDetector(
            onTap: () {
              _showControls();
            },
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
            ),
          ),
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
  final VideoPlayerController controller;
  final Function(bool)? onPlayToggle;
  final Function(Duration)? onSeek;

  const _FullScreenVideoPage({
    required this.controller,
    this.onPlayToggle,
    this.onSeek,
  });

  @override
  State<_FullScreenVideoPage> createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<_FullScreenVideoPage> {
  @override
  void initState() {
    super.initState();
    // Hide system UI and set orientation based on video aspect ratio
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // Check if video is portrait or landscape
    final isPortraitVideo = widget.controller.value.aspectRatio < 1.0;
    
    if (isPortraitVideo) {
      // For portrait videos, use portrait orientation
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    } else {
      // For landscape videos, use landscape orientation
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  @override
  void dispose() {
    // Restore system UI and orientation
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPortraitVideo = widget.controller.value.aspectRatio < 1.0;
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: isPortraitVideo
            ? Container(
                width: screenSize.width,
                height: screenSize.height,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: screenSize.width,
                    height: screenSize.width / widget.controller.value.aspectRatio,
                    child: Stack(
                      children: [
                        VideoPlayer(widget.controller),
                        ControlsOverlay(
                          controller: widget.controller,
                          onPlayToggle: widget.onPlayToggle,
                          onSeek: widget.onSeek,
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
                    VideoPlayer(widget.controller),
                    ControlsOverlay(
                      controller: widget.controller,
                      onPlayToggle: widget.onPlayToggle,
                      onSeek: widget.onSeek,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}