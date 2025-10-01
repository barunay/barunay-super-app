import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class VehicleRegistrationWidget extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onDataChanged;

  const VehicleRegistrationWidget({
    Key? key,
    required this.initialData,
    required this.onDataChanged,
  }) : super(key: key);

  @override
  State<VehicleRegistrationWidget> createState() =>
      _VehicleRegistrationWidgetState();
}

class _VehicleRegistrationWidgetState extends State<VehicleRegistrationWidget> {
  final TextEditingController _licensePlateController = TextEditingController();
  
  String? _selectedVehicleType;
  bool _vehiclePhotosUploaded = false;
  
  final List<Map<String, dynamic>> _vehicleTypes = [
{ 'type': 'motorcycle',
'label': 'Motorcycle',
'icon': 'two_wheeler',
'description': 'Fast delivery, ideal for short distances',
},
{ 'type': 'car',
'label': 'Car',
'icon': 'directions_car',
'description': 'Weather protection, larger capacity',
},
{ 'type': 'bicycle',
'label': 'Bicycle',
'icon': 'pedal_bike',
'description': 'Eco-friendly, good for city centers',
},
];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _selectedVehicleType = widget.initialData['vehicleType'];
    _licensePlateController.text = widget.initialData['licensePlate'] ?? '';
    _vehiclePhotosUploaded = widget.initialData['vehiclePhotosUploaded'] ?? false;
  }

  void _updateData() {
    bool isComplete = _selectedVehicleType != null &&
        _licensePlateController.text.trim().isNotEmpty &&
        _vehiclePhotosUploaded;
    
    widget.onDataChanged({
      'vehicleType': _selectedVehicleType,
      'licensePlate': _licensePlateController.text,
      'vehiclePhotosUploaded': _vehiclePhotosUploaded,
      'isComplete': isComplete,
    });
  }

  void _selectVehicleType(String type) {
    setState(() {
      _selectedVehicleType = type;
    });
    _updateData();
  }

  void _uploadVehiclePhotos() {
    setState(() {
      _vehiclePhotosUploaded = true;
    });
    _updateData();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vehicle photos uploaded successfully'),
      ),
    );
  }

  bool _isValidLicensePlate(String plate) {
    // Basic Brunei license plate validation (simplified)
    final bruneiPlateRegex = RegExp(r'^[A-Z]{2,3}[0-9]{1,4}[A-Z]?$');
    return bruneiPlateRegex.hasMatch(plate.toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vehicle Type Selection
        Text(
          'Select Vehicle Type',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        
        SizedBox(height: 2.h),
        
        ..._vehicleTypes.map((vehicle) {
          bool isSelected = _selectedVehicleType == vehicle['type'];
          
          return Container(
            margin: EdgeInsets.only(bottom: 2.h),
            child: GestureDetector(
              onTap: () => _selectVehicleType(vehicle['type']),
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.colorScheme.outline,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12.w,
                      height: 12.w,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.lightTheme.colorScheme.primary
                            : AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: CustomIconWidget(
                        iconName: vehicle['icon'],
                        color: isSelected
                            ? Colors.white
                            : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        size: 6.w,
                      ),
                    ),
                    
                    SizedBox(width: 3.w),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle['label'],
                            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppTheme.lightTheme.colorScheme.primary
                                  : null,
                            ),
                          ),
                          Text(
                            vehicle['description'],
                            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    if (isSelected)
                      CustomIconWidget(
                        iconName: 'check_circle',
                        color: AppTheme.lightTheme.colorScheme.primary,
                        size: 6.w,
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
        
        SizedBox(height: 3.h),
        
        // License Plate Input
        Text(
          'License Plate Number',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        
        SizedBox(height: 2.h),
        
        TextFormField(
          controller: _licensePlateController,
          decoration: InputDecoration(
            labelText: 'License Plate',
            hintText: 'e.g. KB1234A',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.confirmation_number),
            helperText: 'Format: KB1234A (Brunei format)',
          ),
          textCapitalization: TextCapitalization.characters,
          onChanged: (value) {
            _updateData();
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter license plate number';
            }
            if (!_isValidLicensePlate(value)) {
              return 'Please enter valid Brunei license plate format';
            }
            return null;
          },
        ),
        
        SizedBox(height: 3.h),
        
        // Vehicle Photos Upload
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _vehiclePhotosUploaded
                  ? AppTheme.lightTheme.colorScheme.tertiary
                  : AppTheme.lightTheme.colorScheme.outline,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: _vehiclePhotosUploaded ? 'check_circle' : 'camera_alt',
                    color: _vehiclePhotosUploaded
                        ? AppTheme.lightTheme.colorScheme.tertiary
                        : AppTheme.lightTheme.colorScheme.primary,
                    size: 6.w,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vehicle Photos',
                          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Upload photos from multiple angles: front, back, left, right',
                          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 2.h),
              
              if (!_vehiclePhotosUploaded) ...[
                ElevatedButton(
                  onPressed: _uploadVehiclePhotos,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                    minimumSize: Size(double.infinity, 5.h),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'add_a_photo',
                        color: Colors.white,
                        size: 5.w,
                      ),
                      SizedBox(width: 2.w),
                      const Text('Upload Vehicle Photos'),
                    ],
                  ),
                ),
                
                SizedBox(height: 2.h),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPhotoRequirement('Front View', 'camera_front'),
                    _buildPhotoRequirement('Back View', 'camera_rear'),
                    _buildPhotoRequirement('Side Views', 'cameraswitch'),
                  ],
                ),
              ] else ...[
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.tertiary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'check',
                        color: AppTheme.lightTheme.colorScheme.tertiary,
                        size: 5.w,
                      ),
                      SizedBox(width: 2.w),
                      const Text('All vehicle photos uploaded successfully'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoRequirement(String label, String iconName) {
    return Column(
      children: [
        Container(
          width: 15.w,
          height: 15.w,
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.outline,
            ),
          ),
          child: CustomIconWidget(
            iconName: iconName,
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 6.w,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    super.dispose();
  }
}