import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../models/category.dart';
import '../models/recurring_transaction.dart';
import '../providers/recurring_transaction_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  final String type; // 'Credit', 'Debit', or 'Transfer'

  const AddTransactionScreen({Key? key, required this.type}) : super(key: key);

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late String _type;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _paymentAppController = TextEditingController();
  final _transactionNumberController = TextEditingController();
  
  String _selectedCategory = 'Food';
  String? _selectedAccountId;
  String? _selectedTransferAccountId; // For Transfer
  DateTime _selectedDate = DateTime.now();
  
  // Recurring
  bool _isRecurring = false;
  Frequency _selectedFrequency = Frequency.monthly;
  DateTime? _endDate;
  bool _processPaymentToday = true; // New field for payment timing

  // Theme Colors based on Type
  Color get _activeColor {
    switch (_type) {
      case 'Credit': return const Color(0xFF2ECC71);
      case 'Debit': return const Color(0xFFFF5252);
      case 'Transfer': return const Color(0xFF4EA8DE);
      default: return const Color(0xFF2ECC71);
    }
  }

  @override
  void initState() {
    super.initState();
    _type = widget.type;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accountProvider = Provider.of<AccountProvider>(context, listen: false);
      if (accountProvider.accounts.isNotEmpty) {
        setState(() {
          _selectedAccountId = accountProvider.defaultAccount?.id ??
              accountProvider.accounts.first.id;

          if (accountProvider.accounts.length > 1) {
            _selectedTransferAccountId = accountProvider.accounts
                .firstWhere((a) => a.id != _selectedAccountId)
                .id;
          }
        });
      }
      
      // Set default category
      final catProvider = Provider.of<CategoryProvider>(context, listen: false);
      if (_type == 'Credit' && catProvider.incomeCategories.isNotEmpty) {
        setState(() => _selectedCategory = catProvider.incomeCategories.first.name);
      } else if (_type == 'Debit' && catProvider.expenseCategories.isNotEmpty) {
        setState(() => _selectedCategory = catProvider.expenseCategories.first.name);
      } else if (_type == 'Transfer') {
        setState(() => _selectedCategory = 'Transfer');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = Provider.of<AccountProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Premium Palette
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
          'New Transaction',
          style: TextStyle(
            color: primaryText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: primaryText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Type Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Container(
                height: 50,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    _buildTypeTab('Credit', isDark),
                    _buildTypeTab('Debit', isDark),
                    _buildTypeTab('Transfer', isDark),
                  ],
                ),
              ),
            ),

            // 2. Hero Amount Input
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Text(
                    'ENTER AMOUNT',
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  IntrinsicWidth(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _activeColor,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '0',
                        hintStyle: TextStyle(color: secondaryText?.withOpacity(0.3)),
                        prefixText: '₹',
                        prefixStyle: TextStyle(
                          color: _activeColor,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 3. Content Body
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Account Selector
                  if (_type == 'Transfer')
                    _buildTransferSelector(accountProvider, isDark, secondaryText!)
                  else
                    _buildSingleAccountSelector(accountProvider, isDark, secondaryText!),
                  
                  const SizedBox(height: 24),

                  // Categories
                  if (_type != 'Transfer') ...[
                    Text(
                      'CATEGORY',
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Consumer<CategoryProvider>(
                      builder: (context, catProvider, _) {
                        final categories = _type == 'Credit' 
                            ? catProvider.incomeCategories 
                            : catProvider.expenseCategories;
                        
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          alignment: WrapAlignment.start,
                          children: categories.map((c) => _buildCategoryItem(c, isDark)).toList(),
                        );
                      }
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Date & Note inputs
                  Text(
                    'DETAILS',
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildDetailRow(
                    icon: FontAwesomeIcons.calendar,
                    child: InkWell(
                      onTap: () => _pickDate(context, isDark),
                      child: Text(
                        DateFormat('dd MMMM yyyy').format(_selectedDate),
                        style: TextStyle(
                          color: primaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    isDark: isDark,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildDetailRow(
                    icon: FontAwesomeIcons.noteSticky,
                    child: TextField(
                      controller: _noteController,
                      style: TextStyle(color: primaryText, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Add a note...',
                        hintStyle: TextStyle(color: secondaryText),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    isDark: isDark,
                  ),

                  // Debit specific fields
                  if (_type == 'Debit') ...[
                    const SizedBox(height: 16),
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Text(
                          'More Options',
                          style: TextStyle(
                            color: secondaryText,
                            fontSize: 14,
                            fontWeight: FontWeight.w500
                          ),
                        ),
                        children: [
                          _buildDetailRow(
                            icon: FontAwesomeIcons.googlePay,
                            child: TextField(
                              controller: _paymentAppController,
                              style: TextStyle(color: primaryText, fontSize: 16),
                              decoration: InputDecoration(
                                hintText: 'Payment App (e.g., GPay)',
                                hintStyle: TextStyle(color: secondaryText),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: FontAwesomeIcons.hashtag,
                            child: TextField(
                              controller: _transactionNumberController,
                              style: TextStyle(color: primaryText, fontSize: 16),
                              decoration: InputDecoration(
                                hintText: 'Transaction ID',
                                hintStyle: TextStyle(color: secondaryText),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  
                  // Recurring Options
                  if (_type != 'Transfer') ...[
                    _buildDetailRow(
                      icon: FontAwesomeIcons.arrowsRotate,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Recurring Transaction',
                              style: TextStyle(
                                color: primaryText,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Switch(
                            value: _isRecurring,
                            onChanged: (val) => setState(() => _isRecurring = val),
                            activeColor: _activeColor,
                          ),
                        ],
                      ),
                      isDark: isDark,
                    ),
                    
                    if (_isRecurring) ...[
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        icon: FontAwesomeIcons.clock,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Frequency>(
                            value: _selectedFrequency,
                            isExpanded: true,
                            dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                            items: Frequency.values.map((f) {
                              return DropdownMenuItem(
                                value: f,
                                child: Text(
                                  f.name[0].toUpperCase() + f.name.substring(1),
                                  style: TextStyle(
                                    color: primaryText,
                                    fontSize: 16,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedFrequency = val);
                            },
                          ),
                        ),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      
                      // Payment Timing Option
                      _buildDetailRow(
                        icon: FontAwesomeIcons.calendarCheck,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Process Payment Today',
                                    style: TextStyle(
                                      color: primaryText,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _processPaymentToday 
                                        ? 'Amount will be deducted immediately'
                                        : 'First payment will be on selected date',
                                    style: TextStyle(
                                      color: secondaryText,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _processPaymentToday,
                              onChanged: (val) => setState(() => _processPaymentToday = val),
                              activeColor: _activeColor,
                            ),
                          ],
                        ),
                        isDark: isDark,
                      ),
                      
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        icon: FontAwesomeIcons.calendarXmark,
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                              builder: (context, child) {
                                return Theme(
                                  data: isDark ? ThemeData.dark() : ThemeData.light(),
                                  child: child!,
                                );
                              },
                            );
                            setState(() => _endDate = picked);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _endDate == null 
                                    ? 'Optional End Date' 
                                    : DateFormat('dd MMMM yyyy').format(_endDate!),
                                style: TextStyle(
                                  color: _endDate == null ? secondaryText : primaryText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (_endDate != null)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () => setState(() => _endDate = null),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                            ],
                          ),
                        ),
                        isDark: isDark,
                      ),
                    ],
                  ],

                  const SizedBox(height: 30),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _saveTransaction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _activeColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        shadowColor: _activeColor.withOpacity(0.4),
                        elevation: 8,
                      ),
                      child: const Text(
                        'Save Transaction',
                        style: TextStyle(
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
          ],
        ),
      ),
    );
  }

  // --- Component Builders ---

  Widget _buildTypeTab(String label, bool isDark) {
    final isSelected = _type == label;
    Color typeColor;
    switch (label) {
      case 'Credit': typeColor = const Color(0xFF2ECC71); break;
      case 'Debit': typeColor = const Color(0xFFFF5252); break;
      default: typeColor = const Color(0xFF4EA8DE);
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _type = label;
            // Update default category when type changes
            final catProvider = Provider.of<CategoryProvider>(context, listen: false);
            if (_type == 'Credit' && catProvider.incomeCategories.isNotEmpty) {
              _selectedCategory = catProvider.incomeCategories.first.name;
            } else if (_type == 'Debit' && catProvider.expenseCategories.isNotEmpty) {
              _selectedCategory = catProvider.expenseCategories.first.name;
            } else if (_type == 'Transfer') {
              _selectedCategory = 'Transfer';
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? typeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(21),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected 
                  ? Colors.white
                  : (isDark ? Colors.grey : Colors.black54),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(Category category, bool isDark) {
    final isSelected = _selectedCategory == category.name;
    final bgColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF4F6F8);

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category.name),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isSelected ? _activeColor : bgColor,
              shape: BoxShape.circle,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: _activeColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Center(
              child: Icon(
                IconData(category.iconCode, fontFamily: 'FontAwesomeSolid', fontPackage: 'font_awesome_flutter'),
                color: isSelected ? Colors.white : (isDark ? Colors.grey : Colors.grey[700]),
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category.name,
            style: TextStyle(
              color: isSelected ? _activeColor : (isDark ? Colors.grey : Colors.grey[600]),
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleAccountSelector(AccountProvider provider, bool isDark, Color secondaryText) {
    if (provider.accounts.isEmpty || _selectedAccountId == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.black12 : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: Text(
          'No accounts available. Please add an account first.',
          style: TextStyle(color: secondaryText, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }

    final selectedAccount = provider.accounts.firstWhere((a) => a.id == _selectedAccountId);
    final currencyFormat = NumberFormat.currency(locale: "en_IN", symbol: "₹");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'WALLET',
              style: TextStyle(
                color: secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            if (_type == 'Debit' || _type == 'Transfer')
              Text(
                'Balance: ${currencyFormat.format(selectedAccount.balance)}',
                style: TextStyle(
                  color: _activeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? Colors.black12 : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedAccountId,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: _activeColor),
              dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              items: provider.accounts.map((account) {
                return DropdownMenuItem(
                  value: account.id,
                  child: Row(
                    children: [
                      Icon(
                        account.type == 'Bank' 
                          ? FontAwesomeIcons.buildingColumns 
                          : FontAwesomeIcons.wallet,
                        size: 16,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          account.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedAccountId = val),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransferSelector(AccountProvider provider, bool isDark, Color secondaryText) {
    if (provider.accounts.length < 2) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.black12 : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: Column(
          children: [
            Icon(FontAwesomeIcons.circleExclamation, color: secondaryText, size: 24),
            const SizedBox(height: 12),
            Text(
              'At least 2 accounts are required for a transfer.',
              style: TextStyle(color: secondaryText, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final sourceAccount = provider.accounts.firstWhere(
      (a) => a.id == _selectedAccountId, 
      orElse: () => provider.accounts.first
    );
    final currencyFormat = NumberFormat.currency(locale: "en_IN", symbol: "₹");

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('FROM', style: TextStyle(color: secondaryText, fontSize: 10, fontWeight: FontWeight.bold)),
                      Text(
                        currencyFormat.format(sourceAccount.balance),
                        style: TextStyle(color: _activeColor, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildCompactDropdown(provider, true, isDark),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Icon(FontAwesomeIcons.arrowRightArrowLeft, size: 16, color: secondaryText),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TO', style: TextStyle(color: secondaryText, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildCompactDropdown(provider, false, isDark),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactDropdown(AccountProvider provider, bool isSource, bool isDark) {
    final val = isSource ? _selectedAccountId : _selectedTransferAccountId;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        color: isDark ? Colors.black12 : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: val,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          items: provider.accounts.map((account) {
            return DropdownMenuItem(
              value: account.id,
              child: Text(
                account.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            );
          }).toList(),
          onChanged: (v) => setState(() {
            if (isSource) {
              _selectedAccountId = v;
            } else {
              _selectedTransferAccountId = v;
            }
          }),
        ),
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required Widget child, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.black12 : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: isDark ? Colors.grey : Colors.grey[600]),
          const SizedBox(width: 16),
          Expanded(child: child),
        ],
      ),
    );
  }

  // --- Logic ---

  Future<void> _pickDate(BuildContext context, bool isDark) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: isDark ? ThemeData.dark() : ThemeData.light(),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveTransaction() {
    if (_amountController.text.isEmpty || _selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter amount and select account')));
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    final accountProvider = Provider.of<AccountProvider>(context, listen: false);
    final selectedAccount = accountProvider.accounts.firstWhere((a) => a.id == _selectedAccountId);

    // Validation: Check if amount exceeds available balance (For Debit and Transfer)
    if ((_type == 'Debit' || _type == 'Transfer') && amount > selectedAccount.balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient balance! Available: ₹${selectedAccount.balance}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validation: Transfer to same account
    if (_type == 'Transfer') {
      if (_selectedTransferAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a destination account')));
        return;
      }
      if (_selectedAccountId == _selectedTransferAccountId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot transfer to the same account'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final transaction = Transaction(
      id: const Uuid().v4(),
      accountId: _selectedAccountId!,
      amount: amount,
      type: _type,
      category: _selectedCategory,
      date: _selectedDate,
      note: _noteController.text,
      paymentApp: _paymentAppController.text.isNotEmpty ? _paymentAppController.text : null,
      transactionNumber: _transactionNumberController.text.isNotEmpty ? _transactionNumberController.text : null,
      transferAccountId: _type == 'Transfer' ? _selectedTransferAccountId : null,
    );

    if (_isRecurring && _type != 'Transfer') {
      final recurringTransaction = RecurringTransaction(
        id: const Uuid().v4(),
        amount: amount,
        type: _type,
        category: _selectedCategory,
        startDate: _selectedDate,
        frequency: _selectedFrequency,
        platform: _paymentAppController.text.isNotEmpty ? _paymentAppController.text : null,
        accountId: _selectedAccountId!,
        endDate: _endDate,
        note: _noteController.text,
      );

      final recurringProvider = Provider.of<RecurringTransactionProvider>(context, listen: false);
      recurringProvider.addRecurringTransaction(recurringTransaction);
      
      // Process immediate transaction if selected
      if (_processPaymentToday) {
        final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
        transactionProvider.addTransaction(transaction);
        
        // Update balance for immediate transaction
        if (_type == 'Credit') {
          accountProvider.updateBalance(_selectedAccountId!, amount);
        } else if (_type == 'Debit') {
          accountProvider.updateBalance(_selectedAccountId!, -amount);
        }
      }
      
      // Generate future transactions
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      recurringProvider.checkAndGenerateTransactions(transactionProvider, accountProvider);
      
      _showSuccessModal(context, true);
      return;
    }

    // Regular transaction
    Provider.of<TransactionProvider>(context, listen: false).addTransaction(transaction);
    
    // Update Balances
    if (_type == 'Credit') {
      accountProvider.updateBalance(_selectedAccountId!, amount);
    } else if (_type == 'Debit') {
      accountProvider.updateBalance(_selectedAccountId!, -amount);
    } else {
      accountProvider.updateBalance(_selectedAccountId!, -amount);
      accountProvider.updateBalance(_selectedTransferAccountId!, amount);
    }

    _showSuccessModal(context, false);
  }

  void _showSuccessModal(BuildContext context, bool isRecurring) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentGreen = const Color(0xFF2ECC71);
    final accentBlue = const Color(0xFF4EA8DE);
    final primaryText = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final secondaryText = isDark ? Colors.grey[400] : Colors.grey[600];
    final currencyFormat = NumberFormat.currency(locale: "en_IN", symbol: "₹", decimalDigits: 0);
    final amount = double.tryParse(_amountController.text) ?? 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (dialogContext) {
        // Auto-dismiss after 2 seconds
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
            Navigator.of(context).pop(); // Also pop the add transaction screen
          }
        });

        return Dialog(
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
                  color: _activeColor.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with gradient background
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _activeColor.withOpacity(0.8),
                          _activeColor.withOpacity(0.6),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _activeColor.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      isRecurring ? FontAwesomeIcons.arrowsRotate : FontAwesomeIcons.circleCheck,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  // Title
                  Text(
                    isRecurring ? 'Recurring Transaction Set!' : 'Transaction Recorded!',
                    style: TextStyle(
                      color: primaryText,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  
                  // Subtitle
                  Text(
                    isRecurring
                        ? '${currencyFormat.format(amount)} ${_type.toLowerCase()} set to recur ${_selectedFrequency.name}'
                        : '${currencyFormat.format(amount)} ${_type.toLowerCase()} recorded in $_selectedCategory',
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  if (isRecurring && _processPaymentToday) ...[
                    const SizedBox(height: 8),
                    Text(
                      'First payment processed today',
                      style: TextStyle(
                        color: _activeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _paymentAppController.dispose();
    _transactionNumberController.dispose();
    super.dispose();
  }
}