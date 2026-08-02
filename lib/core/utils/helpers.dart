import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

class AppHelpers {
  AppHelpers._();

  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppStrings.goodMorning;
    if (hour < 17) return AppStrings.goodAfternoon;
    return AppStrings.goodEvening;
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
      case 'approved':
      case 'active':
        return AppColors.present;
      case 'absent':
      case 'rejected':
      case 'inactive':
        return AppColors.absent;
      case 'late':
      case 'pending':
      case 'warning':
        return AppColors.late;
      case 'on leave':
      case 'leave':
        return AppColors.onLeave;
      case 'remote':
      case 'working from home':
        return AppColors.remote;
      default:
        return AppColors.grey500;
    }
  }
}
