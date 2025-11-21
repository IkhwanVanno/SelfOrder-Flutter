import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:selforder/controllers/auth_controller.dart';
import 'package:selforder/routes/app_routes.dart';
import 'package:selforder/theme/app_theme.dart';
import 'package:toastification/toastification.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      body: Obx(() {
        if (!authController.isLoggedIn) {
          return _buildNotLoggedInView();
        }

        if (authController.isLoading && authController.currentUser == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return _buildProfileForm(authController);
      }),
    );
  }

  Widget _buildNotLoggedInView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 80, color: AppColors.grey),
            const SizedBox(height: 16),
            Text(
              'Silahkan masuk untuk melihat profil anda',
              style: TextStyle(fontSize: 16, color: AppColors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Get.toNamed(AppRoutes.LOGIN),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Masuk'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileForm(AuthController authController) {
    final formKey = GlobalKey<FormState>();
    final firstnameController = TextEditingController(
      text: authController.currentUser?.firstName ?? '',
    );
    final lastnameController = TextEditingController(
      text: authController.currentUser?.surname ?? '',
    );
    final emailController = TextEditingController(
      text: authController.currentUser?.email ?? '',
    );
    final passwordController = TextEditingController();
    final obscurePassword = true.obs;

    return Center(
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
                  // Profile Picture
                  Center(
                    child: Stack(
                      children: [
                        Obx(() {
                          final user = authController.currentUser;
                          return CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.primary.withAlpha(25),
                            child: Text(
                              user != null
                                  ? '${user.firstName.isNotEmpty ? user.firstName[0] : 'U'}${user.surname.isNotEmpty ? user.surname[0] : ''}'
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 64),

                  // Firstname & Lastname
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: firstnameController,
                          decoration: const InputDecoration(
                            labelText: 'Nama depan',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nama depan wajib diisi';
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
                            labelText: 'Nama belakang',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nama belakang wajib diisi';
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
                        return 'Email wajib diisi';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Invalid email format';
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
                        labelText:
                            'Kata Sandi Baru (Biarkan kosong untuk mempertahankan kata sandi saat ini)',
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
                        if (value != null &&
                            value.isNotEmpty &&
                            value.length < 6) {
                          return 'Kata sandi harus terdiri dari minimal 6 karakter.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
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
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Menyimpan...'),
                                ],
                              )
                            : const Text(
                                'Simpan Perubahan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Logout Button
                  Obx(
                    () => SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: authController.isLoading
                            ? null
                            : () => _logout(authController),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.red,
                          side: const BorderSide(color: AppColors.red),
                        ),
                        child: const Text(
                          'Keluar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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

    final success = await authController.updateProfile(
      firstnameController.text.trim(),
      lastnameController.text.trim(),
      emailController.text.trim(),
      password: passwordController.text.isNotEmpty
          ? passwordController.text
          : null,
    );

    if (success) {
      passwordController.clear();
      toastification.show(
        type: ToastificationType.success,
        style: ToastificationStyle.flatColored,
        title: Text('Berhasil'),
        description: Text('Profile berhasil diperbarui'),
        autoCloseDuration: const Duration(seconds: 2),
        alignment: Alignment.topCenter,
      );
    } else {
      toastification.show(
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        title: Text('Gagal'),
        description: Text('Gagal memperbarui profile'),
        autoCloseDuration: const Duration(seconds: 2),
        alignment: Alignment.topCenter,
      );
    }
  }

  Future<void> _logout(AuthController authController) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batalkan'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text(
              'Keluar',
              style: TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await authController.logout();
      toastification.show(
        type: ToastificationType.success,
        style: ToastificationStyle.flatColored,
        title: Text('Berhasil'),
        description: Text('Anda telah keluar dari akun Anda.'),
        autoCloseDuration: const Duration(seconds: 2),
        alignment: Alignment.topCenter,
      );
    }
  }
}
