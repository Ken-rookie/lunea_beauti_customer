import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/auth_screens.dart';
import 'screens/app_shell.dart';
import 'screens/order_screens.dart';
import 'screens/welcome_screen.dart';
import 'services/shop_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://zmclothzxbaaxiedlgvi.supabase.co',
    publishableKey: 'sb_publishable_b1akULANrkBxOTZLFdnwpw_JPmM1cOD',
  );

  runApp(const LuneaBeautiApp());
}

class LuneaBeautiApp extends StatefulWidget {
  const LuneaBeautiApp({super.key});

  @override
  State<LuneaBeautiApp> createState() => _LuneaBeautiAppState();
}

class _LuneaBeautiAppState extends State<LuneaBeautiApp> {
  final ShopStore store = ShopStore();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lunéa Beauti Customer App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Builder(
        builder: (context) {
          final query = Uri.base.queryParameters;
          final paymentResult = query['payment'];

          if (paymentResult == 'success' || paymentResult == 'cancelled') {
            return PaymentReturnScreen(
              store: store,
              paymentResult: paymentResult!,
              orderId: query['order_id'],
              onContinueShopping: () => _openShop(context),
            );
          }

          return WelcomeScreen(
            onGetStarted: () => _openLogin(context),
            onLogin: () => _openLogin(context),
          );
        },
      ),
    );
  }

  void _openLogin(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => LoginScreen(store: store)));
  }

  void _openShop(BuildContext context) {
    final navigator = Navigator.of(context);
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => AppShell(
          store: store,
          onLogout: () => returnToLogin(navigator, store),
        ),
      ),
      (_) => false,
    );
  }
}
