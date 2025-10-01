
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ChatInputWidget extends StatefulWidget {
  final Function(String, String) onSendMessage;
  final Function(String, String, String?) onSendImage;
  final Function(String, String) onSendVoice;
  final Function(String, String, String) onSendLocation;
  final VoidCallback? onTypingStart;
  final VoidCallback? onTypingStop;

  const ChatInputWidget({
    Key? key,
    required this.onSendMessage,
    required this.onSendImage,
    required this.onSendVoice,
    required this.onSendLocation,
    this.onTypingStart,
    this.onTypingStop,
  }) : super(key: key);

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool _isRecording = false;
  bool _isTyping = false;
  bool _showAttachmentOptions = false;
  List<CameraDescription>? _cameras;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    _initializeCamera();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _cameraController?.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final isTyping = _textController.text.isNotEmpty;
    if (isTyping != _isTyping) {
      setState(() {
        _isTyping = isTyping;
      });
      if (isTyping) {
        widget.onTypingStart?.call();
      } else {
        widget.onTypingStop?.call();
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      if (await _requestCameraPermission()) {
        _cameras = await availableCameras();
        if (_cameras != null && _cameras!.isNotEmpty) {
          final camera = kIsWeb
              ? _cameras!.firstWhere(
                  (c) => c.lensDirection == CameraLensDirection.front,
                  orElse: () => _cameras!.first)
              : _cameras!.firstWhere(
                  (c) => c.lensDirection == CameraLensDirection.back,
                  orElse: () => _cameras!.first);

          _cameraController = CameraController(
              camera, kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high);

          await _cameraController!.initialize();
          await _applySettings();

          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      // Silent fail - camera not available
    }
  }

  Future<bool> _requestCameraPermission() async {
    if (kIsWeb) return true;
    return (await Permission.camera.request()).isGranted;
  }

  Future<void> _applySettings() async {
    if (_cameraController == null) return;
    try {
      await _cameraController!.setFocusMode(FocusMode.auto);
      if (!kIsWeb) {
        try {
          await _cameraController!.setFlashMode(FlashMode.auto);
        } catch (e) {
          // Flash not supported
        }
      }
    } catch (e) {
      // Settings not supported
    }
  }

  Future<void> _sendTextMessage() async {
    if (_textController.text.trim().isEmpty) return;

    final message = _textController.text.trim();
    _textController.clear();
    widget.onSendMessage('text', message);

    // Haptic feedback
    HapticFeedback.lightImpact();
  }

  Future<void> _capturePhoto() async {
    if (!_isCameraInitialized || _cameraController == null) return;

    try {
      final XFile photo = await _cameraController!.takePicture();
      widget.onSendImage('image', photo.path, null);
      HapticFeedback.mediumImpact();
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        widget.onSendImage('image', image.path, null);
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        setState(() {
          _isRecording = true;
        });

        if (kIsWeb) {
          await _audioRecorder.start(
              const RecordConfig(encoder: AudioEncoder.wav),
              path: 'recording.wav');
        } else {
          final dir = await getTemporaryDirectory();
          String path = '${dir.path}/recording.m4a';
          await _audioRecorder.start(const RecordConfig(), path: path);
        }

        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _stopRecording() async {
    try {
      final String? path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });

      if (path != null) {
        widget.onSendVoice('voice', path);
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      );

      if (result != null) {
        final file = result.files.first;
        widget.onSendMessage('file', file.name);
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _shareLocation() {
    // Mock location sharing
    widget.onSendLocation(
        'location', 'Current Location', 'Bandar Seri Begawan, Brunei');
    HapticFeedback.lightImpact();
  }

  void _toggleAttachmentOptions() {
    setState(() {
      _showAttachmentOptions = !_showAttachmentOptions;
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          if (_showAttachmentOptions) _buildAttachmentOptions(),
          Row(
            children: [
              GestureDetector(
                onTap: _toggleAttachmentOptions,
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primary
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: CustomIconWidget(
                    iconName: _showAttachmentOptions ? 'close' : 'attach_file',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 5.w,
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Container(
                  constraints: BoxConstraints(maxHeight: 20.h),
                  decoration: BoxDecoration(
                    color:
                        AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6.w),
                    border: Border.all(
                      color: AppTheme.lightTheme.colorScheme.outline
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle:
                          AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                    ),
                    style: AppTheme.lightTheme.textTheme.bodyMedium,
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              _isTyping
                  ? GestureDetector(
                      onTap: _sendTextMessage,
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: CustomIconWidget(
                          iconName: 'send',
                          color: Colors.white,
                          size: 5.w,
                        ),
                      ),
                    )
                  : GestureDetector(
                      onLongPressStart: (_) => _startRecording(),
                      onLongPressEnd: (_) => _stopRecording(),
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: _isRecording
                              ? AppTheme.lightTheme.colorScheme.error
                              : AppTheme.lightTheme.colorScheme.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: CustomIconWidget(
                          iconName: _isRecording ? 'stop' : 'mic',
                          color: Colors.white,
                          size: 5.w,
                        ),
                      ),
                    ),
            ],
          ),
          if (_isRecording) _buildRecordingIndicator(),
        ],
      ),
    );
  }

  Widget _buildAttachmentOptions() {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildAttachmentOption(
            icon: 'camera_alt',
            label: 'Camera',
            color: AppTheme.lightTheme.colorScheme.primary,
            onTap: _capturePhoto,
          ),
          _buildAttachmentOption(
            icon: 'photo',
            label: 'Gallery',
            color: AppTheme.lightTheme.colorScheme.secondary,
            onTap: _pickImageFromGallery,
          ),
          _buildAttachmentOption(
            icon: 'attach_file',
            label: 'File',
            color: AppTheme.lightTheme.colorScheme.tertiary,
            onTap: _pickFile,
          ),
          _buildAttachmentOption(
            icon: 'location_on',
            label: 'Location',
            color: AppTheme.lightTheme.colorScheme.error,
            onTap: _shareLocation,
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption({
    required String icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: CustomIconWidget(
              iconName: icon,
              color: color,
              size: 6.w,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    return Container(
      margin: EdgeInsets.only(top: 2.h),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4.w),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 2.w,
            height: 2.w,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.error,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 2.w),
          Text(
            'Recording... Release to send, slide to cancel',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}
