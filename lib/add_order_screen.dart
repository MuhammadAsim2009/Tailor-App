// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/customer_model.dart';
import '../models/order_model.dart';
import '../models/measurement_model.dart';
import '../controllers/order_controller.dart';

// ─────────────────────────────────────────────────────────────────
//  Design System Constants
// ─────────────────────────────────────────────────────────────────
const Color kPrimary = Color(0xFF1E3A5F);
const Color kAccent = Color(0xFF10B981);
const Color kBg = Color(0xFFF8FAFC);
const Color kCard = Color(0xFFFFFFFF);
const Color kTextPri = Color(0xFF0F172A);
const Color kTextSec = Color(0xFF64748B);
const double kR = 16.0;

// ─────────────────────────────────────────────────────────────────
//  AddOrderScreen — 4-Step Wizard
// ─────────────────────────────────────────────────────────────────
class AddOrderScreen extends StatefulWidget {
  const AddOrderScreen({super.key});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen>
    with SingleTickerProviderStateMixin {
  // ── Step tracking ──
  int _currentStep = 0; // 0=Customer, 1=Type, 2=Details, 3=Measurements
  final PageController _pageController = PageController();

  // ── Step 1: Customer Details ──
  final _formKey1 = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();

  final OrderController _orderController = OrderController();

  CustomerModel? _selectedCustomer;
  bool _measurementsLocked =
      false; // only locked when auto-filled from an existing customer

  // ── Step 2: Customer Type ──
  bool _isAdult = true;

  // ── Step 3: Order Details ──
  final _formKey3 = GlobalKey<FormState>();
  final _quantityCtrl = TextEditingController(text: '1');
  DateTime? _orderDate = DateTime.now();
  DateTime? _deliveryDate = DateTime.now().add(const Duration(days: 7));
  final _totalCtrl = TextEditingController();
  final _advanceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // ── Step 4: Measurements ──
  final _lengthCtrl = TextEditingController();
  final _armCtrl = TextEditingController();
  bool _optMundo = false;
  final _shoulderCtrl = TextEditingController();
  final _collarCtrl = TextEditingController();
  bool _colRegular = false;
  bool _colFrench = false;
  bool _colSherwani = false;
  String _sherwaniType = 'Half'; // 'Half' or 'Full'
  final _chestCtrl = TextEditingController();
  final _waistCtrl = TextEditingController();
  final _hipCtrl = TextEditingController();
  final _shalwarCtrl = TextEditingController();
  bool _shalKanto = false;
  bool _shalZipPocket = false;
  bool _shalWidth = false;
  final _bottomCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  bool _optFrontPocket = false;
  final _frontPocketCtrl = TextEditingController();
  bool _optSidePocket = false;
  String _cuffType = 'Round'; // Round, Double kaj, Double, Square
  final _extraCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _totalCtrl.addListener(_updateBalance);
    _advanceCtrl.addListener(_updateBalance);
    _orderController.addListener(_onDataLoaded);
    // If data is already loaded, populate immediately
    if (!_orderController.isLoading) {
      _onDataLoaded();
    }
  }

  void _onDataLoaded() {
    if (!_orderController.isLoading && _selectedCustomer == null) {
      if (_idCtrl.text.isEmpty) {
        _idCtrl.text = _orderController.nextCustomerId;
      }
    }
  }

  @override
  void dispose() {
    _orderController.removeListener(_onDataLoaded);
    _pageController.dispose();
    _idCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addrCtrl.dispose();
    _quantityCtrl.dispose();
    _totalCtrl.dispose();
    _advanceCtrl.dispose();
    _notesCtrl.dispose();
    _lengthCtrl.dispose();
    _armCtrl.dispose();
    _shoulderCtrl.dispose();
    _collarCtrl.dispose();
    _chestCtrl.dispose();
    _waistCtrl.dispose();
    _hipCtrl.dispose();
    _shalwarCtrl.dispose();
    _bottomCtrl.dispose();
    _plateCtrl.dispose();
    _frontPocketCtrl.dispose();
    _extraCtrl.dispose();
    super.dispose();
  }

  // ── Balance Calculation ──
  double get _remainingBalance {
    final total = double.tryParse(_totalCtrl.text) ?? 0;
    final advance = double.tryParse(_advanceCtrl.text) ?? 0;
    return (total - advance).clamp(0.0, double.infinity);
  }

  void _updateBalance() => setState(() {});

  // ── Navigation ──
  void _nextStep() {
    if (_currentStep == 0 && !_formKey1.currentState!.validate()) return;
    if (_currentStep == 3 && !_formKey3.currentState!.validate()) return;

    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _confirmOrder();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _confirmOrder() async {
    final customer =
        _selectedCustomer ??
        CustomerModel(
          id: '', // Will be generated by controller
          name: _nameCtrl.text,
          phone: _phoneCtrl.text,
          address: _addrCtrl.text,
        );

    final measurements = MeasurementModel(
      lengthMeasure: _lengthCtrl.text,
      armMeasure: _armCtrl.text,
      optMundo: _optMundo,
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
      extraNotes: _extraCtrl.text,
    );

    final order = OrderModel(
      id: '', // Generated by controller
      customerId: '', // Replaced by controller
      isAdult: _isAdult,
      quantity: int.tryParse(_quantityCtrl.text) ?? 1,
      orderDate: _orderDate ?? DateTime.now(),
      deliveryDate:
          _deliveryDate ?? DateTime.now().add(const Duration(days: 7)),
      totalAmount: double.tryParse(_totalCtrl.text) ?? 0.0,
      advancePaid: double.tryParse(_advanceCtrl.text) ?? 0.0,
      measurements: measurements,
      status: 'Pending',
    );

    try {
      await _orderController.addOrder(order: order, customer: customer);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order saved successfully!',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: kAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save order.',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate(bool isDelivery) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDelivery ? _deliveryDate! : _orderDate!,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: kAccent,
            onPrimary: Colors.white,
            onSurface: kPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isDelivery) {
          _deliveryDate = picked;
        } else {
          _orderDate = picked;
        }
      });
    }
  }

  void _fillMeasurements(CustomerModel c) {
    if (c.measurements == null) return;
    final m = c.measurements!;
    _lengthCtrl.text = m.lengthMeasure ?? '';
    _armCtrl.text = m.armMeasure ?? '';
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
    _extraCtrl.text = m.extraNotes ?? '';
  }

  void _showExistingCustomerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kR)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Existing Customer',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: AnimatedBuilder(
                  animation: _orderController,
                  builder: (context, _) {
                    if (_orderController.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (_orderController.customers.isEmpty) {
                      return Center(
                        child: Text(
                          "No customers found.",
                          style: GoogleFonts.inter(color: kTextSec),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: _orderController.customers.length,
                      separatorBuilder: (context, _) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final c = _orderController.customers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: kAccent.withValues(alpha: 0.1),
                            child: Text(
                              c.name.isNotEmpty ? c.name[0] : '?',
                              style: GoogleFonts.inter(
                                color: kAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            c.name,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            c.phone,
                            style: GoogleFonts.inter(
                              color: kTextSec,
                              fontSize: 12,
                            ),
                          ),
                          trailing: c.measurements != null
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: kAccent.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Has Data',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: kAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedCustomer = c;
                              _idCtrl.text = c.id;
                              _nameCtrl.text = c.name;
                              _phoneCtrl.text = c.phone;
                              _addrCtrl.text = c.address ?? '';
                              if (c.measurements != null) {
                                _fillMeasurements(c);
                                _measurementsLocked = true;
                              } else {
                                _measurementsLocked = false;
                              }
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
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
        appBar: _buildAppBar(),
        body: Column(
          children: [
            const SizedBox(height: 24),
            _buildStepper(),
            const SizedBox(height: 24),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1Customer(),
                  _buildStep2Type(),
                  _buildStep4Measurements(),
                  _buildStep3Order(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: kCard,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_outlined,
          color: kPrimary,
          size: 20,
        ),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Text(
        'Add New Order',
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: kPrimary,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.grey.shade100),
      ),
    );
  }

  Widget _buildStepper() {
    final steps = ['Customer', 'Type', 'Measure', 'Details'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (i) {
          final isPast = i < _currentStep;
          final isCurrent = i == _currentStep;
          return Expanded(
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isPast || isCurrent
                            ? kAccent
                            : Colors.grey.shade200,
                      ),
                      child: Center(
                        child: isPast
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                            : Text(
                                '${i + 1}',
                                style: GoogleFonts.inter(
                                  color: isCurrent
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[i],
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isPast || isCurrent
                            ? kPrimary
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                if (i != steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(
                        bottom: 16,
                        left: 4,
                        right: 4,
                      ),
                      color: isPast ? kAccent : Colors.grey.shade200,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  STEP 1 — Customer Details
  // ─────────────────────────────────────────────────────────────────
  Widget _buildStep1Customer() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Form(
        key: _formKey1,
        child: Column(
          children: [
            _SectionCard(
              title: 'Customer Details',
              child: Column(
                children: [
                  _InputField(
                    controller: _idCtrl,
                    label: 'Customer ID',
                    hint: 'e.g. 101',
                    icon: Icons.badge_outlined,
                    readOnly: true,
                  ),
                  const SizedBox(height: 16),
                  _InputField(
                    controller: _nameCtrl,
                    label: 'Full Name',
                    hint: 'e.g. Ahmed Ali',
                    icon: Icons.person_outline,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  _InputField(
                    controller: _phoneCtrl,
                    label: 'Phone Number',
                    hint: '+92 300 1234567',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  _InputField(
                    controller: _addrCtrl,
                    label: 'Address (Optional)',
                    hint: 'Street, City',
                    icon: Icons.location_on_outlined,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _showExistingCustomerModal,
                      icon: const Icon(
                        Icons.people_alt_outlined,
                        color: kAccent,
                        size: 18,
                      ),
                      label: Text(
                        'Select Existing Customer',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: kAccent,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: kAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kR),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildNavButtons(),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  STEP 2 — Customer Type
  // ─────────────────────────────────────────────────────────────────
  Widget _buildStep2Type() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        children: [
          _SectionCard(
            title: 'Customer Type',
            child: Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: Text(
                      'Adult',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    value: true,
                    groupValue: _isAdult,
                    activeColor: kAccent,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setState(() => _isAdult = v!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: Text(
                      'Child',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    value: false,
                    groupValue: _isAdult,
                    activeColor: kAccent,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setState(() => _isAdult = v!),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildNavButtons(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  STEP 3 — Order Details
  // ─────────────────────────────────────────────────────────────────
  Widget _buildStep3Order() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Form(
        key: _formKey3,
        child: Column(
          children: [
            _SectionCard(
              title: 'General Details',
              child: Column(
                children: [
                  _InputField(
                    controller: _quantityCtrl,
                    label: 'Quantity',
                    hint: '1',
                    icon: Icons.format_list_numbered,
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildDatePickerRow(
                    'Order Date',
                    _orderDate,
                    () => _selectDate(false),
                  ),
                  const SizedBox(height: 16),
                  _buildDatePickerRow(
                    'Delivery Date',
                    _deliveryDate,
                    () => _selectDate(true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SectionCard(
              title: 'Pricing',
              child: Column(
                children: [
                  _InputField(
                    controller: _totalCtrl,
                    label: 'Total Amount (PKR)',
                    hint: '0',
                    icon: Icons.money,
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  _InputField(
                    controller: _advanceCtrl,
                    label: 'Advance Paid (PKR)',
                    hint: '0',
                    icon: Icons.account_balance_wallet_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Remaining Balance',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: kTextPri,
                          ),
                        ),
                        Text(
                          'PKR ${_remainingBalance.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: kAccent,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildNavButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerRow(String label, DateTime? date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: kBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              color: kTextSec,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(fontSize: 12, color: kTextSec),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date != null
                        ? DateFormat('dd MMM, yyyy').format(date)
                        : 'Select date',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: kTextPri,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  STEP 4 — Measurements
  // ─────────────────────────────────────────────────────────────────
  Widget _buildStep4Measurements() {
    final bool isAutoFilled = _selectedCustomer != null;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        children: [
          // ── Auto-fill banner + toggle ──
          if (isAutoFilled) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _measurementsLocked
                    ? kAccent.withValues(alpha: 0.1)
                    : kPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _measurementsLocked
                      ? kAccent.withValues(alpha: 0.3)
                      : kPrimary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _measurementsLocked
                        ? Icons.lock_outline
                        : Icons.edit_outlined,
                    color: _measurementsLocked ? kAccent : kPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _measurementsLocked
                              ? 'Auto-filled from saved data'
                              : 'Edit Mode',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _measurementsLocked ? kAccent : kPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _measurementsLocked
                              ? 'Measurements are locked.'
                              : 'Measurements unlocked.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: _measurementsLocked
                                ? Colors.green.shade700
                                : kTextSec,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: !_measurementsLocked,
                    onChanged: (val) {
                      setState(() {
                        _measurementsLocked = !val;
                      });
                    },
                    activeTrackColor: kPrimary.withValues(alpha: 0.5),
                    inactiveThumbColor: kAccent,
                    inactiveTrackColor: kAccent.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          _SectionCard(
            title: 'Measurements',
            child: Column(
              children: [
                // 1. Length
                _buildCompactMeasureField(
                  'Length',
                  _lengthCtrl,
                  readOnly: _measurementsLocked,
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),

                // 2. Arm + Mundo
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _buildCompactMeasureField(
                        'Arm',
                        _armCtrl,
                        readOnly: _measurementsLocked,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildOptionCheckbox(
                        'Mundo',
                        _optMundo,
                        _measurementsLocked
                            ? null
                            : (v) => setState(() => _optMundo = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),

                // 3. Shoulder
                _buildCompactMeasureField(
                  'Shoulder',
                  _shoulderCtrl,
                  readOnly: _measurementsLocked,
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),

                // 4. Collar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCompactMeasureField(
                      'Collar',
                      _collarCtrl,
                      readOnly: _measurementsLocked,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildOptionCheckbox(
                            'Regular',
                            _colRegular,
                            _measurementsLocked
                                ? null
                                : (v) => setState(() => _colRegular = v),
                          ),
                        ),
                        Expanded(
                          child: _buildOptionCheckbox(
                            'French',
                            _colFrench,
                            _measurementsLocked
                                ? null
                                : (v) => setState(() => _colFrench = v),
                          ),
                        ),
                        Expanded(
                          child: _buildOptionCheckbox(
                            'Sherwani',
                            _colSherwani,
                            _measurementsLocked
                                ? null
                                : (v) => setState(() => _colSherwani = v),
                          ),
                        ),
                      ],
                    ),
                    if (_colSherwani) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text(
                                'Half',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              value: 'Half',
                              groupValue: _sherwaniType,
                              onChanged: _measurementsLocked
                                  ? null
                                  : (v) => setState(() => _sherwaniType = v!),
                              activeColor: kAccent,
                              contentPadding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text(
                                'Full',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              value: 'Full',
                              groupValue: _sherwaniType,
                              onChanged: _measurementsLocked
                                  ? null
                                  : (v) => setState(() => _sherwaniType = v!),
                              activeColor: kAccent,
                              contentPadding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),

                // 5. Chest
                _buildCompactMeasureField(
                  'Chest',
                  _chestCtrl,
                  readOnly: _measurementsLocked,
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),

                // 6. Waist
                _buildCompactMeasureField(
                  'Waist',
                  _waistCtrl,
                  readOnly: _measurementsLocked,
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),

                // 7. Hip
                _buildCompactMeasureField(
                  'Hip',
                  _hipCtrl,
                  readOnly: _measurementsLocked,
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),

                // 8. Shalwar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCompactMeasureField(
                      'Shalwar',
                      _shalwarCtrl,
                      readOnly: _measurementsLocked,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildOptionCheckbox(
                            'Kanto',
                            _shalKanto,
                            _measurementsLocked
                                ? null
                                : (v) => setState(() => _shalKanto = v),
                          ),
                        ),
                        Expanded(
                          child: _buildOptionCheckbox(
                            'Zip Pocket',
                            _shalZipPocket,
                            _measurementsLocked
                                ? null
                                : (v) => setState(() => _shalZipPocket = v),
                          ),
                        ),
                        Expanded(
                          child: _buildOptionCheckbox(
                            'Width',
                            _shalWidth,
                            _measurementsLocked
                                ? null
                                : (v) => setState(() => _shalWidth = v),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),

                // 9. Bottom
                _buildCompactMeasureField(
                  'Bottom',
                  _bottomCtrl,
                  readOnly: _measurementsLocked,
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),

                // 10. Plate
                _buildCompactMeasureField(
                  'Plate',
                  _plateCtrl,
                  readOnly: _measurementsLocked,
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),

                // 11. Front Pocket
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildOptionCheckbox(
                        'Front Pocket',
                        _optFrontPocket,
                        _measurementsLocked
                            ? null
                            : (v) => setState(() => _optFrontPocket = v),
                      ),
                    ),
                    if (_optFrontPocket)
                      Expanded(
                        flex: 1,
                        child: _buildCompactMeasureField(
                          '',
                          _frontPocketCtrl,
                          readOnly: _measurementsLocked,
                        ),
                      )
                    else
                      const Spacer(),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),

                // 12. Side Pocket
                _buildOptionCheckbox(
                  'Side Pocket',
                  _optSidePocket,
                  _measurementsLocked
                      ? null
                      : (v) => setState(() => _optSidePocket = v),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),

                // 13. Cuff
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cuff',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kTextPri,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 0,
                      children: ['Round', 'Double kaj', 'Double', 'Square'].map(
                        (type) {
                          return SizedBox(
                            width: 140,
                            child: RadioListTile<String>(
                              title: Text(
                                type,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              value: type,
                              groupValue: _cuffType,
                              onChanged: _measurementsLocked
                                  ? null
                                  : (v) => setState(() => _cuffType = v!),
                              activeColor: kAccent,
                              contentPadding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          );
                        },
                      ).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),

                // 14. Extra
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Extra',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kTextPri,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _extraCtrl,
                      readOnly: _measurementsLocked,
                      maxLines: 3,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: _measurementsLocked ? kTextSec : kTextPri,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _measurementsLocked
                            ? Colors.grey.shade100
                            : kBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: _measurementsLocked
                                ? Colors.grey.shade300
                                : Colors.grey.shade200,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: kAccent),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          _buildNavButtons(),
        ],
      ),
    );
  }

  Widget _buildCompactMeasureField(
    String label,
    TextEditingController ctrl, {
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kTextPri,
            ),
          ),
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 0,
              ),
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

  Widget _buildOptionCheckbox(
    String title,
    bool value,
    ValueChanged<bool>? onChanged,
  ) {
    return CheckboxListTile(
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: onChanged == null ? kTextSec : kTextPri,
        ),
      ),
      value: value,
      onChanged: onChanged != null ? (v) => onChanged(v!) : null,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      activeColor: kAccent,
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  Shared UI
  // ─────────────────────────────────────────────────────────────────
  Widget _buildNavButtons() {
    return Row(
      children: [
        if (_currentStep > 0) ...[
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: _prevStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kR),
                ),
              ),
              child: Text(
                'Back',
                style: GoogleFonts.inter(fontSize: 16, color: kTextPri),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: kAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kR),
              ),
            ),
            child: Text(
              _currentStep == 3 ? 'Confirm Order' : 'Next Step',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Helper Widgets
// ─────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(kR),
        boxShadow: [
          BoxShadow(
            color: kTextPri.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kPrimary,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool readOnly;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    this.icon,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: kTextPri,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          validator: validator,
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: icon != null
                ? Icon(icon, color: kTextSec, size: 20)
                : null,
            filled: true,
            fillColor: kBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kAccent, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade300),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
