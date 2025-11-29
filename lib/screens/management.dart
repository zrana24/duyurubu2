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

  @override
  void initState() {
    super.initState();
    _loadSharedData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_cachedData == null && !_isLoadingData && !_hasError) {
      _loadSharedData();
    }
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
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veri yüklenemedi: ${e.toString()}'),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Veri Yüklenemedi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadSharedData,
            child: Text('Tekrar Dene'),
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
                padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
                child: _isLoadingData
                    ? Center(child: CircularProgressIndicator())
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
          child: SpeakerManagement(cachedData: _cachedData),
        ),
        Expanded(
          flex: 1,
          child: ContentManagement(cachedData: _cachedData),
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
            child: SpeakerManagement(cachedData: _cachedData),
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
            child: ContentManagement(cachedData: _cachedData),
          ),
        ),
      ],
    );
  }
}

class SpeakerManagement extends StatefulWidget {
  final Map<String, dynamic>? cachedData;

  const SpeakerManagement({Key? key, this.cachedData}) : super(key: key);

  @override
  State<SpeakerManagement> createState() => _SpeakerManagementState();
}

class _SpeakerManagementState extends State<SpeakerManagement> {
  final BluetoothService _bluetoothService = BluetoothService();
  List<Map<String, dynamic>> _speakers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDataFromCache();
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
        }).toList();
        _isLoading = false;
      });
      print(_speakers);
    }
    else {
      setState(() => _isLoading = false);
    }
  }

  void _addNewSpeaker() {
    _showAddSpeakerDialog();
  }

  void _showAddSpeakerDialog() {
    String department = '';
    String name = '';
    String time = '';
    bool isLoading = false;
    bool toggleValue = false;
    bool buttonStatus = false;

    final timeController = TextEditingController(text: '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: 450,
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                  ),
                  child: AlertDialog(
                    insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    titlePadding: EdgeInsets.fromLTRB(24, 24, 24, 24),
                    contentPadding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                    actionsPadding: EdgeInsets.fromLTRB(24, 0, 24, 20),
                    content: SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 8),
                          TextField(
                            enabled: !isLoading,
                            decoration: InputDecoration(
                              labelText: 'Bölüm/Departman',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) => department = v,
                          ),
                          SizedBox(height: 20),
                          TextField(
                            enabled: !isLoading,
                            decoration: InputDecoration(
                              labelText: 'Ad Soyad',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) => name = v,
                          ),
                          SizedBox(height: 20),

                          TextField(
                            enabled: !isLoading,
                            controller: timeController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [TimeTextInputFormatter()],
                            decoration: InputDecoration(
                              labelText: '00:00:00',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              time = value;
                            },
                          ),
                          SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Aktif Durum', style: TextStyle(fontSize: 16)),
                              GestureDetector(
                                onTap: () {
                                  setDialogState(() {
                                    toggleValue = !toggleValue;
                                  });
                                },
                                child: Container(
                                  width: 50,
                                  height: 26,
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: toggleValue ? const Color(0xFF196E64) : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: AnimatedAlign(
                                    duration: Duration(milliseconds: 200),
                                    alignment: toggleValue ? Alignment.centerRight : Alignment.centerLeft,
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Aktif Buton', style: TextStyle(fontSize: 16)),
                              GestureDetector(
                                onTap: () {
                                  setDialogState(() {
                                    buttonStatus = !buttonStatus;
                                  });
                                },
                                child: Container(
                                  width: 50,
                                  height: 26,
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: buttonStatus ? const Color(0xFF196E64) : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: AnimatedAlign(
                                    duration: Duration(milliseconds: 200),
                                    alignment: buttonStatus ? Alignment.centerRight : Alignment.centerLeft,
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (isLoading)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(width: 16),
                                  Text('Bluetooth cihazına gönderiliyor...'),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () {
                          Navigator.of(context).pop();
                        },
                        child: Text('İptal'),
                      ),
                      ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                          if (department.isEmpty || name.isEmpty || time.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Lütfen tüm alanları doldurun'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          try {
                            await _bluetoothService.isimlikAdd(
                              name: name,
                              title: department,
                              togle: toggleValue,
                              isActive: buttonStatus,
                              time: time,
                            );

                            _saveNewSpeaker(department, name, time, toggleValue);

                            Navigator.of(context).pop();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Konuşmacı başarıyla eklendi'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Hata: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: Text('Ekle'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }


  void _saveNewSpeaker(String department, String name, String time, bool toggleValue) {
    setState(() {
      _speakers.add({
        'department': department.trim(),
        'name': name.trim(),
        'time': time,
        'isEditing': false,
        'isActive': toggleValue,
      });
    });
  }

  void _saveSpeaker(int index, String department, String name, String time) {
    if (department.trim().isEmpty || name.trim().isEmpty || time.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lütfen tüm alanları doldurun'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ));
      return;
    }

    if (time.replaceAll(':', '').length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Geçersiz zaman formatı'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Konuşmacı başarıyla güncellendi'),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
    ));

    setState(() {
      _speakers[index] = {
        'department': department.trim(),
        'name': name.trim(),
        'time': time,
        'isEditing': false,
        'isActive': _speakers[index]['isActive'] ?? false,
      };
    });
  }

  void _deleteSpeaker(int index) async {
    setState(() {
      _speakers.removeAt(index);
    });

    if (mounted) {
      final parentState = context.findAncestorStateOfType<_ManagementState>();
      await parentState?._loadSharedData();
    }
  }

  Color _getCardColor(int index) {
    List<Color> colors = [const Color(0xFF4CAF50), const Color(0xFFFF9800)];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;

    return Column(
      children: [
        Container(
          height: isTablet ? 59 : 50,
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
              horizontal: isTablet ? 13 : 10,
              vertical: isTablet ? 10 : 8,
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
                  'İSİMLİK EKRANI',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1D7269),
                    height: 0.7,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _addNewSpeaker,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 5 : 4,
                      vertical: isTablet ? 4 : 3,
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
                          'İSİM EKLE',
                          style: TextStyle(
                            fontSize: isTablet ? 13.5 : 11,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF0D7066),
                            height: 0.92,
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
                  'Konuşmacı bulunamadı',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            )
                : SingleChildScrollView(
              padding: EdgeInsets.only(top: isTablet ? 8 : 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int index = 0; index < _speakers.length; index++) ...[
                    EditableSpeakerCard(
                      speaker: _speakers[index],
                      index: index,
                      isTablet: isTablet,
                      onSave: (department, name, time) => _saveSpeaker(index, department, name, time),
                      onDelete: () => _deleteSpeaker(index),
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

  const ContentManagement({Key? key, this.cachedData}) : super(key: key);

  @override
  State<ContentManagement> createState() => _ContentManagementState();
}

class _ContentManagementState extends State<ContentManagement> {
  final BluetoothService _bluetoothService = BluetoothService();
  List<Map<String, dynamic>> _contents = [];
  final ImagePicker _picker = ImagePicker();
  bool _showExportSuccess = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDataFromCache();
  }

  void _loadDataFromCache() {
    if (widget.cachedData != null &&
        widget.cachedData!.containsKey('bilgi') &&
        widget.cachedData!['bilgi'] is List) {
      List<dynamic> bilgiList = widget.cachedData!['bilgi'];

      setState(() {
        _contents = bilgiList.map((item) {
          Image? thumbnail = item['thumbnailImage'];

          return {
            'title': item['meeting_title'] ?? '',
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
          };
        }).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _addNewContent() {
    setState(() {
      _contents.add({
        'title': 'Toplantı Konusu',
        'startTime': '00:00:00',
        'endTime': '00:00:00',
        'type': 'photo',
        'file': null,
        'isEditing': true,
        'isNew': true,
        'videoPath': null,
      });
    });
  }

  Future<void> _pickFile(int index) async {
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
                leading: const Icon(Icons.photo, size: 22),
                title: const Text('Fotoğraf Seç', style: TextStyle(fontSize: 14)),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() {
                      _contents[index]['file'] = File(image.path);
                      _contents[index]['type'] = 'photo';
                      _contents[index]['videoPath'] = image.path;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam, size: 22),
                title: const Text('Video Seç', style: TextStyle(fontSize: 14)),
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
                        'Video Gönderiliyor',
                        style: TextStyle(fontSize: 18),
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
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Boyut: $videoSizeMB MB',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
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
                              'Video Gönderildi!\nŞimdi bilgileri girin.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
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
                              'Gönderim İptal Edildi',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
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
                              content: Text('Video gönderimi iptal edildi'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      },
                      child: Text(
                        'İptal',
                        style: TextStyle(color: Colors.red),
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
                        'Tamam',
                        style: TextStyle(color: Colors.white),
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

        // ✅ Video yolu BluetoothService'den al
        String? serverVideoPath = _bluetoothService.receivedVideoPath;
        print(serverVideoPath);
        setState(() {
          _contents[index]['file'] = videoFile;
          _contents[index]['type'] = 'video';
          _contents[index]['videoPath'] = serverVideoPath;// Server'dan gelen
          // path
        });

        print('✅ Video path kaydedildi: ${_contents[index]['videoPath']}');

        // ✅ Path başarıyla alındığında kullanıcıya bildir
        if (serverVideoPath != null && serverVideoPath.isNotEmpty) {
          ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(
              content: Text('Video yolu alındı: $serverVideoPath'),
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
            content: Text('Video gönderilemedi: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    });
  }

  Future<void> _saveContent(int index, String title, String startTime, String endTime, bool isActive) async {
    if (title.trim().isEmpty || startTime.trim().isEmpty || endTime.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Lütfen tüm alanları doldurun'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ));
      return;
    }

    RegExp timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9])$');

    if (!timeRegex.hasMatch(startTime) || !timeRegex.hasMatch(endTime)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Geçersiz zaman formatı'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ));
      return;
    }

    try {
      // ✅ Video yolunu içerikten al
      String? videoPath = _contents[index]['videoPath'] as String?;

      // ✅ Eğer video yolu boşsa veya nullsa uyar
      if (videoPath == null || videoPath.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Video yolu bulunamadı. Lütfen önce video yükleyin.'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ));
        return;
      }

      print('📤 bilgiAdd çağrılıyor - path: $videoPath');

      // ✅ bilgiAdd fonksiyonuna gönder
      await _bluetoothService.bilgiAdd(
        meeting_title: title.trim(),
        start_hour: startTime,
        end_hour: endTime,
        path: videoPath,
        is_active: isActive,
        button_status: false,
      );

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('İçerik başarıyla eklendi ve cihaza gönderildi'),
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
        };
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Hata: ${e.toString()}'),
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

  void _deleteContent(int index) async {
    setState(() {
      _contents.removeAt(index);
    });

    if (mounted) {
      final parentState = context.findAncestorStateOfType<_ManagementState>();
      await parentState?._loadSharedData();
    }
  }

  void _exportToComputer() async {
    if (_contents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Aktarılacak içerik bulunamadı.'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ));
      return;
    }

    setState(() {
      _showExportSuccess = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _showExportSuccess = false;
    });

    try {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'İçerikleri Kaydet',
        fileName: 'toplanti_icerikleri_${DateTime.now().millisecondsSinceEpoch}.json',
      );

      if (outputFile != null) {
        final exportData = {
          'exportDate': DateTime.now().toIso8601String(),
          'contentCount': _contents.length,
          'contents': _contents,
        };
        print('İçerikler şu konuma kaydedildi: $outputFile');
      }
    } catch (e) {
      print('Aktarma hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;

    return Column(
      children: [
        Container(
          height: isTablet ? 59 : 50,
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
              horizontal: isTablet ? 13 : 10,
              vertical: isTablet ? 10 : 8,
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
                  'BİLGİ EKRANI',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1D7269),
                    height: 0.7,
                  ),
                ),
                const Spacer(),
                if (screenWidth > 400)
                  GestureDetector(
                    onTap: _exportToComputer,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 5 : 4,
                        vertical: isTablet ? 4 : 3,
                      ),
                      margin: EdgeInsets.only(right: isTablet ? 8 : 6),
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
                          if (screenWidth > 500)
                            Text(
                              'BİLGİSAYARA AKTAR',
                              style: TextStyle(
                                fontSize: isTablet ? 13.5 : 11,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF0D7066),
                                height: 0.92,
                              ),
                            ),
                          if (screenWidth > 500) SizedBox(width: isTablet ? 6 : 4),
                          Icon(
                            Icons.computer,
                            size: isTablet ? 16 : 13,
                            color: const Color(0xFF0D7066),
                          ),
                        ],
                      ),
                    ),
                  ),
                GestureDetector(
                  onTap: _addNewContent,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 5 : 4,
                      vertical: isTablet ? 4 : 3,
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
                            'İÇERİK EKLE',
                            style: TextStyle(
                              fontSize: isTablet ? 13.5 : 11,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF0D7066),
                              height: 0.92,
                            ),
                          ),
                        if (screenWidth > 400) SizedBox(width: isTablet ? 6 : 4),
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
                  'İçerik bulunamadı',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            )
                : SingleChildScrollView(
              padding: EdgeInsets.only(top: isTablet ? 8 : 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int index = 0; index < _contents.length; index++) ...[
                    EditableContentCard(
                      content: _contents[index],
                      index: index,
                      isTablet: isTablet,
                      onSave: (title, startTime, endTime, isActive) =>
                          _saveContent(index, title, startTime, endTime, isActive),
                      onCancel: () => _cancelEdit(index),
                      onDelete: () => _deleteContent(index),
                      onFilePick: () => _pickFile(index),
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
  final Function(String, String, String) onSave;
  final VoidCallback onDelete;
  final Function(bool) onToggleChange;

  const EditableSpeakerCard({
    Key? key,
    required this.speaker,
    required this.index,
    required this.isTablet,
    required this.onSave,
    required this.onDelete,
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
  bool _isPlaying = false;
  late bool _isSwitchActive;
  String tip="isimlik";

  @override
  void initState() {
    super.initState();
    _departmentController = TextEditingController(text: widget.speaker['department'] as String);
    _nameController = TextEditingController(text: widget.speaker['name'] as String);
    _timeController = TextEditingController(text: widget.speaker['time'] as String);
    _isSwitchActive = widget.speaker['isActive'] as bool? ?? false;
  }

  @override
  void dispose() {
    _departmentController.dispose();
    _nameController.dispose();
    _timeController.dispose();
    super.dispose();
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

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardHeight = widget.isTablet ? 143.0 : 133.0;
    final borderColor = _getBorderColor();

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
                    _buildRightSection(borderColor)
                  else
                    const SizedBox.shrink(),
                ],
              ),
            ),
            Positioned(
              left: widget.isTablet ? 28.0 : 20.0,
              top: -8.0,
              child: _buildSpeakerBadgeWithBorder(widget.index + 1, borderColor),
            ),
          ],
        )
    );
  }

  Widget _buildLeftSection(Color borderColor) {
    return SizedBox(
      width: widget.isTablet ? 520.0 : double.infinity,
      height: widget.isTablet ? 143.0 : 133.0,
      child: Padding(
        padding: EdgeInsets.only(
          left: widget.isTablet ? 24.0 : 14.0,
          right: widget.isTablet ? 24.0 : 14.0,
          top: widget.isTablet ? 18.0 : 16.0,
          bottom: widget.isTablet ? 14.0 : 12.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildImageIcon('assets/images/icerik.png', widget.isTablet ? 18 : 16, widget.isTablet ? 16 : 14),
                SizedBox(width: widget.isTablet ? 8.0 : 6.0),
                Expanded(
                  child: _isEditing
                      ? TextField(
                    controller: _departmentController,
                    style: TextStyle(
                      fontSize: widget.isTablet ? 17.0 : 15,
                      fontWeight: FontWeight.w400,
                      color: borderColor == const Color(0xFF5E6676)
                          ? const Color(0xFF414A5D)
                          : const Color(0xFFA24D00),
                      height: 0.94,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
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
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                _buildImageIcon('assets/images/konusmaci.png', widget.isTablet ? 18 : 16, widget.isTablet ? 20 : 18),
                SizedBox(width: widget.isTablet ? 8.0 : 6.0),
                Expanded(
                  child: _isEditing
                      ? TextField(
                    controller: _nameController,
                    style: TextStyle(
                      fontSize: widget.isTablet ? 17.0 : 15,
                      fontWeight: FontWeight.w400,
                      color: borderColor == const Color(0xFF5E6676)
                          ? const Color(0xFF414A5D)
                          : const Color(0xFFA24D00),
                      height: 0.94,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
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
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                _buildImageIcon('assets/images/saat.png', widget.isTablet ? 18 : 16, widget.isTablet ? 20 : 18),
                SizedBox(width: widget.isTablet ? 8.0 : 6.0),
                _buildDigitalTime(
                  widget.speaker['time'] as String,
                  borderColor == const Color(0xFF5E6676)
                      ? const Color(0xFF3B4458)
                      : const Color(0xFFA24D00),
                  widget.isTablet,
                  _isEditing,
                  _isEditing ? _timeController : null,
                ),
                if (!_isEditing) ...[
                  const Spacer(),
                  _buildToggleSwitch(),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDigitalTime(String time, Color textColor, bool isTablet, bool isEditing, [TextEditingController? controller]) {
    if (isEditing && controller != null) {
      return SizedBox(
        width: isTablet ? 120.0 : 110.0,
        child: TextField(
          controller: controller,
          style: TextStyle(
            fontSize: isTablet ? 16.0 : 14,
            fontWeight: FontWeight.w400,
            fontFamily: 'monospace',
            color: textColor,
            height: 0.70,
            letterSpacing: 2.5,
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
            padding: EdgeInsets.symmetric(horizontal: time[i] == ':' ? 2.0 : 1.0),
            child: Text(
              time[i],
              style: TextStyle(
                fontSize: isTablet ? 16.0 : 14,
                fontWeight: FontWeight.w400,
                fontFamily: 'monospace',
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
      onTap: () async {
        int id = widget.index;
        String tip = this.tip;
        bool isSwitchActive = this._isSwitchActive;

        print("toogle tıklandı $id $tip");

        await _bluetooth.toogle(id: id, tip: tip ,status:isSwitchActive);
        _toggleSwitch();
      },
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

  Widget _buildSpeakerBadgeWithBorder(int number, Color borderColor) {
    final fontSize = widget.isTablet ? 12.0 : 10.0;
    final verticalPadding = widget.isTablet ? 3.0 : 2.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isTablet ? 10 : 8,
        vertical: verticalPadding,
      ),
      child: Text(
        '$number. KONUŞMACI BİLGİSİ',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1D1D1D),
          height: 1.037037037037037,
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildRightSection(Color borderColor) {
    return Container(
      width: widget.isTablet ? 120 : 0,
      height: widget.isTablet ? 143 : 0,
      padding: EdgeInsets.symmetric(
        horizontal: widget.isTablet ? 4 : 0,
        vertical: widget.isTablet ? 10 : 0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () async {
                  int id = widget.index;
                  String tip = this.tip;

                  print("artı tıklandı $tip ve $id");

                  await _bluetooth.arti(id: id, tip: tip);
                },
                child: Container(
                  width: widget.isTablet ? 48 : 0,
                  height: widget.isTablet ? 57 : 0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEFF9),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                    border: Border.all(
                      color: const Color(0xFF52596C),
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.add,
                      size: widget.isTablet ? 18 : 16,
                      color: const Color(0xFF1D1D1D),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  int id = widget.index;
                  String tip = this.tip;

                  print("eksi tıklandı $tip ve $id");

                  await _bluetooth.eksi(id: id, tip: tip);
                },
                child: Container(
                  width: widget.isTablet ? 48 : 0,
                  height: widget.isTablet ? 57 : 0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEFF9),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                    border: Border.all(
                      color: const Color(0xFF52596C),
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.remove,
                      size: widget.isTablet ? 18 : 16,
                      color: const Color(0xFF1D1D1D),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: widget.isTablet ? 6 : 0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () async {
                  int id = widget.index;
                  String tip = this.tip;

                  print("delete tıklandı $tip ve $id");

                  await _bluetooth.delete(id: id, tip: tip);
                },
                child: Container(
                  width: widget.isTablet ? 48 : 0,
                  height: widget.isTablet ? 57 : 0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE5E5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF52596C),
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.close,
                      size: widget.isTablet ? 18 : 16,
                      color: Colors.red[900],
                    ),
                  ),
                ),
              ),
              SizedBox(height: widget.isTablet ? 2 : 0),
              GestureDetector(
                onTap: () async {
                  int id = widget.index;
                  String tip = this.tip;
                  bool _isPlaying = this._isPlaying;

                  print("play tıklandı $tip ve $id");

                  await _bluetooth.playStatus(id: id, tip: tip, isPlaying: _isPlaying);
                  _togglePlay();
                },
                child: Container(
                  width: widget.isTablet ? 48 : 0,
                  height: widget.isTablet ? 56 : 0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF52596C),
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      size: widget.isTablet ? 18 : 16,
                      color: const Color(0xFF1D1D1D),
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
  final Function(String, String, String, bool) onSave;
  final VoidCallback onCancel;
  final VoidCallback onFilePick;
  final VoidCallback onDelete;
  final Function(bool) onToggleChange;

  const EditableContentCard({
    Key? key,
    required this.content,
    required this.index,
    required this.isTablet,
    required this.onSave,
    required this.onCancel,
    required this.onFilePick,
    required this.onDelete,
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
  bool _isPlaying = false;
  late bool _isSwitchActive;
  String tip= "bilgi";

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.content['title'] as String);
    _startTimeController =
        TextEditingController(text: widget.content['startTime'] as String);
    _endTimeController =
        TextEditingController(text: widget.content['endTime'] as String);
    _isSwitchActive = widget.content['isActive'] as bool? ?? false;
  }

  Color _getBorderColor() {
    return widget.content['borderColor'] as Color? ?? const Color(0xFF5E6676);
  }

  bool get _isEditing => widget.content['isEditing'] as bool? ?? false;

  @override
  void dispose() {
    _titleController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
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
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _toggleSwitch() {
    setState(() {
      _isSwitchActive = !_isSwitchActive;
    });
    widget.onToggleChange(_isSwitchActive);
  }

  Widget _buildFilePreview() {
    if (widget.content['thumbnail'] != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: widget.content['thumbnail'] as Image,
      );
    }

    if (widget.content['file'] != null) {
      final file = widget.content['file'] as File;
      final fileType = widget.content['type'] as String;

      if (fileType == 'photo') {
        return ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.broken_image,
                size: widget.isTablet ? 28 : 26,
                color: Colors.grey[400],
              );
            },
          ),
        );
      } else if (fileType == 'video') {
        return Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.1),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam,
                  size: widget.isTablet ? 24 : 22,
                  color: Colors.red,
                ),
                SizedBox(height: 4),
                Text(
                  'Video',
                  style: TextStyle(
                    fontSize: widget.isTablet ? 10 : 8,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return Icon(
      Icons.image_outlined,
      size: widget.isTablet ? 28 : 26,
      color: Colors.grey[400],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardHeight = widget.isTablet ? 143.0 : 133.0;
    final borderColor = _getBorderColor();

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
                  _buildRightSection(borderColor)
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
          Positioned(
            left: widget.isTablet ? 28.0 : 20.0,
            top: -8.0,
            child: _buildContentBadgeWithBorder(widget.index + 1, borderColor),
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
          left: widget.isTablet ? 24.0 : 14.0,
          right: widget.isTablet ? 24.0 : 14.0,
          top: widget.isTablet ? 18.0 : 16.0,
          bottom: widget.isTablet ? 14.0 : 12.0,
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: widget.onFilePick,
              child: Container(
                width: widget.isTablet ? 60 : 55,
                height: widget.isTablet ? 80 : 75,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFE0E0E0),
                    width: 1,
                  ),
                ),
                child: _buildFilePreview(),
              ),
            ),
            SizedBox(width: widget.isTablet ? 10.0 : 8.0),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildImageIcon(
                          'assets/images/icerik.png', widget.isTablet ? 18 : 16,
                          widget.isTablet ? 16 : 14),
                      SizedBox(width: widget.isTablet ? 6.0 : 5.0),
                      Expanded(
                        child: _isEditing
                            ? TextField(
                          controller: _titleController,
                          style: TextStyle(
                            fontSize: widget.isTablet ? 17.0 : 15,
                            fontWeight: FontWeight.w400,
                            color: borderColor == const Color(0xFF5E6676)
                                ? const Color(0xFF414A5D)
                                : const Color(0xFFA24D00),
                            height: 0.94,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
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
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildImageIcon('assets/images/saat.png',
                              widget.isTablet ? 18 : 16,
                              widget.isTablet ? 20 : 18),
                          SizedBox(width: widget.isTablet ? 8.0 : 6.0),
                          _buildDigitalTime(
                            widget.content['startTime'] as String,
                            borderColor == const Color(0xFF5E6676)
                                ? const Color(0xFF3B4458)
                                : const Color(0xFFA24D00),
                            widget.isTablet,
                            _isEditing,
                            _isEditing ? _startTimeController : null,
                          ),
                        ],
                      ),
                      SizedBox(height: widget.isTablet ? 8.0 : 6.0),
                      Row(
                        children: [
                          SizedBox(width: widget.isTablet ? 24.0 : 22.0),
                          _buildDigitalTime(
                            widget.content['endTime'] as String,
                            borderColor == const Color(0xFF5E6676)
                                ? const Color(0xFF3B4458)
                                : const Color(0xFFA24D00),
                            widget.isTablet,
                            _isEditing,
                            _isEditing ? _endTimeController : null,
                          ),
                          const Spacer(),
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

  Widget _buildDigitalTime(String time,
      Color textColor,
      bool isTablet,
      bool isEditing, [
        TextEditingController? controller,
      ]) {
    if (isEditing && controller != null) {
      return SizedBox(
        width: isTablet ? 75.0 : 65.0,
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [TimeTextInputFormatter()],
          style: TextStyle(
            fontSize: isTablet ? 14.0 : 12,
            fontWeight: FontWeight.w400,
            fontFamily: 'monospace',
            color: textColor,
            height: 0.70,
            letterSpacing: 1.5,
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
                horizontal: time[i] == ':' ? 1.0 : 0.5),
            child: Text(
              time[i],
              style: TextStyle(
                fontSize: isTablet ? 14.0 : 12,
                fontWeight: FontWeight.w400,
                fontFamily: 'monospace',
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
      onTap: () async {
        int id = widget.index;
        String tip =this.tip ;
        bool isSwitchActive = this._isSwitchActive;

        print("toogle tıklandı $id $tip $_isSwitchActive");

        await _bluetooth.toogle(id: id, tip: tip ,status:isSwitchActive);
        _toggleSwitch();
      },
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
          alignment: _isSwitchActive ? Alignment.centerRight : Alignment
              .centerLeft,
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

  Widget _buildContentBadgeWithBorder(int number, Color borderColor) {
    final fontSize = widget.isTablet ? 12.0 : 10.0;
    final verticalPadding = widget.isTablet ? 3.0 : 2.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isTablet ? 10 : 8,
        vertical: verticalPadding,
      ),
      child: Text(
        '$number. İÇERİK',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1D1D1D),
          height: 1.037037037037037,
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildRightSection(Color borderColor) {
    if (_isEditing) {
      return Container(
        width: widget.isTablet ? 120 : 0,
        height: widget.isTablet ? 143 : 0,
        padding: EdgeInsets.symmetric(
          horizontal: widget.isTablet ? 8 : 0,
          vertical: widget.isTablet ? 10 : 0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _saveContent,
              child: Container(
                width: widget.isTablet ? 104 : 0,
                height: widget.isTablet ? 50 : 0,
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
                    'KAYDET',
                    style: TextStyle(
                      fontSize: widget.isTablet ? 14 : 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: widget.isTablet ? 8 : 0),
            GestureDetector(
              onTap: widget.onCancel,
              child: Container(
                width: widget.isTablet ? 104 : 0,
                height: widget.isTablet ? 50 : 0,
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
                    'İPTAL',
                    style: TextStyle(
                      fontSize: widget.isTablet ? 14 : 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1D1D1D),
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
      padding: EdgeInsets.symmetric(
        horizontal: widget.isTablet ? 4 : 0,
        vertical: widget.isTablet ? 10 : 0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
              key: ValueKey(widget.index),
                onTap: () async {
                  int id = widget.index;
                  String tip = this.tip;

                  print("artı tıklandı → id:$id tip:$tip");

                  await _bluetooth.arti(id: id, tip: tip);
                },
                child: Container(
                  width: widget.isTablet ? 48 : 0,
                  height: widget.isTablet ? 57 : 0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEFF9),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                    border: Border.all(
                      color: const Color(0xFF52596C),
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.add,
                      size: widget.isTablet ? 18 : 16,
                      color: const Color(0xFF1D1D1D),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  int id = widget.index;
                  String tip = this.tip;

                  print("eksi tıklandı → id:$id tip:$tip");

                  await _bluetooth.eksi(id: id, tip: tip);
                },
                child: Container(
                  width: widget.isTablet ? 48 : 0,
                  height: widget.isTablet ? 56 : 0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEFF9),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                    border: Border.all(
                      color: const Color(0xFF52596C),
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.remove,
                      size: widget.isTablet ? 18 : 16,
                      color: const Color(0xFF1D1D1D),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: widget.isTablet ? 6 : 0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () async {
                  int id = widget.index;
                  String tip = this.tip;

                  print("delete tıklandı → id:$id tip:$tip");

                  await _bluetooth.delete(id: id, tip: tip);
                },
                child: Container(
                  width: widget.isTablet ? 48 : 0,
                  height: widget.isTablet ? 57 : 0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE5E5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF52596C),
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.close,
                      size: widget.isTablet ? 18 : 16,
                      color: Colors.red[900],
                    ),
                  ),
                ),
              ),
              SizedBox(height: widget.isTablet ? 2 : 0),
              GestureDetector(
                onTap: () async {
                  int id = widget.index;
                  String tip = this.tip;
                  bool _isPlaying = this._isPlaying;

                  print("play tıklandı → id:$id tip:$tip");

                  await _bluetooth.playStatus(id: id, tip: tip, isPlaying:_isPlaying);
                  _togglePlay();
                },
                child: Container(
                  width: widget.isTablet ? 48 : 0,
                  height: widget.isTablet ? 56 : 0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF52596C),
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      size: widget.isTablet ? 18 : 16,
                      color: const Color(0xFF1D1D1D),
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