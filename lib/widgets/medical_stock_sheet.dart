import 'package:flutter/material.dart';
import '../models/medical_stock.dart';

class MedicalStockSheet extends StatelessWidget {
  final MedicalStock stock;

  const MedicalStockSheet({
    super.key,
    required this.stock,
  });

  static const Color orange = Color(0xFFD8620F);
  static const Color blue = Color(0xFF2D4678);

  static void show(BuildContext context, MedicalStock stock) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => MedicalStockSheet(stock: stock),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 80),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: stock.statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: stock.statusColor.withOpacity(0.3),
                  ),
                ),
                child: Icon(
                  Icons.medical_services_rounded,
                  color: stock.statusColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stock.campName,
                      style: const TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: blue,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          stock.locationName,
                          style: TextStyle(
                            fontFamily: 'Lexend',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: stock.statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: stock.statusColor.withOpacity(0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      stock.statusIcon,
                      color: stock.statusColor,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      stock.status == MedicalStockStatus.critical
                          ? 'SHORTAGE'
                          : (stock.status == MedicalStockStatus.warning ? 'LOW' : 'STOCKED'),
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: stock.statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Marathi Status Alert Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: stock.statusColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: stock.statusColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: stock.statusColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stock.statusLabel,
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: stock.statusColor,
                        ),
                      ),
                      Text(
                        stock.statusLabelMarathi,
                        style: TextStyle(
                          fontFamily: 'Kalam',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: blue.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Live Inventory Status (वैद्यकीय साठा):',
            style: TextStyle(
              fontFamily: 'Lexend',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: blue,
            ),
          ),

          const SizedBox(height: 10),

          // Inventory List
          Column(
            children: stock.inventory.map((item) {
              final pct = item.fillPercentage;
              final isLow = item.isLow;
              final barColor = isLow ? const Color(0xFFD32F2F) : (pct < 0.6 ? const Color(0xFFF57C00) : const Color(0xFF2E7D32));

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBF7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: blue.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontFamily: 'Lexend',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: blue,
                          ),
                        ),
                        Text(
                          '${item.availableQuantity} / ${item.totalCapacity} ${item.unit}',
                          style: TextStyle(
                            fontFamily: 'Lexend',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: barColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 7,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Doctor in charge & Refill Request Button
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: stock.statusColor,
                        behavior: SnackBarBehavior.floating,
                        content: Text(
                          '🚨 Stock Alert dispatched to central medical team for ${stock.campName}!',
                          style: const TextStyle(fontFamily: 'Lexend'),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_alert_rounded, size: 18),
                  label: const Text(
                    'REQUEST REFILL',
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: stock.statusColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
}
