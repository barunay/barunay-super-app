import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class ReviewProgressWidget extends StatefulWidget {
  final int currentStage;
  final AnimationController animationController;

  const ReviewProgressWidget({
    super.key,
    required this.currentStage,
    required this.animationController,
  });

  @override
  State<ReviewProgressWidget> createState() => _ReviewProgressWidgetState();
}

class _ReviewProgressWidgetState extends State<ReviewProgressWidget> {
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.currentStage / 3.0,
    ).animate(CurvedAnimation(
      parent: widget.animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Timeline visual
        Container(
          height: 8.h,
          child: Row(
            children: [
              _buildTimelineStep(
                title: 'Submitted',
                isCompleted: widget.currentStage >= 0,
                isActive: widget.currentStage == 0,
                icon: Icons.upload_file,
              ),
              Expanded(
                child: Container(
                  height: 2,
                  color: widget.currentStage >= 1
                      ? Colors.green
                      : Colors.grey.shade300,
                ),
              ),
              _buildTimelineStep(
                title: 'Under Review',
                isCompleted: widget.currentStage >= 1,
                isActive: widget.currentStage == 1,
                icon: Icons.search,
              ),
              Expanded(
                child: Container(
                  height: 2,
                  color: widget.currentStage >= 2
                      ? Colors.green
                      : Colors.grey.shade300,
                ),
              ),
              _buildTimelineStep(
                title: 'Approved',
                isCompleted: widget.currentStage >= 2,
                isActive: widget.currentStage == 2,
                icon: Icons.check_circle,
              ),
            ],
          ),
        ),

        SizedBox(height: 2.h),

        // Progress bar with animation
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Column(
              children: [
                LinearProgressIndicator(
                  value: _progressAnimation.value,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
                SizedBox(height: 1.h),
                Text(
                  '${(_progressAnimation.value * 100).round()}% Complete',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required bool isCompleted,
    required bool isActive,
    required IconData icon,
  }) {
    Color color;
    if (isCompleted) {
      color = Colors.green;
    } else if (isActive) {
      color = Colors.orange;
    } else {
      color = Colors.grey.shade400;
    }

    return Column(
      children: [
        Container(
          width: 12.w,
          height: 12.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(77),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 6.w,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
