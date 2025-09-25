import 'package:flutter/material.dart';
import 'package:selforder/services/auth_service.dart';
import 'package:selforder/models/member_model.dart';
import 'package:selforder/theme/app_theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController firstnameController = TextEditingController();
  final TextEditingController lastnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  Member? _currentUser;

  late Function() _authListener;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
    _loadUserData();
  }

  @override
  void dispose() {
    firstnameController.dispose();
    lastnameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    AuthService.removeAuthStateListener(_authListener);
    super.dispose();
  }

  void _setupAuthListener() {
    _authListener = () {
      if (mounted) {
        setState(() {});
        if (AuthService.isLoggedIn) {
          _loadUserData();
        } else {
          _currentUser = null;
          _clearForm();
        }
      }
    };
    AuthService.addAuthStateListener(_authListener);
  }

  void _clearForm() {
    firstnameController.clear();
    lastnameController.clear();
    emailController.clear();
    passwordController.clear();
  }

  void _loadUserData() async {
    if (!AuthService.isLoggedIn) {
      setState(() {
        _currentUser = null;
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      Member? user = AuthService.currentUser;
      if (user == null) {
        user = await AuthService.fetchCurrentMember();
      }

      if (user != null) {
        setState(() {
          _currentUser = user;
          firstnameController.text = user!.firstName;
          lastnameController.text = user.surname;
          emailController.text = user.email;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Gagal memuat profil: ${e.toString()}');
    }
  }

  Future<void> submitForm() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await AuthService.updateProfile(
        firstnameController.text.trim(),
        lastnameController.text.trim(),
        emailController.text.trim(),
        password: passwordController.text.isNotEmpty
            ? passwordController.text
            : null,
      );

      setState(() => _isLoading = false);

      if (success) {
        passwordController.clear();
        _showSuccessSnackBar('Profile telah berhasil diperbarui!');
        _loadUserData();
      } else {
        _showErrorSnackBar('Profile gagal diperbarui');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batalkan'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
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
      setState(() => _isLoading = true);

      await AuthService.logout();

      setState(() => _isLoading = false);

      _showSuccessSnackBar('Berhasil keluar');
    }
  }

  void _navigateToLogin() {
    Navigator.pushNamed(context, '/login').then((_) {});
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.red),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isLoggedIn) {
      return _buildNotLoggedInView();
    }

    if (_isLoading && _currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
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
                    // Profile Picture
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.primary.withAlpha(25),
                            child: Text(
                              _currentUser != null
                                  ? '${_currentUser!.firstName.isNotEmpty ? _currentUser!.firstName[0] : 'U'}${_currentUser!.surname.isNotEmpty ? _currentUser!.surname[0] : ''}'
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
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
                    TextFormField(
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText:
                            'Kata Sandi Baru (Biarkan kosong untuk mempertahankan kata sandi saat ini)',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
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
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
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

                    const SizedBox(height: 16),

                    // Logout Button
                    SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _logout,
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotLoggedInView() {
    return Scaffold(
      body: Center(
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
                onPressed: _navigateToLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('Masuk'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
