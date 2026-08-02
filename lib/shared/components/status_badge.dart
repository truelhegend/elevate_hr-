import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/helpers.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool isSmall;
  final bool showDot;

  const StatusBadge({
    super.key,
    required this.status,
    this.isSmall = false,
    this.showDot = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppHelpers.getStatusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? AppSizes.p8 : AppSizes.p12,
        vertical: isSmall ? AppSizes.p4 : AppSizes.p6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.rFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: isSmall ? 6 : 8,
              height: isSmall ? 6 : 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: isSmall ? 4 : 6),
          ],
          Text(
            status,
            style: GoogleFonts.inter(
              fontSize: isSmall ? AppSizes.s10 : AppSizes.s12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
