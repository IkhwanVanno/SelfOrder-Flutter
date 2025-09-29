import 'package:flutter/material.dart';
import 'package:selforder/models/siteconfig_model.dart';
import 'package:selforder/services/api_service.dart';
import 'package:selforder/services/auth_service.dart';
import 'package:selforder/theme/app_theme.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  SiteConfig? _siteConfig;
  bool _isLoadingSiteConfig = true;

  @override
  void initState() {
    super.initState();
    _loadSiteConfig();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadSiteConfig() async {
    try {
      final siteConfig = await ApiService.fetchSiteConfig();
      setState(() {
        _siteConfig = siteConfig;
        _isLoadingSiteConfig = false;
      });
    } catch (e) {
      print('Gagal memuat SiteConfig: $e');
      setState(() {
        _isLoadingSiteConfig = false;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();

    try {
      final result = await AuthService.forgotPassword(email);

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        _showSuccessSnackBar(result['message']);
        _showSuccessDialog();
      } else {
        _showErrorSnackBar(result['message']);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Terjadi kesalahan. Silakan coba lagi.');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(
            Icons.mark_email_read,
            color: AppColors.green,
            size: 48,
          ),
          title: const Text(
            'Email Terkirim!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Link untuk mengatur ulang kata sandi telah dikirim ke ${_emailController.text.trim()}.\n\nSilakan periksa email Anda dan ikuti petunjuk yang diberikan.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Back to previous page
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
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lupa Kata Sandi', style: TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    if (_siteConfig != null && _siteConfig!.imageURL.isNotEmpty)
                      _siteConfig!.imageURL.startsWith('http')
                          ? Image.network(
                              _siteConfig!.imageURL,
                              height: 100,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  "assets/images/cafe.png",
                                  height: 100,
                                );
                              },
                            )
                          : Image.asset(
                              _siteConfig!.imageURL,
                              height: 100,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  "assets/images/cafe.png",
                                  height: 100,
                                );
                              },
                            )
                    else if (!_isLoadingSiteConfig)
                      Image.asset("assets/images/cafe.png", height: 100)
                    else
                      const SizedBox(height: 100),

                    const SizedBox(height: 12),

                    // Title
                    Text(
                      _siteConfig?.title ?? 'Self Order',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Description
                    const Text(
                      'Masukkan alamat email Anda untuk menerima link pengaturan ulang kata sandi',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submitForm(),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                        helperText: 'Masukkan email yang terdaftar di akun Anda',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email tidak boleh kosong';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
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
                    const SizedBox(height: 16),

                    // Back to Login Link
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
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
}