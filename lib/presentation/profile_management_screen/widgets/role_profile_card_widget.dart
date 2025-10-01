import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class RoleProfileCardWidget extends StatefulWidget {
  final String profileType;
  final Map<String, dynamic> profileData;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onSetup;

  const RoleProfileCardWidget({
    Key? key,
    required this.profileType,
    required this.profileData,
    required this.isActive,
    required this.onTap,
    this.onSetup,
  }) : super(key: key);

  @override
  State<RoleProfileCardWidget> createState() => _RoleProfileCardWidgetState();
}

class _RoleProfileCardWidgetState extends State<RoleProfileCardWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  void _toggleExpand() {
    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  String _getStatusText() {
    final status = widget.profileData['status'] as String;
    final isSetup = widget.profileData['isSetup'] as bool;

    if (!isSetup) return 'Not Created';
    if (widget.isActive) return 'Active';
    return status;
  }

  Color _getStatusColor() {
    final status = _getStatusText();
    switch (status) {
      case 'Active':
        return AppTheme.lightTheme.colorScheme.tertiary;
      case 'Not Created':
        return AppTheme.lightTheme.colorScheme.error;
      case 'Setup Required':
        return AppTheme.lightTheme.colorScheme.secondary;
      default:
        return AppTheme.lightTheme.colorScheme.onSurfaceVariant;
    }
  }

  Widget _buildMetrics() {
    switch (widget.profileType) {
      case 'Shopper':
        return Column(
          children: [
            _buildMetricRow(
                'Orders Placed', '${widget.profileData['orderCount']}'),
            _buildMetricRow(
                'Wishlist Items', '${widget.profileData['wishlistCount']}'),
            _buildMetricRow('Total Spent', widget.profileData['totalSpent']),
          ],
        );
      case 'Seller':
        if (!widget.profileData['isSetup']) return const SizedBox.shrink();
        return Column(
          children: [
            _buildMetricRow(
                'Products Listed', '${widget.profileData['productsListed']}'),
            _buildMetricRow(
                'Total Earnings', widget.profileData['totalEarnings']),
            _buildMetricRow(
                'Shop Rating', '${widget.profileData['rating']}/5.0'),
          ],
        );
      case 'Runner':
        if (!widget.profileData['isSetup']) return const SizedBox.shrink();
        return Column(
          children: [
            _buildMetricRow('Deliveries Completed',
                '${widget.profileData['deliveriesCompleted']}'),
            _buildMetricRow(
                'Total Earnings', widget.profileData['totalEarnings']),
            _buildMetricRow(
                'Runner Rating', '${widget.profileData['rating']}/5.0'),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSetup = widget.profileData['isSetup'] as bool;
    final profileColor = widget.profileData['color'] as Color;

    return Container(
      decoration: BoxDecoration(
        color: widget.isActive
            ? profileColor.withValues(alpha: 0.1)
            : AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isActive
              ? profileColor
              : AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
          width: widget.isActive ? 2 : 1,
        ),
        boxShadow: widget.isActive
            ? [
                BoxShadow(
                  color: profileColor.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // Main card content
          InkWell(
            onTap: isSetup ? widget.onTap : null,
            onLongPress: isSetup ? _toggleExpand : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  // Profile icon
                  Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      color: profileColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: widget.profileData['icon'],
                        color: profileColor,
                        size: 6.w,
                      ),
                    ),
                  ),

                  SizedBox(width: 4.w),

                  // Profile info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.profileType,
                              style: AppTheme.lightTheme.textTheme.titleMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: widget.isActive
                                    ? profileColor
                                    : AppTheme.lightTheme.colorScheme.onSurface,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 2.w, vertical: 0.5.h),
                              decoration: BoxDecoration(
                                color: _getStatusColor().withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getStatusText(),
                                style: AppTheme.lightTheme.textTheme.labelSmall
                                    ?.copyWith(
                                  color: _getStatusColor(),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          _getSubtitle(),
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action buttons
                  Column(
                    children: [
                      if (!isSetup && widget.onSetup != null) ...[
                        ElevatedButton(
                          onPressed: widget.onSetup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: profileColor,
                            foregroundColor: Colors.white,
                            minimumSize: Size(20.w, 5.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Setup',
                            style: AppTheme.lightTheme.textTheme.labelSmall
                                ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ] else if (isSetup) ...[
                        if (widget.isActive)
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 3.w, vertical: 1.h),
                            decoration: BoxDecoration(
                              color: profileColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: CustomIconWidget(
                              iconName: 'check',
                              color: Colors.white,
                              size: 4.w,
                            ),
                          )
                        else
                          OutlinedButton(
                            onPressed: widget.onTap,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: profileColor),
                              minimumSize: Size(20.w, 5.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Switch',
                              style: AppTheme.lightTheme.textTheme.labelSmall
                                  ?.copyWith(
                                color: profileColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],

                      // Expand indicator
                      if (isSetup) ...[
                        SizedBox(height: 1.h),
                        GestureDetector(
                          onTap: _toggleExpand,
                          child: RotationTransition(
                            turns: _expandAnimation,
                            child: CustomIconWidget(
                              iconName: 'expand_more',
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                              size: 4.w,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expandable metrics section
          if (isSetup)
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(
                      color: AppTheme.lightTheme.colorScheme.outline
                          .withValues(alpha: 0.2),
                      height: 2.h,
                    ),
                    Text(
                      'Profile Statistics',
                      style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    _buildMetrics(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getSubtitle() {
    if (!widget.profileData['isSetup']) {
      switch (widget.profileType) {
        case 'Seller':
          return 'Start selling your products online';
        case 'Runner':
          return 'Earn money by delivering orders';
        default:
          return 'Create this profile to get started';
      }
    }

    switch (widget.profileType) {
      case 'Shopper':
        return 'Browse and purchase products';
      case 'Seller':
        final shopName = widget.profileData['shopName'];
        return shopName?.isNotEmpty == true
            ? shopName
            : 'Manage your online shop';
      case 'Runner':
        return 'Deliver orders and earn money';
      default:
        return '';
    }
  }
}
