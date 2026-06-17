import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'add_expense_screen.dart';
import 'edit_expense_screen.dart';
import '../models/expense_model.dart';
import '../controllers/expense_controller.dart';
import '../controllers/order_controller.dart';

// --- Design System Constants ---
const Color kPrimary = Color(0xFF1E3A5F);
const Color kAccent = Color(0xFF10B981);
const Color kBg = Color(0xFFF8FAFC);
const Color kCard = Color(0xFFFFFFFF);
const Color kTextPri = Color(0xFF0F172A);
const Color kTextSec = Color(0xFF64748B);
const double kR = 16.0;

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  final ExpenseController _controller = ExpenseController();
  final OrderController _orderController = OrderController();

  DateTime _currentMonth = DateTime.now();
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    '🏠 Rent',
    '⚡ Electricity',
    '🧵 Material',
    '👤 Salary',
    '🔧 Maintenance',
    '📦 Other'
  ];

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
    _controller.addListener(_onControllerChanged);
    _orderController.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _orderController.removeListener(_onControllerChanged);
    _animController.dispose();
    super.dispose();
  }

  void _changeMonth(int dir) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + dir);
    });
    _animController.reset();
    _animController.forward();
  }

  // ── Category emoji/icon helper ──
  String _getCategoryEmoji(String cat) {
    if (cat.contains('Rent'))        return '🏠';
    if (cat.contains('Electricity')) return '⚡';
    if (cat.contains('Material'))    return '🧵';
    if (cat.contains('Salary'))      return '👤';
    if (cat.contains('Maintenance')) return '🔧';
    return '📦';
  }


  // ── Navigate to Edit Expense screen ──
  void _navigateToEdit(ExpenseModel exp) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, secondaryAnimation) => EditExpenseScreen(
          expenseId:       exp.id,
          expenseTitle:    exp.title,
          expenseAmount:   exp.amount,
          expenseCategory: exp.category,
          expenseDate:     exp.date,
          expenseNotes:    exp.notes ?? '',
        ),
        transitionsBuilder: (_, animation, secondaryAnimation, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    ).then((_) => _controller.loadExpenses());
  }

  // ── Show animated delete confirmation popup ──
  void _showDeleteConfirmation(ExpenseModel exp) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => const SizedBox.shrink(),
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curved,
          child: FadeTransition(
            opacity: animation,
            child: _DeleteConfirmationDialog(
              expense: exp,
              onDelete: () async {
                Navigator.pop(ctx); // close dialog
                await _controller.deleteExpense(exp.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '"${exp.title}" deleted',
                        style: GoogleFonts.inter(color: Colors.white),
                      ),
                      backgroundColor: Colors.red.shade500,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
              onCancel: () => Navigator.pop(ctx),
            ),
          ),
        );
      },
    );
  }

  void _showExpenseDetail(ExpenseModel exp) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExpenseDetailSheet(expense: exp, onEdit: () => _navigateToEdit(exp)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filtered list (by category chip and current month)
    final monthExpenses = _controller.expenses.where((e) =>
        e.date.year == _currentMonth.year && e.date.month == _currentMonth.month);
        
    final filteredExpenses = _selectedCategory == 'All'
        ? monthExpenses.toList()
        : monthExpenses.where((e) =>
            e.category == _selectedCategory.split(' ').skip(1).join(' ')).toList();

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'Expenses',
          style: GoogleFonts.inter(
            color: kPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: kPrimary),
            onPressed: () => _controller.loadExpenses(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildSummaryCard(),
              const SizedBox(height: 24),
              _buildChartCard(),
              const SizedBox(height: 24),
              _buildCategoryChips(),
              const SizedBox(height: 24),
              Text(
                'Transactions',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kPrimary,
                ),
              ),
              const SizedBox(height: 16),
              if (filteredExpenses.isEmpty)
                _buildEmptyState()
              else
                ...filteredExpenses.map((e) => _buildExpenseCard(e)),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, animation, secondaryAnimation) => const AddExpenseScreen(),
              transitionsBuilder: (_, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 350),
            ),
          ).then((_) => _controller.loadExpenses());
        },
        backgroundColor: kAccent,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final monthExpenses = _controller.expenses.where((e) =>
        e.date.year == _currentMonth.year && e.date.month == _currentMonth.month);
    final double totalExpenses = monthExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final double totalIncome = _orderController.orders
        .where((o) => o.orderDate.year == _currentMonth.year && o.orderDate.month == _currentMonth.month)
        .fold(0.0, (sum, o) => sum + o.totalAmount);
    final double netBalance = totalIncome - totalExpenses;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kPrimary,
        borderRadius: BorderRadius.circular(kR),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month navigator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: () => _changeMonth(-1),
              ),
              Text(
                DateFormat('MMMM yyyy').format(_currentMonth),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                onPressed: () => _changeMonth(1),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _AnimatedStat(
                  label: 'Total Income',
                  value: totalIncome,
                  color: kAccent,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _AnimatedStat(
                  label: 'Total Expenses',
                  value: totalExpenses,
                  color: Colors.red.shade400,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _AnimatedStat(
                  label: 'Net Balance',
                  value: netBalance,
                  color: netBalance >= 0 ? kAccent : Colors.red.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    // Build 6 months of expense data ending at current month
    final now = _currentMonth;
    final months = List.generate(6, (i) => DateTime(now.year, now.month - 5 + i));
    final monthLabels = months.map((m) => DateFormat('MMM').format(m)).toList();

    double maxY = 10;
    final expenseByMonth = months.map((m) {
      final total = _controller.expenses
          .where((e) => e.date.year == m.year && e.date.month == m.month)
          .fold(0.0, (sum, e) => sum + e.amount) / 1000; // in thousands
      if (total > maxY) maxY = total;
      return total;
    }).toList();
    final incomeByMonth = months.map((m) {
      final total = _orderController.orders
          .where((o) => o.orderDate.year == m.year && o.orderDate.month == m.month)
          .fold(0.0, (sum, o) => sum + o.totalAmount) / 1000;
      if (total > maxY) maxY = total;
      return total;
    }).toList();
    maxY = (maxY * 1.3).ceilToDouble().clamp(10, double.infinity);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(kR),
        boxShadow: [
          BoxShadow(
            color: kTextPri.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Overview',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kPrimary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final label = rodIndex == 0 ? 'Income' : 'Expenses';
                      return BarTooltipItem(
                        '$label\nPKR ${(rod.toY * 1000).toStringAsFixed(0)}',
                        GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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
                        if (value.toInt() < 0 || value.toInt() >= monthLabels.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            monthLabels[value.toInt()],
                            style: GoogleFonts.inter(color: kTextSec, fontSize: 11),
                          ),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox();
                        return Text(
                          '${value.toStringAsFixed(0)}k',
                          style: GoogleFonts.inter(color: kTextSec, fontSize: 11),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(6, (i) => _buildBarGroup(i, incomeByMonth[i], expenseByMonth[i])),
              ),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(kAccent, 'Income'),
              const SizedBox(width: 24),
              _buildLegend(Colors.red.shade400, 'Expenses'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: kTextSec)),
      ],
    );
  }

  BarChartGroupData _buildBarGroup(int x, double income, double expense) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: income,
          color: kAccent,
          width: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        BarChartRodData(
          toY: expense,
          color: Colors.red.shade400,
          width: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildCategoryChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kPrimary,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: _categories.map((cat) {
              final isActive = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? kAccent : kCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive ? kAccent : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        color: isActive ? Colors.white : kTextPri,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseCard(ExpenseModel exp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(exp.id),
        // ── Swipe RIGHT background (green + edit icon) ──
        background: Container(
          decoration: BoxDecoration(
            color: Colors.green.shade500,
            borderRadius: BorderRadius.circular(kR),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text('Edit', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        // ── Swipe LEFT background (red + delete icon) ──
        secondaryBackground: Container(
          decoration: BoxDecoration(
            color: Colors.red.shade500,
            borderRadius: BorderRadius.circular(kR),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Delete', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              const Icon(Icons.delete_outline, color: Colors.white, size: 24),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            // Swipe RIGHT → navigate to Edit screen (do NOT dismiss)
            _navigateToEdit(exp);
            return false;
          } else {
            // Swipe LEFT → show delete confirmation (do NOT auto-dismiss)
            _showDeleteConfirmation(exp);
            return false;
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(kR),
            boxShadow: [
              BoxShadow(
                color: kTextPri.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            onTap: () => _showExpenseDetail(exp),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: _getCategoryColor(exp.category).withValues(alpha: 0.1),
              child: Text(
                _getCategoryEmoji(exp.category),
                style: const TextStyle(fontSize: 20),
              ),
            ),
            title: Text(
              exp.title,
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: kTextPri),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  exp.category,
                  style: GoogleFonts.inter(fontSize: 12, color: kTextSec),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd MMM yyyy').format(exp.date),
                  style: GoogleFonts.inter(fontSize: 11, color: kTextSec),
                ),
              ],
            ),
            trailing: Text(
              'PKR ${NumberFormat('#,###').format(exp.amount)}',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No expenses found',
              style: GoogleFonts.inter(fontSize: 16, color: kTextSec),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String cat) {
    if (cat.contains('Rent'))        return const Color(0xFF3B82F6);
    if (cat.contains('Electricity')) return const Color(0xFFEAB308);
    if (cat.contains('Material'))    return const Color(0xFF8B5CF6);
    if (cat.contains('Salary'))      return const Color(0xFFF97316);
    if (cat.contains('Maintenance')) return const Color(0xFFEF4444);
    return Colors.grey;
  }
}


class _AnimatedStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _AnimatedStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: value),
          duration: const Duration(seconds: 1),
          curve: Curves.easeOutCubic,
          builder: (context, val, child) {
            String formatted = NumberFormat.compact().format(val);
            return Text(
              formatted,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class _AddExpenseSheet extends StatefulWidget {
  const _AddExpenseSheet();

  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _category = '🏠 Rent';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Add Expense',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kPrimary,
              ),
            ),
            const SizedBox(height: 24),
            _buildInput(label: 'Expense Title', icon: Icons.title, controller: _titleCtrl),
            const SizedBox(height: 16),
            _buildInput(label: 'Amount (PKR)', icon: Icons.attach_money, controller: _amountCtrl, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              items: ['🏠 Rent', '⚡ Electricity', '🧵 Material', '👤 Salary', '🔧 Maintenance', '📦 Other']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
              decoration: InputDecoration(
                labelText: 'Category',
                prefixIcon: const Icon(Icons.category_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(kR)),
              ),
            ),
            const SizedBox(height: 16),
            _buildInput(label: 'Date', icon: Icons.calendar_today, readOnly: true, initialValue: 'Today'),
            const SizedBox(height: 16),
            _buildInput(label: 'Notes (Optional)', icon: Icons.notes, controller: _notesCtrl, maxLines: 2),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kR)),
                    ),
                    child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: kTextPri)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kR)),
                      elevation: 0,
                    ),
                    child: Text('Save Expense', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput({
    required String label,
    required IconData icon,
    TextEditingController? controller,
    String? initialValue,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(kR)),
      ),
    );
  }
}

class _ExpenseDetailSheet extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback onEdit;

  const _ExpenseDetailSheet({required this.expense, required this.onEdit});

  static String _emoji(String cat) {
    if (cat.contains('Rent'))        return '🏠';
    if (cat.contains('Electricity')) return '⚡';
    if (cat.contains('Material'))    return '🧵';
    if (cat.contains('Salary'))      return '👤';
    if (cat.contains('Maintenance')) return '🔧';
    return '📦';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.grey.shade100,
            child: Text(_emoji(expense.category), style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(height: 16),
          Text(
            expense.title,
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: kTextPri),
          ),
          const SizedBox(height: 8),
          Text(
            'PKR ${NumberFormat('#,###').format(expense.amount)}',
            style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.red.shade500),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              expense.category,
              style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: kTextSec),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today_outlined, size: 16, color: kTextSec),
              const SizedBox(width: 8),
              Text(DateFormat('dd MMM yyyy').format(expense.date), style: GoogleFonts.inter(color: kTextSec)),
            ],
          ),
          // ── Notes ──
          if (expense.notes != null && expense.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notes',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: kTextSec)),
                  const SizedBox(height: 6),
                  Text(expense.notes!,
                    style: GoogleFonts.inter(fontSize: 13, color: kTextPri, height: 1.5)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onEdit();
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kR)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kR)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  _DeleteConfirmationDialog
// ─────────────────────────────────────────────────────────────────
class _DeleteConfirmationDialog extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback onDelete;
  final VoidCallback onCancel;

  const _DeleteConfirmationDialog({
    required this.expense,
    required this.onDelete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(kR),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Red warning icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade500, size: 36),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Delete Expense?',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kTextPri,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                'This action cannot be undone.\nThis expense will be permanently deleted.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: kTextSec, height: 1.5),
              ),
              const SizedBox(height: 24),

              // Expense Preview Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child: Text(_ExpenseDetailSheet._emoji(expense.category), style: const TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense.title,
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: kTextPri, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            DateFormat('dd MMM yyyy').format(expense.date),
                            style: GoogleFonts.inter(fontSize: 12, color: kTextSec),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'PKR ${NumberFormat('#,###').format(expense.amount)}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: onDelete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade500,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Delete',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: kPrimary.withValues(alpha: 0.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
