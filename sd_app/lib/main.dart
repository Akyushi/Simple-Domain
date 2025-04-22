import 'pages/home.dart';
import 'pages/login.dart'; // Import LoginPage
import 'pages/sign_up.dart'; // Import SignUpPage
import 'pages/terms.dart'; // Import TermsPage
import 'pages/wishlist.dart'; // Import WishlistPage
import 'pages/cart.dart'; // Import CartPage
import 'pages/search.dart'; // Import SearchPage
import 'pages/account.dart'; // Import AccountPage
import 'pages/shop.dart'; // Import ShopPage
import 'pages/product_details.dart'; // Import ProductDetailsPage
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import 'firebase_options.dart'; // Import Firebase options

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
        fontFamily: 'Jaldi',
      ),
      // home: Scaffold(
      //   appBar: AppBar(title: const Text('Test App')),
      //   body: const Center(child: Text('Flutter is working!')),
      // ),
      home: const HomePage(),
      routes: {
        '/login': (context) => const LoginPage(), // Add route for LoginPage
        '/sign_up': (context) => const SignUpPage(), // Add route for SignUpPage
        '/terms': (context) => const TermsPage(), // Add route for TermsPage
        '/home': (context) => const HomePage(), // Add route for HomePage
        '/wishlist': (context) => const WishlistPage(), // Add route for WishlistPage
        '/cart': (context) => const CartPage(), // Add route for CartPage
        '/search': (context) {
          final query = ModalRoute.of(context)!.settings.arguments as String;
          return SearchPage(query: query);
        },
        '/account': (context) => const AccountPage(), // Add route for AccountPage
        '/shop': (context) => const ShopPage(), // Added shop route
        '/product_details': (context) {
          final product = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ProductDetailsPage(product: product); // Add ProductDetailsPage route
        },
      },
    );
  }
}



