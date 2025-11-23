import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../main.dart'; // To access StartupScreen

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({Key? key}) : super(key: key);

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    // Check if permissions are already granted
    // We only check for storage/photos now as SMS is removed
    final storageStatus = await Permission.storage.status;
    final photosStatus = await Permission.photos.status;
    
    // On Android 13+, storage might not work, so we accept photos as alternative
    final hasStorageAccess = storageStatus.isGranted || photosStatus.isGranted;

    if (hasStorageAccess) {
      _navigateToStartup();
    } else {
      setState(() {
        _isChecking = false;
      });
    }
  }

  void _navigateToStartup() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const StartupScreen()),
    );
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isChecking = true;
    });

    try {
      // Request Storage permission
      print('Requesting storage permission...');
      
      // First try the standard storage permission (works on Android 12 and below)
      PermissionStatus storageStatus = await Permission.storage.request();
      print('Storage permission result: ${storageStatus.name}');
      
      // If storage permission is denied/restricted (likely Android 13+), 
      // try Photos permission which provides file access on newer Android
      if (!storageStatus.isGranted) {
        print('Storage permission not granted, trying Photos permission for Android 13+...');
        await Future.delayed(const Duration(milliseconds: 500));
        
        final photosStatus = await Permission.photos.request();
        print('Photos permission result: ${photosStatus.name}');
        
        // Use photos status as fallback
        storageStatus = photosStatus;
      }

      setState(() {
        _isChecking = false;
      });

      if (storageStatus.isGranted) {
        print('Storage/Files permission granted, navigating to startup...');
        _navigateToStartup();
      } else {
        print('Storage permission not granted');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Storage/Files permission is required for backup functionality.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          
          if (storageStatus.isPermanentlyDenied) {
            _showSettingsDialog('Storage/Files');
          }
        }
      }
    } catch (e) {
      print('Error requesting permissions: $e');
      setState(() {
        _isChecking = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting permissions: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showSettingsDialog(String permissionType) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Permission Denied', style: TextStyle(color: Colors.white)),
        content: Text(
          'You have permanently denied $permissionType permission. Please enable it in the app settings to proceed.',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings', style: TextStyle(color: Color(0xFF5bd43d))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF5bd43d))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                FontAwesomeIcons.shieldHalved,
                size: 80,
                color: Color(0xFF5bd43d),
              ),
              const SizedBox(height: 32),
              const Text(
                'Permissions Required',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'To provide you with the best experience, SpendX needs access to Storage and Network.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              _buildPermissionItem(
                icon: FontAwesomeIcons.folderOpen,
                title: 'Storage Access',
                description: 'To securely backup and restore your financial data.',
              ),
              const SizedBox(height: 16),
              _buildPermissionItem(
                icon: FontAwesomeIcons.wifi,
                title: 'Network Access',
                description: 'Only for checking app updates to ensure you have the latest version.',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _requestPermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5bd43d),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Allow Permissions',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF5bd43d).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF5bd43d), size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
