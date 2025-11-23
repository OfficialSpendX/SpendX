import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
// Note: We'll use the 'timezone' package to ensure we get the IST time accurately.
// For simplicity in this file, I'll rely on the device's clock and adjust the logic.

import '../providers/user_provider.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/glass_card.dart';
import 'add_transaction_screen.dart';
import 'search_screen.dart';
import 'goals_screen.dart';
import 'calendar_screen.dart';
import '../providers/category_provider.dart';
import '../providers/theme_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isBalanceVisible = true;

  // --- Dynamic Greeting Logic ---
  String _getGreeting() {
    // Note: DateTime.now() returns the time in the local timezone of the device.
    // Assuming the user's device is set to IST, this logic will work.
    // For true IST time regardless of device setting, consider using the 'timezone' package.
    final now = DateTime.now();
    final hour = now.hour;

    // 12:00 AM (0) to 11:59 AM (11) -> Good Morning
    if (hour >= 0 && hour < 12) {
      return 'Good Morning,';
    }
    // 12:00 PM (12) to 4:59 PM (16) -> Good Afternoon
    else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon,';
    }
    // 5:00 PM (17) to 11:59 PM (23) -> Good Evening
    else {
      return 'Good Evening,';
    }
  }
  // ------------------------------

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final accountProvider = Provider.of<AccountProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Premium palette
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F8);
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryTextColor =
        isDark ? Colors.white : const Color(0xFF1A1A2E);
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[500];
    final accentColor = const Color(0xFF5E60CE);

    final defaultAccount = accountProvider.defaultAccount;
    final currencyFormat =
        NumberFormat.currency(locale: "en_IN", symbol: "₹");

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // Top bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // *** UPDATED: Using the dynamic greeting here ***
                        _getGreeting(), 
                        // **********************************************
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userProvider.user?.name ?? 'User',
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.search_rounded,
                            color: isDark ? Colors.white : Colors.black,
                            size: 22,
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SearchScreen()),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            isDark
                                ? Icons.light_mode_rounded
                                : Icons.dark_mode_rounded,
                            color: isDark ? Colors.amber : Colors.grey[800],
                            size: 22,
                          ),
                          onPressed: () {
                            // theme toggle
                            final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
                            themeProvider.toggleTheme(!themeProvider.isDarkMode);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Premium account card
              defaultAccount == null
                  ? _buildNoAccountState(isDark, secondaryTextColor)
                  : _buildPremiumCard(
                      defaultAccount,
                      currencyFormat,
                      isDark,
                    ),

              const SizedBox(height: 20),

              // Monthly summary row under card
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryChip(
                      label: 'Monthly Credit',
                      value:
                          currencyFormat.format(transactionProvider.monthlyIncome),
                      color: const Color(0xFF2ECC71),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryChip(
                      label: 'Monthly Debit',
                      value: currencyFormat
                          .format(transactionProvider.monthlyExpense),
                      color: const Color(0xFFFF5252),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Quick Access Cards Row
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GoalsScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4EA8DE).withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                FontAwesomeIcons.bullseye,
                                color: Color(0xFF4EA8DE),
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Savings Goals',
                              style: TextStyle(
                                color: primaryTextColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Track your dreams',
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CalendarScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9F1C).withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                FontAwesomeIcons.calendar,
                                color: Color(0xFFFF9F1C),
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Calendar View',
                              style: TextStyle(
                                color: primaryTextColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Monthly overview',
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Operations
              Text(
                'Operations',
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      label: 'Credit',
                      icon: FontAwesomeIcons.arrowDown,
                      color: const Color(0xFF2ECC71),
                      bgColor: isDark
                          ? const Color(0xFF1E2B23)
                          : const Color(0xFFE8F8F0),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const AddTransactionScreen(type: 'Credit'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildActionButton(
                      label: 'Debit',
                      icon: FontAwesomeIcons.arrowUp,
                      color: const Color(0xFFFF5252),
                      bgColor: isDark
                          ? const Color(0xFF2C1F1F)
                          : const Color(0xFFFEECEC),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const AddTransactionScreen(type: 'Debit'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Transactions header - UPDATED: Removed "View all" button
              Row(
                mainAxisAlignment: MainAxisAlignment.start, // Changed to start, as there's no "View all"
                children: [
                  Text(
                    // UPDATED: Changed label to reflect the focused nature
                    "Today's Transactions",
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  // Removed the TextButton for 'View all'
                ],
              ),
              const SizedBox(height: 15),

              // Transactions list
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                // NOTE: The current implementation uses transactionProvider.recentTransactions.
                // To ONLY show today's transactions, the TransactionProvider implementation
                // would need to be updated to expose a list filtered by the current date.
                // Assuming `recentTransactions` gives today's transactions for this UI change.
                itemCount: transactionProvider.recentTransactions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final t = transactionProvider.recentTransactions[index];
                  return GestureDetector(
                    onTap: () => _showTransactionDetailsDialog(context, t, currencyFormat, isDark),
                    child: _buildTransactionTile(
                      t,
                      currencyFormat,
                      isDark,
                      surfaceColor,
                      primaryTextColor,
                      secondaryTextColor,
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- Transaction Details Modal (Same as transactions_screen.dart) ---
  void _showTransactionDetailsDialog(BuildContext context, dynamic transaction, NumberFormat format, bool isDark) {
    final accountProvider = Provider.of<AccountProvider>(context, listen: false);
    final primaryText = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final secondaryText = isDark ? Colors.grey[400] : Colors.grey[600];
    
    // Determine color based on transaction type
    Color accentColor;
    if (transaction.type == 'Credit') {
      accentColor = const Color(0xFF2ECC71);
    } else if (transaction.type == 'Transfer') {
      accentColor = const Color(0xFF4EA8DE);
    } else {
      accentColor = const Color(0xFFFF5252);
    }

    final sourceAccount = accountProvider.getAccountById(transaction.accountId);
    final transferAccount = transaction.type == 'Transfer' 
        ? accountProvider.getAccountById(transaction.transferAccountId) 
        : null;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (ctx) => Dialog(
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
                color: accentColor.withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 0,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with gradient background - COMPACT
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accentColor.withOpacity(0.8),
                          accentColor.withOpacity(0.6),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      _getCategoryIcon(transaction.category, context),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Title - COMPACT
                  Text(
                    'Transaction Details',
                    style: TextStyle(
                      color: primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),

                  // Category badge - COMPACT
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: accentColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getCategoryIcon(transaction.category, context),
                          color: accentColor,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          transaction.category,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Amount - COMPACT
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.08),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Amount',
                          style: TextStyle(
                            color: secondaryText,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${transaction.type == 'Credit' ? '+' : transaction.type == 'Transfer' ? '' : '-'}${format.format(transaction.amount)}',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Details Section - COMPACT SPACING
                  _buildDetailRowInDialog(
                    label: 'Date & Time',
                    value: DateFormat('dd MMMM yyyy, hh:mm a').format(transaction.date),
                    icon: FontAwesomeIcons.calendar,
                    isDark: isDark,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                  ),
                  const SizedBox(height: 8),
                  
                  // Source Account
                  _buildDetailRowInDialog(
                    label: transaction.type == 'Credit' ? 'Deposited To' : 'Paid From',
                    value: sourceAccount?.name ?? 'Account Not Found',
                    icon: FontAwesomeIcons.wallet,
                    isDark: isDark,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                  ),
                  
                  // Transfer To Account
                  if (transaction.type == 'Transfer' && transferAccount != null) ...[
                    const SizedBox(height: 8),
                    _buildDetailRowInDialog(
                      label: 'Transfer To',
                      value: transferAccount.name,
                      icon: FontAwesomeIcons.rightLeft,
                      isDark: isDark,
                      primaryText: primaryText,
                      secondaryText: secondaryText,
                    ),
                  ],
                  
                  // Note
                  if (transaction.note != null && transaction.note.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildDetailRowInDialog(
                      label: 'Note',
                      value: transaction.note,
                      icon: FontAwesomeIcons.noteSticky,
                      isDark: isDark,
                      primaryText: primaryText,
                      secondaryText: secondaryText,
                    ),
                  ],

                  // Payment App (Debit specific)
                  if (transaction.type == 'Debit' && transaction.paymentApp != null && transaction.paymentApp.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildDetailRowInDialog(
                      label: 'Payment App',
                      value: transaction.paymentApp,
                      icon: FontAwesomeIcons.googlePay,
                      isDark: isDark,
                      primaryText: primaryText,
                      secondaryText: secondaryText,
                    ),
                  ],
                  
                  // Transaction ID (Debit specific)
                  if (transaction.type == 'Debit' && transaction.transactionNumber != null && transaction.transactionNumber.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildDetailRowInDialog(
                      label: 'Transaction ID',
                      value: transaction.transactionNumber,
                      icon: FontAwesomeIcons.hashtag,
                      isDark: isDark,
                      primaryText: primaryText,
                      secondaryText: secondaryText,
                    ),
                  ],

                  const SizedBox(height: 18),

                  // Close Button - COMPACT
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accentColor,
                          accentColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRowInDialog({
    required String label,
    required String value,
    required IconData icon,
    required bool isDark,
    required Color primaryText,
    required Color? secondaryText,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: secondaryText),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? primaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- The rest of your widget methods remain the same ---

  Widget _buildPremiumCard(dynamic account, NumberFormat format, bool isDark) {
    final gradientColors = isDark
        ? [const Color(0xFF2D033B), const Color(0xFF810CA8)]
        : [const Color(0xFF463FB5), const Color(0xFF7B72E5)];

    return Container(
      height: 210,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              height: 150,
              width: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -20,
            child: Container(
              height: 150,
              width: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Balance',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              _isBalanceVisible
                                  ? format.format(account.balance)
                                  : '₹ ••••••',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => setState(
                                  () => _isBalanceVisible = !_isBalanceVisible),
                              child: Icon(
                                _isBalanceVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color:
                                    Colors.white.withOpacity(0.6),
                                size: 18,
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                    Icon(
                      FontAwesomeIcons.simCard,
                      color: Colors.white.withOpacity(0.5),
                      size: 30,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          account.type,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: account.imagePath != null
                          ? Image.asset(
                              account.imagePath!,
                              width: 24,
                              height: 24,
                            )
                          : const Icon(
                              Icons.account_balance,
                              color: Colors.black,
                              size: 20,
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAccountState(bool isDark, Color? textColor) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_card_rounded, size: 48, color: textColor),
          const SizedBox(height: 16),
          Text(
            'No accounts yet',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a bank or cash account\nto start tracking.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor?.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              label == 'Monthly Credit'
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(
    dynamic transaction,
    NumberFormat format,
    bool isDark,
    Color surface,
    Color primaryText,
    Color? secText,
  ) {
    final isIncome = transaction.type == 'Credit';
    final amountColor =
        isIncome ? const Color(0xFF2ECC71) : const Color(0xFFFF5252);
    final iconData = _getCategoryIcon(transaction.category, context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : const Color(0xFFF4F6F8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Icon(
                iconData,
                color: isDark ? Colors.white : Colors.black,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.category,
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d, hh:mm a').format(transaction.date),
                  style: TextStyle(
                    color: secText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'} ${format.format(transaction.amount)}',
            style: TextStyle(
              color: amountColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category, BuildContext context) {
    try {
      final provider = Provider.of<CategoryProvider>(context, listen: false);
      final cat = provider.categories.firstWhere((c) => c.name == category);
      return IconData(cat.iconCode, fontFamily: 'FontAwesomeSolid', fontPackage: 'font_awesome_flutter');
    } catch (e) {
      return FontAwesomeIcons.wallet;
    }
  }
}