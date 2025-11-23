import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../models/transaction.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: primaryText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Calendar View',
          style: TextStyle(
            color: primaryText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.today, color: primaryText),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildMonthSummary(provider.transactions, isDark, surfaceColor, primaryText, secondaryText),
              ),
              SliverToBoxAdapter(
                child: _buildCalendar(provider.transactions, isDark, surfaceColor, primaryText, secondaryText),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: _buildLegend(isDark, primaryText),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 20),
                sliver: SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildTransactionList(provider.transactions, isDark, surfaceColor, primaryText, secondaryText),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonthSummary(List<Transaction> allTransactions, bool isDark, Color surface, Color primary, Color? secondary) {
    final monthStart = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final monthEnd = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    
    final monthTransactions = allTransactions.where((t) =>
      t.date.isAfter(monthStart.subtract(const Duration(days: 1))) &&
      t.date.isBefore(monthEnd.add(const Duration(days: 1)))
    ).toList();

    final totalIncome = monthTransactions
        .where((t) => t.type == 'Credit')
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final totalExpense = monthTransactions
        .where((t) => t.type == 'Debit')
        .fold(0.0, (sum, t) => sum + t.amount);

    final currencyFormat = NumberFormat.currency(locale: "en_IN", symbol: "₹", decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            DateFormat('MMMM yyyy').format(_focusedDay),
            style: TextStyle(
              color: primary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Icon(FontAwesomeIcons.arrowTrendUp, color: const Color(0xFF2ECC71), size: 16),
                  const SizedBox(height: 8),
                  Text('Credit', style: TextStyle(color: secondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(totalIncome),
                    style: const TextStyle(
                      color: Color(0xFF2ECC71),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                height: 40,
                width: 1,
                color: isDark ? Colors.grey[800] : Colors.grey[200],
              ),
              Column(
                children: [
                  Icon(FontAwesomeIcons.arrowTrendDown, color: const Color(0xFFFF5252), size: 16),
                  const SizedBox(height: 8),
                  Text('Debit', style: TextStyle(color: secondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(totalExpense),
                    style: const TextStyle(
                      color: Color(0xFFFF5252),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                height: 40,
                width: 1,
                color: isDark ? Colors.grey[800] : Colors.grey[200],
              ),
              Column(
                children: [
                  Icon(FontAwesomeIcons.chartLine, color: const Color(0xFF5E60CE), size: 16),
                  const SizedBox(height: 8),
                  Text('Net', style: TextStyle(color: secondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(totalIncome - totalExpense),
                    style: TextStyle(
                      color: totalIncome - totalExpense >= 0 ? const Color(0xFF2ECC71) : const Color(0xFFFF5252),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(List<Transaction> allTransactions, bool isDark, Color surface, Color primary, Color? secondary) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: const Color(0xFF5E60CE).withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: Color(0xFF5E60CE),
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: Color(0xFF2ECC71),
            shape: BoxShape.circle,
          ),
          outsideDaysVisible: false,
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonDecoration: BoxDecoration(
            color: const Color(0xFF5E60CE).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          formatButtonTextStyle: const TextStyle(color: Color(0xFF5E60CE)),
          titleTextStyle: TextStyle(color: primary, fontSize: 16, fontWeight: FontWeight.bold),
          leftChevronIcon: Icon(Icons.chevron_left, color: primary),
          rightChevronIcon: Icon(Icons.chevron_right, color: primary),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: secondary),
          weekendStyle: TextStyle(color: secondary),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            final dayTransactions = _getTransactionsForDay(date, allTransactions);
            if (dayTransactions.isEmpty) return const SizedBox();

            final hasIncome = dayTransactions.any((t) => t.type == 'Credit');
            final hasExpense = dayTransactions.any((t) => t.type == 'Debit');

            return Positioned(
              bottom: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasIncome)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2ECC71),
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (hasExpense)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5252),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLegend(bool isDark, Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem('Credit', const Color(0xFF2ECC71)),
          const SizedBox(width: 20),
          _buildLegendItem('Debit', const Color(0xFFFF5252)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildTransactionList(List<Transaction> allTransactions, bool isDark, Color surface, Color primary, Color? secondary) {
    if (_selectedDay == null) {
      return Center(
        child: Text('Select a date to view transactions', style: TextStyle(color: secondary)),
      );
    }

    final dayTransactions = _getTransactionsForDay(_selectedDay!, allTransactions);

    if (dayTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FontAwesomeIcons.calendar, size: 48, color: secondary),
            const SizedBox(height: 12),
            Text(
              'No transactions on this day',
              style: TextStyle(color: secondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final currencyFormat = NumberFormat.currency(locale: "en_IN", symbol: "₹", decimalDigits: 0);
    final categoryProvider = Provider.of<CategoryProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            DateFormat('EEEE, MMM dd').format(_selectedDay!),
            style: TextStyle(
              color: primary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: dayTransactions.length,
            itemBuilder: (context, index) {
              final t = dayTransactions[index];
              final isIncome = t.type == 'Credit';
              final color = isIncome ? const Color(0xFF2ECC71) : const Color(0xFFFF5252);

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
                        _getCategoryIcon(t.category, categoryProvider),
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
            },
          ),
        ),
      ],
    );
  }

  List<Transaction> _getTransactionsForDay(DateTime day, List<Transaction> all) {
    return all.where((t) {
      return t.date.year == day.year &&
             t.date.month == day.month &&
             t.date.day == day.day;
    }).toList();
  }

  IconData _getCategoryIcon(String categoryName, CategoryProvider provider) {
    try {
      final cat = provider.categories.firstWhere((c) => c.name == categoryName);
      return IconData(cat.iconCode, fontFamily: 'FontAwesomeSolid', fontPackage: 'font_awesome_flutter');
    } catch (e) {
      return FontAwesomeIcons.receipt;
    }
  }
}
