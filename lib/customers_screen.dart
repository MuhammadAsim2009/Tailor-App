import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────
//  Design System Constants
// ─────────────────────────────────────────────────────────────────
const Color kPrimaryColor   = Color(0xFF1E3A5F);
const Color kAccentColor    = Color(0xFF10B981);
const Color kBgColor        = Color(0xFFF8FAFC);
const Color kCardColor      = Color(0xFFFFFFFF);
const Color kTextPrimary    = Color(0xFF0F172A);
const Color kTextSecondary  = Color(0xFF64748B);
const double kRadius        = 16.0;

// ─────────────────────────────────────────────────────────────────
//  Customer Model (dummy data)
// ─────────────────────────────────────────────────────────────────
class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final int totalOrders;
  final double pendingDues;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.totalOrders,
    required this.pendingDues,
  });

  String get initials {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }
}

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

  final List<CustomerModel> _allCustomers = [
    CustomerModel(id: '101', name: 'Ahmed Ali',    phone: '+92 300 1234567', totalOrders: 12, pendingDues: 0),
    CustomerModel(id: '102', name: 'Sara Khan',    phone: '+92 321 7654321', totalOrders: 4,  pendingDues: 1500),
    CustomerModel(id: '103', name: 'Usman Tariq',  phone: '+92 333 1122334', totalOrders: 8,  pendingDues: 0),
    CustomerModel(id: '104', name: 'Aisha Bibi',   phone: '+92 345 9988776', totalOrders: 2,  pendingDues: 5000),
    CustomerModel(id: '105', name: 'Bilal Malik',  phone: '+92 301 5566778', totalOrders: 15, pendingDues: 2500),
    CustomerModel(id: '106', name: 'Nadia Iqbal',  phone: '+92 302 4433221', totalOrders: 1,  pendingDues: 0),
    CustomerModel(id: '107', name: 'Kamran Shah',  phone: '+92 313 7788990', totalOrders: 20, pendingDues: 8000),
  ];

  List<CustomerModel> get _filteredCustomers {
    final query = _searchQuery.toLowerCase();
    if (query.isEmpty) return _allCustomers;
    return _allCustomers.where((c) {
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
      MaterialPageRoute(builder: (_) => CustomerProfileScreen(customer: customer)),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            icon: const Icon(Icons.filter_list_outlined, color: kPrimaryColor),
            onPressed: () {},
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
            child: customers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    physics: const BouncingScrollPhysics(),
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return _buildCustomerCard(customer);
                    },
                  ),
          ),
        ],
      ),
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
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_outlined, color: kTextSecondary, size: 20),
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
    return Container(
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
                // Avatar
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
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            customer.name,
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: kTextPrimary),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: kPrimaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '#${customer.id}',
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: kPrimaryColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 14, color: kTextSecondary),
                          const SizedBox(width: 4),
                          Text(
                            customer.phone,
                            style: GoogleFonts.inter(fontSize: 13, color: kTextSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Stats (Orders & Dues)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${customer.totalOrders} Orders',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: kTextSecondary),
                    ),
                    const SizedBox(height: 6),
                    if (customer.pendingDues > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Rs ${customer.pendingDues.toStringAsFixed(0)} Due',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.red.shade700),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Cleared',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green.shade700),
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
          Icon(Icons.person_search_outlined, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No customers found',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: kTextSecondary),
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

  const CustomerProfileScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Customer Profile',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
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
                  _buildSectionTitle('Saved Measurements'),
                  const SizedBox(height: 12),
                  _buildMeasurementsCard(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Payment Record'),
                  const SizedBox(height: 12),
                  _buildPaymentCard(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Order History'),
                  const SizedBox(height: 12),
                  _buildOrderHistory(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Notes'),
                  const SizedBox(height: 12),
                  _buildNotesCard(),
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
              style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                customer.name,
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '#${customer.id}',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            customer.phone,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryColor),
    );
  }

  Widget _buildMeasurementsCard() {
    return _buildBaseCard(
      child: Column(
        children: [
          _buildMeasurementRow('Length', '40"'),
          const Divider(height: 16),
          _buildMeasurementRow('Arm', '24" (Mundo)'),
          const Divider(height: 16),
          _buildMeasurementRow('Shoulder', '18"'),
          const Divider(height: 16),
          _buildMeasurementRow('Collar', '15" (Regular)'),
          const Divider(height: 16),
          _buildMeasurementRow('Chest', '42"'),
          const Divider(height: 16),
          _buildMeasurementRow('Waist', '34"'),
          const Divider(height: 16),
          _buildMeasurementRow('Hip', '40"'),
          const Divider(height: 16),
          _buildMeasurementRow('Shalwar', '38" (Width)'),
          const Divider(height: 16),
          _buildMeasurementRow('Bottom', '14"'),
          const Divider(height: 16),
          _buildMeasurementRow('Plate', 'Yes'),
          const Divider(height: 16),
          _buildMeasurementRow('Pockets', 'Front, Side'),
          const Divider(height: 16),
          _buildMeasurementRow('Cuff', 'Round'),
          const Divider(height: 16),
          _buildMeasurementRow('Extra', 'Tight fit on waist'),
        ],
      ),
    );
  }

  Widget _buildMeasurementRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: kTextSecondary)),
        Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: kTextPrimary)),
      ],
    );
  }

  Widget _buildPaymentCard() {
    return _buildBaseCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pending Dues', style: GoogleFonts.inter(color: kTextSecondary, fontSize: 13)),
              const SizedBox(height: 4),
              Text(
                'Rs ${customer.pendingDues.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: customer.pendingDues > 0 ? Colors.red.shade600 : kAccentColor,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: kAccentColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Record Payment', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderHistory() {
    return _buildBaseCard(
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(backgroundColor: kBgColor, child: Icon(Icons.checkroom, color: kPrimaryColor)),
            title: Text('3-Piece Suit', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            subtitle: Text('Delivered • 12 May 2026', style: GoogleFonts.inter(fontSize: 12)),
            trailing: Text('Rs 8500', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: kPrimaryColor)),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(backgroundColor: kBgColor, child: Icon(Icons.checkroom, color: kPrimaryColor)),
            title: Text('Kurta Shalwar', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            subtitle: Text('Pending • Due 14 Jun', style: GoogleFonts.inter(fontSize: 12)),
            trailing: Text('Rs 3200', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: kPrimaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return _buildBaseCard(
      child: Text(
        'Customer prefers slim fit trousers and extra deep pockets. Always double check shoulder measurements before cutting.',
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
}
