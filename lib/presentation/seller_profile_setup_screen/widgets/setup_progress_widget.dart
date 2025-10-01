import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SetupProgressWidget extends StatefulWidget {
  final int currentStep;
  final int totalSteps;
  final double completionPercentage;

  const SetupProgressWidget({
    Key? key,
    required this.currentStep,
    required this.totalSteps,
    required this.completionPercentage,
  }) : super(key: key);

  @override
  State<SetupProgressWidget> createState() => _SetupProgressWidgetState();
}

class _SetupProgressWidgetState extends State<SetupProgressWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  final List<String> _steps = [
    'Business Info',
    'Verification',
    'Customization', // Changed from 'Bank Details' to 'Customization'
    'Terms & Conditions',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.completionPercentage / 100,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void didUpdateWidget(SetupProgressWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.completionPercentage != widget.completionPercentage) {
      _progressAnimation = Tween<double>(
        begin: oldWidget.completionPercentage / 100,
        end: widget.completionPercentage / 100,
      ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
      );
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Progress bar
        Container(
          height: 0.8.h,
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(0.4.h),
          ),
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progressAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.lightTheme.colorScheme.primary,
                        AppTheme.lightTheme.colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(0.4.h),
                  ),
                ),
              );
            },
          ),
        ),

        SizedBox(height: 2.h),

        // Step indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(widget.totalSteps, (index) {
            final isActive = index == widget.currentStep;
            final isCompleted = index < widget.currentStep;
            final isUpcoming = index > widget.currentStep;

            return Expanded(
              child: Column(
                children: [
                  // Step circle
                  Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          isCompleted
                              ? AppTheme.lightTheme.colorScheme.tertiary
                              : isActive
                              ? AppTheme.lightTheme.colorScheme.primary
                              : AppTheme
                                  .lightTheme
                                  .colorScheme
                                  .surfaceContainerHighest,
                      border:
                          isUpcoming
                              ? Border.all(
                                color: AppTheme.lightTheme.colorScheme.outline,
                                width: 1,
                              )
                              : null,
                    ),
                    child: Center(
                      child:
                          isCompleted
                              ? CustomIconWidget(
                                iconName: 'check',
                                color: Colors.white,
                                size: 4.w,
                              )
                              : Text(
                                '${index + 1}',
                                style: AppTheme.lightTheme.textTheme.labelSmall
                                    ?.copyWith(
                                      color:
                                          isActive
                                              ? Colors.white
                                              : AppTheme
                                                  .lightTheme
                                                  .colorScheme
                                                  .onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                    ),
                  ),

                  SizedBox(height: 1.h),

                  // Step title
                  Text(
                    _steps[index],
                    style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                      color:
                          isActive
                              ? AppTheme.lightTheme.colorScheme.primary
                              : isCompleted
                              ? AppTheme.lightTheme.colorScheme.tertiary
                              : AppTheme
                                  .lightTheme
                                  .colorScheme
                                  .onSurfaceVariant,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}
