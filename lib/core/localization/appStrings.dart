import 'package:jetkiz_mobile/core/localization/appLanguage.dart';

class AppStrings {
  final AppLanguage language;

  const AppStrings(this.language);

  bool get _ru => language == AppLanguage.ru;

  String get appTitle => 'Jetkiz';

  String get navHome => _ru ? 'Главная' : 'Басты бет';
  String get navFavorites => _ru ? 'Избранное' : 'Таңдаулылар';
  String get navCart => _ru ? 'Корзина' : 'Себет';
  String get navProfile => _ru ? 'Профиль' : 'Профиль';

  String get profileTitle => _ru ? 'Профиль' : 'Профиль';
  String get profileDefaultName => _ru ? 'Клиент Jetkiz' : 'Jetkiz клиенті';
  String get profileDefaultSubtitle =>
      _ru ? 'Профиль клиента' : 'Клиент профилі';
  String get profileAvatarHint => _ru
      ? 'Нажмите на фото, чтобы загрузить аватар'
      : 'Аватар жүктеу үшін фотоны басыңыз';
  String get profileEditPhoto =>
      _ru ? 'Нажмите, чтобы изменить фото' : 'Фотоны өзгерту үшін басыңыз';
  String get profileActive => _ru ? 'Активен' : 'Белсенді';
  String get profileLoadError =>
      _ru ? 'Не удалось загрузить профиль' : 'Профильді жүктеу мүмкін болмады';
  String get retry => _ru ? 'Повторить' : 'Қайталау';
  String get avatarUpdated =>
      _ru ? 'Фото профиля обновлено' : 'Профиль фотосы жаңартылды';
  String avatarUploadFailed(String error) => _ru
      ? 'Не удалось загрузить фото: $error'
      : 'Фотоны жүктеу мүмкін болмады: $error';

  String get profileMyData => _ru ? 'Мои данные' : 'Менің деректерім';
  String get profileAddCard => _ru ? 'Добавить карту' : 'Карта қосу';
  String get profileSettings => _ru ? 'Настройки' : 'Баптаулар';
  String get profileAddress => _ru ? 'Адрес' : 'Мекенжай';
  String get profileAddresses => _ru ? 'Адреса' : 'Мекенжайлар';
  String get profileOrdersHistory =>
      _ru ? 'История заказов' : 'Тапсырыстар тарихы';
  String get profileSupport => _ru ? 'Поддержка' : 'Қолдау';
  String get profileOffer => _ru ? 'Договор и оферта' : 'Келісім және оферта';
  String get profilePublicOffer =>
      _ru ? 'Публичная оферта' : 'Жария оферта';
  String get logout => _ru ? 'Выйти' : 'Шығу';
  String get loggingOut => _ru ? 'Выход...' : 'Шығу...';
  String get profileSaved =>
      _ru ? 'Данные профиля сохранены' : 'Профиль деректері сақталды';
  String get pageOpenFailed =>
      _ru ? 'Не удалось открыть страницу' : 'Бетті ашу мүмкін болмады';
  String get appVersion => _ru ? 'Версия 1.0.0' : 'Нұсқа 1.0.0';
  String get loggedOutMessage =>
      _ru ? 'Вы вышли из аккаунта' : 'Сіз аккаунттан шықтыңыз';
  String comingSoon(String title) =>
      _ru ? '$title — скоро будет' : '$title — жақында болады';

  String get settingsTitle => _ru ? 'Настройки' : 'Баптаулар';
  String get settingsSecurity => _ru ? 'Безопасность' : 'Қауіпсіздік';
  String get settingsNotifications => _ru ? 'Уведомления' : 'Хабарландырулар';
  String get settingsLanguage => _ru ? 'Язык' : 'Тіл';
  String get settingsContractSoon =>
      _ru ? 'Договор будет добавлен позже' : 'Келісім кейінірек қосылады';

  String get ordersTitle => _ru ? 'Заказы' : 'Тапсырыстар';
  String get ordersEmptyTitle =>
      _ru ? 'Заказов пока нет' : 'Әзірге тапсырыс жоқ';
  String get ordersEmptySubtitle => _ru
      ? 'Когда появятся ваши заказы,\nони будут отображаться здесь.'
      : 'Тапсырыстарыңыз пайда болған кезде,\nолар осы жерде көрсетіледі.';
  String get goHome => _ru ? 'На главную' : 'Басты бетке';

  String get favoritesTitle => _ru ? 'Избранное' : 'Таңдаулылар';
  String get favoriteRestaurants => _ru ? 'Рестораны' : 'Мейрамханалар';
  String get favoriteProducts => _ru ? 'Блюда' : 'Тағамдар';
  String get guestFavoritesTitle => _ru
      ? 'Войдите, чтобы сохранять любимые блюда'
      : 'Сүйікті тағамдарды сақтау үшін кіріңіз';
  String get guestFavoritesSubtitle => _ru
      ? 'Избранное будет доступно на всех ваших устройствах.'
      : 'Таңдаулылар барлық құрылғыларыңызда қолжетімді болады.';
  String get loginToAccount => _ru ? 'Войти в аккаунт' : 'Аккаунтқа кіру';
  String get cartTitle => _ru ? 'Корзина' : 'Себет';
  String get guestCartTitle => _ru
      ? 'Войдите, чтобы оформить заказ'
      : 'Тапсырыс беру үшін аккаунтқа кіріңіз';
  String get guestCartSubtitle => _ru
      ? 'После входа вы сможете добавить адрес и оформить доставку.'
      : 'Кіргеннен кейін мекенжай қосып, жеткізуге тапсырыс бере аласыз.';
  String get browseRestaurants =>
      _ru ? 'Смотреть рестораны' : 'Мейрамханаларды көру';
}
