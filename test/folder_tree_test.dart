import 'package:flutter_test/flutter_test.dart';
import 'package:syncy/controllers/library_controller.dart';

void main() {
  test('nests subfolders and counts videos at every level', () {
    final tree = buildFolderTree(r'D:\Media', [
      r'D:\Media\loose.mp4',
      r'D:\Media\Movies\heat.mkv',
      r'D:\Media\Movies\Marvel\ironman.mp4',
      r'D:\Media\Movies\Marvel\thor.mp4',
      r'D:\Media\Shows\ep1.mkv',
    ]);

    expect(tree.map((node) => node.name), ['Movies', 'Marvel', 'Shows']);

    final movies = tree.firstWhere((node) => node.name == 'Movies');
    expect(movies.depth, 0);
    // Everything beneath it, including the two nested Marvel files.
    expect(movies.totalCount, 3);
    // Only the file sitting directly in Movies/.
    expect(movies.directCount, 1);

    final marvel = tree.firstWhere((node) => node.name == 'Marvel');
    expect(marvel.depth, 1);
    expect(marvel.totalCount, 2);
    expect(marvel.directCount, 2);
  });

  test('a file directly in the root produces no folder node', () {
    final tree = buildFolderTree(r'D:\Media', [r'D:\Media\only.mp4']);

    expect(tree, isEmpty);
  });

  test('folder names keep the casing they have on disk', () {
    final tree = buildFolderTree(r'D:\Media', [
      r'D:\Media\Anime Series\OVA\ep1.mkv',
    ]);

    expect(tree.map((node) => node.name), ['Anime Series', 'OVA']);
  });

  test('a trailing separator on the root does not shift the tree', () {
    final withSlash = buildFolderTree(r'D:\Media\', [
      r'D:\Media\Movies\heat.mkv',
    ]);
    final withoutSlash = buildFolderTree(r'D:\Media', [
      r'D:\Media\Movies\heat.mkv',
    ]);

    expect(withSlash.single.name, 'Movies');
    expect(withSlash.single.path, withoutSlash.single.path);
  });

  test('posix roots are handled alongside windows ones', () {
    final tree = buildFolderTree('/home/me/videos', [
      '/home/me/videos/Clips/a.mp4',
    ]);

    expect(tree.single.name, 'Clips');
    expect(tree.single.path, '/home/me/videos/Clips');
  });

  test('a drive root indexes its top-level folders', () {
    final tree = buildFolderTree(r'E:\', [r'E:\Downloads\film.mp4']);

    expect(tree.single.name, 'Downloads');
    expect(tree.single.depth, 0);
  });
}
