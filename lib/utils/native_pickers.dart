import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart' as fs;
import 'package:syncy/utils/platform_utils.dart';

/// File and folder pickers that pick the right native implementation per
/// platform.
///
/// file_picker drives its Windows dialogs through hand-marshaled `comdlg32`
/// FFI, which access-violates (faulting module `comdlg32.dll`) when opening the
/// folder chooser on this build. `file_selector` uses the Flutter team's C++
/// `file_selector_windows` plugin instead, so desktop routes through it. Mobile
/// keeps file_picker, which works fine there and avoids disturbing the shipping
/// app.

/// Prompts for a directory and returns its path, or null if cancelled.
Future<String?> pickDirectory({String? title}) {
  if (isDesktop) {
    return fs.getDirectoryPath(confirmButtonText: 'Add');
  }
  return FilePicker.platform.getDirectoryPath(dialogTitle: title);
}

/// Prompts for a single subtitle file and returns its path, or null.
Future<String?> pickSubtitleFile() async {
  const extensions = ['srt', 'vtt', 'sub', 'ass', 'ssa', 'txt'];

  if (isDesktop) {
    const group = fs.XTypeGroup(label: 'Subtitles', extensions: extensions);
    final file = await fs.openFile(acceptedTypeGroups: const [group]);
    return file?.path;
  }

  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: extensions,
    allowMultiple: false,
  );
  return result?.files.first.path;
}
