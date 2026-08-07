import 'package:flutter_test/flutter_test.dart';
import 'package:syncy/models/remote_media.dart';

void main() {
  final library = RemoteLibrary(
    roots: const [
      RemoteLibraryRoot(id: '10', name: 'Movies'),
      RemoteLibraryRoot(id: '20', name: 'Shows'),
    ],
    media: const [
      RemoteMedia(id: 1, name: 'Loose.mp4', rootId: '10', rootName: 'Movies'),
      RemoteMedia(
        id: 2,
        name: 'Heat.mkv',
        rootId: '10',
        rootName: 'Movies',
        relativeFolder: 'Crime',
      ),
      RemoteMedia(
        id: 3,
        name: 'Iron Man.mp4',
        rootId: '10',
        rootName: 'Movies',
        relativeFolder: r'Marvel\Phase One',
      ),
      RemoteMedia(
        id: 4,
        name: 'Pilot.mkv',
        rootId: '20',
        rootName: 'Shows',
        relativeFolder: 'Drama/Season 1',
      ),
    ],
  );

  test('library home groups media into PC roots', () {
    final folders = library.childDirectories('');

    expect(folders.map((item) => item.name), ['Movies', 'Shows']);
    expect(folders.first.mediaCount, 3);
    expect(folders.last.mediaCount, 1);
    expect(library.visibleMedia(''), isEmpty);
  });

  test('directory explorer shows immediate children and direct videos', () {
    expect(library.childDirectories('10').map((item) => item.name), [
      'Crime',
      'Marvel',
    ]);
    expect(library.visibleMedia('10').single.name, 'Loose.mp4');

    final marvel = library.childDirectories('10/Marvel').single;
    expect(marvel.name, 'Phase One');
    expect(marvel.mediaCount, 1);
    expect(
      library.visibleMedia('10/Marvel/Phase One').single.name,
      'Iron Man.mp4',
    );
  });

  test('search spans every root and matches folder paths', () {
    expect(library.visibleMedia('', searchQuery: 'iron').single.id, 3);
    expect(library.visibleMedia('10', searchQuery: 'season 1').single.id, 4);
  });

  test('breadcrumbs and parent navigation preserve virtual paths', () {
    final crumbs = library.breadcrumbs('10/Marvel/Phase One');

    expect(crumbs.map((item) => item.label), [
      'Library',
      'Movies',
      'Marvel',
      'Phase One',
    ]);
    expect(parentRemoteDirectory('10/Marvel/Phase One'), '10/Marvel');
    expect(parentRemoteDirectory('10'), '');
  });

  test('parses legacy flat library responses', () {
    final parsed = RemoteLibrary.fromJson({
      'media': [
        {'id': 7, 'name': 'Old.mp4', 'folder': 'Downloads'},
      ],
    });

    expect(parsed.roots.single.name, 'Downloads');
    expect(parsed.childDirectories('').single.name, 'Downloads');
    expect(parsed.visibleMedia(parsed.roots.single.id).single.id, 7);
  });
}
