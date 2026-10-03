import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'presentation/view_models/app_mode_view_model.dart';
import 'presentation/view_models/auth_view_model.dart';
import 'presentation/view_models/customer_view_model.dart';
import 'presentation/view_models/inventory_view_model.dart';
import 'presentation/view_models/pos_view_model.dart';
import 'presentation/views/auth/merchant_auth_view.dart';
import 'presentation/views/customer/customer_portal_view.dart';
import 'presentation/views/shopkeeper/shopkeeper_shell_view.dart';
import 'presentation/view_models/notification_view_model.dart';
import 'data/services/notification_service.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    await Firebase.initializeApp();
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Firebase initialize notice: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppModeViewModel()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => PosViewModel()),
        ChangeNotifierProvider(create: (_) => InventoryViewModel()),
        ChangeNotifierProvider(create: (_) => CustomerViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
      ],
      child: const FMCGApp(),
    ),
  );
}

class FMCGApp extends StatelessWidget {
  const FMCGApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appMode = context.watch<AppModeViewModel>();
    final authVm = context.watch<AuthViewModel>();

    return MaterialApp(
      title: 'FMCG+ Retail POS & Ledger',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appMode.themeMode,
      locale: appMode.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: (authVm.isAuthenticated && authVm.isCustomer)
          ? const CustomerPortalView()
          : (authVm.isAuthenticated && authVm.isMerchant)
              ? (appMode.userType == UserType.customer
                  ? const CustomerPortalView()
                  : const ShopkeeperShellView())
              : appMode.userType == UserType.customer
                  ? const CustomerPortalView()
                  : MerchantAuthView(
                      viewModel: authVm,
                      onAuthenticated: () {},
                    ),
    );
  }
}
