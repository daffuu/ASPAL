import 'package:flutter/material.dart';

const severityLabels = ['Ringan', 'Sedang', 'Parah', 'Sangat Parah'];
const severityTextColors = [
  Color(0xFF16A34A),
  Color(0xFFA16207),
  Color(0xFFEA580C),
  Color(0xFFDC2626),
];
const severityBgColors = [
  Color(0xFFDCFCE7),
  Color(0xFFFEF9C3),
  Color(0xFFFFEDD5),
  Color(0xFFFEE2E2),
];
const severityBarColors = [
  Color(0xFF22C55E),
  Color(0xFFFACC15),
  Color(0xFFF97316),
  Color(0xFFDC2626),
];

class SeverityChip extends StatelessWidget {
  const SeverityChip({super.key, required this.severity});

  final int severity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: severityBgColors[severity],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        severityLabels[severity],
        style: TextStyle(
          color: severityTextColors[severity],
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
