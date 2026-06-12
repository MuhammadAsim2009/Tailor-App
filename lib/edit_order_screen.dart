import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'customers_screen.dart';

// --- Design System Constants ---
const Color kPrimary = Color(0xFF1E3A5F);
const Color kAccent = Color(0xFF10B981);
const Color kBg = Color(0xFFF8FAFC);
const Color kCard = Color(0xFFFFFFFF);
const Color kTextPri = Color(0xFF0F172A);
const Color kTextSec = Color(0xFF64748B);
const double kR = 16.0;

class EditOrderScreen extends StatefulWidget {
  const EditOrderScreen({super.key});

  @override
  State<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  final PageController _pageController = PageController();
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  int _currentStep = 0;

  // Dummy Pre-filled Data
  final String _customerName = "Ahmed Ali";
  final String _customerPhone = "+92 300 1234567";

  String _status = 'In Progress';
  String _garmentType = '3-Piece Suit';
  String _priority = 'High';
  String _unit = 'inches';

  final TextEditingController _fabricNotesCtrl = TextEditingController(text: 'Navy Blue Worsted Wool, imported. Client provided fabric 4 meters.');
  final TextEditingController _specialNotesCtrl = TextEditingController(text: 'Tight fit on the waist, wide leg pants as per reference image.');
  final TextEditingController _quantityCtrl = TextEditingController(text: '2');
  final TextEditingController _orderDateCtrl = TextEditingController(text: '01 Jun 2026');
  final TextEditingController _deliveryDateCtrl = TextEditingController(text: '12 Jun 2026');

  final TextEditingController _totalAmountCtrl = TextEditingController(text: '5000');
  final TextEditingController _advancePaidCtrl = TextEditingController(text: '2000');

  // Measurements
  final TextEditingController _lenCtrl = TextEditingController(text: '40');
  final TextEditingController _armCtrl = TextEditingController(text: '24');
  final TextEditingController _shouldersCtrl = TextEditingController(text: '18');
  final TextEditingController _collarCtrl = TextEditingController(text: '15.5');
  final TextEditingController _halfSherwaniCtrl = TextEditingController(text: '');
  final TextEditingController _chestCtrl = TextEditingController(text: '42');
  final TextEditingController _waistCtrl = TextEditingController(text: '34');
  final TextEditingController _hipCtrl = TextEditingController(text: '40');
  final TextEditingController _shalwarCtrl = TextEditingController(text: '38');
  final TextEditingController _bottomCtrl = TextEditingController(text: '14');

  bool _optPlate = true;
  bool _optFrontPocket = true;
  bool _optCuff = true;
  bool _optMundho = false;

  double get _totalAmount => double.tryParse(_totalAmountCtrl.text) ?? 0;
  double get _advancePaid => double.tryParse(_advancePaidCtrl.text) ?? 0;
  double get _remainingAmount => _totalAmount - _advancePaid;

  final List<String> _garmentTypes = [
    'Kurta Shalwar',
    '2-Piece Suit',
    '3-Piece Suit',
    'Sherwani',
    'Waistcoat',
    'Formal Pant',
    'Dress Shirt'
  ];

  final List<String> _statuses = [
    'Pending',
    'In Progress',
    'Ready',
    'Delivered'
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _fabricNotesCtrl.dispose();
    _specialNotesCtrl.dispose();
    _quantityCtrl.dispose();
    _orderDateCtrl.dispose();
    _deliveryDateCtrl.dispose();
    _totalAmountCtrl.dispose();
    _advancePaidCtrl.dispose();
    _lenCtrl.dispose();
    _armCtrl.dispose();
    _shouldersCtrl.dispose();
    _collarCtrl.dispose();
    _halfSherwaniCtrl.dispose();
    _chestCtrl.dispose();
    _waistCtrl.dispose();
    _hipCtrl.dispose();
    _shalwarCtrl.dispose();
    _bottomCtrl.dispose();
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
                  onPressed: () {
                    Navigator.pop(context); // Close sheet
                    Navigator.pop(context); // Go back to details/orders
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
                  _customerPhone,
                  style: GoogleFonts.inter(fontSize: 13, color: kTextSec),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CustomerProfileScreen(
                  customer: CustomerModel(
                    id: 'C-001',
                    name: _customerName,
                    phone: _customerPhone,
                    totalOrders: 12,
                    pendingDues: 0,
                  ),
                )),
              );
            },
            child: Text(
              'View Customer',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: kPrimary,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
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
          DropdownButtonFormField<String>(
            initialValue: _garmentType,
            items: _garmentTypes.map((type) {
              return DropdownMenuItem(value: type, child: Text(type));
            }).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _garmentType = v);
            },
            decoration: InputDecoration(
              labelText: 'Garment Type',
              prefixIcon: const Icon(Icons.checkroom_outlined, size: 20),
              filled: true,
              fillColor: kCard,
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
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          Text('Priority', style: GoogleFonts.inter(fontSize: 13, color: kTextSec)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildPriorityOption('Low', kTextSec)),
              const SizedBox(width: 8),
              Expanded(child: _buildPriorityOption('Medium', Colors.orange)),
              const SizedBox(width: 8),
              Expanded(child: _buildPriorityOption('High', Colors.red)),
            ],
          ),
          const SizedBox(height: 16),
          _InputField(
            controller: _fabricNotesCtrl,
            label: 'Fabric Notes',
            icon: Icons.texture_outlined,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityOption(String label, Color color) {
    final isSelected = _priority == label;
    return GestureDetector(
      onTap: () => setState(() => _priority = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : kBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? color : kTextSec,
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Form(
        key: _formKey2,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Editing existing measurements',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.blue[800], fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Measurements',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _UnitChip(label: 'cm', active: _unit == 'cm', onTap: () => setState(() => _unit = 'cm')),
                  const SizedBox(width: 4),
                  _UnitChip(label: 'inches', active: _unit == 'inches', onTap: () => setState(() => _unit = 'inches')),
                ],
              ),
              child: Column(
                children: [
                  _MeasurementRow(label: 'Length', controller: _lenCtrl, unit: _unit),
                  const SizedBox(height: 12),
                  _MeasurementRow(label: 'Arm', controller: _armCtrl, unit: _unit),
                  const SizedBox(height: 12),
                  _MeasurementRow(label: 'Shoulders', controller: _shouldersCtrl, unit: _unit),
                  const SizedBox(height: 12),
                  _MeasurementRow(label: 'Collar', controller: _collarCtrl, unit: _unit),
                  const SizedBox(height: 12),
                  _MeasurementRow(label: 'Half Sherwani', controller: _halfSherwaniCtrl, unit: _unit),
                  const SizedBox(height: 12),
                  _MeasurementRow(label: 'Chest', controller: _chestCtrl, unit: _unit),
                  const SizedBox(height: 12),
                  _MeasurementRow(label: 'Waist', controller: _waistCtrl, unit: _unit),
                  const SizedBox(height: 12),
                  _MeasurementRow(label: 'Hip', controller: _hipCtrl, unit: _unit),
                  const SizedBox(height: 12),
                  _MeasurementRow(label: 'Shalwar', controller: _shalwarCtrl, unit: _unit),
                  const SizedBox(height: 12),
                  _MeasurementRow(label: 'Bottom', controller: _bottomCtrl, unit: _unit),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Additional Options',
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 3.5,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _AnimatedCheckbox(label: 'Plate', checked: _optPlate, onChanged: (v) => setState(() => _optPlate = v)),
                  _AnimatedCheckbox(label: 'Front Pocket', checked: _optFrontPocket, onChanged: (v) => setState(() => _optFrontPocket = v)),
                  _AnimatedCheckbox(label: 'Cuff', checked: _optCuff, onChanged: (v) => setState(() => _optCuff = v)),
                  _AnimatedCheckbox(label: 'Mundho', checked: _optMundho, onChanged: (v) => setState(() => _optMundho = v)),
                ],
              ),
            ),
            const SizedBox(height: 32),
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
      ),
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

class _MeasurementRow extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String unit;

  const _MeasurementRow({
    required this.label,
    required this.controller,
    required this.unit,
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
        Expanded(
          flex: 3,
          child: Text(
            widget.label,
            style: GoogleFonts.inter(fontSize: 14, color: kTextPri, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Focus(
            onFocusChange: (f) => setState(() => _focused = f),
            child: TextFormField(
              controller: widget.controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              style: GoogleFonts.inter(fontSize: 14, color: kTextPri),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: widget.unit,
                hintStyle: GoogleFonts.inter(fontSize: 12, color: kTextSec),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(kR),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(kR),
                  borderSide: const BorderSide(color: kAccent, width: 2),
                ),
                filled: true,
                fillColor: _focused ? kAccent.withValues(alpha: 0.04) : kBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
  final ValueChanged<bool> onChanged;

  const _AnimatedCheckbox({
    required this.label,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!checked),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: checked ? kAccent : Colors.transparent,
              border: Border.all(
                color: checked ? kAccent : kTextSec,
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
                color: checked ? kPrimary : kTextSec,
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
