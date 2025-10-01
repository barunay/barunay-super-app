import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AvailabilityPreferencesWidget extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onDataChanged;

  const AvailabilityPreferencesWidget({
    Key? key,
    required this.initialData,
    required this.onDataChanged,
  }) : super(key: key);

  @override
  State<AvailabilityPreferencesWidget> createState() =>
      _AvailabilityPreferencesWidgetState();
}

class _AvailabilityPreferencesWidgetState
    extends State<AvailabilityPreferencesWidget> {
  Map<String, Map<String, dynamic>> _weeklySchedule = {};
  List<String> _selectedDistricts = [];
  double _maxDeliveryRadius = 10.0;

  final List<String> _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final List<String> _bruneiDistricts = [
    'Bandar Seri Begawan',
    'Gadong',
    'Kiulap',
    'Jerudong',
    'Seria',
    'Kuala Belait',
    'Tutong',
    'Bangar',
    'Temburong',
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _selectedDistricts =
        List<String>.from(widget.initialData['selectedDistricts'] ?? []);
    _maxDeliveryRadius = widget.initialData['maxDeliveryRadius'] ?? 10.0;

    // Initialize weekly schedule
    for (String day in _weekDays) {
      _weeklySchedule[day] = {
        'startTime': null,
        'endTime': null,
        'isEnabled': false,
      };
    }

    // Load existing schedule if any
    Map<String, dynamic>? savedSchedule = widget.initialData['weeklySchedule'];
    if (savedSchedule != null) {
      for (String day in _weekDays) {
        if (savedSchedule[day] != null) {
          Map<String, dynamic> dayData = savedSchedule[day];
          _weeklySchedule[day] = {
            'startTime': dayData['startTime'] != null
                ? TimeOfDay(
                    hour: dayData['startTime']['hour'],
                    minute: dayData['startTime']['minute'],
                  )
                : null,
            'endTime': dayData['endTime'] != null
                ? TimeOfDay(
                    hour: dayData['endTime']['hour'],
                    minute: dayData['endTime']['minute'],
                  )
                : null,
            'isEnabled': dayData['isEnabled'] ?? false,
          };
        }
      }
    }
  }

  void _updateData() {
    bool hasSchedule =
        _weeklySchedule.values.any((day) => day['isEnabled'] == true);
    bool hasDistricts = _selectedDistricts.isNotEmpty;
    bool isComplete = hasSchedule && hasDistricts;

    // Convert TimeOfDay to serializable format
    Map<String, dynamic> serializedSchedule = {};
    for (String day in _weekDays) {
      serializedSchedule[day] = {
        'startTime': _weeklySchedule[day]?['startTime'] != null
            ? {
                'hour': (_weeklySchedule[day]?['startTime'] as TimeOfDay).hour,
                'minute':
                    (_weeklySchedule[day]?['startTime'] as TimeOfDay).minute,
              }
            : null,
        'endTime': _weeklySchedule[day]?['endTime'] != null
            ? {
                'hour': (_weeklySchedule[day]?['endTime'] as TimeOfDay).hour,
                'minute':
                    (_weeklySchedule[day]?['endTime'] as TimeOfDay).minute,
              }
            : null,
        'isEnabled': _weeklySchedule[day]?['isEnabled'] ?? false,
      };
    }

    widget.onDataChanged({
      'weeklySchedule': serializedSchedule,
      'selectedDistricts': _selectedDistricts,
      'maxDeliveryRadius': _maxDeliveryRadius,
      'isComplete': isComplete,
    });
  }

  Future<void> _selectTime(String day, String timeType) async {
    TimeOfDay? currentTime = _weeklySchedule[day]?[timeType];
    TimeOfDay initialTime = currentTime ?? TimeOfDay.now();

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: 'Select ${timeType == 'startTime' ? 'Start' : 'End'} Time',
    );

    if (pickedTime != null) {
      setState(() {
        _weeklySchedule[day]?[timeType] = pickedTime;
        _weeklySchedule[day]?['isEnabled'] = true;
      });
      _updateData();
    }
  }

  void _toggleDay(String day, bool isEnabled) {
    setState(() {
      _weeklySchedule[day]?['isEnabled'] = isEnabled;
      if (!isEnabled) {
        _weeklySchedule[day]?['startTime'] = null;
        _weeklySchedule[day]?['endTime'] = null;
      }
    });
    _updateData();
  }

  void _toggleDistrict(String district) {
    setState(() {
      if (_selectedDistricts.contains(district)) {
        _selectedDistricts.remove(district);
      } else {
        _selectedDistricts.add(district);
      }
    });
    _updateData();
  }

  String _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return '--:--';
    final String hour = time.hour.toString().padLeft(2, '0');
    final String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Schedule Setting
        Text(
          'Working Schedule',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

        SizedBox(height: 1.h),

        Text(
          'Set your preferred working hours for each day',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),

        SizedBox(height: 3.h),

        Container(
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.outline,
            ),
          ),
          child: Column(
            children: _weekDays.map((day) {
              bool isEnabled = (_weeklySchedule[day]?['isEnabled'] as bool?) ?? false;
              TimeOfDay? startTime = _weeklySchedule[day]?['startTime'];
              TimeOfDay? endTime = _weeklySchedule[day]?['endTime'];

              return Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  border: _weekDays.indexOf(day) != _weekDays.length - 1
                      ? Border(
                          bottom: BorderSide(
                            color: AppTheme.lightTheme.colorScheme.outline
                                .withValues(alpha: 0.3),
                          ),
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20.w,
                      child: Text(
                        day,
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Switch(
                      value: isEnabled,
                      onChanged: (value) => _toggleDay(day, value),
                    ),
                    SizedBox(width: 4.w),
                    if (isEnabled) ...[
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _selectTime(day, 'startTime'),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 3.w,
                                    vertical: 1.5.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.lightTheme.colorScheme
                                        .surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppTheme
                                          .lightTheme.colorScheme.outline,
                                    ),
                                  ),
                                  child: Text(
                                    _formatTimeOfDay(startTime),
                                    textAlign: TextAlign.center,
                                    style: AppTheme
                                        .lightTheme.textTheme.bodyMedium,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 2.w),
                              child: const Text('-'),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _selectTime(day, 'endTime'),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 3.w,
                                    vertical: 1.5.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.lightTheme.colorScheme
                                        .surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppTheme
                                          .lightTheme.colorScheme.outline,
                                    ),
                                  ),
                                  child: Text(
                                    _formatTimeOfDay(endTime),
                                    textAlign: TextAlign.center,
                                    style: AppTheme
                                        .lightTheme.textTheme.bodyMedium,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: Text(
                          'Off',
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        SizedBox(height: 4.h),

        // Delivery Areas
        Text(
          'Preferred Delivery Areas',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

        SizedBox(height: 1.h),

        Text(
          'Select districts where you prefer to deliver',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),

        SizedBox(height: 3.h),

        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: _bruneiDistricts.map((district) {
            bool isSelected = _selectedDistricts.contains(district);

            return GestureDetector(
              onTap: () => _toggleDistrict(district),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.colorScheme.outline,
                  ),
                ),
                child: Text(
                  district,
                  style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? Colors.white
                        : AppTheme.lightTheme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        SizedBox(height: 4.h),

        // Maximum Delivery Radius
        Text(
          'Maximum Delivery Radius',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

        SizedBox(height: 1.h),

        Text(
          'Set your maximum delivery distance (${_maxDeliveryRadius.toInt()} km)',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),

        SizedBox(height: 2.h),

        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.outline,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('5 km'),
                  Text('${_maxDeliveryRadius.toInt()} km'),
                  Text('25 km'),
                ],
              ),
              Slider(
                value: _maxDeliveryRadius,
                min: 5.0,
                max: 25.0,
                divisions: 20,
                label: '${_maxDeliveryRadius.toInt()} km',
                onChanged: (value) {
                  setState(() {
                    _maxDeliveryRadius = value;
                  });
                  _updateData();
                },
              ),
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primaryContainer
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'info',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 5.w,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        'Larger radius = more delivery opportunities but longer travel times',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 3.h),

        // Quick Setup Options
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.tertiaryContainer
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.tertiary
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Setup',
                style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.tertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _setWeekdaySchedule(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppTheme.lightTheme.colorScheme.tertiary,
                        ),
                      ),
                      child: Text(
                        'Weekdays Only',
                        style: TextStyle(
                          color: AppTheme.lightTheme.colorScheme.tertiary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _setFullTimeSchedule(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppTheme.lightTheme.colorScheme.tertiary,
                        ),
                      ),
                      child: Text(
                        'Full Time',
                        style: TextStyle(
                          color: AppTheme.lightTheme.colorScheme.tertiary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _setWeekdaySchedule() {
    List<String> weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday'
    ];

    setState(() {
      for (String day in _weekDays) {
        if (weekdays.contains(day)) {
          _weeklySchedule[day] = {
            'startTime': const TimeOfDay(hour: 9, minute: 0),
            'endTime': const TimeOfDay(hour: 17, minute: 0),
            'isEnabled': true,
          };
        } else {
          _weeklySchedule[day] = {
            'startTime': null,
            'endTime': null,
            'isEnabled': false,
          };
        }
      }
    });
    _updateData();
  }

  void _setFullTimeSchedule() {
    setState(() {
      for (String day in _weekDays) {
        _weeklySchedule[day] = {
          'startTime': const TimeOfDay(hour: 8, minute: 0),
          'endTime': const TimeOfDay(hour: 22, minute: 0),
          'isEnabled': true,
        };
      }
    });
    _updateData();
  }
}