import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class LocationBadge extends StatelessWidget {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final bool isManual;
  final VoidCallback? onRefresh;

  const LocationBadge({
    super.key,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.isManual = false,
    this.onRefresh,
  });

  Color get _accuracyColor {
    if (isManual) return Colors.blue;
    if (accuracy == null) return Colors.grey;
    if (accuracy! <= 5) return AppColors.severityLow;
    if (accuracy! <= 12) return AppColors.severityMedium;
    return AppColors.severityCritical;
  }

  String get _accuracyLabel {
    if (isManual) return 'Manual';
    if (accuracy == null) return 'GPS';
    return '±${accuracy!.toStringAsFixed(1)}m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _accuracyColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _accuracyColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isManual ? Icons.edit_location_alt : Icons.my_location,
            size: 16,
            color: _accuracyColor,
          ),
          const SizedBox(width: 6),
          Text(
            '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: _accuracyColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _accuracyLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (onRefresh != null) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: onRefresh,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(2.0),
                child: Icon(Icons.refresh, size: 16, color: AppColors.primary),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
