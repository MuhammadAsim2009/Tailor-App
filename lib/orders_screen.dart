import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/order_model.dart';
import '../controllers/order_controller.dart';
import 'order_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────
//  Design System Constants
// ─────────────────────────────────────────────────────────────────
const Color kPrimaryColor = Color(0xFF1E3A5F);
const Color kAccentColor = Color(0xFF10B981);
const Color kBgColor = Color(0xFFF8FAFC);
const Color kCardColor = Color(0xFFFFFFFF);
const Color kTextPrimary = Color(0xFF0F172A);
const Color kTextSecondary = Color(0xFF64748B);
const double kRadius = 16.0;

// ─────────────────────────────────────────────────────────────────
//  OrdersScreen
// ─────────────────────────────────────────────────────────────────
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _activeFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final OrderController _controller = OrderController();

  final List<String> _filters = [
    'All',
    'Pending',
    'In Progress',
    'Ready',
    'Delivered',
  ];

  List<OrderModel> get _filteredOrders {
    return _controller.orders.where((o) {
      final matchesFilter =
          _activeFilter == 'All' || o.status == _activeFilter;
      final query = _searchQuery.toLowerCase();
      final customerName = _controller.getCustomerName(o.customerId);
      final matchesSearch =
          query.isEmpty ||
          customerName.toLowerCase().contains(query) ||
          o.id.toLowerCase().contains(query) ||
          o.status.toLowerCase().contains(query);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _markDelivered(OrderModel order) async {
    await _controller.updateOrderStatus(order.id, 'Delivered');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_controller.getCustomerName(order.customerId)}\'s order marked as Delivered',
        ),
        backgroundColor: kAccentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showEditSheet(OrderModel order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kCardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (_) => _EditOrderSheet(
            order: order,
            customerName: _controller.getCustomerName(order.customerId),
            onSave: (newStatus) async {
              await _controller.updateOrderStatus(order.id, newStatus);
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final orders = _filteredOrders;
        return Scaffold(
          backgroundColor: kBgColor,
          appBar: _buildAppBar(),
          body: Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSearchBar(),
              ),
              const SizedBox(height: 16),
              _buildFilterChips(),
              const SizedBox(height: 16),
              Expanded(
                child:
                    _controller.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : orders.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          physics: const BouncingScrollPhysics(),
                          itemCount: orders.length,
                          itemBuilder:
                              (context, index) =>
                                  _buildDismissibleCard(orders[index]),
                        ),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: kCardColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      centerTitle: true,
      title: Text(
        'Orders',
        style: GoogleFonts.inter(
          color: kPrimaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_outlined, color: kPrimaryColor),
          onPressed: () => _controller.loadData(),
        ),
      ],
    );
  }

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
          suffixIcon:
              _searchQuery.isNotEmpty
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

  Widget _buildDismissibleCard(OrderModel order) {
    return Dismissible(
      key: ValueKey('${order.id}_${order.status}'),
      background: _swipeBackground(
        alignment: Alignment.centerLeft,
        color: kAccentColor,
        icon: Icons.check_circle_outline,
        label: 'Delivered',
      ),
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
        return false;
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
        children:
            alignment == Alignment.centerLeft
                ? [
                  Icon(icon, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ]
                : [
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
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final customerName = _controller.getCustomerName(order.customerId);
    final deliveryFormatted = DateFormat(
      'd MMM yyyy',
    ).format(order.deliveryDate);

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
          onTap: () {
            final customer = _controller.getCustomerById(order.customerId);
            if (customer != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderDetailScreen(
                    order: order,
                    customer: customer,
                  ),
                ),
              ).then((_) => _controller.loadData());
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: short ID + status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#${order.id.length > 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase()}',
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
                // Row 2: customer name + amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
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
                              Icons.people_outline,
                              size: 14,
                              color: kTextSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              order.isAdult ? 'Adult' : 'Child',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: kTextSecondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.shopping_bag_outlined,
                              size: 14,
                              color: kTextSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Qty: ${order.quantity}',
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
                      'Rs ${order.totalAmount.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(height: 1, color: Colors.grey.shade100),
                const SizedBox(height: 10),
                // Row 3: delivery date + swipe hint
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: kTextSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Delivery: $deliveryFormatted',
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
            'No orders yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first order.',
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
    'Pending': [const Color(0xFFFFF7ED), const Color(0xFFC2410C)],
    'In Progress': [const Color(0xFFEFF6FF), const Color(0xFF1D4ED8)],
    'Ready': [const Color(0xFFECFDF5), kAccentColor],
    'Delivered': [const Color(0xFFF1F5F9), kTextSecondary],
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
  final String customerName;
  final ValueChanged<String> onSave;

  const _EditOrderSheet({
    required this.order,
    required this.customerName,
    required this.onSave,
  });

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
            'Update Status',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.customerName,
            style: GoogleFonts.inter(fontSize: 14, color: kTextSecondary),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _statuses.map((s) {
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
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color:
                            isSelected ? kAccentColor : Colors.grey.shade300,
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 28),
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
