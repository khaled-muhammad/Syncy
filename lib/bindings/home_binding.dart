import 'package:get/get.dart';
import 'package:syncy/controllers/home_controller.dart';
import 'package:syncy/utils/storage_helper.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
  }
}
