import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/transaction_provider.dart';
import '../providers/account_provider.dart';
import '../models/transaction.dart';
import '../providers/category_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String _filterType = 'All'; // All, Credit, Debit
  DateTime? _startDate;
  DateTime? _endDate;
  List<String> _selectedCategories = [];
  String? _selectedAccount;
  double _minAmount = 0;
  double _maxAmount = 1000000;
  String _sortBy = 'date_desc'; // date_desc, date_asc, amount_desc, amount_asc
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F8);
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryText = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final secondaryText = isDark ? Colors.grey[400] : Colors.grey[600];
    final categoryProvider = Provider.of<CategoryProvider>(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(color: primaryText),
          decoration: InputDecoration(
            hintText: 'Search transactions...',
            hintStyle: TextStyle(color: secondaryText),
            border: InputBorder.none,
          ),
          onChanged: (val) => setState(() {}),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _hasActiveFilters(),
              label: const Text('!'),
              child: Icon(Icons.filter_list_rounded, color: primaryText),
            ),
            onPressed: _showFilterDialog,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.sort_rounded, color: primaryText),
            onSelected: (value) => setState(() => _sortBy = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'date_desc', child: Text('Newest First')),
              const PopupMenuItem(value: 'date_asc', child: Text('Oldest First')),
              const PopupMenuItem(value: 'amount_desc', child: Text('Highest Amount')),
              const PopupMenuItem(value: 'amount_asc', child: Text('Lowest Amount')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_hasActiveFilters()) _buildActiveFiltersChips(isDark, primaryText, secondaryText),
          _buildQuickFilters(isDark, primaryText, secondaryText),
          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (context, provider, _) {
                var transactions = _filterTransactions(provider.transactions);
                transactions = _sortTransactions(transactions);

                if (transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(FontAwesomeIcons.magnifyingGlass, size: 48, color: secondaryText),
                        const SizedBox(height: 16),
                        Text(
                          'No results found',
                          style: TextStyle(color: secondaryText, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final t = transactions[index];
                    return _buildTransactionItem(t, isDark, surfaceColor, primaryText, secondaryText, categoryProvider);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _filterType != 'All' ||
           _startDate != null ||
           _endDate != null ||
           _selectedCategories.isNotEmpty ||
           _selectedAccount != null ||
           _minAmount > 0 ||
           _maxAmount < 1000000;
  }

  Widget _buildActiveFiltersChips(bool isDark, Color primaryText, Color? secondaryText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (_filterType != 'All')
            _buildFilterChip('Type: $_filterType', () => setState(() => _filterType = 'All'), isDark),
          if (_selectedCategories.isNotEmpty)
            _buildFilterChip('${_selectedCategories.length} Categories', () => setState(() => _selectedCategories.clear()), isDark),
          if (_selectedAccount != null)
            _buildFilterChip('Account', () => setState(() => _selectedAccount = null), isDark),
          if (_startDate != null || _endDate != null)
            _buildFilterChip('Date Range', () => setState(() {
              _startDate = null;
              _endDate = null;
            }), isDark),
          if (_minAmount > 0 || _maxAmount < 1000000)
            _buildFilterChip('Amount Range', () => setState(() {
              _minAmount = 0;
              _maxAmount = 1000000;
            }), isDark),
          TextButton.icon(
            icon: const Icon(Icons.clear_all, size: 16),
            label: const Text('Clear All'),
            onPressed: () => setState(() {
              _filterType = 'All';
              _selectedCategories.clear();
              _selectedAccount = null;
              _startDate = null;
              _endDate = null;
              _minAmount = 0;
              _maxAmount = 1000000;
            }),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDelete, bool isDark) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onDelete,
      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
    );
  }

  Widget _buildQuickFilters(bool isDark, Color primaryText, Color? secondaryText) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildQuickFilterChip('Today', () {
            final now = DateTime.now();
            setState(() {
              _startDate = DateTime(now.year, now.month, now.day);
              _endDate = now;
            });
          }, isDark, primaryText),
          const SizedBox(width: 8),
          _buildQuickFilterChip('This Week', () {
            final now = DateTime.now();
            final weekStart = now.subtract(Duration(days: now.weekday - 1));
            setState(() {
              _startDate = weekStart;
              _endDate = now;
            });
          }, isDark, primaryText),
          const SizedBox(width: 8),
          _buildQuickFilterChip('This Month', () {
            final now = DateTime.now();
            setState(() {
              _startDate = DateTime(now.year, now.month, 1);
              _endDate = now;
            });
          }, isDark, primaryText),
          const SizedBox(width: 8),
          _buildQuickFilterChip('Last 30 Days', () {
            final now = DateTime.now();
            setState(() {
              _startDate = now.subtract(const Duration(days: 30));
              _endDate = now;
            });
          }, isDark, primaryText),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip(String label, VoidCallback onTap, bool isDark, Color primaryText) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
      labelStyle: TextStyle(color: primaryText, fontSize: 12),
    );
  }

  List<Transaction> _filterTransactions(List<Transaction> all) {
    return all.where((t) {
      // Search Text
      final query = _searchController.text.toLowerCase();
      final matchesQuery = t.note.toLowerCase().contains(query) || 
                           t.category.toLowerCase().contains(query) ||
                           t.amount.toString().contains(query);
      
      if (!matchesQuery) return false;

      // Type Filter
      if (_filterType != 'All' && t.type != _filterType) return false;

      // Category Filter
      if (_selectedCategories.isNotEmpty && !_selectedCategories.contains(t.category)) return false;

      // Account Filter
      if (_selectedAccount != null && t.accountId != _selectedAccount) return false;

      // Date Filter
      if (_startDate != null && t.date.isBefore(_startDate!)) return false;
      if (_endDate != null && t.date.isAfter(_endDate!.add(const Duration(days: 1)))) return false;

      // Amount Filter
      if (t.amount < _minAmount || t.amount > _maxAmount) return false;

      return true;
    }).toList();
  }

  List<Transaction> _sortTransactions(List<Transaction> transactions) {
    final sorted = List<Transaction>.from(transactions);
    switch (_sortBy) {
      case 'date_asc':
        sorted.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'date_desc':
        sorted.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'amount_asc':
        sorted.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case 'amount_desc':
        sorted.sort((a, b) => b.amount.compareTo(a.amount));
        break;
    }
    return sorted;
  }

  Widget _buildTransactionItem(Transaction t, bool isDark, Color surface, Color primary, Color? secondary, CategoryProvider catProvider) {
    final isIncome = t.type == 'Credit';
    final color = isIncome ? const Color(0xFF2ECC71) : const Color(0xFFFF5252);
    final currencyFormat = NumberFormat.currency(locale: "en_IN", symbol: "₹", decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getCategoryIcon(t.category, catProvider),
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.category,
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                if (t.note.isNotEmpty)
                  Text(
                    t.note,
                    style: TextStyle(color: secondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  DateFormat('MMM dd, yyyy • hh:mm a').format(t.date),
                  style: TextStyle(color: secondary, fontSize: 10),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'} ${currencyFormat.format(t.amount)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName, CategoryProvider provider) {
    try {
      final cat = provider.categories.firstWhere((c) => c.name == categoryName);
      return IconData(cat.iconCode, fontFamily: 'FontAwesomeSolid', fontPackage: 'font_awesome_flutter');
    } catch (e) {
      return FontAwesomeIcons.receipt;
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final primaryText = isDark ? Colors.white : const Color(0xFF1A1A2E);
          final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
          final accountProvider = Provider.of<AccountProvider>(context, listen: false);

          return DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: ListView(
                  controller: scrollController,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Advanced Filters', style: TextStyle(color: primaryText, fontSize: 22, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Type Filter
                    Text('Transaction Type', style: TextStyle(color: primaryText, fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children: ['All', 'Credit', 'Debit'].map((type) {
                        final isSelected = _filterType == type;
                        return ChoiceChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (val) {
                            setModalState(() => _filterType = type);
                            setState(() {});
                          },
                          selectedColor: const Color(0xFF5E60CE),
                          labelStyle: TextStyle(color: isSelected ? Colors.white : primaryText),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Category Filter
                    Text('Categories', style: TextStyle(color: primaryText, fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categoryProvider.categories.map((cat) {
                        final isSelected = _selectedCategories.contains(cat.name);
                        return FilterChip(
                          label: Text(cat.name),
                          selected: isSelected,
                          onSelected: (val) {
                            setModalState(() {
                              if (val) {
                                _selectedCategories.add(cat.name);
                              } else {
                                _selectedCategories.remove(cat.name);
                              }
                            });
                            setState(() {});
                          },
                          selectedColor: const Color(0xFF5E60CE),
                          labelStyle: TextStyle(color: isSelected ? Colors.white : primaryText, fontSize: 12),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Account Filter
                    if (accountProvider.accounts.isNotEmpty) ...[
                      Text('Account', style: TextStyle(color: primaryText, fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('All Accounts'),
                            selected: _selectedAccount == null,
                            onSelected: (val) {
                              setModalState(() => _selectedAccount = null);
                              setState(() {});
                            },
                            selectedColor: const Color(0xFF5E60CE),
                            labelStyle: TextStyle(color: _selectedAccount == null ? Colors.white : primaryText, fontSize: 12),
                          ),
                          ...accountProvider.accounts.map((acc) {
                            final isSelected = _selectedAccount == acc.id;
                            return ChoiceChip(
                              label: Text(acc.name),
                              selected: isSelected,
                              onSelected: (val) {
                                setModalState(() => _selectedAccount = val ? acc.id : null);
                                setState(() {});
                              },
                              selectedColor: const Color(0xFF5E60CE),
                              labelStyle: TextStyle(color: isSelected ? Colors.white : primaryText, fontSize: 12),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Date Range
                    Text('Date Range', style: TextStyle(color: primaryText, fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 16),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _startDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setModalState(() => _startDate = picked);
                                setState(() {});
                              }
                            },
                            label: Text(_startDate == null ? 'Start Date' : DateFormat('MMM dd, yyyy').format(_startDate!)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 16),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _endDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setModalState(() => _endDate = picked);
                                setState(() {});
                              }
                            },
                            label: Text(_endDate == null ? 'End Date' : DateFormat('MMM dd, yyyy').format(_endDate!)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Amount Range
                    Text('Amount Range', style: TextStyle(color: primaryText, fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 10),
                    RangeSlider(
                      values: RangeValues(_minAmount, _maxAmount),
                      min: 0,
                      max: 1000000,
                      divisions: 100,
                      labels: RangeLabels(
                        '₹${_minAmount.toInt()}',
                        '₹${_maxAmount.toInt()}',
                      ),
                      onChanged: (values) {
                        setModalState(() {
                          _minAmount = values.start;
                          _maxAmount = values.end;
                        });
                        setState(() {});
                      },
                      activeColor: const Color(0xFF5E60CE),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('₹${_minAmount.toInt()}', style: TextStyle(color: primaryText)),
                        Text('₹${_maxAmount.toInt()}', style: TextStyle(color: primaryText)),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Apply Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5E60CE),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Apply Filters', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
