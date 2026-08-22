import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/localization/appLanguage.dart';
import 'package:jetkiz_mobile/core/localization/appLocalizationScope.dart';
import 'package:jetkiz_mobile/features/profile/domain/profileData.dart';
import 'package:jetkiz_mobile/features/profile/domain/updateProfileDto.dart';

typedef SaveProfileCallback = Future<ProfileData> Function(
    UpdateProfileDto dto);

Future<ProfileData?> showEditProfileSheet({
  required BuildContext context,
  required ProfileData? profile,
  required SaveProfileCallback onSave,
}) {
  return showGeneralDialog<ProfileData>(
    context: context,
    barrierLabel: 'EditProfile',
    barrierDismissible: true,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) {
      return SafeArea(
        child: Material(
          type: MaterialType.transparency,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: EditProfileSheet(
                profile: profile,
                onSave: onSave,
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );

      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({
    super.key,
    required this.profile,
    required this.onSave,
  });

  final ProfileData? profile;
  final SaveProfileCallback onSave;

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  static const _green = Color(0xFF4CAF50);
  static const _fieldFill = Color(0xFFF9FAFB);
  static const _fieldBorder = Color(0xFFE5E7EB);
  static const _titleColor = Color(0xFF1F2937);
  static const _labelColor = Color(0xFF374151);
  static const _hintColor = Color(0xFF9CA3AF);

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isSaving = false;
  String? _submitError;
  bool get _kk =>
      AppLocalizationScope.of(context).language == AppLanguage.kk;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.profile?.firstName?.trim() ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.profile?.lastName?.trim() ?? '',
    );
    _emailController = TextEditingController(
      text: widget.profile?.email?.trim() ?? '',
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _isSaving) return;

    setState(() {
      _isSaving = true;
      _submitError = null;
    });

    try {
      final updated = await widget.onSave(
        UpdateProfileDto(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _submitError = _readError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String? _validateFirstName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return _kk ? 'Атыңызды енгізіңіз' : 'Имя обязательно для заполнения';
    }
    if (text.length < 2) {
      return _kk ? 'Аты тым қысқа' : 'Имя слишком короткое';
    }
    if (text.length > 50) {
      return _kk ? 'Аты тым ұзын' : 'Имя слишком длинное';
    }
    return null;
  }

  String? _validateLastName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (text.length > 60) {
      return _kk ? 'Тегі тым ұзын' : 'Фамилия слишком длинная';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;

    final emailRegex = RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    );

    if (!emailRegex.hasMatch(text)) {
      return _kk ? 'Дұрыс email енгізіңіз' : 'Введите корректный email';
    }

    if (text.length > 120) {
      return _kk ? 'Email тым ұзын' : 'Email слишком длинный';
    }

    return null;
  }

  String _readError(Object error) {
    final text = error.toString().trim();
    if (text.isEmpty) {
      return _kk
          ? 'Деректерді сақтау мүмкін болмады'
          : 'Не удалось сохранить данные';
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizationScope.of(context).strings;
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 420,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings.profileMyData,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _titleColor,
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _isSaving ? null : () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.close_rounded,
                      size: 26,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _FieldLabel(
                    title: _kk ? 'Аты' : 'Имя',
                    required: true,
                  ),
                  const SizedBox(height: 8),
                  _FormTextField(
                    controller: _firstNameController,
                    hintText: _kk ? 'Атыңызды енгізіңіз' : 'Введите ваше имя',
                    textInputAction: TextInputAction.next,
                    validator: _validateFirstName,
                    enabled: !_isSaving,
                  ),
                  const SizedBox(height: 16),
                  _FieldLabel(
                    title: _kk ? 'Тегі' : 'Фамилия',
                  ),
                  const SizedBox(height: 8),
                  _FormTextField(
                    controller: _lastNameController,
                    hintText:
                        _kk ? 'Тегіңізді енгізіңіз' : 'Введите вашу фамилию',
                    textInputAction: TextInputAction.next,
                    validator: _validateLastName,
                    enabled: !_isSaving,
                  ),
                  const SizedBox(height: 16),
                  const _FieldLabel(
                    title: 'Email',
                  ),
                  const SizedBox(height: 8),
                  _FormTextField(
                    controller: _emailController,
                    hintText: 'example@email.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    validator: _validateEmail,
                    enabled: !_isSaving,
                    onSubmitted: (_) => _submit(),
                  ),
                ],
              ),
            ),
            if (_submitError != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFFECDD3),
                  ),
                ),
                child: Text(
                  _submitError!,
                  style: const TextStyle(
                    color: Color(0xFFBE123C),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _green.withValues(alpha: 0.6),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        _kk ? 'Сақтау' : 'Сохранить',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.title,
    this.required = false,
  });

  final String title;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF374151),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

class _FormTextField extends StatelessWidget {
  const _FormTextField({
    required this.controller,
    required this.hintText,
    required this.validator,
    required this.enabled,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final String? Function(String?) validator;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF4CAF50),
            width: 1.6,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 1.4,
          ),
        ),
      ),
    );
  }
}
