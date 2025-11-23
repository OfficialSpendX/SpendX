import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../providers/account_provider.dart';
import 'add_account_screen.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final accountProvider = Provider.of<AccountProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(locale: "en_IN", symbol: "₹");

    // Premium Palette
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F8);
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryText = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final secondaryText = isDark ? Colors.grey[400] : Colors.grey[600];
    final accentGreen = const Color(0xFF2ECC71);

    // Calculate Total Balance
    double totalBalance = 0;
    for (var acc in accountProvider.accounts) {
      totalBalance += acc.balance;
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'My Wallets',
          style: TextStyle(
            color: primaryText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddAccountScreen()),
          );
        },
        backgroundColor: isDark ? Colors.white : const Color(0xFF1A1A2E),
        label: Text(
          'Add Account',
          style: TextStyle(
            color: isDark ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        icon: Icon(
          Icons.add,
          color: isDark ? Colors.black : Colors.white,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Total Balance Header
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF2D033B), const Color(0xFF810CA8)]
                      : [const Color(0xFF463FB5), const Color(0xFF7B72E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? const Color(0xFF810CA8) : const Color(0xFF7B72E5))
                        .withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Net Liquidity',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormat.format(totalBalance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            // 2. Account List
            Expanded(
              child: accountProvider.accounts.isEmpty
                  ? _buildEmptyState(isDark, secondaryText)
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 80), // Bottom padding for FAB
                      itemCount: accountProvider.accounts.length,
                      itemBuilder: (context, index) {
                        final account = accountProvider.accounts[index];
                        return _buildAccountCard(
                          context,
                          account,
                          isDark,
                          surfaceColor,
                          primaryText,
                          secondaryText,
                          accentGreen,
                          currencyFormat,
                          accountProvider,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(
    BuildContext context,
    dynamic account,
    bool isDark,
    Color surface,
    Color primaryText,
    Color? secondaryText,
    Color accentColor,
    NumberFormat format,
    AccountProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: account.isDefault 
            ? Border.all(color: accentColor.withOpacity(0.5), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showAccountOptions(
            context: context,
            accountProvider: provider,
            account: account,
            isDark: isDark,
            primaryText: primaryText,
            secondaryText: secondaryText,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon/Logo
                Container(
                  height: 50,
                  width: 50,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: account.imagePath != null
                      ? Image.asset(
                          account.imagePath!,
                          errorBuilder: (_, __, ___) => Icon(
                            FontAwesomeIcons.buildingColumns,
                            color: primaryText,
                            size: 20,
                          ),
                        )
                      : Icon(
                          account.type == 'Cash' 
                              ? FontAwesomeIcons.wallet 
                              : FontAwesomeIcons.buildingColumns,
                              color: primaryText,
                              size: 20,
                            ),
                ),
                const SizedBox(width: 16),
                
                // Name & Type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              account.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: primaryText,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (account.isDefault) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.check_circle, size: 14, color: accentColor),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        account.type,
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Balance
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      format.format(account.balance),
                      style: TextStyle(
                        color: primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color? secondaryText) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              FontAwesomeIcons.wallet,
              size: 40,
              color: secondaryText,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No accounts added',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first bank or cash account\nto track your net worth.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: secondaryText,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showAccountOptions({
    required BuildContext context,
    required AccountProvider accountProvider,
    required dynamic account,
    required bool isDark,
    required Color primaryText,
    required Color? secondaryText,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: secondaryText?.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_circle_outline, color: Color(0xFF2ECC71)),
              ),
              title: Text(
                'Set as Default Wallet',
                style: TextStyle(color: primaryText, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Primary account for quick transactions',
                style: TextStyle(color: secondaryText, fontSize: 12),
              ),
              onTap: () {
                accountProvider.setAsDefault(account.id);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
              ),
              title: Text(
                'Edit Wallet',
                style: TextStyle(color: primaryText, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Update name, balance or icon',
                style: TextStyle(color: secondaryText, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddAccountScreen(accountToEdit: account),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete_outline, color: Colors.redAccent),
              ),
              title: Text(
                'Delete Wallet',
                style: TextStyle(color: primaryText, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Removes wallet but keeps history',
                style: TextStyle(color: secondaryText, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteDialog(
                  context: context,
                  accountProvider: accountProvider,
                  account: account,
                  isDark: isDark,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog({
    required BuildContext context,
    required AccountProvider accountProvider,
    required dynamic account,
    required bool isDark,
    required Color primaryText,
    required Color? secondaryText,
  }) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Account?',
          style: TextStyle(color: primaryText, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to remove ${account.name}? Your transaction history will be preserved.',
          style: TextStyle(color: secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Cancel',
              style: TextStyle(color: secondaryText, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () {
              accountProvider.deleteAccount(account.id);
              Navigator.pop(dialogCtx);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}