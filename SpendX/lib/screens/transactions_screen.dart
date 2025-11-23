import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/transaction_provider.dart';
import '../providers/account_provider.dart';
import 'search_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _filterType = 'All'; // All, Credit, Debit

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: "en_IN", symbol: "₹");

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Premium Palette
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F8);
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryText = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final secondaryText = isDark ? Colors.grey[400] : Colors.grey[600];
    final accentGreen = const Color(0xFF2ECC71);
    final accentRed = const Color(0xFFFF5252);

    var filteredTransactions = transactionProvider.transactions;
    if (_filterType != 'All') {
      filteredTransactions =
          filteredTransactions.where((t) => t.type == _filterType).toList();
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Transactions',
          style: TextStyle(
            color: primaryText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: primaryText),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Premium Filter Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            height: 45,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[200],
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                _buildFilterTab('All', isDark),
                _buildFilterTab('Credit', isDark),
                _buildFilterTab('Debit', isDark),
              ],
            ),
          ),

          // 2. Transaction List
          Expanded(
            child: filteredTransactions.isEmpty
                ? _buildEmptyState(secondaryText)
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: filteredTransactions.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final transaction = filteredTransactions[index];
                      final isIncome = transaction.type == 'Credit';
                      final amountColor = isIncome ? accentGreen : accentRed;

                      return _buildTransactionTile(
                        context,
                        transaction,
                        currencyFormat,
                        isIncome,
                        amountColor,
                        isDark,
                        surfaceColor,
                        primaryText,
                        secondaryText,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, bool isDark) {
    final isSelected = _filterType == label;
    final activeColor = isDark ? const Color(0xFF5E60CE) : Colors.white;
    final activeText = isDark ? Colors.white : Colors.black;
    final inactiveText = isDark ? Colors.grey[500] : Colors.grey[600];

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filterType = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected && !isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? activeText : inactiveText,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTile(
    BuildContext context,
    dynamic transaction,
    NumberFormat format,
    bool isIncome,
    Color amountColor,
    bool isDark,
    Color surfaceColor,
    Color primaryText,
    Color? secondaryText,
  ) {
    return GestureDetector(
      onTap: () => _showTransactionDetailsDialog(context, transaction, format, isDark),
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
        child: Row(
          children: [
            // Category Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : const Color(0xFFF4F6F8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(
                  _getCategoryIcon(transaction.category),
                  color: isDark ? Colors.white : Colors.black,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Details
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
                  Row(
                    children: [
                      Text(
                        DateFormat('MMM d, hh:mm a').format(transaction.date),
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (transaction.note != null && transaction.note.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.circle, size: 4, color: secondaryText),
                        ),
                        Expanded(
                          child: Text(
                            transaction.note,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${format.format(transaction.amount)}',
                  style: TextStyle(
                    color: amountColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isIncome && transaction.type != 'Transfer')
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      transaction.type,
                      style: TextStyle(
                        color: secondaryText?.withOpacity(0.7),
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
                      _getCategoryIcon(transaction.category),
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
                          _getCategoryIcon(transaction.category),
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

  Widget _buildEmptyState(Color? textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: textColor?.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              FontAwesomeIcons.receipt,
              size: 40,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food': return FontAwesomeIcons.utensils;
      case 'Transport': return FontAwesomeIcons.bus;
      case 'Shopping': return FontAwesomeIcons.bagShopping;
      case 'Bills': return FontAwesomeIcons.fileInvoiceDollar;
      case 'Entertainment': return FontAwesomeIcons.film;
      case 'Health': return FontAwesomeIcons.heartPulse;
      case 'Salary': return FontAwesomeIcons.moneyBillWave;
      case 'Transfer': return FontAwesomeIcons.rightLeft;
      default: return FontAwesomeIcons.wallet;
    }
  }
}