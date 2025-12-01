import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'image.dart';
import 'screens/connected.dart';
import 'bluetooth_provider.dart';


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
      'language_options': 'DİL SEÇENEKLİ',
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
      'name_screen_header': 'İSİMLİK EKRANI',
      'add_speaker_btn': 'İSİM EKLE',
      'speaker_badge': 'KONUŞMACI BİLGİSİ',
      'no_speakers_found': 'Konuşmacı bulunamadı',

      
      'info_screen_header': 'BİLGİ EKRANI',
      'add_content_btn': 'İÇERİK EKLE',
      'export_computer_btn': 'BİLGİSAYARA AKTAR',
      'content_badge': 'İÇERİK',
      'no_content_found': 'İçerik bulunamadı',

      
      'department_label': 'Bölüm/Departman',
      'fullname_label': 'Ad Soyad',
      'time_placeholder': '00:00:00',
      'active_status_label': 'Aktif Durum',
      'active_button_label': 'Aktif Buton',
      'sending_bluetooth': 'Bluetooth cihazına gönderiliyor...',
      'add_button': 'Ekle',

      'video_sending_title': 'Video Gönderiliyor',
      'size_label': 'Boyut',
      'video_sent_success': 'Video Gönderildi!\nŞimdi bilgileri girin.',
      'sending_cancelled': 'Gönderim İptal Edildi',
      'ok_button': 'Tamam',
      'select_photo': 'Fotoğraf Seç',
      'select_video': 'Video Seç',
      'fill_all_fields': 'Lütfen tüm alanları doldurun',
      'speaker_added_success': 'Konuşmacı başarıyla eklendi',
      'speaker_updated_success': 'Konuşmacı başarıyla güncellendi',
      'content_added_success': 'İçerik başarıyla eklendi ve cihaza gönderildi',
      'invalid_time_format': 'Geçersiz zaman formatı',
      'video_upload_cancelled': 'Video gönderimi iptal edildi',
      'video_send_error': 'Video gönderilemedi',
      'video_path_not_found': 'Video yolu bulunamadı. Lütfen önce video yükleyin.',
      'export_no_content': 'Aktarılacak içerik bulunamadı.',
      'data_load_error': 'Veri Yüklenemedi',
      'retry_button': 'Tekrar Dene',

      
      'save_button': 'KAYDET',
      'cancel_button': 'İPTAL',

      
      'video_label': 'Video',

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
      'name_screen_header': 'NAME SCREEN',
      'add_speaker_btn': 'ADD NAME',
      'speaker_badge': 'SPEAKER INFO',
      'no_speakers_found': 'No speakers found',

      
      'info_screen_header': 'INFO SCREEN',
      'add_content_btn': 'ADD CONTENT',
      'export_computer_btn': 'EXPORT TO COMPUTER',
      'content_badge': 'CONTENT',
      'no_content_found': 'No content found',

      
      'department_label': 'Department/Division',
      'fullname_label': 'Full Name',
      'time_placeholder': '00:00:00',
      'active_status_label': 'Active Status',
      'active_button_label': 'Active Button',
      'sending_bluetooth': 'Sending to Bluetooth device...',
      'add_button': 'Add',

      
      'video_sending_title': 'Sending Video',
      'size_label': 'Size',
      'video_sent_success': 'Video Sent!\nNow enter the information.',
      'sending_cancelled': 'Sending Cancelled',
      'ok_button': 'OK',

      
      'select_photo': 'Select Photo',
      'select_video': 'Select Video',

      
      'fill_all_fields': 'Please fill in all fields',
      'speaker_added_success': 'Speaker successfully added',
      'speaker_updated_success': 'Speaker successfully updated',
      'content_added_success': 'Content successfully added and sent to device',
      'invalid_time_format': 'Invalid time format',
      'video_upload_cancelled': 'Video upload cancelled',
      'video_send_error': 'Video could not be sent',
      'video_path_not_found': 'Video path not found. Please upload video first.',
      'export_no_content': 'No content to export.',
      'data_load_error': 'Data Could Not Be Loaded',
      'retry_button': 'Try Again',

      
      'save_button': 'SAVE',
      'cancel_button': 'CANCEL',

      
      'video_label': 'Video',
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
      'name_screen_header': 'ЭКРАН ИМЕН',
      'add_speaker_btn': 'ДОБАВИТЬ ИМЯ',
      'speaker_badge': 'ИНФОРМАЦИЯ О ДОКЛАДЧИКЕ',
      'no_speakers_found': 'Докладчики не найдены',

      
      'info_screen_header': 'ИНФОРМАЦИОННЫЙ ЭКРАН',
      'add_content_btn': 'ДОБАВИТЬ КОНТЕНТ',
      'export_computer_btn': 'ЭКСПОРТ НА КОМПЬЮТЕР',
      'content_badge': 'СОДЕРЖАНИЕ',
      'no_content_found': 'Контент не найден',

      
      'department_label': 'Отдел/Подразделение',
      'fullname_label': 'ФИО',
      'time_placeholder': '00:00:00',
      'active_status_label': 'Активный статус',
      'active_button_label': 'Активная кнопка',
      'sending_bluetooth': 'Отправка на устройство Bluetooth...',
      'add_button': 'Добавить',

      
      'video_sending_title': 'Отправка видео',
      'size_label': 'Размер',
      'video_sent_success': 'Видео отправлено!\nТеперь введите информацию.',
      'sending_cancelled': 'Отправка отменена',
      'ok_button': 'ОК',

      
      'select_photo': 'Выбрать фото',
      'select_video': 'Выбрать видео',

      
      'fill_all_fields': 'Пожалуйста, заполните все поля',
      'speaker_added_success': 'Докладчик успешно добавлен',
      'speaker_updated_success': 'Докладчик успешно обновлен',
      'content_added_success': 'Контент успешно добавлен и отправлен на устройство',
      'invalid_time_format': 'Неверный формат времени',
      'video_upload_cancelled': 'Загрузка видео отменена',
      'video_send_error': 'Не удалось отправить видео',
      'video_path_not_found': 'Путь к видео не найден. Пожалуйста, сначала загрузите видео.',
      'export_no_content': 'Нет контента для экспорта.',
      'data_load_error': 'Не удалось загрузить данные',
      'retry_button': 'Повторить',

      
      'save_button': 'СОХРАНИТЬ',
      'cancel_button': 'ОТМЕНА',

      
      'video_label': 'Видео',
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
      'name_screen_header': 'شاشة الأسماء',
      'add_speaker_btn': 'إضافة اسم',
      'speaker_badge': 'معلومات المتحدث',
      'no_speakers_found': 'لم يتم العثور على متحدثين',

      
      'info_screen_header': 'شاشة المعلومات',
      'add_content_btn': 'إضافة محتوى',
      'export_computer_btn': 'تصدير إلى الكمبيوتر',
      'content_badge': 'المحتوى',
      'no_content_found': 'لم يتم العثور على محتوى',

      
      'department_label': 'القسم/الإدارة',
      'fullname_label': 'الاسم الكامل',
      'time_placeholder': '00:00:00',
      'active_status_label': 'الحالة النشطة',
      'active_button_label': 'زر نشط',
      'sending_bluetooth': 'الإرسال إلى جهاز البلوتوث...',
      'add_button': 'إضافة',

      
      'video_sending_title': 'إرسال الفيديو',
      'size_label': 'الحجم',
      'video_sent_success': 'تم إرسال الفيديو!\nأدخل المعلومات الآن.',
      'sending_cancelled': 'تم إلغاء الإرسال',
      'ok_button': 'حسناً',

      
      'select_photo': 'اختر صورة',
      'select_video': 'اختر فيديو',

      
      'fill_all_fields': 'يرجى ملء جميع الحقول',
      'speaker_added_success': 'تمت إضافة المتحدث بنجاح',
      'speaker_updated_success': 'تم تحديث المتحدث بنجاح',
      'content_added_success': 'تمت إضافة المحتوى وإرساله إلى الجهاز بنجاح',
      'invalid_time_format': 'تنسيق وقت غير صالح',
      'video_upload_cancelled': 'تم إلغاء تحميل الفيديو',
      'video_send_error': 'تعذر إرسال الفيديو',
      'video_path_not_found': 'لم يتم العثور على مسار الفيديو. يرجى تحميل الفيديو أولاً.',
      'export_no_content': 'لا يوجد محتوى للتصدير.',
      'data_load_error': 'تعذر تحميل البيانات',
      'retry_button': 'حاول مرة أخرى',

      
      'save_button': 'حفظ',
      'cancel_button': 'إلغاء',

      
      'video_label': 'فيديو',
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


class LanguagePage extends StatelessWidget {
  const LanguagePage({Key? key}) : super(key: key);

  static const List<Map<String, String>> _languages = [
    {'code': 'tr', 'name': 'TÜRKÇE', 'flag': 'assets/images/flag1.png'},
    {'code': 'en', 'name': 'ENGLISH', 'flag': 'assets/images/flag2.png'},
    {'code': 'ru', 'name': 'РУССКИЙ', 'flag': 'assets/images/flag3.png'},
    {'code': 'ar', 'name': 'اللغة العربية', 'flag': 'assets/images/flag4.png'},
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 60,
              width: double.infinity,
              child: ImageWidget(activePage: "language"),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.white,
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: _languages.map((lang) {
                        bool isSelected =
                            languageProvider.locale.languageCode == lang['code'];
                        return Container(
                          margin: EdgeInsets.only(bottom: screenHeight * 0.02),
                          child: _buildLanguageCard(context, lang, isSelected, isTablet, screenWidth, screenHeight),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard(BuildContext context, Map<String, String> lang, bool isSelected, bool isTablet, double screenWidth, double screenHeight) {
    return GestureDetector(
      onTap: () => _selectLanguage(context, lang),
      child: Container(
        width: isTablet ? screenWidth * 0.65 : screenWidth * 0.8, 
        height: isTablet ? screenHeight * 0.1 : screenHeight * 0.085,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.black
                : const Color(0xFFC5CAE9),
            width: isSelected ? 3 : 2,
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
              child: Center(
                child: Image.asset(
                  lang['flag']!,
                  width: isTablet ? 32 : 28,
                  height: isTablet ? 24 : 20,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    
                    return Container(
                      width: isTablet ? 32 : 28,
                      height: isTablet ? 24 : 20,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          lang['code']!.toUpperCase(),
                          style: TextStyle(
                            fontSize: isTablet ? 12 : 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 10 : 8,
                  vertical: isTablet ? 10 : 8,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang['name']!,
                      style: TextStyle(
                        fontSize: isTablet ? 16 : screenWidth * 0.038,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF37474F),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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