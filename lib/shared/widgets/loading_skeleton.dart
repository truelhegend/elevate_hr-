import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';

class LoadingSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.grey700 : AppColors.grey200,
      highlightColor: isDark ? AppColors.grey600 : AppColors.grey100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? AppColors.grey700 : AppColors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          LoadingSkeleton(width: double.infinity, height: 120),
          SizedBox(height: 16),
          LoadingSkeleton(width: double.infinity, height: 200),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: LoadingSkeleton(width: double.infinity, height: 100)),
              SizedBox(width: 12),
              Expanded(child: LoadingSkeleton(width: double.infinity, height: 100)),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: LoadingSkeleton(width: double.infinity, height: 100)),
              SizedBox(width: 12),
              Expanded(child: LoadingSkeleton(width: double.infinity, height: 100)),
            ],
          ),
          SizedBox(height: 16),
          LoadingSkeleton(width: double.infinity, height: 200),
        ],
      ),
    );
  }
}

class ListSkeleton extends StatelessWidget {
  final int itemCount;

  const ListSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Shimmer.fromColors(
            baseColor: isDark ? AppColors.grey700 : AppColors.grey200,
            highlightColor: isDark ? AppColors.grey600 : AppColors.grey100,
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.grey700 : AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.grey700 : AppColors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 120,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.grey700 : AppColors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
