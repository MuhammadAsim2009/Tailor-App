import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'edit_order_screen.dart';

// --- Design System Constants ---
const Color kPrimary = Color(0xFF1E3A5F); // Deep Navy
const Color kAccent = Color(0xFF10B981); // Emerald Green
const Color kBg = Color(0xFFF8FAFC);
const Color kCard = Color(0xFFFFFFFF);
const Color kTextPri = Color(0xFF0F172A);
const Color kTextSec = Color(0xFF64748B);
const double kR = 16.0;

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> with TickerProviderStateMixin {
  // Dummy State Data
  String _status = 'In Progress'; // Pending, In Progress, Ready, Delivered
  final double _totalAmount = 5000.0;
  double _advancePaid = 2000.0;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  double get _remainingAmount => _totalAmount - _advancePaid;
  bool get _isFullyPaid => _remainingAmount <= 0;

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'In Progress':
        return Colors.blue;
      case 'Ready':
        return Colors.purple;
      case 'Delivered':
        return kAccent;
      default:
        return kTextSec;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined, color: kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Order Details',
          style: GoogleFonts.inter(
            color: kPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: kPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditOrderScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),
            _buildFinancialCard(),
            const SizedBox(height: 16),
            _buildOrderInfoCard(),
            const SizedBox(height: 16),
            _buildMeasurementsCard(),
            const SizedBox(height: 16),
            _buildTimelineCard(),
            const SizedBox(height: 24),
            _buildBottomActions(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // 1. HEADER CARD
  Widget _buildHeaderCard() {
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
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: kAccent.withValues(alpha: 0.1),
                child: Text(
                  'AA',
                  style: GoogleFonts.inter(
                    color: kAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ahmed Ali',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kTextPri,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+92 300 1234567',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: kTextSec,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#ORD-001',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kTextSec,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: kPrimary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '3-Piece Suit',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(_status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _getStatusColor(_status)),
                    ),
                    child: Text(
                      _status,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _getStatusColor(_status),
                        fontWeight: FontWeight.bold,
                      ),
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

  // 2. FINANCIAL SUMMARY CARD
  Widget _buildFinancialCard() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Summary',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildAmountRow('Total Amount:', _totalAmount, Colors.white),
          const SizedBox(height: 12),
          _buildAmountRow('Advance Paid:', _advancePaid, kAccent),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
          ),
          _buildAmountRow(
            'Remaining:',
            _remainingAmount,
            _isFullyPaid ? kAccent : Colors.redAccent,
          ),
          const SizedBox(height: 20),
          if (_isFullyPaid)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: kAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(kR),
                  border: Border.all(color: kAccent),
                ),
                child: Text(
                  'Fully Paid ✓',
                  style: GoogleFonts.inter(
                    color: kAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ScaleTransition(
              scale: _pulseAnimation,
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _advancePaid = _totalAmount;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kR),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Mark as Paid',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: amount),
          duration: const Duration(seconds: 1),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Text(
              'PKR ${value.toStringAsFixed(0)}',
              style: GoogleFonts.inter(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      ],
    );
  }

  // 3. ORDER INFO CARD
  Widget _buildOrderInfoCard() {
    return _buildSectionCard(
      title: 'Order Info',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(Icons.calendar_today_outlined, 'Order Date', '01 Jun 2026'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.local_shipping_outlined, 'Delivery Date', '12 Jun 2026'),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.bolt_outlined, size: 20, color: kTextSec),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Priority', style: GoogleFonts.inter(fontSize: 14, color: kTextSec)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'High',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.checkroom_outlined, 'Garment Type', '3-Piece Suit'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.format_list_numbered_outlined, 'Quantity', '2'),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _buildFullWidthNote(Icons.texture_outlined, 'Fabric Notes', 'Navy Blue Worsted Wool, imported. Client provided fabric 4 meters.'),
          const SizedBox(height: 12),
          _buildFullWidthNote(Icons.notes_outlined, 'Special Notes', 'Tight fit on the waist, wide leg pants as per reference image.'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: kTextSec),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: GoogleFonts.inter(fontSize: 14, color: kTextSec)),
        ),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 14, color: kTextPri, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildFullWidthNote(IconData icon, String label, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: kPrimary),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 14, color: kPrimary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          text,
          style: GoogleFonts.inter(fontSize: 14, color: kTextPri, height: 1.5),
        ),
      ],
    );
  }

  // 4. MEASUREMENTS CARD
  Widget _buildMeasurementsCard() {
    final Map<String, String> measurements = {
      'Length': '40',
      'Arm': '24',
      'Shoulders': '18',
      'Collar': '15.5',
      'Half Sherwani': 'N/A',
      'Chest': '42',
      'Waist': '34',
      'Hip': '40',
      'Shalwar': '38',
      'Bottom': '14',
    };

    final List<String> additionalOptions = ['Plate', 'Front Pocket', 'Cuff'];

    return _buildSectionCard(
      title: 'Measurements',
      trailing: Text('inches', style: GoogleFonts.inter(color: kTextSec, fontSize: 12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: measurements.length,
            itemBuilder: (context, index) {
              final key = measurements.keys.elementAt(index);
              final val = measurements[key];
              return Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(key, style: GoogleFonts.inter(fontSize: 13, color: kTextSec)),
                    Text(val!, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: kTextPri)),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Additional Options',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: kPrimary),
          ),
          const SizedBox(height: 12),
          additionalOptions.isNotEmpty
              ? Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: additionalOptions.map((opt) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: kAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kAccent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check, size: 14, color: kAccent),
                          const SizedBox(width: 4),
                          Text(opt, style: GoogleFonts.inter(fontSize: 12, color: kAccent, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  }).toList(),
                )
              : Text('None', style: GoogleFonts.inter(color: kTextSec)),
        ],
      ),
    );
  }

  // 5. TIMELINE CARD
  Widget _buildTimelineCard() {
    final timelineSteps = [
      {'title': 'Order Placed', 'date': '01 Jun 2026, 10:30 AM', 'done': true},
      {'title': 'In Progress', 'date': '02 Jun 2026, 09:15 AM', 'done': true},
      {'title': 'Ready for Pickup', 'date': 'Pending', 'done': false},
      {'title': 'Delivered', 'date': 'Pending', 'done': false},
    ];

    return _buildSectionCard(
      title: 'Order Timeline',
      child: Column(
        children: List.generate(timelineSteps.length, (index) {
          final step = timelineSteps[index];
          final isLast = index == timelineSteps.length - 1;
          final isDone = step['done'] as bool;

          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: Duration(milliseconds: 400 + (index * 200)),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 10 * (1 - value)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDone ? kAccent : kBg,
                              border: Border.all(
                                color: isDone ? kAccent : kTextSec,
                                width: 2,
                              ),
                            ),
                            child: isDone
                                ? const Icon(Icons.check, size: 14, color: Colors.white)
                                : null,
                          ),
                          if (!isLast)
                            Container(
                              width: 2,
                              height: 40,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: isDone ? kAccent : Colors.grey.shade300,
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step['title'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                                color: isDone ? kTextPri : kTextSec,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              step['date'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: kTextSec,
                              ),
                            ),
                            if (!isLast) const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  // 6. BOTTOM ACTIONS
  Widget _buildBottomActions() {
    final bool isDelivered = _status == 'Delivered';

    if (isDelivered) {
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.download_outlined),
          label: Text('Download Receipt', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
          style: OutlinedButton.styleFrom(
            foregroundColor: kPrimary,
            side: const BorderSide(color: kPrimary, width: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kR)),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 54,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditOrderScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: kPrimary,
                side: const BorderSide(color: kPrimary, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kR)),
              ),
              child: Text('Edit Order', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _status = 'Delivered';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kR)),
                elevation: 0,
              ),
              child: Text('Mark Delivered', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  // HELPER FOR SECTION CARDS
  Widget _buildSectionCard({required String title, Widget? trailing, required Widget child}) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kPrimary,
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
