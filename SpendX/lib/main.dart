import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'models/account.dart';
import 'models/transaction.dart';
import 'models/budget.dart';
import 'models/category.dart';
import 'models/goal.dart';
import 'providers/user_provider.dart';
import 'providers/account_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/category_provider.dart';
import 'providers/goal_provider.dart';
import 'models/recurring_transaction.dart';
import 'providers/recurring_transaction_provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/permission_screen.dart';
import 'screens/main_navigation.dart';
import 'providers/theme_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:package_info_plus/package_info_plus.dart';
import 'widgets/version_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Adapters
  Hive.registerAdapter(AccountAdapter());
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(BudgetAdapter());
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(GoalAdapter());
  Hive.registerAdapter(RecurringTransactionAdapter());
  Hive.registerAdapter(FrequencyAdapter());

  // Open Boxes
  await Hive.openBox<Account>('accounts');
  await Hive.openBox<Transaction>('transactions');
  await Hive.openBox<Budget>('budgets');
  await Hive.openBox<Category>('categories');
  await Hive.openBox<Goal>('goals');
  await Hive.openBox<RecurringTransaction>('recurring_transactions');

  runApp(const SpendXApp());
}

class SpendXApp extends StatelessWidget {
  const SpendXApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()..loadUser()),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()..init()),
        ChangeNotifierProvider(create: (_) => GoalProvider()),
        ChangeNotifierProvider(create: (_) => RecurringTransactionProvider()..init()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'SpendX',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              brightness: Brightness.light,
              scaffoldBackgroundColor: Colors.white,
              primaryColor: const Color(0xFF5bd43d),
              fontFamily: 'Poppins',
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF5bd43d),
                secondary: Color(0xFF5bd43d),
                background: Colors.white,
                surface: Color(0xFFF5F5F5),
              ),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: Colors.black,
              primaryColor: const Color(0xFF5bd43d),
              fontFamily: 'Poppins',
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF5bd43d),
                secondary: Color(0xFF5bd43d),
                background: Colors.black,
                surface: Color(0xFF101010),
              ),
              useMaterial3: true,
            ),
            home: const PermissionScreen(),
          );
        },
      ),
    );
  }
}

class StartupScreen extends StatefulWidget {
  const StartupScreen({Key? key}) : super(key: key);

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  bool _showRetry = false;

  @override
  void initState() {
    super.initState();
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.npoint.io/6f44b0101768be4b2c87'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = data['latest_version'] as String;
        
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        if (_isUpdateAvailable(currentVersion, latestVersion)) {
          if (!mounted) return;
          
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => VersionCheckDialog(
              currentVersion: currentVersion,
              latestVersion: latestVersion,
              updateDate: data['update_date'],
              updateSize: data['update_size'],
              changelog: List<String>.from(data['changelog']),
              updateLink: data['update_link'],
            ),
          );
        } else {
          _checkUser();
        }
      } else {
        _checkUser();
      }
    } catch (e) {
      debugPrint('Version check error: $e');
      _checkUser();
    }
  }

  bool _isUpdateAvailable(String current, String latest) {
    List<int> currentParts = current.split('.').map(int.parse).toList();
    List<int> latestParts = latest.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      int currentPart = i < currentParts.length ? currentParts[i] : 0;
      int latestPart = i < latestParts.length ? latestParts[i] : 0;

      if (latestPart > currentPart) return true;
      if (latestPart < currentPart) return false;
    }
    return false;
  }

  Future<void> _checkUser() async {
    final userProvider = context.read<UserProvider>();
    final isLoggedIn = await userProvider.isUserLoggedIn();
    
    if (!mounted) return;

    if (isLoggedIn) {
      final storage = const FlutterSecureStorage();
      final biometricEnabled = await storage.read(key: 'biometric_enabled') == 'true';
      
      if (biometricEnabled) {
        final localAuth = LocalAuthentication();
        bool didAuthenticate = false;
        try {
          didAuthenticate = await localAuth.authenticate(
            localizedReason: 'Please authenticate to access SpendX',
          );
        } catch (e) {
          debugPrint('Biometric error: $e');
        }

        if (!didAuthenticate) {
          setState(() {
            _showRetry = true;
          });
          return;
        }
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
        
        // Check for recurring transactions
        final recurringProvider = context.read<RecurringTransactionProvider>();
        final transactionProvider = context.read<TransactionProvider>();
        final accountProvider = context.read<AccountProvider>();
        recurringProvider.checkAndGenerateTransactions(transactionProvider, accountProvider);
      }
    } else {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _showRetry
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Authentication Required',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showRetry = false;
                      });
                      _checkUser();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5bd43d),
                    ),
                    child: const Text('Retry', style: TextStyle(color: Colors.black)),
                  ),
                ],
              )
            : const CircularProgressIndicator(
                color: Color(0xFF5bd43d),
              ),
      ),
    );
  }
}
