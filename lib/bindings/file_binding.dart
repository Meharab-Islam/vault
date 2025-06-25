import 'package:get/get.dart';
import '../controllers/file_hider_controller.dart';

class FileBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(FileHiderController());
  }
}
