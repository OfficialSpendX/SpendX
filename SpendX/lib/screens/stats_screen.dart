import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:flutter/services.dart' show rootBundle;
import '../providers/transaction_provider.dart';
import '../providers/account_provider.dart';
import '../models/transaction.dart';
import '../widgets/export_options_modal.dart';
import 'budget_screen.dart';


class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  DateTime _selectedMonth = DateTime.now();
  int _touchedIndex = -1;

  // Cache State
  List<Transaction>? _lastTransactions;
  DateTime? _lastSelectedMonth;

  // Processed Data
  List<Transaction> _monthTransactions = [];
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _incomeChange = 0;
  double _expenseChange = 0;
  double _healthScore = 0;
  String _healthLabel = 'Needs Work';
  Color _healthColor = const Color(0xFFFF5252);
  
  // Chart Data
  List<double> _weeklyExpenses = [];
  double _weeklyMaxY = 0;
  Map<String, double> _categoryTotals = {};
  List<FlSpot> _incomeSpots = [];
  List<FlSpot> _expenseSpots = [];
  List<BarChartGroupData> _sixMonthBarGroups = [];
  double _sixMonthMaxY = 0;
  List<DateTime> _sixMonthLabels = [];

  void _processData(List<Transaction> transactions) {
    if (transactions == _lastTransactions && _selectedMonth == _lastSelectedMonth) return;
    
    _lastTransactions = transactions;
    _lastSelectedMonth = _selectedMonth;

    // 1. Current Month Transactions
    _monthTransactions = transactions.where((t) {
      return t.date.year == _selectedMonth.year &&
          t.date.month == _selectedMonth.month;
    }).toList();

    // 2. Totals
    _totalIncome = _monthTransactions
        .where((t) => t.type == 'Credit')
        .fold<double>(0, (sum, t) => sum + t.amount);

    _totalExpense = _monthTransactions
        .where((t) => t.type == 'Debit')
        .fold<double>(0, (sum, t) => sum + t.amount);

    // 3. Trends
    final prevMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    final prevMonthTransactions = transactions.where((t) {
      return t.date.year == prevMonth.year && t.date.month == prevMonth.month;
    }).toList();

    final prevIncome = prevMonthTransactions
        .where((t) => t.type == 'Credit')
        .fold<double>(0, (sum, t) => sum + t.amount);

    final prevExpense = prevMonthTransactions
        .where((t) => t.type == 'Debit')
        .fold<double>(0, (sum, t) => sum + t.amount);

    double calculateChange(double current, double prev) {
      if (prev == 0) return current > 0 ? 100 : 0;
      return ((current - prev) / prev) * 100;
    }

    _incomeChange = calculateChange(_totalIncome, prevIncome);
    _expenseChange = calculateChange(_totalExpense, prevExpense);

    // 4. Health Score
    _healthScore = 0;
    if (_totalIncome > 0) {
      _healthScore = ((_totalIncome - _totalExpense) / _totalIncome) * 100;
    }
    if (_totalExpense > _totalIncome) _healthScore = 0;
    
    if (_healthScore >= 50) {
      _healthLabel = 'Excellent';
      _healthColor = const Color(0xFF2ECC71);
    } else if (_healthScore >= 20) {
      _healthLabel = 'Good';
      _healthColor = Colors.blue;
    } else if (_healthScore > 0) {
      _healthLabel = 'Fair';
      _healthColor = Colors.orange;
    } else {
      _healthLabel = 'Needs Work';
      _healthColor = const Color(0xFFFF5252);
    }

    // 5. Weekly Expenses
    _weeklyExpenses = List.filled(5, 0.0);
    for (final t in _monthTransactions) {
      if (t.type == 'Debit') {
        int weekIndex = (t.date.day - 1) ~/ 7;
        if (weekIndex < 5) {
          _weeklyExpenses[weekIndex] += t.amount;
        }
      }
    }
    _weeklyMaxY = _weeklyExpenses.reduce((curr, next) => curr > next ? curr : next);
    if (_weeklyMaxY == 0) _weeklyMaxY = 1;

    // 6. Category Totals
    _categoryTotals = {};
    for (final t in _monthTransactions) {
      if (t.type == 'Debit') {
        _categoryTotals[t.category] = (_categoryTotals[t.category] ?? 0) + t.amount;
      }
    }

    // 7. Daily Trends (Line Chart)
    final Map<int, double> incomeByDay = {};
    final Map<int, double> expenseByDay = {};
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;

    for (final t in _monthTransactions) {
      final day = t.date.day;
      if (t.type == 'Credit') {
        incomeByDay[day] = (incomeByDay[day] ?? 0) + t.amount;
      } else if (t.type == 'Debit') {
        expenseByDay[day] = (expenseByDay[day] ?? 0) + t.amount;
      }
    }

    _incomeSpots = [];
    _expenseSpots = [];
    for (int i = 1; i <= daysInMonth; i++) {
        _incomeSpots.add(FlSpot(i.toDouble(), incomeByDay[i] ?? 0));
        _expenseSpots.add(FlSpot(i.toDouble(), expenseByDay[i] ?? 0));
    }

    // 8. 6-Month History (Bar Chart)
    final now = DateTime.now();
    _sixMonthLabels = [];
    _sixMonthBarGroups = [];
    
    for (int i = 5; i >= 0; i--) {
      _sixMonthLabels.add(DateTime(now.year, now.month - i, 1));
    }

    for (int i = 0; i < _sixMonthLabels.length; i++) {
      final month = _sixMonthLabels[i];
      final monthTrans = transactions.where((t) =>
          t.date.year == month.year && t.date.month == month.month);

      final credit = monthTrans
          .where((t) => t.type == 'Credit')
          .fold<double>(0, (sum, t) => sum + t.amount);
      final debit = monthTrans
          .where((t) => t.type == 'Debit')
          .fold<double>(0, (sum, t) => sum + t.amount);

      _sixMonthBarGroups.add(
        BarChartGroupData(
          x: i,
          barsSpace: 4,
          barRods: [
            BarChartRodData(
              toY: credit,
              color: const Color(0xFF2ECC71),
              width: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            BarChartRodData(
              toY: debit,
              color: const Color(0xFFFF5252),
              width: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }
    
    _sixMonthMaxY = (_sixMonthBarGroups
                .expand((g) => g.barRods)
                .map((r) => r.toY)
                .fold<double>(0, (a, b) => a > b ? a : b)) * 1.2;
    if (_sixMonthMaxY == 0) _sixMonthMaxY = 1;
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final accountProvider = Provider.of<AccountProvider>(context);

    // Process data if needed
    _processData(transactionProvider.transactions);

    final currencyFormat = NumberFormat.currency(
      locale: "en_IN",
      symbol: "₹",
      decimalDigits: 0,
    );

    // Premium Palette - Matching home_screen and settings_screen
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F8);
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final accentGreen = const Color(0xFF2ECC71);
    final accentRed = const Color(0xFFFF5252);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Statistics',
          style: TextStyle(
            color: primaryTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // Month Selector Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.chevron_left_rounded, color: primaryTextColor),
                        onPressed: () {
                          setState(() {
                            _selectedMonth = DateTime(
                              _selectedMonth.year,
                              _selectedMonth.month - 1,
                            );
                          });
                        },
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(_selectedMonth),
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.chevron_right_rounded,
                          color: _selectedMonth.isBefore(DateTime(
                                  DateTime.now().year,
                                  DateTime.now().month,
                                  1))
                              ? primaryTextColor
                              : primaryTextColor.withOpacity(0.2),
                        ),
                        onPressed: () {
                          if (_selectedMonth.isBefore(DateTime(
                              DateTime.now().year, DateTime.now().month, 1))) {
                            setState(() {
                              _selectedMonth = DateTime(
                                _selectedMonth.year,
                                _selectedMonth.month + 1,
                              );
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BudgetScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.pie_chart_outline_rounded, size: 18),
                          label: const Text('Budgets'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryTextColor,
                            side: BorderSide(
                              color: secondaryTextColor!.withOpacity(0.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _exportData(
                            context,
                            transactionProvider.transactions,
                          ),
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: const Text('Export'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryTextColor,
                            side: BorderSide(
                              color: secondaryTextColor.withOpacity(0.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Financial Health Score
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                      ? [const Color(0xFF2C3E50), const Color(0xFF4CA1AF)]
                      : [const Color(0xFF4CA1AF), const Color(0xFF2C3E50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Financial Health',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _healthLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _healthScore.toStringAsFixed(0),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8, left: 4),
                        child: Text(
                          '/ 100',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _healthScore / 100,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _healthScore >= 50 ? const Color(0xFF2ECC71) : (_healthScore >= 20 ? Colors.blue : Colors.orange),
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Net Worth Card
            Container(
              width: double.infinity,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Net Worth',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    currencyFormat.format(accountProvider.totalBalance),
                    style: TextStyle(
                      color: accentGreen,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Combined balance of all accounts',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Credit / Debit Cards with Trends
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Credit',
                    amount: _totalIncome,
                    changePercent: _incomeChange,
                    color: accentGreen,
                    icon: Icons.arrow_downward_rounded,
                    currencyFormat: currencyFormat,
                    surfaceColor: surfaceColor,
                    secondaryTextColor: secondaryTextColor,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildStatCard(
                    title: 'Debit',
                    amount: _totalExpense,
                    changePercent: _expenseChange,
                    color: accentRed,
                    icon: Icons.arrow_upward_rounded,
                    currencyFormat: currencyFormat,
                    surfaceColor: surfaceColor,
                    secondaryTextColor: secondaryTextColor,
                    isDark: isDark,
                    inverseTrend: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Debit Pie Chart
            if (_totalExpense > 0) ...[
              Text(
                'Debit Breakdown',
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(20),
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
                child: SizedBox(
                  height: 250,
                  child: RepaintBoundary(
                    child: _buildExpensePieChart(
                      primaryTextColor,
                      isDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],

            // Weekly Spending Heatmap (Bar Chart)
            if (_totalExpense > 0) ...[
              Text(
                'Weekly Spending',
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(20),
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
                child: SizedBox(
                  height: 200,
                  child: RepaintBoundary(
                    child: _buildWeeklyChart(
                      primaryTextColor,
                      secondaryTextColor,
                      isDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],

            // Top 5 Categories
            if (_totalExpense > 0) ...[
              Text(
                'Top 5 Spending Categories',
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              _buildTopCategories(
                primaryTextColor,
                currencyFormat,
                surfaceColor,
                isDark,
              ),
              const SizedBox(height: 30),
            ],

            // Bar Chart
            Text(
              'Credit vs Debit (Last 6 Months)',
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(20),
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
              child: SizedBox(
                height: 250,
                child: RepaintBoundary(
                  child: _buildBarChart(
                    primaryTextColor,
                    secondaryTextColor,
                    isDark,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Line Chart
            Text(
              'Daily Trend (This Month)',
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(20),
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
              child: SizedBox(
                height: 250,
                child: RepaintBoundary(
                  child: _buildLineChart(
                    primaryTextColor,
                    secondaryTextColor,
                    isDark,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // All Category Details
            if (_totalExpense > 0) ...[
              Text(
                'All Categories',
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              ..._buildCategoryList(
                primaryTextColor,
                currencyFormat,
                surfaceColor,
                isDark,
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required double amount,
    required double changePercent,
    required Color color,
    required IconData icon,
    required NumberFormat currencyFormat,
    required Color surfaceColor,
    required Color? secondaryTextColor,
    required bool isDark,
    bool inverseTrend = false,
  }) {
    bool isPositive = changePercent > 0;
    Color trendColor = isPositive 
        ? (inverseTrend ? const Color(0xFFFF5252) : const Color(0xFF2ECC71))
        : (inverseTrend ? const Color(0xFF2ECC71) : const Color(0xFFFF5252));
    
    IconData trendIcon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(trendIcon, color: trendColor, size: 12),
              const SizedBox(width: 2),
              Text(
                '${changePercent.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                  color: trendColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                ' vs last month',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(
    Color textColor,
    Color? secondaryTextColor,
    bool isDark,
  ) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _weeklyMaxY * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: isDark ? Colors.black87 : Colors.grey[200]!,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                rod.toY.toStringAsFixed(0),
                TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < 5) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'W${value.toInt() + 1}',
                      style: TextStyle(color: secondaryTextColor, fontSize: 10),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(5, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: _weeklyExpenses[index],
                color: const Color(0xFF6C5CE7),
                width: 12,
                borderRadius: BorderRadius.circular(4),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: _weeklyMaxY * 1.2,
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTopCategories(
    Color textColor,
    NumberFormat currencyFormat,
    Color surfaceColor,
    bool isDark,
  ) {
    final sorted = _categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final top5 = sorted.take(5).toList();

    return Column(
      children: top5.map((entry) {
        final percent = _totalExpense == 0 ? 0.0 : (entry.value / _totalExpense);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    currencyFormat.format(entry.value),
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percent,
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFFFD79A8),
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // LINE CHART
  Widget _buildLineChart(
    Color textColor,
    Color? secondaryTextColor,
    bool isDark,
  ) {
    final daysInMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value % 5 == 0 &&
                    value > 0 &&
                    value <= daysInMonth.toDouble()) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      value.toInt().toString(),
                      style:
                          TextStyle(color: secondaryTextColor, fontSize: 10),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: _incomeSpots,
            isCurved: true,
            color: const Color(0xFF2ECC71),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF2ECC71).withOpacity(0.12),
            ),
          ),
          LineChartBarData(
            spots: _expenseSpots,
            isCurved: true,
            color: const Color(0xFFFF5252),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFFFF5252).withOpacity(0.12),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 10,
            tooltipBgColor:
                isDark ? Colors.black87 : Colors.grey[200]!,
            getTooltipItems: (touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final flSpot = barSpot;
                return LineTooltipItem(
                  flSpot.y.toInt().toString(),
                  TextStyle(
                    color: barSpot.bar.color,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  // PIE CHART
  Widget _buildExpensePieChart(
    Color textColor,
    bool isDark,
  ) {
    final colors = <Color>[
      const Color(0xFF6C5CE7),
      const Color(0xFFFD79A8),
      const Color(0xFF00CEC9),
      const Color(0xFFFF7675),
      const Color(0xFF0984E3),
      const Color(0xFF2ECC71),
      const Color(0xFFFDCB6E),
    ];

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex =
                        response.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 4,
              centerSpaceRadius: 40,
              sections: List.generate(_categoryTotals.length, (i) {
                final isTouched = i == _touchedIndex;
                final fontSize = isTouched ? 16.0 : 12.0;
                final radius = isTouched ? 60.0 : 52.0;
                final entry = _categoryTotals.entries.elementAt(i);
                final total = _categoryTotals.values.fold<double>(
                    0, (a, b) => a + b);
                final percent =
                    total == 0 ? '0.0' : ((entry.value / total) * 100)
                        .toStringAsFixed(1);

                return PieChartSectionData(
                  color: colors[i % colors.length],
                  value: entry.value,
                  title: '$percent%',
                  radius: radius,
                  titleStyle: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  badgeWidget: isTouched
                      ? Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.black.withOpacity(0.85)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : null,
                  badgePositionPercentageOffset: .98,
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: List.generate(_categoryTotals.length, (i) {
            final entry = _categoryTotals.entries.elementAt(i);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors[i % colors.length],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  entry.key,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  // BAR CHART
  Widget _buildBarChart(
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _sixMonthMaxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor:
                isDark ? Colors.black87 : Colors.grey[200]!,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                rod.toY.toStringAsFixed(0),
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 &&
                    value.toInt() < _sixMonthLabels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('MMM').format(
                        _sixMonthLabels[value.toInt()],
                      ),
                      style:
                          TextStyle(color: secondaryTextColor, fontSize: 10),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.04),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: _sixMonthBarGroups,
      ),
    );
  }

  // CATEGORY LIST
  List<Widget> _buildCategoryList(
    Color textColor,
    NumberFormat currencyFormat,
    Color surfaceColor,
    bool isDark,
  ) {
    final sorted = _categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.map((entry) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: surfaceColor,
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5252),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  entry.key,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            Text(
              currencyFormat.format(entry.value),
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  // EXPORT
  void _exportData(BuildContext context, List<Transaction> allTransactions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ExportOptionModal(
        onRangeSelected: (start, end, label) {
          _generatePDF(context, allTransactions, start, end, label);
        },
      ),
    );
  }

  Future<void> _generatePDF(
    BuildContext context,
    List<Transaction> allTransactions,
    DateTime startDate,
    DateTime endDate,
    String periodLabel,
  ) async {
    try {
      final accountProvider =
          Provider.of<AccountProvider>(context, listen: false);

      // 1. Filter Transactions for the selected range
      final rangeTransactions = allTransactions.where((t) {
        return t.date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
            t.date.isBefore(endDate.add(const Duration(seconds: 1)));
      }).toList();

      // Sort by date descending
      rangeTransactions.sort((a, b) => b.date.compareTo(a.date));

      // 2. Calculate Balances (Reverse Calculation)
      final currentTotalBalance = accountProvider.totalBalance;

      // Transactions AFTER the end date (to get Closing Balance)
      final futureTransactions = allTransactions.where((t) {
        return t.date.isAfter(endDate);
      });

      final futureIncome = futureTransactions
          .where((t) => t.type == 'Credit')
          .fold<double>(0, (sum, t) => sum + t.amount);
      
      final futureExpense = futureTransactions
          .where((t) => t.type == 'Debit')
          .fold<double>(0, (sum, t) => sum + t.amount);

      final closingBalance = currentTotalBalance - futureIncome + futureExpense;

      // Transactions IN the range (to get Opening Balance from Closing)
      final rangeIncome = rangeTransactions
          .where((t) => t.type == 'Credit')
          .fold<double>(0, (sum, t) => sum + t.amount);

      final rangeExpense = rangeTransactions
          .where((t) => t.type == 'Debit')
          .fold<double>(0, (sum, t) => sum + t.amount);

      final openingBalance = closingBalance - rangeIncome + rangeExpense;
      final netChange = rangeIncome - rangeExpense;

      // 3. Category Breakdown
      final Map<String, double> categoryExpenses = {};
      for (final t in rangeTransactions) {
        if (t.type == 'Debit') {
          categoryExpenses[t.category] =
              (categoryExpenses[t.category] ?? 0) + t.amount;
        }
      }
      final sortedCategories = categoryExpenses.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // 4. Generate PDF
      final pdf = pw.Document();
      
      // Load Logo
      pw.MemoryImage? logoImage;
      try {
        final byteData = await rootBundle.load('assets/img/logo/logo2.png');
        logoImage = pw.MemoryImage(byteData.buffer.asUint8List());
      } catch (e) {
        debugPrint('Error loading logo: $e');
      }

      final font = await PdfGoogleFonts.interRegular();
      final boldFont = await PdfGoogleFonts.interBold();

      String formatCurrency(double amount) {
        return 'Rs ${amount.toStringAsFixed(0)}';
      }

      String getAccountName(String id) {
        try {
          return accountProvider.accounts.firstWhere((a) => a.id == id).name;
        } catch (_) {
          return 'Unknown';
        }
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          theme: pw.ThemeData.withFont(
            base: font,
            bold: boldFont,
          ),
          build: (context) {
            return [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (logoImage != null)
                    pw.Container(
                      height: 60,
                      width: 60,
                      child: pw.Image(logoImage),
                    ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'SpendX - Transaction Report',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Generated on ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Period: $periodLabel',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.blueGrey800,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '${DateFormat('dd MMM yyyy').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Summary Section
              pw.Text(
                'Financial Summary',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey800,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPdfSummaryItem('Opening Balance', openingBalance, PdfColors.grey800),
                    _buildPdfSummaryItem('Total Credit', rangeIncome, PdfColors.green700),
                    _buildPdfSummaryItem('Total Debit', rangeExpense, PdfColors.red700),
                    _buildPdfSummaryItem('Closing Balance', closingBalance, PdfColors.blueGrey900, isBold: true),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // Category Breakdown
              if (sortedCategories.isNotEmpty) ...[
                pw.Text(
                  'Expense Breakdown',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey800,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.ClipRRect(
                  horizontalRadius: 8,
                  verticalRadius: 8,
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                    ),
                    child: pw.Table(
                      border: pw.TableBorder.symmetric(
                        inside: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                      ),
                      children: [
                        // Header
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('%', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                            ),
                          ],
                        ),
                        // Rows
                        ...sortedCategories.map((entry) {
                          final percent = (entry.value / rangeExpense) * 100;
                          return pw.TableRow(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(entry.key, style: const pw.TextStyle(fontSize: 10)),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(formatCurrency(entry.value), style: const pw.TextStyle(fontSize: 10)),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text('${percent.toStringAsFixed(1)}%', style: const pw.TextStyle(fontSize: 10)),
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(height: 30),
              ],

              // Transaction List
              pw.Text(
                'Transaction Details',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey800,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.ClipRRect(
                horizontalRadius: 8,
                verticalRadius: 8,
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  ),
                  child: pw.Table(
                    border: pw.TableBorder.symmetric(
                      inside: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                    ),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(2), // Date
                      1: const pw.FlexColumnWidth(3), // Category
                      2: const pw.FlexColumnWidth(2), // Amount
                      3: const pw.FlexColumnWidth(2), // Account
                      4: const pw.FlexColumnWidth(3), // Note
                    },
                    children: [
                      // Header
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          _buildPdfTableHeader('Date'),
                          _buildPdfTableHeader('Category'),
                          _buildPdfTableHeader('Amount'),
                          _buildPdfTableHeader('Account'),
                          _buildPdfTableHeader('Note'),
                        ],
                      ),
                      // Rows
                      ...rangeTransactions.map((t) {
                        final accountName = getAccountName(t.accountId);
                        String displayNote = t.note.isEmpty ? '-' : t.note;
                        if (t.type == 'Transfer' && t.transferAccountId != null) {
                          displayNote = 'To: ${getAccountName(t.transferAccountId!)}';
                        }
                        
                        PdfColor amountColor = PdfColors.black;
                        String prefix = '';
                        if (t.type == 'Credit') {
                          amountColor = PdfColors.green700;
                          prefix = '+ ';
                        } else if (t.type == 'Debit') {
                          amountColor = PdfColors.red700;
                          prefix = '- ';
                        }

                        return pw.TableRow(
                          children: [
                            _buildPdfTableCell(DateFormat('dd MMM yy').format(t.date)),
                            _buildPdfTableCell(t.category),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                '$prefix${formatCurrency(t.amount)}',
                                style: pw.TextStyle(fontSize: 9, color: amountColor, fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                            _buildPdfTableCell(accountName),
                            _buildPdfTableCell(displayNote),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ];
          },
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          'SpendX_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final path = '${dir.path}/$fileName';
      final file = File(path);
      await file.writeAsBytes(await pdf.save());

      try {
        await Share.shareXFiles([XFile(path)],
            text: 'SpendX Transaction Report ($periodLabel)');
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF saved to: $path'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting PDF: $e')),
        );
      }
    }
  }

  pw.Widget _buildPdfSummaryItem(String label, double amount, PdfColor color, {bool isBold = false}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 9,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Rs ${amount.toStringAsFixed(0)}',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPdfTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.black,
        ),
      ),
    );
  }

  pw.Widget _buildPdfTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9),
      ),
    );
  }
}
