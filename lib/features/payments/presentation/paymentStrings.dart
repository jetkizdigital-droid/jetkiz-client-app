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
  String get addCard => _kk ? 'Жаңа карта' : 'Новая карта';
  String get card => _kk ? 'Карта' : 'Карта';
  String get noSavedCards =>
      _kk ? 'Сақталған карталар әзірге жоқ' : 'Сохранённых карт пока нет';
  String get cardsProviderHint => _kk
      ? 'Картаны келесі тапсырысты төлеу кезінде қауіпсіз PayLink бетінде сақтауға болады.'
      : 'Карту можно сохранить при следующей оплате на защищённой странице PayLink.';
  String get secureProviderHint => _kk
      ? 'Карта деректері тек PayLink қорғалған бетінде енгізіледі. JETKIZ картаның толық нөмірін және CVV кодын алмайды және сақтамайды.'
      : 'Данные карты вводятся только на защищённой странице PayLink. JETKIZ не получает и не хранит полный номер карты и CVV.';
  String get providerPendingHint => _kk
      ? 'Жаңа карта тапсырысты төлеу кезінде қосылады. Жеке карта деректерін JETKIZ қолданбасына енгізудің қажеті жоқ.'
      : 'Новая карта добавляется во время оплаты заказа. Вводить реквизиты карты в приложении JETKIZ не нужно.';
  String get providerPendingAction => _kk
      ? 'Жаңа картаны келесі төлем кезінде сақтауға болады'
      : 'Новую карту можно сохранить при следующей оплате';
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
      ? 'Келесі тапсырыстар үшін картаны сақтау'
      : 'Сохранить карту для следующих заказов';
  String get paymentCheck => _kk ? 'Төлемді тексеру' : 'Проверка оплаты';
  String get paymentCheckHint => _kk
      ? 'JETKIZ төлем мәртебесін сервер арқылы тексереді. PayLink бетінен қайту төлемнің сәтті болғанын білдірмейді.'
      : 'JETKIZ проверяет оплату через сервер. Возврат со страницы PayLink сам по себе не означает успешную оплату.';
  String get paymentSecured => _kk ? 'Төлем расталды' : 'Оплата подтверждена';
  String get paymentSecuredHint => _kk
      ? 'Қаражат картада расталды. Тапсырыс мейрамханаға жіберілді.'
      : 'Средства на карте подтверждены. Заказ отправлен ресторану.';
  String get paymentFailed => _kk ? 'Төлем өтпеді' : 'Оплата не прошла';
  String get paymentFailedHint => _kk
      ? 'Басқа картаны таңдаңыз немесе төлемді қайталап көріңіз.'
      : 'Выберите другую карту или попробуйте оплатить ещё раз.';
  String get paymentStillPending =>
      _kk ? 'Төлем әлі өңделуде' : 'Оплата ещё обрабатывается';
  String get paymentStillPendingHint => _kk
      ? 'PayLink немесе банк жауабын күтіп отырмыз. Төлемді қайталамаңыз — алдымен мәртебені тексеріңіз.'
      : 'Ждём ответ PayLink или банка. Не создавайте повторную оплату — сначала проверьте статус.';
  String get checkAgain => _kk ? 'Қайта тексеру' : 'Проверить снова';
  String get backToOrder => _kk ? 'Тапсырысқа оралу' : 'Вернуться к заказу';
  String get openPayLink => _kk ? 'PayLink ашу' : 'Открыть PayLink';
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
      _kk ? 'Аяқталмаған төлем бар' : 'Есть незавершённая оплата';
  String get unfinishedPaymentHint => _kk
      ? 'Қайта төлем жасамас бұрын алдыңғы тапсырыстың мәртебесін тексереміз. Бұл қайталама төлемнен қорғайды.'
      : 'Перед новой оплатой проверим предыдущий заказ. Это защищает от повторного списания.';
  String get resumePayment => _kk ? 'Төлемді жалғастыру' : 'Продолжить оплату';
  String get verifyPreviousPayment =>
      _kk ? 'Алдыңғы төлемді тексеру' : 'Проверить предыдущую оплату';
  String get previousPaymentConfirmed => _kk
      ? 'Алдыңғы тапсырыстың төлемі расталды. Тапсырыс өңделіп жатыр.'
      : 'Оплата предыдущего заказа подтверждена. Заказ уже обрабатывается.';
  String get previousPaymentFailed => _kk
      ? 'Алдыңғы төлем аяқталды. Жаңа төлем жасауға болады.'
      : 'Предыдущая оплата завершена. Можно создать новую оплату.';
  String get recoveryCheckError => _kk
      ? 'Алдыңғы төлемнің мәртебесін тексеру мүмкін болмады. Қайталама списание болмас үшін қайта тексеріңіз.'
      : 'Не удалось проверить предыдущую оплату. Повторите проверку, чтобы исключить двойное списание.';
}
