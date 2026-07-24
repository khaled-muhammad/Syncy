import 'package:get/get.dart';
import 'package:syncy/controllers/home_controller.dart';
import 'package:syncy/controllers/library_controller.dart';
import 'package:syncy/utils/platform_utils.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    if (isDesktop) {
      // Desktop browses a user-curated set of folders instead of scanning the
      // device, so HomeController's automatic scan is never started here.
      Get.lazyPut<LibraryController>(() => LibraryController());
    } else {
      Get.lazyPut<HomeController>(() => HomeController());
    }
  }
}
