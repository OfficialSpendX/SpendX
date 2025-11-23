import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExportOptionModal extends StatelessWidget {
  final Function(DateTime start, DateTime end, String label) onRangeSelected;

  const ExportOptionModal({
    Key? key,
    required this.onRangeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: backgroundColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: secondaryTextColor!.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Select Period',
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a date range for your report',
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            _buildOption(context, 'Current Week', () {
              final now = DateTime.now();
              // Find the previous Monday (or today if it's Monday)
              final start = now.subtract(Duration(days: now.weekday - 1));
              final end = now; // Up to now
              onRangeSelected(
                  DateTime(start.year, start.month, start.day),
                  DateTime(end.year, end.month, end.day, 23, 59, 59),
                  'Current Week');
            }, textColor, isDark),
            _buildOption(context, 'Current Month', () {
              final now = DateTime.now();
              final start = DateTime(now.year, now.month, 1);
              final end = now;
              onRangeSelected(start, end, 'Current Month');
            }, textColor, isDark),
            _buildOption(context, 'Last 3 Months', () {
              final now = DateTime.now();
              final start = DateTime(now.year, now.month - 2, 1);
              final end = now;
              onRangeSelected(start, end, 'Last 3 Months');
            }, textColor, isDark),
            _buildOption(context, 'Last 6 Months', () {
              final now = DateTime.now();
              final start = DateTime(now.year, now.month - 5, 1);
              final end = now;
              onRangeSelected(start, end, 'Last 6 Months');
            }, textColor, isDark),
            _buildOption(context, 'Last 12 Months', () {
              final now = DateTime.now();
              final start = DateTime(now.year, now.month - 11, 1);
              final end = now;
              onRangeSelected(start, end, 'Last 12 Months');
            }, textColor, isDark),
            _buildOption(context, 'Current Financial Year', () {
              final now = DateTime.now();
              // FY starts April 1st.
              // If now is Jan-Mar (e.g., Feb 2025), FY started April 2024.
              // If now is Apr-Dec (e.g., May 2025), FY started April 2025.
              int startYear = now.month < 4 ? now.year - 1 : now.year;
              final start = DateTime(startYear, 4, 1);
              final end = now;
              onRangeSelected(start, end, 'Current Financial Year');
            }, textColor, isDark),
            _buildOption(context, 'Last Financial Year', () {
              final now = DateTime.now();
              int currentFyStartYear = now.month < 4 ? now.year - 1 : now.year;
              final start = DateTime(currentFyStartYear - 1, 4, 1);
              final end = DateTime(currentFyStartYear, 3, 31, 23, 59, 59);
              onRangeSelected(start, end, 'Last Financial Year');
            }, textColor, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, String title, VoidCallback onTap,
      Color textColor, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
            ),
            borderRadius: BorderRadius.circular(12),
            color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: textColor.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
