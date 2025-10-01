import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SafetyTrainingWidget extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onDataChanged;

  const SafetyTrainingWidget({
    Key? key,
    required this.initialData,
    required this.onDataChanged,
  }) : super(key: key);

  @override
  State<SafetyTrainingWidget> createState() => _SafetyTrainingWidgetState();
}

class _SafetyTrainingWidgetState extends State<SafetyTrainingWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  Map<String, bool> _moduleCompletion = {
    'deliveryProtocols': false,
    'customerInteraction': false,
    'emergencyProcedures': false,
  };
  
  bool _finalQuizCompleted = false;
  int _currentQuizScore = 0;
  bool _trainingCompleted = false;

  final List<Map<String, dynamic>> _trainingModules = [
{ 'id': 'deliveryProtocols',
'title': 'Delivery Protocols',
'subtitle': 'Learn safe delivery practices',
'icon': 'local_shipping',
'duration': '15 min',
'content': [ 'Package handling and care procedures',
'Proper delivery verification methods',
'Time management and route optimization',
'Weather considerations and safety',
'Vehicle safety and maintenance checks',
],
},
{ 'id': 'customerInteraction',
'title': 'Customer Interaction',
'subtitle': 'Professional communication guidelines',
'icon': 'people',
'duration': '10 min',
'content': [ 'Professional communication standards',
'Handling customer complaints and issues',
'Privacy and confidentiality guidelines',
'Cultural sensitivity and respect',
'Contactless delivery procedures',
],
},
{ 'id': 'emergencyProcedures',
'title': 'Emergency Procedures',
'subtitle': 'What to do in emergency situations',
'icon': 'emergency',
'duration': '12 min',
'content': [ 'Accident reporting and procedures',
'Emergency contact information',
'Medical emergency response',
'Security incident handling',
'Natural disaster protocols',
],
},
];

  final List<Map<String, dynamic>> _quizQuestions = [
{ 'question': 'What should you do if a customer is not available for delivery?',
'options': [ 'Leave package at the door',
'Contact customer and wait for instructions',
'Return package to sender immediately',
'Give package to a neighbor',
],
'correctAnswer': 1,
},
{ 'question': 'In case of a vehicle breakdown, what is your first priority?',
'options': [ 'Fix the vehicle yourself',
'Call for roadside assistance',
'Ensure personal safety first',
'Continue delivery on foot',
],
'correctAnswer': 2,
},
{ 'question': 'How should you handle fragile packages?',
'options': [ 'Handle normally',
'Use extra care and proper positioning',
'Rush delivery to minimize handling time',
'Ask customer to collect personally',
],
'correctAnswer': 1,
},
];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _trainingModules.length, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeData() {
    Map<String, dynamic>? moduleCompletion = widget.initialData['moduleCompletion'];
    _moduleCompletion = Map<String, bool>.from(moduleCompletion ?? {});
      
    _finalQuizCompleted = widget.initialData['finalQuizCompleted'] ?? false;
    _currentQuizScore = widget.initialData['currentQuizScore'] ?? 0;
    _trainingCompleted = widget.initialData['trainingCompleted'] ?? false;
  }

  void _updateData() {
    bool allModulesComplete = _moduleCompletion.values.every((completed) => completed);
    bool isComplete = allModulesComplete && _finalQuizCompleted && _trainingCompleted;
    
    widget.onDataChanged({
      'moduleCompletion': _moduleCompletion,
      'finalQuizCompleted': _finalQuizCompleted,
      'currentQuizScore': _currentQuizScore,
      'trainingCompleted': _trainingCompleted,
      'isComplete': isComplete,
    });
  }

  void _completeModule(String moduleId) {
    setState(() {
      _moduleCompletion[moduleId] = true;
    });
    _updateData();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_getModuleTitle(moduleId)} completed successfully!'),
        backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
      ),
    );
  }

  String _getModuleTitle(String moduleId) {
    return _trainingModules.firstWhere((module) => module['id'] == moduleId)['title'];
  }

  void _startQuiz() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildQuizDialog(),
    );
  }

  Widget _buildQuizDialog() {
    return AlertDialog(
      title: const Text('Safety Training Quiz'),
      content: SizedBox(
        width: double.maxFinite,
        height: 60.h,
        child: _buildQuizContent(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildQuizContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Answer all questions to complete the safety training.',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
        
        SizedBox(height: 2.h),
        
        Expanded(
          child: ListView.builder(
            itemCount: _quizQuestions.length,
            itemBuilder: (context, index) {
              return _buildQuizQuestion(index);
            },
          ),
        ),
        
        SizedBox(height: 2.h),
        
        ElevatedButton(
          onPressed: () => _submitQuiz(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
            minimumSize: Size(double.infinity, 5.h),
          ),
          child: const Text('Submit Quiz'),
        ),
      ],
    );
  }

  Widget _buildQuizQuestion(int questionIndex) {
    Map<String, dynamic> question = _quizQuestions[questionIndex];
    
    return Container(
      margin: EdgeInsets.only(bottom: 3.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Q${questionIndex + 1}. ${question['question']}',
            style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          SizedBox(height: 2.h),
          
          ...List.generate(question['options'].length, (optionIndex) {
            return RadioListTile<int>(
              title: Text(
                question['options'][optionIndex],
                style: AppTheme.lightTheme.textTheme.bodyMedium,
              ),
              value: optionIndex,
              groupValue: null, // In a real implementation, you'd track selected answers
              onChanged: (value) {
                // Handle option selection
              },
            );
          }),
        ],
      ),
    );
  }

  void _submitQuiz() {
    // In a real implementation, you'd calculate the actual score
    int score = 3; // Assuming all correct for demo
    int totalQuestions = _quizQuestions.length;
    double percentage = (score / totalQuestions) * 100;
    
    Navigator.pop(context);
    
    if (percentage >= 80) {
      setState(() {
        _finalQuizCompleted = true;
        _currentQuizScore = score;
        _trainingCompleted = true;
      });
      _updateData();
      
      _showQuizResultDialog(true, score, totalQuestions);
    } else {
      _showQuizResultDialog(false, score, totalQuestions);
    }
  }

  void _showQuizResultDialog(bool passed, int score, int total) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(passed ? 'Quiz Passed!' : 'Quiz Failed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                color: passed
                    ? AppTheme.lightTheme.colorScheme.tertiary.withValues(alpha: 0.1)
                    : AppTheme.lightTheme.colorScheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: CustomIconWidget(
                iconName: passed ? 'check' : 'close',
                color: passed
                    ? AppTheme.lightTheme.colorScheme.tertiary
                    : AppTheme.lightTheme.colorScheme.error,
                size: 10.w,
              ),
            ),
            
            SizedBox(height: 2.h),
            
            Text(
              'Score: $score/$total (${((score/total)*100).toInt()}%)',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            
            SizedBox(height: 1.h),
            
            Text(
              passed
                  ? 'Congratulations! You have successfully completed the safety training.'
                  : 'You need 80% or higher to pass. Please review the training materials and try again.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(passed ? 'Continue' : 'Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool allModulesComplete = _moduleCompletion.values.every((completed) => completed);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Safety Training Course',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        
        SizedBox(height: 1.h),
        
        Text(
          'Complete all training modules and pass the quiz to finish setup',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
        
        SizedBox(height: 3.h),
        
        // Training Progress
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Training Progress',
                    style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${_moduleCompletion.values.where((completed) => completed).length}/${_moduleCompletion.length} modules',
                    style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 2.h),
              
              LinearProgressIndicator(
                value: _moduleCompletion.values.where((completed) => completed).length /
                    _moduleCompletion.length,
                backgroundColor: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 3.h),
        
        // Training Modules
        ..._trainingModules.map((module) {
          bool isCompleted = _moduleCompletion[module['id']] ?? false;
          
          return Container(
            margin: EdgeInsets.only(bottom: 2.h),
            child: _buildTrainingModule(module, isCompleted),
          );
        }).toList(),
        
        SizedBox(height: 3.h),
        
        // Final Quiz Section
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _finalQuizCompleted
                  ? AppTheme.lightTheme.colorScheme.tertiary
                  : allModulesComplete
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.outline,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: _finalQuizCompleted ? 'check_circle' : 'quiz',
                    color: _finalQuizCompleted
                        ? AppTheme.lightTheme.colorScheme.tertiary
                        : allModulesComplete
                            ? AppTheme.lightTheme.colorScheme.primary
                            : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 6.w,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Safety Training Quiz',
                          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _finalQuizCompleted
                              ? 'Quiz completed successfully (Score: $_currentQuizScore/3)'
                              : 'Complete all modules to unlock the quiz',
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
              
              if (!_finalQuizCompleted) ...[
                ElevatedButton(
                  onPressed: allModulesComplete ? _startQuiz : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
                    minimumSize: Size(double.infinity, 5.h),
                  ),
                  child: const Text('Start Final Quiz'),
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
                      const Text('Safety training completed successfully!'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        
        if (_trainingCompleted) ...[
          SizedBox(height: 3.h),
          
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.tertiaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.tertiary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                CustomIconWidget(
                  iconName: 'school',
                  color: AppTheme.lightTheme.colorScheme.tertiary,
                  size: 12.w,
                ),
                
                SizedBox(height: 2.h),
                
                Text(
                  'Training Complete!',
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                SizedBox(height: 1.h),
                
                Text(
                  'You have successfully completed all safety training requirements and are ready to become a delivery runner.',
                  textAlign: TextAlign.center,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTrainingModule(Map<String, dynamic> module, bool isCompleted) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
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
                iconName: isCompleted ? 'check_circle' : module['icon'],
                color: isCompleted
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
                      module['title'],
                      style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${module['subtitle']} • ${module['duration']}',
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
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: module['content'].map<Widget>((item) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 0.5.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 1.h, right: 2.w),
                      width: 1.w,
                      height: 1.w,
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          
          SizedBox(height: 2.h),
          
          if (!isCompleted) ...[
            ElevatedButton(
              onPressed: () => _completeModule(module['id']),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                minimumSize: Size(double.infinity, 5.h),
              ),
              child: Text('Complete ${module['title']}'),
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
                  Text('${module['title']} completed'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}