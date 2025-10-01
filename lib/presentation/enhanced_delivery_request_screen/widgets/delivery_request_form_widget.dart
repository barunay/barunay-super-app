import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/delivery_service.dart';

class DeliveryRequestFormWidget extends StatefulWidget {
  final VoidCallback onRequestCreated;

  const DeliveryRequestFormWidget({Key? key, required this.onRequestCreated})
    : super(key: key);

  @override
  State<DeliveryRequestFormWidget> createState() =>
      _DeliveryRequestFormWidgetState();
}

class _DeliveryRequestFormWidgetState extends State<DeliveryRequestFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pickupAddressController = TextEditingController();
  final _deliveryAddressController = TextEditingController();
  final _recipientNameController = TextEditingController();
  final _recipientPhoneController = TextEditingController();
  final _specialInstructionsController = TextEditingController();
  final _budgetController = TextEditingController();

  String _selectedUrgency = 'medium';
  String _selectedSize = 'medium';
  bool _isSubmitting = false;

  final DeliveryService _deliveryService = DeliveryService();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pickupAddressController.dispose();
    _deliveryAddressController.dispose();
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    _specialInstructionsController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await _deliveryService.createDeliveryRequest(
        title: _titleController.text,
        description: _descriptionController.text,
        pickupAddress: _pickupAddressController.text,
        deliveryAddress: _deliveryAddressController.text,
        recipientName:
            _recipientNameController.text.isEmpty
                ? null
                : _recipientNameController.text,
        recipientPhone:
            _recipientPhoneController.text.isEmpty
                ? null
                : _recipientPhoneController.text,
        packageSize: _selectedSize,
        maxBudget:
            _budgetController.text.isEmpty
                ? null
                : double.tryParse(_budgetController.text),
        urgency: _selectedUrgency,
        specialInstructions:
            _specialInstructionsController.text.isEmpty
                ? null
                : _specialInstructionsController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery request created successfully!'),
          ),
        );
        _clearForm();
        widget.onRequestCreated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create request: $e')));
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _pickupAddressController.clear();
    _deliveryAddressController.clear();
    _recipientNameController.clear();
    _recipientPhoneController.clear();
    _specialInstructionsController.clear();
    _budgetController.clear();
    setState(() {
      _selectedUrgency = 'medium';
      _selectedSize = 'medium';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Description
            _buildSectionTitle('Request Details'),
            SizedBox(height: 2.h),

            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g., Deliver documents to office',
                prefixIcon: CustomIconWidget(iconName: 'description'),
              ),
              validator:
                  (value) =>
                      value?.isEmpty ?? true ? 'Title is required' : null,
            ),

            SizedBox(height: 2.h),

            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe what needs to be delivered',
                prefixIcon: CustomIconWidget(iconName: 'notes'),
              ),
              maxLines: 3,
              validator:
                  (value) =>
                      value?.isEmpty ?? true ? 'Description is required' : null,
            ),

            SizedBox(height: 3.h),

            // Pickup & Delivery Addresses
            _buildSectionTitle('Addresses'),
            SizedBox(height: 2.h),

            TextFormField(
              controller: _pickupAddressController,
              decoration: const InputDecoration(
                labelText: 'Pickup Address',
                hintText: 'Where to pick up the item',
                prefixIcon: CustomIconWidget(iconName: 'pickup'),
              ),
              validator:
                  (value) =>
                      value?.isEmpty ?? true
                          ? 'Pickup address is required'
                          : null,
            ),

            SizedBox(height: 2.h),

            TextFormField(
              controller: _deliveryAddressController,
              decoration: const InputDecoration(
                labelText: 'Delivery Address',
                hintText: 'Where to deliver the item',
                prefixIcon: CustomIconWidget(iconName: 'location_on'),
              ),
              validator:
                  (value) =>
                      value?.isEmpty ?? true
                          ? 'Delivery address is required'
                          : null,
            ),

            SizedBox(height: 3.h),

            // Recipient Information
            _buildSectionTitle('Recipient (Optional)'),
            SizedBox(height: 2.h),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _recipientNameController,
                    decoration: const InputDecoration(
                      labelText: 'Recipient Name',
                      prefixIcon: CustomIconWidget(iconName: 'person'),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: TextFormField(
                    controller: _recipientPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: CustomIconWidget(iconName: 'phone'),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),

            SizedBox(height: 3.h),

            // Package & Urgency Details
            _buildSectionTitle('Package Details'),
            SizedBox(height: 2.h),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSize,
                    decoration: const InputDecoration(
                      labelText: 'Package Size',
                      prefixIcon: CustomIconWidget(iconName: 'inventory'),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'small',
                        child: Text('Small (envelope)'),
                      ),
                      DropdownMenuItem(
                        value: 'medium',
                        child: Text('Medium (box)'),
                      ),
                      DropdownMenuItem(
                        value: 'large',
                        child: Text('Large (multiple items)'),
                      ),
                    ],
                    onChanged:
                        (value) => setState(() => _selectedSize = value!),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedUrgency,
                    decoration: const InputDecoration(
                      labelText: 'Urgency',
                      prefixIcon: CustomIconWidget(iconName: 'schedule'),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'low',
                        child: Text('Low (anytime today)'),
                      ),
                      DropdownMenuItem(
                        value: 'medium',
                        child: Text('Medium (within 2 hours)'),
                      ),
                      DropdownMenuItem(
                        value: 'high',
                        child: Text('High (within 1 hour)'),
                      ),
                      DropdownMenuItem(
                        value: 'urgent',
                        child: Text('Urgent (ASAP)'),
                      ),
                    ],
                    onChanged:
                        (value) => setState(() => _selectedUrgency = value!),
                  ),
                ),
              ],
            ),

            SizedBox(height: 2.h),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _budgetController,
                    decoration: const InputDecoration(
                      labelText: 'Max Budget (B\$)',
                      hintText: 'Your maximum budget',
                      prefixIcon: CustomIconWidget(iconName: 'payments'),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(2.w),
                    ),
                    child: Row(
                      children: [
                        const CustomIconWidget(iconName: 'info', size: 16),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            'Suggested: B\$5-15',
                            style: AppTheme.lightTheme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 3.h),

            // Special Instructions
            TextFormField(
              controller: _specialInstructionsController,
              decoration: const InputDecoration(
                labelText: 'Special Instructions (Optional)',
                hintText: 'Any specific delivery instructions',
                prefixIcon: CustomIconWidget(iconName: 'info'),
              ),
              maxLines: 2,
            ),

            SizedBox(height: 4.h),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 6.h,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child:
                    _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          'Create Delivery Request',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppTheme.lightTheme.colorScheme.primary,
      ),
    );
  }
}
