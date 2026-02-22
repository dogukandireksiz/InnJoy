import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/database_service.dart';
import '../../utils/responsive_utils.dart';

class SpendingTrackerScreen extends StatefulWidget {
  const SpendingTrackerScreen({super.key});

  @override
  State<SpendingTrackerScreen> createState() => _SpendingTrackerScreenState();
}

class _SpendingTrackerScreenState extends State<SpendingTrackerScreen> {
  // State
  String? _hotelName;
  String? _role;
  String _roomNumber = '...';
  String _guestName = '...';
  bool _isLoading = true;

  // View Controls
  bool _isListView = true; // Toggle between List (Transactions) and Category (Breakdown)
  
  // Date Filter Controls
  String _selectedDateFilter = 'all'; // 'all', 'today', 'week', 'custom'
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (_currentUser == null) return;

    final userData = await DatabaseService().getUser(_currentUser!.uid);
    if (mounted && userData != null) {
      setState(() {
        _hotelName = userData['hotelName'];
        _role = userData['role'];
        _roomNumber = userData['roomNumber'] ?? '';
        _guestName = userData['name_username'] ?? 'Guest';
        _isLoading = false;
      });
    }
  }

  // Date Range Picker
  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 7)),
              end: DateTime.now(),
            ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF009688),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF0d141b),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _selectedDateFilter = 'custom';
      });
    }
  }

  // Filter expenses by date
  List<dynamic> _filterExpensesByDate(List<dynamic> expenses) {
    final now = DateTime.now();
    
    return expenses.where((expense) {
      if (expense['date'] is! Timestamp) return false;
      final DateTime date = (expense['date'] as Timestamp).toDate();
      
      switch (_selectedDateFilter) {
        case 'today':
          return date.year == now.year && 
                 date.month == now.month && 
                 date.day == now.day;
        case 'week':
          final weekAgo = now.subtract(const Duration(days: 7));
          return date.isAfter(weekAgo);
        case 'custom':
          if (_customStartDate == null || _customEndDate == null) return true;
          final startOfDay = DateTime(_customStartDate!.year, _customStartDate!.month, _customStartDate!.day);
          final endOfDay = DateTime(_customEndDate!.year, _customEndDate!.month, _customEndDate!.day, 23, 59, 59);
          return date.isAfter(startOfDay.subtract(const Duration(seconds: 1))) && 
                 date.isBefore(endOfDay.add(const Duration(seconds: 1)));
        case 'all':
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Colors from design
    final Color primaryColor = const Color(0xFF04336A);
    final Color accentColor = const Color(0xFF009688);
    final Color backgroundColor = const Color(0xFFF6F7F8);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hotelName == null
              ? const Center(child: Text("Hotel information not found."))
              : StreamBuilder<Map<String, dynamic>?>(
                  stream: DatabaseService().getMySpending(_hotelName!),
                  builder: (context, snapshot) {
                    double currentBalance = 0.0;
                    List<dynamic> rawExpenses = [];

                    if (snapshot.hasData && snapshot.data != null) {
                      final data = snapshot.data!;
                      if (_role == 'admin') {
                        currentBalance = 0.0;
                      } else {
                        var balanceData = data['currentBalance'];
                        if (balanceData is int) {
                          currentBalance = balanceData.toDouble();
                        } else if (balanceData is double) {
                          currentBalance = balanceData;
                        }
                      }

                      rawExpenses = data['expenses'] ?? [];
                      // Sort by date descending
                      rawExpenses.sort((a, b) {
                        Timestamp? timeA = a['date'] is Timestamp ? a['date'] : null;
                        Timestamp? timeB = b['date'] is Timestamp ? b['date'] : null;
                        if (timeA == null) return 1;
                        if (timeB == null) return -1;
                        return timeB.compareTo(timeA);
                      });
                    }

                    // Apply Date Filter
                    List<dynamic> filteredExpenses = _filterExpensesByDate(rawExpenses);

                    // Calculate Category Totals (excluding minibar)
                    Map<String, Map<String, dynamic>> categoryBreakdown = {};
                    for (var expense in filteredExpenses) {
                      String cat = expense['category'] ?? 'other';
                      // Skip minibar category
                      if (cat == 'minibar') continue;
                      
                      double amount = (expense['amount'] is int)
                          ? (expense['amount'] as int).toDouble()
                          : (expense['amount'] as double?) ?? 0.0;
                      
                      if (!categoryBreakdown.containsKey(cat)) {
                        categoryBreakdown[cat] = {
                           'count': 0,
                           'total': 0.0,
                           'name': _getCategoryName(cat),
                           'icon': _getCategoryIcon(cat),
                           'color': _getCategoryColor(cat),
                           'categoryKey': cat,
                        };
                      }
                      categoryBreakdown[cat]!['count'] = (categoryBreakdown[cat]!['count'] as int) + 1;
                      categoryBreakdown[cat]!['total'] = (categoryBreakdown[cat]!['total'] as double) + amount;
                    }

                    // Filter out minibar from expenses list as well
                    filteredExpenses = filteredExpenses.where((e) => e['category'] != 'minibar').toList();

                    return Column(
                      children: [
                        // Custom App Bar & Header Section
                        Container(
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top + 16,
                            left: 16,
                            right: 16,
                            bottom: 16,
                          ),
                          color: backgroundColor,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  width: ResponsiveUtils.wp(context, 40 / 375),
                                  height: ResponsiveUtils.hp(context, 40 / 844),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 20)),
                                  ),
                                  child: Icon(Icons.arrow_back, color: Color(0xFF0d141b), size: ResponsiveUtils.iconSize(context) * (24 / 24)),
                                ),
                              ),
                              Text(
                                'Spending',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.sp(context, 18),
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0d141b),
                                  fontFamily: 'Plus Jakarta Sans',
                                ),
                              ),
                              SizedBox(width: ResponsiveUtils.spacing(context, 40)), // Spacer for centering
                            ],
                          ),
                        ),

                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 16)),
                            child: Column(
                              children: [
                                // Gradient Balance Card
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Color(0xFF009688), Color(0xFF00BCD4)], // Teal to Cyan
                                    ),
                                    borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 24)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF009688).withValues(alpha: 0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 24)),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Current Balance',
                                                style: TextStyle(
                                                  color: Colors.white.withValues(alpha: 0.9),
                                                  fontSize: ResponsiveUtils.sp(context, 16),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                                              Text(
                                                '₺${currentBalance.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: ResponsiveUtils.sp(context, 36),
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: -1,
                                                ),
                                              ),
                                              SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                                              Text(
                                                '$_guestName, Room $_roomNumber',
                                                style: TextStyle(
                                                  color: Colors.white.withValues(alpha: 0.7),
                                                  fontSize: ResponsiveUtils.sp(context, 14),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.15),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(Icons.account_balance_wallet, color: Colors.white, size: ResponsiveUtils.iconSize(context) * (28 / 24)),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: ResponsiveUtils.spacing(context, 24)),
                                      ElevatedButton(
                                        onPressed: () {
                                          _showSettleDialog(context, currentBalance);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: accentColor,
                                          elevation: 4,
                                          shadowColor: Colors.black.withValues(alpha: 0.2),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 16)),
                                          ),
                                          padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 24), vertical: ResponsiveUtils.spacing(context, 16)),
                                          minimumSize: const Size(double.infinity, 54),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Settle Full Bill',
                                              style: TextStyle(
                                                fontSize: ResponsiveUtils.sp(context, 16),
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Plus Jakarta Sans',
                                              ),
                                            ),
                                            SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                                            Icon(Icons.payment, size: ResponsiveUtils.iconSize(context) * (20 / 24), color: accentColor),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: ResponsiveUtils.spacing(context, 24)),

                                // Date Filter Chips
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      _buildDateFilterChip(
                                        'All Time',
                                        Icons.all_inclusive,
                                        _selectedDateFilter == 'all',
                                        primaryColor,
                                        () => setState(() => _selectedDateFilter = 'all'),
                                      ),
                                      SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                                      _buildDateFilterChip(
                                        'Today',
                                        Icons.today,
                                        _selectedDateFilter == 'today',
                                        primaryColor,
                                        () => setState(() => _selectedDateFilter = 'today'),
                                      ),
                                      SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                                      _buildDateFilterChip(
                                        'Last 7 Days',
                                        Icons.date_range,
                                        _selectedDateFilter == 'week',
                                        primaryColor,
                                        () => setState(() => _selectedDateFilter = 'week'),
                                      ),
                                      SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                                      _buildDateFilterChip(
                                        _selectedDateFilter == 'custom' && _customStartDate != null
                                            ? '${DateFormat('MMM d').format(_customStartDate!)} - ${DateFormat('MMM d').format(_customEndDate!)}'
                                            : 'Custom Range',
                                        Icons.calendar_month,
                                        _selectedDateFilter == 'custom',
                                        primaryColor,
                                        _selectDateRange,
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: ResponsiveUtils.spacing(context, 24)),

                                // Section Header & View Toggle
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _isListView ? 'Recent Transactions' : 'Spending Breakdown',
                                      style: TextStyle(
                                        fontSize: ResponsiveUtils.sp(context, 18),
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0d141b),
                                        fontFamily: 'Plus Jakarta Sans',
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE0E5EB),
                                        borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 24)),
                                      ),
                                      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 4)),
                                      child: Row(
                                        children: [
                                          _buildViewToggleIcon(Icons.list, _isListView, primaryColor, () {
                                            setState(() => _isListView = true);
                                          }),
                                          _buildViewToggleIcon(Icons.category, !_isListView, primaryColor, () {
                                            setState(() => _isListView = false);
                                          }),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: ResponsiveUtils.spacing(context, 16)),

                                // CONTENT AREA
                                if (filteredExpenses.isEmpty)
                                  _buildEmptyState()
                                else if (_isListView)
                                  // LIST VIEW (Transactions) - Grouped by Date
                                  _buildGroupedTransactionList(filteredExpenses)
                                else
                                  // CATEGORY VIEW (Breakdown)
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: categoryBreakdown.length,
                                    itemBuilder: (context, index) {
                                      String key = categoryBreakdown.keys.elementAt(index);
                                      Map<String, dynamic> data = categoryBreakdown[key]!;
                                      return _buildCategoryCard(data, filteredExpenses);
                                    },
                                  ),
                                
                                SizedBox(height: ResponsiveUtils.spacing(context, 40)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }

  Widget _buildDateFilterChip(String label, IconData icon, bool isSelected, Color primary, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: ResponsiveUtils.hp(context, 40 / 844),
        padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 16)),
        decoration: BoxDecoration(
          color: isSelected ? primary.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 24)),
          border: isSelected ? Border.all(color: primary.withValues(alpha: 0.3), width: 1.5) : Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: ResponsiveUtils.iconSize(context) * (16 / 24), color: isSelected ? primary : Colors.grey[600]),
            SizedBox(width: ResponsiveUtils.spacing(context, 6)),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? primary : const Color(0xFF0d141b),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: ResponsiveUtils.sp(context, 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedTransactionList(List<dynamic> expenses) {
    // Group expenses by date
    Map<String, List<dynamic>> groupedExpenses = {};
    
    for (var expense in expenses) {
      if (expense['date'] is Timestamp) {
        DateTime date = (expense['date'] as Timestamp).toDate();
        String dateKey = DateFormat('yyyy-MM-dd').format(date);
        
        if (!groupedExpenses.containsKey(dateKey)) {
          groupedExpenses[dateKey] = [];
        }
        groupedExpenses[dateKey]!.add(expense);
      }
    }

    // Sort keys by date descending
    List<String> sortedKeys = groupedExpenses.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Column(
      children: sortedKeys.map((dateKey) {
        DateTime date = DateTime.parse(dateKey);
        String displayDate = _getDisplayDate(date);
        List<dynamic> dayExpenses = groupedExpenses[dateKey]!;
        
        // Calculate day total
        double dayTotal = dayExpenses.fold(0.0, (runningTotal, e) {
          double amount = 0.0;
          if (e['amount'] is int) amount = (e['amount'] as int).toDouble();
          if (e['amount'] is double) amount = e['amount'];
          return runningTotal + amount;
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Padding(
              padding: EdgeInsets.only(top: 8, bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 12), vertical: ResponsiveUtils.spacing(context, 6)),
                        decoration: BoxDecoration(
                          color: const Color(0xFF04336A).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
                        ),
                        child: Text(
                          displayDate,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.sp(context, 13),
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF04336A),
                          ),
                        ),
                      ),
                      SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                      Text(
                        '${dayExpenses.length} transaction${dayExpenses.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.sp(context, 12),
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '-₺${dayTotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.sp(context, 14),
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4c739a),
                    ),
                  ),
                ],
              ),
            ),
            // Transactions for this date
            ...dayExpenses.map((expense) => _buildTransactionCard(expense)),
          ],
        );
      }).toList(),
    );
  }

  String _getDisplayDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE, MMM d').format(date);
    }
  }

  Widget _buildViewToggleIcon(IconData icon, bool isActive, Color activeColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: ResponsiveUtils.wp(context, 36 / 375),
        height: ResponsiveUtils.hp(context, 36 / 844),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))] : null,
        ),
        child: Icon(
          icon,
          size: ResponsiveUtils.iconSize(context) * (20 / 24),
          color: isActive ? activeColor : const Color(0xFF8B9CB0),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> expense) {
    String title = expense['title'] ?? 'Expense';
    double amount = 0.0;
    if (expense['amount'] is int) amount = (expense['amount'] as int).toDouble();
    if (expense['amount'] is double) amount = expense['amount'];

    String timeStr = '';
    if (expense['date'] is Timestamp) {
      timeStr = DateFormat('HH:mm').format((expense['date'] as Timestamp).toDate());
    }

    String category = expense['category'] ?? 'other';
    IconData icon = _getCategoryIcon(category);
    Color color = _getCategoryColor(category);
    
    // Get additional details if available
    String? details = expense['items'] as String?;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 16)),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: ResponsiveUtils.wp(context, 50 / 375),
            height: ResponsiveUtils.hp(context, 50 / 844),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 25)),
            ),
            child: Icon(icon, color: color, size: ResponsiveUtils.iconSize(context) * (24 / 24)),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveUtils.sp(context, 16),
                    color: Color(0xFF0d141b),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 2)),
                Row(
                  children: [
                    Icon(Icons.access_time, size: ResponsiveUtils.iconSize(context) * (12 / 24), color: Colors.grey[400]),
                    SizedBox(width: ResponsiveUtils.spacing(context, 4)),
                    Text(
                      timeStr,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: ResponsiveUtils.sp(context, 12),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (details != null && details.isNotEmpty) ...[
                      SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                      Text('•', style: TextStyle(color: Colors.grey[400])),
                      SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                      Expanded(
                        child: Text(
                          details,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: ResponsiveUtils.sp(context, 12),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-₺${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveUtils.sp(context, 16),
                  color: Color(0xFF0d141b),
                ),
              ),
              Text(
                _getCategoryName(category),
                style: TextStyle(
                  fontSize: ResponsiveUtils.sp(context, 11),
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> data, List<dynamic> allExpenses) {
    String categoryKey = data['categoryKey'] ?? 'other';
    
    return GestureDetector(
      onTap: () => _showCategoryDetails(categoryKey, data, allExpenses),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 16)),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: ResponsiveUtils.wp(context, 50 / 375),
              height: ResponsiveUtils.hp(context, 50 / 844),
              decoration: BoxDecoration(
                color: (data['color'] as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 25)),
              ),
              child: Icon(data['icon'], color: data['color'], size: ResponsiveUtils.iconSize(context) * (24 / 24)),
            ),
            SizedBox(width: ResponsiveUtils.spacing(context, 16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveUtils.sp(context, 16),
                      color: Color(0xFF0d141b),
                    ),
                  ),
                  Text(
                    '${data['count']} transaction${(data['count'] as int) > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Color(0xFF4c739a),
                      fontSize: ResponsiveUtils.sp(context, 13),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text(
                  '₺${(data['total'] as double).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveUtils.sp(context, 16),
                    color: Color(0xFF0d141b),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                const Icon(Icons.chevron_right, color: Color(0xFF4c739a)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Show category details bottom sheet
  void _showCategoryDetails(String categoryKey, Map<String, dynamic> categoryData, List<dynamic> allExpenses) {
    // Filter expenses for this category
    List<dynamic> categoryExpenses = allExpenses
        .where((e) => (e['category'] ?? 'other') == categoryKey)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 12),
                width: ResponsiveUtils.wp(context, 40 / 375),
                height: ResponsiveUtils.hp(context, 4 / 844),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 2)),
                ),
              ),
              // Header
              Padding(
                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
                child: Row(
                  children: [
                    Container(
                      width: ResponsiveUtils.wp(context, 50 / 375),
                      height: ResponsiveUtils.hp(context, 50 / 844),
                      decoration: BoxDecoration(
                        color: (categoryData['color'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 25)),
                      ),
                      child: Icon(categoryData['icon'], color: categoryData['color'], size: ResponsiveUtils.iconSize(context) * (24 / 24)),
                    ),
                    SizedBox(width: ResponsiveUtils.spacing(context, 16)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            categoryData['name'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: ResponsiveUtils.sp(context, 20),
                              color: Color(0xFF0d141b),
                            ),
                          ),
                          Text(
                            'Total: ₺${(categoryData['total'] as double).toStringAsFixed(2)}',
                            style: TextStyle(
                              color: categoryData['color'],
                              fontSize: ResponsiveUtils.sp(context, 16),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Divider(height: 1),
              // Transactions list
              Expanded(
                child: categoryExpenses.isEmpty
                    ? Center(
                        child: Text(
                          'No transactions in this category',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                        itemCount: categoryExpenses.length,
                        itemBuilder: (context, index) {
                          return _buildTransactionCard(categoryExpenses[index]);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 40.0)),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: ResponsiveUtils.iconSize(context) * (64 / 24), color: Colors.grey[300]),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          Text(
            "No expenses found.",
            style: TextStyle(fontSize: ResponsiveUtils.sp(context, 16), color: Colors.grey[500], fontWeight: FontWeight.w500),
          ),
          if (_selectedDateFilter != 'all')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton(
                onPressed: () => setState(() => _selectedDateFilter = 'all'),
                child: const Text('Show all transactions'),
              ),
            ),
        ],
      ),
    );
  }

  void _showSettleDialog(BuildContext context, double amount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 16))),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 8)),
              decoration: BoxDecoration(
                color: const Color(0xFF009688).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 8)),
              ),
              child: const Icon(Icons.info_outline, color: Color(0xFF009688)),
            ),
            SizedBox(width: ResponsiveUtils.spacing(context, 12)),
            Text('Payment Information'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F7F8),
                borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount:',
                    style: TextStyle(fontSize: ResponsiveUtils.sp(context, 16), color: Color(0xFF4c739a)),
                  ),
                  Text(
                    '₺${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.sp(context, 24),
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0d141b),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 20)),
            Row(
              children: [
                Icon(Icons.construction, size: ResponsiveUtils.iconSize(context) * (20 / 24), color: Colors.orange[700]),
                SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                Expanded(
                  child: Text(
                    'Online payment feature is under development.',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0d141b),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            Text(
              'For now, please visit the reception to complete your payment. Thank you for your understanding!',
              style: TextStyle(
                fontSize: ResponsiveUtils.sp(context, 14),
                height: ResponsiveUtils.hp(context, 1.5 / 844),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF009688),
              padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 24), vertical: ResponsiveUtils.spacing(context, 12)),
            ),
            child: const Text('Got it!', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Helpers
  String _getCategoryName(String cat) {
    switch(cat) {
      case 'room_service': return 'Room Service';
      case 'spa_wellness': return 'Spa & Wellness';
      case 'restaurant': return 'Dining & Restaurants';
      default: return 'Other';
    }
  }

  IconData _getCategoryIcon(String cat) {
    switch(cat) {
      case 'room_service': return Icons.room_service;
      case 'spa_wellness': return Icons.spa;
      case 'restaurant': return Icons.restaurant;
      default: return Icons.local_offer;
    }
  }

  Color _getCategoryColor(String cat) {
    switch(cat) {
      case 'room_service': return Colors.orange;
      case 'spa_wellness': return Colors.purple;
      case 'restaurant': return const Color(0xFF009688); // Teal
      default: return Colors.grey;
    }
  }
}










