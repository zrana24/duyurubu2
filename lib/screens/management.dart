import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../language.dart';
import '../image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'connected.dart';
import 'dart:convert';
import 'connect.dart';

class TimeTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length > 6) digits = digits.substring(0, 6);

    String formatted = '';
    int len = digits.length;

    if (len >= 1) {
      formatted += digits.substring(0, len >= 2 ? 2 : 1);
    }
    if (len >= 2) {
      int hour = int.parse(digits.substring(0, 2));
      if (hour > 23) hour = 23;
      formatted = hour.toString().padLeft(2, '0');
    }

    if (len >= 3) {
      formatted += ":" + digits.substring(2, len >= 4 ? 4 : 3);
    }
    if (len >= 4) {
      int minute = int.parse(digits.substring(2, 4));
      if (minute > 59) minute = 59;
      formatted = formatted.substring(0, 3) + minute.toString().padLeft(2, '0');
    }

    if (len >= 5) {
      formatted += ":" + digits.substring(4, len >= 6 ? 6 : 5);
    }
    if (len == 6) {
      int second = int.parse(digits.substring(4, 6));
      if (second > 59) second = 59;
      formatted =
          formatted.substring(0, 6) + second.toString().padLeft(2, '0');
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class VideoUploadData {
  String videoPath;
  String videoName;
  String? title;
  String? startTime;
  String? endTime;

  VideoUploadData({
    required this.videoPath,
    required this.videoName,
    this.title,
    this.startTime,
    this.endTime,
  });
}

class Management extends StatefulWidget {
  const Management({Key? key}) : super(key: key);

  @override
  State<Management> createState() => _ManagementState();
}

class _ManagementState extends State<Management> {
  int _currentIndex = 0;
  final BluetoothService _bluetoothService = BluetoothService();
  Map<String, dynamic>? _cachedData;
  bool _isLoadingData = false;
  bool _hasError = false;
  String _errorMessage = '';
  StreamSubscription<Map<String, dynamic>>? _navigationSubscription;
  StreamSubscription<BluetoothServiceState>? _connectionStateSubscription;

  int? _activeSpeakerIndex;
  int? _activeContentIndex;

  @override
  void initState() {
    super.initState();
    _loadSharedData();

    _navigationSubscription = _bluetoothService.notificationStream.listen((notification) {
      if (!mounted) return;

      if (notification['type'] == 'navigation' && notification['message'] == 'navigate_to_connect') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => ConnectPage()),
              (route) => false,
        );
      }
    });

    _connectionStateSubscription = _bluetoothService.connectionStateStream.listen((state) {
      if (!mounted) return;

      if (state == BluetoothServiceState.connected) {
        print('🔄 Bağlantı yeniden kuruldu, veriler yeniden yükleniyor...');
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            _loadSharedData();
          }
        });
      }
    });
  }

  void _setActiveSpeakerIndex(int? index) {
    setState(() {
      _activeSpeakerIndex = index;
    });
  }

  void _setActiveContentIndex(int? index) {
    setState(() {
      _activeContentIndex = index;
    });
  }

  void _resetAllActiveItems() {
    setState(() {
      _activeSpeakerIndex = null;
      _activeContentIndex = null;
    });
  }

  Future<void> _loadSharedData() async {
    if (_isLoadingData) return;

    setState(() {
      _isLoadingData = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      Map<String, dynamic> freshData = await _bluetoothService.veriWithImages();

      setState(() {
        _cachedData = freshData;
        _hasError = false;
        _activeSpeakerIndex = null;
        _activeContentIndex = null;
      });

      print('✅ Veri başarıyla yüklendi');
    }
    catch (e, stackTrace) {
      print('❌ Veri yükleme hatası: $e');
      print(stackTrace);

      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _cachedData = null;
        _activeSpeakerIndex = null;
        _activeContentIndex = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Provider.of<LanguageProvider>(context, listen: false).getTranslation('data_load_error') + ': ${e.toString()}', style: TextStyle(fontFamily: 'brandontext')),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
    finally {
      setState(() => _isLoadingData = false);
    }
  }


  Widget _buildErrorWidget() {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            languageProvider.getTranslation('data_load_error'),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'brandontext'),
          ),
          SizedBox(height: 8),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600], fontFamily: 'brandontext'),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadSharedData,
            child: Text(languageProvider.getTranslation('retry_button'), style: TextStyle(fontFamily: 'brandontext')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 60,
              width: double.infinity,
              child: ImageWidget(activePage: "management"),
            ),

            Expanded(
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 18.0 : 14.0),
                child: _isLoadingData
                    ? Center(child: CircularProgressIndicator())
                    : _hasError
                    ? _buildErrorWidget()
                    : (isTablet ? _buildTabletLayout() : _buildMobileLayout()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(
          flex: 1,
          child: SpeakerManagement(
            cachedData: _cachedData,
            activeIndex: _activeSpeakerIndex,
            onActiveIndexChanged: _setActiveSpeakerIndex,
          ),
        ),
        Expanded(
          flex: 1,
          child: ContentManagement(
            cachedData: _cachedData,
            activeIndex: _activeContentIndex,
            onActiveIndexChanged: _setActiveContentIndex,
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: const Color(0xFF469088),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SpeakerManagement(
              cachedData: _cachedData,
              activeIndex: _activeSpeakerIndex,
              onActiveIndexChanged: _setActiveSpeakerIndex,
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: const Color(0xFF469088),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ContentManagement(
              cachedData: _cachedData,
              activeIndex: _activeContentIndex,
              onActiveIndexChanged: _setActiveContentIndex,
            ),
          ),
        ),
      ],
    );
  }
}

class SpeakerManagement extends StatefulWidget {
  final Map<String, dynamic>? cachedData;
  final int? activeIndex;
  final Function(int?) onActiveIndexChanged;

  const SpeakerManagement({
    Key? key,
    this.cachedData,
    this.activeIndex,
    required this.onActiveIndexChanged,
  }) : super(key: key);

  @override
  State<SpeakerManagement> createState() => _SpeakerManagementState();
}

class _SpeakerManagementState extends State<SpeakerManagement> {
  final BluetoothService _bluetoothService = BluetoothService();
  List<Map<String, dynamic>> _speakers = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadDataFromCache();
  }

  @override
  void didUpdateWidget(SpeakerManagement oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.activeIndex != oldWidget.activeIndex) {
      _updateSpeakersPlayState();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadDataFromCache() {
    if (widget.cachedData != null &&
        widget.cachedData!.containsKey('isimlik') &&
        widget.cachedData!['isimlik'] is List) {
      List<dynamic> isimlikList = widget.cachedData!['isimlik'];
      setState(() {
        _speakers = isimlikList.map((item) => {
          'department': item['title'] ?? '',
          'name': item['name'] ?? '',
          'time': item['duration'] ?? '00:00:00',
          'isEditing': false,
          'isActive': item['is_active'] ?? false,
          'toggle': item['toggle'] ?? false,
          'isPlaying': widget.activeIndex == isimlikList.indexOf(item),
        }).toList();
        _isLoading = false;
      });
      print(_speakers);
      print('✅ İsimlik verileri yüklendi: ${_speakers.length} kayıt');
    }
    else {
      setState(() => _isLoading = false);
      print('İsimlik verisi bulunamadı');
    }
  }

  void _updateSpeakersPlayState() {
    setState(() {
      for (int i = 0; i < _speakers.length; i++) {
        _speakers[i]['isPlaying'] = widget.activeIndex == i;
      }
    });
  }

  void _addNewSpeaker() {
    setState(() {
      _speakers.add({
        'department': Provider.of<LanguageProvider>(context, listen: false).getTranslation('department_label'),
        'name': Provider.of<LanguageProvider>(context, listen: false).getTranslation('fullname_label'),
        'time': '00:00:00',
        'isEditing': true,
        'isNew': true,
        'isActive': false,
        'toggle': false,
        'isPlaying': false,
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        Future.delayed(Duration(milliseconds: 100), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
            );
          }
        });
      }
    });
  }

  Future<void> _saveSpeaker(int index, String department, String name, String time, bool toggleValue) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    if (department.trim().isEmpty || name.trim().isEmpty || department == "Ünvan" || name == "Ad Soyad" || time.trim()
        .isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(languageProvider.getTranslation('empty_field_warning'), style: TextStyle(fontFamily: 'brandontext')),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ));
      return;
    }

    if (time.replaceAll(':', '').length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(languageProvider.getTranslation('invalid_time_format'), style: TextStyle(fontFamily: 'brandontext')),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ));
      return;
    }

    try {
      await _bluetoothService.isimlikAdd(
        name: name,
        title: department,
        togle: toggleValue,
        isActive: false,
        time: time,
      );
      print(toggleValue);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(languageProvider.getTranslation('speaker_added_success'), style: TextStyle(fontFamily: 'brandontext')),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ));

      setState(() {
        _speakers[index] = {
          'department': department.trim(),
          'name': name.trim(),
          'time': time,
          'isEditing': false,
          'isNew': false,
          'isActive': toggleValue,
          'toggle': false,
          'isPlaying': _speakers[index]['isPlaying'] ?? false,
        };
      });
    }
    catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(languageProvider.getTranslation('error') + ': $e', style: TextStyle(fontFamily: 'brandontext')),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ));
    }
  }

  void _cancelEdit(int index) {
    setState(() {
      if (_speakers[index]['isNew'] == true) {
        _speakers.removeAt(index);
      } else {
        _speakers[index]['isEditing'] = false;
      }
    });
  }

  Future<void> _deleteSpeaker(int index) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Expanded(
                  child: Text(
                    languageProvider.getTranslation('deleting_please_wait') ?? 'Siliniyor, lütfen bekleyin...',
                    style: TextStyle(fontFamily: 'brandontext'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (widget.activeIndex == index) {
      widget.onActiveIndexChanged(null);
      final parentState = context.findAncestorStateOfType<_ManagementState>();
      parentState?._setActiveSpeakerIndex(null);
    }

    try {
      bool isDeleted = await _bluetoothService.delete(id: index, tip: "isimlik");

      if (mounted) {
        Navigator.of(context).pop();
      }

      if (isDeleted) {
        setState(() {
          _speakers.removeAt(index);
        });

        final parentState = context.findAncestorStateOfType<_ManagementState>();
        await parentState?._loadSharedData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                languageProvider.getTranslation('speaker_deleted_success') ?? 'Konuşmacı başarıyla silindi',
                style: TextStyle(fontFamily: 'brandontext'),
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                languageProvider.getTranslation('delete_failed') ?? 'Silme işlemi başarısız',
                style: TextStyle(fontFamily: 'brandontext'),
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${languageProvider.getTranslation('error')}: $e',
              style: TextStyle(fontFamily: 'brandontext'),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _toggleSpeakerPlay(int index) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentIsPlaying = _speakers[index]['isPlaying'] ?? false;

    String department = _speakers[index]['department'] as String? ?? '';
    String name = _speakers[index]['name'] as String? ?? '';

    bool isDepartmentEmpty = department.trim().isEmpty ||
        department == languageProvider.getTranslation('department_label') ||
        department == 'Ünvan';

    bool isNameEmpty = name.trim().isEmpty ||
        name == languageProvider.getTranslation('fullname_label') ||
        name == 'Konuşmacı Adı';

    if (isDepartmentEmpty && isNameEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            languageProvider.getTranslation('empty_field_warning'),
            style: TextStyle(fontFamily: 'brandontext'),
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      int id = index;
      String tip = "isimlik";

      print("id:$id tip:$tip isPlaying:$currentIsPlaying");

      final managementState = context.findAncestorStateOfType<_ManagementState>();

      if (currentIsPlaying) {
        await _bluetoothService.playStatus(id: id, tip: tip);
        widget.onActiveIndexChanged(null);
        managementState?._setActiveSpeakerIndex(null);
      }
      else {

        if (widget.activeIndex != null && widget.activeIndex != index) {
          int previousActiveSpeakerId = widget.activeIndex!;
          await _bluetoothService.playStatus(id: previousActiveSpeakerId, tip: tip);
        }

        await _bluetoothService.playStatus(id: id, tip: tip);
        widget.onActiveIndexChanged(index);
        managementState?._setActiveSpeakerIndex(index);
      }

    } catch (e) {
      print("Play/Pause hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${languageProvider.getTranslation('error')}: $e',
            style: TextStyle(fontFamily: 'brandontext')),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ));
    }
  }


  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Column(
      children: [
        Container(
          height: isTablet ? 50 : 44,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFD0F9F9),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFF00D0C6),
                width: 0.3,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 4 : 2,
              vertical: isTablet ? 3 : 1,
            ),
            child: Row(
              children: [
                Container(
                  width: isTablet ? 64 : 48,
                  height: isTablet ? 24 : 18,
                  child: Center(
                    child: Image.asset(
                      'assets/images/logo2.png',
                      width: isTablet ? 28 : 32,
                      height: isTablet ? 18 : 14,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Text(
                  languageProvider.getTranslation('name_screen_header'),
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1D7269),
                    height: 0.7,
                    fontFamily: 'brandontext',
                  ),
                ),
                SizedBox(width: isTablet ? 190 : 180),
                GestureDetector(
                  onTap: _addNewSpeaker,
                  child: Container(
                    margin: EdgeInsets.only(left: isTablet ? 17 : 15),
                    height: isTablet ? 28 : 24,
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 10 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFF469088),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          languageProvider.getTranslation('add_speaker_btn'),
                          style: TextStyle(
                            fontSize: isTablet ? 13.5 : 11,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF0D7066),
                            height: 1.2,
                            fontFamily: 'brandontext',
                          ),
                        ),
                        SizedBox(width: isTablet ? 6 : 4),
                        Container(
                          width: isTablet ? 16 : 13,
                          height: isTablet ? 16 : 13,
                          child: Image.asset(
                            'assets/images/icerik.png',
                            color: const Color(0xFF0D7066),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFCFDFD),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: _speakers.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  languageProvider.getTranslation('no_speakers_found'),
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: Colors.grey[600],
                    fontFamily: 'brandontext',
                  ),
                ),
              ),
            )
                : SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int index = 0; index < _speakers.length; index++) ...[
                    EditableSpeakerCard(
                      speaker: _speakers[index],
                      index: index,
                      isTablet: isTablet,
                      isPlaying: _speakers[index]['isPlaying'] ?? false,
                      isActive: _speakers[index]['isActive'] ?? false,
                      onSave: (department, name, time, toggleValue) =>
                          _saveSpeaker(index, department, name, time, toggleValue),
                      onCancel: () => _cancelEdit(index),
                      onDelete: () => _deleteSpeaker(index),
                      onPlayToggle: () => _toggleSpeakerPlay(index),
                      onToggleChange: (value) {
                        setState(() {
                          _speakers[index]['isActive'] = value;
                        });
                      },
                    ),
                    if (index < _speakers.length - 1)
                      Transform.translate(
                        offset: Offset(0, isTablet ? -12.0 : -10.0),
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: isTablet ? 13 : 8,
                          ),
                          height: 0,
                          width: isTablet ? 711.0 : double.infinity,
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: const Color(0xFF00D0C6),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ContentManagement extends StatefulWidget {
  final Map<String, dynamic>? cachedData;
  final int? activeIndex;
  final Function(int?) onActiveIndexChanged;

  const ContentManagement({
    Key? key,
    this.cachedData,
    this.activeIndex,
    required this.onActiveIndexChanged,
  }) : super(key: key);

  @override
  State<ContentManagement> createState() => _ContentManagementState();
}

class _ContentManagementState extends State<ContentManagement> {
  final BluetoothService _bluetoothService = BluetoothService();
  List<Map<String, dynamic>> _contents = [];
  final ImagePicker _picker = ImagePicker();
  bool _showExportSuccess = false;
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadDataFromCache();
  }

  @override
  void didUpdateWidget(ContentManagement oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.activeIndex != oldWidget.activeIndex) {
      _updateContentsPlayState();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadDataFromCache() {
    if (widget.cachedData != null &&
        widget.cachedData!.containsKey('bilgi') &&
        widget.cachedData!['bilgi'] is List) {
      List<dynamic> bilgiList = widget.cachedData!['bilgi'];


      setState(() {
        _contents = bilgiList.map((item) {
          Image? thumbnail = item['thumbnailImage'];
          String title = item['meeting_title'] as String? ?? '';
          if (title.trim().isEmpty) {
            title = Provider.of<LanguageProvider>(context, listen: false).getTranslation('meeting_topic');
          }

          return {
            'title': title,
            'startTime': item['start_hour'] ?? '00:00:00',
            'endTime': item['end_hour'] ?? '00:00:00',
            'type': (item['path'] ?? '').toString().toLowerCase().endsWith('.mp4') ? 'video' : 'photo',
            'file': null,
            'isEditing': false,
            'videoPath': item['path'] ?? '',
            'isActive': item['is_active'] ?? false,
            'buttonStatus': item['button_status'] ?? false,
            'thumbnailBase64': item['thumbnailBase64'] ?? '',
            'thumbnail': thumbnail,
            'isPlaying': widget.activeIndex == bilgiList.indexOf(item),
          };
        }).toList();
        _isLoading = false;
        print(_contents);
      });

      print('Bilgi verileri yüklendi: ${_contents.length} kayıt');
    }
    else {
      setState(() => _isLoading = false);
      print('Bilgi verisi bulunamadı');
    }
  }

  void _updateContentsPlayState() {
    setState(() {
      for (int i = 0; i < _contents.length; i++) {
        _contents[i]['isPlaying'] = widget.activeIndex == i;
      }
    });
  }

  void _addNewContent() {
    setState(() {
      _contents.add({
        'title': Provider.of<LanguageProvider>(context, listen: false).getTranslation('meeting_topic'),
        'startTime': '00:00:00',
        'endTime': '00:00:00',
        'type': 'photo',
        'file': null,
        'isEditing': true,
        'isNew': true,
        'videoPath': null,
        'isPlaying': false,
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        Future.delayed(Duration(milliseconds: 100), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
            );
          }
        });
      }
    });
  }

  Future<void> _pickFile(int index) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    if (_contents[index]['isEditing'] != true) {
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.videocam, size: 22),
                title: Text(languageProvider.getTranslation('select_video'), style: TextStyle(fontSize: 14, fontFamily: 'brandontext')),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
                  if (video != null) {
                    final videoFile = File(video.path);

                    try {
                      final videoSize = await videoFile.length();
                      final videoSizeMB = (videoSize / (1024 * 1024)).toStringAsFixed(2);

                      print("Video: ${video.name}");
                      print("Boyut: $videoSize bytes ($videoSizeMB MB)");

                      _showVideoUploadProgress(
                        videoName: video.name,
                        videoPath: video.path,
                        videoSizeMB: videoSizeMB,
                        index: index,
                        videoFile: videoFile,
                      );
                    } catch (e) {
                      print("Video boyut hatası: $e");
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showVideoUploadProgress({
    required String videoName,
    required String videoPath,
    required String videoSizeMB,
    required int index,
    required File videoFile,
  }) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    double uploadProgress = 0.0;
    bool isUploading = true;
    bool isCancelled = false;

    late StateSetter dialogSetState;
    late BuildContext dialogContext;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        dialogContext = ctx;

        return StatefulBuilder(
          builder: (context, setState) {
            dialogSetState = setState;

            return WillPopScope(
              onWillPop: () async => false,
              child: AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.videocam, color: Color(0xFF196E64)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        languageProvider.getTranslation('video_sending_title'),
                        style: TextStyle(fontSize: 18, fontFamily: 'brandontext'),
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      videoName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'brandontext',
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${languageProvider.getTranslation('size_label')}: $videoSizeMB MB',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'brandontext',
                      ),
                    ),
                    SizedBox(height: 24),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: uploadProgress / 100,
                        minHeight: 12,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF196E64),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),

                    Text(
                      '${uploadProgress.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF196E64),
                        fontFamily: 'brandontext',
                      ),
                    ),

                    if (!isUploading && !isCancelled)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Text(
                              languageProvider.getTranslation('video_sent_success'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'brandontext',
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (isCancelled)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cancel, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text(
                              languageProvider.getTranslation('sending_cancelled'),
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'brandontext',
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                actions: [
                  if (isUploading)
                    TextButton(
                      onPressed: () {
                        dialogSetState(() {
                          isCancelled = true;
                          isUploading = false;
                        });

                        Navigator.of(dialogContext).pop();

                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text(languageProvider.getTranslation('video_upload_cancelled'), style: TextStyle(fontFamily: 'brandontext')),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      },
                      child: Text(
                        languageProvider.getTranslation('cancel_button'),
                        style: TextStyle(color: Colors.red, fontFamily: 'brandontext'),
                      ),
                    ),

                  if (!isUploading)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF196E64),
                      ),
                      child: Text(
                        languageProvider.getTranslation('ok_button'),
                        style: TextStyle(color: Colors.white, fontFamily: 'brandontext'),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );

    _bluetoothService.videosend(
      size: videoSizeMB,
      name: videoName,
      videoPath: videoPath,
      onProgress: (progress) {
        if (!isCancelled && mounted) {
          try {
            dialogSetState(() {
              uploadProgress = progress;
            });
          }
          catch (e) {
            print('güncelleme hatası: $e');
          }
        }
      },
    ).then((_) {
      if (!isCancelled && mounted) {
        dialogSetState(() {
          isUploading = false;
          uploadProgress = 100.0;
        });

        String? serverVideoPath = _bluetoothService.receivedVideoPath;
        print(serverVideoPath);
        setState(() {
          _contents[index]['file'] = videoFile;
          _contents[index]['type'] = 'video';
          _contents[index]['videoPath'] = serverVideoPath;
        });

        print('✅ Video path kaydedildi: ${_contents[index]['videoPath']}');

        if (serverVideoPath != null && serverVideoPath.isNotEmpty) {
          ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(
              content: Text('Video yolu alındı: $serverVideoPath', style: TextStyle(fontFamily: 'brandontext')),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }).catchError((e) {
      if (!isCancelled && mounted) {
        dialogSetState(() {
          isUploading = false;
        });

        Navigator.of(dialogContext).pop();

        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.getTranslation('video_send_error') + ': $e', style: TextStyle(fontFamily: 'brandontext')),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    });
  }

  Future<void> _saveContent(int index, String title, String startTime, String endTime, bool isActive) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    if (title.trim().isEmpty || title == "Toplantı Konusu" || startTime.trim().isEmpty || endTime.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(languageProvider.getTranslation('empty_field_warning'),
            style: TextStyle(fontFamily: 'brandontext')),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ));
      return;
    }

    RegExp timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9])$');

    if (!timeRegex.hasMatch(startTime) || !timeRegex.hasMatch(endTime)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(languageProvider.getTranslation('invalid_time_format'), style: TextStyle(fontFamily: 'brandontext')),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ));
      return;
    }

    try {
      String? videoPath = _contents[index]['videoPath'] as String?;

      if (videoPath == null || videoPath.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(languageProvider.getTranslation('video_path_not_found'), style: TextStyle(fontFamily: 'brandontext')),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ));
        return;
      }

      print('📤 bilgiAdd çağrılıyor - path: $videoPath');

      await _bluetoothService.bilgiAdd(
        meeting_title: title.trim(),
        start_hour: startTime,
        end_hour: endTime,
        path: videoPath,
        is_active: isActive,
        button_status: false,
      );

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(languageProvider.getTranslation('content_added_success'), style: TextStyle(fontFamily: 'brandontext')),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ));

      setState(() {
        _contents[index] = {
          'title': title.trim(),
          'startTime': startTime,
          'endTime': endTime,
          'type': _contents[index]['type'],
          'file': _contents[index]['file'],
          'videoPath': videoPath,
          'isEditing': false,
          'isNew': false,
          'isActive': isActive,
          'borderColor': _contents[index]['borderColor'] ?? const Color(0xFF5E6676),
          'isPlaying': _contents[index]['isPlaying'] ?? false,
        };
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${languageProvider.getTranslation('error')}: ${e.toString()}', style: TextStyle(fontFamily: 'brandontext')),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ));
    }
  }

  void _cancelEdit(int index) {
    setState(() {
      if (_contents[index]['isNew'] == true) {
        _contents.removeAt(index);
      } else {
        _contents[index]['isEditing'] = false;
      }
    });
  }

  Future<void> _deleteContent(int index) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Expanded(
                  child: Text(
                    languageProvider.getTranslation('deleting_please_wait') ?? 'Siliniyor, lütfen bekleyin...',
                    style: TextStyle(fontFamily: 'brandontext'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (widget.activeIndex == index) {
      widget.onActiveIndexChanged(null);
      final parentState = context.findAncestorStateOfType<_ManagementState>();
      parentState?._setActiveContentIndex(null);
    }

    try {
      bool isDeleted = await _bluetoothService.delete(id: index, tip: "bilgi");

      if (mounted) {
        Navigator.of(context).pop();
      }

      if (isDeleted) {
        setState(() {
          _contents.removeAt(index);
        });

        final parentState = context.findAncestorStateOfType<_ManagementState>();
        await parentState?._loadSharedData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                languageProvider.getTranslation('content_deleted_success') ?? 'İçerik başarıyla silindi',
                style: TextStyle(fontFamily: 'brandontext'),
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                languageProvider.getTranslation('delete_failed') ?? 'Silme işlemi başarısız',
                style: TextStyle(fontFamily: 'brandontext'),
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${languageProvider.getTranslation('error')}: $e',
              style: TextStyle(fontFamily: 'brandontext'),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _toggleContentPlay(int index) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentIsPlaying = _contents[index]['isPlaying'] ?? false;
    var videoPath = _contents[index]['videoPath'] as String?;
    var title = _contents[index]['title'] as String?;

    print('videoPath değeri: "$videoPath"');
    print("title $title");

    bool video = videoPath == null || videoPath.isEmpty;
    bool gelentitle = title == null || title == "Toplantı Konusu" ||
        title.trim().isEmpty ||
        title == languageProvider.getTranslation('meeting_topic');

    if (video && gelentitle) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            languageProvider.getTranslation('video_and_title_missing_warning') ?? '',
            style: TextStyle(fontFamily: 'brandontext'),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      int id = index;
      String tip = "bilgi";

      print("id:$id tip:$tip isPlaying:$currentIsPlaying");

      final managementState = context.findAncestorStateOfType<_ManagementState>();

      if (currentIsPlaying) {
        await _bluetoothService.playStatus(id: id, tip: tip);
        widget.onActiveIndexChanged(null);
        managementState?._setActiveContentIndex(null);
      }
      else {
        if (widget.activeIndex != null && widget.activeIndex != index) {
          int previousActiveContentId = widget.activeIndex!;
          await _bluetoothService.playStatus(id: previousActiveContentId, tip: tip);
        }

        await _bluetoothService.playStatus(id: id, tip: tip);
        widget.onActiveIndexChanged(index);
        managementState?._setActiveContentIndex(index);
      }

    } catch (e) {
      print("Play/Pause hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${languageProvider.getTranslation('error')}: $e',
            style: TextStyle(fontFamily: 'brandontext')),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Column(
      children: [
        Container(
          height: isTablet ? 50 : 44,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFD0F9F9),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFF00D0C6),
                width: 0.3,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 6 : 4,
            ),
            child: Row(
              children: [
                Container(
                  width: isTablet ? 64 : 48,
                  height: isTablet ? 24 : 18,
                  child: Center(
                    child: Image.asset(
                      'assets/images/3car.png',
                      width: isTablet ? 32 : 36,
                      height: isTablet ? 18 : 14,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Text(
                  languageProvider.getTranslation('info_screen_header'),
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1D7269),
                    height: 0.7,
                    fontFamily: 'brandontext',
                  ),
                ),
                SizedBox(width: isTablet ? 190 : 180),
                if (screenWidth > 400)
                  GestureDetector(
                    onTap: _addNewContent,
                    child: Container(
                      margin: EdgeInsets.only(left: isTablet ? 17 : 15),
                      height: isTablet ? 28 : 24,
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 10 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: const Color(0xFF469088),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (screenWidth > 400)
                            Text(
                              languageProvider.getTranslation('add_content_btn'),
                              style: TextStyle(
                                fontSize: isTablet ? 13.5 : 11,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF0D7066),
                                height: 0.92,
                                fontFamily: 'brandontext',
                              ),
                            ),
                          if (screenWidth > 400) SizedBox(width: isTablet ? 8
                              : 6),
                          Container(
                            width: isTablet ? 16 : 13,
                            height: isTablet ? 16 : 13,
                            child: Image.asset(
                              'assets/images/icerikbuton.png',
                              color: const Color(0xFF0D7066),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFCFDFD),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: _contents.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  languageProvider.getTranslation('no_content_found'),
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: Colors.grey[600],
                    fontFamily: 'brandontext',
                  ),
                ),
              ),
            )
                : SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int index = 0; index < _contents.length; index++) ...[
                    EditableContentCard(
                      content: _contents[index],
                      index: index,
                      isTablet: isTablet,
                      isPlaying: _contents[index]['isPlaying'] ?? false,
                      isActive: _contents[index]['isActive'] ?? false,
                      onSave: (title, startTime, endTime, isActive) =>
                          _saveContent(index, title, startTime, endTime, isActive),
                      onCancel: () => _cancelEdit(index),
                      onDelete: () => _deleteContent(index),
                      onFilePick: () => _pickFile(index),
                      onPlayToggle: () => _toggleContentPlay(index),
                      onToggleChange: (value) {
                        setState(() {
                          _contents[index]['isActive'] = value;
                        });
                      },
                    ),
                    if (index < _contents.length - 1)
                      Transform.translate(
                        offset: Offset(0, isTablet ? -12.0 : -10.0),
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: isTablet ? 13 : 8,
                          ),
                          height: 0,
                          width: isTablet ? 711.0 : double.infinity,
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: const Color(0xFF00D0C6),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class EditableSpeakerCard extends StatefulWidget {
  final Map<String, dynamic> speaker;
  final int index;
  final bool isTablet;
  final bool isPlaying;
  final bool isActive;
  final Function(String, String, String, bool) onSave;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final VoidCallback onPlayToggle;
  final Function(bool) onToggleChange;

  const EditableSpeakerCard({
    Key? key,
    required this.speaker,
    required this.index,
    required this.isTablet,
    required this.isPlaying,
    required this.isActive,
    required this.onSave,
    required this.onCancel,
    required this.onDelete,
    required this.onPlayToggle,
    required this.onToggleChange,
  }) : super(key: key);

  @override
  State<EditableSpeakerCard> createState() => _EditableSpeakerCardState();
}

class _EditableSpeakerCardState extends State<EditableSpeakerCard> {
  final BluetoothService _bluetooth = BluetoothService();
  late TextEditingController _departmentController;
  late TextEditingController _nameController;
  late TextEditingController _timeController;
  FocusNode? _timeFocusNode;
  late bool _isPlaying;
  late bool _isSwitchActive;
  String tip="isimlik";

  Timer? _countdownTimer;
  String _currentTime = '00:00:00';

  @override
  void initState() {
    super.initState();
    _departmentController = TextEditingController(text: widget.speaker['department'] as String);
    _nameController = TextEditingController(text: widget.speaker['name'] as String);
    _timeController = TextEditingController(text: widget.speaker['time'] as String);
    _timeFocusNode = FocusNode();
    _currentTime = widget.speaker['time'] as String? ?? '00:00:00';
    _isSwitchActive = widget.speaker['toggle'] as bool? ?? false;
    _isPlaying = widget.isPlaying;

    _timeFocusNode?.addListener(() {
      if (_timeFocusNode!.hasFocus && _timeController.text.isNotEmpty) {
        _timeController.clear();
      }
    });
  }

  @override
  void didUpdateWidget(EditableSpeakerCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isPlaying != oldWidget.isPlaying) {
      setState(() {
        _isPlaying = widget.isPlaying;
      });
    }
    if (widget.isActive != oldWidget.isActive) {
      setState(() {
        _isSwitchActive = widget.isActive;
      });
    }

    if (widget.speaker['toggle'] != oldWidget.speaker['toggle']) {
      setState(() {
        _isSwitchActive = widget.speaker['toggle'] as bool? ?? false;
      });
    }

    if (!widget.isPlaying && _isPlaying) {
      setState(() {
        _isPlaying = false;
        _countdownTimer?.cancel();
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _departmentController.dispose();
    _nameController.dispose();
    _timeController.dispose();
    _timeFocusNode?.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        List<String> parts = _currentTime.split(':');
        if (parts.length != 3) {
          timer.cancel();
          _isPlaying = false;
          return;
        }

        int hours = int.tryParse(parts[0]) ?? 0;
        int minutes = int.tryParse(parts[1]) ?? 0;
        int seconds = int.tryParse(parts[2]) ?? 0;

        int totalSeconds = hours * 3600 + minutes * 60 + seconds;
        totalSeconds--;

        if (totalSeconds <= 0) {
          _currentTime = '00:00:00';
          _isPlaying = false;
          timer.cancel();
          return;
        }

        hours = totalSeconds ~/ 3600;
        minutes = (totalSeconds % 3600) ~/ 60;
        seconds = totalSeconds % 60;

        _currentTime = '${hours.toString().padLeft(2, '0')}:'
            '${minutes.toString().padLeft(2, '0')}:'
            '${seconds.toString().padLeft(2, '0')}';
      });
    });
  }

  void _togglePlay() async {
    widget.onPlayToggle();
  }

  Color _getBorderColor() {
    return widget.speaker['borderColor'] as Color? ?? const Color(0xFF5E6676);
  }

  bool get _isEditing => widget.speaker['isEditing'] as bool? ?? false;

  void _toggleSwitch() {
    setState(() {
      _isSwitchActive = !_isSwitchActive;
    });
    widget.onToggleChange(_isSwitchActive);
  }

  Widget _buildCharacterCounter(int currentLength) {
    var renk=Colors.grey[600];
    if(currentLength>24){
      renk=Colors.red[600];
    }else if(currentLength>14){
      renk=Colors.yellow[700];
    }else{
      renk=Colors.grey[600];
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isTablet ? 5.0 : 4.0,
        vertical: widget.isTablet ? 2.5 : 2.0,
      ),
      margin: EdgeInsets.only(
          right: widget.isTablet ? 0 : 0
      ),
      decoration: BoxDecoration(
        color: renk,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$currentLength/35',
        style: TextStyle(
          fontSize: widget.isTablet ? 9.5 : 8.0,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          fontFamily: 'brandontext',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardHeight = widget.isTablet ? 143.0 : 133.0;
    final borderColor = _getBorderColor();
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Container(
        margin: EdgeInsets.only(
          left: widget.isTablet ? 13 : 8,
          right: widget.isTablet ? 13 : 8,
          top: widget.isTablet ? (widget.index == 0 ? 20 : 0) : (widget.index == 0 ? 15 : 0),
          bottom: widget.isTablet ? 24 : 20,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              height: cardHeight,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: borderColor,
                  width: 0.3,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildLeftSection(borderColor),
                  ),
                  if (widget.isTablet)
                    _buildRightSection(borderColor, languageProvider)
                  else
                    const SizedBox.shrink(),
                ],
              ),
            ),
            Positioned(
              left: widget.isTablet ? 10.0 : 8.0,
              top: -10.0,
              child: _buildSpeakerBadgeWithBorder(widget.index + 1, borderColor, languageProvider),
            ),
          ],
        )
    );
  }

  Widget _buildLeftSection(Color borderColor) {
    return SizedBox(
      width: widget.isTablet ? 480.0 : double.infinity,
      height: widget.isTablet ? 143.0 : 133.0,
      child: Padding(
        padding: EdgeInsets.only(
          left: widget.isTablet ? 20.0 : 16.0,
          right: widget.isTablet ? 20.0 : 18.0,
          top: widget.isTablet ? 28.0 : 24.0,
          bottom: widget.isTablet ? 24.0 : 20.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildImageIcon('assets/images/icerik.png', widget.isTablet ? 18 : 16, widget.isTablet ? 16 : 14),
                SizedBox(width: widget.isTablet ? 6.0 : 4.0),
                Expanded(
                  child: _isEditing
                      ? TextField(
                    controller: _departmentController,
                    maxLength: 35,
                    onTap: () {
                      if (_departmentController.text == widget.speaker['department']) {
                        _departmentController.clear();
                      }
                    },
                    onChanged: (value) {
                      setState(() {});
                    },
                    style: TextStyle(
                      fontSize: widget.isTablet ? 17.0 : 15,
                      fontWeight: FontWeight.w400,
                      color: _departmentController.text == widget.speaker['department']
                          ? Colors.grey[600]
                          : (borderColor == const Color(0xFF5E6676)
                          ? const Color(0xFF000000)
                          : const Color(0xFFA24D00)),
                      height: 0.94,
                      fontFamily: 'brandontext',
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      counterText: '',
                    ),
                  )
                      : Text(
                    widget.speaker['department'] as String,
                    style: TextStyle(
                      fontSize: widget.isTablet ? 17.0 : 15,
                      fontWeight: FontWeight.w400,
                      color: borderColor == const Color(0xFF5E6676)
                          ? const Color(0xFF414A5D)
                          : const Color(0xFFA24D00),
                      height: 0.94,
                      fontFamily: 'brandontext',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_isEditing) ...[
                  SizedBox(width: widget.isTablet ? 8.0 : 6.0),
                  _buildCharacterCounter(_departmentController.text.length),
                ],
              ],
            ),
            SizedBox(height: widget.isTablet ? 1 : 0.5),
            Row(
              children: [
                _buildImageIcon('assets/images/konusmaci.png', widget.isTablet ? 18 : 16, widget.isTablet ? 20 : 18),
                SizedBox(width: widget.isTablet ? 6.0 : 4.0),
                Expanded(
                  child: _isEditing
                      ? TextField(
                    controller: _nameController,
                    maxLength: 35,
                    onTap: () {
                      if (_nameController.text == widget.speaker['name']) {
                        _nameController.clear();
                      }
                    },
                    onChanged: (value) {
                      setState(() {});
                    },
                    style: TextStyle(
                      fontSize: widget.isTablet ? 17.0 : 15,
                      fontWeight: FontWeight.w400,
                      color: _nameController.text == widget.speaker['name']
                          ? Colors.grey[600]
                          : (borderColor == const Color(0xFF5E6676)
                          ? const Color(0xFF000000)
                          : const Color(0xFFA24D00)),
                      height: 0.94,
                      fontFamily: 'brandontext',
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      counterText: '',
                    ),
                  )
                      : Text(
                    widget.speaker['name'] as String,
                    style: TextStyle(
                      fontSize: widget.isTablet ? 17.0 : 15,
                      fontWeight: FontWeight.w400,
                      color: borderColor == const Color(0xFF5E6676)
                          ? const Color(0xFF414A5D)
                          : const Color(0xFFA24D00),
                      height: 0.94,
                      fontFamily: 'brandontext',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_isEditing) ...[
                  SizedBox(width: widget.isTablet ? 8.0 : 6.0),
                  _buildCharacterCounter(_nameController.text.length),
                ],
              ],
            ),
            SizedBox(height: widget.isTablet ? 1 : 0.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildImageIcon('assets/images/saat.png', widget.isTablet ? 18 : 16, widget.isTablet ? 20 : 18),
                    SizedBox(width: widget.isTablet ? 6.0 : 4.0),
                    _buildDigitalTime(
                      _currentTime,
                      borderColor == const Color(0xFF5E6676)
                          ? const Color(0xFF3B4458)
                          : const Color(0xFFA24D00),
                      widget.isTablet,
                      _isEditing,
                      _isEditing ? _timeController : null,
                      _isEditing ? _timeFocusNode : null,
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: widget.isTablet ? 18 : 16,
                      height: widget.isTablet ? 18 : 16,
                      margin: EdgeInsets.only(right: widget.isTablet ? 12.0 :
                      10.0),
                      child: Image.asset(
                        'assets/images/zamanlayici-yesil.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    _buildToggleSwitch(),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDigitalTime(String time, Color textColor, bool isTablet, bool isEditing, [TextEditingController? controller, FocusNode? focusNode]) {
    if (isEditing && controller != null && focusNode != null) {
      return SizedBox(
        width: isTablet ? 120.0 : 110.0,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          inputFormatters: [
            TimeTextInputFormatter(),
          ],
          style: TextStyle(
            fontSize: isTablet ? 16.0 : 13,
            fontWeight: FontWeight.w400,
            fontFamily: 'digitalClock',
            color: textColor,
            height: 0.70,
            letterSpacing: 2.5,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
            hintText: '00:00:00',
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < time.length; i++)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: time[i] == ':' ? 2.0 : 1.0),
            child: Text(
              time[i],
              style: TextStyle(
                fontSize: isTablet ? 16.0 : 13,
                fontWeight: FontWeight.w400,
                fontFamily: 'digitalClock',
                color: textColor,
                height: 0.70,
                letterSpacing: 0,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageIcon(String imagePath, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Image.asset(
        imagePath,
        width: width * 0.7,
        height: height * 0.7,
        color: const Color(0xFF3C465A),
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildToggleSwitch() {
    return GestureDetector(
      key: ValueKey(widget.index),
      onTap: _isEditing ? _toggleSwitch : null,
      child: Container(
        width: widget.isTablet ? 30 : 26,
        height: widget.isTablet ? 14 : 12,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: _isSwitchActive ? const Color(0xFF196E64) : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedAlign(
          duration: Duration(milliseconds: 200),
          alignment: _isSwitchActive ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: widget.isTablet ? 10 : 8,
            height: widget.isTablet ? 10 : 8,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeakerBadgeWithBorder(int number, Color borderColor, LanguageProvider languageProvider) {
    final fontSize = widget.isTablet ? 12.0 : 10.0;
    final horizontalPadding = widget.isTablet ? 8.0 : 6.0;
    final verticalPadding = widget.isTablet ? 4.0 : 2.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.white,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(4.0),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Text(
        '$number. ${languageProvider.getTranslation('speaker_badge')}',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1D1D1D),
          height: 1.037037037037037,
          fontFamily: 'brandontext',
        ),
      ),
    );
  }

  Widget _buildRightSection(Color borderColor, LanguageProvider languageProvider) {
    if (_isEditing) {
      return Container(
        width: widget.isTablet ? 120 : 0,
        height: widget.isTablet ? 143 : 0,
        margin: EdgeInsets.only(
            right: widget.isTablet ? 0 : 0
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                widget.onSave(
                  _departmentController.text,
                  _nameController.text,
                  _timeController.text,
                  _isSwitchActive,
                );
              },
              child: Container(
                width: widget.isTablet ? 90 : 0,
                height: widget.isTablet ? 42 : 0,
                decoration: BoxDecoration(
                  color: const Color(0xFF196E64),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF52596C),
                    width: 0.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    languageProvider.getTranslation('save_button'),
                    style: TextStyle(
                      fontSize: widget.isTablet ? 12 : 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      fontFamily: 'brandontext',
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: widget.isTablet ? 12 : 0),
            GestureDetector(
              onTap: widget.onCancel,
              child: Container(
                width: widget.isTablet ? 90 : 0,
                height: widget.isTablet ? 42 : 0,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF52596C),
                    width: 0.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    languageProvider.getTranslation('cancel_button'),
                    style: TextStyle(
                      fontSize: widget.isTablet ? 12 : 10,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1D1D1D),
                      fontFamily: 'brandontext',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: widget.isTablet ? 120 : 0,
      height: widget.isTablet ? 143 : 0,
      padding: EdgeInsets.only(
        right: widget.isTablet ? 12 : 0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: widget.onDelete,
                child: Container(
                  width: widget.isTablet ? 48 : 0,
                  height: widget.isTablet ? 48 : 0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF52596C),
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/delete.png',
                      width: widget.isTablet ? 18 : 16,
                      height: widget.isTablet ? 18 : 16,
                    ),
                  ),
                ),
              ),
              SizedBox(height: widget.isTablet ? 12 : 0),
              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: widget.isTablet ? 48 : 0,
                  height: widget.isTablet ? 48 : 0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF52596C),
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Image.asset(
                      _isPlaying
                          ? 'assets/images/pause.png'
                          : 'assets/images/play.png',
                      width: _isPlaying
                          ? (widget.isTablet ? 16 : 14)
                          : (widget.isTablet ? 28 : 24),
                      height: _isPlaying
                          ? (widget.isTablet ? 16 : 14)
                          : (widget.isTablet ? 28 : 24),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class EditableContentCard extends StatefulWidget {
  final Map<String, dynamic> content;
  final int index;
  final bool isTablet;
  final bool isPlaying;
  final bool isActive;
  final Function(String, String, String, bool) onSave;
  final VoidCallback onCancel;
  final VoidCallback onFilePick;
  final VoidCallback onDelete;
  final VoidCallback onPlayToggle;
  final Function(bool) onToggleChange;

  const EditableContentCard({
    Key? key,
    required this.content,
    required this.index,
    required this.isTablet,
    required this.isPlaying,
    required this.isActive,
    required this.onSave,
    required this.onCancel,
    required this.onFilePick,
    required this.onDelete,
    required this.onPlayToggle,
    required this.onToggleChange,
  }) : super(key: key);

  @override
  State<EditableContentCard> createState() => _EditableContentCardState();
}

class _EditableContentCardState extends State<EditableContentCard> {
  final BluetoothService _bluetooth = BluetoothService();
  late TextEditingController _titleController;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;
  FocusNode? _startTimeFocusNode;
  FocusNode? _endTimeFocusNode;
  late bool _isPlaying;
  late bool _isSwitchActive;
  String tip = "bilgi";

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.content['title'] as String);
    _startTimeController =
        TextEditingController(text: widget.content['startTime'] as String);
    _endTimeController =
        TextEditingController(text: widget.content['endTime'] as String);
    _startTimeFocusNode = FocusNode();
    _endTimeFocusNode = FocusNode();

    _isSwitchActive = widget.isActive;
    _isPlaying = widget.isPlaying;
    print(' index ${widget.index}');

    _startTimeFocusNode?.addListener(() {
      if (_startTimeFocusNode!.hasFocus &&
          _startTimeController.text.isNotEmpty) {
        _startTimeController.clear();
      }
    });

    _endTimeFocusNode?.addListener(() {
      if (_endTimeFocusNode!.hasFocus && _endTimeController.text.isNotEmpty) {
        _endTimeController.clear();
      }
    });

    _startTimeController.addListener(() {
      _formatTimeInput(_startTimeController);
    });

    _endTimeController.addListener(() {
      _formatTimeInput(_endTimeController);
    });
  }

  @override
  void didUpdateWidget(EditableContentCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isPlaying != oldWidget.isPlaying) {
      setState(() {
        _isPlaying = widget.isPlaying;
      });
    }
    if (widget.isActive != oldWidget.isActive) {
      setState(() {
        _isSwitchActive = widget.isActive;
      });
    }


    if (!widget.isPlaying && _isPlaying) {
      setState(() {
        _isPlaying = false;
      });
    }
  }

  Color _getBorderColor() {
    return widget.content['borderColor'] as Color? ?? const Color(0xFF5E6676);
  }

  bool get _isEditing => widget.content['isEditing'] as bool? ?? false;

  void _formatTimeInput(TextEditingController controller) {
    String text = controller.text.replaceAll(':', '');

    if (text.length > 6) {
      text = text.substring(0, 6);
    }

    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 2 || i == 4) {
        formatted += ':';
      }
      formatted += text[i];
    }

    if (formatted != controller.text) {
      controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _startTimeFocusNode?.dispose();
    _endTimeFocusNode?.dispose();
    super.dispose();
  }

  void _saveContent() {
    widget.onSave(
      _titleController.text,
      _startTimeController.text,
      _endTimeController.text,
      _isSwitchActive,
    );
  }

  void _togglePlay() {
    widget.onPlayToggle();
  }

  void _toggleSwitch() {
    setState(() {
      _isSwitchActive = !_isSwitchActive;
    });
    widget.onToggleChange(_isSwitchActive);
  }

  Widget _buildCharacterCounter(int currentLength) {
    var renk=Colors.grey[600];
    if(currentLength>59){
      renk=Colors.red[600];
    }
    else if(currentLength>49){
      renk=Colors.yellow[700];
    }
    else{
      renk=Colors.grey[600];
    }
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isTablet ? 5.0 : 4.0,
        vertical: widget.isTablet ? 2.5 : 2.0,
      ),
      decoration: BoxDecoration(
        color: renk,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$currentLength/70',
        style: TextStyle(
          fontSize: widget.isTablet ? 9.5 : 8.0,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          fontFamily: 'brandontext',
        ),
      ),
    );
  }

  Widget _buildFilePreview() {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    if (widget.content['thumbnail'] != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: FittedBox(
            fit: BoxFit.fitWidth,
            child: widget.content['thumbnail'] as Image,
          ),
        ),
      );
    }

    if (widget.content['file'] != null) {
      final file = widget.content['file'] as File;
      final fileType = widget.content['type'] as String;

      if (fileType == 'photo') {
        return ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.broken_image,
                  size: widget.isTablet ? 40 : 36,
                  color: Colors.grey[400],
                );
              },
            ),
          ),
        );
      }
      else if (fileType == 'video') {
        return ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.videocam,
                    size: widget.isTablet ? 36 : 32,
                    color: Colors.red,
                  ),
                  SizedBox(height: 6),
                  Text(
                    languageProvider.getTranslation('video_label'),
                    style: TextStyle(
                      fontSize: widget.isTablet ? 14 : 12,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'brandontext',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return Center(
      child: Transform.translate(
        offset: Offset(0, widget.isTablet ? -11 : -9),
        child: Image.asset(
          'assets/images/icerik-ekle.png',
          width: widget.isTablet ? 31 : 35,
          height: widget.isTablet ? 31 : 35,
          fit: BoxFit.contain,
        ),
      ),
    );

  }

  @override
  Widget build(BuildContext context) {
    final cardHeight = widget.isTablet ? 143.0 : 133.0;
    final borderColor = _getBorderColor();
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Container(
      margin: EdgeInsets.only(
        left: widget.isTablet ? 13 : 8,
        right: widget.isTablet ? 13 : 8,
        top: widget.isTablet ? (widget.index == 0 ? 20 : 0) : (widget.index == 0
            ? 15
            : 0),
        bottom: widget.isTablet ? 24 : 20,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            height: cardHeight,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: borderColor,
                width: 0.3,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildLeftSection(borderColor),
                ),
                if (widget.isTablet)
                  _buildRightSection(borderColor, languageProvider)
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
          Positioned(
            left: widget.isTablet ? 10.0 : 8.0,
            top: -10.0,
            child: _buildContentBadgeWithBorder(widget.index + 1, borderColor, languageProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftSection(Color borderColor) {
    return SizedBox(
      width: widget.isTablet ? 520.0 : double.infinity,
      height: widget.isTablet ? 143.0 : 133.0,
      child: Padding(
        padding: EdgeInsets.only(
          left: widget.isTablet ? 12.0 : 8.0,
          right: widget.isTablet ? 12.0 : 14.0,
          top: widget.isTablet ? 14.0 : 12.0,
          bottom: widget.isTablet ? 14.0 : 12.0,
        ),
        child: Row(
          children: [
            _isEditing
                ? GestureDetector(
              onTap: widget.onFilePick,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: widget.isTablet ? 90 : 80,
                  height: widget.isTablet ? 100 : 90,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: const Color(0xFFE0E0E0),
                      width: 0.5,
                    ),
                  ),
                  child: _buildFilePreview(),
                ),
              ),
            )
                : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: widget.isTablet ? 90 : 80,
                height: widget.isTablet ? 100 : 90,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: const Color(0xFFE0E0E0),
                    width: 0.5,
                  ),
                ),
                child: _buildFilePreview(),
              ),
            ),
            SizedBox(width: widget.isTablet ? 10.0 : 8.0),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImageIcon(
                        'assets/images/icerik.png',
                        widget.isTablet ? 18 : 16,
                        widget.isTablet ? 16 : 14,
                      ),
                      SizedBox(width: widget.isTablet ? 6.0 : 5.0),
                      Expanded(
                        child: _isEditing
                            ? TextField(
                          controller: _titleController,
                          maxLength: 70,
                          maxLines: 2,
                          onTap: () {
                            if (_titleController.text == widget.content['title']) {
                              _titleController.clear();
                            }
                          },
                          onChanged: (value) {
                            setState(() {});
                          },
                          style: TextStyle(
                            fontSize: widget.isTablet ? 17.0 : 15,
                            fontWeight: FontWeight.w400,
                            color: _titleController.text == widget.content['title']
                                ? Colors.grey[600]
                                : (borderColor == const Color(0xFF5E6676)
                                ? const Color(0xFF000000)
                                : const Color(0xFFA24D00)),
                            height: 0.94,
                            fontFamily: 'brandontext',
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            counterText: '',
                          ),
                        )
                            : Text(
                          widget.content['title'] as String,
                          style: TextStyle(
                            fontSize: widget.isTablet ? 17.0 : 15,
                            fontWeight: FontWeight.w400,
                            color: borderColor == const Color(0xFF5E6676)
                                ? const Color(0xFF414A5D)
                                : const Color(0xFFA24D00),
                            height: 0.94,
                            fontFamily: 'brandontext',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_isEditing) ...[
                        SizedBox(width: widget.isTablet ? 8.0 : 6.0),
                        _buildCharacterCounter(_titleController.text.length),
                      ],
                    ],
                  ),
                  SizedBox(height: widget.isTablet ? 40.0 : 36.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildImageIcon(
                            'assets/images/saat.png',
                            widget.isTablet ? 18 : 16,
                            widget.isTablet ? 20 : 18,
                          ),
                          SizedBox(width: widget.isTablet ? 4.0 : 2.0),
                          _buildDigitalTime(
                            widget.content['startTime'] as String,
                            borderColor == const Color(0xFF5E6676)
                                ? const Color(0xFF3B4458)
                                : const Color(0xFFA24D00),
                            widget.isTablet,
                            _isEditing,
                            _isEditing ? _startTimeController : null,
                            _isEditing ? _startTimeFocusNode : null,
                          ),
                          Text(
                            '-',
                            style: TextStyle(
                              fontSize: widget.isTablet ? 10.0 : 8.0,
                              fontWeight: FontWeight.w400,
                              color: borderColor == const Color(0xFF5E6676)
                                  ? const Color(0xFF3B4458)
                                  : const Color(0xFFA24D00),
                              fontFamily: 'digitalClock',
                            ),
                          ),
                          SizedBox(width: widget.isTablet ? 4.0 : 2.0),
                          _buildDigitalTime(
                            widget.content['endTime'] as String,
                            borderColor == const Color(0xFF5E6676)
                                ? const Color(0xFF3B4458)
                                : const Color(0xFFA24D00),
                            widget.isTablet,
                            _isEditing,
                            _isEditing ? _endTimeController : null,
                            _isEditing ? _endTimeFocusNode : null,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: widget.isTablet ? 18 : 16,
                            height: widget.isTablet ? 18 : 16,
                            margin: EdgeInsets.only(right: widget.isTablet ?
                            10.0 : 8.0),
                            child: Image.asset(
                              'assets/images/toggle-icon-1.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          _buildToggleSwitch(),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleSwitch() {
    return GestureDetector(
      onTap: _isEditing ? () async {
        setState(() {
          _isSwitchActive = !_isSwitchActive;
        });
        widget.onToggleChange(_isSwitchActive);
      } : null,
      child: Container(
        width: widget.isTablet ? 30 : 26,
        height: widget.isTablet ? 14 : 12,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: _isSwitchActive ? const Color(0xFF196E64) : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
          border: _isEditing ? null : Border.all(
            color: Colors.grey[400]!,
            width: 0.5,
          ),
        ),
        child: AnimatedAlign(
          duration: Duration(milliseconds: 200),
          alignment: _isSwitchActive ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: widget.isTablet ? 10 : 8,
            height: widget.isTablet ? 10 : 8,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: _isEditing ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ] : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDigitalTime(String time,
      Color textColor,
      bool isTablet,
      bool isEditing, [
        TextEditingController? controller,
        FocusNode? focusNode,
      ]) {
    if (isEditing && controller != null) {
      return SizedBox(
        width: isTablet ? 80.0 : 70.0,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          style: TextStyle(
            fontSize: isTablet ? 16.0 : 13,
            fontWeight: FontWeight.w400,
            fontFamily: 'digitalClock',
            color: textColor,
            height: 0.70,
            letterSpacing: 1.0,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < time.length; i++)
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: time[i] == ':' ? 1.5 : 0.5),
            child: Text(
              time[i],
              style: TextStyle(
                fontSize: isTablet ? 16.0 : 13,
                fontWeight: FontWeight.w500,
                fontFamily: 'digitalClock',
                color: textColor,
                height: 0.70,
                letterSpacing: 0,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageIcon(String imagePath, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Image.asset(
        imagePath,
        width: width * 0.7,
        height: height * 0.7,
        color: const Color(0xFF3C465A),
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildContentBadgeWithBorder(int number, Color borderColor, LanguageProvider languageProvider) {
    final fontSize = widget.isTablet ? 12.0 : 10.0;
    final horizontalPadding = widget.isTablet ? 8.0 : 6.0;
    final verticalPadding = widget.isTablet ? 4.0 : 2.0;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Text(
        '$number. ${languageProvider.getTranslation('content_badge')}',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1D1D1D),
          height: 1.037037037037037,
          fontFamily: 'brandontext',
        ),
      ),
    );
  }

  Widget _buildRightSection(Color borderColor, LanguageProvider languageProvider) {
    if (_isEditing) {
      return Container(
        width: widget.isTablet ? 120 : 0,
        height: widget.isTablet ? 143 : 0,
        margin: EdgeInsets.only(
            right: widget.isTablet ? 0 : 0
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _saveContent,
              child: Container(
                width: widget.isTablet ? 90 : 0,
                height: widget.isTablet ? 42 : 0,
                decoration: BoxDecoration(
                  color: const Color(0xFF196E64),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF52596C),
                    width: 0.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    languageProvider.getTranslation('save_button'),
                    style: TextStyle(
                      fontSize: widget.isTablet ? 12 : 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      fontFamily: 'brandontext',
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: widget.isTablet ? 12 : 0),
            GestureDetector(
              onTap: widget.onCancel,
              child: Container(
                width: widget.isTablet ? 90 : 0,
                height: widget.isTablet ? 42 : 0,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF52596C),
                    width: 0.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    languageProvider.getTranslation('cancel_button'),
                    style: TextStyle(
                      fontSize: widget.isTablet ? 12 : 10,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1D1D1D),
                      fontFamily: 'brandontext',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: widget.isTablet ? 120 : 0,
      height: widget.isTablet ? 143 : 0,
      padding: EdgeInsets.only(
        right: widget.isTablet ? 12 : 0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: widget.onDelete,
                child: Container(
                  width: widget.isTablet ? 48 : 0,
                  height: widget.isTablet ? 48 : 0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF52596C),
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/delete.png',
                      width: widget.isTablet ? 18 : 16,
                      height: widget.isTablet ? 18 : 16,
                    ),
                  ),
                ),
              ),
              SizedBox(height: widget.isTablet ? 12 : 0),
              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: widget.isTablet ? 48 : 0,
                  height: widget.isTablet ? 48 : 0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF52596C),
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Image.asset(
                      _isPlaying
                          ? 'assets/images/pause.png'
                          : 'assets/images/play.png',
                      width: _isPlaying
                          ? (widget.isTablet ? 16 : 14)
                          : (widget.isTablet ? 28 : 24),
                      height: _isPlaying
                          ? (widget.isTablet ? 16 : 14)
                          : (widget.isTablet ? 28 : 24),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}