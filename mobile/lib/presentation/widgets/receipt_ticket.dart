import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/transaction_model.dart';
import '../../core/utils/formatters.dart';
import '../../l10n/app_localizations.dart';

class ReceiptTicket extends StatelessWidget {
  final ReceiptModel receipt;

  const ReceiptTicket({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Text(
                  receipt.storeName.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  receipt.storeAddress,
                  style: GoogleFonts.jetBrainsMono(fontSize: 10, color: Colors.grey.shade600),
                ),
                Text(
                  'Tel: ${receipt.storePhone}',
                  style: GoogleFonts.jetBrainsMono(fontSize: 10, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  '*** OFFICIAL CASH MEMO ***',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          _buildDashedLine(),
          const SizedBox(height: 8),

          // Metadata
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                receipt.orderNumber,
                style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black87),
              ),
              Text(
                receipt.dateTime,
                style: GoogleFonts.jetBrainsMono(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Customer: ${receipt.customerName}',
            style: GoogleFonts.jetBrainsMono(fontSize: 11, color: Colors.grey.shade800),
          ),

          const SizedBox(height: 8),
          _buildDashedLine(),
          const SizedBox(height: 8),

          // Items Table (Exact prompt spec)
          ...receipt.items.map((it) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${it.name} × ${it.quantity}',
                      style: GoogleFonts.jetBrainsMono(fontSize: 12, color: Colors.black87),
                    ),
                    Text(
                      Formatters.formatCurrency(it.totalPrice),
                      style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 8),
          _buildDashedLine(),
          const SizedBox(height: 8),

          // Subtotal & Discount
          _buildSummaryRow('Subtotal', Formatters.formatCurrency(receipt.subtotal)),
          const SizedBox(height: 4),
          _buildSummaryRow(
            'Discount',
            '-${Formatters.formatCurrency(receipt.discount)}',
            valueColor: Colors.red.shade700,
          ),

          const SizedBox(height: 8),
          _buildDashedLine(),
          const SizedBox(height: 8),

          // Total, Paid, Remaining
          _buildSummaryRow(
            'Total',
            Formatters.formatCurrency(receipt.total),
            isBold: true,
            fontSize: 14,
          ),
          const SizedBox(height: 4),
          _buildSummaryRow(
            'Paid',
            Formatters.formatCurrency(receipt.paidAmount),
            valueColor: Colors.green.shade700,
            isBold: true,
          ),
          const SizedBox(height: 4),
          _buildSummaryRow(
            'Remaining',
            Formatters.formatCurrency(receipt.remainingDue),
            valueColor: receipt.remainingDue > 0 ? Colors.red.shade700 : Colors.black87,
            isBold: true,
          ),

          const SizedBox(height: 12),
          _buildDashedLine(),
          const SizedBox(height: 8),

          // Footer
          Center(
            child: Column(
              children: [
                Text(
                  AppLocalizations.of(context)?.thankYou ?? 'Thank you, visit again!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  'Powered by FMCG+ Retail Engine',
                  style: GoogleFonts.jetBrainsMono(fontSize: 9, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 4),
                Icon(Icons.qr_code_2, size: 40, color: Colors.grey.shade800),
                Text(
                  receipt.authCode,
                  style: GoogleFonts.jetBrainsMono(fontSize: 8, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, double fontSize = 12, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildDashedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey.shade400),
              ),
            );
          }),
        );
      },
    );
  }
}
