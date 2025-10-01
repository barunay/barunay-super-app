import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class StickyBottomBar extends StatefulWidget {
  final bool isInStock;
  final bool hasQuantitySelector;
  final int currentQuantity;
  final int maxQuantity;
  final VoidCallback onChatWithSeller;
  final VoidCallback onContactSeller;
  final Function(int) onQuantityChanged;

  const StickyBottomBar({
    Key? key,
    required this.isInStock,
    required this.hasQuantitySelector,
    required this.currentQuantity,
    required this.maxQuantity,
    required this.onChatWithSeller,
    required this.onContactSeller,
    required this.onQuantityChanged,
  }) : super(key: key);

  @override
  State<StickyBottomBar> createState() => _StickyBottomBarState();
}

class _StickyBottomBarState extends State<StickyBottomBar> {
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = widget.currentQuantity;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.hasQuantitySelector && widget.isInStock) ...[
                _buildQuantitySelector(),
                SizedBox(height: 2.h),
              ],
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Quantity:',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 4.w),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.outline,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildQuantityButton(
                icon: 'remove',
                onPressed:
                    _quantity > 1 ? () => _updateQuantity(_quantity - 1) : null,
              ),
              Container(
                width: 12.w,
                padding: EdgeInsets.symmetric(vertical: 1.h),
                child: Text(
                  '$_quantity',
                  textAlign: TextAlign.center,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildQuantityButton(
                icon: 'add',
                onPressed: _quantity < widget.maxQuantity
                    ? () => _updateQuantity(_quantity + 1)
                    : null,
              ),
            ],
          ),
        ),
        SizedBox(width: 2.w),
        Text(
          'Max: ${widget.maxQuantity}',
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityButton({
    required String icon,
    required VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: EdgeInsets.all(2.w),
        child: CustomIconWidget(
          iconName: icon,
          color: onPressed != null
              ? AppTheme.lightTheme.primaryColor
              : AppTheme.lightTheme.colorScheme.onSurfaceVariant
                  .withValues(alpha: 0.5),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (!widget.isInStock) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 2.h),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.warningLight,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            CustomIconWidget(
              iconName: 'inventory_2',
              color: AppTheme.warningLight,
              size: 32,
            ),
            SizedBox(height: 1.h),
            Text(
              'Out of Stock',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.warningLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              'Get notified when this item is back in stock',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            OutlinedButton(
              onPressed: () {
                // Handle notify when available
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'You will be notified when this item is available'),
                    backgroundColor: AppTheme.successLight,
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.warningLight),
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
              ),
              child: Text(
                'Notify Me',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.warningLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.onChatWithSeller,
            icon: CustomIconWidget(
              iconName: 'chat',
              color: AppTheme.lightTheme.primaryColor,
              size: 20,
            ),
            label: Text(
              'Chat with Seller',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 1.8.h),
              side: BorderSide(
                color: AppTheme.lightTheme.primaryColor,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: widget.onContactSeller,
            icon: CustomIconWidget(
              iconName: 'phone',
              color: Colors.white,
              size: 20,
            ),
            label: Text(
              'Contact Seller',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.primaryColor,
              padding: EdgeInsets.symmetric(vertical: 1.8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
      ],
    );
  }

  void _updateQuantity(int newQuantity) {
    setState(() {
      _quantity = newQuantity;
    });
    widget.onQuantityChanged(newQuantity);
  }
}
