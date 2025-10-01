import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ProgressStepperWidget extends StatelessWidget {
  final List<Map<String, dynamic>> steps;
  final int currentStep;
  final Map<int, bool> stepCompletion;
  final Function(int) onStepTap;

  const ProgressStepperWidget({
    Key? key,
    required this.steps,
    required this.currentStep,
    required this.stepCompletion,
    required this.onStepTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: steps.length,
        itemBuilder: (context, index) {
          bool isCompleted = stepCompletion[index] ?? false;
          bool isCurrent = index == currentStep;
          bool isClickable = index <= currentStep || isCompleted;

          return GestureDetector(
            onTap: isClickable ? () => onStepTap(index) : null,
            child: Container(
              margin: EdgeInsets.only(right: 2.w),
              child: Column(
                children: [
                  // Step Circle
                  Container(
                    width: 10.w,
                    height: 10.w,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppTheme.lightTheme.colorScheme.tertiary
                          : isCurrent
                              ? AppTheme.lightTheme.colorScheme.primary
                              : AppTheme.lightTheme.colorScheme.outline
                                  .withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                      border: isCurrent && !isCompleted
                          ? Border.all(
                              color: AppTheme.lightTheme.colorScheme.primary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Center(
                      child: isCompleted
                          ? CustomIconWidget(
                              iconName: 'check',
                              color: Colors.white,
                              size: 5.w,
                            )
                          : Text(
                              '${index + 1}',
                              style: AppTheme.lightTheme.textTheme.labelMedium
                                  ?.copyWith(
                                color: isCurrent
                                    ? AppTheme.lightTheme.colorScheme.primary
                                    : AppTheme.lightTheme.colorScheme
                                        .onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: 1.h),

                  // Step Title
                  SizedBox(
                    width: 20.w,
                    child: Text(
                      steps[index]['subtitle'],
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        color: isCurrent || isCompleted
                            ? AppTheme.lightTheme.colorScheme.onSurface
                            : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        fontWeight:
                            isCurrent ? FontWeight.w600 : FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
