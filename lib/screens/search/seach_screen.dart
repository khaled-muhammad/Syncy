import 'dart:ui';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncy/models/media.dart';
import 'package:syncy/widgets/media_card.dart';
import 'package:syncy/widgets/modern_input.dart';

class SearchScreen extends StatefulWidget {
  final List<Media> media;
  const SearchScreen({super.key, required this.media, this.onSelect});
  final Function(Media selectedMedia)? onSelect;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  bool show = false;
  late List<Media> filteredMedia = [];
  Timer? _debounceTimer;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 200)).then((_) {
      if (mounted) {
        setState(() {
          show = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<Media> _smartSearch(String query) {
    if (query.trim().isEmpty) return [];

    final searchTerms = query.toLowerCase().trim().split(RegExp(r'\s+'));
    final results = <MediaSearchResult>[];

    for (final media in widget.media) {
      final score = _calculateRelevanceScore(
        media,
        searchTerms,
        query.toLowerCase(),
      );
      if (score > 0) {
        results.add(MediaSearchResult(media: media, score: score));
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));

    return results.map((result) => result.media).toList();
  }

  double _calculateRelevanceScore(
    Media media,
    List<String> searchTerms,
    String fullQuery,
  ) {
    double score = 0.0;
    final mediaName = media.name.toLowerCase();

    if (mediaName == fullQuery) {
      score += 100.0;
    }

    if (mediaName.startsWith(fullQuery)) {
      score += 80.0;
    }

    if (mediaName.contains(fullQuery)) {
      score += 60.0;
    }

    for (final term in searchTerms) {
      if (term.isEmpty) continue;

      if (mediaName.split(RegExp(r'\s+')).contains(term)) {
        score += 40.0;
      }

      else if (mediaName.contains(term)) {
        score += 20.0;
      }

      else if (_fuzzyMatch(mediaName, term)) {
        score += 10.0;
      }
    }

    if (score > 0 && mediaName.length < 20) {
      score += 5.0;
    }

    return score;
  }

  bool _fuzzyMatch(String text, String pattern) {
    if (pattern.length > text.length) return false;
    if (pattern.isEmpty) return true;

    final maxDistance = (pattern.length / 3).ceil();

    for (int i = 0; i <= text.length - pattern.length; i++) {
      final substring = text.substring(i, i + pattern.length);
      if (_levenshteinDistance(substring, pattern) <= maxDistance) {
        return true;
      }
    }

    return false;
  }

  int _levenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final matrix = List.generate(
      s1.length + 1,
      (i) => List.generate(s2.length + 1, (j) => 0),
    );

    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }

    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s1.length][s2.length];
  }

  // To increase performance a bit
  void _onSearchChanged(String searchQuery) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          if (searchQuery.trim().isNotEmpty) {
            filteredMedia = _smartSearch(searchQuery);
          } else {
            filteredMedia = [];
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withAlpha(190),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: show ? 1 : 0,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: const SizedBox.shrink(),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 400),
                          opacity: show ? 1 : 0,
                          child: ModernInput(
                            controller: _searchController,
                            hintText: "Smart search ...",
                            icon: Icons.search_rounded,
                            onCancelPressed: () {
                              setState(() {
                                filteredMedia = [];
                              });
                            },
                            onChanged: _onSearchChanged,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Hero(
                        tag: 'search-btn',
                        child: ClipRRect(
                          borderRadius: BorderRadiusGeometry.circular(100),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white24,
                              ),
                              child: IconButton(
                                style: IconButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  fixedSize: Size(52, 52),
                                ),
                                onPressed: () {
                                  Get.back();
                                },
                                icon: Icon(Icons.arrow_back_ios_new_rounded),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 20,
                    ),
                    child:
                        filteredMedia.isEmpty &&
                            _searchController.text.trim().isNotEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 64,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No results found',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try different keywords or check spelling',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            itemCount: filteredMedia.length,
                            padding: const EdgeInsets.only(bottom: 100),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 20,
                                  mainAxisSpacing: 25,
                                  childAspectRatio: 3 / 5,
                                ),
                            itemBuilder: (context, index) {
                              final mediaElement = filteredMedia[index];
                              return MediaCard(
                                mediaElement: mediaElement,
                                onPressed: widget.onSelect == null? null : () {
                                  widget.onSelect!(mediaElement);
                                  Get.back();
                                },
                              );
                            },
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

class MediaSearchResult {
  final Media media;
  final double score;

  MediaSearchResult({required this.media, required this.score});
}