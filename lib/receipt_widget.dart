import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'controllers/profile_controller.dart';
import 'tailor_icon.dart';

import 'models/order_model.dart';
import 'models/customer_model.dart';

// Assuming these are defined in your main.dart or a constants file
const Color kPrimaryColor = Color(0xFF1E3A5F);
const Color kAccentColor = Color(0xFF10B981);
const Color kTextPrimary = Color(0xFF334155);
const Color kTextSecondary = Color(0xFF64748B);

class ReceiptWidget extends StatelessWidget {
  final OrderModel order;
  final CustomerModel customer;

  const ReceiptWidget({
    super.key,
    required this.order,
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    final double remaining = order.totalAmount - order.advancePaid;
    final bool isPaid = remaining <= 0;
    
    return Container(
      color: Colors.white,
      width: 450, // Fixed width for generated receipt
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. HEADER
          Container(
            width: double.infinity,
            color: kPrimaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CustomPaint(
                    painter: TailorLineArtPainter(
                      primaryColor: Colors.white,
                      accentColor: kAccentColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ProfileController().profile?.shopName ?? 'Tailor App',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '0300-1234567',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                ),
                Text(
                  'Main Market, Larkana',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. RECEIPT TITLE
          Text(
            'RECEIPT',
            style: GoogleFonts.inter(
              color: kPrimaryColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Container(height: 2, width: 100, color: kAccentColor),
          const SizedBox(height: 16),

          // 3. ORDER INFO SECTION
          _buildInfoRow('Order ID:', '#${order.id}'),
          _buildInfoRow('Date:', DateFormat('dd MMM yyyy').format(order.orderDate)),
          _buildInfoRow('Delivery Date:', DateFormat('dd MMM yyyy').format(order.deliveryDate)),
          _buildInfoRow('Status:', order.status),
          const SizedBox(height: 12),
          _buildDashedDivider(),
          const SizedBox(height: 12),

          // 4. CUSTOMER INFO SECTION
          _buildSectionTitle('Customer Details'),
          const SizedBox(height: 8),
          _buildInfoRow('Name:', customer.name),
          _buildInfoRow('Phone:', customer.phone),
          _buildInfoRow('Address:', customer.address?.isNotEmpty == true ? customer.address! : 'N/A'),
          const SizedBox(height: 12),
          _buildDashedDivider(),
          const SizedBox(height: 12),

          // 5. ORDER DETAILS SECTION
          _buildSectionTitle('Order Details'),
          const SizedBox(height: 8),
          _buildInfoRow('Order Type:', order.isAdult ? 'Adult' : 'Child'),
          _buildInfoRow('Quantity:', '${order.quantity}'),
          _buildInfoRow('Fabric Notes:', order.measurements.extraNotes ?? 'N/A'),
          const SizedBox(height: 12),
          _buildDashedDivider(),
          const SizedBox(height: 12),

          // 7. PAYMENT SUMMARY SECTION
          _buildSectionTitle('Payment Summary'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kPrimaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildPaymentRow('Total Amount:', 'PKR ${order.totalAmount.toStringAsFixed(0)}', Colors.white),
                const SizedBox(height: 8),
                _buildPaymentRow('Advance Paid:', 'PKR ${order.advancePaid.toStringAsFixed(0)}', kAccentColor),
                const Divider(color: Colors.white24, height: 16),
                _buildPaymentRow('Remaining:', 'PKR ${remaining.toStringAsFixed(0)}', kAccentColor),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Payment Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: (isPaid ? kAccentColor : Colors.orange).withValues(alpha: 0.1),
              border: Border.all(color: isPaid ? kAccentColor : Colors.orange, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isPaid ? 'PAID ✓' : 'UNPAID',
              style: GoogleFonts.inter(
                color: isPaid ? kAccentColor : Colors.orange,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildDashedDivider(),
          const SizedBox(height: 16),

          // 8. FOOTER
          Container(height: 2, width: double.infinity, color: kAccentColor),
          const SizedBox(height: 16),
          Text(
            'Thank you for your business!',
            style: GoogleFonts.inter(
              color: kTextSecondary,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Powered by TryUnity Solutions',
            style: GoogleFonts.inter(color: kTextSecondary, fontSize: 10, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            '+92 302 3476605',
            style: GoogleFonts.inter(color: kTextSecondary, fontSize: 10),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Expanded(child: _DashedLine()),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(Icons.content_cut, color: kTextSecondary, size: 16),
              ),
              const Expanded(child: _DashedLine()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: kPrimaryColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isMeasurement = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: kTextSecondary,
              fontSize: isMeasurement ? 12 : 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: kTextPrimary,
              fontSize: isMeasurement ? 12 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  Widget _buildDashedDivider() {
    return const _DashedLine();
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          direction: Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey),
              ),
            );
          }),
        );
      },
    );
  }
}
