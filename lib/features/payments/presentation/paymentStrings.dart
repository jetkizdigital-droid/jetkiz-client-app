import 'package:flutter/widgets.dart';
import 'package:jetkiz_mobile/core/localization/appLanguage.dart';
import 'package:jetkiz_mobile/core/localization/appLocalizationScope.dart';

class PaymentStrings {
  const PaymentStrings._(this.language);

  final AppLanguage language;

  bool get _kk => language == AppLanguage.kk;

  static PaymentStrings of(BuildContext context) {
    return PaymentStrings._(AppLocalizationScope.of(context).language);
  }

  String get paymentMethods => _kk ? 'Төлем тәсілдері' : 'Способы оплаты';
  String get addCard => _kk ? 'Карта қосу' : 'Добавить карту';
  String get card => _kk ? 'Карта' : 'Карта';
  String get noSavedCards =>
      _kk ? 'Сақталған карталар әзірге жоқ' : 'Сохранённых карт пока нет';
  String get cardsProviderHint => _kk
      ? 'Төлем провайдері қосылғаннан кейін мұнда сақталған төлем тәсілдерін басқаруға болады.'
      : 'После подключения платёжного провайдера здесь можно будет управлять сохранёнными способами оплаты.';
  String get secureProviderHint => _kk
      ? 'Карта деректері төлем провайдерінің қорғалған нысаны арқылы енгізіліп, өңделеді. JETKIZ картаның толық нөмірін немесе CVV кодын сақтамайды.'
      : 'Данные карты будут вводиться и обрабатываться защищённой формой платёжного провайдера. JETKIZ не будет хранить полный номер карты или CVV.';
  String get providerPendingHint => _kk
      ? 'Өрістер болашақ қорғалған экранның макеті ретінде көрсетілген. PayLink API расталғанға дейін реквизиттер жіберілмейді және сақталмайды.'
      : 'Поля показаны как макет будущего защищённого экрана. До подтверждения API PayLink реквизиты не отправляются и не сохраняются.';
  String get providerPendingAction => _kk
      ? 'Функция төлем провайдері қосылғаннан кейін қолжетімді болады'
      : 'Функция станет доступна после подключения платёжного провайдера';
  String get deleteCard => _kk ? 'Картаны жою' : 'Удалить карту';
  String get deleteCardQuestion =>
      _kk ? 'Картаны жою керек пе?' : 'Удалить карту?';
  String deleteCardDescription(String cardLabel) => _kk
      ? '$cardLabel төлем тәсілдерінен жойылады.'
      : '$cardLabel будет удалена из способов оплаты.';
  String get cancel => _kk ? 'Бас тарту' : 'Отмена';
  String get delete => _kk ? 'Жою' : 'Удалить';
  String get defaultCard => _kk ? 'Негізгі карта' : 'Основная карта';
  String get defaultBadge => _kk ? 'Негізгі' : 'Основная';
  String get expiry => _kk ? 'Жарамдылық мерзімі' : 'Срок действия';
  String get cardNumber => _kk ? 'Карта нөмірі' : 'Номер карты';
  String get cardholderName => _kk ? 'Картадағы аты-жөні' : 'Имя на карте';
  String get saveCard => _kk ? 'Картаны сақтау' : 'Сохранить карту';
  String get paymentCheck => _kk ? 'Төлемді тексеру' : 'Проверка оплаты';
  String get paymentCheckHint => _kk
      ? 'Төлем провайдері қосылғаннан кейін JETKIZ төлем мәртебесін сервер арқылы тексереді.'
      : 'После подключения платёжного провайдера JETKIZ будет проверять статус оплаты на сервере.';
  String get bankCard => _kk ? 'Банк картасы' : 'Банковская карта';
}
