import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double? padding;
  final double? margin;
  final Color? color;
  final double? elevation;
  final double? borderRadius;
  final bool showBorder;
  final Color? borderColor;
  final double? width;
  final double? height;

  const CustomCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.borderRadius,
    this.showBorder = false,
    this.borderColor,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: height,
        margin: EdgeInsets.all(margin ?? 0),
        decoration: BoxDecoration(
          color: color ?? Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(borderRadius ?? AppSizes.r16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: elevation ?? AppSizes.elevation2,
              offset: const Offset(0, 2),
            ),
          ],
          border: showBorder
              ? Border.all(
                  color: borderColor ?? AppColors.grey200,
                  width: 1,
                )
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius ?? AppSizes.r16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius ?? AppSizes.r16),
            child: Padding(
              padding: EdgeInsets.all(padding ?? AppSizes.p16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
