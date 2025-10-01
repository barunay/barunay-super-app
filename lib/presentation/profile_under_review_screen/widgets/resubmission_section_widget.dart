import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class ResubmissionSectionWidget extends StatefulWidget {
  final List<String> missingDocuments;
  final Function(String, String) onDocumentUpload;

  const ResubmissionSectionWidget({
    super.key,
    required this.missingDocuments,
    required this.onDocumentUpload,
  });

  @override
  State<ResubmissionSectionWidget> createState() =>
      _ResubmissionSectionWidgetState();
}

class _ResubmissionSectionWidgetState extends State<ResubmissionSectionWidget> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.upload_file,
                color: Colors.orange,
                size: 6.w,
              ),
              SizedBox(width: 2.w),
              Text(
                'Document Resubmission Required',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),

          Text(
            'The following documents need to be updated or resubmitted:',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: Colors.orange.shade700,
            ),
          ),
          SizedBox(height: 2.h),

          // Missing documents list
          ...widget.missingDocuments
              .map((doc) => Container(
                    margin: EdgeInsets.only(bottom: 2.h),
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: Colors.orange,
                          size: 5.w,
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doc,
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 0.5.h),
                              Text(
                                _getDocumentRequirements(doc),
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed:
                              _isUploading ? null : () => _uploadDocument(doc),
                          icon: _isUploading
                              ? SizedBox(
                                  width: 4.w,
                                  height: 4.w,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(Icons.upload, size: 4.w),
                          label: Text(
                            'Upload',
                            style: GoogleFonts.inter(fontSize: 12.sp),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 3.w,
                              vertical: 1.h,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),

          SizedBox(height: 2.h),

          // File format requirements
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info,
                      color: Colors.blue,
                      size: 5.w,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'File Requirements',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                Text(
                  '• Supported formats: JPG, PNG, PDF\n'
                  '• Maximum file size: 5MB\n'
                  '• Image should be clear and readable\n'
                  '• Document should be complete and uncut',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getDocumentRequirements(String documentType) {
    switch (documentType) {
      case 'Identity Documents':
        return 'Clear photo of national ID or passport (both sides if applicable)';
      case 'Business Registration':
        return 'Official business license or registration certificate';
      case 'Bank Details':
        return 'Bank statement or account verification document';
      default:
        return 'Please upload the required document';
    }
  }

  void _uploadDocument(String documentType) async {
    setState(() => _isUploading = true);

    try {
      // Simulate file picker and upload
      await Future.delayed(Duration(seconds: 2));

      // In a real implementation, you would:
      // 1. Show file picker
      // 2. Upload selected file
      // 3. Call the callback with document type and file path

      widget.onDocumentUpload(documentType, 'path/to/uploaded/file');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$documentType uploaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload $documentType: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }
}
