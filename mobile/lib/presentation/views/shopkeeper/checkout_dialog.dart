import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../view_models/pos_view_model.dart';
import '../../view_models/customer_view_model.dart';
import '../../view_models/app_mode_view_model.dart';
import '../../../l10n/app_localizations.dart';
import 'receipt_view.dart';

class CheckoutDialog extends StatefulWidget {
  final String? initialMode;

  const CheckoutDialog({super.key, this.initialMode});

  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<CheckoutDialog> {
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  String? _customerError;

  @override
  void initState() {
    super.initState();
    final posVm = context.read<PosViewModel>();
    if (widget.initialMode == 'due') {
      posVm.setPaymentMode(PaymentMode.credit);
      posVm.setCashReceived(0.0);
      _cashController.text = '0';
    } else {
      _cashController.text = posVm.cashReceived.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _cashController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posVm = context.watch<PosViewModel>();
    final customerVm = context.watch<CustomerViewModel>();
    final appMode = context.watch<AppModeViewModel>();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final changeReturn = posVm.cashReceived > posVm.grandTotal
        ? posVm.cashReceived - posVm.grandTotal
        : 0.0;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: isDark ? const BorderSide(color: AppConstants.borderInteractiveDark, width: 1) : BorderSide.none,
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: isDark ? AppConstants.surfaceOverlayDark : Colors.white,
      child: SafeArea(
        top: false,
        bottom: true,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFEAEDFF),
                        borderRadius: BorderRadius.circular(12),
                        border: isDark ? Border.all(color: AppConstants.borderInteractiveDark) : null,
                      ),
                      child: Icon(
                        Icons.point_of_sale_rounded,
                        color: isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appMode.isBangla ? 'বিল পরিশোধ ও লেজার' : 'Checkout & Payment',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppConstants.textPrimaryDark : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            appMode.isBangla ? 'ক্যাশ মেমো ও লেজার সমন্বয়' : 'Cash memo and ledger settlement',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              color: isDark ? AppConstants.textSecondaryDark : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, size: 20, color: isDark ? AppConstants.textSecondaryDark : const Color(0xFF64748B)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Hero Total Payable Banner
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppConstants.borderInteractiveDark : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n?.totalPayable ?? (appMode.isBangla ? 'মোট প্রদেয়' : 'TOTAL PAYABLE'),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: isDark ? AppConstants.textSecondaryDark : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? AppConstants.surfaceDark : const Color(0xFFEAEDFF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${posVm.totalItemCount} items',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.formatCurrency(posVm.grandTotal),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Customer Account (Khata) Selection
                Text(
                  appMode.isBangla ? 'গ্রাহক একাউন্ট (লেজার রেজিস্টার)' : 'Customer Account (Ledger Register)',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppConstants.textSecondaryDark : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: posVm.selectedCustomer?.id,
                  isExpanded: true,
                  dropdownColor: isDark ? AppConstants.surfaceElevatedDark : Colors.white,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark ? AppConstants.surfaceDark : const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppConstants.borderInteractiveDark : const Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue, width: 1.5),
                    ),
                  ),
                  hint: Text(
                    appMode.isBangla ? 'নগদ খরিদ্দার' : 'Walk-in Cash Customer',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B),
                    ),
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text(
                        appMode.isBangla ? 'নগদ খরিদ্দার' : 'Walk-in Cash Customer',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppConstants.textPrimaryDark : const Color(0xFF334155),
                        ),
                      ),
                    ),
                    ...customerVm.customers.map((c) => DropdownMenuItem<String>(
                          value: c.id,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  c.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppConstants.textPrimaryDark : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: c.currentDue > 0
                                      ? (isDark ? AppConstants.alertCrimsonDark.withValues(alpha: 0.15) : const Color(0xFFFFECEB))
                                      : (isDark ? AppConstants.secondaryEmeraldDark.withValues(alpha: 0.15) : const Color(0xFFE8F5E9)),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Due: ৳${c.currentDue.toInt()}',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: c.currentDue > 0
                                        ? (isDark ? AppConstants.alertCrimsonDark : AppConstants.alertCrimson)
                                        : (isDark ? AppConstants.secondaryEmeraldDark : const Color(0xFF2E7D32)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                  onChanged: (val) {
                    if (val == null) {
                      posVm.selectCustomer(null);
                    } else {
                      final cust = customerVm.customers.where((c) => c.id == val).firstOrNull;
                      posVm.selectCustomer(cust);
                      setState(() => _customerError = null);
                    }
                  },
                ),

                // Inline Immediate Customer Registration for Walk-in Credit/Partial Pay
                if (posVm.paymentMode != PaymentMode.cash && posVm.selectedCustomer == null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppConstants.dueAmberDark.withValues(alpha: 0.12) : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppConstants.dueAmberDark.withValues(alpha: 0.35) : const Color(0xFFFDE68A),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isDark ? AppConstants.dueAmberDark.withValues(alpha: 0.25) : const Color(0xFFFDE68A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.person_add_alt_1_rounded,
                                color: isDark ? AppConstants.dueAmberDark : const Color(0xFFB45309),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appMode.isBangla ? 'গ্রাহক লেজার তৈরি করুন (Add to Ledger) *' : 'Create Customer Ledger (Add to Ledger) *',
                                    style: isDark
                                        ? GoogleFonts.spaceGrotesk(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: AppConstants.dueAmberDark,
                                          )
                                        : GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF92400E),
                                          ),
                                  ),
                                  Text(
                                    'বাকি বা আংশিক বিক্রির জন্য নাম ও ফোন নম্বর আবশ্যক',
                                    style: isDark
                                        ? GoogleFonts.spaceGrotesk(
                                            fontSize: 10,
                                            color: AppConstants.textSecondaryDark,
                                          )
                                        : GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            color: const Color(0xFFB45309),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _customerNameController,
                          decoration: InputDecoration(
                            hintText: 'গ্রাহকের নাম (Customer Name) *',
                            hintStyle: isDark
                                ? GoogleFonts.spaceGrotesk(fontSize: 12, color: AppConstants.textMutedDark)
                                : GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF94A3B8)),
                            filled: true,
                            fillColor: isDark ? AppConstants.surfaceDark : Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDark ? AppConstants.dueAmberDark : const Color(0xFFB45309),
                                width: 1.5,
                              ),
                            ),
                          ),
                          style: isDark
                              ? GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w600, color: AppConstants.textPrimaryDark)
                              : GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _customerPhoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  hintText: 'মোবাইল নম্বর (Phone) *',
                                  hintStyle: isDark
                                      ? GoogleFonts.spaceGrotesk(fontSize: 12, color: AppConstants.textMutedDark)
                                      : GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF94A3B8)),
                                  filled: true,
                                  fillColor: isDark ? AppConstants.surfaceDark : Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: isDark ? AppConstants.dueAmberDark : const Color(0xFFB45309),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppConstants.textPrimaryDark : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                final name = _customerNameController.text.trim();
                                final phone = _customerPhoneController.text.trim();
                                if (name.isEmpty || phone.isEmpty) {
                                  setState(() => _customerError = 'দয়া করে নাম ও ফোন নম্বর লিখুন');
                                  return;
                                }
                                final newCust = await customerVm.createAndReturnCustomer(name: name, phone: phone);
                                posVm.selectCustomer(newCust);
                                setState(() => _customerError = null);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? AppConstants.dueAmberDark : const Color(0xFFB45309),
                                foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                              child: Text(
                                'যোগ করুন',
                                style: isDark
                                    ? GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700)
                                    : GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        if (_customerError != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            _customerError!,
                            style: isDark
                                ? GoogleFonts.spaceGrotesk(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppConstants.alertCrimsonDark,
                                  )
                                : GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.red.shade700,
                                  ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Payment Method 3-way Split Selector
                Text(
                  'Payment Method (পরিশোধের ধরন)',
                  style: isDark
                      ? GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppConstants.textPrimaryDark,
                        )
                      : GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildPaymentMethodOption(
                      label: 'Full Cash',
                      subLabel: 'সম্পূর্ণ নগদ',
                      icon: Icons.payments_rounded,
                      mode: PaymentMode.cash,
                      activeMode: posVm.paymentMode,
                      color: isDark ? AppConstants.secondaryEmeraldDark : AppConstants.secondaryEmerald,
                      isDark: isDark,
                      onTap: () {
                        posVm.setPaymentMode(PaymentMode.cash);
                        _cashController.text = posVm.grandTotal.toStringAsFixed(0);
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildPaymentMethodOption(
                      label: 'Partial Pay',
                      subLabel: 'আংশিক',
                      icon: Icons.pie_chart_rounded,
                      mode: PaymentMode.partial,
                      activeMode: posVm.paymentMode,
                      color: isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue,
                      isDark: isDark,
                      onTap: () {
                        posVm.setPaymentMode(PaymentMode.partial);
                        final partialDefault = (posVm.grandTotal / 2).roundToDouble();
                        _cashController.text = partialDefault > 0 ? partialDefault.toStringAsFixed(0) : '0';
                        posVm.setCashReceived(partialDefault);
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildPaymentMethodOption(
                      label: 'Credit',
                      subLabel: appMode.isBangla ? 'বাকি (লেজার)' : 'Due (Ledger)',
                      icon: Icons.receipt_long_rounded,
                      mode: PaymentMode.credit,
                      activeMode: posVm.paymentMode,
                      color: isDark ? AppConstants.alertCrimsonDark : AppConstants.alertCrimson,
                      isDark: isDark,
                      onTap: () {
                        posVm.setPaymentMode(PaymentMode.credit);
                        _cashController.text = '0';
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Cash Input & Presets (When Cash or Partial)
                if (posVm.paymentMode != PaymentMode.credit) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cash Received (নগদ গ্রহণ)',
                        style: isDark
                            ? GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppConstants.textPrimaryDark,
                              )
                            : GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                      ),
                      if (posVm.paymentMode == PaymentMode.partial)
                        Text(
                          appMode.isBangla ? 'লেজার বাকি: ৳${posVm.remainingDue.toInt()}' : 'Ledger Due: ৳${posVm.remainingDue.toInt()}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppConstants.alertCrimsonDark : AppConstants.alertCrimson,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _cashController,
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      final amount = double.tryParse(val) ?? 0.0;
                      posVm.setCashReceived(amount);
                    },
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppConstants.textPrimaryDark : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF8FAFC),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          '৳',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppConstants.textPrimaryDark : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Rapid Increment Chips
                  Row(
                    children: [
                      _buildPresetChip('Exact', () {
                        _cashController.text = posVm.grandTotal.toStringAsFixed(0);
                        posVm.setCashReceived(posVm.grandTotal);
                      }, isDark: isDark),
                      const SizedBox(width: 6),
                      _buildPresetChip('+৳50', () {
                        final now = (double.tryParse(_cashController.text) ?? 0) + 50;
                        _cashController.text = now.toStringAsFixed(0);
                        posVm.setCashReceived(now);
                      }, isDark: isDark),
                      const SizedBox(width: 6),
                      _buildPresetChip('+৳100', () {
                        final now = (double.tryParse(_cashController.text) ?? 0) + 100;
                        _cashController.text = now.toStringAsFixed(0);
                        posVm.setCashReceived(now);
                      }, isDark: isDark),
                      const SizedBox(width: 6),
                      _buildPresetChip('+৳500', () {
                        final now = (double.tryParse(_cashController.text) ?? 0) + 500;
                        _cashController.text = now.toStringAsFixed(0);
                        posVm.setCashReceived(now);
                      }, isDark: isDark),
                      const SizedBox(width: 6),
                      _buildPresetChip('+৳1000', () {
                        final now = (double.tryParse(_cashController.text) ?? 0) + 1000;
                        _cashController.text = now.toStringAsFixed(0);
                        posVm.setCashReceived(now);
                      }, isDark: isDark),
                    ],
                  ),

                  // Change Return Notification Banner
                  if (changeReturn > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppConstants.secondaryEmeraldDark.withValues(alpha: 0.15)
                            : const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? AppConstants.secondaryEmeraldDark.withValues(alpha: 0.35)
                              : const Color(0xFFA7F3D0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.change_circle_rounded,
                            color: isDark ? AppConstants.secondaryEmeraldDark : AppConstants.secondaryEmerald,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'ফেরত দিন (Change Due):',
                              style: isDark
                                  ? GoogleFonts.spaceGrotesk(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppConstants.secondaryEmeraldDark,
                                    )
                                  : GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF065F46),
                                    ),
                            ),
                          ),
                          Text(
                            '৳${changeReturn.toStringAsFixed(0)}',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppConstants.secondaryEmeraldDark : const Color(0xFF065F46),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: 20),

                // Action Confirm CTA Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: posVm.isLoading
                        ? null
                        : () async {
                            // If partial or credit is selected and customer is not set, auto-create immediately:
                            if (posVm.paymentMode != PaymentMode.cash && posVm.selectedCustomer == null) {
                              final name = _customerNameController.text.trim();
                              final phone = _customerPhoneController.text.trim();
                              if (name.isEmpty || phone.isEmpty) {
                                final errorText = appMode.isBangla
                                    ? 'বাকি বা আংশিক রেকর্ডের জন্য গ্রাহকের নাম ও ফোন নম্বর দিন'
                                    : 'Please provide customer name and phone for credit or partial payment';
                                setState(() {
                                  _customerError = errorText;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      errorText,
                                      style: isDark
                                          ? GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600)
                                          : GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                                    ),
                                    backgroundColor: isDark ? AppConstants.alertCrimsonDark : AppConstants.alertCrimson,
                                  ),
                                );
                                return;
                              }
                              final newCust = await customerVm.createAndReturnCustomer(name: name, phone: phone);
                              posVm.selectCustomer(newCust);
                            }

                            final remainingDue = posVm.remainingDue;
                            final selectedCustId = posVm.selectedCustomer?.id;

                            final receipt = await posVm.processCheckout();
                            if (context.mounted && receipt != null) {
                              // If there is remaining due, immediately update Khata balance in customer list!
                              if (remainingDue > 0 && selectedCustId != null) {
                                customerVm.recordCreditSale(
                                  customerId: selectedCustId,
                                  dueAmount: remainingDue,
                                  orderNumber: receipt.orderNumber,
                                );
                              }
                              // Ensure recent transactions are refreshed
                              posVm.loadRecentTransactions();

                              Navigator.pop(context); // close checkout dialog
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ReceiptView(receipt: receipt)),
                              );
                            }
                          },
                    icon: posVm.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_rounded, size: 20),
                    label: Text(
                      posVm.isLoading
                          ? (appMode.isBangla ? 'বিক্রয় প্রক্রিয়াধীন...' : 'Processing Sale...')
                          : posVm.paymentMode == PaymentMode.cash
                              ? (appMode.isBangla
                                  ? 'সম্পূর্ণ নগদ নিশ্চিত করুন (${Formatters.formatCurrency(posVm.grandTotal)})'
                                  : 'Confirm Full Cash (${Formatters.formatCurrency(posVm.grandTotal)})')
                              : posVm.paymentMode == PaymentMode.partial
                                  ? (appMode.isBangla
                                      ? 'নিশ্চিত করুন ও লেজারে ৳${posVm.remainingDue.toInt()} যোগ করুন'
                                      : 'Confirm & Add ৳${posVm.remainingDue.toInt()} to Ledger')
                                  : (appMode.isBangla
                                      ? 'সম্পূর্ণ বাকি নিশ্চিত করুন (লেজার)'
                                      : 'Confirm 100% Credit (Ledger)'),
                      style: isDark
                          ? GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700)
                          : GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: posVm.paymentMode == PaymentMode.cash
                          ? (isDark ? AppConstants.secondaryEmeraldDark : AppConstants.secondaryEmerald)
                          : posVm.paymentMode == PaymentMode.partial
                              ? (isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue)
                              : (isDark ? AppConstants.alertCrimsonDark : AppConstants.alertCrimson),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption({
    required String label,
    required String subLabel,
    required IconData icon,
    required PaymentMode mode,
    required PaymentMode activeMode,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final isSelected = mode == activeMode;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: isDark ? 0.2 : 0.1)
                : (isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : (isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: isSelected ? color : (isDark ? AppConstants.textMutedDark : const Color(0xFF64748B))),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: isDark
                    ? GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? color : AppConstants.textPrimaryDark,
                      )
                    : GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? color : const Color(0xFF1E293B),
                      ),
              ),
              Text(
                subLabel,
                textAlign: TextAlign.center,
                style: isDark
                    ? GoogleFonts.spaceGrotesk(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? color.withValues(alpha: 0.8) : AppConstants.textMutedDark,
                      )
                    : GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? color.withValues(alpha: 0.8) : const Color(0xFF94A3B8),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap, {required bool isDark}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? AppConstants.textPrimaryDark : const Color(0xFF1E293B),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
