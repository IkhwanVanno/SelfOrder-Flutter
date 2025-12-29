import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:selforder/models/app_version_model.dart';
import 'package:selforder/services/api_service.dart';

class VersionController extends GetxController {
  var isLoading = false.obs;
  var currentVersion = ''.obs;
  var serverVersion = Rx<AppVersion?>(null);
  var needsUpdate = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkVersion();
  }

  Future<void> checkVersion() async {
    try {
      isLoading.value = true;

      // Get current app version dari package info
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      currentVersion.value = packageInfo.version;

      // Get server version
      AppVersion version = await ApiService.checkAppVersion();
      serverVersion.value = version;

      // Compare versions
      int comparison = AppVersion.compareVersions(
        currentVersion.value,
        version.version,
      );

      // Jika versi server lebih baru, maka perlu update
      needsUpdate.value = comparison < 0;

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      print('Error checking version: $e');
      // Jika error, anggap tidak perlu update
      needsUpdate.value = false;
    }
  }

  String getVersionStatus() {
    if (serverVersion.value == null) return 'Unknown';
    return serverVersion.value!.status;
  }

  String getReleaseDate() {
    if (serverVersion.value == null) return '';
    return serverVersion.value!.releaseDate;
  }
}
