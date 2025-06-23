import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:realm/realm.dart';
import 'package:syncy/controllers/room_controller.dart';
import 'package:syncy/models/media.dart';
import 'package:syncy/models/user.dart';
import 'package:syncy/routes/app_pages.dart';
import 'package:syncy/services/thumbnail_service.dart';
import 'package:syncy/theme/app_theme.dart';
import 'package:fvp/fvp.dart' as fvp;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var config = Configuration.local([Folder.schema, Media.schema, User.schema]);
  var realm = Realm(config);
  Get.put(realm);

  // Initialize ThumbnailService
  Get.put(ThumbnailService());
  Get.lazyPut<RoomController>(() => RoomController(), fenix: true);
  
  fvp.registerWith();
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
