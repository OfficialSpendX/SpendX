import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F8);
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryText = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final secondaryText = (isDark ? Colors.grey[400] : Colors.grey[600]) ?? Colors.grey;
    const accentPurple = Color(0xFF5E60CE);
    const accentRed = Color(0xFFFF4D4D);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy Policy',
          style: TextStyle(
            color: primaryText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHighlightCard(
              context,
              isDark,
              surfaceColor,
              primaryText,
              secondaryText,
              accentPurple,
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Data & Permissions', secondaryText),
            const SizedBox(height: 10),
            _buildInfoCard(
              isDark,
              surfaceColor,
              primaryText,
              secondaryText,
              [
                _InfoItem(
                  icon: FontAwesomeIcons.database,
                  iconColor: const Color(0xFF4EA8DE),
                  title: 'Local Storage Only',
                  description:
                      'All your data is stored purely on your device. We do not have any cloud servers or external databases.',
                ),
                _InfoItem(
                  icon: FontAwesomeIcons.shieldHalved,
                  iconColor: const Color(0xFF2ECC71),
                  title: 'No Data Sharing',
                  description:
                      'Your financial data is never shared with anyone. Since the app works offline, no data leaves your phone.',
                ),
                _InfoItem(
                  icon: FontAwesomeIcons.wifi,
                  iconColor: const Color(0xFFFF9F1C),
                  title: 'Offline First',
                  description:
                      'SpendX is a purely offline app. It does not require or use internet connectivity to function.',
                ),
                _InfoItem(
                  icon: FontAwesomeIcons.userLock,
                  iconColor: accentPurple,
                  title: 'Permissions',
                  description:
                      'We only request permissions for:\n• Storage: To save your local backups.\n• Network: Only for checking app updates to ensure you have the latest version.',
                ),
              ],
            ),
            const SizedBox(height: 30),
            _buildWarningCard(isDark, surfaceColor, primaryText, accentRed),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightCard(
    BuildContext context,
    bool isDark,
    Color surfaceColor,
    Color primaryText,
    Color secondaryText,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              FontAwesomeIcons.lock,
              color: accentColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your Privacy is Our Priority',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: primaryText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'SpendX is designed to keep your financial data 100% private and secure on your device.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: secondaryText,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    bool isDark,
    Color surfaceColor,
    Color primaryText,
    Color secondaryText,
    List<_InfoItem> items,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: item.iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item.icon,
                        color: item.iconColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              color: primaryText,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.description,
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (index != items.length - 1)
                Divider(
                  height: 1,
                  indent: 68,
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildWarningCard(
    bool isDark,
    Color surfaceColor,
    Color primaryText,
    Color accentRed,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accentRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentRed.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            FontAwesomeIcons.triangleExclamation,
            color: accentRed,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Important Warning',
                  style: TextStyle(
                    color: accentRed,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Since there is no cloud backup, uninstalling the app will permanently delete all your data. \n\nPlease ensure you create a backup from the Settings menu before uninstalling or switching devices.',
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.grey[800],
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  _InfoItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });
}
