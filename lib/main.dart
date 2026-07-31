import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar_community/isar.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncy/controllers/room_controller.dart';
import 'package:syncy/services/recent_rooms_service.dart';
import 'package:syncy/services/lan/lan_host_service.dart';
import 'package:syncy/services/room_link_service.dart';
import 'package:syncy/services/update_service.dart';
import 'package:syncy/models/media.dart';
import 'package:syncy/models/user.dart';
import 'package:syncy/routes/app_pages.dart';
import 'package:syncy/services/thumbnail_service.dart';
import 'package:syncy/theme/app_theme.dart';
import 'package:syncy/utils/platform_utils.dart';
import 'package:window_manager/window_manager.dart';
import 'package:syncy/widgets/room_link_listener.dart';
import 'package:syncy/widgets/update_notification_listener.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (isDesktop) {
    // Desktop playback and thumbnails both run on media_kit, so libmpv has to
    // be loaded before anything constructs a Player.
    MediaKit.ensureInitialized();
    await _configureDesktopWindow();
  }

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
  await Get.putAsync(() => RecentRoomsService().init(), permanent: true);
  await Get.putAsync(() => RoomLinkService().init(), permanent: true);
  final updateService = Get.put(UpdateService(), permanent: true);
  // Room state owns the active socket and must remain a single app-wide
  // instance. Recreating it mid-room leaves fullscreen bound to a fresh,
  // disconnected controller while the portrait screen still has the old one.
  Get.put(RoomController(), permanent: true);

  if (isDesktop) {
    // The desktop can host its library on the LAN for paired phones to stream.
    // Started after Isar so the server can read the indexed media immediately.
    final host = LanHostService();
    Get.put(host, permanent: true);
    unawaited(host.start());
  }

  runApp(const MyApp());
  unawaited(updateService.init().then((service) => service.check()));
}

/// Gives the desktop build a real window: a comfortable default size and a
/// floor below which the sidebar-plus-grid layout would start to break down.
Future<void> _configureDesktopWindow() async {
  await windowManager.ensureInitialized();

  const options = WindowOptions(
    size: Size(1280, 800),
    minimumSize: Size(960, 640),
    center: true,
    title: 'Syncy',
    backgroundColor: Color(0xFF090512),
    titleBarStyle: TitleBarStyle.normal,
  );

  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });
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
      builder: (context, child) => UpdateNotificationListener(
        child: RoomLinkListener(child: child ?? const SizedBox.shrink()),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
