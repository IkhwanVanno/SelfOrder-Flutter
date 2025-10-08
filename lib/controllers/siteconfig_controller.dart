import 'package:get/get.dart';
import 'package:selforder/models/siteconfig_model.dart';
import 'package:selforder/services/api_service.dart';

class SiteConfigController extends GetxController {
  final _siteConfig = Rx<SiteConfig?>(null);
  final _isLoading = false.obs;

  SiteConfig? get siteConfig => _siteConfig.value;
  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    loadSiteConfig();
  }

  Future<void> loadSiteConfig() async {
    if (_siteConfig.value != null) return; // Jangan load ulang jika sudah ada
    
    _isLoading.value = true;
    try {
      final config = await ApiService.fetchSiteConfig();
      _siteConfig.value = config;
    } catch (e) {
      print('Failed to load site config: $e');
    } finally {
      _isLoading.value = false;
    }
  }
}