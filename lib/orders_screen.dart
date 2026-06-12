import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'order_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────
//  Design System Constants (shared with rest of app)
// ─────────────────────────────────────────────────────────────────
const Color kPrimaryColor = Color(0xFF1E3A5F);
const Color kAccentColor = Color(0xFF10B981);
const Color kBgColor = Color(0xFFF8FAFC);
const Color kCardColor = Color(0xFFFFFFFF);
const Color kTextPrimary = Color(0xFF0F172A);
const Color kTextSecondary = Color(0xFF64748B);
const double kRadius = 16.0;

// ─────────────────────────────────────────────────────────────────
//  Order Model (dummy data)
// ─────────────────────────────────────────────────────────────────
class OrderModel {
  final String id;
  final String customerName;
  final String dressType;
  final String deliveryDate;
  final double amount;
  String status; // mutable so swipe-right can update it

  OrderModel({
    required this.id,
    required this.customerName,
    required this.dressType,
    required this.deliveryDate,
    required this.amount,
    required this.status,
  });
}

// ─────────────────────────────────────────────────────────────────
//  OrdersScreen
// ─────────────────────────────────────────────────────────────────
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  // Active filter chip
  String _activeFilter = 'All';

  // Search query
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  // Dummy dataset
  final List<OrderModel> _allOrders = [
    OrderModel(
      id: '#ORD-001',
      customerName: 'Ahmed Ali',
      dressType: '3-Piece Suit',
      deliveryDate: '12 Jun 2026',
      amount: 8500,
      status: 'Pending',
    ),
    OrderModel(
      id: '#ORD-002',
      customerName: 'Sara Khan',
      dressType: 'Kurta Shalwar',
      deliveryDate: '14 Jun 2026',
      amount: 3200,
      status: 'In Progress',
    ),
    OrderModel(
      id: '#ORD-003',
      customerName: 'Usman Tariq',
      dressType: 'Formal Pant',
      deliveryDate: '10 Jun 2026',
      amount: 1800,
      status: 'Ready',
    ),
    OrderModel(
      id: '#ORD-004',
      customerName: 'Aisha Bibi',
      dressType: 'Wedding Dress',
      deliveryDate: '08 Jun 2026',
      amount: 15000,
      status: 'Delivered',
    ),
    OrderModel(
      id: '#ORD-005',
      customerName: 'Bilal Malik',
      dressType: '2-Piece Suit',
      deliveryDate: '15 Jun 2026',
      amount: 6500,
      status: 'Pending',
    ),
    OrderModel(
      id: '#ORD-006',
      customerName: 'Nadia Iqbal',
      dressType: 'Shirt',
      deliveryDate: '16 Jun 2026',
      amount: 1200,
      status: 'In Progress',
    ),
    OrderModel(
      id: '#ORD-007',
      customerName: 'Tariq Mehmood',
      dressType: 'Waistcoat',
      deliveryDate: '18 Jun 2026',
      amount: 2500,
      status: 'Ready',
    ),
    OrderModel(
      id: '#ORD-008',
      customerName: 'Hina Baig',
      dressType: 'Lace Frock',
      deliveryDate: '20 Jun 2026',
      amount: 9000,
      status: 'Pending',
    ),
    OrderModel(
      id: '#ORD-009',
      customerName: 'Kamran Shah',
      dressType: 'Shalwar Kameez',
      deliveryDate: '22 Jun 2026',
      amount: 2800,
      status: 'Delivered',
    ),
    OrderModel(
      id: '#ORD-010',
      customerName: 'Saba Riaz',
      dressType: 'Bridal Suit',
      deliveryDate: '25 Jun 2026',
      amount: 22000,
      status: 'In Progress',
    ),
  ];

  // Filter chips definition
  final List<String> _filters = [
    'All',
    'Pending',
    'In Progress',
    'Ready',
    'Delivered',
  ];

  /// Returns orders filtered by chip + search query
  List<OrderModel> get _filteredOrders {
    return _allOrders.where((o) {
      final matchesFilter = _activeFilter == 'All' || o.status == _activeFilter;
      final query = _searchQuery.toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          o.customerName.toLowerCase().contains(query) ||
          o.dressType.toLowerCase().contains(query) ||
          o.id.toLowerCase().contains(query);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Mark an order as Delivered (swipe-right action) ──
  void _markDelivered(OrderModel order) {
    setState(() => order.status = 'Delivered');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${order.customerName}\'s order marked as Delivered'),
        backgroundColor: kAccentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Show edit bottom sheet (swipe-left action) ──
  void _showEditSheet(OrderModel order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kCardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditOrderSheet(
        order: order,
        onSave: (newStatus) {
          setState(() => order.status = newStatus);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = _filteredOrders;

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSearchBar(),
          ),
          const SizedBox(height: 16),
          // Horizontal filter chips
          _buildFilterChips(),
          const SizedBox(height: 16),
          // Orders list
          Expanded(
            child: orders.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    physics: const BouncingScrollPhysics(),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      return _buildDismissibleCard(orders[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  AppBar
  // ─────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: kCardColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_outlined,
          color: kPrimaryColor,
          size: 20,
        ),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Text(
        'Orders',
        style: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: kPrimaryColor,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.tune_outlined, color: kPrimaryColor),
          onPressed: () {}, // filter / sort placeholder
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.grey.shade100),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  Search Bar
  // ─────────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(kRadius),
        boxShadow: [
          BoxShadow(
            color: kTextPrimary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: GoogleFonts.inter(fontSize: 14, color: kTextPrimary),
        decoration: InputDecoration(
          hintText: 'Search orders...',
          hintStyle: GoogleFonts.inter(color: kTextSecondary),
          prefixIcon: const Icon(Icons.search_outlined, color: kTextSecondary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_outlined,
                    color: kTextSecondary,
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kRadius),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  Filter Chips
  // ─────────────────────────────────────────────────────────────────
  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isActive = filter == _activeFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: ChoiceChip(
                label: Text(filter),
                selected: isActive,
                onSelected: (_) => setState(() => _activeFilter = filter),
                selectedColor: kAccentColor,
                backgroundColor: kCardColor,
                showCheckmark: false,
                labelStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive ? Colors.white : kTextSecondary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isActive ? kAccentColor : Colors.grey.shade300,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  Dismissible Order Card wrapper
  // ─────────────────────────────────────────────────────────────────
  Widget _buildDismissibleCard(OrderModel order) {
    return Dismissible(
      key: ValueKey('${order.id}_${order.status}'),
      // Swipe RIGHT → Mark Delivered (green background)
      background: _swipeBackground(
        alignment: Alignment.centerLeft,
        color: kAccentColor,
        icon: Icons.check_circle_outline,
        label: 'Delivered',
      ),
      // Swipe LEFT → Edit (navy background)
      secondaryBackground: _swipeBackground(
        alignment: Alignment.centerRight,
        color: kPrimaryColor,
        icon: Icons.edit_outlined,
        label: 'Edit',
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _markDelivered(order);
        } else {
          _showEditSheet(order);
        }
        return false; // Don't actually remove the card
      },
      child: _buildOrderCard(order),
    );
  }

  Widget _swipeBackground({
    required AlignmentGeometry alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(kRadius),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alignment == Alignment.centerLeft) ...[
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else ...[
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: Colors.white, size: 22),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  Order Card
  // ─────────────────────────────────────────────────────────────────
  Widget _buildOrderCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(kRadius),
        boxShadow: [
          BoxShadow(
            color: kTextPrimary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(kRadius),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderDetailScreen())),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Row 1: Order ID + Status badge ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.id,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: kTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    _StatusBadge(status: order.status),
                  ],
                ),
                const SizedBox(height: 10),
                // ── Row 2: Customer name + Amount ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.customerName,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: kTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.checkroom_outlined,
                              size: 14,
                              color: kTextSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              order.dressType,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: kTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      'Rs ${order.amount.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // ── Divider ──
                Container(height: 1, color: Colors.grey.shade100),
                const SizedBox(height: 10),
                // ── Row 3: Delivery date + swipe hint ──
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: kTextSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Delivery: ${order.deliveryDate}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: kTextSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '← swipe →',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  Empty state
  // ─────────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 72,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No orders found',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing the filter or search term.',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Reusable animated Status Badge
// ─────────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  static Map<String, List<Color>> get _palette => {
    'Pending': [Color(0xFFFFF7ED), Color(0xFFC2410C)],
    'In Progress': [Color(0xFFEFF6FF), Color(0xFF1D4ED8)],
    'Ready': [Color(0xFFECFDF5), kAccentColor],
    'Delivered': [Color(0xFFF1F5F9), kTextSecondary],
  };

  @override
  Widget build(BuildContext context) {
    final colors = _palette[status] ?? [Colors.grey.shade100, kTextSecondary];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors[0],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colors[1],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Edit Order Bottom Sheet
// ─────────────────────────────────────────────────────────────────
class _EditOrderSheet extends StatefulWidget {
  final OrderModel order;
  final ValueChanged<String> onSave;

  const _EditOrderSheet({required this.order, required this.onSave});

  @override
  State<_EditOrderSheet> createState() => _EditOrderSheetState();
}

class _EditOrderSheetState extends State<_EditOrderSheet> {
  final List<String> _statuses = [
    'Pending',
    'In Progress',
    'Ready',
    'Delivered',
  ];
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.order.status;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Edit Order',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.order.customerName,
            style: GoogleFonts.inter(fontSize: 14, color: kTextSecondary),
          ),
          const SizedBox(height: 24),
          Text(
            'Update Status',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // Status selection chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _statuses.map((s) {
              final isSelected = s == _selectedStatus;
              return ChoiceChip(
                label: Text(s),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedStatus = s),
                selectedColor: kAccentColor,
                backgroundColor: kBgColor,
                showCheckmark: false,
                labelStyle: GoogleFonts.inter(
                  color: isSelected ? Colors.white : kTextSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? kAccentColor : Colors.grey.shade300,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          // Save button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kRadius),
                ),
                elevation: 0,
              ),
              onPressed: () {
                widget.onSave(_selectedStatus);
                Navigator.pop(context);
              },
              child: Text(
                'Save Changes',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
