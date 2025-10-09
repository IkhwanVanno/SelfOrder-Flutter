import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:selforder/controllers/auth_controller.dart';
import 'package:selforder/controllers/siteconfig_controller.dart';
import 'package:selforder/routes/app_routes.dart';
import 'package:selforder/theme/app_theme.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final siteConfigController = Get.find<SiteConfigController>();

    final formKey = GlobalKey<FormState>();
    final firstnameController = TextEditingController();
    final lastnameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final obscurePassword = true.obs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar', style: TextStyle(color: AppColors.white)),
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

                    // Firstname & Lastname
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: firstnameController,
                            decoration: const InputDecoration(
                              labelText: 'Nama Depan',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Nama depan tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: lastnameController,
                            decoration: const InputDecoration(
                              labelText: 'Nama Belakang',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Nama belakang tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email tidak boleh kosong';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password
                    Obx(
                      () => TextFormField(
                        controller: passwordController,
                        obscureText: obscurePassword.value,
                        decoration: InputDecoration(
                          labelText: 'Sandi',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword.value
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              obscurePassword.value = !obscurePassword.value;
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Sandi tidak boleh kosong';
                          }
                          if (value.length < 6) {
                            return 'Sandi minimal 6 karakter';
                          }
                          return null;
                        },
                      ),
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
                                  firstnameController,
                                  lastnameController,
                                  emailController,
                                  passwordController,
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
                                    Text('Mendaftar...'),
                                  ],
                                )
                              : const Text(
                                  'Daftar Sekarang',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Register / Login with Google
                    Obx(
                      () => SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: authController.isLoading
                              ? null
                              : () async {
                                  final success = await authController
                                      .loginWithGoogle();
                                  if (success) {
                                    Get.snackbar(
                                      'Berhasil',
                                      'Login Google berhasil!',
                                      snackPosition: SnackPosition.TOP,
                                      backgroundColor: AppColors.green,
                                      colorText: AppColors.white,
                                    );
                                    await Future.delayed(
                                      const Duration(milliseconds: 500),
                                    );
                                    Get.offAllNamed(AppRoutes.MAIN);
                                  } else {
                                    Get.snackbar(
                                      'Gagal',
                                      'Login Google gagal!',
                                      snackPosition: SnackPosition.TOP,
                                      backgroundColor: AppColors.red,
                                      colorText: AppColors.white,
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: Image.asset(
                            'assets/images/google.png',
                            height: 24,
                            width: 24,
                          ),
                          label: authController.isLoading
                              ? const Text('Masuk dengan Google...')
                              : const Text('Daftar/Masuk dengan Google'),
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
    TextEditingController firstnameController,
    TextEditingController lastnameController,
    TextEditingController emailController,
    TextEditingController passwordController,
    AuthController authController,
  ) async {
    if (!formKey.currentState!.validate()) return;

    final success = await authController.register(
      firstnameController.text.trim(),
      lastnameController.text.trim(),
      emailController.text.trim(),
      passwordController.text,
    );

    if (success) {
      Get.snackbar(
        'Berhasil',
        'Pendaftaran berhasil',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.green,
        colorText: AppColors.white,
      );
      Get.offNamed(AppRoutes.LOGIN);
    } else {
      Get.snackbar(
        'Error',
        'Pendaftaran gagal',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.red,
        colorText: AppColors.white,
      );
    }
  }
}
