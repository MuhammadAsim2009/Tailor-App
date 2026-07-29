import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../controllers/expense_controller.dart';

// ─────────────────────────────────────────────────────────────────
//  Design System Constants
// ─────────────────────────────────────────────────────────────────
const Color _kPrimary = Color(0xFF1E3A5F);
const Color _kAccent = Color(0xFF10B981);
const Color _kBg = Color(0xFFF8FAFC);
const Color _kCard = Color(0xFFFFFFFF);
const Color _kTextPri = Color(0xFF0F172A);
const Color _kTextSec = Color(0xFF64748B);
const double _kR = 16.0;

// ─────────────────────────────────────────────────────────────────
//  AddExpenseScreen
// ─────────────────────────────────────────────────────────────────
class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  // ── Form Controllers ──
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  final ExpenseController _controller = ExpenseController();

  @override
  void initState() {
    super.initState();
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

  bool get _canSave => _titleCtrl.text.trim().isNotEmpty && _parsedAmount > 0;

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
  void _saveExpense() async {
    if (!_canSave) return;

    await _controller.addExpense(
      title: _titleCtrl.text.trim(),
      category: '',
      amount: _parsedAmount,
      date: _selectedDate,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Expense saved: PKR ${_parsedAmount.toStringAsFixed(0)}',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: _kAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Prominent Amount Display ──
            _buildAmountDisplay(),

            const SizedBox(height: 20),

            // ── 2. Expense Details ──
            _buildSectionCard(
              title: 'Expense Details',
              child: _buildDetailsForm(),
            ),

            const SizedBox(height: 32),

            // ── 3. Save Button ──
            _buildSaveButton(),
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
      backgroundColor: _kCard,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_outlined,
          color: _kPrimary,
          size: 20,
        ),
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
  //  Prominent Amount Display
  // ─────────────────────────────────────────────────────────────────
  Widget _buildAmountDisplay() {
    final hasAmount = _parsedAmount > 0;

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
          // Large amount
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
                    color: hasAmount ? const Color(0xFFEF4444) : _kTextSec,
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: GoogleFonts.inter(
                    fontSize: hasAmount ? 44 : 36,
                    fontWeight: FontWeight.bold,
                    color: hasAmount ? const Color(0xFFEF4444) : _kTextSec,
                  ),
                  child: Text(
                    hasAmount ? _parsedAmount.toStringAsFixed(0) : '0',
                  ),
                ),
              ],
            ),
          ),

          if (hasAmount) ...[
            const SizedBox(height: 8),
            Text(
              'will be recorded as expense',
              style: GoogleFonts.inter(fontSize: 12, color: _kTextSec),
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
            const Icon(
              Icons.calendar_today_outlined,
              color: _kTextSec,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date',
                    style: GoogleFonts.inter(fontSize: 12, color: _kTextSec),
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
            Icon(
              Icons.chevron_right_outlined,
              color: Colors.grey.shade400,
              size: 20,
            ),
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
          prefixIcon: Icon(
            widget.icon,
            color: _focused ? _kAccent : _kTextSec,
            size: 20,
          ),
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
