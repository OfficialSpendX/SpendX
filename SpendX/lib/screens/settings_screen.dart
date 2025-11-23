import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import 'category_management_screen.dart';
import 'privacy_policy_screen.dart';
import 'recurring_transactions_screen.dart';
import 'onboarding_screen.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/goal.dart';
import '../models/recurring_transaction.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _biometricEnabled = false;
  bool _isCheckingBiometric = true;
  String _selectedAvatar = '7'; // Default avatar

  // Premium Colors
  static const Color _accentPurple = Color(0xFF5E60CE);
  static const Color _accentGreen = Color(0xFF2ECC71);
  static const Color _accentBlue = Color(0xFF4EA8DE);
  static const Color _accentOrange = Color(0xFFFF9F1C);

  @override
  void initState() {
    super.initState();
    _loadBiometricSetting();
    _loadAvatar();
    
    // Check for pending restore on init (after frame)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingRestore();
    });
  }

  void _checkPendingRestore() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final path = userProvider.pendingRestorePath;
    
    if (path != null) {
      // Clear it immediately so we don't loop
      userProvider.setPendingRestorePath(null);
      
      // Resume restore process
      await _processRestoreFile(path);
    }
  }

  Future<void> _processRestoreFile(String path) async {
    try {
      final file = File(path);
      final encryptedContent = await file.readAsString();

      if (!mounted) return;

      final password = await _showPasswordDialog(isBackup: false);
      if (password == null || password.isEmpty) return;

      String jsonData;
      try {
        jsonData = _decryptData(encryptedContent, password);
      } catch (e) {
        if (mounted) _showMessage('Decryption failed. Wrong password?');
        return;
      }

      final backup = jsonDecode(jsonData);

      final userData = backup['user'];
      await _storage.write(key: 'name', value: userData['name']);
      await _storage.write(key: 'mobile', value: userData['mobile']);
      await _storage.write(key: 'username', value: userData['username']);

      final accountBox = Hive.box<Account>('accounts');
      final transactionBox = Hive.box<Transaction>('transactions');
      await accountBox.clear();
      await transactionBox.clear();

      for (final accountData in backup['accounts']) {
        await accountBox.add(
          Account(
            id: accountData['id'],
            name: accountData['name'],
            type: accountData['type'],
            balance: (accountData['balance'] as num).toDouble(),
            imagePath: accountData['imagePath'],
            isDefault: accountData['isDefault'] as bool,
          ),
        );
      }

      for (final transactionData in backup['transactions']) {
        await transactionBox.add(
          Transaction(
            id: transactionData['id'],
            accountId: transactionData['accountId'],
            amount: (transactionData['amount'] as num).toDouble(),
            type: transactionData['type'],
            category: transactionData['category'],
            date: DateTime.parse(transactionData['date']),
            note: transactionData['note'],
          ),
        );
      }

      if (mounted) {
        context.read<UserProvider>().loadUser();
        _showMessage('Data restored successfully');
      }
    } catch (e) {
      if (mounted) _showMessage('Restore failed: ${e.toString()}');
    }
  }

  Future<void> _restoreData() async {
    try {
      // Capture provider before async gap
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result == null) return;

      final path = result.files.single.path;
      if (path == null) {
        if (mounted) _showMessage('Error: Cannot read file path');
        return;
      }

      if (mounted) {
        // If still mounted, process directly
        await _processRestoreFile(path);
      } else {
        // If unmounted (activity recreated), save path to provider
        // The new instance will pick it up in initState -> _checkPendingRestore
        userProvider.setPendingRestorePath(path);
      }
    } catch (e) {
      if (mounted) _showMessage('Restore failed: ${e.toString()}');
    }
  }

  Future<void> _loadAvatar() async {
    final savedAvatar = await _storage.read(key: 'user_avatar');
    if (!mounted) return;
    setState(() {
      _selectedAvatar = savedAvatar ?? '7';
    });
  }

  Future<void> _saveAvatar(String avatarNumber) async {
    await _storage.write(key: 'user_avatar', value: avatarNumber);
    if (!mounted) return;
    setState(() {
      _selectedAvatar = avatarNumber;
    });
  }

  Future<void> _showAvatarSelection() async {
    final selectedAvatar = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Select Avatar'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final avatarNumber = '${index + 1}';
              final isSelected = avatarNumber == _selectedAvatar;
              return GestureDetector(
                onTap: () => Navigator.pop(context, avatarNumber),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? _accentPurple : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage('assets/img/avatar/$avatarNumber.jpg'),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedAvatar != null) {
      await _saveAvatar(selectedAvatar);
    }
  }

  Future<void> _loadBiometricSetting() async {
    final enabled = await _storage.read(key: 'biometric_enabled');
    if (!mounted) return;
    setState(() {
      _biometricEnabled = enabled == 'true';
      _isCheckingBiometric = false;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        _showMessage('Biometric authentication not available on this device');
        return;
      }

      if (value) {
        final didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Please authenticate to enable biometric login',
        );

        if (didAuthenticate) {
          await _storage.write(key: 'biometric_enabled', value: 'true');
          if (!mounted) return;
          setState(() => _biometricEnabled = true);
          _showMessage('Biometric authentication enabled');
        }
      } else {
        await _storage.delete(key: 'biometric_enabled');
        if (!mounted) return;
        setState(() => _biometricEnabled = false);
        _showMessage('Biometric authentication disabled');
      }
    } catch (e) {
      _showMessage('Error: ${e.toString()}');
    }
  }

  Future<void> _backupData() async {
    final password = await _showPasswordDialog(isBackup: true);
    if (password == null || password.isEmpty) return;

    try {
      final accountBox = Hive.box<Account>('accounts');
      final transactionBox = Hive.box<Transaction>('transactions');

      final userName = await _storage.read(key: 'name');
      final userMobile = await _storage.read(key: 'mobile');
      final userUsername = await _storage.read(key: 'username');

      final backup = {
        'user': {
          'name': userName,
          'mobile': userMobile,
          'username': userUsername,
        },
        'accounts': accountBox.values.map((a) {
          return {
            'id': a.id,
            'name': a.name,
            'type': a.type,
            'balance': a.balance,
            'imagePath': a.imagePath,
            'isDefault': a.isDefault,
          };
        }).toList(),
        'transactions': transactionBox.values.map((t) {
          return {
            'id': t.id,
            'accountId': t.accountId,
            'amount': t.amount,
            'type': t.type,
            'category': t.category,
            'date': t.date.toIso8601String(),
            'note': t.note,
          };
        }).toList(),
        'backupDate': DateTime.now().toIso8601String(),
      };

      final jsonData = jsonEncode(backup);
      final encryptedData = _encryptData(jsonData, password);

      String? path;
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        // Try standard public download folder
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          path = downloadDir.path;
        }
      }

      if (path == null) {
        final directory = await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
        path = directory.path;
      }

      final file = File(
        '$path/spendx_backup_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await file.writeAsString(encryptedData);

      _showMessage('Backup saved to ${file.path}');
    } catch (e) {
      _showMessage('Backup failed: ${e.toString()}');
    }
  }



  // --- Encryption Helpers ---

  String _encryptData(String plainText, String password) {
    final key = encrypt.Key.fromUtf8(sha256.convert(utf8.encode(password)).toString().substring(0, 32));
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return jsonEncode({
      'iv': iv.base64,
      'content': encrypted.base64,
    });
  }

  String _decryptData(String encryptedText, String password) {
    final key = encrypt.Key.fromUtf8(sha256.convert(utf8.encode(password)).toString().substring(0, 32));
    final data = jsonDecode(encryptedText);
    final iv = encrypt.IV.fromBase64(data['iv']);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    return encrypter.decrypt(encrypt.Encrypted.fromBase64(data['content']), iv: iv);
  }

  Future<void> _resetApp() async {
    try {
      // 1. Clear User Provider (Secure Storage & State)
      await Provider.of<UserProvider>(context, listen: false).clearUser();

      // 2. Clear Hive Boxes
      await Hive.box<Account>('accounts').clear();
      await Hive.box<Transaction>('transactions').clear();
      await Hive.box<Budget>('budgets').clear();
      await Hive.box<Category>('categories').clear();
      await Hive.box<Goal>('goals').clear();
      await Hive.box<RecurringTransaction>('recurring_transactions').clear();

      if (!mounted) return;

      // 3. Navigate to Onboarding
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        (route) => false,
      );
      
    } catch (e) {
      _showMessage('Reset failed: ${e.toString()}');
    }
  }

  void _showResetAppDialog() {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isEnabled = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF1E1E1E), const Color(0xFF2D2D2D)]
                    : [Colors.white, const Color(0xFFF8F9FA)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.red.withOpacity(0.8),
                          Colors.orange.withOpacity(0.8),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      FontAwesomeIcons.triangleExclamation,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Reset Application?',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This action is irreversible. All your data including accounts, transactions, and settings will be permanently deleted.',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08),
                      ),
                    ),
                    child: TextField(
                      controller: controller,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type CONFIRM',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                          fontSize: 14,
                          letterSpacing: 0,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      onChanged: (value) {
                        setState(() {
                          isEnabled = value == 'CONFIRM';
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                              ),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[700],
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Opacity(
                          opacity: isEnabled ? 1.0 : 0.5,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.red, Colors.orange],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: isEnabled
                                  ? [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 5),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: ElevatedButton(
                              onPressed: isEnabled
                                  ? () {
                                      Navigator.pop(context);
                                      _resetApp();
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Reset',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _showPasswordDialog({required bool isBackup}) async {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool obscureText = true;
    
    return showDialog<String>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF1E1E1E),
                        const Color(0xFF2D2D2D),
                      ]
                    : [
                        Colors.white,
                        const Color(0xFFF8F9FA),
                      ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _accentPurple.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(22.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon with gradient background
                    Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _accentPurple.withOpacity(0.8),
                            _accentBlue.withOpacity(0.8),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _accentPurple.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        isBackup ? FontAwesomeIcons.lock : FontAwesomeIcons.unlockKeyhole,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Title
                    Text(
                      isBackup ? 'Set Backup Password' : 'Enter Backup Password',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    
                    // Subtitle
                    Text(
                      isBackup 
                          ? 'Create a strong password to encrypt your backup'
                          : 'Enter the password to decrypt your backup',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 13,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    
                    // Password TextField
                    Container(
                      decoration: BoxDecoration(
                        color: isDark 
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark 
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.08),
                        ),
                      ),
                      child: TextField(
                        controller: controller,
                        obscureText: obscureText,
                        autofocus: true,
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter password',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 12, right: 8),
                            child: Icon(
                              FontAwesomeIcons.key,
                              color: _accentPurple,
                              size: 18,
                            ),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureText 
                                  ? FontAwesomeIcons.eye 
                                  : FontAwesomeIcons.eyeSlash,
                              size: 18,
                              color: isDark ? Colors.grey[600] : Colors.grey[400],
                            ),
                            onPressed: () {
                              setState(() {
                                obscureText = !obscureText;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark 
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _accentPurple,
                                  _accentBlue,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: _accentPurple.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context, controller.text),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isBackup 
                                        ? FontAwesomeIcons.floppyDisk 
                                        : FontAwesomeIcons.arrowRotateLeft,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isBackup ? 'Save' : 'Restore',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=SpendX Support Request',
    );
    
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(
          emailUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showMessage('Could not open email client');
      }
    } catch (e) {
      _showMessage('Error opening email: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F8);
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryText = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final secondaryText = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Settings',
          style: TextStyle(
            color: primaryText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            _buildProfileSection(context, isDark, primaryText, secondaryText),
            const SizedBox(height: 30),
            
            _buildSectionHeader('Preferences', secondaryText),
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) {
                      return _buildSettingsTile(
                        title: 'Dark Mode',
                        subtitle: 'Toggle app theme',
                        icon: isDark ? Icons.dark_mode : Icons.light_mode,
                        iconColor: _accentPurple,
                        isDark: isDark,
                        showDivider: true,
                        trailing: Switch.adaptive(
                          value: themeProvider.isDarkMode,
                          onChanged: themeProvider.toggleTheme,
                          activeColor: _accentPurple,
                        ),
                      );
                    },
                  ),
                  _buildSettingsTile(
                    title: 'Categories',
                    subtitle: 'Manage custom categories',
                    icon: FontAwesomeIcons.tags,
                    iconColor: _accentOrange,
                    isDark: isDark,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryManagementScreen())),
                    showDivider: true,
                  ),
                  _buildSettingsTile(
                    title: 'Recurring Transactions',
                    subtitle: 'Manage automated transactions',
                    icon: FontAwesomeIcons.arrowsRotate,
                    iconColor: _accentBlue,
                    isDark: isDark,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecurringTransactionsScreen())),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _buildSectionHeader('Security', secondaryText),
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: _buildSettingsTile(
                title: 'Biometric Login',
                subtitle: 'Secure with FaceID or Fingerprint',
                icon: FontAwesomeIcons.fingerprint,
                iconColor: _accentGreen,
                isDark: isDark,
                trailing: Switch.adaptive(
                  value: _biometricEnabled,
                  onChanged: _isCheckingBiometric ? null : _toggleBiometric,
                  activeColor: _accentGreen,
                ),
              ),
            ),

            const SizedBox(height: 24),

            _buildSectionHeader('Data Management', secondaryText),
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildSettingsTile(
                    title: 'Backup Data',
                    subtitle: 'Save to device storage',
                    icon: FontAwesomeIcons.cloudArrowUp,
                    iconColor: _accentBlue,
                    isDark: isDark,
                    onTap: _backupData,
                    showDivider: true,
                  ),
                  _buildSettingsTile(
                    title: 'Restore Data',
                    subtitle: 'Import from backup file',
                    icon: FontAwesomeIcons.cloudArrowDown,
                    iconColor: _accentOrange,
                    isDark: isDark,
                    onTap: _restoreData,
                    showDivider: true,
                  ),
                  _buildSettingsTile(
                    title: 'Reset App',
                    subtitle: 'Clear all data and reset',
                    icon: FontAwesomeIcons.triangleExclamation,
                    iconColor: Colors.red,
                    isDark: isDark,
                    onTap: _showResetAppDialog,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _buildSectionHeader('About', secondaryText),
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildSettingsTile(
                    title: 'Version',
                    subtitle: '1.0.0',
                    icon: FontAwesomeIcons.codeBranch,
                    iconColor: Colors.grey,
                    isDark: isDark,
                    trailing: const SizedBox(),
                    showDivider: true,
                  ),
                  _buildSettingsTile(
                    title: 'Privacy Policy',
                    subtitle: 'Data usage & protection',
                    icon: FontAwesomeIcons.shieldHalved,
                    iconColor: const Color(0xFF2ECC71),
                    isDark: isDark,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                    showDivider: true,
                  ),
                  _buildSettingsTile(
                    title: 'Contact Support',
                    subtitle: 'contact.spendx@zohomail.in',
                    icon: FontAwesomeIcons.envelope,
                    iconColor: _accentBlue,
                    isDark: isDark,
                    onTap: () => _launchEmail('contact.spendx@zohomail.in'),
                    showDivider: true,
                  ),
                  // Custom SpendX tile with logo image
                  Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.pinkAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.asset(
                                'assets/img/logo/logo2.png',
                                width: 30,
                                height: 30,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    FontAwesomeIcons.appStoreIos,
                                    color: Colors.pinkAccent,
                                    size: 20,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          'SpendX',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          'Personal Finance Tracker',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        trailing: const SizedBox(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, bool isDark, Color primaryText, Color? secondaryText) {
    final userProvider = Provider.of<UserProvider>(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showAvatarSelection,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _accentPurple,
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 35,
                backgroundImage: AssetImage('assets/img/avatar/$_selectedAvatar.jpg'),
                backgroundColor: _accentPurple.withOpacity(0.2),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userProvider.user?.name ?? 'User',
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userProvider.user?.username ?? 'username',
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 14,
                  ),
                ),
                if ((userProvider.user?.mobile ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    userProvider.user!.mobile,
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color? color) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    Widget? trailing,
    VoidCallback? onTap,
    bool showDivider = false,
  }) {
    final primaryText = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final secondaryText = isDark ? Colors.grey[400] : Colors.grey[600];

    return Column(
      children: [
        ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: primaryText,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: secondaryText,
              fontSize: 13,
            ),
          ),
          trailing: trailing ?? Icon(
            Icons.arrow_forward_ios_rounded,
            color: secondaryText,
            size: 16,
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 70,
            color: isDark ? Colors.grey[800] : Colors.grey[200],
          ),
      ],
    );
  }
}
