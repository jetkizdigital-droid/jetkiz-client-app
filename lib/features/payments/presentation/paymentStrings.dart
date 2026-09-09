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
  String get addCard => _kk ? 'Басқа картамен төлеу' : 'Оплатить другой картой';
  String get card => _kk ? 'Карта' : 'Карта';
  String get noSavedCards =>
      _kk ? 'Сақталған карталар әзірге жоқ' : 'У вас пока нет сохранённых карт';
  String get cardsProviderHint => _kk
      ? 'Картаны тапсырысты төлеу кезінде қосуға болады.'
      : 'Карту можно добавить при оплате заказа.';
  String get secureProviderHint => _kk
      ? 'Карта деректерін төлем терезесінде енгізіңіз.'
      : 'Введите данные карты в окне оплаты.';
  String get providerPendingHint => cardsProviderHint;
  String get providerPendingAction => cardsProviderHint;
  String get deleteCard => _kk ? 'Картаны жою' : 'Удалить карту';
  String get deleteCardQuestion =>
      _kk ? 'Картаны жою керек пе?' : 'Удалить карту?';
  String deleteCardDescription(String cardLabel) => _kk
      ? '$cardLabel төлем тәсілдерінен жойылады.'
      : '$cardLabel будет удалена из способов оплаты.';
  String get cancel => _kk ? 'Бас тарту' : 'Отмена';
  String get delete => _kk ? 'Жою' : 'Удалить';
  String get defaultCard => _kk ? 'Негізгі карта' : 'Основная карта';
  String get makeDefault => _kk ? 'Негізгі ету' : 'Сделать основной';
  String get defaultBadge => _kk ? 'Негізгі' : 'Основная';
  String get expiry => _kk ? 'Жарамдылық мерзімі' : 'Срок действия';
  String get cardNumber => _kk ? 'Карта нөмірі' : 'Номер карты';
  String get cardholderName => _kk ? 'Картадағы аты-жөні' : 'Имя на карте';
  String get saveCard => _kk ? 'Картаны сақтау' : 'Сохранить карту';
  String get saveCardForFuture => _kk
      ? 'Келесі төлемдер үшін картаны сақтау'
      : 'Сохранить карту для следующих оплат';
  String get paymentCheck => _kk ? 'Төлем' : 'Оплата';
  String get paymentCheckHint => _kk
      ? 'Төлем нәтижесін тексеріп жатырмыз.'
      : 'Проверяем результат оплаты.';
  String get paymentSecured => _kk ? 'Тапсырыс рәсімделді' : 'Заказ оформлен';
  String get paymentSecuredHint =>
      _kk ? 'Тапсырыс мейрамханаға жіберілді.' : 'Заказ отправлен ресторану.';
  String get paymentFailed => _kk ? 'Төлем өтпеді' : 'Оплата не прошла';
  String get paymentFailedHint => _kk
      ? 'Басқа картаны таңдаңыз немесе қайтадан төлеңіз.'
      : 'Попробуйте другую карту или повторите оплату.';
  String get paymentStillPending =>
      _kk ? 'Төлемді тексеріп жатырмыз' : 'Проверяем оплату';
  String get paymentStillPendingHint =>
      _kk ? 'Бірнеше секунд күтіңіз.' : 'Подождите несколько секунд.';
  String get checkAgain => _kk ? 'Қайта тексеру' : 'Проверить снова';
  String get backToOrder => _kk ? 'Артқа' : 'Назад';
  String get openPayLink => _kk ? 'Төлемді жалғастыру' : 'Продолжить оплату';
  String get understood => _kk ? 'Түсінікті' : 'Понятно';
  String get bankCard => _kk ? 'Банк картасы' : 'Банковская карта';
  String get issuerBank => _kk ? 'Банк' : 'Банк';
  String get loadingCards => _kk ? 'Карталар жүктелуде' : 'Загрузка карт';
  String get cardsLoadError =>
      _kk ? 'Карталарды жүктеу мүмкін болмады' : 'Не удалось загрузить карты';
  String get retry => _kk ? 'Қайталау' : 'Повторить';
  String get removingCard => _kk ? 'Карта жойылуда…' : 'Удаляем карту…';
  String get defaultUpdated =>
      _kk ? 'Негізгі карта жаңартылды' : 'Основная карта обновлена';
  String get cardDeleted => _kk ? 'Карта жойылды' : 'Карта удалена';

  String get unfinishedPaymentTitle =>
      _kk ? 'Алдыңғы төлем аяқталмады' : 'Предыдущая оплата не завершена';
  String get unfinishedPaymentHint => _kk
      ? 'Қайта төлем жасамас бұрын оның мәртебесін тексереміз.'
      : 'Сначала проверим её статус, чтобы исключить повторное списание.';
  String get resumePayment => _kk ? 'Төлемді жалғастыру' : 'Продолжить оплату';
  String get verifyPreviousPayment =>
      _kk ? 'Төлемді тексеру' : 'Проверить оплату';
  String get previousPaymentConfirmed => _kk
      ? 'Төлем расталды. Тапсырыс рәсімделді.'
      : 'Оплата подтверждена. Заказ оформлен.';
  String get previousPaymentFailed => _kk
      ? 'Алдыңғы төлем аяқталды. Қайтадан төлеуге болады.'
      : 'Предыдущая попытка завершена. Можно оплатить снова.';
  String get recoveryCheckError => _kk
      ? 'Төлем мәртебесін тексеру мүмкін болмады. Қайта тексеріңіз.'
      : 'Не удалось проверить оплату. Попробуйте снова.';
}
