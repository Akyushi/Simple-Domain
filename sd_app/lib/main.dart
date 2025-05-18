import 'pages/home.dart';
import 'pages/login.dart';
import 'pages/sign_up.dart';
import 'pages/terms.dart';
import 'pages/wishlist.dart';
import 'pages/cart.dart';
import 'pages/search.dart';
import 'pages/account.dart';
import 'pages/shop.dart';
import 'pages/product_details.dart';
import 'pages/account_settings.dart';
import 'pages/seller.dart';
import 'pages/add_product.dart';
import 'pages/edit_product.dart';
import 'pages/about_us.dart'; // Import AboutUsPage
import 'pages/forgot_password.dart'; // Import ForgotPasswordPage
import 'pages/password_reset.dart'; // Import PasswordResetPage
import 'pages/admin_page.dart';
import 'pages/order_status.dart';
import 'pages/seller_store.dart';
import 'pages/admin_login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'widgets/bottom_navbar.dart'; // Import BottomNavBar
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAut
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("Firebase initialization error: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Domain',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: const MainScreen(), // Set MainScreen as the home
      routes: {
        '/login': (context) => const LoginPage(),
        '/sign_up': (context) => const SignUpPage(),
        '/terms': (context) => const TermsPage(),
        '/wishlist': (context) => const WishlistPage(),
        '/cart': (context) => const CartPage(),
        '/search': (context) {
          final query = ModalRoute.of(context)?.settings.arguments as String?;
          return SearchPage(query: query ?? '');
        },
        '/account': (context) => const AccountPage(),
        '/shop': (context) => const ShopPage(),
        '/product_details': (context) {
          final product = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return ProductDetailsPage(product: product ?? {});
        },
        '/account_settings': (context) => const AccountSettingsPage(),
        '/seller': (context) => const SellerPage(),
        '/add_product': (context) => const AddProductPage(),
        '/edit_product': (context) => const EditProductPage(),
        '/about_us': (context) => const AboutUsPage(),
        '/forgot_password': (context) => const ForgotPasswordPage(),
        '/password_reset': (context) => const PasswordResetPage(),
        '/admin': (context) => const AdminPage(),
        '/order_status': (context) => const OrderStatusPage(),
        '/seller_store': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return SellerStorePage(sellerId: args?['sellerId'] ?? '');
        },
        '/admin-login': (context) => const AdminLoginPage(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final List<Widget> _pages = [
    const HomePage(),
    const CartPage(),
    const WishlistPage(),
    const ShopPage(),
    const AccountPage(),
  ];


  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300), // Keep sliding animation
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser; // Get the current user

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: user != null
                ? null
                : const NeverScrollableScrollPhysics(), // Disable dragging if not logged in
            children: _pages,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: BottomNavBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
            ),
          ),
        ],
      ),
    );
  }
}



