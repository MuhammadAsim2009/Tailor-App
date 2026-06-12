import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'add_customer_screen.dart';

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
//  Dummy Data Models
// ─────────────────────────────────────────────────────────────────
class DummyCustomer {
  final String id;
  final String name;
  final String phone;
  final Map<String, String>? measurements;
  final Map<String, bool>? options;

  DummyCustomer({
    required this.id,
    required this.name,
    required this.phone,
    this.measurements,
    this.options,
  });
}

// ─────────────────────────────────────────────────────────────────
//  AddOrderScreen — 2-Step Wizard
// ─────────────────────────────────────────────────────────────────
class AddOrderScreen extends StatefulWidget {
  const AddOrderScreen({super.key});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen>
    with SingleTickerProviderStateMixin {
  // ── Step tracking ──
  int _currentStep = 0; // 0 = Order Details, 1 = Measurements
  final PageController _pageController = PageController();

  // ── Step 1: Customer Selection ──
  final List<DummyCustomer> _customers = [
    DummyCustomer(
      id: '1',
      name: 'Ahmed Ali',
      phone: '+92 300 1234567',
      measurements: {
        'Length': '40',
        'Arm': '24',
        'Shoulders': '18',
        'Collar': '15',
        'Half Sherwani': '16',
        'Chest': '38',
        'Waist': '34',
        'Hip': '40',
        'Shalwar': '38',
        'Bottom': '7',
      },
      options: {
        'Plate': true,
        'Front Pocket': true,
        'Cuff': false,
        'Mundho': false,
      },
    ),
    DummyCustomer(
      id: '2',
      name: 'Usman Khan',
      phone: '+92 311 9876543',
      measurements: null, // No saved measurements
    ),
    DummyCustomer(
      id: '3',
      name: 'Bilal Malik',
      phone: '+92 333 4455667',
      measurements: {
        'Length': '38',
        'Arm': '23',
        'Shoulders': '17',
        'Collar': '14.5',
        'Half Sherwani': '15',
        'Chest': '36',
        'Waist': '32',
        'Hip': '38',
        'Shalwar': '36',
        'Bottom': '6.5',
      },
      options: {
        'Plate': false,
        'Front Pocket': false,
        'Cuff': true,
        'Mundho': true,
      },
    ),
  ];

  DummyCustomer? _selectedCustomer;
  final TextEditingController _searchCtrl = TextEditingController();

  // ── Step 1: Order Info ──
  final _formKey1 = GlobalKey<FormState>();
  String? _garmentType;
  final List<String> _garmentTypes = [
    'Shirt',
    'Pant',
    'Suit',
    'Shalwar Kameez',
    'Sherwani',
    'Other'
  ];
  final _fabricNotesCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  DateTime? _orderDate;
  DateTime? _deliveryDate;
  String _priority = 'Medium'; // Low, Medium, High

  // ── Step 1: Pricing ──
  final _totalCtrl = TextEditingController();
  final _advanceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // ── Step 2: Measurements ──
  bool _isInches = false; // false = cm, true = inches
  bool _updateMeasurements = false; // Toggle to allow editing
  bool _hasLoadedMeasurements = false;

  final Map<String, TextEditingController> _measureCtrl = {
    'Length': TextEditingController(),
    'Arm': TextEditingController(),
    'Shoulders': TextEditingController(),
    'Collar': TextEditingController(),
    'Half Sherwani': TextEditingController(),
    'Chest': TextEditingController(),
    'Waist': TextEditingController(),
    'Hip': TextEditingController(),
    'Shalwar': TextEditingController(),
    'Bottom': TextEditingController(),
  };

  final Map<String, bool> _optionsMap = {
    'Plate': false,
    'Front Pocket': false,
    'Cuff': false,
    'Mundho': false,
  };

  @override
  void initState() {
    super.initState();
    // Auto-calculate remaining balance
    _totalCtrl.addListener(_updateBalance);
    _advanceCtrl.addListener(_updateBalance);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchCtrl.dispose();
    _fabricNotesCtrl.dispose();
    _quantityCtrl.dispose();
    _totalCtrl.dispose();
    _advanceCtrl.dispose();
    _notesCtrl.dispose();
    for (final c in _measureCtrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Balance Calculation ──
  double get _remainingBalance {
    final total = double.tryParse(_totalCtrl.text) ?? 0;
    final advance = double.tryParse(_advanceCtrl.text) ?? 0;
    return (total - advance).clamp(0.0, double.infinity);
  }

  void _updateBalance() {
    setState(() {}); // Rebuild to update balance display
  }

  // ── Navigate to Step 2 ──
  void _nextStep() {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a customer first.',
              style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    if (_formKey1.currentState!.validate()) {
      _populateMeasurements();
      setState(() => _currentStep = 1);
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  // ── Populate auto-fill data ──
  void _populateMeasurements() {
    if (_selectedCustomer?.measurements != null) {
      _hasLoadedMeasurements = true;
      _updateMeasurements = false; // Read-only by default
      _selectedCustomer!.measurements!.forEach((key, value) {
        if (_measureCtrl.containsKey(key)) {
          _measureCtrl[key]!.text = value;
        }
      });
      _selectedCustomer!.options?.forEach((key, value) {
        if (_optionsMap.containsKey(key)) {
          _optionsMap[key] = value;
        }
      });
    } else {
      _hasLoadedMeasurements = false;
      _updateMeasurements = true; // Editable by default
      for (final c in _measureCtrl.values) {
        c.clear();
      }
      _optionsMap.updateAll((key, value) => false);
    }
  }

  // ── Navigate back to Step 1 ──
  void _prevStep() {
    setState(() => _currentStep = 0);
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  // ── Confirm Order ──
  void _confirmOrder() {
    // TODO: save to backend
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order created for ${_selectedCustomer?.name}!',
            style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: kAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isDelivery) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: isDelivery ? 7 : 0)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kAccent, // header background color
              onPrimary: Colors.white, // header text color
              onSurface: kPrimary, // body text color
            ),
          ),
          child: child!,
        );
      },
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
            // ── Step indicator ──
            _StepIndicator(currentStep: _currentStep),
            const SizedBox(height: 24),
            // ── Slide between steps ──
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: kCard,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_outlined,
            color: kPrimary, size: 20),
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

  // ─────────────────────────────────────────────────────────────────
  //  STEP 1 — Order Details
  // ─────────────────────────────────────────────────────────────────
  Widget _buildStep1() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Form(
        key: _formKey1,
        child: Column(
          children: [
            // 1. SELECT CUSTOMER
            _SectionCard(
              title: 'Select Customer',
              child: Column(
                children: [
                  _buildSearchField(),
                  const SizedBox(height: 12),
                  _buildCustomerList(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddCustomerScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_add_outlined,
                          color: kAccent, size: 18),
                      label: Text(
                        'Add New Customer',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: kAccent),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: kAccent),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(kR)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 2. ORDER INFO
            _SectionCard(
              title: 'Order Details',
              child: Column(
                children: [
                  _buildDropdownField(),
                  const SizedBox(height: 16),
                  _InputField(
                    controller: _fabricNotesCtrl,
                    label: 'Fabric Notes',
                    hint: 'Color, brand, etc.',
                    icon: Icons.notes_outlined,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _InputField(
                    controller: _quantityCtrl,
                    label: 'Quantity',
                    hint: '1',
                    icon: Icons.numbers_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Quantity required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _DatePickerField(
                          label: 'Order Date',
                          date: _orderDate,
                          onTap: () => _selectDate(context, false),
                          validator: (v) =>
                              _orderDate == null ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DatePickerField(
                          label: 'Delivery Date',
                          date: _deliveryDate,
                          onTap: () => _selectDate(context, true),
                          validator: (v) =>
                              _deliveryDate == null ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPrioritySelector(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 3. PRICING
            _SectionCard(
              title: 'Pricing',
              child: Column(
                children: [
                  _InputField(
                    controller: _totalCtrl,
                    label: 'Total Amount (PKR)',
                    hint: '0',
                    icon: Icons.payments_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Amount required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _InputField(
                    controller: _advanceCtrl,
                    label: 'Advance Paid (PKR)',
                    hint: '0',
                    icon: Icons.money_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 16),
                  _buildRemainingBalance(),
                  const SizedBox(height: 16),
                  _InputField(
                    controller: _notesCtrl,
                    label: 'Special Notes (Optional)',
                    hint: 'Any special requests',
                    icon: Icons.edit_note_outlined,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Next button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _nextStep,
                icon: const Icon(Icons.arrow_forward_outlined,
                    color: Colors.white, size: 18),
                label: Text(
                  'Next',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kR)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchCtrl,
      style: GoogleFonts.inter(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search customer...',
        hintStyle: GoogleFonts.inter(color: kTextSec, fontSize: 13),
        prefixIcon: const Icon(Icons.search, color: kTextSec, size: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kR),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kR),
          borderSide: const BorderSide(color: kAccent, width: 2),
        ),
        filled: true,
        fillColor: kBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      ),
      onChanged: (val) => setState(() {}),
    );
  }

  Widget _buildCustomerList() {
    final filtered = _customers
        .where((c) =>
            c.name.toLowerCase().contains(_searchCtrl.text.toLowerCase()) ||
            c.phone.contains(_searchCtrl.text))
        .toList();

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(kR),
      ),
      child: filtered.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('No customers found',
                    style: GoogleFonts.inter(color: kTextSec, fontSize: 13)),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              itemCount: filtered.length,
              separatorBuilder: (ctx, i) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (ctx, i) {
                final c = filtered[i];
                final isSelected = _selectedCustomer?.id == c.id;
                return InkWell(
                  onTap: () => setState(() => _selectedCustomer = c),
                  borderRadius: i == 0
                      ? const BorderRadius.vertical(top: Radius.circular(kR))
                      : i == filtered.length - 1
                          ? const BorderRadius.vertical(
                              bottom: Radius.circular(kR))
                          : BorderRadius.zero,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    color: isSelected
                        ? kAccent.withValues(alpha: 0.1)
                        : Colors.transparent,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              isSelected ? kAccent : Colors.grey.shade200,
                          child: Text(
                            c.name.substring(0, 1),
                            style: GoogleFonts.inter(
                              color: isSelected ? Colors.white : kTextSec,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.name,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  color: kPrimary,
                                ),
                              ),
                              Text(
                                c.phone,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: kTextSec,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          color: isSelected ? kAccent : kTextSec,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      initialValue: _garmentType,
      items: _garmentTypes.map((type) {
        return DropdownMenuItem(value: type, child: Text(type));
      }).toList(),
      onChanged: (v) => setState(() => _garmentType = v),
      validator: (v) => v == null ? 'Please select a garment type' : null,
      style: GoogleFonts.inter(fontSize: 14, color: kTextPri),
      icon: const Icon(Icons.keyboard_arrow_down, color: kTextSec),
      decoration: InputDecoration(
        labelText: 'Garment Type',
        labelStyle: GoogleFonts.inter(color: kTextSec, fontSize: 13),
        prefixIcon: const Icon(Icons.checkroom_outlined, color: kTextSec, size: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kR),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kR),
          borderSide: const BorderSide(color: kAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kR),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: kCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Priority',
            style: GoogleFonts.inter(fontSize: 13, color: kTextSec)),
        const SizedBox(height: 8),
        Row(
          children: [
            _PriorityChip(
              label: 'Low',
              color: kTextSec,
              isSelected: _priority == 'Low',
              onTap: () => setState(() => _priority = 'Low'),
            ),
            const SizedBox(width: 8),
            _PriorityChip(
              label: 'Medium',
              color: Colors.orange,
              isSelected: _priority == 'Medium',
              onTap: () => setState(() => _priority = 'Medium'),
            ),
            const SizedBox(width: 8),
            _PriorityChip(
              label: 'High',
              color: Colors.red,
              isSelected: _priority == 'High',
              onTap: () => setState(() => _priority = 'High'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRemainingBalance() {
    final bal = _remainingBalance;
    final color = bal > 0 ? Colors.red.shade400 : kAccent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(kR),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Remaining Balance',
            style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w600, color: kTextPri),
          ),
          Text(
            'Rs. ${bal.toStringAsFixed(0)}',
            style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  STEP 2 — Measurements
  // ─────────────────────────────────────────────────────────────────
  Widget _buildStep2() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _hasLoadedMeasurements
                ? _InfoBanner(
                    text: 'Measurements loaded from customer profile.',
                    color: kAccent,
                    icon: Icons.check_circle_outline,
                  )
                : _InfoBanner(
                    text: 'No measurements found, please fill in.',
                    color: Colors.orange,
                    icon: Icons.info_outline,
                  ),
          ),
          const SizedBox(height: 16),
          // ── Measurements card ──
          _SectionCard(
            title: 'Measurements',
            trailing: _buildUnitToggle(),
            child: Column(
              children: [
                if (_hasLoadedMeasurements)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Update Measurements',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: kPrimary)),
                      Switch(
                        value: _updateMeasurements,
                        onChanged: (v) => setState(() => _updateMeasurements = v),
                        activeTrackColor: kAccent,
                        activeThumbColor: Colors.white,
                      ),
                    ],
                  ),
                if (_hasLoadedMeasurements) const SizedBox(height: 16),
                ..._measureCtrl.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MeasurementRow(
                      label: entry.key,
                      controller: entry.value,
                      unit: _isInches ? 'in' : 'cm',
                      readOnly: !_updateMeasurements,
                      onChanged: () => setState(() {}),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ── Additional Options card ──
          _SectionCard(
            title: 'Additional Options',
            child: _buildCheckboxGrid(),
          ),
          const SizedBox(height: 28),
          // ── Bottom Buttons ──
          Row(
            children: [
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _prevStep,
                    icon: const Icon(Icons.arrow_back_outlined,
                        color: kPrimary, size: 18),
                    label: Text(
                      'Back',
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: kPrimary),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: kPrimary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kR)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _confirmOrder,
                    icon: const Icon(Icons.check_circle_outline,
                        color: Colors.white, size: 18),
                    label: Text(
                      'Confirm Order',
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kR)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnitToggle() {
    return Container(
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _UnitChip(
            label: 'cm',
            active: !_isInches,
            onTap: () => setState(() => _isInches = false),
          ),
          _UnitChip(
            label: 'in',
            active: _isInches,
            onTap: () => setState(() => _isInches = true),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxGrid() {
    final keys = _optionsMap.keys.toList();
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3.8,
      children: keys.map((key) {
        return _AnimatedCheckbox(
          label: key,
          checked: _optionsMap[key]!,
          readOnly: !_updateMeasurements,
          onChanged: (val) {
            if (!_updateMeasurements) return;
            setState(() {
              _optionsMap[key] = val;
            });
          },
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Reusable Widgets below (similar to AddCustomer)
// ─────────────────────────────────────────────────────────────────

class _PriorityChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PriorityChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kR),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : kBg,
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(kR),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : kTextSec,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final FormFieldValidator<String>? validator;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onTap,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: IgnorePointer(
        child: TextFormField(
          key: ValueKey(date),
          initialValue: date != null ? DateFormat('MMM dd, yyyy').format(date!) : null,
          validator: validator,
          style: GoogleFonts.inter(fontSize: 14, color: kTextPri),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.inter(color: kTextSec, fontSize: 13),
            hintText: 'Select',
            hintStyle: GoogleFonts.inter(color: kTextSec, fontSize: 13),
            prefixIcon:
                const Icon(Icons.calendar_today_outlined, color: kTextSec, size: 20),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kR),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kR),
              borderSide: const BorderSide(color: Colors.red),
            ),
            filled: true,
            fillColor: kCard,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const _InfoBanner({
    required this.text,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(kR),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
                  ? const Icon(Icons.check,
                      color: Colors.white, size: 20, key: ValueKey('check'))
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
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kPrimary,
                      ),
                    ),
                  ],
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
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final int maxLines;
  final String? Function(String?)? validator;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.inputFormatters = const [],
    this.maxLines = 1,
    this.validator,
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
        validator: widget.validator,
        style: GoogleFonts.inter(fontSize: 14, color: kTextPri),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          labelStyle: GoogleFonts.inter(
            color: _focused ? kAccent : kTextSec,
            fontSize: 13,
          ),
          hintStyle: GoogleFonts.inter(color: kTextSec, fontSize: 13),
          prefixIcon: Icon(widget.icon,
              color: _focused ? kAccent : kTextSec, size: 20),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kR),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kR),
            borderSide: const BorderSide(color: kAccent, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kR),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kR),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: kCard,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _MeasurementRow extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String unit;
  final bool readOnly;
  final VoidCallback onChanged;

  const _MeasurementRow({
    required this.label,
    required this.controller,
    required this.unit,
    this.readOnly = false,
    required this.onChanged,
  });

  @override
  State<_MeasurementRow> createState() => _MeasurementRowState();
}

class _MeasurementRowState extends State<_MeasurementRow> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Label
        Expanded(
          flex: 3,
          child: Text(
            widget.label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: widget.readOnly ? kTextSec : kTextPri,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Number input
        Expanded(
          flex: 2,
          child: Focus(
            onFocusChange: (f) {
              if (!widget.readOnly) setState(() => _focused = f);
            },
            child: TextFormField(
              controller: widget.controller,
              readOnly: widget.readOnly,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
              ],
              onChanged: (_) => widget.onChanged(),
              style: GoogleFonts.inter(
                  fontSize: 14, color: widget.readOnly ? kTextSec : kTextPri),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: widget.unit,
                hintStyle: GoogleFonts.inter(fontSize: 12, color: kTextSec),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(kR),
                  borderSide: BorderSide(
                      color: widget.readOnly
                          ? Colors.grey.shade100
                          : Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(kR),
                  borderSide: BorderSide(
                      color: widget.readOnly ? Colors.grey.shade200 : kAccent,
                      width: widget.readOnly ? 1 : 2),
                ),
                filled: true,
                fillColor: widget.readOnly
                    ? Colors.grey.shade50
                    : (_focused ? kAccent.withValues(alpha: 0.04) : kBg),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedCheckbox extends StatelessWidget {
  final String label;
  final bool checked;
  final bool readOnly;
  final ValueChanged<bool> onChanged;

  const _AnimatedCheckbox({
    required this.label,
    required this.checked,
    this.readOnly = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: readOnly ? null : () => onChanged(!checked),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: checked
                  ? (readOnly ? Colors.grey.shade400 : kAccent)
                  : Colors.transparent,
              border: Border.all(
                color: checked
                    ? (readOnly ? Colors.grey.shade400 : kAccent)
                    : (readOnly ? Colors.grey.shade300 : kTextSec),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: AnimatedOpacity(
              opacity: checked ? 1 : 0,
              duration: const Duration(milliseconds: 150),
              child: const Icon(Icons.check, color: Colors.white, size: 14),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: checked ? (readOnly ? kTextSec : kPrimary) : kTextSec,
                fontWeight: checked ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _UnitChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? kAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : kTextSec,
          ),
        ),
      ),
    );
  }
}
