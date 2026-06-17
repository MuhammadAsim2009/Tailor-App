import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'edit_order_screen.dart';
import 'receipt_widget.dart';
import 'models/order_model.dart';
import 'models/customer_model.dart';
import 'controllers/order_controller.dart';

// --- Design System Constants ---
const Color kPrimary = Color(0xFF1E3A5F); // Deep Navy
const Color kAccent = Color(0xFF10B981); // Emerald Green
const Color kBg = Color(0xFFF8FAFC);
const Color kCard = Color(0xFFFFFFFF);
const Color kTextPri = Color(0xFF0F172A);
const Color kTextSec = Color(0xFF64748B);
const double kR = 16.0;

class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;
  final CustomerModel customer;

  const OrderDetailScreen({
    super.key,
    required this.order,
    required this.customer,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> with TickerProviderStateMixin {
  bool _isDownloading = false;
  final ScreenshotController _screenshotController = ScreenshotController();
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  late OrderModel _currentOrder;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
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

  double get _remainingAmount => _currentOrder.totalAmount - _currentOrder.advancePaid;
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

  Future<void> _downloadReceipt() async {
    setState(() => _isDownloading = true);
    
    try {
      // gal handles gallery permission natively
      final hasAccess = await Gal.requestAccess();
      if (!hasAccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Gallery permission denied. Please allow in Settings.'),
              backgroundColor: Colors.red.shade600,
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () => openAppSettings(),
              ),
            ),
          );
        }
        setState(() => _isDownloading = false);
        return;
      }

      // Capture receipt widget off-screen as PNG bytes
      final Uint8List bytes = await _screenshotController.captureFromWidget(
        Material(
          type: MaterialType.transparency,
          child: Directionality(
            textDirection: ui.TextDirection.ltr,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topCenter,
              child: ReceiptWidget(
                order: _currentOrder,
                customer: widget.customer,
              ),
            ),
          ),
        ),
        delay: const Duration(milliseconds: 200),
      );

      // Save to gallery using gal (returns void, throws on failure)
      await Gal.putImageBytes(
        bytes,
        name: "IrfanTailors_Receipt_${DateTime.now().millisecondsSinceEpoch}",
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Receipt saved to gallery! 📥', style: GoogleFonts.inter(color: Colors.white)),
              ],
            ),
            backgroundColor: kAccent,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save receipt: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
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
                MaterialPageRoute(
                  builder: (_) => EditOrderScreen(
                    order: _currentOrder,
                    customer: widget.customer,
                  ),
                ),
              ).then((updatedOrder) {
                if (updatedOrder != null && updatedOrder is OrderModel) {
                  setState(() {
                    _currentOrder = updatedOrder;
                  });
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _showDeleteConfirmation(),
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
            const SizedBox(height: 16),
            _buildDownloadReceiptButton(),
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
                  widget.customer.initials,
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
                      widget.customer.name,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kTextPri,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${widget.customer.id}',
                      style: GoogleFonts.inter(fontSize: 13, color: kAccent, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.customer.phone,
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
                '#${_currentOrder.id}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kTextSec,
                ),
              ),
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(_currentOrder.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _getStatusColor(_currentOrder.status)),
                    ),
                    child: Text(
                      _currentOrder.status,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _getStatusColor(_currentOrder.status),
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
          _buildAmountRow('Total Amount:', _currentOrder.totalAmount, Colors.white),
          const SizedBox(height: 12),
          _buildAmountRow('Advance Paid:', _currentOrder.advancePaid, kAccent),
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
                  onPressed: () async {
                    try {
                      await OrderController().markOrderAsPaid(_currentOrder.id, _currentOrder.totalAmount);
                      if (mounted) {
                        setState(() {
                          _currentOrder = _currentOrder.copyWith(advancePaid: _currentOrder.totalAmount);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Order marked as Paid!',
                              style: GoogleFonts.inter(color: Colors.white),
                            ),
                            backgroundColor: kAccent,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error updating order: $e')),
                        );
                      }
                    }
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
          _buildInfoRow(Icons.calendar_today_outlined, 'Order Date', DateFormat('dd MMM yyyy').format(_currentOrder.orderDate)),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.local_shipping_outlined, 'Delivery Date', DateFormat('dd MMM yyyy').format(_currentOrder.deliveryDate)),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.format_list_numbered_outlined, 'Quantity', _currentOrder.quantity.toString()),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _buildFullWidthNote(Icons.notes_outlined, 'Special Notes', _currentOrder.measurements.extraNotes?.isNotEmpty == true ? _currentOrder.measurements.extraNotes! : 'No notes.'),
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
    final Map<String, String> measurementLabels = {
      'lengthMeasure': 'Length',
      'armMeasure': 'Arm',
      'shoulderMeasure': 'Shoulder',
      'collarMeasure': 'Collar',
      'chestMeasure': 'Chest',
      'waistMeasure': 'Waist',
      'hipMeasure': 'Hip',
      'shalwarMeasure': 'Shalwar',
      'shalWidth': 'Shalwar Width',
      'bottomMeasure': 'Bottom',
      'plateMeasure': 'Plate',
      'frontPocketMeasure': 'Front Pocket',
      'cuffType': 'Cuff Type',
      'sherwaniType': 'Sherwani Type',
    };

    final Map<String, String> measurements = {};
    _currentOrder.measurements.toMap().forEach((key, value) {
      if (value != null && value.toString().isNotEmpty && value != false && value != 'false') {
        if (measurementLabels.containsKey(key)) {
          measurements[measurementLabels[key]!] = value.toString();
        }
      }
    });
    final List<String> designOptions = _currentOrder.measurements.designOptions;

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
            'Design Options',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: kPrimary),
          ),
          const SizedBox(height: 12),
          designOptions.isNotEmpty
              ? Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: designOptions.map((opt) {
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
      {'title': 'Order Placed', 'date': DateFormat('dd MMM yyyy').format(_currentOrder.orderDate), 'done': true},
      {'title': 'In Progress', 'date': _currentOrder.status == 'In Progress' || _currentOrder.status == 'Ready' || _currentOrder.status == 'Delivered' ? DateFormat('dd MMM yyyy').format(_currentOrder.orderDate) : 'Pending', 'done': _currentOrder.status != 'Pending'},
      {'title': 'Ready for Pickup', 'date': _currentOrder.status == 'Ready' || _currentOrder.status == 'Delivered' ? 'Done' : 'Pending', 'done': _currentOrder.status == 'Ready' || _currentOrder.status == 'Delivered'},
      {'title': 'Delivered', 'date': _currentOrder.status == 'Delivered' ? DateFormat('dd MMM yyyy').format(_currentOrder.deliveryDate) : 'Pending', 'done': _currentOrder.status == 'Delivered'},
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
    final bool isDelivered = _currentOrder.status == 'Delivered';

    if (isDelivered) {
      return const SizedBox.shrink(); // Replaced by _buildDownloadReceiptButton
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
                  MaterialPageRoute(
                    builder: (_) => EditOrderScreen(
                      order: _currentOrder,
                      customer: widget.customer,
                    ),
                  ),
                ).then((updatedOrder) {
                  if (updatedOrder != null && updatedOrder is OrderModel) {
                    setState(() {
                      _currentOrder = updatedOrder;
                    });
                  }
                });
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
              onPressed: () async {
                try {
                  await OrderController().updateOrderStatus(_currentOrder.id, 'Delivered');
                  if (mounted) {
                    Navigator.pop(context, true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Order marked as Delivered!',
                          style: GoogleFonts.inter(color: Colors.white),
                        ),
                        backgroundColor: kAccent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating order: $e')),
                    );
                  }
                }
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
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kR)),
          title: Text(
            'Delete Order',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: kPrimary),
          ),
          content: Text(
            'Are you sure you want to delete this order? This action cannot be undone.',
            style: GoogleFonts.inter(color: kTextPri),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: kTextSec, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // Close dialog
                try {
                  await OrderController().deleteOrder(_currentOrder.id);
                  if (mounted) {
                    Navigator.pop(context, true); // Go back to dashboard/orders
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Order deleted successfully!',
                          style: GoogleFonts.inter(color: Colors.white),
                        ),
                        backgroundColor: Colors.red.shade600,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting order: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDownloadReceiptButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: _isDownloading ? null : _downloadReceipt,
        icon: _isDownloading 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.download_outlined),
        label: Text(
          _isDownloading ? 'Saving Receipt...' : 'Download Receipt', 
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: kPrimary,
          side: const BorderSide(color: kPrimary, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kR)),
        ),
      ),
    );
  }
}
