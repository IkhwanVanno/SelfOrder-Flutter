import 'package:flutter/material.dart';
import 'package:selforder/pages/homepage.dart';
import 'package:selforder/pages/cartpage.dart';
import 'package:selforder/pages/orderpage.dart';
import 'package:selforder/pages/profilepage.dart';
import 'package:selforder/pages/loginpage.dart';
import 'package:selforder/pages/registerpage.dart';
import 'package:selforder/services/auth_service.dart';
import 'package:selforder/services/api_service.dart';
import 'package:selforder/models/siteconfig_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Self Order',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainNavigationWrapper(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
      },
    );
  }
}

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _selectedIndex = 0;
  SiteConfig? _siteConfig;
  bool _isLoadingSiteConfig = true;

  late Function() _authListener;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
    _loadSiteConfig();
  }

  @override
  void dispose() {
    AuthService.removeAuthStateListener(_authListener);
    super.dispose();
  }

  void _setupAuthListener() {
    _authListener = () {
      if (mounted) {
        setState(() {});
      }
    };
    AuthService.addAuthStateListener(_authListener);
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

  void _navigateToLogin() {
    Navigator.pushNamed(context, '/login').then((_) {});
  }

  final List<Widget> _pages = [
    const HomePage(),
    const CartPage(),
    const OrderPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Pindahkan logo ke leading
        leading: _siteConfig != null && _siteConfig!.imageURL.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: _siteConfig!.imageURL.startsWith('http')
                    ? Image.network(
                        _siteConfig!.imageURL,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            "images/cafe.png",
                            fit: BoxFit.contain,
                          );
                        },
                      )
                    : Image.asset(
                        _siteConfig!.imageURL,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            "images/cafe.png",
                            fit: BoxFit.contain,
                          );
                        },
                      ),
              )
            : !_isLoadingSiteConfig
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset("images/cafe.png", fit: BoxFit.contain),
              )
            : null,
        // Judul akan otomatis center
        title: Text(
          _siteConfig?.title ?? 'Self Order',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        actions: [
          if (AuthService.isLoggedIn && AuthService.currentUser != null) ...[
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  'Hi, ${AuthService.currentUser!.firstName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ] else ...[
            TextButton(
              onPressed: _navigateToLogin,
              child: const Text(
                'Masuk',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Rumah'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Keranjang',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Pesanan',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
