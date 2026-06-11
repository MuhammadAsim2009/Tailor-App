import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'orders_screen.dart';
import 'customers_screen.dart';

// --- Design System Constants ---
const Color kPrimaryColor = Color(0xFF1E3A5F); // Deep Navy
const Color kAccentColor = Color(0xFF10B981); // Emerald Green
const Color kBackgroundColor = Color(0xFFF8FAFC);
const Color kCardColor = Color(0xFFFFFFFF);
const Color kTextPrimary = Color(0xFF0F172A);
const Color kTextSecondary = Color(0xFF64748B);
const double kBorderRadius = 16.0;

// Dummy Models
class DummyOrder {
  final String customerName;
  final String orderType;
  final String deliveryDate;
  final String status;
  
  DummyOrder({required this.customerName, required this.orderType, required this.deliveryDate, required this.status});
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  int _bottomNavIndex = 0;
  String _activeStatusChip = 'Pending';
  bool _isLoading = true;

  final List<String> _statusFilters = ['Pending', 'In Progress', 'Ready', 'Delivered'];
  
  final List<DummyOrder> _allOrders = [
    DummyOrder(customerName: 'Ahmed Ali', orderType: '3-Piece Suit', deliveryDate: '12 Jun 2026', status: 'Pending'),
    DummyOrder(customerName: 'Sara Khan', orderType: 'Kurta Shalwar', deliveryDate: '14 Jun 2026', status: 'In Progress'),
    DummyOrder(customerName: 'Usman Tariq', orderType: 'Formal Pant', deliveryDate: '10 Jun 2026', status: 'Ready'),
    DummyOrder(customerName: 'Aisha Bibi', orderType: 'Wedding Dress', deliveryDate: '08 Jun 2026', status: 'Delivered'),
    DummyOrder(customerName: 'Bilal Malik', orderType: '2-Piece Suit', deliveryDate: '15 Jun 2026', status: 'Pending'),
  ];

  @override
  void initState() {
    super.initState();
    // Simulate loading data
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  List<DummyOrder> get _filteredOrders {
    return _allOrders.where((order) => order.status == _activeStatusChip).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: _isLoading
          ? SafeArea(child: _buildSkeletonLoading())
          : _bottomNavIndex == 1
              ? const OrdersScreen()
              : _bottomNavIndex == 2
                  ? const CustomersScreen()
                  : SafeArea(child: _buildContent()),
      bottomNavigationBar: _AnimatedBottomBar(
        currentIndex: _bottomNavIndex,
        onTap: (index) => setState(() => _bottomNavIndex = index),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  // --- Main Content Structure ---

  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          _buildKPIGrid(),
          const SizedBox(height: 32),
          _buildQuickActions(),
          const SizedBox(height: 32),
          _buildOrderStatusFilter(),
          const SizedBox(height: 16),
          _buildRecentOrders(),
        ],
      ),
    );
  }

  // --- Subcomponents ---

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good Morning,',
              style: GoogleFonts.inter(fontSize: 14, color: kTextSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Irfan Tailors',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('EEEE, d MMM').format(DateTime.now()),
              style: GoogleFonts.inter(fontSize: 14, color: kTextSecondary),
            ),
          ],
        ),
        Container(
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
            icon: const Icon(Icons.notifications_none_outlined, color: kPrimaryColor),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildKPIGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      children: [
        _buildKPICard(
          title: 'Total Orders',
          value: 124,
          icon: Icons.list_alt_outlined,
          bgColor: kPrimaryColor,
          textColor: Colors.white,
        ),
        _buildKPICard(
          title: 'Pending',
          value: 12,
          icon: Icons.pending_actions_outlined,
          bgColor: kCardColor,
          textColor: kTextPrimary,
          iconColor: Colors.orange,
        ),
        _buildKPICard(
          title: 'Completed',
          value: 89,
          icon: Icons.check_circle_outline,
          bgColor: kCardColor,
          textColor: kTextPrimary,
          iconColor: kAccentColor,
        ),
        _buildKPICard(
          title: 'Revenue',
          value: 4500, // Prefix handled inside
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
  }) {
    return Container(
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
            children: [
              Icon(icon, color: iconColor ?? textColor, size: 24),
            ],
          ),
          const Spacer(),
          AnimatedCounter(
            targetValue: value,
            textStyle: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            prefix: isCurrency ? '\$' : '',
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
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryColor),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionItem(icon: Icons.add_circle_outline, label: 'New Order'),
            _buildActionItem(icon: Icons.people_outline, label: 'Customers'),
            _buildActionItem(icon: Icons.bar_chart_outlined, label: 'Reports'),
            _buildActionItem(icon: Icons.straighten_outlined, label: 'Measurements'),
          ],
        ),
      ],
    );
  }

  Widget _buildActionItem({required IconData icon, required String label}) {
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
              onTap: () {},
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentOrders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Orders',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryColor),
        ),
        const SizedBox(height: 16),
        if (_filteredOrders.isEmpty)
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
          ..._filteredOrders.map((order) {
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  order.customerName,
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: kTextPrimary),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      order.orderType,
                      style: GoogleFonts.inter(color: kTextSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: kTextSecondary),
                        const SizedBox(width: 4),
                        Text(
                          order.deliveryDate,
                          style: GoogleFonts.inter(color: kTextSecondary, fontSize: 12),
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

  // Bottom nav replaced by _AnimatedBottomBar widget below

  Widget _buildFAB() {
    return AnimatedScale(
      scale: _isLoading ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: FloatingActionButton(
        onPressed: () {},
        backgroundColor: kAccentColor,
        child: const Icon(Icons.add, color: Colors.white),
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

class _AnimatedCounterState extends State<AnimatedCounter> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = IntTween(begin: 0, end: widget.targetValue).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetValue != widget.targetValue) {
      _animation = IntTween(begin: _animation.value, end: widget.targetValue).animate(
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

  const _AnimatedBottomBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<_AnimatedBottomBar> createState() => _AnimatedBottomBarState();
}

class _AnimatedBottomBarState extends State<_AnimatedBottomBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pillController;
  late Animation<double> _pillPosition;
  int _previousIndex = 0;

  static const _items = [
    _NavItem(label: 'Dashboard', outlineIcon: Icons.dashboard_outlined,    filledIcon: Icons.dashboard),
    _NavItem(label: 'Orders',    outlineIcon: Icons.receipt_long_outlined,  filledIcon: Icons.receipt_long),
    _NavItem(label: 'Customers', outlineIcon: Icons.people_outline,         filledIcon: Icons.people),
    _NavItem(label: 'Profile',   outlineIcon: Icons.person_outline,         filledIcon: Icons.person),
  ];

  @override
  void initState() {
    super.initState();
    _pillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _pillPosition = Tween<double>(
      begin: widget.currentIndex.toDouble(),
      end: widget.currentIndex.toDouble(),
    ).animate(CurvedAnimation(parent: _pillController, curve: Curves.easeInOutCubic));
  }

  @override
  void didUpdateWidget(covariant _AnimatedBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _pillPosition = Tween<double>(
        begin: _previousIndex.toDouble(),
        end: widget.currentIndex.toDouble(),
      ).animate(CurvedAnimation(parent: _pillController, curve: Curves.easeInOutCubic));
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
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
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
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3),  weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.88), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _bounceController, curve: Curves.easeOut));
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
                  widget.isActive ? widget.item.filledIcon : widget.item.outlineIcon,
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
                fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.normal,
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

