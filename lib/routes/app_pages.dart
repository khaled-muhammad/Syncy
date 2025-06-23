import 'package:get/get.dart';
import 'package:syncy/bindings/home_binding.dart';
import 'package:syncy/bindings/profile_binding.dart';
import 'package:syncy/bindings/settings_binding.dart';
import 'package:syncy/routes/app_routes.dart';
import 'package:syncy/screens/home/home_screen.dart';
import 'package:syncy/screens/profile/profile_screen.dart';
import 'package:syncy/screens/room/room_screen.dart';
import 'package:syncy/screens/settings/settings_screen.dart';

class AppPages {
  // ignore: constant_identifier_names
  static const INITIAL = Routes.HOME;

  static final routes = [
    GetPage(
      name: Routes.HOME,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: Routes.SETTINGS,
      page: () => const SettingsScreen(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: Routes.PROFILE,
      page: () => const ProfileScreen(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: Routes.ROOM,
      page: () => const RoomScreen(),
    ),
  ];
}
