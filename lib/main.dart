import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:selforder/pages/auth/forgotpasswordpage.dart';
import 'package:selforder/pages/auth/loginpage.dart';
import 'package:selforder/pages/auth/profilepage.dart';
import 'package:selforder/pages/auth/registerpage.dart';
import 'package:selforder/pages/cart/cartpage.dart';
import 'package:selforder/pages/home/homepage.dart';
import 'package:selforder/pages/order/orderpage.dart';
import 'package:selforder/services/api_service.dart';
import 'package:selforder/services/cart_service.dart';
import 'package:selforder/services/duitku_service.dart';
import 'package:selforder/services/pdf_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final apiService = ApiService();
  final cartService = CartService();

  // Load stored auth data and cart
  await apiService.loadAuthData();
  await cartService.loadCart();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService()),
        Provider<CartService>(create: (_) => CartService()),
        Provider<DuitkuService>(create: (_) => DuitkuService()),
        Provider<PdfService>(create: (_) => PdfService()),
      ],
      child: MaterialApp(
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
          '/forgot-password': (context) => const ForgotPassword(),
        },
      ),
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

  final List<Widget> _pages = const [
    HomePage(),
    OrderPage(),
    CartPage(),
    ProfilePage(),
  ];

  void _onButtonNavTapped(int index) {
    setState(() {
      _bottomNavIndex = index;
    });
  }

  void _navigateToLogin() {
    Navigator.pushNamed(context, '/login');
  }

  void _handleLogout() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final cartService = Provider.of<CartService>(context, listen: false);

    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        // Logout from API
        await apiService.logout();

        // Clear local cart
        await cartService.clearCart();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the app state
        setState(() {});
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiService>(
      builder: (context, apiService, child) {
        return Consumer<CartService>(
          builder: (context, cartService, child) {
            return Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.blue,
                automaticallyImplyLeading: false,
                title: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Text(
                      'SelfOrder',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image.asset("images/cafe.png", height: 30),
                        _buildAuthButton(apiService),
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
                        if (cartService.itemCount > 0)
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
                                cartService.itemCount > 99
                                    ? '99+'
                                    : cartService.itemCount.toString(),
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
          },
        );
      },
    );
  }

  Widget _buildAuthButton(ApiService apiService) {
    if (apiService.isAuthenticated) {
      return PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'profile':
              setState(() {
                _bottomNavIndex = 3; // Navigate to profile page
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
                _getDisplayName(apiService.currentUser),
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

// Error Handler Widget
class ErrorHandler extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorHandler({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Loading Widget
class LoadingWidget extends StatelessWidget {
  final String? message;

  const LoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: TextStyle(color: Colors.grey[600])),
          ],
        ],
      ),
    );
  }
}
