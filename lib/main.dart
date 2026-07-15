import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncy/controllers/room_controller.dart';
import 'package:syncy/models/media.dart';
import 'package:syncy/models/user.dart';
import 'package:syncy/routes/app_pages.dart';
import 'package:syncy/services/thumbnail_service.dart';
import 'package:syncy/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Isar
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open([
    FolderSchema,
    MediaSchema,
    UserSchema,
  ], directory: dir.path);
  Get.put(isar);

  // Initialize ThumbnailService
  Get.put(ThumbnailService());
  // Room state owns the active socket and must remain a single app-wide
  // instance. Recreating it mid-room leaves fullscreen bound to a fresh,
  // disconnected controller while the portrait screen still has the old one.
  Get.put(RoomController(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Syncy',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}
