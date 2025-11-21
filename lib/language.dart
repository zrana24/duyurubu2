import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../bluetooth_provider.dart';
import 'image.dart';
import '../screens/management.dart';
import '../screens/settings.dart';
import '../screens/connect.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('tr', 'TR');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }

  final Map<String, Map<String, String>> _localizedStrings = {
    'tr': {
      'name_screen': 'İSİMLİK EKRANI',
      'language_selection':'DİL SEÇİMİ',
      'pairing':'EŞLEŞTİRME',
      'add_name': 'İSİM EKLE AI',
      'speaker_info': 'KONUŞMACI BİLGİSİ',
      'no_speakers': 'KONUŞMACI YOK',
      'content_management':'İÇERİK YÖNETİMİ',
      'no_contents': 'İÇERİK YOK',
      'department': 'Bölüm/Pozisyon:',
      'volume_level': 'SES DÜZEYİ',
      'name': 'Ad Soyad:',
      'duration': 'Sunum Süresi:',
      'cancel': 'İPTAL',
      'save': 'KAYDET',
      'fill_all_fields': 'Lütfen tüm alanları doldurun!',
      'invalid_time': 'Lütfen geçerli bir süre formatı girin! (SS:DD:SS)',
      'added_success': 'Konuşmacı başarıyla eklendi!',
      'language_options': 'DİL SEÇENEKLERİ',
      'selected_language': 'dili seçildi',
      'select_button': 'SEÇ',
      'paired_podiums': 'EŞLEŞMİŞ KÜRSÜLER',
      'nearby_devices': 'ÇEVREDEKİ CİHAZLAR',
      'pairing_connecting': 'Eşleştiriliyor ve bağlanıyor...',
      'processing': 'İŞLEM YAPILIYOR...',
      'disconnect': 'BAĞLANTIYI KES',
      'connect': 'BAĞLAN',
      'select_device': 'CİHAZ SEÇİN',
      'no_devices_found': 'Çevrede cihaz bulunamadı',
      'no_paired_podiums': 'Eşleşmiş kürsü bulunamadı',
      'management': 'YÖNETİM',
      'connection': 'BAĞLANTI',
      'settings': 'AYARLAR',
      'main_screen': '1. ANA EKRAN',
      'name_screen1': '2. İSİMLİK EKRAN',
      'name_screen_': 'İSİMLİK EKRAN',
      'info_screen': '3. BİLGİ EKRAN',
      'info_screen_': 'BİLGİ EKRAN',
      'screen_brightness': 'EKRAN PARLAKLIĞI',
      'add_content': 'İÇERİK EKLE',
      'meeting_topic': 'Toplantı Konusu',
      'project_evaluation': 'Proje Değerlendirme ve Geliştirme Süreçleri',
      'budget_planning': 'Bütçe Planlaması',
      'excellent': 'MÜKEMMEL',
      'good': 'İYİ',
      'average': 'ORTA',
      'poor': 'ZAYIF',
      'unknown': 'BİLİNMİYOR',
      'select_file': 'Dosya Seç',
      'file_selected': 'Dosya Seçildi',
      'start': 'Başlangıç',
      'end': 'Bitiş',
      'invalid_time_format': 'Geçersiz saat formatı (SS:DD:SS)',
      'content_added_success': 'İçerik başarıyla eklendi',
      'choose_file_type': 'Dosya Türü Seçin',
      'select_photo': 'Fotoğraf Seç',
      'select_video': 'Video Seç',
      'select_document': 'Belge Seç',
      'document_selection': 'Belge seçme özelliği eklenecek',
      'department_example': 'Örn: İnsan Kaynakları Müdürü',
      'name_example': 'Örn: Ahmet Yılmaz',
      'duration_example': 'Örn: 00:30:00',
    },
    'en': {
      'name_screen': 'NAME SCREEN',
      'language_selection': 'LANGUAGE SELECTION',
      'pairing': 'PAIRING',
      'add_name': 'ADD NAME AI',
      'speaker_info': 'SPEAKER INFO',
      'no_speakers': 'NO SPEAKERS',
      'content_management': 'CONTENT MANAGEMENT',
      'no_contents': 'NO CONTENTS',
      'department': 'Department/Position:',
      'volume_level': 'VOLUME LEVEL',
      'name': 'Full Name:',
      'duration': 'Presentation Time:',
      'cancel': 'CANCEL',
      'save': 'SAVE',
      'fill_all_fields': 'Please fill in all fields!',
      'invalid_time': 'Please enter a valid time format! (HH:MM:SS)',
      'added_success': 'Speaker added successfully!',
      'language_options': 'LANGUAGE OPTIONS',
      'selected_language': 'language selected',
      'select_button': 'SELECT',
      'paired_podiums': 'PAIRED PODIUMS',
      'nearby_devices': 'NEARBY DEVICES',
      'pairing_connecting': 'Pairing and connecting...',
      'processing': 'PROCESSING...',
      'disconnect': 'DISCONNECT',
      'connect': 'CONNECT',
      'select_device': 'SELECT DEVICE',
      'no_devices_found': 'No devices found nearby',
      'no_paired_podiums': 'No paired podiums found',
      'management': 'MANAGEMENT',
      'connection': 'CONNECTION',
      'settings': 'SETTINGS',
      'main_screen': '1. MAIN SCREEN',
      'name_screen1': '2. NAME SCREEN',
      'name_screen_': 'NAME SCREEN',
      'info_screen': '3. INFO SCREEN',
      'info_screen_': 'INFO SCREEN',
      'screen_brightness': 'SCREEN BRIGHTNESS',
      'add_content': 'ADD CONTENT',
      'meeting_topic': 'Meeting Topic',
      'project_evaluation': 'Project Evaluation and Development Processes',
      'budget_planning': 'Budget Planning',
      'excellent': 'EXCELLENT',
      'good': 'GOOD',
      'average': 'AVERAGE',
      'poor': 'POOR',
      'unknown': 'UNKNOWN',
      'select_file': 'Select File',
      'file_selected': 'File Selected',
      'start': 'Start',
      'end': 'End',
      'invalid_time_format': 'Invalid time format (HH:MM:SS)',
      'content_added_success': 'Content added successfully',
      'choose_file_type': 'Choose File Type',
      'select_photo': 'Select Photo',
      'select_video': 'Select Video',
      'select_document': 'Select Document',
      'document_selection': 'Document selection feature will be added',
      'department_example': 'Ex: Human Resources Manager',
      'name_example': 'Ex: John Smith',
      'duration_example': 'Ex: 00:30:00',
    },
    'ru': {
      'name_screen': 'ЭКРАН ИМЕН',
      'language_selection': 'ВЫБОР ЯЗЫКА',
      'pairing': 'СОПРЯЖЕНИЕ',
      'add_name': 'ДОБАВИТЬ ИМЯ AI',
      'speaker_info': 'ИНФОРМАЦИЯ О ДОКЛАДЧИКЕ',
      'no_speakers': 'НЕТ ДОКЛАДЧИКОВ',
      'content_management': 'УПРАВЛЕНИЕ КОНТЕНТОМ',
      'no_contents': 'НЕТ СОДЕРЖИМОГО',
      'department': 'Отдел/Должность:',
      'volume_level': 'УРОВЕНЬ ГРОМКОСТИ',
      'name': 'ФИО:',
      'duration': 'Время выступления:',
      'cancel': 'ОТМЕНА',
      'save': 'СОХРАНИТЬ',
      'fill_all_fields': 'Пожалуйста, заполните все поля!',
      'invalid_time': 'Введите правильный формат времени! (ЧЧ:ММ:СС)',
      'added_success': 'Докладчик успешно добавлен!',
      'language_options': 'ВАРИАНТЫ ЯЗЫКА',
      'selected_language': 'язык выбран',
      'select_button': 'ВЫБРАТЬ',
      'paired_podiums': 'СОПРЯЖЕННЫЕ ПОДИУМЫ',
      'nearby_devices': 'БЛИЗЛЕЖАЩИЕ УСТРОЙСТВА',
      'pairing_connecting': 'Сопряжение и подключение...',
      'processing': 'ОБРАБОТКА...',
      'disconnect': 'ОТКЛЮЧИТЬ',
      'connect': 'ПОДКЛЮЧИТЬ',
      'select_device': 'ВЫБРАТЬ УСТРОЙСТВО',
      'no_devices_found': 'Устройства поблизости не найдены',
      'no_paired_podiums': 'Сопряженные подиумы не найдены',
      'management': 'УПРАВЛЕНИЕ',
      'connection': 'СВЯЗЬ',
      'settings': 'НАСТРОЙКИ',
      'main_screen': '1. ГЛАВНЫЙ ЭКРАН',
      'name_screen1': '2. ЭКРАН ИМЕН',
      'name_screen_': 'ЭКРАН ИМЕН',
      'info_screen': '3. ИНФОРМАЦИОННЫЙ ЭКРАН',
      'info_screen_': 'ИНФОРМАЦИОННЫЙ ЭКРАН',
      'screen_brightness': 'ЯРКОСТЬ ЭКРАНА',
      'add_content': 'ДОБАВИТЬ КОНТЕНТ',
      'meeting_topic': 'Тема собрания',
      'project_evaluation': 'Оценка проекта и процессы разработки',
      'budget_planning': 'Планирование бюджета',
      'excellent': 'ОТЛИЧНО',
      'good': 'ХОРОШО',
      'average': 'СРЕДНЕ',
      'poor': 'ПЛОХО',
      'unknown': 'НЕИЗВЕСТНО',
      'select_file': 'Выбрать файл',
      'file_selected': 'Файл выбран',
      'start': 'Начало',
      'end': 'Конец',
      'invalid_time_format': 'Неверный формат времени (ЧЧ:ММ:СС)',
      'content_added_success': 'Контент успешно добавлен',
      'choose_file_type': 'Выберите тип файла',
      'select_photo': 'Выбрать фото',
      'select_video': 'Выбрать видео',
      'select_document': 'Выбрать документ',
      'document_selection': 'Функция выбора документа будет добавлена',
      'department_example': 'Напр: Менеджер по персоналу',
      'name_example': 'Напр: Иван Иванов',
      'duration_example': 'Напр: 00:30:00',
    },
    'ar': {
      'name_screen': 'شاشة الأسماء',
      'language_selection': 'اختيار اللغة',
      'pairing': 'الاقتران',
      'add_name': 'إضافة اسم AI',
      'speaker_info': 'معلومات المتحدث',
      'no_speakers': 'لا يوجد متحدثون',
      'content_management': 'إدارة المحتوى',
      'no_contents': 'لا يوجد محتوى',
      'department': 'القسم/الوظيفة:',
      'volume_level': 'مستوى الصوت',
      'name': 'الاسم الكامل:',
      'duration': 'مدة العرض:',
      'cancel': 'إلغاء',
      'save': 'حفظ',
      'fill_all_fields': 'يرجى ملء جميع الحقول!',
      'invalid_time': 'الرجاء إدخال صيغة وقت صحيحة! (س:د:ث)',
      'added_success': 'تمت إضافة المتحدث بنجاح!',
      'language_options': 'خيارات اللغة',
      'selected_language': 'تم اختيار اللغة',
      'select_button': 'اختيار',
      'paired_podiums': 'المنصات المقترنة',
      'nearby_devices': 'الأجهزة القريبة',
      'pairing_connecting': 'جاري الاقتران والتوصيل...',
      'processing': 'جاري المعالجة...',
      'disconnect': 'قطع الاتصال',
      'connect': 'اتصال',
      'select_device': 'اختر الجهاز',
      'no_devices_found': 'لم يتم العثور على أجهزة قريبة',
      'no_paired_podiums': 'لم يتم العثور على منصات مقترنة',
      'management': 'الإدارة',
      'connection': 'اتصال',
      'settings': 'الإعدادات',
      'main_screen': '1. الشاشة الرئيسية',
      'name_screen1': '2. شاشة الأسماء',
      'name_screen_': 'شاشة الأسماء',
      'info_screen': '3. شاشة المعلومات',
      'info_screen_': 'شاشة المعلومات',
      'screen_brightness': 'سطوع الشاشة',
      'add_content': 'إضافة محتوى',
      'meeting_topic': 'موضوع الاجتماع',
      'project_evaluation': 'تقييم المشروع وعمليات التطوير',
      'budget_planning': 'تخطيط الميزانية',
      'excellent': 'ممتاز',
      'good': 'جيد',
      'average': 'متوسط',
      'poor': 'ضعيف',
      'unknown': 'غير معروف',
      'select_file': 'اختر ملف',
      'file_selected': 'تم اختيار الملف',
      'start': 'بداية',
      'end': 'نهاية',
      'invalid_time_format': 'تنسيق وقت غير صالح (س:د:ث)',
      'content_added_success': 'تمت إضافة المحتوى بنجاح',
      'choose_file_type': 'اختر نوع الملف',
      'select_photo': 'اختر صورة',
      'select_video': 'اختر فيديو',
      'select_document': 'اختر مستند',
      'document_selection': 'سيتم إضافة ميزة اختيار المستند',
      'department_example': 'مثال: مدير الموارد البشرية',
      'name_example': 'مثال: أحمد محمد',
      'duration_example': 'مثال: 00:30:00',
    },
  };

  String getTranslation(String key) {
    String translation = _localizedStrings[_locale.languageCode]?[key] ?? key;

    if (translation == key && key.contains('_')) {
      translation = key.replaceAll('_', ' ');
      translation = translation[0].toUpperCase() + translation.substring(1);
    }

    return translation;
  }
}

class LanguagePage extends StatefulWidget {
  const LanguagePage({Key? key}) : super(key: key);

  @override
  _LanguagePageState createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  final List<Map<String, String>> languages = [
    {'code': 'tr', 'name': 'TÜRKÇE', 'flag': '🇹🇷'},
    {'code': 'en', 'name': 'ENGLISH', 'flag': '🇺🇸'},
    {'code': 'ru', 'name': 'РУССКИЙ', 'flag': '🇷🇺'},
    {'code': 'ar', 'name': 'اللغة العربية', 'flag': '🇸🇦'},
  ];

  void _selectLanguage(BuildContext context, Map<String, String> lang) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    languageProvider.setLocale(Locale(lang['code']!));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${lang['name']} ${languageProvider.getTranslation('selected_language')}"),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF4DB6AC),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFE8EAF6),
      body: SafeArea(
        child: Column(
          children: [
            ImageWidget(activePage: "language"),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.03,
                  vertical: screenHeight * 0.01,
                ),
                child: ListView.builder(
                  itemCount: languages.length,
                  padding: EdgeInsets.all(screenWidth * 0.03),
                  itemBuilder: (context, index) {
                    final lang = languages[index];
                    bool isSelected =
                        languageProvider.locale.languageCode == lang['code'];
                    return Container(
                      margin: EdgeInsets.only(bottom: screenHeight * 0.015),
                      child: _buildLanguageCard(lang, isSelected, isTablet),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard(Map<String, String> lang, bool isSelected, bool isTablet) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () => _selectLanguage(context, lang),
      child: Container(
        width: double.infinity,
        height: isTablet ? screenHeight * 0.1 : screenHeight * 0.08,
        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC5CAE9) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF37474F)
                : const Color(0xFFC5CAE9),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: isTablet ? screenWidth * 0.12 : screenWidth * 0.15,
              padding: EdgeInsets.all(isTablet ? 12 : 8),
              child: Center(
                child: Text(
                  lang['flag']!,
                  style: TextStyle(
                    fontSize: isTablet ? 24 : screenWidth * 0.08,
                  ),
                ),
              ),
            ),

            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 12 : 8,
                  vertical: isTablet ? 12 : 8,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang['name']!,
                      style: TextStyle(
                        fontSize: isTablet ? 18 : screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF37474F),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}