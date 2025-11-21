import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:selforder/controllers/auth_controller.dart';
import 'package:selforder/controllers/siteconfig_controller.dart';
import 'package:selforder/theme/app_theme.dart';
import 'package:toastification/toastification.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final siteConfigController = Get.find<SiteConfigController>();

    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lupa Kata Sandi',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: formKey,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    Obx(() {
                      final siteConfig = siteConfigController.siteConfig;
                      if (siteConfig != null &&
                          siteConfig.imageURL.isNotEmpty) {
                        return siteConfig.imageURL.startsWith('http')
                            ? Image.network(
                                siteConfig.imageURL,
                                height: 100,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    "assets/images/cafe.png",
                                    height: 100,
                                  );
                                },
                              )
                            : Image.asset(
                                siteConfig.imageURL,
                                height: 100,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    "assets/images/cafe.png",
                                    height: 100,
                                  );
                                },
                              );
                      }
                      return Image.asset("assets/images/cafe.png", height: 100);
                    }),

                    const SizedBox(height: 12),

                    // Title
                    Obx(() {
                      final siteConfig = siteConfigController.siteConfig;
                      return Text(
                        siteConfig?.title ?? 'Self Order',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }),
                    const SizedBox(height: 32),

                    // Description
                    const Text(
                      'Masukkan alamat email Anda untuk menerima link pengaturan ulang kata sandi',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: AppColors.grey),
                    ),
                    const SizedBox(height: 24),

                    // Email Field
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) =>
                          _submitForm(formKey, emailController, authController),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                        helperText:
                            'Masukkan email yang terdaftar di akun Anda',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email tidak boleh kosong';
                        }
                        if (!RegExp(
                          r'^[^@]+@[^@]+\.[^@]+',
                        ).hasMatch(value.trim())) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    Obx(
                      () => SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: authController.isLoading
                              ? null
                              : () => _submitForm(
                                  formKey,
                                  emailController,
                                  authController,
                                ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: authController.isLoading
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppColors.white,
                                            ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Mengirim...'),
                                  ],
                                )
                              : const Text(
                                  'Kirim Link Reset',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Back to Login Link
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text(
                        'Kembali ke Halaman Masuk',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm(
    GlobalKey<FormState> formKey,
    TextEditingController emailController,
    AuthController authController,
  ) async {
    if (!formKey.currentState!.validate()) return;

    final result = await authController.forgotPassword(
      emailController.text.trim(),
    );

    if (result['success']) {
      toastification.show(
        type: ToastificationType.success,
        style: ToastificationStyle.flatColored,
        title: Text('Berhasil'),
        description: Text(
          'Link pengaturan ulang kata sandi telah dikirim ke email Anda.',
        ),
        autoCloseDuration: const Duration(seconds: 2),
        alignment: Alignment.topCenter,
      );
      _showSuccessDialog(emailController.text.trim());
    } else {
      toastification.show(
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        title: Text('Gagal'),
        description: Text(
          result['message'] ?? 'Terjadi kesalahan saat mengirim email.',
        ),
        autoCloseDuration: const Duration(seconds: 2),
        alignment: Alignment.topCenter,
      );
    }
  }

  void _showSuccessDialog(String email) {
    Get.dialog(
      AlertDialog(
        icon: const Icon(
          Icons.mark_email_read,
          color: AppColors.green,
          size: 48,
        ),
        title: const Text(
          'Email Terkirim!',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.green, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Link untuk mengatur ulang kata sandi telah dikirim ke $email.\n\nSilakan periksa email Anda dan ikuti petunjuk yang diberikan.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(); // Close dialog
              Get.back(); // Back to previous page
            },
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Kembali'),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
      barrierDismissible: false,
    );
  }
}
