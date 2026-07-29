import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';

import '../models/family_model.dart';
import '../models/customer_model.dart';
import '../models/order_model.dart';
import '../controllers/order_controller.dart';
import '../controllers/profile_controller.dart';
import 'order_detail_screen.dart';
import 'tailor_icon.dart';

// ─────────────────────────────────────────────────────────────────
//  Design System
// ─────────────────────────────────────────────────────────────────
const Color _kPrimary  = Color(0xFF1E3A5F);
const Color _kAccent   = Color(0xFF10B981);
const Color _kBg       = Color(0xFFF8FAFC);
const Color _kCard     = Color(0xFFFFFFFF);
const Color _kTextPri  = Color(0xFF0F172A);
const Color _kTextSec  = Color(0xFF64748B);
const double _kR       = 16.0;

// ─────────────────────────────────────────────────────────────────
//  FamilyReceiptScreen
// ─────────────────────────────────────────────────────────────────
class FamilyReceiptScreen extends StatefulWidget {
  final FamilyModel family;
  final OrderController controller;

  const FamilyReceiptScreen({
    super.key,
    required this.family,
    required this.controller,
  });

  @override
  State<FamilyReceiptScreen> createState() => _FamilyReceiptScreenState();
}

class _FamilyReceiptScreenState extends State<FamilyReceiptScreen> {
  String _statusFilter = 'All';
  final List<String> _statusOptions = ['All', 'Pending', 'In Progress', 'Ready', 'Delivered'];

  bool _isSharing    = false;
  bool _isDownloading = false;

  // ── Data helpers ──
  List<CustomerModel> get _members =>
      widget.controller.getCustomersByFamilyId(widget.family.id);

  List<OrderModel> _ordersFor(String customerId) {
    final all = widget.controller.getOrdersByCustomerId(customerId);
    if (_statusFilter == 'All') return all;
    return all.where((o) => o.status == _statusFilter).toList();
  }

  double _subtotalFor(String customerId) =>
      _ordersFor(customerId).fold(0.0, (sum, o) => sum + o.totalAmount);

  int _totalQuantityFor(String customerId) =>
      _ordersFor(customerId).fold(0, (sum, o) => sum + o.quantity);

  double get _grandTotal =>
      _members.fold(0.0, (sum, c) => sum + _subtotalFor(c.id));

  double get _grandAdvance =>
      _members.fold(
          0.0,
          (sum, c) =>
              sum + _ordersFor(c.id).fold(0.0, (s, o) => s + o.advancePaid));

  double get _grandRemaining => _grandTotal - _grandAdvance;

  int get _grandTotalOrders =>
      _members.fold(0, (sum, c) => sum + _ordersFor(c.id).length);

  int get _grandTotalQuantity =>
      _members.fold(0, (sum, c) => sum + _totalQuantityFor(c.id));

  Color _statusColor(String status) {
    switch (status) {
      case 'Pending':     return Colors.orange;
      case 'In Progress': return Colors.blue;
      case 'Ready':       return Colors.purple;
      case 'Delivered':   return _kAccent;
      default:            return _kTextSec;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  Generate receipt image bytes (shared helper)
  // ─────────────────────────────────────────────────────────────────
  Future<File?> _generateReceiptFile() async {
    final members = _members;
    final memberOrdersMap  = {for (var c in members) c.id: _ordersFor(c.id)};
    final memberSubtotals  = {for (var c in members) c.id: _subtotalFor(c.id)};
    final memberQuantities = {for (var c in members) c.id: _totalQuantityFor(c.id)};

    final repaintKey   = GlobalKey();
    final overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        left: -10000,
        top:  -10000,
        child: RepaintBoundary(
          key: repaintKey,
          child: MediaQuery(
            data: const MediaQueryData(devicePixelRatio: 3.0),
            child: Material(
              color: Colors.transparent,
              child: _ReceiptWidget(
                family:           widget.family,
                members:          members,
                grandTotal:       _grandTotal,
                grandAdvance:     _grandAdvance,
                grandRemaining:   _grandRemaining,
                totalOrders:      _grandTotalOrders,
                totalQuantity:    _grandTotalQuantity,
                memberOrders:     memberOrdersMap,
                memberSubtotals:  memberSubtotals,
                memberQuantities: memberQuantities,
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    await Future.delayed(const Duration(milliseconds: 200));

    final boundary = repaintKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;

    if (boundary == null) {
      overlayEntry.remove();
      return null;
    }

    final image    = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    overlayEntry.remove();

    if (byteData == null) return null;

    final bytes = byteData.buffer.asUint8List();
    final dir   = await getTemporaryDirectory();
    final file  = File(
        '${dir.path}/family_receipt_${widget.family.name.replaceAll(' ', '_')}.png');
    await file.writeAsBytes(bytes);
    return file;
  }

  // ─────────────────────────────────────────────────────────────────
  //  Share receipt
  // ─────────────────────────────────────────────────────────────────
  Future<void> _shareReceipt() async {
    if (_isSharing || _isDownloading) return;
    setState(() => _isSharing = true);
    try {
      final file = await _generateReceiptFile();
      if (file == null) {
        _showSnack('Could not generate receipt', isError: true);
        return;
      }
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Family Receipt \u2014 ${widget.family.name}',
      );
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  Download receipt to gallery
  // ─────────────────────────────────────────────────────────────────
  Future<void> _downloadReceipt() async {
    if (_isSharing || _isDownloading) return;
    setState(() => _isDownloading = true);
    try {
      final file = await _generateReceiptFile();
      if (file == null) {
        _showSnack('Could not generate receipt', isError: true);
        return;
      }
      await Gal.putImage(file.path, album: 'Tailor App');
      _showSnack('Receipt saved to gallery ✓');
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: isError ? Colors.red : _kAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kCard,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              widget.family.name,
              style: GoogleFonts.inter(
                  color: _kPrimary, fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              'Family Receipt',
              style: GoogleFonts.inter(color: _kTextSec, fontSize: 12),
            ),
          ],
        ),
        actions: const [],
      ),
      body: Column(
        children: [
          // ── Status filter pills ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _statusOptions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final opt = _statusOptions[i];
                  final active = opt == _statusFilter;
                  return GestureDetector(
                    onTap: () => setState(() => _statusFilter = opt),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? _kPrimary : _kCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active ? _kPrimary : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        opt,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                          color: active ? Colors.white : _kTextSec,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Member cards + grand total ──
          Expanded(
            child: _members.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group_outlined,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'No members in this family yet',
                          style: GoogleFonts.inter(
                              color: _kTextSec, fontSize: 15),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ..._members.map((c) => _buildMemberCard(c)),
                      const SizedBox(height: 12),
                      _buildGrandTotalCard(),
                      const SizedBox(height: 32),
                    ],
                  ),
          ),

          // ── Bottom action buttons ──
          _buildBottomButtons(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  Member card
  // ─────────────────────────────────────────────────────────────────
  Widget _buildMemberCard(CustomerModel customer) {
    final orders   = _ordersFor(customer.id);
    final subtotal = _subtotalFor(customer.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(_kR),
        boxShadow: [
          BoxShadow(
            color: _kTextPri.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Member header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.04),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(_kR)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _kAccent.withValues(alpha: 0.12),
                  child: Text(
                    customer.initials,
                    style: GoogleFonts.inter(
                        color: _kAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer.name,
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: _kTextPri)),
                      if (customer.phone.isNotEmpty)
                        Text(customer.phone,
                            style: GoogleFonts.inter(
                                fontSize: 12, color: _kTextSec)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'PKR ${subtotal.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: _kPrimary),
                    ),
                    Text(
                      '${orders.length} order${orders.length == 1 ? '' : 's'}',
                      style: GoogleFonts.inter(fontSize: 11, color: _kTextSec),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Order rows
          if (orders.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No orders matching filter',
                style: GoogleFonts.inter(color: _kTextSec, fontSize: 13),
              ),
            )
          else
            ...orders.asMap().entries.map((entry) {
              final i = entry.key;
              final o = entry.value;
              final isLast = i == orders.length - 1;
              return Column(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(
                            order: o,
                            customer: customer,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                              Text(
                                '#${o.id.length > 8 ? o.id.substring(0, 8).toUpperCase() : o.id.toUpperCase()}',
                                style: GoogleFonts.inter(
                                    fontSize: 11, color: _kTextSec),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('dd MMM yyyy')
                                    .format(o.deliveryDate),
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: _kTextSec),
                              ),
                              Text(
                                'Qty: ${o.quantity}',
                                style: GoogleFonts.inter(
                                    fontSize: 11, color: _kTextSec),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _statusColor(o.status)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            o.status,
                            style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _statusColor(o.status)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'PKR ${o.totalAmount.toStringAsFixed(0)}',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _kTextPri),
                            ),
                            if (o.advancePaid > 0)
                              Text(
                                'Adv: ${o.advancePaid.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                    fontSize: 10, color: _kAccent),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ), // Closing InkWell
                  if (!isLast)
                    Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Colors.grey.shade100),
                ],
              );
            }),

          // Member subtotal footer
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _kBg,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(_kR)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        color: _kTextSec,
                        fontWeight: FontWeight.w500)),
                Text(
                  'PKR ${subtotal.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _kPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  Grand Total Card — with individual breakdown
  // ─────────────────────────────────────────────────────────────────
  Widget _buildGrandTotalCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF2D5A8E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(_kR),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.receipt_long, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(
                'Family Grand Total',
                style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Individual breakdown ──
          ..._members.map((c) {
            final orders   = _ordersFor(c.id);
            final subtotal = _subtotalFor(c.id);
            final qty      = _totalQuantityFor(c.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    child: Text(
                      c.initials,
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Name + orders/qty
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.name,
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${orders.length} order${orders.length == 1 ? '' : 's'} · Qty $qty',
                          style: GoogleFonts.inter(
                              color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  // Individual total
                  Text(
                    'PKR ${subtotal.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
          ),

          // ── Totals ──
          _buildTotalRow('Total Amount', _grandTotal, Colors.white),
          const SizedBox(height: 8),
          _buildTotalRow('Total Advance', _grandAdvance, _kAccent),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
          ),
          _buildTotalRow(
            'Remaining Balance',
            _grandRemaining,
            _grandRemaining <= 0 ? _kAccent : Colors.redAccent.shade100,
          ),

          if (_grandRemaining <= 0) ...[
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: _kAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kAccent),
                ),
                child: Text(
                  'Family Fully Paid ✓',
                  style: GoogleFonts.inter(
                      color: _kAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
        Text(
          'PKR ${amount.toStringAsFixed(0)}',
          style: GoogleFonts.inter(
              color: color, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  Bottom Action Buttons
  // ─────────────────────────────────────────────────────────────────
  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: _kCard,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          // Download Button
          Expanded(
            child: InkWell(
              onTap: _downloadReceipt,
              borderRadius: BorderRadius.circular(_kR),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: _kAccent),
                  borderRadius: BorderRadius.circular(_kR),
                  color: _kAccent.withValues(alpha: 0.05),
                ),
                alignment: Alignment.center,
                child: _isDownloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _kAccent),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.download_outlined,
                              color: _kAccent, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Download',
                            style: GoogleFonts.inter(
                              color: _kAccent,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Share Button
          Expanded(
            child: InkWell(
              onTap: _shareReceipt,
              borderRadius: BorderRadius.circular(_kR),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: _kAccent,
                  borderRadius: BorderRadius.circular(_kR),
                ),
                alignment: Alignment.center,
                child: _isSharing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.share_outlined,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Share',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  _ReceiptWidget — standalone widget captured as image for sharing
// ─────────────────────────────────────────────────────────────────
class _ReceiptWidget extends StatelessWidget {
  final FamilyModel family;
  final List<CustomerModel> members;
  final double grandTotal;
  final double grandAdvance;
  final double grandRemaining;
  final int totalOrders;
  final int totalQuantity;

  // Per-member data
  final Map<String, List<OrderModel>> memberOrders;
  final Map<String, double> memberSubtotals;
  final Map<String, int> memberQuantities;

  const _ReceiptWidget({
    required this.family,
    required this.members,
    required this.grandTotal,
    required this.grandAdvance,
    required this.grandRemaining,
    required this.totalOrders,
    required this.totalQuantity,
    required this.memberOrders,
    required this.memberSubtotals,
    required this.memberQuantities,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    
    final profile = ProfileController().profile;
    final shopName = profile?.shopName ?? 'Tailor Shop';
    final address = profile?.address ?? '';
    final phone = profile?.phone ?? '';

    final bool isPaid = grandRemaining <= 0;

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
            color: _kPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CustomPaint(
                    painter: TailorLineArtPainter(
                      primaryColor: Colors.white,
                      accentColor: _kAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  shopName,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phone,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                ),
                Text(
                  address,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. RECEIPT TITLE
          Text(
            'FAMILY RECEIPT',
            style: GoogleFonts.inter(
              color: _kPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Container(height: 2, width: 100, color: _kAccent),
          const SizedBox(height: 16),

          // 3. FAMILY INFO SECTION
          _buildInfoRow('Family:', family.name),
          _buildInfoRow('Total Members:', '${members.length}'),
          _buildInfoRow('Date:', DateFormat('dd MMM yyyy, hh:mm a').format(now)),
          const SizedBox(height: 12),
          _buildDashedDivider(),
          const SizedBox(height: 12),

          // 4. MEMBER DETAILS SECTION
          _buildSectionTitle('Member Details'),
          const SizedBox(height: 12),
          ...members.map((c) {
            final orders   = memberOrders[c.id] ?? [];
            final subtotal = memberSubtotals[c.id] ?? 0;
            final qty      = memberQuantities[c.id] ?? 0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      c.name,
                      style: GoogleFonts.inter(
                        color: _kPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'PKR ${subtotal.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        color: _kPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${orders.length} order${orders.length == 1 ? '' : 's'}',
                      style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13),
                    ),
                    Text(
                      'Qty: $qty',
                      style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            );
          }),
          const SizedBox(height: 4),
          _buildDashedDivider(),
          const SizedBox(height: 12),

          // 5. PAYMENT SUMMARY SECTION
          _buildSectionTitle('Grand Summary'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _kPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildPaymentRow('Total Orders:', '$totalOrders', Colors.white),
                const SizedBox(height: 6),
                _buildPaymentRow('Total Quantity:', '$totalQuantity', Colors.white),
                const Divider(color: Colors.white24, height: 16),
                _buildPaymentRow('Total Amount:', 'PKR ${grandTotal.toStringAsFixed(0)}', Colors.white),
                const SizedBox(height: 8),
                _buildPaymentRow('Advance Paid:', 'PKR ${grandAdvance.toStringAsFixed(0)}', _kAccent),
                const Divider(color: Colors.white24, height: 16),
                _buildPaymentRow('Remaining:', 'PKR ${grandRemaining.toStringAsFixed(0)}', _kAccent),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Payment Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: (isPaid ? _kAccent : Colors.orange).withValues(alpha: 0.1),
              border: Border.all(color: isPaid ? _kAccent : Colors.orange, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isPaid ? 'FULLY PAID ✓' : 'UNPAID',
              style: GoogleFonts.inter(
                color: isPaid ? _kAccent : Colors.orange,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildDashedDivider(),
          const SizedBox(height: 16),

          // 6. FOOTER
          Container(height: 2, width: double.infinity, color: _kAccent),
          const SizedBox(height: 16),
          Text(
            'Thank you for ordering with $shopName!',
            style: GoogleFonts.inter(
              color: const Color(0xFF64748B),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Powered by TryUnity Solutions',
            style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            '+92 302 3476605',
            style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 10),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Expanded(child: _DashedLine()),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(Icons.content_cut, color: Color(0xFF64748B), size: 16),
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
          color: _kPrimary,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFF64748B),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: const Color(0xFF334155),
              fontSize: 14,
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
