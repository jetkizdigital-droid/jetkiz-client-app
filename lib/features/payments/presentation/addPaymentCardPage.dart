import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jetkiz_mobile/core/localization/localizedText.dart';

class AddPaymentCardPage extends StatefulWidget {
  const AddPaymentCardPage({super.key});

  @override
  State<AddPaymentCardPage> createState() => _AddPaymentCardPageState();
}

class _AddPaymentCardPageState extends State<AddPaymentCardPage> {
  static const Color _green = Color(0xFF489F2A);
  static const Color _background = Color(0xFFF7FAF5);

  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _numberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _showProviderNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: LocalizedText(
          'Добавление карты будет доступно после подключения платёжного провайдера',
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE1E7DE)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE1E7DE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _green, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const LocalizedText(
          'Добавить карту',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE4E9E1)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline_rounded, color: _green),
                  SizedBox(width: 12),
                  Expanded(
                    child: LocalizedText(
                      'Данные карты будут вводиться и обрабатываться защищённой формой платёжного провайдера. JETKIZ не будет хранить полный номер карты или CVV.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: Color(0xFF5F685D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AbsorbPointer(
              child: Column(
                children: [
                  TextField(
                    controller: _numberController,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.creditCardNumber],
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _fieldDecoration(
                      label: 'Номер карты',
                      hint: '0000 0000 0000 0000',
                      suffixIcon: const Icon(Icons.credit_card_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _expiryController,
                          keyboardType: TextInputType.number,
                          autofillHints: const [AutofillHints.creditCardExpirationDate],
                          decoration: _fieldDecoration(
                            label: 'Срок действия',
                            hint: 'MM/YY',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _cvvController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          autofillHints: const [AutofillHints.creditCardSecurityCode],
                          decoration: _fieldDecoration(
                            label: 'CVV',
                            hint: '•••',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.characters,
                    autofillHints: const [AutofillHints.creditCardName],
                    decoration: _fieldDecoration(
                      label: 'Имя на карте',
                      hint: 'IVAN IVANOV',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const LocalizedText(
              'Поля показаны как макет будущего защищённого экрана. До подтверждения API PayLink реквизиты не отправляются и не сохраняются.',
              style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF7A8378)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showProviderNotice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const LocalizedText(
                  'Сохранить карту',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
