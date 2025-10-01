import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';
import 'package:time_range_picker/time_range_picker.dart';

import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';

class ShopCustomizationSectionWidget extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(String, dynamic) onDataChanged;

  const ShopCustomizationSectionWidget({
    Key? key,
    required this.formData,
    required this.onDataChanged,
  }) : super(key: key);

  @override
  State<ShopCustomizationSectionWidget> createState() =>
      _ShopCustomizationSectionWidgetState();
}

class _ShopCustomizationSectionWidgetState
    extends State<ShopCustomizationSectionWidget> {
  bool _isUploadingLogo = false;
  bool _isUploadingBanner = false;
  Map<String, Map<String, TimeOfDay?>> _operatingHours = {};
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeOperatingHours();
  }

  void _initializeOperatingHours() {
    // Fix null safety issue - safely handle the operatingHours data
    final existingHours = widget.formData['operatingHours'];
    Map<String, dynamic> hoursMap = {};

    if (existingHours != null && existingHours is Map<String, dynamic>) {
      hoursMap = existingHours;
    }

    final daysOfWeek = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    for (String day in daysOfWeek) {
      final dayData = hoursMap[day];
      Map<String, dynamic>? dayMap;

      if (dayData != null && dayData is Map<String, dynamic>) {
        dayMap = dayData;
      }

      _operatingHours[day] = {
        'start': dayMap?['start'] != null
            ? _timeFromString(dayMap!['start'].toString())
            : null,
        'end': dayMap?['end'] != null
            ? _timeFromString(dayMap!['end'].toString())
            : null,
      };
    }
  }

  TimeOfDay? _timeFromString(String timeStr) {
    try {
      // Add null safety check
      if (timeStr.isEmpty) return null;

      final parts = timeStr.split(':');
      if (parts.length != 2) return null;

      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);

      if (hour == null || minute == null) return null;
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }

  String _timeToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Automatic image processing to fit required aspect ratios
  Future<Uint8List> _processImageAutomatically(
    Uint8List imageBytes, {
    required bool isLogo,
  }) async {
    try {
      // Decode the image
      final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image originalImage = frameInfo.image;

      final int originalWidth = originalImage.width;
      final int originalHeight = originalImage.height;

      // Calculate target dimensions based on type
      int targetWidth, targetHeight;

      if (isLogo) {
        // Square format (1:1) for logo
        final int size =
            originalWidth < originalHeight ? originalWidth : originalHeight;
        targetWidth = size > 512 ? 512 : size;
        targetHeight = targetWidth;
      } else {
        // 16:9 format for banner
        if (originalWidth / originalHeight > 16 / 9) {
          // Image is wider than 16:9, fit by height
          targetHeight = originalHeight > 675 ? 675 : originalHeight;
          targetWidth = (targetHeight * 16 / 9).round();
        } else {
          // Image is taller than 16:9, fit by width
          targetWidth = originalWidth > 1200 ? 1200 : originalWidth;
          targetHeight = (targetWidth * 9 / 16).round();
        }
      }

      // Create a picture recorder to draw the processed image
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      final Paint paint = Paint()..isAntiAlias = true;

      // Calculate crop area for center crop
      double sourceX = 0,
          sourceY = 0,
          sourceWidth = originalWidth.toDouble(),
          sourceHeight = originalHeight.toDouble();

      if (isLogo) {
        // Center crop to square
        final int size =
            originalWidth < originalHeight ? originalWidth : originalHeight;
        sourceX = (originalWidth - size) / 2;
        sourceY = (originalHeight - size) / 2;
        sourceWidth = size.toDouble();
        sourceHeight = size.toDouble();
      } else {
        // Center crop to 16:9
        final double targetAspectRatio = 16 / 9;
        final double originalAspectRatio = originalWidth / originalHeight;

        if (originalAspectRatio > targetAspectRatio) {
          // Image is wider, crop width
          sourceWidth = (originalHeight * targetAspectRatio);
          sourceX = (originalWidth - sourceWidth) / 2;
          sourceY = 0;
          sourceHeight = originalHeight.toDouble();
        } else {
          // Image is taller, crop height
          sourceHeight = (originalWidth / targetAspectRatio);
          sourceX = 0;
          sourceY = (originalHeight - sourceHeight) / 2;
          sourceWidth = originalWidth.toDouble();
        }
      }

      // Draw the cropped and resized image
      canvas.drawImageRect(
        originalImage,
        Rect.fromLTWH(sourceX, sourceY, sourceWidth, sourceHeight),
        Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
        paint,
      );

      // Convert to image
      final ui.Picture picture = recorder.endRecording();
      final ui.Image processedImage =
          await picture.toImage(targetWidth, targetHeight);

      // Convert to bytes
      final ByteData? byteData =
          await processedImage.toByteData(format: ui.ImageByteFormat.png);

      // Clean up
      originalImage.dispose();
      processedImage.dispose();
      picture.dispose();

      return byteData!.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error processing image: $e');
      // Return original image bytes if processing fails
      return imageBytes;
    }
  }

  Future<String?> _uploadImageToSupabase(
    Uint8List imageBytes,
    String filePrefix,
    String folder,
  ) async {
    try {
      // Safe null checking for user authentication
      final user = SupabaseService.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Generate unique filename
      final fileName =
          '${filePrefix}_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '${user.id}/$folder/$fileName';

      // Upload to Supabase Storage
      await SupabaseService.instance.client.storage
          .from('shop-assets') // Use shop-assets bucket
          .uploadBinary(filePath, imageBytes);

      // Get public URL
      final publicUrl = SupabaseService.instance.client.storage
          .from('shop-assets')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading to Supabase: $e');
      throw Exception('Failed to upload image');
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Select Image Source',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primary
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: 'camera_alt',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 6.w,
                    ),
                  ),
                ),
                title: Text(
                  'Take Photo',
                  style: AppTheme.lightTheme.textTheme.titleMedium,
                ),
                subtitle: Text(
                  'Use device camera',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              SizedBox(height: 1.h),
              ListTile(
                leading: Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.secondary
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: 'photo_library',
                      color: AppTheme.lightTheme.colorScheme.secondary,
                      size: 6.w,
                    ),
                  ),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: AppTheme.lightTheme.textTheme.titleMedium,
                ),
                subtitle: Text(
                  'Select from device storage',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _setOperatingHours() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Set Operating Hours'),
          content: SizedBox(
            width: double.maxFinite,
            height: 60.h,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Configure your shop operating hours for each day',
                    style: AppTheme.lightTheme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 2.h),
                  ..._operatingHours.keys
                      .map((day) => _buildDayTimePicker(
                            day: day,
                            setDialogState: setDialogState,
                          ))
                      .toList(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _saveOperatingHours();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayTimePicker({
    required String day,
    required StateSetter setDialogState,
  }) {
    // Safe null checking for day hours
    final dayHours = _operatingHours[day];
    if (dayHours == null) return const SizedBox.shrink();

    final isClosed = dayHours['start'] == null || dayHours['end'] == null;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                day,
                style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Switch(
                value: !isClosed,
                onChanged: (value) {
                  setDialogState(() {
                    if (value) {
                      _operatingHours[day] = {
                        'start': const TimeOfDay(hour: 9, minute: 0),
                        'end': const TimeOfDay(hour: 18, minute: 0),
                      };
                    } else {
                      _operatingHours[day] = {
                        'start': null,
                        'end': null,
                      };
                    }
                  });
                },
              ),
            ],
          ),
          if (!isClosed) ...[
            SizedBox(height: 1.h),
            Row(
              children: [
                Expanded(
                  child: _buildTimeButton(
                    'Start Time',
                    dayHours['start'],
                    (time) {
                      setDialogState(() {
                        // Safe null checking before updating
                        if (_operatingHours[day] != null) {
                          _operatingHours[day]!['start'] = time;
                        }
                      });
                    },
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: _buildTimeButton(
                    'End Time',
                    dayHours['end'],
                    (time) {
                      setDialogState(() {
                        // Safe null checking before updating
                        if (_operatingHours[day] != null) {
                          _operatingHours[day]!['end'] = time;
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Center(
              child: OutlinedButton.icon(
                onPressed: () => _showTimeRangePicker(day, setDialogState),
                icon: const Icon(Icons.schedule),
                label: const Text('Set Time Range'),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(40.w, 5.h),
                ),
              ),
            ),
          ] else ...[
            SizedBox(height: 1.h),
            Center(
              child: Text(
                'Closed',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeButton(
      String label, TimeOfDay? time, Function(TimeOfDay) onTimeSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 0.5.h),
        OutlinedButton(
          onPressed: () async {
            final TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: time ?? TimeOfDay.now(),
            );
            if (picked != null) {
              onTimeSelected(picked);
            }
          },
          child: Text(
            time?.format(context) ?? 'Select Time',
            style: AppTheme.lightTheme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  void _showTimeRangePicker(String day, StateSetter setDialogState) async {
    // Safe null checking
    final currentHours = _operatingHours[day];
    if (currentHours == null) return;

    TimeRange? result = await showTimeRangePicker(
      context: context,
      start: currentHours['start'] ?? const TimeOfDay(hour: 9, minute: 0),
      end: currentHours['end'] ?? const TimeOfDay(hour: 18, minute: 0),
      strokeWidth: 4,
      ticks: 12,
      ticksColor: AppTheme.lightTheme.colorScheme.primary,
      labels: [
        ClockLabel.fromIndex(idx: 0, length: 8, text: "12 AM"),
        ClockLabel.fromIndex(idx: 1, length: 8, text: "3 AM"),
        ClockLabel.fromIndex(idx: 2, length: 8, text: "6 AM"),
        ClockLabel.fromIndex(idx: 3, length: 8, text: "9 AM"),
        ClockLabel.fromIndex(idx: 4, length: 8, text: "12 PM"),
        ClockLabel.fromIndex(idx: 5, length: 8, text: "3 PM"),
        ClockLabel.fromIndex(idx: 6, length: 8, text: "6 PM"),
        ClockLabel.fromIndex(idx: 7, length: 8, text: "9 PM")
      ],
      labelOffset: 35,
      rotateLabels: false,
      padding: 60,
    );

    if (result != null) {
      setDialogState(() {
        _operatingHours[day] = {
          'start': result.startTime,
          'end': result.endTime,
        };
      });
    }
  }

  void _saveOperatingHours() {
    final Map<String, Map<String, String>> hoursData = {};

    _operatingHours.forEach((day, times) {
      if (times['start'] != null && times['end'] != null) {
        hoursData[day] = {
          'start': _timeToString(times['start']!),
          'end': _timeToString(times['end']!),
          'isOpen': 'true',
        };
      } else {
        hoursData[day] = {
          'isOpen': 'false',
        };
      }
    });

    widget.onDataChanged('operatingHours', hoursData);

    Fluttertoast.showToast(
      msg: "Operating hours saved successfully",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  String _getOperatingHoursDisplay() {
    final openDays = _operatingHours.entries
        .where((entry) =>
            entry.value['start'] != null && entry.value['end'] != null)
        .length;

    if (openDays == 0) {
      return 'Set your shop operating hours';
    } else if (openDays == 7) {
      return 'Open all days - Hours configured';
    } else {
      return 'Open $openDays days - Hours configured';
    }
  }

  Future<void> _uploadImage({required bool isLogo}) async {
    try {
      // Show image source dialog
      final ImageSource? source = await _showImageSourceDialog();
      if (source == null) return;

      if (isLogo) {
        setState(() => _isUploadingLogo = true);
      } else {
        setState(() => _isUploadingBanner = true);
      }

      // Pick image with appropriate quality settings
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: isLogo ? 1024 : 1920,
        maxHeight: isLogo ? 1024 : 1080,
        imageQuality: 90,
      );

      if (pickedFile == null) return;

      // Get image bytes
      final Uint8List imageBytes = await pickedFile.readAsBytes();

      // Automatically process image to fit required aspect ratio
      final Uint8List processedBytes = await _processImageAutomatically(
        imageBytes,
        isLogo: isLogo,
      );

      // Upload to Supabase
      final String? imageUrl = await _uploadImageToSupabase(
        processedBytes,
        isLogo ? 'shop_logo' : 'shop_banner',
        isLogo ? 'logos' : 'banners',
      );

      if (imageUrl != null) {
        widget.onDataChanged(
          isLogo ? 'shopLogo' : 'bannerImage',
          imageUrl,
        );

        Fluttertoast.showToast(
          msg: isLogo
              ? "Shop logo uploaded and automatically fitted!"
              : "Banner image uploaded and automatically fitted!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      Fluttertoast.showToast(
        msg: "Failed to upload image. Please try again.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() {
          if (isLogo) {
            _isUploadingLogo = false;
          } else {
            _isUploadingBanner = false;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Text(
            'Shop Customization',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Customize your shop appearance to attract more customers.',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),

          SizedBox(height: 3.h),

          // Shop logo upload
          _buildImageUploadCard(
            title: 'Shop Logo',
            subtitle: 'Upload your shop logo (Required)',
            isRequired: true,
            isUploaded: widget.formData['shopLogo'] != null,
            isUploading: _isUploadingLogo,
            onTap: () => _uploadImage(isLogo: true),
            aspectRatio: '1:1 (Square)',
            maxSize: '2MB max',
            imageUrl: widget.formData['shopLogo']?.toString(),
            autoProcessInfo:
                'Images are automatically resized and fitted to square format',
          ),

          SizedBox(height: 2.h),

          // Banner image upload
          _buildImageUploadCard(
            title: 'Banner Image',
            subtitle: 'Upload a cover image for your shop (Optional)',
            isRequired: false,
            isUploaded: widget.formData['bannerImage'] != null,
            isUploading: _isUploadingBanner,
            onTap: () => _uploadImage(isLogo: false),
            aspectRatio: '16:9 (Landscape)',
            maxSize: '5MB max',
            imageUrl: widget.formData['bannerImage']?.toString(),
            autoProcessInfo:
                'Images are automatically resized and fitted to landscape format',
          ),

          SizedBox(height: 3.h),

          // Operating hours
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primary
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: 'schedule',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 6.w,
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Operating Hours',
                        style:
                            AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        _getOperatingHoursDisplay(),
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _setOperatingHours,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(20.w, 5.h),
                  ),
                  child: Text(
                    'Set Hours',
                    style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 3.h),

          // Design Tips Section
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primaryContainer
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.primaryContainer
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'lightbulb',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 5.w,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Design Tips',
                      style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lightTheme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                _buildTip(
                  'Logo should be square (1:1 ratio) and clear',
                ),
                _buildTip(
                  'Banner works best in landscape (16:9 ratio)',
                ),
                _buildTip(
                  'Use high-quality images for better impression',
                ),
                _buildTip(
                  'Images will automatically fit the required dimensions',
                ),
              ],
            ),
          ),

          SizedBox(height: 3.h),

          // Preview section
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'preview',
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                      size: 5.w,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Shop Preview',
                      style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),

                // Mock shop preview
                Container(
                  width: double.infinity,
                  height: 15.h,
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.lightTheme.colorScheme.outline
                          .withValues(alpha: 0.2),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Banner placeholder or image
                      Container(
                        width: double.infinity,
                        height: 8.h,
                        decoration: BoxDecoration(
                          color: widget.formData['bannerImage'] != null
                              ? Colors.transparent
                              : AppTheme.lightTheme.colorScheme
                                  .surfaceContainerHighest,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          image: widget.formData['bannerImage'] != null
                              ? DecorationImage(
                                  image: NetworkImage(widget
                                      .formData['bannerImage']
                                      .toString()),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: widget.formData['bannerImage'] == null
                            ? Center(
                                child: Text(
                                  'No Banner',
                                  style: AppTheme.lightTheme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: AppTheme.lightTheme.colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              )
                            : null,
                      ),

                      // Logo placeholder or image
                      Positioned(
                        left: 4.w,
                        top: 5.h,
                        child: Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: BoxDecoration(
                            color: widget.formData['shopLogo'] != null
                                ? Colors.transparent
                                : AppTheme.lightTheme.colorScheme.outline
                                    .withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.lightTheme.colorScheme.surface,
                              width: 2,
                            ),
                            image: widget.formData['shopLogo'] != null
                                ? DecorationImage(
                                    image: NetworkImage(
                                        widget.formData['shopLogo'].toString()),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: widget.formData['shopLogo'] == null
                              ? Center(
                                  child: CustomIconWidget(
                                    iconName: 'add_photo_alternate',
                                    color: AppTheme.lightTheme.colorScheme
                                        .onSurfaceVariant,
                                    size: 4.w,
                                  ),
                                )
                              : null,
                        ),
                      ),

                      // Shop name and info - Fix null safety
                      Positioned(
                        left: 16.w,
                        bottom: 2.h,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (widget.formData['shopName']
                                          ?.toString()
                                          .isNotEmpty ==
                                      true)
                                  ? widget.formData['shopName'].toString()
                                  : 'Your Shop Name',
                              style: AppTheme.lightTheme.textTheme.titleSmall
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _getOperatingHoursDisplay(),
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadCard({
    required String title,
    required String subtitle,
    required bool isRequired,
    required bool isUploaded,
    required bool isUploading,
    required VoidCallback onTap,
    required String aspectRatio,
    required String maxSize,
    String? imageUrl,
    String? autoProcessInfo,
  }) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUploaded
              ? AppTheme.lightTheme.colorScheme.tertiary
              : AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
          width: isUploaded ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: isUploaded
                      ? AppTheme.lightTheme.colorScheme.tertiary
                          .withValues(alpha: 0.1)
                      : AppTheme.lightTheme.colorScheme.primary
                          .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isUploading
                      ? SizedBox(
                          width: 5.w,
                          height: 5.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.lightTheme.colorScheme.primary,
                          ),
                        )
                      : CustomIconWidget(
                          iconName: isUploaded
                              ? 'check_circle'
                              : 'add_photo_alternate',
                          color: isUploaded
                              ? AppTheme.lightTheme.colorScheme.tertiary
                              : AppTheme.lightTheme.colorScheme.primary,
                          size: 6.w,
                        ),
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: AppTheme.lightTheme.textTheme.titleSmall
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isUploaded
                                ? AppTheme.lightTheme.colorScheme.tertiary
                                : AppTheme.lightTheme.colorScheme.onSurface,
                          ),
                        ),
                        if (isRequired) ...[
                          SizedBox(width: 1.w),
                          Text(
                            '*',
                            style: AppTheme.lightTheme.textTheme.titleSmall
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      subtitle,
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: isUploading ? null : onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isUploaded
                      ? AppTheme.lightTheme.colorScheme.tertiary
                      : AppTheme.lightTheme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: Size(20.w, 5.h),
                ),
                child: Text(
                  isUploaded ? 'Change' : 'Upload',
                  style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          // Show uploaded image preview
          if (isUploaded && imageUrl != null) ...[
            SizedBox(height: 2.h),
            Container(
              width: double.infinity,
              height: title.contains('Banner') ? 20.w : 20.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.3),
                ),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ] else if (!isUploaded) ...[
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'aspect_ratio',
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        size: 4.w,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        aspectRatio,
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'file_download',
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 4.w,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      maxSize,
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Auto processing info
            if (autoProcessInfo != null) ...[
              SizedBox(height: 1.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.tertiary
                      .withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.tertiary
                        .withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'auto_fix_high',
                      color: AppTheme.lightTheme.colorScheme.tertiary,
                      size: 4.w,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        autoProcessInfo,
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.tertiary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 1.5.w,
            height: 1.5.w,
            margin: EdgeInsets.only(top: 1.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              tip,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
