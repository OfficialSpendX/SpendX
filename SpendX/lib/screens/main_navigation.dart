import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'accounts_screen.dart';
import 'transactions_screen.dart';
import 'stats_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'settings_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isLocked = false;

  final List<Widget> _screens = [
    const HomeScreen(),
    const AccountsScreen(),
    const TransactionsScreen(),
    const StatsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (!_isAuthenticating) {
        setState(() {
          _isLocked = true;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_isLocked && !_isAuthenticating) {
        _checkBiometric();
      }
    }
  }

  bool _isAuthenticating = false;

  Future<void> _checkBiometric() async {
    if (_isAuthenticating) return;

    final storage = const FlutterSecureStorage();
    final biometricEnabled = await storage.read(key: 'biometric_enabled') == 'true';

    if (!biometricEnabled) {
      if (mounted) {
        setState(() {
          _isLocked = false;
        });
      }
      return;
    }

    if (biometricEnabled) {
      setState(() {
        _isLocked = true;
        _isAuthenticating = true;
      });

      final localAuth = LocalAuthentication();
      bool didAuthenticate = false;
      try {
        didAuthenticate = await localAuth.authenticate(
          localizedReason: 'Please authenticate to access SpendX',
        );
      } catch (e) {
        debugPrint('Biometric error: $e');
      }

      if (mounted) {
        setState(() {
          _isLocked = !didAuthenticate;
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Color(0xFF5bd43d)),
              const SizedBox(height: 20),
              const Text(
                'App Locked',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _checkBiometric,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5bd43d),
                ),
                child: const Text('Unlock', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: const Color(0xFF101010),
          selectedItemColor: const Color(0xFF5bd43d),
          unselectedItemColor: Colors.grey[600],
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance),
              label: 'Accounts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: 'Transactions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Stats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
