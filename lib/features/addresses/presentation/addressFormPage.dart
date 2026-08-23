import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/localization/localizedText.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/addresses/data/addressesApi.dart';
import 'package:jetkiz_mobile/features/addresses/domain/address.dart';

class AddressFormPage extends StatefulWidget {
  const AddressFormPage({
    super.key,
    this.initialAddress,
  });

  final Address? initialAddress;

  bool get isEditing => initialAddress != null;

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  static const Color _green = Color(0xFF489F2A);
  static const Color _bg = Color(0xFFF7FAF5);
  static const Color _text = Color(0xFF111827);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _error = Color(0xFFE53935);

  late final AddressesApi _addressesApi;

  late final TextEditingController _addressController;
  late final TextEditingController _entranceController;
  late final TextEditingController _floorController;
  late final TextEditingController _doorController;
  late final TextEditingController _intercomController;
  late final TextEditingController _contactPhoneController;
  late final TextEditingController _commentController;

  bool _isSaving = false;
  String? _submitError;

  String? _addressError;
  String? _entranceError;
  String? _floorError;
  String? _doorError;
  String? _intercomError;
  String? _contactPhoneError;
  String? _commentError;

  late String _selectedTitle;

  @override
  void initState() {
    super.initState();

    _addressesApi = AddressesApi(ApiClient());

    final initial = widget.initialAddress;

    _selectedTitle = _resolveInitialTitle(initial?.title);
    _addressController = TextEditingController(text: initial?.address ?? '');
    _entranceController = TextEditingController(text: initial?.entrance ?? '');
    _floorController = TextEditingController(text: initial?.floor ?? '');
    _doorController = TextEditingController(text: initial?.door ?? '');
    _intercomController = TextEditingController(text: initial?.intercom ?? '');
    _contactPhoneController =
        TextEditingController(text: initial?.contactPhone ?? '');
    _commentController = TextEditingController(text: initial?.comment ?? '');
  }

  String _resolveInitialTitle(String? title) {
    const allowed = ['Дом', 'Работа', 'Другое'];
    final value = (title ?? '').trim();

    return allowed.contains(value) ? value : 'Дом';
  }

  @override
  void dispose() {
    _addressController.dispose();
    _entranceController.dispose();
    _floorController.dispose();
    _doorController.dispose();
    _intercomController.dispose();
    _contactPhoneController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    final addressText = _addressController.text.trim();
    final entranceText = _entranceController.text.trim();
    final floorText = _floorController.text.trim();
    final doorText = _doorController.text.trim();
    final intercomText = _intercomController.text.trim();
    final contactPhoneText = _contactPhoneController.text.trim();
    final commentText = _commentController.text.trim();

    String? addressError;
    String? entranceError;
    String? floorError;
    String? doorError;
    String? intercomError;
    String? contactPhoneError;
    String? commentError;

    if (addressText.isEmpty) {
      addressError = 'Укажите адрес';
    } else if (addressText.length < 3) {
      addressError = 'Адрес слишком короткий';
    } else if (addressText.length > 255) {
      addressError = 'Максимум 255 символов';
    }

    if (entranceText.length > 50) {
      entranceError = 'Максимум 50 символов';
    }

    if (floorText.length > 50) {
      floorError = 'Максимум 50 символов';
    }

    if (doorText.length > 50) {
      doorError = 'Максимум 50 символов';
    }

    if (intercomText.length > 50) {
      intercomError = 'Максимум 50 символов';
    }

    if (contactPhoneText.length > 30) {
      contactPhoneError = 'Максимум 30 символов';
    }

    if (commentText.length > 500) {
      commentError = 'Максимум 500 символов';
    }

    setState(() {
      _addressError = addressError;
      _entranceError = entranceError;
      _floorError = floorError;
      _doorError = doorError;
      _intercomError = intercomError;
      _contactPhoneError = contactPhoneError;
      _commentError = commentError;
    });

    return addressError == null &&
        entranceError == null &&
        floorError == null &&
        doorError == null &&
        intercomError == null &&
        contactPhoneError == null &&
        commentError == null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (_isSaving) return;
    if (!_validateForm()) return;

    setState(() {
      _isSaving = true;
      _submitError = null;
    });

    final payload = SaveAddressPayload(
      title: _selectedTitle,
      address: _addressController.text.trim(),
      entrance: _entranceController.text.trim(),
      floor: _floorController.text.trim(),
      door: _doorController.text.trim(),
      intercom: _intercomController.text.trim(),
      contactPhone: _contactPhoneController.text.trim(),
      comment: _commentController.text.trim(),
    );

    try {
      final result = widget.isEditing
          ? await _addressesApi.updateAddress(
              widget.initialAddress!.id,
              payload,
            )
          : await _addressesApi.createAddress(payload);

      if (!mounted) return;

      Navigator.of(context).pop(result);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _submitError =
            'Не удалось сохранить адрес. Проверь подключение и попробуй ещё раз.';
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _setTitle(String title) {
    if (_selectedTitle == title) return;

    setState(() {
      _selectedTitle = title;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          Container(
            color: _green,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 18,
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).maybePop(),
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                Expanded(
                  child: LocalizedText(
                    widget.isEditing ? 'Редактировать адрес' : 'Адрес доставки',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 32),
              ],
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                children: [
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const LocalizedText(
                          'Тип адреса',
                          style: TextStyle(
                            color: _text,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _AddressTypeChip(
                                label: 'Дом',
                                selected: _selectedTitle == 'Дом',
                                onTap: () => _setTitle('Дом'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _AddressTypeChip(
                                label: 'Работа',
                                selected: _selectedTitle == 'Работа',
                                onTap: () => _setTitle('Работа'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _AddressTypeChip(
                                label: 'Другое',
                                selected: _selectedTitle == 'Другое',
                                onTap: () => _setTitle('Другое'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    child: Column(
                      children: [
                        _AppTextField(
                          controller: _addressController,
                          label: 'Улица, дом',
                          hint: 'Например: ул. Абая, 25',
                          errorText: _addressError,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) {
                            if (_addressError != null) _validateForm();
                          },
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _AppTextField(
                                controller: _entranceController,
                                label: 'Подъезд',
                                hint: '2',
                                errorText: _entranceError,
                                textInputAction: TextInputAction.next,
                                onChanged: (_) {
                                  if (_entranceError != null) _validateForm();
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _AppTextField(
                                controller: _floorController,
                                label: 'Этаж',
                                hint: '3',
                                errorText: _floorError,
                                textInputAction: TextInputAction.next,
                                onChanged: (_) {
                                  if (_floorError != null) _validateForm();
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _AppTextField(
                                controller: _doorController,
                                label: 'Квартира / офис',
                                hint: '12',
                                errorText: _doorError,
                                textInputAction: TextInputAction.next,
                                onChanged: (_) {
                                  if (_doorError != null) _validateForm();
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _AppTextField(
                                controller: _intercomController,
                                label: 'Домофон',
                                hint: '1234',
                                errorText: _intercomError,
                                textInputAction: TextInputAction.next,
                                onChanged: (_) {
                                  if (_intercomError != null) _validateForm();
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _AppTextField(
                          controller: _contactPhoneController,
                          label: 'Телефон для курьера',
                          hint: '+7 700 000 00 00',
                          errorText: _contactPhoneError,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) {
                            if (_contactPhoneError != null) _validateForm();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    child: _AppTextField(
                      controller: _commentController,
                      label: 'Комментарий к адресу',
                      hint: 'Например: звонок не работает',
                      minLines: 3,
                      maxLines: 4,
                      errorText: _commentError,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) {
                        if (_commentError != null) _validateForm();
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: LocalizedText(
                      'Доставка осуществляется только в зоне обслуживания JETKIZ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: _muted,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),
                  if (_submitError != null) ...[
                    const SizedBox(height: 14),
                    LocalizedText(
                      _submitError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _error,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Container(
            color: _bg,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    disabledBackgroundColor: _green.withValues(alpha: 0.7),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : LocalizedText(
                          widget.isEditing
                              ? 'Сохранить изменения'
                              : 'Сохранить адрес',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AddressTypeChip extends StatelessWidget {
  const _AddressTypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF489F2A);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? green : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? green : const Color(0xFFE5E7EB),
          ),
        ),
        child: LocalizedText(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF111827),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _AppTextField extends StatelessWidget {
  const _AppTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.errorText,
    this.minLines = 1,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? errorText;
  final int minLines;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    const border = Color(0xFFE5E7EB);
    const text = Color(0xFF111827);
    const muted = Color(0xFF6B7280);
    const error = Color(0xFFE53935);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocalizedText(
          label,
          style: const TextStyle(
            color: text,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: muted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: errorText == null ? border : error,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: errorText == null ? border : error,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: errorText == null ? const Color(0xFF489F2A) : error,
                width: 1.4,
              ),
            ),
          ),
          style: const TextStyle(
            color: text,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          LocalizedText(
            errorText!,
            style: const TextStyle(
              color: error,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
