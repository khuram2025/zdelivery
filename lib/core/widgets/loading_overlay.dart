import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    if (message != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        message!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ShimmerLoading extends StatelessWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceVariant,
      highlightColor: Colors.white,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class OrderCardShimmer extends StatelessWidget {
  const OrderCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const ShimmerLoading(height: 20, width: 120),
                ShimmerLoading(height: 24, width: 80, borderRadius: 12),
              ],
            ),
            const SizedBox(height: 12),
            const ShimmerLoading(height: 16, width: 180),
            const SizedBox(height: 12),
            const ShimmerLoading(height: 14),
          ],
        ),
      ),
    );
  }
}

class ProfileShimmer extends StatelessWidget {
  const ProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ShimmerLoading(height: 80, width: 80, borderRadius: 40),
        const SizedBox(height: 16),
        const ShimmerLoading(height: 24, width: 150),
        const SizedBox(height: 8),
        const ShimmerLoading(height: 16, width: 100),
      ],
    );
  }
}
