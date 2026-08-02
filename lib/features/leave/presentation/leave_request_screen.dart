import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/data/providers.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

class LeaveRequestScreen extends ConsumerStatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  ConsumerState<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends ConsumerState<LeaveRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedLeaveType;
  DateTime? _startDate;
  DateTime? _endDate;
  final _reasonController = TextEditingController();
  bool _isLoading = false;
  XFile? _selectedFile;
  final _imagePicker = ImagePicker();

  final Map<String, String> _leaveTypes = {
    'Annual': AppStrings.annualLeave,
    'Sick': AppStrings.sickLeave,
    'Emergency': AppStrings.emergencyLeave,
    'Personal': AppStrings.personalLeave,
    'Maternity': AppStrings.maternityLeave,
    'Unpaid': AppStrings.unpaidLeave,
  };

  Future<void> _selectDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? DateTime.now() : (_startDate ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select start and end dates', style: GoogleFonts.inter()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_selectedLeaveType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a leave type', style: GoogleFonts.inter()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final leaveType = _leaveTypes.entries
          .firstWhere((e) => e.value == _selectedLeaveType)
          .key;

      await ref.read(leaveRepositoryProvider).submitLeaveRequest(
            leaveType: leaveType,
            startDate: _startDate!,
            endDate: _endDate!,
            reason: _reasonController.text.trim(),
          );

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Leave request submitted successfully!', style: GoogleFonts.inter()),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        if (context.mounted) context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit leave request. Please try again.', style: GoogleFonts.inter()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final picked = await _imagePicker.pickMedia(
      imageQuality: 85,
    );
    if (picked != null) {
      final ext = picked.name.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'heic', 'heif'].contains(ext)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Only JPG, and PNG files are allowed', style: GoogleFonts.inter()),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      setState(() => _selectedFile = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.requestLeaveTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.leaveType,
                style: GoogleFonts.inter(
                  fontSize: AppSizes.s14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(AppSizes.r12),
                  border: Border.all(color: AppColors.grey200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLeaveType,
                    isExpanded: true,
                    hint: Text(
                      AppStrings.selectLeaveType,
                      style: GoogleFonts.inter(
                        fontSize: AppSizes.s14,
                        color: AppColors.grey400,
                      ),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    items: _leaveTypes.entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.value,
                        child: Text(
                          entry.value,
                          style: GoogleFonts.inter(fontSize: AppSizes.s14),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedLeaveType = value);
                    },
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 500.ms),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: AppStrings.startDate,
                      date: _startDate,
                      onTap: () => _selectDate(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _DateField(
                      label: AppStrings.endDate,
                      date: _endDate,
                      onTap: () => _selectDate(isStart: false),
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 500.ms),

              const SizedBox(height: 20),

              CustomTextField(
                controller: _reasonController,
                labelText: AppStrings.reason,
                hintText: AppStrings.reasonHint,
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide a reason';
                  }
                  return null;
                },
              )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 500.ms),

              const SizedBox(height: 20),

              _DocumentUpload(
                selectedFile: _selectedFile,
                onPickFile: _pickFile,
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 500.ms),

              const SizedBox(height: 32),

              PrimaryButton(
                text: AppStrings.submitRequest,
                onPressed: _submitRequest,
                isLoading: _isLoading,
                width: double.infinity,
                icon: Icons.send_rounded,
              )
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: AppSizes.s14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).inputDecorationTheme.fillColor,
              borderRadius: BorderRadius.circular(AppSizes.r12),
              border: Border.all(
                color: date != null ? AppColors.primary : AppColors.grey200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 20,
                  color: date != null ? AppColors.primary : AppColors.grey400,
                ),
                const SizedBox(width: 12),
                Text(
                  date != null
                      ? '${date!.day}/${date!.month}/${date!.year}'
                      : 'Select date',
                  style: GoogleFonts.inter(
                    fontSize: AppSizes.s14,
                    color: date != null
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : AppColors.grey400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DocumentUpload extends StatelessWidget {
  final XFile? selectedFile;
  final VoidCallback onPickFile;

  const _DocumentUpload({this.selectedFile, required this.onPickFile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.attachDocument,
          style: GoogleFonts.inter(
            fontSize: AppSizes.s14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onPickFile,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: selectedFile != null ? AppColors.success.withValues(alpha: 0.05) : AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppSizes.r12),
              border: Border.all(
                color: selectedFile != null ? AppColors.success : AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: (selectedFile != null ? AppColors.success : AppColors.primary).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    selectedFile != null ? Icons.check_circle_rounded : Icons.cloud_upload_rounded,
                    size: 28,
                    color: selectedFile != null ? AppColors.success : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  selectedFile != null ? selectedFile!.name : 'Tap to upload file',
                  style: GoogleFonts.inter(
                    fontSize: AppSizes.s14,
                    fontWeight: FontWeight.w600,
                    color: selectedFile != null ? AppColors.success : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  selectedFile != null ? 'Tap to change file' : 'JPG or PNG (Max 5MB)',
                  style: GoogleFonts.inter(
                    fontSize: AppSizes.s12,
                    color: AppColors.grey500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
