import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────
//  Design System Constants
// ─────────────────────────────────────────────────────────────────
const Color kPrimary    = Color(0xFF1E3A5F);
const Color kAccent     = Color(0xFF10B981);
const Color kBg         = Color(0xFFF8FAFC);
const Color kCard       = Color(0xFFFFFFFF);
const Color kTextPri    = Color(0xFF0F172A);
const Color kTextSec    = Color(0xFF64748B);
const double kR         = 16.0;

// ─────────────────────────────────────────────────────────────────
//  AddCustomerScreen — 2-Step Wizard
// ─────────────────────────────────────────────────────────────────
class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen>
    with SingleTickerProviderStateMixin {
  // ── Step tracking ──
  int _currentStep = 0; // 0 = Biodata, 1 = Measurements

  // ── Page controller for slide animation ──
  final PageController _pageController = PageController();

  // ── Step 1 controllers + form key ──
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addrCtrl  = TextEditingController();

  // ── Step 2: measurement unit toggle ──
  bool _isInches = false; // false = cm, true = inches

  // ── Step 2: 10 measurement fields ──
  final Map<String, TextEditingController> _measureCtrl = {
    'Length'       : TextEditingController(),
    'Arm'          : TextEditingController(),
    'Shoulders'    : TextEditingController(),
    'Collar'       : TextEditingController(),
    'Half Sherwani': TextEditingController(),
    'Chest'        : TextEditingController(),
    'Waist'        : TextEditingController(),
    'Hip'          : TextEditingController(),
    'Shalwar'      : TextEditingController(),
    'Bottom'       : TextEditingController(),
  };

  // ── Step 2: 4 additional option checkboxes ──
  final Map<String, bool> _options = {
    'Plate'       : false,
    'Front Pocket': false,
    'Cuff'        : false,
    'Mundho'      : false,
  };

  // ── Derived: is any measurement/checkbox filled? ──
  bool get _hasMeasurements {
    final anyField = _measureCtrl.values
        .any((c) => c.text.trim().isNotEmpty);
    final anyCheck = _options.values.any((v) => v);
    return anyField || anyCheck;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addrCtrl.dispose();
    for (final c in _measureCtrl.values) { c.dispose(); }
    super.dispose();
  }

  // ── Navigate to Step 2 ──
  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      setState(() => _currentStep = 1);
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
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

  // ── Save (with or without measurements) ──
  void _save({bool skip = false}) {
    // TODO: wire to backend / state management
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          skip
              ? '${_nameCtrl.text} added (no measurements)'
              : '${_nameCtrl.text} added with measurements',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: kAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Dismiss keyboard on tap outside any field
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

  // ─────────────────────────────────────────────────────────────────
  //  AppBar
  // ─────────────────────────────────────────────────────────────────
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
        'Add Customer',
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
  //  STEP 1 — Customer Biodata
  // ─────────────────────────────────────────────────────────────────
  Widget _buildStep1() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Form(
        key: _formKey,
        child: _SectionCard(
          title: 'Customer Info',
          child: Column(
            children: [
              // Full Name
              _InputField(
                controller: _nameCtrl,
                label: 'Full Name',
                hint: 'e.g. Ahmed Ali',
                icon: Icons.person_outline,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              // Phone Number
              _InputField(
                controller: _phoneCtrl,
                label: 'Phone Number',
                hint: '+92 300 1234567',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9 +]'))
                ],
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Phone is required' : null,
              ),
              const SizedBox(height: 16),
              // Address
              _InputField(
                controller: _addrCtrl,
                label: 'Address',
                hint: 'Street, City',
                icon: Icons.location_on_outlined,
                maxLines: 3,
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
          // ── Measurements card ──
          _SectionCard(
            title: 'Measurements',
            subtitle: 'Optional — you can skip for now',
            trailing: _buildUnitToggle(),
            child: Column(
              children: _measureCtrl.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MeasurementRow(
                    label: entry.key,
                    controller: entry.value,
                    unit: _isInches ? 'in' : 'cm',
                    onChanged: () => setState(() {}),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          // ── Additional Options card ──
          _SectionCard(
            title: 'Additional Options',
            child: _buildCheckboxGrid(),
          ),
          const SizedBox(height: 28),
          // ── Smart buttons ──
          _buildBottomButtons(),
        ],
      ),
    );
  }

  // ── cm / inches toggle ──
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

  // ── 2×2 checkbox grid ──
  Widget _buildCheckboxGrid() {
    final keys = _options.keys.toList();
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
          checked: _options[key]!,
          onChanged: (val) => setState(() {
            _options[key] = val;
          }),
        );
      }).toList(),
    );
  }

  // ── Smart bottom buttons: fade between Skip / Save ──
  Widget _buildBottomButtons() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: _hasMeasurements
          ? _SaveButtons(key: const ValueKey('save'), onBack: _prevStep,
              onSave: () => _save())
          : _SkipButtons(key: const ValueKey('skip'), onBack: _prevStep,
              onSkip: () => _save(skip: true)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  _StepIndicator — numbered circles + connecting line
// ─────────────────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          _StepCircle(index: 0, currentStep: currentStep, label: 'Customer Details'),
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
          _StepCircle(
              index: 1, currentStep: currentStep, label: 'Measurements'),
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
    final isActive    = currentStep == index;

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
                  ? const Icon(Icons.check, color: Colors.white, size: 20,
                      key: ValueKey('check'))
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
            fontWeight:
                isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? kPrimary : kTextSec,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  _SectionCard — white rounded card wrapper
// ─────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  const _SectionCard({
    required this.title,
    this.subtitle,
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
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: kTextSec),
                      ),
                    ],
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

// ─────────────────────────────────────────────────────────────────
//  _InputField — single outlined text field
// ─────────────────────────────────────────────────────────────────
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
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  _MeasurementRow — label left + number input right
// ─────────────────────────────────────────────────────────────────
class _MeasurementRow extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String unit;
  final VoidCallback onChanged;

  const _MeasurementRow({
    required this.label,
    required this.controller,
    required this.unit,
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
              color: kTextPri,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Number input
        Expanded(
          flex: 2,
          child: Focus(
            onFocusChange: (f) => setState(() => _focused = f),
            child: TextFormField(
              controller: widget.controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
              ],
              onChanged: (_) => widget.onChanged(),
              style: GoogleFonts.inter(fontSize: 14, color: kTextPri),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: widget.unit,
                hintStyle: GoogleFonts.inter(
                    fontSize: 12, color: kTextSec),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(kR),
                  borderSide:
                      BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(kR),
                  borderSide:
                      const BorderSide(color: kAccent, width: 2),
                ),
                filled: true,
                fillColor: _focused
                    ? kAccent.withValues(alpha: 0.04)
                    : kBg,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  _AnimatedCheckbox — custom animated checkbox with label
// ─────────────────────────────────────────────────────────────────
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
              child: const Icon(Icons.check,
                  color: Colors.white, size: 14),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: checked ? kPrimary : kTextSec,
                fontWeight:
                    checked ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  _UnitChip — cm / inches toggle chip
// ─────────────────────────────────────────────────────────────────
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
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

// ─────────────────────────────────────────────────────────────────
//  _SaveButtons — shown when measurements are present
// ─────────────────────────────────────────────────────────────────
class _SaveButtons extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onSave;

  const _SaveButtons({super.key, required this.onBack, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save_outlined,
                color: Colors.white, size: 18),
            label: Text(
              'Save with Measurements',
              style: GoogleFonts.inter(
                  fontSize: 15,
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
        const SizedBox(height: 12),
        _BackButton(onTap: onBack),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  _SkipButtons — shown when measurements are empty
// ─────────────────────────────────────────────────────────────────
class _SkipButtons extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onSkip;

  const _SkipButtons({super.key, required this.onBack, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: onSkip,
            icon: const Icon(Icons.skip_next_outlined,
                color: kTextSec, size: 18),
            label: Text(
              'Skip for Now',
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: kTextSec),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kR)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _BackButton(onTap: onBack),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  _BackButton — shared outlined back button
// ─────────────────────────────────────────────────────────────────
class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onTap,
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
    );
  }
}
