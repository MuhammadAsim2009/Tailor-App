import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tailor_icon.dart';

// Assuming these are defined in your main.dart or a constants file
const Color kPrimaryColor = Color(0xFF1E3A5F);
const Color kAccentColor = Color(0xFF10B981);
const Color kTextPrimary = Color(0xFF334155);
const Color kTextSecondary = Color(0xFF64748B);

class ReceiptWidget extends StatelessWidget {
  const ReceiptWidget({super.key});

  @override
  Widget build(BuildContext context) {
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
                  'Irfan Tailors',
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
          _buildInfoRow('Order ID:', '#ORD-001'),
          _buildInfoRow('Date:', '12 June 2025'),
          _buildInfoRow('Delivery Date:', '20 June 2025'),
          _buildInfoRow('Status:', 'Ready ✓'),
          const SizedBox(height: 12),
          _buildDashedDivider(),
          const SizedBox(height: 12),

          // 4. CUSTOMER INFO SECTION
          _buildSectionTitle('Customer Details'),
          const SizedBox(height: 8),
          _buildInfoRow('Name:', 'Muhammad Ali'),
          _buildInfoRow('Phone:', '0300-1234567'),
          _buildInfoRow('Address:', 'Larkana, Sindh'),
          const SizedBox(height: 12),
          _buildDashedDivider(),
          const SizedBox(height: 12),

          // 5. ORDER DETAILS SECTION
          _buildSectionTitle('Order Details'),
          const SizedBox(height: 8),
          _buildInfoRow('Order Type:', 'Adult'), // Or Child based on data
          _buildInfoRow('Quantity:', '1'),
          _buildInfoRow('Fabric Notes:', 'White lawn fabric'),
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
                _buildPaymentRow('Total Amount:', 'PKR 5,000', Colors.white),
                const SizedBox(height: 8),
                _buildPaymentRow('Advance Paid:', 'PKR 2,000', kAccentColor),
                const Divider(color: Colors.white24, height: 16),
                _buildPaymentRow('Remaining:', 'PKR 3,000', kAccentColor),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Payment Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: kAccentColor.withValues(alpha: 0.1),
              border: Border.all(color: kAccentColor, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'PAID ✓',
              style: GoogleFonts.inter(
                color: kAccentColor,
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
            'Powered by Irfan Tailors App',
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

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: kTextSecondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: kTextPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
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
