import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/customer_model.dart';
import '../models/order_model.dart';
import '../controllers/order_controller.dart';

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
//  CustomersScreen (Main Tab)
// ─────────────────────────────────────────────────────────────────
class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final OrderController _controller = OrderController();

  List<CustomerModel> get _filteredCustomers {
    final query = _searchQuery.toLowerCase();
    if (query.isEmpty) return _controller.customers;
    return _controller.customers.where((c) {
      return c.name.toLowerCase().contains(query) ||
          c.phone.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToProfile(CustomerModel customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => CustomerProfileScreen(
              customer: customer,
              controller: _controller,
            ),
      ),
    ).then((_) => _controller.loadData());
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final customers = _filteredCustomers;
        return Scaffold(
          backgroundColor: kBgColor,
          appBar: AppBar(
            backgroundColor: kCardColor,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            centerTitle: true,
            title: Text(
              'Customers',
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
          ),
          body: Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSearchBar(),
              ),
              const SizedBox(height: 16),
              Expanded(
                child:
                    _controller.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : customers.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          physics: const BouncingScrollPhysics(),
                          itemCount: customers.length,
                          itemBuilder:
                              (context, index) =>
                                  _buildCustomerCard(customers[index]),
                        ),
              ),
            ],
          ),
        );
      },
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
          hintText: 'Search customers...',
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

  Widget _buildCustomerCard(CustomerModel customer) {
    // Count this customer's orders
    final orderCount =
        _controller.orders
            .where((o) => o.customerId == customer.id)
            .length;
    final pendingDues =
        _controller.orders
            .where(
              (o) => o.customerId == customer.id && o.status != 'Delivered',
            )
            .fold<double>(0, (sum, o) => sum + (o.totalAmount - o.advancePaid));

    return Dismissible(
      key: Key(customer.id),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: kAccentColor,
          borderRadius: BorderRadius.circular(kRadius),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(kRadius),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          return await _showDeleteConfirmation(customer);
        } else if (direction == DismissDirection.startToEnd) {
          _showEditCustomerSheet(customer);
          return false;
        }
        return false;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _controller.deleteCustomer(customer.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Customer deleted', style: GoogleFonts.inter(color: Colors.white)),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(kRadius),
        boxShadow: [
          BoxShadow(
            color: kTextPrimary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(kRadius),
          onTap: () => _navigateToProfile(customer),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: kAccentColor.withValues(alpha: 0.15),
                  child: Text(
                    customer.initials,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kAccentColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          Text(
                            customer.name,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kTextPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: kPrimaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '#${customer.id.length > 6 ? customer.id.substring(0, 6).toUpperCase() : customer.id.toUpperCase()}',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: kPrimaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: kTextSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            customer.phone,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: kTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Stats
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$orderCount Orders',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: kTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    pendingDues > 0
                        ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Rs ${pendingDues.toStringAsFixed(0)} Due',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade700,
                            ),
                          ),
                        )
                        : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Cleared',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Future<bool> _showDeleteConfirmation(CustomerModel customer) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete Customer',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
          content: Text(
            'Are you sure you want to delete ${customer.name}? This will also delete all of their orders.',
            style: GoogleFonts.inter(color: kTextPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: kTextSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }

  void _showEditCustomerSheet(CustomerModel customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditCustomerSheet(
        customer: customer,
        onSave: (updatedCustomer) {
          _controller.updateCustomer(updatedCustomer);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_outlined, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No customers yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Customers are added when you create an order.',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Customer Profile Screen (Sub-screen)
// ─────────────────────────────────────────────────────────────────
class CustomerProfileScreen extends StatelessWidget {
  final CustomerModel customer;
  final OrderController controller;

  const CustomerProfileScreen({
    super.key,
    required this.customer,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final customerOrders =
        controller.orders
            .where((o) => o.customerId == customer.id)
            .toList();
    final pendingDues = customerOrders
        .where((o) => o.status != 'Delivered')
        .fold<double>(0, (sum, o) => sum + (o.totalAmount - o.advancePaid));
    final m = customer.measurements;

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Customer Profile',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (m != null) ...[
                    _buildSectionTitle('Saved Measurements'),
                    const SizedBox(height: 12),
                    _buildMeasurementsCard(m),
                    const SizedBox(height: 24),
                  ],
                  _buildSectionTitle('Payment Record'),
                  const SizedBox(height: 12),
                  _buildPaymentCard(context, pendingDues),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Order History'),
                  const SizedBox(height: 12),
                  _buildOrderHistory(customerOrders),
                  const SizedBox(height: 24),
                  if (m?.extraNotes?.isNotEmpty == true) ...[
                    _buildSectionTitle('Notes'),
                    const SizedBox(height: 12),
                    _buildNotesCard(m!.extraNotes!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 32, top: 16),
      decoration: const BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: kAccentColor,
            child: Text(
              customer.initials,
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            customer.name,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            customer.phone,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
          ),
          if (customer.address?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              customer.address!,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white60),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: kPrimaryColor,
      ),
    );
  }

  Widget _buildMeasurementsCard(dynamic m) {
    final rows = <MapEntry<String, String>>[];

    void addRow(String label, String? value, {String suffix = '"'}) {
      if (value != null && value.isNotEmpty) {
        rows.add(MapEntry(label, '$value$suffix'));
      }
    }

    addRow('Length', m.lengthMeasure);
    addRow('Arm', m.armMeasure, suffix: m.optMundo == true ? '" (Mundo)' : '"');
    addRow('Shoulder', m.shoulderMeasure);
    addRow('Collar', m.collarMeasure);
    addRow('Chest', m.chestMeasure);
    addRow('Waist', m.waistMeasure);
    addRow('Hip', m.hipMeasure);
    addRow('Shalwar', m.shalwarMeasure);
    addRow('Bottom', m.bottomMeasure);
    addRow('Plate', m.plateMeasure);
    if (m.cuffType?.isNotEmpty == true) rows.add(MapEntry('Cuff', m.cuffType));

    if (rows.isEmpty) {
      return _buildBaseCard(
        child: Text(
          'No measurements saved.',
          style: GoogleFonts.inter(color: kTextSecondary),
        ),
      );
    }

    return _buildBaseCard(
      child: Column(
        children: rows.asMap().entries.map((entry) {
          return Column(
            children: [
              _buildMeasurementRow(entry.value.key, entry.value.value),
              if (entry.key < rows.length - 1) const Divider(height: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMeasurementRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: kTextSecondary)),
        Text(
          value,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: kTextPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCard(BuildContext context, double pendingDues) {
    return _buildBaseCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pending Dues',
                style: GoogleFonts.inter(color: kTextSecondary, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Rs ${pendingDues.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: pendingDues > 0 ? Colors.red.shade600 : kAccentColor,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: pendingDues > 0
                ? () => _showRecordPaymentDialog(context, pendingDues)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: kAccentColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Record Payment',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderHistory(List<OrderModel> orders) {
    if (orders.isEmpty) {
      return _buildBaseCard(
        child: Text(
          'No orders yet.',
          style: GoogleFonts.inter(color: kTextSecondary),
        ),
      );
    }

    return _buildBaseCard(
      child: Column(
        children: orders.asMap().entries.map((entry) {
          final i = entry.key;
          final o = entry.value;
          final date = DateFormat('d MMM yyyy').format(o.orderDate);
          return Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: kBgColor,
                  child: const Icon(Icons.checkroom, color: kPrimaryColor),
                ),
                title: Text(
                  o.isAdult ? 'Adult Order' : 'Child Order',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${o.status} • $date',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
                trailing: Text(
                  'Rs ${o.totalAmount.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
              ),
              if (i < orders.length - 1) const Divider(),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotesCard(String notes) {
    return _buildBaseCard(
      child: Text(
        notes,
        style: GoogleFonts.inter(color: kTextSecondary, height: 1.5),
      ),
    );
  }

  Widget _buildBaseCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(kRadius),
        boxShadow: [
          BoxShadow(
            color: kTextPrimary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Future<void> _showRecordPaymentDialog(BuildContext context, double pendingDues) async {
    if (pendingDues <= 0) return;

    final TextEditingController amountCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Record Payment',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: kPrimaryColor),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pending Dues: Rs ${pendingDues.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(color: kTextSecondary),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount Paid',
                    prefixIcon: const Icon(Icons.currency_rupee),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter amount';
                    final num = double.tryParse(val);
                    if (num == null || num <= 0) return 'Invalid amount';
                    if (num > pendingDues) return 'Cannot exceed pending dues';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.inter(color: kTextSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final amount = double.parse(amountCtrl.text.trim());
                  Navigator.pop(context, amount);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccentColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Save', style: GoogleFonts.inter(color: Colors.white)),
            ),
          ],
        );
      },
    ).then((amount) async {
      if (amount != null && amount is double) {
        final pendingOrders = controller.orders
            .where((o) => o.customerId == customer.id && o.status != 'Delivered' && (o.totalAmount - o.advancePaid) > 0)
            .toList();
        pendingOrders.sort((a, b) => a.orderDate.compareTo(b.orderDate));

        double remainingPayment = amount;
        for (var o in pendingOrders) {
          if (remainingPayment <= 0) break;
          double balance = o.totalAmount - o.advancePaid;
          if (remainingPayment >= balance) {
            final updatedOrder = o.copyWith(advancePaid: o.advancePaid + balance);
            await controller.updateOrder(updatedOrder);
            remainingPayment -= balance;
          } else {
            final updatedOrder = o.copyWith(advancePaid: o.advancePaid + remainingPayment);
            await controller.updateOrder(updatedOrder);
            remainingPayment = 0;
          }
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment recorded successfully!', style: GoogleFonts.inter(color: Colors.white)),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    });
  }
}

class _EditCustomerSheet extends StatefulWidget {
  final CustomerModel customer;
  final ValueChanged<CustomerModel> onSave;

  const _EditCustomerSheet({
    required this.customer,
    required this.onSave,
  });

  @override
  State<_EditCustomerSheet> createState() => _EditCustomerSheetState();
}

class _EditCustomerSheetState extends State<_EditCustomerSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addrCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.customer.name);
    _phoneCtrl = TextEditingController(text: widget.customer.phone);
    _addrCtrl = TextEditingController(text: widget.customer.address ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addrCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
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
              'Edit Customer',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) => v!.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) => v!.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addrCtrl,
              decoration: InputDecoration(
                labelText: 'Address (Optional)',
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final updatedCustomer = CustomerModel(
                      id: widget.customer.id,
                      name: _nameCtrl.text.trim(),
                      phone: _phoneCtrl.text.trim(),
                      address: _addrCtrl.text.trim(),
                      measurements: widget.customer.measurements,
                    );
                    widget.onSave(updatedCustomer);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Customer updated successfully!',
                          style: GoogleFonts.inter(color: Colors.white),
                        ),
                        backgroundColor: kAccentColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Save Changes',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

