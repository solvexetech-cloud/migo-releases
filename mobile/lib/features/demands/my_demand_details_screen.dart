// mobile/lib/features/demands/my_demand_details_screen.dart
// FULLY FIXED - Correct Arabic text and working View Offers button
import 'package:flutter/material.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/migo_colors.dart';
import 'bids_comparison_screen.dart';

class MyDemandDetailsScreen extends StatelessWidget {
  final String demandId;
  final Map<String, dynamic> data;

  const MyDemandDetailsScreen({
    super.key,
    required this.demandId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final t = AppLocalizations.of(context)!;
        final isAr = LocaleProvider.instance.locale == 'ar';
        
        final title = data['title'] ?? '';
        final description = data['description'] ?? '';
        final status = data['status'] ?? 'collecting';
        final groupId = data['groupId'];
        
        final double price = (data['minTargetPrice'] as num?)?.toDouble() ?? 0.0;
        final int quantity = (data['totalQuantity'] as num?)?.toInt() ?? 0;
        final int threshold = data['threshold'] ?? 3;
        final isBulk = threshold == 1; 

        String statusText;
        Color statusColor;

        if (status == 'collecting') {
          statusText = t.get('waiting_for_people');
          statusColor = Colors.orange;
        } else if (status == 'threshold_reached') {
          statusText = isBulk ? (isAr ? 'طلب خاص' : 'Personal Order') : (isAr ? 'بدأت المجموعة' : 'Group Started');
          statusColor = isBulk ? Colors.purple : Colors.green;
        } else if (status == 'bidding') {
          statusText = t.get('receiving_offers');
          statusColor = Colors.blue;
        } else if (status == 'fulfilled') {
          statusText = t.get('order_placed');
          statusColor = Colors.green.shade700;
        } else {
          statusText = status;
          statusColor = Colors.grey;
        }

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: MigoColors.backgroundLight,
            appBar: AppBar(
              title: Text(isAr ? 'تفاصيل الطلب' : 'Demand Details', style: const TextStyle(fontWeight: FontWeight.w800)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: MigoColors.primaryDark,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isBulk ? [Colors.purple.shade700, Colors.purple.shade900] : [MigoColors.primary, MigoColors.primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: (isBulk ? Colors.purple : MigoColors.primary).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                        if (description.toString().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(description, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                              child: Text('${price.toStringAsFixed(0)} QAR', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(8)),
                              child: Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _SectionTitle(title: isAr ? 'تفاصيل' : 'Details', isAr: isAr),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                    child: Column(
                      children: [
                        _DetailRow(label: isAr ? 'نوع الطلب' : 'Order Type', value: isBulk ? (isAr ? 'طلب بالجملة' : 'Bulk Order') : (isAr ? 'طلب مجتمعي' : 'Community'), valueColor: isBulk ? Colors.purple : Colors.blue),
                        const SizedBox(height: 12),
                        _DetailRow(label: isAr ? 'الفئة' : 'Category', value: data['category'] ?? ''),
                        const SizedBox(height: 12),
                        _DetailRow(label: isAr ? 'الكمية' : 'Quantity', value: '$quantity'),
                        const SizedBox(height: 12),
                        _DetailRow(label: isAr ? 'الحالة' : 'Status', value: statusText, valueColor: statusColor),
                      ],
                    ),
                  ),

                  if (groupId != null && (status == 'threshold_reached' || status == 'bidding'))
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: SizedBox(
                        width: double.infinity, height: 50,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: isBulk ? Colors.purple : MigoColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          onPressed: () {
                            // 🆕 Navigate to Bids Comparison (QR Ticket)
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => BidsComparisonScreen(groupId: demandId, groupData: data),
                            ));
                          },
                          icon: const Icon(Icons.gavel),
                          label: Text(isAr ? 'عرض العروض' : 'View Offers', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isAr;
  const _SectionTitle({required this.title, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(color: MigoColors.primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: MigoColors.primaryDark)),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: valueColor ?? Colors.black87)),
      ],
    );
  }
}