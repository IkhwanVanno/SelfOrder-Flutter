import 'package:flutter/material.dart';
import 'package:selforder/models/siteconfig_model.dart';
import 'package:selforder/services/api_service.dart';
import 'package:selforder/pages/loginpage.dart';
import 'package:selforder/pages/profilepage.dart';
import 'package:selforder/pages/registerpage.dart';
import 'package:selforder/pages/cartpage.dart';
import 'package:selforder/pages/homepage.dart';
import 'package:selforder/pages/orderpage.dart';
import 'package:selforder/services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SelfOrder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const MainPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _bottomNavIndex = 0;
  bool _isAuthenticated = false;
  Map<String, dynamic>? _currentUser;
  int _cartItemCount = 0;

  SiteConfig? _siteConfig;
  bool _isLoadingConfig = true;

  final List<Widget> _pages = const [
    HomePage(),
    OrderPage(),
    CartPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadSiteConfig();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final user = await AuthService.fetchCurrentMember();
    if (user != null) {
      setState(() {
        _isAuthenticated = true;
        _currentUser = {
          'FirstName': user.firstName,
          'Surname': user.surname,
          'Email': user.email,
        };
      });
    }
  }

  void _loadSiteConfig() async {
    try {
      final config = await ApiService.fetchSiteConfig();
      setState(() {
        _siteConfig = config;
        _isLoadingConfig = false;
      });
    } catch (e) {
      print('Error loading site config: $e');
      setState(() {
        _isLoadingConfig = false;
      });
    }
  }

  void _onButtonNavTapped(int index) {
    setState(() {
      _bottomNavIndex = index;
    });
  }

  void _navigateToLogin() {
    Navigator.pushNamed(context, '/login').then((result) {
      if (result == true) {
        setState(() {
          _isAuthenticated = true;
          _currentUser = {
            'FirstName': 'John',
            'Surname': 'Doe',
            'Email': 'john.doe@example.com',
          };
        });
      }
    });
  }

  void _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah kamu yakin ingin keluar?'),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await AuthService.logout();
      if (result) {
        setState(() {
          _isAuthenticated = false;
          _currentUser = null;
          _cartItemCount = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logout berhasil'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal logout'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: _isLoadingConfig
            ? const Text("Loading...")
            : Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    _siteConfig?.title ?? "SelfOrder",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _siteConfig != null &&
                              _siteConfig!.imageURL.startsWith("http")
                          ? Image.network(
                              _siteConfig!.imageURL,
                              height: 30,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  "images/cafe.png",
                                  height: 30,
                                );
                              },
                            )
                          : Image.asset("images/cafe.png", height: 30),
                      _buildAuthButton(),
                    ],
                  ),
                ],
              ),
      ),
      body: IndexedStack(index: _bottomNavIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.black54,
        currentIndex: _bottomNavIndex,
        onTap: _onButtonNavTapped,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Order',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart),
                if (_cartItemCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        _cartItemCount > 99 ? '99+' : _cartItemCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Keranjang',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildAuthButton() {
    if (_isAuthenticated) {
      return PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'profile':
              setState(() {
                _bottomNavIndex = 3;
              });
              break;
            case 'logout':
              _handleLogout();
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'profile',
            child: Row(
              children: [
                Icon(Icons.person, size: 18),
                SizedBox(width: 8),
                Text('Profile'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout, size: 18),
                SizedBox(width: 8),
                Text('Logout'),
              ],
            ),
          ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(25),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                _getDisplayName(_currentUser),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
            ],
          ),
        ),
      );
    } else {
      return TextButton(
        onPressed: _navigateToLogin,
        style: TextButton.styleFrom(foregroundColor: Colors.white),
        child: const Text(
          'Masuk',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }
  }

  String _getDisplayName(Map<String, dynamic>? user) {
    if (user == null) return 'User';

    final firstName = user['FirstName'] ?? '';
    final lastName = user['Surname'] ?? '';

    if (firstName.isNotEmpty) {
      return firstName;
    } else if (lastName.isNotEmpty) {
      return lastName;
    } else {
      return user['Email']?.split('@')[0] ?? 'User';
    }
  }
}
