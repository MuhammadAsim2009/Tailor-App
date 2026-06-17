import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tailor_icon.dart';
import 'controllers/profile_controller.dart';
import 'models/profile_model.dart';
import 'services/backup_export_service.dart';
import 'controllers/order_controller.dart';
import 'controllers/expense_controller.dart';
const Color kPrimaryColor = Color(0xFF1E3A5F);
const Color kAccentColor = Color(0xFF10B981);
const Color kBackgroundColor = Color(0xFFF8FAFC);
const Color kTextPrimary = Color(0xFF0F172A);
const Color kTextSecondary = Color(0xFF64748B);

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  final ProfileController _profileController = ProfileController();
  final OrderController _orderController = OrderController();
  final ExpenseController _expenseController = ExpenseController();

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _profileController.addListener(_onStateChanged);
    _orderController.addListener(_onStateChanged);
    _expenseController.addListener(_onStateChanged);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _profileController.removeListener(_onStateChanged);
    _orderController.removeListener(_onStateChanged);
    _expenseController.removeListener(_onStateChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _showLogoutDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) => Container(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: animation,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.white,
              title: Text(
                'Logout?',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              content: Text(
                'Are you sure you want to logout?',
                style: GoogleFonts.inter(color: kTextSecondary),
                textAlign: TextAlign.center,
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: kTextSecondary),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(color: kTextPrimary),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    // Add logout logic here
                  },
                  child: Text(
                    'Logout',
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditProfileSheet() {
    final profile = _profileController.profile;
    if (profile == null) return;
    
    final shopNameController = TextEditingController(text: profile.shopName);
    final ownerNameController = TextEditingController(text: profile.ownerName);
    final phoneController = TextEditingController(text: profile.phone);
    final addressController = TextEditingController(text: profile.address);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Edit Shop Profile',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildTextField('Shop Name', shopNameController),
                const SizedBox(height: 16),
                _buildTextField('Owner Name', ownerNameController),
                const SizedBox(height: 16),
                _buildTextField('Contact Number', phoneController),
                const SizedBox(height: 16),
                _buildTextField('Address', addressController),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final updated = ProfileModel(
                      id: profile.id,
                      shopName: shopNameController.text,
                      ownerName: ownerNameController.text,
                      phone: phoneController.text,
                      address: addressController.text,
                    );
                    await _profileController.updateProfile(updated);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text(
                    'Save Changes',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: kTextSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kTextSecondary.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kTextSecondary.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      style: GoogleFonts.inter(color: kTextPrimary),
    );
  }

  void _showBackupSheet() {
    _showGenericSheet(
      title: 'Backup Data',
      description:
          'Securely save your orders, customers, and measurements to the local storage.',
      actionLabel: 'Backup Now',
      icon: Icons.cloud_upload_outlined,
      onAction: () async {
        Navigator.pop(context);
        await BackupExportService.createBackup(context);
      },
    );
  }

  void _showExportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Export Data',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildExportOption(
                  ctx,
                  Icons.picture_as_pdf_outlined,
                  'Export as PDF',
                  Colors.red,
                  'Generates a PDF document',
                  () async {
                    Navigator.pop(ctx);
                    await BackupExportService.exportToPDF(context);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExportOption(
    BuildContext ctx,
    IconData icon,
    String label,
    Color color,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: kTextSecondary.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kTextPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: kTextSecondary,
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

  void _showSupportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Help & Support',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildSupportItem(
                  Icons.call_outlined,
                  'Call Us',
                  '+92 302 3476605',
                ),
                const SizedBox(height: 16),
                _buildSupportItem(
                  Icons.email_outlined,
                  'Email',
                  'infotryunity@gmail.com',
                ),
                const SizedBox(height: 16),
                _buildSupportItem(
                  Icons.help_outline,
                  'FAQs',
                  'Read frequently asked questions',
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSupportItem(IconData icon, String title, String subtitle) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: kPrimaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kTextPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: kTextSecondary,
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

  void _showRateSheet() {
    _showGenericSheet(
      title: 'Rate App',
      description: 'Are you enjoying the ${ProfileController().profile?.shopName ?? 'Tailor App'} app? Let us know!',
      actionLabel: 'Submit 5 Stars ⭐',
      icon: Icons.star_border,
      iconColor: Colors.amber,
    );
  }

  void _showGenericSheet({
    required String title,
    required String description,
    required String actionLabel,
    required IconData icon,
    Color iconColor = kPrimaryColor,
    VoidCallback? onAction,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(icon, size: 64, color: iconColor),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: GoogleFonts.inter(fontSize: 16, color: kTextSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (onAction != null) {
                      onAction();
                    } else {
                      Navigator.pop(ctx);
                    }
                  },
                  child: Text(
                    actionLabel,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          backgroundColor: kBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_outlined, color: kPrimaryColor),
            onPressed: () => Navigator.pop(context),
            splashRadius: 24,
          ),
          title: Text(
            'Profile & Settings',
            style: GoogleFonts.inter(
              color: kPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 2. SHOP PROFILE CARD
              _buildProfileCard(),
              const SizedBox(height: 24),

              // 3. QUICK STATS ROW
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      Icons.shopping_bag_outlined,
                      'Orders',
                      '${_orderController.orders.length}',
                      kPrimaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      Icons.people_outline,
                      'Customers',
                      '${_orderController.customers.length}',
                      kAccentColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      Icons.account_balance_wallet_outlined,
                      'Revenue',
                      '${_orderController.orders.fold<double>(0, (sum, o) => sum + (o.status == 'Delivered' ? o.totalAmount : o.advancePaid)) - _expenseController.expenses.fold<double>(0, (sum, e) => sum + e.amount)}',
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 4. SETTINGS SECTIONS
              _buildSectionTitle('Data'),
              _buildSettingsCard([
                _buildSettingsItem(
                  icon: Icons.save_outlined,
                  label: 'Backup Data',
                  subtitle: 'Save your data securely',
                  onTap: _showBackupSheet,
                ),
                _buildSettingsItem(
                  icon: Icons.file_upload_outlined,
                  label: 'Export Data',
                  subtitle: 'Export as Excel or PDF',
                  onTap: _showExportSheet,
                  showDivider: false,
                ),
              ]),
              const SizedBox(height: 24),

              _buildSectionTitle('Support'),
              _buildSettingsCard([
                _buildSettingsItem(
                  icon: Icons.help_outline,
                  label: 'Help & Support',
                  subtitle: 'FAQs and contact us',
                  onTap: _showSupportSheet,
                ),
                _buildSettingsItem(
                  icon: Icons.star_outline,
                  label: 'Rate App',
                  subtitle: 'Share your feedback',
                  onTap: _showRateSheet,
                  showDivider: false,
                ),
              ]),
              const SizedBox(height: 24),

              _buildSectionTitle('Account'),
              _buildSettingsCard([
                _buildSettingsItem(
                  icon: Icons.logout_outlined,
                  label: 'Logout',
                  iconColor: const Color(0xFFEF4444),
                  labelColor: const Color(0xFFEF4444),
                  hideSubtitle: true,
                  onTap: _showLogoutDialog,
                  showDivider: false,
                ),
              ]),
              const SizedBox(height: 48), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    if (_profileController.isLoading || _profileController.profile == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final profile = _profileController.profile!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: kAccentColor, width: 3),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: CustomPaint(
                        painter: TailorLineArtPainter(
                          primaryColor: Colors.white,
                          accentColor: kAccentColor,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  profile.shopName,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.ownerName,
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '${profile.phone} • ${profile.address}',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              onPressed: _showEditProfileSheet,
              tooltip: 'Edit Profile',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kTextPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              color: kTextPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(color: kTextSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: kTextSecondary,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kTextPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: items),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String label,
    String? subtitle,
    bool hideSubtitle = false,
    Color iconColor = kPrimaryColor,
    Color labelColor = kTextPrimary,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          color: labelColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (!hideSubtitle && subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            color: kTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: kTextSecondary.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
          if (showDivider)
            Padding(
              padding: const EdgeInsets.only(left: 56, right: 16),
              child: Divider(
                color: kTextSecondary.withValues(alpha: 0.1),
                height: 1,
              ),
            ),
        ],
      ),
    );
  }
}
