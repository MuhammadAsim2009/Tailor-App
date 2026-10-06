import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'profile_settings_screen.dart';
import 'orders_screen.dart';
import 'customers_screen.dart';
import 'speed_dial_fab.dart';
import 'add_order_screen.dart';
import 'add_expense_screen.dart';
import 'order_detail_screen.dart';
import 'expenses_screen.dart';
import '../controllers/order_controller.dart';
import '../controllers/expense_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/wallet_controller.dart';
import '../models/order_model.dart';
import '../models/wallet_transaction_model.dart';
import 'services/firebase_sync_service.dart';

// --- Design System Constants ---
const Color kPrimaryColor = Color(0xFF1E3A5F); // Deep Navy
const Color kAccentColor = Color(0xFF10B981); // Emerald Green
const Color kBackgroundColor = Color(0xFFF8FAFC);
const Color kCardColor = Color(0xFFFFFFFF);
const Color kTextPrimary = Color(0xFF0F172A);
const Color kTextSecondary = Color(0xFF64748B);
const double kBorderRadius = 16.0;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  int _bottomNavIndex = 0;
  String _activeStatusChip = 'Pending';
  final OrderController _orderController = OrderController();
  final ExpenseController _expenseController = ExpenseController();
  final ProfileController _profileController = ProfileController();
  final WalletController _walletController = WalletController.instance;

  DateTime _selectedDate = DateTime.now();

  bool _isSameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isSameMonth(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month;
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _orderController.addListener(_onStateChanged);
    _expenseController.addListener(_onStateChanged);
    _profileController.addListener(_onStateChanged);
    _walletController.addListener(_onStateChanged);
    FirebaseSyncService.instance.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _orderController.removeListener(_onStateChanged);
    _expenseController.removeListener(_onStateChanged);
    _profileController.removeListener(_onStateChanged);
    _walletController.removeListener(_onStateChanged);
    FirebaseSyncService.instance.removeListener(_onStateChanged);
    super.dispose();
  }

  List<OrderModel> get _filteredOrders {
    return _orderController.orders
        .where((o) => o.status == _activeStatusChip)
        .toList();
  }

  final List<String> _statusFilters = [
    'Pending',
    'In Progress',
    'Ready',
    'Delivered',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: _orderController.isLoading
          ? SafeArea(child: _buildSkeletonLoading())
          : _bottomNavIndex == 1
          ? const OrdersScreen()
          : _bottomNavIndex == 2
          ? const CustomersScreen()
          : _bottomNavIndex == 3
          ? const ExpenseScreen()
          : SafeArea(child: _buildContent()),
      bottomNavigationBar: _AnimatedBottomBar(
        currentIndex: _bottomNavIndex,
        onTap: (index) => setState(() => _bottomNavIndex = index),
      ),
      floatingActionButton: _orderController.isLoading
          ? null
          : SpeedDialFAB(
              options: [
                SpeedDialOption(
                  icon: Icons.receipt_long_outlined,
                  label: 'Add Order',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddOrderScreen()),
                    ).then((_) => _orderController.loadData());
                  },
                ),
                SpeedDialOption(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Add Expense',
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, animation, secondaryAnimation) =>
                            const AddExpenseScreen(),
                        transitionsBuilder:
                            (_, animation, secondaryAnimation, child) {
                              return SlideTransition(
                                position:
                                    Tween<Offset>(
                                      begin: const Offset(0, 1),
                                      end: Offset.zero,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOutCubic,
                                      ),
                                    ),
                                child: child,
                              );
                            },
                        transitionDuration: const Duration(milliseconds: 350),
                      ),
                    ).then((_) => _orderController.loadData());
                  },
                ),
              ],
            ),
    );
  }

  // --- Main Content Structure ---

  Widget _buildContent() {
    return RefreshIndicator(
      color: kAccentColor,
      backgroundColor: kCardColor,
      onRefresh: () async {
        await FirebaseSyncService.instance.forcePullFromFirebase();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildOtherWalletCard(),
            const SizedBox(height: 16),
            _buildTodayIncomeCard(),
            const SizedBox(height: 16),
            _buildKPIGrid(),
            const SizedBox(height: 32),
            _buildQuickActions(),
            const SizedBox(height: 32),
            _buildOrderStatusFilter(),
            const SizedBox(height: 16),
            _buildRecentOrders(),
          ],
        ),
      ),
    );
  }

  // --- Subcomponents ---

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning,';
    } else if (hour < 17) {
      return 'Good Afternoon,';
    } else {
      return 'Good Evening,';
    }
  }

  Widget _buildHeader() {
    final syncStatus = FirebaseSyncService.instance.status;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: GoogleFonts.inter(fontSize: 14, color: kTextSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                _profileController.profile?.shopName ?? 'Tailor App',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: _pickDate,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isSameDay(_selectedDate, DateTime.now())
                          ? DateFormat('EEEE, d MMM').format(_selectedDate)
                          : DateFormat('d MMM yyyy').format(_selectedDate),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: _isSameDay(_selectedDate, DateTime.now())
                            ? kTextSecondary
                            : kPrimaryColor,
                        fontWeight: _isSameDay(_selectedDate, DateTime.now())
                            ? FontWeight.normal
                            : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: _isSameDay(_selectedDate, DateTime.now())
                          ? kTextSecondary
                          : kPrimaryColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sync Status Badge
            _SyncBadge(status: syncStatus),
            const SizedBox(width: 8),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: kCardColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kTextPrimary.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.person_outline, color: kPrimaryColor),
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const ProfileSettingsScreen(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                            return child;
                          },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOtherWalletCard() {
    final walletBalance = _walletController.balance;
    final isNegative = walletBalance < 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF065F46), Color(0xFF059669), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(kBorderRadius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showWalletSheet,
          borderRadius: BorderRadius.circular(kBorderRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Other Wallet',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Rs. ${isNegative ? '-' : ''}${walletBalance.abs().toInt()}',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap to view history & add funds',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayIncomeCard() {
    final sel = _selectedDate;
    final isViewingToday = _isSameDay(sel, DateTime.now());

    // Sum payments that were actually recorded on selected date (from the payments ledger)
    final dailyIncome = _orderController.payments
        .where((p) => _isSameDay(p.paidAt, sel))
        .fold<double>(0, (sum, p) => sum + p.amount);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kPrimaryColor, Color(0xFF2A5298)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(kBorderRadius),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.white70,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isViewingToday ? 'Today\'s Income' : 'Income on ${DateFormat('d MMM').format(sel)}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (!isViewingToday)
                GestureDetector(
                  onTap: () => setState(() => _selectedDate = DateTime.now()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.today, size: 13, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'Today',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Rs. ${dailyIncome.toInt()}',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPIGrid() {
    final sel = _selectedDate;
    final isViewingToday = _isSameDay(_selectedDate, DateTime.now());

    // Use payments ledger for accurate daily income tracking
    final todayCollected = _orderController.payments
        .where((p) => _isSameDay(p.paidAt, sel))
        .fold<double>(0, (sum, p) => sum + p.amount);
    // Only deduct shop expenses from revenue (not other-wallet ones)
    final todayExpensesList = _expenseController.expenses
        .where((e) => _isSameDay(e.date, sel))
        .toList();
    final todayShopExpenses = todayExpensesList
        .where((e) => e.walletSource != 'other')
        .fold<double>(0, (sum, e) => sum + e.amount);
    final todayTotalExpenses = todayExpensesList
        .fold<double>(0, (sum, e) => sum + e.amount);
    final todayRevenue = todayCollected - todayShopExpenses;

    final allOrders = _orderController.orders;
    final todayOrders = allOrders.where((o) => _isSameDay(o.orderDate, sel)).toList();
    final total = todayOrders.length;

    // Pending dues: cumulative if today, or for the selected date's orders
    final pendingAmount = isViewingToday
        ? allOrders.fold<double>(
            0,
            (sum, o) => sum + (o.totalAmount - o.advancePaid),
          )
        : todayOrders.fold<double>(
            0,
            (sum, o) => sum + (o.totalAmount - o.advancePaid),
          );

    // Completed on selected date
    final completed = allOrders
        .where((o) => o.status == 'Delivered' && _isSameDay(o.updatedAt, sel))
        .length;

    final monthCollected = _orderController.payments
        .where((p) => _isSameMonth(p.paidAt, sel))
        .fold<double>(0, (sum, p) => sum + p.amount);
    final monthShopExpenses = _expenseController.expenses
        .where((e) => _isSameMonth(e.date, sel) && e.walletSource != 'other')
        .fold<double>(0, (sum, e) => sum + e.amount);
    final monthRevenue = monthCollected - monthShopExpenses;

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      children: [
        _buildKPICard(
          title: isViewingToday ? 'Today\'s Revenue' : 'Day Revenue',
          value: todayRevenue.toInt(),
          icon: Icons.account_balance_wallet_outlined,
          bgColor: kPrimaryColor,
          textColor: Colors.white,
          isCurrency: true,
        ),
        _buildKPICard(
          title: isViewingToday ? 'Today\'s Expenses' : 'Day Expenses',
          value: todayTotalExpenses.toInt(),
          icon: Icons.money_off_csred_outlined,
          bgColor: kCardColor,
          textColor: kTextPrimary,
          iconColor: Colors.redAccent,
          isCurrency: true,
        ),
        _buildKPICard(
          title: isViewingToday ? 'Today\'s Orders' : 'Day Orders',
          value: total,
          icon: Icons.list_alt_outlined,
          bgColor: kPrimaryColor,
          textColor: Colors.white,
        ),
        _buildKPICard(
          title: isViewingToday ? 'Pending Dues' : 'Day Pending Dues',
          value: pendingAmount.toInt(),
          icon: Icons.pending_actions_outlined,
          bgColor: kCardColor,
          textColor: kTextPrimary,
          iconColor: Colors.orange,
          isCurrency: true,
        ),
        _buildKPICard(
          title: isViewingToday ? 'Completed Today' : 'Completed',
          value: completed,
          icon: Icons.check_circle_outline,
          bgColor: kCardColor,
          textColor: kTextPrimary,
          iconColor: kAccentColor,
        ),
        _buildKPICard(
          title: isViewingToday ? 'Monthly Revenue' : '${DateFormat('MMM yyyy').format(sel)} Revenue',
          value: monthRevenue.toInt(),
          icon: Icons.account_balance_wallet_outlined,
          bgColor: kCardColor,
          textColor: kTextPrimary,
          iconColor: Colors.purple,
          isCurrency: true,
        ),
      ],
    );
  }


  Widget _buildKPICard({
    required String title,
    required int value,
    required IconData icon,
    required Color bgColor,
    required Color textColor,
    Color? iconColor,
    bool isCurrency = false,
    VoidCallback? onTap,
  }) {
    final card = Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(kBorderRadius),
        boxShadow: [
          BoxShadow(
            color: kTextPrimary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Icon(icon, color: iconColor ?? textColor, size: 24)],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AnimatedCounter(
              targetValue: value,
              textStyle: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              prefix: isCurrency ? 'PKR ' : '',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: bgColor == kPrimaryColor ? Colors.white70 : kTextSecondary,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return ClipRRect(
      borderRadius: BorderRadius.circular(kBorderRadius),
      child: Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, child: card),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionItem(
              icon: Icons.add_circle_outline,
              label: 'New Order',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddOrderScreen()),
              ).then((_) => _orderController.loadData()),
            ),
            _buildActionItem(
              icon: Icons.people_outline,
              label: 'Customers',
              onTap: () => setState(() => _bottomNavIndex = 2),
            ),
            _buildActionItem(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Expenses',
              onTap: () => setState(() => _bottomNavIndex = 3),
            ),
            _buildActionItem(
              icon: Icons.list_alt_outlined,
              label: 'Orders',
              onTap: () => setState(() => _bottomNavIndex = 1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: kTextPrimary.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Icon(icon, color: kPrimaryColor),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: kTextPrimary),
        ),
      ],
    );
  }

  Widget _buildOrderStatusFilter() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _statusFilters.length,
        itemBuilder: (context, index) {
          final status = _statusFilters[index];
          final isActive = status == _activeStatusChip;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: ChoiceChip(
                label: Text(status),
                selected: isActive,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _activeStatusChip = status;
                    });
                  }
                },
                selectedColor: kAccentColor,
                backgroundColor: kCardColor,
                labelStyle: GoogleFonts.inter(
                  color: isActive ? Colors.white : kTextSecondary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isActive ? kAccentColor : Colors.grey.shade300,
                  ),
                ),
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentOrders() {
    final orders = _filteredOrders;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Orders',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        if (orders.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'No orders found for this status.',
                style: GoogleFonts.inter(color: kTextSecondary),
              ),
            ),
          )
        else
          ...orders.map((order) {
            final customerName = _orderController.getCustomerName(
              order.customerId,
            );
            final deliveryFormatted = DateFormat(
              'd MMM yyyy',
            ).format(order.deliveryDate);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: kCardColor,
                borderRadius: BorderRadius.circular(kBorderRadius),
                boxShadow: [
                  BoxShadow(
                    color: kTextPrimary.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                onTap: () {
                  final customer = _orderController.getCustomerById(
                    order.customerId,
                  );
                  if (customer != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            OrderDetailScreen(order: order, customer: customer),
                      ),
                    ).then((_) => _orderController.loadData());
                  }
                },
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                title: Text(
                  customerName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      order.isAdult ? 'Adult Order' : 'Child Order',
                      style: GoogleFonts.inter(
                        color: kTextSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: kTextSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          deliveryFormatted,
                          style: GoogleFonts.inter(
                            color: kTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: _buildStatusBadge(order.status),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Pending':
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      case 'In Progress':
        bgColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        break;
      case 'Ready':
        bgColor = kAccentColor.withValues(alpha: 0.2);
        textColor = kAccentColor;
        break;
      case 'Delivered':
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(now) ? now : _selectedDate,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: kPrimaryColor,
            onPrimary: Colors.white,
            onSurface: kPrimaryColor,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showWalletSheet() {
    DateTimeRange? selectedRange;
    String activeFilter = 'All'; // 'All', 'Today', 'This Week', 'This Month', 'Custom'

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final now = DateTime.now();
            final allTxns = _walletController.transactions
                .where((t) => t.deletedAt == null)
                .toList();

            final txns = allTxns.where((t) {
              if (activeFilter == 'All') return true;
              final d = t.date.toLocal();
              if (activeFilter == 'Today') {
                return d.year == now.year && d.month == now.month && d.day == now.day;
              } else if (activeFilter == 'This Week') {
                final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
                final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
                return d.isAfter(start.subtract(const Duration(seconds: 1)));
              } else if (activeFilter == 'This Month') {
                return d.year == now.year && d.month == now.month;
              } else if (activeFilter == 'Custom' && selectedRange != null) {
                final start = DateTime(
                  selectedRange!.start.year,
                  selectedRange!.start.month,
                  selectedRange!.start.day,
                );
                final end = DateTime(
                  selectedRange!.end.year,
                  selectedRange!.end.month,
                  selectedRange!.end.day,
                  23,
                  59,
                  59,
                );
                return d.isAfter(start.subtract(const Duration(seconds: 1))) &&
                    d.isBefore(end.add(const Duration(seconds: 1)));
              }
              return true;
            }).toList()
              ..sort((a, b) => b.date.compareTo(a.date));

            final balance = _walletController.balance;

            final periodCredits = txns
                .where((t) => t.type == 'credit')
                .fold<double>(0, (sum, t) => sum + t.amount);
            final periodDebits = txns
                .where((t) => t.type == 'debit')
                .fold<double>(0, (sum, t) => sum + t.amount);

            Future<void> pickCustomRange() async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: selectedRange ??
                    DateTimeRange(
                      start: DateTime.now().subtract(const Duration(days: 7)),
                      end: DateTime.now(),
                    ),
                builder: (pickerCtx, child) => Theme(
                  data: Theme.of(pickerCtx).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: kPrimaryColor,
                      onPrimary: Colors.white,
                      onSurface: kPrimaryColor,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) {
                setSheetState(() {
                  selectedRange = picked;
                  activeFilter = 'Custom';
                });
              }
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Other Wallet',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: kPrimaryColor,
                              ),
                            ),
                            Text(
                              'Separate funds & expense tracking',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: kTextSecondary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: kTextSecondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Balance Card + Add Money Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E3A5F), Color(0xFF0F172A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Balance',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'PKR ${balance.toInt()}',
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              _showAddMoneyDialog(ctx, () {
                                setSheetState(() {});
                                setState(() {});
                              });
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(
                              'Add Money',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Date Range Filter Bar
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _buildWalletFilterChip(
                          label: 'All',
                          isSelected: activeFilter == 'All',
                          onTap: () => setSheetState(() => activeFilter = 'All'),
                        ),
                        const SizedBox(width: 8),
                        _buildWalletFilterChip(
                          label: 'Today',
                          isSelected: activeFilter == 'Today',
                          onTap: () => setSheetState(() => activeFilter = 'Today'),
                        ),
                        const SizedBox(width: 8),
                        _buildWalletFilterChip(
                          label: 'This Week',
                          isSelected: activeFilter == 'This Week',
                          onTap: () => setSheetState(() => activeFilter = 'This Week'),
                        ),
                        const SizedBox(width: 8),
                        _buildWalletFilterChip(
                          label: 'This Month',
                          isSelected: activeFilter == 'This Month',
                          onTap: () => setSheetState(() => activeFilter = 'This Month'),
                        ),
                        const SizedBox(width: 8),
                        _buildWalletFilterChip(
                          label: activeFilter == 'Custom' && selectedRange != null
                              ? '${DateFormat('d MMM').format(selectedRange!.start)} - ${DateFormat('d MMM').format(selectedRange!.end)}'
                              : 'Custom Range 📅',
                          isSelected: activeFilter == 'Custom',
                          icon: Icons.date_range,
                          onTap: pickCustomRange,
                        ),
                      ],
                    ),
                  ),
                  if (activeFilter != 'All') ...[
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'In: +PKR ${periodCredits.toInt()}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Out: -PKR ${periodDebits.toInt()}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => setSheetState(() {
                                activeFilter = 'All';
                                selectedRange = null;
                              }),
                              child: Text(
                                'Clear',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: kPrimaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(
                          'Transaction History (Ledger)',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${txns.length} records',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: kTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: txns.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 48,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  activeFilter == 'All'
                                      ? 'No transactions yet'
                                      : 'No transactions for this date range',
                                  style: GoogleFonts.inter(
                                    color: kTextSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            itemCount: txns.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: Colors.grey.shade100,
                            ),
                            itemBuilder: (context, index) {
                              final t = txns[index];
                              final isCredit = t.type == 'credit';
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isCredit
                                        ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                        : Colors.red.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isCredit
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    color: isCredit
                                        ? const Color(0xFF10B981)
                                        : Colors.red,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  isCredit
                                      ? (t.notes?.isNotEmpty == true
                                          ? t.notes!
                                          : 'Deposit / Added')
                                      : (t.notes?.isNotEmpty == true
                                          ? t.notes!
                                          : 'Expense / Debit'),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: kTextPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  DateFormat('d MMM yyyy, hh:mm a').format(t.date),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: kTextSecondary,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${isCredit ? '+' : '-'} PKR ${t.amount.toInt()}',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isCredit
                                            ? const Color(0xFF10B981)
                                            : Colors.red,
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, size: 20, color: kTextSecondary),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onSelected: (action) {
                                        if (action == 'edit') {
                                          _showEditWalletTransactionDialog(ctx, t, () {
                                            setSheetState(() {});
                                            setState(() {});
                                          });
                                        } else if (action == 'delete') {
                                          _showDeleteWalletTransactionDialog(ctx, t, () {
                                            setSheetState(() {});
                                            setState(() {});
                                          });
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.edit_outlined, size: 18, color: kPrimaryColor),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Edit',
                                                style: GoogleFonts.inter(fontSize: 13, color: kTextPrimary),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Delete',
                                                style: GoogleFonts.inter(fontSize: 13, color: Colors.red),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWalletFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? kPrimaryColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.white : kTextSecondary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : kTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMoneyDialog(BuildContext parentContext, VoidCallback onAdded) {
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: parentContext,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Add Money to Other Wallet',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
              fontSize: 18,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Amount (PKR)',
                    hintText: 'e.g. 5000',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixText: 'PKR ',
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Transaction Date',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kTextSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: parentContext,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        selectedDate = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          selectedDate.hour,
                          selectedDate.minute,
                        );
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18, color: kPrimaryColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            DateFormat('d MMM yyyy, hh:mm a').format(selectedDate),
                            style: GoogleFonts.inter(fontSize: 14, color: kTextPrimary),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: kTextSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: notesCtrl,
                  decoration: InputDecoration(
                    labelText: 'Notes / Description (Optional)',
                    hintText: 'e.g. Personal savings deposit',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: kTextSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(amountCtrl.text.trim()) ?? 0;
                if (amt <= 0) return;
                await _walletController.addMoney(
                  amt,
                  notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                  date: selectedDate,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                onAdded();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Add',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditWalletTransactionDialog(
    BuildContext parentContext,
    WalletTransactionModel txn,
    VoidCallback onUpdated,
  ) {
    final amountController = TextEditingController(
      text: txn.amount % 1 == 0 ? txn.amount.toInt().toString() : txn.amount.toString(),
    );
    final notesController = TextEditingController(text: txn.notes ?? '');
    String selectedType = txn.type;
    DateTime selectedDate = txn.date;

    showDialog(
      context: parentContext,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_note, color: kPrimaryColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Edit Transaction',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type selector
                    Text(
                      'Transaction Type',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setDialogState(() => selectedType = 'credit'),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selectedType == 'credit'
                                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selectedType == 'credit'
                                      ? const Color(0xFF10B981)
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_downward,
                                    size: 16,
                                    color: selectedType == 'credit'
                                        ? const Color(0xFF10B981)
                                        : kTextSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Deposit (+)',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: selectedType == 'credit'
                                          ? const Color(0xFF10B981)
                                          : kTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () => setDialogState(() => selectedType = 'debit'),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selectedType == 'debit'
                                    ? Colors.red.withValues(alpha: 0.15)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selectedType == 'debit'
                                      ? Colors.red
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_upward,
                                    size: 16,
                                    color: selectedType == 'debit'
                                        ? Colors.red
                                        : kTextSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Expense (-)',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: selectedType == 'debit'
                                          ? Colors.red
                                          : kTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Amount Input
                    Text(
                      'Amount (PKR)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: 'Enter amount',
                        prefixIcon: const Icon(Icons.payments_outlined, color: kPrimaryColor, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Date Picker Tile
                    Text(
                      'Date & Time',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              selectedDate.hour,
                              selectedDate.minute,
                            );
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18, color: kPrimaryColor),
                            const SizedBox(width: 10),
                            Text(
                              DateFormat('d MMM yyyy, hh:mm a').format(selectedDate),
                              style: GoogleFonts.inter(fontSize: 14, color: kTextPrimary),
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_drop_down, color: kTextSecondary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Notes Input
                    Text(
                      'Description / Notes',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Added personal cash',
                        prefixIcon: const Icon(Icons.notes_outlined, color: kPrimaryColor, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(color: kTextSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final amt = double.tryParse(amountController.text.trim());
                    if (amt == null || amt <= 0) {
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid amount'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    final updated = txn.copyWith(
                      amount: amt,
                      type: selectedType,
                      date: selectedDate,
                      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                    );
                    Navigator.pop(dialogCtx);
                    await _walletController.updateTransaction(updated);
                    onUpdated();
                    if (parentContext.mounted) {
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        const SnackBar(
                          content: Text('Transaction updated successfully!'),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteWalletTransactionDialog(
    BuildContext parentContext,
    WalletTransactionModel txn,
    VoidCallback onDeleted,
  ) {
    showDialog(
      context: parentContext,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'Delete Transaction',
              style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this ${txn.type == 'credit' ? 'deposit' : 'expense'} transaction of PKR ${txn.amount.toInt()}?',
          style: GoogleFonts.inter(fontSize: 14, color: kTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: GoogleFonts.inter(color: kTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await _walletController.deleteTransaction(txn.id);
              onDeleted();
              if (parentContext.mounted) {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(
                    content: Text('Transaction deleted'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Delete', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // --- Skeletons ---

  Widget _buildSkeletonLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _skeletonBox(width: 150, height: 20),
          const SizedBox(height: 8),
          _skeletonBox(width: 200, height: 32),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: _skeletonBox(height: 120)),
              const SizedBox(width: 16),
              Expanded(child: _skeletonBox(height: 120)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _skeletonBox(height: 120)),
              const SizedBox(width: 16),
              Expanded(child: _skeletonBox(height: 120)),
            ],
          ),
          const SizedBox(height: 32),
          _skeletonBox(width: double.infinity, height: 80),
          const SizedBox(height: 32),
          _skeletonBox(width: double.infinity, height: 200),
        ],
      ),
    );
  }

  Widget _skeletonBox({double? width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
    );
  }
}

// --- Animated Counter Widget ---
class AnimatedCounter extends StatefulWidget {
  final int targetValue;
  final TextStyle textStyle;
  final String prefix;

  const AnimatedCounter({
    super.key,
    required this.targetValue,
    required this.textStyle,
    this.prefix = '',
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = IntTween(
      begin: 0,
      end: widget.targetValue,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetValue != widget.targetValue) {
      _animation = IntTween(begin: _animation.value, end: widget.targetValue)
          .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          );
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          '${widget.prefix}${_animation.value}',
          style: widget.textStyle,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  _AnimatedBottomBar — custom bottom nav with sliding pill + bounce
// ─────────────────────────────────────────────────────────────────
class _AnimatedBottomBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _AnimatedBottomBar({required this.currentIndex, required this.onTap});

  @override
  State<_AnimatedBottomBar> createState() => _AnimatedBottomBarState();
}

class _AnimatedBottomBarState extends State<_AnimatedBottomBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pillController;
  late Animation<double> _pillPosition;
  int _previousIndex = 0;

  static const _items = [
    _NavItem(
      label: 'Dashboard',
      outlineIcon: Icons.dashboard_outlined,
      filledIcon: Icons.dashboard,
    ),
    _NavItem(
      label: 'Orders',
      outlineIcon: Icons.receipt_long_outlined,
      filledIcon: Icons.receipt_long,
    ),
    _NavItem(
      label: 'Customers',
      outlineIcon: Icons.people_outline,
      filledIcon: Icons.people,
    ),
    _NavItem(
      label: 'Expenses',
      outlineIcon: Icons.account_balance_wallet_outlined,
      filledIcon: Icons.account_balance_wallet,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _pillPosition =
        Tween<double>(
          begin: widget.currentIndex.toDouble(),
          end: widget.currentIndex.toDouble(),
        ).animate(
          CurvedAnimation(
            parent: _pillController,
            curve: Curves.easeInOutCubic,
          ),
        );
  }

  @override
  void didUpdateWidget(covariant _AnimatedBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _pillPosition =
          Tween<double>(
            begin: _previousIndex.toDouble(),
            end: widget.currentIndex.toDouble(),
          ).animate(
            CurvedAnimation(
              parent: _pillController,
              curve: Curves.easeInOutCubic,
            ),
          );
      _pillController.forward(from: 0);
      _previousIndex = widget.currentIndex;
    }
  }

  @override
  void dispose() {
    _pillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double tabWidth = MediaQuery.of(context).size.width / 4;
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: kCardColor,
        boxShadow: [
          BoxShadow(
            color: kTextPrimary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _pillPosition,
        builder: (context, _) {
          return Stack(
            children: [
              // ── Sliding green indicator pill at the top edge ──
              Positioned(
                top: 0,
                left: _pillPosition.value * tabWidth + tabWidth * 0.2,
                child: Container(
                  width: tabWidth * 0.6,
                  height: 3,
                  decoration: BoxDecoration(
                    color: kAccentColor,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(4),
                    ),
                  ),
                ),
              ),

              // ── Tab items ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_items.length, (index) {
                  return _BottomNavItem(
                    item: _items[index],
                    isActive: widget.currentIndex == index,
                    onTap: () => widget.onTap(index),
                    tabWidth: tabWidth,
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Individual animated nav item ──
class _BottomNavItem extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;
  final double tabWidth;

  const _BottomNavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
    required this.tabWidth,
  });

  @override
  State<_BottomNavItem> createState() => _BottomNavItemState();
}

class _BottomNavItemState extends State<_BottomNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 40),
          TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.88), weight: 30),
          TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.0), weight: 30),
        ]).animate(
          CurvedAnimation(parent: _bounceController, curve: Curves.easeOut),
        );
  }

  @override
  void didUpdateWidget(covariant _BottomNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _bounceController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: widget.tabWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bouncing icon with animated icon swap
            ScaleTransition(
              scale: _scaleAnim,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  widget.isActive
                      ? widget.item.filledIcon
                      : widget.item.outlineIcon,
                  key: ValueKey(widget.isActive),
                  color: widget.isActive ? kAccentColor : kTextSecondary,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Smooth label colour + weight transition
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: widget.isActive
                    ? FontWeight.w600
                    : FontWeight.normal,
                color: widget.isActive ? kAccentColor : kTextSecondary,
              ),
              child: Text(widget.item.label),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple data holder for nav items
class _NavItem {
  final String label;
  final IconData outlineIcon;
  final IconData filledIcon;
  const _NavItem({
    required this.label,
    required this.outlineIcon,
    required this.filledIcon,
  });
}

// ---------------------------------------------------------------------------
// Firebase Sync Status Badge
// ---------------------------------------------------------------------------
class _SyncBadge extends StatelessWidget {
  final SyncStatus status;
  const _SyncBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, IconData icon, String label) = switch (status) {
      SyncStatus.synced => (
        const Color(0xFFDCFCE7),
        const Color(0xFF16A34A),
        Icons.cloud_done_outlined,
        'Synced',
      ),
      SyncStatus.syncing => (
        const Color(0xFFEFF6FF),
        const Color(0xFF2563EB),
        Icons.cloud_sync_outlined,
        'Syncing…',
      ),
      SyncStatus.pending => (
        const Color(0xFFFEF9C3),
        const Color(0xFFCA8A04),
        Icons.cloud_upload_outlined,
        'Pending',
      ),
      SyncStatus.error => (
        const Color(0xFFFEE2E2),
        const Color(0xFFDC2626),
        Icons.cloud_off_outlined,
        'Failed',
      ),
    };

    final bool isSyncing = status == SyncStatus.syncing;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          isSyncing
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(fg),
                  ),
                )
              : Icon(icon, color: fg, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
