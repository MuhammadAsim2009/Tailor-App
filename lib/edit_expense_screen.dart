import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../controllers/expense_controller.dart';
import '../controllers/order_controller.dart';
import '../controllers/wallet_controller.dart';
import '../models/expense_model.dart';

// ─────────────────────────────────────────────────────────────────
//  Design System Constants (private to this file)
// ─────────────────────────────────────────────────────────────────
const Color _kPrimary  = Color(0xFF1E3A5F);
const Color _kAccent   = Color(0xFF10B981);
const Color _kBg       = Color(0xFFF8FAFC);
const Color _kCard     = Color(0xFFFFFFFF);
const Color _kTextPri  = Color(0xFF0F172A);
const Color _kTextSec  = Color(0xFF64748B);
const Color _kRed      = Color(0xFFEF4444);
const double _kR       = 16.0;

// ─────────────────────────────────────────────────────────────────
//  EditExpenseScreen
// ─────────────────────────────────────────────────────────────────
class EditExpenseScreen extends StatefulWidget {
  final String  expenseId;
  final String  expenseTitle;
  final double  expenseAmount;
  final String  expenseCategory;
  final DateTime expenseDate;
  final String  expenseNotes;
  final String  expenseWalletSource;

  const EditExpenseScreen({
    super.key,
    required this.expenseId,
    required this.expenseTitle,
    required this.expenseAmount,
    required this.expenseCategory,
    required this.expenseDate,
    required this.expenseNotes,
    this.expenseWalletSource = 'shop',
  });

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  late DateTime _selectedDate;
  late String _walletSource;

  // ── Form controllers — pre-filled with existing data ──
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _notesCtrl;

  final ExpenseController _controller = ExpenseController();
  final OrderController _orderController = OrderController();
  final WalletController _walletController = WalletController.instance;

  @override
  void initState() {
    super.initState();

    _titleCtrl  = TextEditingController(text: widget.expenseTitle);
    _amountCtrl = TextEditingController(text: widget.expenseAmount.toStringAsFixed(0));
    _notesCtrl  = TextEditingController(text: widget.expenseNotes);
    _selectedDate = widget.expenseDate;
    _walletSource = widget.expenseWalletSource;

    _amountCtrl.addListener(() => setState(() {}));
    _titleCtrl.addListener(() => setState(() {}));
    _walletController.loadTransactions();
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  double get _shopProfitBalance {
    final now = DateTime.now();
    final todayCollected = _orderController.payments
        .where((p) => _isSameDay(p.paidAt, now))
        .fold<double>(0, (sum, p) => sum + p.amount);
    final todayShopExpenses = _controller.expenses
        .where((e) => _isSameDay(e.date, now) && e.walletSource != 'other')
        .fold<double>(0, (sum, e) => sum + e.amount);
    return todayCollected - todayShopExpenses;
  }

  double get _otherWalletBalance => _walletController.balance;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Computed helpers ──
  double get _parsedAmount => double.tryParse(_amountCtrl.text) ?? 0.0;

  bool get _canSave =>
      _titleCtrl.text.trim().isNotEmpty &&
      _parsedAmount > 0;

  // ── Date picker ──
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

  // ── Save confirmation bottom sheet ──
  void _showSaveConfirmation() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SaveConfirmationSheet(
        onConfirm: () async {
          Navigator.pop(context); // close sheet

          final updatedExpense = ExpenseModel(
            id: widget.expenseId,
            title: _titleCtrl.text.trim(),
            category: widget.expenseCategory, // preserve existing category
            amount: _parsedAmount,
            date: _selectedDate,
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
            walletSource: _walletSource,
          );
          await _controller.updateExpense(updatedExpense);

          if (mounted) {
            Navigator.pop(context, true); // close edit screen
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Expense updated successfully',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
                backgroundColor: _kAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
        onCancel: () => Navigator.pop(context),
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
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
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

              const SizedBox(height: 16),

              // ── 3. Payment Source ──
              _buildSectionCard(
                title: 'Payment Source',
                child: Column(
                  children: [
                    _buildSourceTile(
                      value: 'shop',
                      title: 'Shop Profit',
                      subtitle: 'Deducted from daily shop revenue',
                      balance: _shopProfitBalance,
                      icon: Icons.storefront_outlined,
                      activeColor: _kPrimary,
                    ),
                    const SizedBox(height: 10),
                    _buildSourceTile(
                      value: 'other',
                      title: 'Other Wallet',
                      subtitle: 'Deducted from your other wallet balance',
                      balance: _otherWalletBalance,
                      icon: Icons.account_balance_wallet_outlined,
                      activeColor: _kAccent,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── 4. Bottom Buttons ──
              _buildBottomButtons(),
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
        icon: const Icon(Icons.arrow_back_ios_new_outlined, color: _kPrimary, size: 20),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Text(
        'Edit Expense',
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

  Widget _buildSourceTile({
    required String value,
    required String title,
    required String subtitle,
    required double balance,
    required IconData icon,
    required Color activeColor,
  }) {
    final isSelected = _walletSource == value;
    final formattedBalance = NumberFormat('#,##0').format(balance.abs().toInt());
    final isNegative = balance < 0;
    final balanceColor = balance >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return InkWell(
      onTap: () => setState(() => _walletSource = value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? activeColor.withValues(alpha: 0.12) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? activeColor : _kTextSec,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: _kTextPri,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: balanceColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${isNegative ? '-' : ''}PKR $formattedBalance',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: balanceColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Balance: ${isNegative ? '-' : ''}PKR $formattedBalance • $subtitle',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: _kTextSec,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? activeColor : Colors.grey.shade400,
                  width: 2,
                ),
                color: isSelected ? activeColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.check, size: 13, color: Colors.white),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  Prominent Amount Display — live update as user types
  // ─────────────────────────────────────────────────────────────────
  Widget _buildAmountDisplay() {
    final hasAmount = _parsedAmount > 0;

    return Container(
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
          // Large PKR amount
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: hasAmount ? _kRed : _kTextSec,
                ),
                child: const Text('PKR'),
              ),
              const SizedBox(width: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.inter(
                  fontSize: hasAmount ? 44 : 36,
                  fontWeight: FontWeight.bold,
                  color: hasAmount ? _kRed : _kTextSec,
                ),
                child: Text(
                  hasAmount ? _parsedAmount.toStringAsFixed(0) : '0',
                ),
              ),
            ],
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
  //  Details Form — all pre-filled
  // ─────────────────────────────────────────────────────────────────
  Widget _buildDetailsForm() {
    return Column(
      children: [
        _EditInputField(
          controller: _titleCtrl,
          label: 'Expense Title',
          hint: 'e.g Rent for June',
          icon: Icons.edit_outlined,
        ),
        const SizedBox(height: 16),
        _EditInputField(
          controller: _amountCtrl,
          label: 'Amount',
          hint: '0.00',
          icon: Icons.payments_outlined,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          prefix: Text(
            'PKR  ',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: _kTextSec),
          ),
        ),
        const SizedBox(height: 16),
        _buildDateField(),
        const SizedBox(height: 16),
        _EditInputField(
          controller: _notesCtrl,
          label: 'Notes (Optional)',
          hint: 'Additional notes...',
          icon: Icons.notes_outlined,
          maxLines: 4,
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
            const Icon(Icons.calendar_today_outlined, color: _kTextSec, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date', style: GoogleFonts.inter(fontSize: 12, color: _kTextSec)),
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
            Icon(Icons.chevron_right_outlined, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  Bottom Buttons: Cancel + Save Changes
  // ─────────────────────────────────────────────────────────────────
  Widget _buildBottomButtons() {
    return Column(
      children: [
        // ── Save Changes ──
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: _canSave ? _kAccent : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(_kR),
            boxShadow: _canSave
                ? [BoxShadow(color: _kAccent.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _canSave ? _showSaveConfirmation : null,
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
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── Cancel ──
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () => Navigator.maybePop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _kPrimary, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kR)),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _kPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  _EditInputField — focus-aware text field
// ─────────────────────────────────────────────────────────────────
class _EditInputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final int maxLines;
  final Widget? prefix;

  const _EditInputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.inputFormatters = const [],
    this.maxLines = 1,
    this.prefix,
  });

  @override
  State<_EditInputField> createState() => _EditInputFieldState();
}

class _EditInputFieldState extends State<_EditInputField> {
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
          prefixIcon: Icon(widget.icon, color: _focused ? _kAccent : _kTextSec, size: 20),
          prefix: widget.prefix,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_kR),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_kR),
            borderSide: const BorderSide(color: _kAccent, width: 2),
          ),
          filled: true,
          fillColor: _focused ? _kAccent.withValues(alpha: 0.02) : _kCard,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  _SaveConfirmationSheet
// ─────────────────────────────────────────────────────────────────
class _SaveConfirmationSheet extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _SaveConfirmationSheet({
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24, 24, 24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: const BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 24),

          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kAccent.withValues(alpha: 0.1),
            ),
            child: const Icon(Icons.save_outlined, color: _kAccent, size: 32),
          ),

          const SizedBox(height: 16),

          Text(
            'Save Changes?',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _kTextPri,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'This will update the expense details.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: _kTextSec),
          ),

          const SizedBox(height: 32),

          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAccent,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kR)),
              ),
              child: Text(
                'Confirm',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Cancel button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _kPrimary, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kR)),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _kPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
