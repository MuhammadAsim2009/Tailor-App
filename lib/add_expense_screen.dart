import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────
//  Design System Constants
// ─────────────────────────────────────────────────────────────────
const Color _kPrimary  = Color(0xFF1E3A5F);
const Color _kAccent   = Color(0xFF10B981);
const Color _kBg       = Color(0xFFF8FAFC);
const Color _kCard     = Color(0xFFFFFFFF);
const Color _kTextPri  = Color(0xFF0F172A);
const Color _kTextSec  = Color(0xFF64748B);
const double _kR       = 16.0;

// ─────────────────────────────────────────────────────────────────
//  Expense Category Model
// ─────────────────────────────────────────────────────────────────
class _Category {
  final String name;
  final IconData icon;
  final Color color;

  const _Category({
    required this.name,
    required this.icon,
    required this.color,
  });
}

// ─────────────────────────────────────────────────────────────────
//  AddExpenseScreen
// ─────────────────────────────────────────────────────────────────
class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  // ── Category Selection ──
  int? _selectedCategoryIndex;

  final List<_Category> _categories = const [
    _Category(name: 'Rent',        icon: Icons.home_outlined,          color: Color(0xFF3B82F6)),
    _Category(name: 'Electricity', icon: Icons.bolt_outlined,          color: Color(0xFFEAB308)),
    _Category(name: 'Material',    icon: Icons.content_cut_outlined,   color: Color(0xFF8B5CF6)),
    _Category(name: 'Salary',      icon: Icons.person_outline,         color: Color(0xFFF97316)),
    _Category(name: 'Maintenance', icon: Icons.build_outlined,         color: Color(0xFFEF4444)),
    _Category(name: 'Other',       icon: Icons.category_outlined,      color: Color(0xFF64748B)),
  ];

  // ── Form Controllers ──
  final TextEditingController _titleCtrl  = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _notesCtrl  = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Rebuild when title or amount changes (drives _canSave + amount display)
    _amountCtrl.addListener(() => setState(() {}));
    _titleCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Computed Properties ──
  double get _parsedAmount => double.tryParse(_amountCtrl.text) ?? 0.0;

  bool get _canSave =>
      _selectedCategoryIndex != null &&
      _titleCtrl.text.trim().isNotEmpty &&
      _parsedAmount > 0;

  // ── Pick Date ──
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _kAccent,
            onPrimary: Colors.white,
            onSurface: _kPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ── Save Expense ──
  void _saveExpense() {
    if (!_canSave) return;
    // TODO: persist to backend
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Expense saved: PKR ${_parsedAmount.toStringAsFixed(0)}',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: _kAccent,
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
      appBar: _buildAppBar(),
      body: GestureDetector(
        // HitTestBehavior.translucent: dismisses keyboard when user taps
        // empty areas, but does NOT consume taps headed to child widgets.
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          // ClampingScrollPhysics is the Android-native scroll behaviour.
          // BouncingScrollPhysics (iOS style) is aggressive on Android and
          // can cause the gesture arena to misclassify short taps as flings,
          // which is exactly what 'I/ScrollIdentify: on fling' reveals.
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Category Selector ──
              _buildSectionCard(
                title: 'Category',
                child: _buildCategoryGrid(),
              ),

              const SizedBox(height: 20),

              // ── 2. Prominent Amount Display ──
              _buildAmountDisplay(),

              const SizedBox(height: 20),

              // ── 3. Expense Details ──
              _buildSectionCard(
                title: 'Expense Details',
                child: _buildDetailsForm(),
              ),

              const SizedBox(height: 32),

              // ── 4. Save Button ──
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  AppBar
  // ─────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _kCard,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_outlined,
            color: _kPrimary, size: 20),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Text(
        'Add Expense',
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: _kPrimary,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.grey.shade100),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  Section Card wrapper
  // ─────────────────────────────────────────────────────────────────
  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  Category Grid (3 × 2)
  // ─────────────────────────────────────────────────────────────────
  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.92,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, i) {
        final cat        = _categories[i];
        final isSelected = _selectedCategoryIndex == i;

        return Material(
          // Material ensures InkWell splash works + proper hit testing
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(_kR),
          child: InkWell(
            onTap: () => setState(() => _selectedCategoryIndex = i),
            borderRadius: BorderRadius.circular(_kR),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: isSelected
                    ? _kAccent.withValues(alpha: 0.07)
                    : _kBg,
                borderRadius: BorderRadius.circular(_kR),
                border: Border.all(
                  color: isSelected ? _kAccent : Colors.grey.shade200,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  if (!isSelected)
                    BoxShadow(
                      color: _kTextPri.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Stack(
                children: [
                  // ── Main content (rendered first = behind) ──
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? cat.color.withValues(alpha: 0.15)
                                : cat.color.withValues(alpha: 0.1),
                          ),
                          child: Icon(cat.icon, color: cat.color, size: 24),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cat.name,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected ? _kPrimary : _kTextSec,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // ── Checkmark badge (rendered last = on top) ──
                  Positioned(
                    top: 6,
                    right: 6,
                    child: AnimatedScale(
                      scale: isSelected ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: _kAccent,
                        ),
                        child: const Icon(Icons.check,
                            color: Colors.white, size: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  Prominent Amount Display
  // ─────────────────────────────────────────────────────────────────
  Widget _buildAmountDisplay() {
    final hasAmount = _parsedAmount > 0;
    final cat = _selectedCategoryIndex != null
        ? _categories[_selectedCategoryIndex!]
        : null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(_kR),
        boxShadow: [
          BoxShadow(
            color: _kTextPri.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Category label chip
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: cat != null
                ? Container(
                    key: ValueKey(cat.name),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: cat.color.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat.icon, color: cat.color, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          cat.name,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cat.color,
                          ),
                        ),
                      ],
                    ),
                  )
                : Text(
                    key: const ValueKey('placeholder'),
                    'Select a category above',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: _kTextSec),
                  ),
          ),

          const SizedBox(height: 16),

          // Large amount — using AnimatedScale instead of ScaleTransition
          // (ScaleTransition during animation frame 0 could briefly
          //  make the widget invisible and prevent touch events)
          AnimatedScale(
            scale: 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'PKR',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: hasAmount
                        ? const Color(0xFFEF4444)
                        : _kTextSec,
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: GoogleFonts.inter(
                    fontSize: hasAmount ? 44 : 36,
                    fontWeight: FontWeight.bold,
                    color: hasAmount
                        ? const Color(0xFFEF4444)
                        : _kTextSec,
                  ),
                  child: Text(
                    hasAmount
                        ? _parsedAmount.toStringAsFixed(0)
                        : '0',
                  ),
                ),
              ],
            ),
          ),

          if (hasAmount) ...[
            const SizedBox(height: 8),
            Text(
              'will be recorded as expense',
              style: GoogleFonts.inter(
                  fontSize: 12, color: _kTextSec),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  Details Form
  // ─────────────────────────────────────────────────────────────────
  Widget _buildDetailsForm() {
    return Column(
      children: [
        // ── Title field ──
        _ExpenseInputField(
          controller: _titleCtrl,
          label: 'Expense Title',
          hint: 'e.g Rent for June',
          icon: Icons.edit_outlined,
          inputFormatters: [],
        ),

        const SizedBox(height: 16),

        // ── Amount field with PKR prefix ──
        _ExpenseInputField(
          controller: _amountCtrl,
          label: 'Amount',
          hint: '0.00',
          icon: Icons.payments_outlined,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          prefix: Text(
            'PKR  ',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _kTextSec,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Date Picker ──
        _buildDateField(),

        const SizedBox(height: 16),

        // ── Notes field ──
        _ExpenseInputField(
          controller: _notesCtrl,
          label: 'Notes (Optional)',
          hint: 'Additional notes...',
          icon: Icons.notes_outlined,
          maxLines: 4,
          inputFormatters: [],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  Date Field
  // ─────────────────────────────────────────────────────────────────
  Widget _buildDateField() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(_kR),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(_kR),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                color: _kTextSec, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: _kTextSec),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('EEEE, MMM dd yyyy').format(_selectedDate),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kTextPri,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_outlined,
                color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  Save Button
  // ─────────────────────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: _canSave ? _kAccent : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(_kR),
        boxShadow: _canSave
            ? [
                BoxShadow(
                  color: _kAccent.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _canSave ? _saveExpense : null,
          borderRadius: BorderRadius.circular(_kR),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.save_outlined,
                color: _canSave ? Colors.white : Colors.grey.shade500,
                size: 20,
              ),
              const SizedBox(width: 10),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _canSave ? Colors.white : Colors.grey.shade500,
                ),
                child: const Text('Save Expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  _ExpenseInputField — reusable focused input field
// ─────────────────────────────────────────────────────────────────
class _ExpenseInputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final int maxLines;
  final Widget? prefix;

  const _ExpenseInputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.inputFormatters,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.prefix,
  });

  @override
  State<_ExpenseInputField> createState() => _ExpenseInputFieldState();
}

class _ExpenseInputFieldState extends State<_ExpenseInputField> {
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
        style: GoogleFonts.inter(fontSize: 14, color: _kTextPri),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          labelStyle: GoogleFonts.inter(
            color: _focused ? _kAccent : _kTextSec,
            fontSize: 13,
          ),
          hintStyle: GoogleFonts.inter(color: _kTextSec, fontSize: 13),
          prefixIcon: Icon(widget.icon,
              color: _focused ? _kAccent : _kTextSec, size: 20),
          prefix: widget.prefix,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_kR),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_kR),
            borderSide: const BorderSide(color: _kAccent, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_kR),
            borderSide: const BorderSide(color: Colors.red),
          ),
          filled: true,
          fillColor: _focused ? _kAccent.withValues(alpha: 0.02) : _kCard,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
