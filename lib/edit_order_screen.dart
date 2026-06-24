// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/customer_model.dart';
import '../models/measurement_model.dart';
import '../models/order_model.dart';
import '../controllers/order_controller.dart';

// --- Design System Constants ---
const Color kPrimary = Color(0xFF1E3A5F);
const Color kAccent = Color(0xFF10B981);
const Color kBg = Color(0xFFF8FAFC);
const Color kCard = Color(0xFFFFFFFF);
const Color kTextPri = Color(0xFF0F172A);
const Color kTextSec = Color(0xFF64748B);
const double kR = 16.0;

class EditOrderScreen extends StatefulWidget {
  final OrderModel order;
  final CustomerModel customer;

  const EditOrderScreen({
    super.key,
    required this.order,
    required this.customer,
  });

  @override
  State<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  final PageController _pageController = PageController();
  final _formKey1 = GlobalKey<FormState>();

  int _currentStep = 0;

  late String _customerName;
  late String _customerPhone;

  late String _status;
  final OrderController _orderController = OrderController();

  // --- 14-Point Measurement State ---
  final bool _measurementsLocked = false;
  final _lengthCtrl = TextEditingController();
  final _armCtrl = TextEditingController();
  final _mundoCtrl = TextEditingController();
  bool _optMundo = false;
  final _shoulderCtrl = TextEditingController();
  final _collarCtrl = TextEditingController();
  bool _colRegular = true;
  bool _colFrench = false;
  bool _colSherwani = false;
  String _sherwaniType = 'Half';
  final _chestCtrl = TextEditingController();
  final _waistCtrl = TextEditingController();
  final _hipCtrl = TextEditingController();
  final _shalwarCtrl = TextEditingController();
  bool _shalKanto = false;
  bool _shalZipPocket = false;
  bool _shalWidth = false;
  final _bottomCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  bool _optFrontPocket = true;
  final _frontPocketCtrl = TextEditingController();
  bool _optSidePocket = false;
  String _cuffType = 'Round'; // Round, Double kaj, Double, Square
  final _cuffCtrl = TextEditingController();
  final _extraCtrl = TextEditingController();

  double get _totalAmount    => double.tryParse(_totalAmountCtrl.text) ?? 0;
  double get _advancePaid    => double.tryParse(_advancePaidCtrl.text) ?? 0;
  double get _remainingAmount => _totalAmount - _advancePaid;

  final List<String> _statuses = ['Pending', 'In Progress', 'Ready', 'Delivered'];

  final TextEditingController _specialNotesCtrl = TextEditingController();
  final TextEditingController _quantityCtrl     = TextEditingController();
  final TextEditingController _orderDateCtrl    = TextEditingController();
  final TextEditingController _deliveryDateCtrl = TextEditingController();
  final TextEditingController _totalAmountCtrl  = TextEditingController();
  final TextEditingController _advancePaidCtrl  = TextEditingController();

  @override
  void initState() {
    super.initState();
    _customerName = widget.customer.name;
    _customerPhone = widget.customer.phone;
    _status = widget.order.status;

    _quantityCtrl.text = widget.order.quantity.toString();
    _totalAmountCtrl.text = widget.order.totalAmount.toString();
    _advancePaidCtrl.text = widget.order.advancePaid.toString();

    final DateFormat formatter = DateFormat('dd MMM yyyy');
    try {
      _orderDateCtrl.text = formatter.format(widget.order.orderDate);
      _deliveryDateCtrl.text = formatter.format(widget.order.deliveryDate);
    } catch (e) {
      _orderDateCtrl.text = widget.order.orderDate.toString();
      _deliveryDateCtrl.text = widget.order.deliveryDate.toString();
    }

    _populateMeasurements();
  }

  void _populateMeasurements() {
    try {
      final m = widget.order.measurements;
      
      _lengthCtrl.text = m.lengthMeasure ?? '';
      _armCtrl.text = m.armMeasure ?? '';
      _mundoCtrl.text = m.mundoMeasure ?? '';
      _optMundo = m.optMundo;
      _shoulderCtrl.text = m.shoulderMeasure ?? '';
      _collarCtrl.text = m.collarMeasure ?? '';
      _colRegular = m.colRegular;
      _colFrench = m.colFrench;
      _colSherwani = m.colSherwani;
      _sherwaniType = m.sherwaniType;
      _chestCtrl.text = m.chestMeasure ?? '';
      _waistCtrl.text = m.waistMeasure ?? '';
      _hipCtrl.text = m.hipMeasure ?? '';
      _shalwarCtrl.text = m.shalwarMeasure ?? '';
      _shalKanto = m.shalKanto;
      _shalZipPocket = m.shalZipPocket;
      _shalWidth = m.shalWidth;
      _bottomCtrl.text = m.bottomMeasure ?? '';
      _plateCtrl.text = m.plateMeasure ?? '';
      _optFrontPocket = m.optFrontPocket;
      _frontPocketCtrl.text = m.frontPocketMeasure ?? '';
      _optSidePocket = m.optSidePocket;
      _cuffType = m.cuffType;
      _cuffCtrl.text = m.cuffMeasure ?? '';
      _extraCtrl.text = m.extraNotes ?? '';
    } catch (e) {
      debugPrint('Error parsing measurements: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _specialNotesCtrl.dispose();
    _quantityCtrl.dispose();
    _orderDateCtrl.dispose();
    _deliveryDateCtrl.dispose();
    _totalAmountCtrl.dispose();
    _advancePaidCtrl.dispose();
    _lengthCtrl.dispose();
    _armCtrl.dispose();
    _mundoCtrl.dispose();
    _shoulderCtrl.dispose();
    _collarCtrl.dispose();
    _chestCtrl.dispose();
    _waistCtrl.dispose();
    _hipCtrl.dispose();
    _shalwarCtrl.dispose();
    _bottomCtrl.dispose();
    _plateCtrl.dispose();
    _frontPocketCtrl.dispose();
    _cuffCtrl.dispose();
    _extraCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0 && _formKey1.currentState!.validate()) {
      setState(() => _currentStep = 1);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep == 1) {
      setState(() => _currentStep = 0);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showSaveConfirmation() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Icon(Icons.save_outlined, color: kPrimary, size: 48),
              const SizedBox(height: 16),
              Text(
                'Save Changes?',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kTextPri,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This will update the order details.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: kTextSec,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    final MeasurementModel newMeasurements = MeasurementModel(
                      lengthMeasure: _lengthCtrl.text,
                      armMeasure: _armCtrl.text,
                      optMundo: _optMundo,
                      mundoMeasure: _mundoCtrl.text,
                      shoulderMeasure: _shoulderCtrl.text,
                      collarMeasure: _collarCtrl.text,
                      colRegular: _colRegular,
                      colFrench: _colFrench,
                      colSherwani: _colSherwani,
                      sherwaniType: _sherwaniType,
                      chestMeasure: _chestCtrl.text,
                      waistMeasure: _waistCtrl.text,
                      hipMeasure: _hipCtrl.text,
                      shalwarMeasure: _shalwarCtrl.text,
                      shalKanto: _shalKanto,
                      shalZipPocket: _shalZipPocket,
                      shalWidth: _shalWidth,
                      bottomMeasure: _bottomCtrl.text,
                      plateMeasure: _plateCtrl.text,
                      optFrontPocket: _optFrontPocket,
                      frontPocketMeasure: _frontPocketCtrl.text,
                      optSidePocket: _optSidePocket,
                      cuffType: _cuffType,
                      cuffMeasure: _cuffCtrl.text,
                      extraNotes: _extraCtrl.text,
                    );

                    final updatedOrder = widget.order.copyWith(
                      status: _status,
                      orderDate: DateFormat('dd MMM yyyy').parse(_orderDateCtrl.text),
                      deliveryDate: DateFormat('dd MMM yyyy').parse(_deliveryDateCtrl.text),
                      quantity: int.tryParse(_quantityCtrl.text) ?? 1,
                      totalAmount: _totalAmount,
                      advancePaid: _advancePaid,
                      measurements: newMeasurements,
                    );

                    try {
                      await _orderController.updateOrder(updatedOrder);
                      if (context.mounted) {
                        Navigator.pop(context); // Close sheet
                        Navigator.pop(context, updatedOrder); // Go back with updated order
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Order updated successfully!',
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
                      if (context.mounted) {
                        Navigator.pop(context); // Close sheet
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Error updating order: $e',
                              style: GoogleFonts.inter(color: Colors.white),
                            ),
                            backgroundColor: Colors.red,
                          ),
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
                    'Confirm',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kTextSec,
                    side: BorderSide(color: Colors.grey.shade300, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kR),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
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
            'Edit Order',
            style: GoogleFonts.inter(
              color: kPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: Column(
          children: [
            const SizedBox(height: 16),
            _StepIndicator(currentStep: _currentStep),
            const SizedBox(height: 24),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // STEP 1: ORDER DETAILS
  // ==========================================
  Widget _buildStep1() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Form(
        key: _formKey1,
        child: Column(
          children: [
            _buildCustomerCard(),
            const SizedBox(height: 16),
            _buildOrderStatusCard(),
            const SizedBox(height: 16),
            _buildOrderInfoCard(),
            const SizedBox(height: 16),
            _buildPricingCard(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kR),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Next →',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard() {
    return _SectionCard(
      title: 'Customer',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 14, color: kTextSec),
          const SizedBox(width: 4),
          Text('Cannot change', style: GoogleFonts.inter(fontSize: 12, color: kTextSec)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: kAccent.withValues(alpha: 0.1),
            child: Text(
              'AA',
              style: GoogleFonts.inter(color: kAccent, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _customerName,
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: kTextPri),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: 101',
                  style: GoogleFonts.inter(fontSize: 13, color: kAccent, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _customerPhone,
                  style: GoogleFonts.inter(fontSize: 13, color: kTextSec),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusCard() {
    return _SectionCard(
      title: 'Order Status',
      child: DropdownButtonFormField<String>(
        initialValue: _status,
        items: _statuses.map((s) {
          Color c;
          switch (s) {
            case 'Pending': c = Colors.orange; break;
            case 'In Progress': c = Colors.blue; break;
            case 'Ready': c = Colors.purple; break;
            case 'Delivered': c = kAccent; break;
            default: c = kTextPri;
          }
          return DropdownMenuItem(
            value: s,
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: c),
                ),
                const SizedBox(width: 8),
                Text(s, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
              ],
            ),
          );
        }).toList(),
        onChanged: (v) {
          if (v != null) setState(() => _status = v);
        },
        decoration: InputDecoration(
          filled: true,
          fillColor: kCard,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kR),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kR),
            borderSide: const BorderSide(color: kAccent, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard() {
    return _SectionCard(
      title: 'Order Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _InputField(
                  controller: _quantityCtrl,
                  label: 'Quantity',
                  icon: Icons.format_list_numbered_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InputField(
                  controller: _orderDateCtrl,
                  label: 'Order Date',
                  icon: Icons.calendar_today_outlined,
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InputField(
                  controller: _deliveryDateCtrl,
                  label: 'Delivery Date',
                  icon: Icons.local_shipping_outlined,
                  readOnly: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildPricingCard() {
    return _SectionCard(
      title: 'Pricing',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _InputField(
                  controller: _totalAmountCtrl,
                  label: 'Total (PKR)',
                  icon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InputField(
                  controller: _advancePaidCtrl,
                  label: 'Advance (PKR)',
                  icon: Icons.account_balance_wallet_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(kR),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Remaining Balance',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: kTextPri),
                ),
                Text(
                  'PKR ${_remainingAmount.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _remainingAmount <= 0 ? kAccent : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _InputField(
            controller: _specialNotesCtrl,
            label: 'Special Notes (Optional)',
            icon: Icons.notes_outlined,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 2: MEASUREMENTS
  // ==========================================
  Widget _buildStep2() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text('Editing existing measurements',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.blue[800], fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _SectionCard(
            title: 'Measurements',
            child: Column(
              children: [
                // 1. Length
                _buildCompactMeasureField('Length', _lengthCtrl, readOnly: _measurementsLocked),
                const SizedBox(height: 12), const Divider(), const SizedBox(height: 12),
                
                // 2. Arm + Mundo
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: _buildCompactMeasureField('Arm', _armCtrl, readOnly: _measurementsLocked)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildCompactMeasureField('Mundo', _mundoCtrl, readOnly: _measurementsLocked),
                    ),
                  ],
                ),
                const SizedBox(height: 12), const Divider(), const SizedBox(height: 12),

                // 3. Shoulder
                _buildCompactMeasureField('Shoulder', _shoulderCtrl, readOnly: _measurementsLocked),
                const SizedBox(height: 12), const Divider(), const SizedBox(height: 12),

                // 4. Collar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCompactMeasureField('Collar', _collarCtrl, readOnly: _measurementsLocked),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildOptionCheckbox('Regular', _colRegular, _measurementsLocked ? null : (v) => setState(() => _colRegular = v))),
                        Expanded(child: _buildOptionCheckbox('French', _colFrench, _measurementsLocked ? null : (v) => setState(() => _colFrench = v))),
                        Expanded(child: _buildOptionCheckbox('Sherwani', _colSherwani, _measurementsLocked ? null : (v) => setState(() => _colSherwani = v))),
                      ],
                    ),
                    if (_colSherwani) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text('Half', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
                              value: 'Half',
                              groupValue: _sherwaniType,
                              onChanged: _measurementsLocked ? null : (v) => setState(() => _sherwaniType = v!),
                              activeColor: kAccent, contentPadding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text('Full', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
                              value: 'Full',
                              groupValue: _sherwaniType,
                              onChanged: _measurementsLocked ? null : (v) => setState(() => _sherwaniType = v!),
                              activeColor: kAccent, contentPadding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                    ]
                  ],
                ),
                const SizedBox(height: 12), const Divider(), const SizedBox(height: 12),

                // 5. Chest
                _buildCompactMeasureField('Chest', _chestCtrl, readOnly: _measurementsLocked),
                const SizedBox(height: 12), const Divider(), const SizedBox(height: 12),

                // 6. Waist
                _buildCompactMeasureField('Waist', _waistCtrl, readOnly: _measurementsLocked),
                const SizedBox(height: 12), const Divider(), const SizedBox(height: 12),

                // 7. Hip
                _buildCompactMeasureField('Hip', _hipCtrl, readOnly: _measurementsLocked),
                const SizedBox(height: 12), const Divider(), const SizedBox(height: 12),

                // 8. Shalwar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCompactMeasureField('Shalwar', _shalwarCtrl, readOnly: _measurementsLocked),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildOptionCheckbox('Kanto', _shalKanto, _measurementsLocked ? null : (v) => setState(() => _shalKanto = v))),
                        Expanded(child: _buildOptionCheckbox('Zip Pocket', _shalZipPocket, _measurementsLocked ? null : (v) => setState(() => _shalZipPocket = v))),
                        Expanded(child: _buildOptionCheckbox('Width', _shalWidth, _measurementsLocked ? null : (v) => setState(() => _shalWidth = v))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12), const Divider(), const SizedBox(height: 12),

                // 9. Bottom
                _buildCompactMeasureField('Bottom', _bottomCtrl, readOnly: _measurementsLocked),
                const SizedBox(height: 12), const Divider(), const SizedBox(height: 12),

                // 10. Plate
                _buildCompactMeasureField('Plate', _plateCtrl, readOnly: _measurementsLocked),
                const SizedBox(height: 12), const Divider(), const SizedBox(height: 12),

                // 11. Front Pocket
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildOptionCheckbox('Front Pocket', _optFrontPocket, _measurementsLocked ? null : (v) => setState(() => _optFrontPocket = v)),
                    ),
                    if (_optFrontPocket)
                      Expanded(
                        flex: 1,
                        child: _buildCompactMeasureField('', _frontPocketCtrl, readOnly: _measurementsLocked),
                      )
                    else
                      const Spacer(),
                  ],
                ),
                const SizedBox(height: 12), const Divider(), const SizedBox(height: 12),

                // 12. Side Pocket
                _buildOptionCheckbox('Side Pocket', _optSidePocket, _measurementsLocked ? null : (v) => setState(() => _optSidePocket = v)),
                const SizedBox(height: 12), const Divider(), const SizedBox(height: 12),

                // 13. Cuff
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cuff', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: kTextPri)),
                    const SizedBox(height: 8),
                    _buildCompactMeasureField('', _cuffCtrl, readOnly: _measurementsLocked),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 0,
                      children: ['Round', 'Double kaj', 'Double', 'Square'].map((type) {
                        return SizedBox(
                          width: 140,
                          child: RadioListTile<String>(
                            title: Text(type, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
                            value: type,
                            groupValue: _cuffType,
                            onChanged: _measurementsLocked ? null : (v) => setState(() => _cuffType = v!),
                            activeColor: kAccent, contentPadding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 12), const Divider(), const SizedBox(height: 12),

                // 14. Extra
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Extra', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: kTextPri)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _extraCtrl,
                      readOnly: _measurementsLocked,
                      maxLines: 3,
                      style: GoogleFonts.inter(fontSize: 14, color: _measurementsLocked ? kTextSec : kTextPri),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _measurementsLocked ? Colors.grey.shade100 : kBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _measurementsLocked ? Colors.grey.shade300 : Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kAccent)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          // Nav buttons
          Row(
            children: [
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton(
                    onPressed: _prevStep,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kTextPri,
                      side: BorderSide(color: Colors.grey.shade300, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kR)),
                    ),
                    child: Text('← Back', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _showSaveConfirmation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kR)),
                      elevation: 0,
                    ),
                    child: Text('Save Changes', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCompactMeasureField(String label, TextEditingController ctrl, {bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: kTextPri)),
          const SizedBox(height: 4),
        ],
        SizedBox(
          height: 40,
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.text,
            readOnly: readOnly,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: readOnly ? kTextSec : kTextPri,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              filled: true,
              fillColor: readOnly ? Colors.grey.shade100 : kBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: readOnly ? Colors.grey.shade300 : Colors.grey.shade200,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: kAccent),
              ),
              suffixIcon: readOnly
                  ? const Icon(Icons.lock_outline, size: 14, color: kTextSec)
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCheckbox(String title, bool value, ValueChanged<bool>? onChanged) {
    return CheckboxListTile(
      title: Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
      value: value,
      onChanged: onChanged == null ? null : (bool? v) => onChanged(v ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      activeColor: kAccent,
    );
  }
}

// ==========================================
// SHARED WIDGETS
// ==========================================

class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          _StepCircle(index: 0, currentStep: currentStep, label: 'Order Details'),
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: currentStep >= 1
                      ? [kAccent, kAccent]
                      : [kAccent, Colors.grey.shade300],
                ),
              ),
            ),
          ),
          _StepCircle(index: 1, currentStep: currentStep, label: 'Measurements'),
        ],
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  final int index;
  final int currentStep;
  final String label;

  const _StepCircle({
    required this.index,
    required this.currentStep,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = currentStep > index;
    final isActive = currentStep == index;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isCompleted || isActive) ? kAccent : Colors.transparent,
            border: Border.all(
              color: (isCompleted || isActive) ? kAccent : kTextSec,
              width: 2,
            ),
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 20, key: ValueKey('check'))
                  : Text(
                      '${index + 1}',
                      key: ValueKey('num$index'),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.white : kTextSec,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? kPrimary : kTextSec,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;

  const _SectionCard({
    required this.title,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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

class _InputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final int maxLines;
  final bool readOnly;
  final ValueChanged<String>? onChanged;

  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.inputFormatters = const [],
    this.maxLines = 1,
    this.readOnly = false,
    this.onChanged,
  });

  @override
  State<_InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<_InputField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: TextFormField(
        controller: widget.controller,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        maxLines: widget.maxLines,
        readOnly: widget.readOnly,
        onChanged: widget.onChanged,
        style: GoogleFonts.inter(fontSize: 14, color: kTextPri),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: GoogleFonts.inter(
            color: _focused ? kAccent : kTextSec,
            fontSize: 13,
          ),
          prefixIcon: Icon(widget.icon, color: _focused ? kAccent : kTextSec, size: 20),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kR),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kR),
            borderSide: const BorderSide(color: kAccent, width: 2),
          ),
          filled: true,
          fillColor: widget.readOnly ? Colors.grey.shade50 : kCard,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
