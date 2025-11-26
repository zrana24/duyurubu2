import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as blue_plus;
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart' as bluetooth_serial;
import 'package:permission_handler/permission_handler.dart';
import 'dart:core';
import 'dart:math' as math;

enum BluetoothServiceState {
  disconnected,
  connecting,
  connected,
  weakSignal,
  error,
}

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  blue_plus.BluetoothAdapterState _bluetoothState = blue_plus.BluetoothAdapterState.unknown;
  List<blue_plus.BluetoothDevice> _pairedDevicesList = [];
  List<blue_plus.ScanResult> _scanResults = [];

  BluetoothServiceState _connectionState = BluetoothServiceState.disconnected;
  blue_plus.BluetoothDevice? _connectedDevice;
  bool _isConnecting = false;
  bool _isScanning = false;
  bool _connectionLocked = false;


  Map<String, int?> _rssiValues = {};
  List<bluetooth_serial.BluetoothDevice> _bondedDevicesList = [];
  Map<String, String> _deviceNamesCache = {};


  List<Map<String, dynamic>> _isimlikList = [];


  final _bluetoothStateController = StreamController<blue_plus.BluetoothAdapterState>.broadcast();
  final _connectionStateController = StreamController<BluetoothServiceState>.broadcast();
  final _devicesController = StreamController<List<blue_plus.BluetoothDevice>>.broadcast();
  final _scanResultsController = StreamController<List<blue_plus.ScanResult>>.broadcast();


  final _notificationController = StreamController<Map<String, dynamic>>.broadcast();


  bluetooth_serial.BluetoothConnection? _connection;
  bool _isConnectionActive = false;
  StreamSubscription<Uint8List>? _dataSubscription;
  final _incomingDataController = StreamController<String>.broadcast();


  String? receivedVideoPath;


  blue_plus.BluetoothAdapterState get bluetoothState => _bluetoothState;
  List<blue_plus.BluetoothDevice> get pairedDevices => _pairedDevicesList;
  List<blue_plus.BluetoothDevice> get nearbyDevices => _scanResults.map((r) => r.device).toList();
  BluetoothServiceState get connectionState => _connectionState;
  blue_plus.BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnecting => _isConnecting;
  bool get isScanning => _isScanning;
  bool get isConnected => _connectedDevice != null && !_isConnecting && _isConnectionActive;
  Map<String, int?> get rssiValues => _rssiValues;
  List<Map<String, dynamic>> get isimlikList => _isimlikList;

  List<String> get connectedDevicesMacAddresses {
    return _pairedDevicesList
        .where((device) => device.isConnected)
        .map((device) => device.remoteId.str)
        .toList();
  }

  static String? _connectedDeviceMacAddress;

  static String? get connectedDeviceMacAddress => _connectedDeviceMacAddress;

  static set connectedDeviceMacAddress(String? macAddress) {
    _connectedDeviceMacAddress = macAddress;
  }


  Stream<blue_plus.BluetoothAdapterState> get bluetoothStateStream => _bluetoothStateController.stream;
  Stream<BluetoothServiceState> get connectionStateStream => _connectionStateController.stream;
  Stream<List<blue_plus.BluetoothDevice>> get devicesStream => _devicesController.stream;
  Stream<List<blue_plus.ScanResult>> get scanResultsStream => _scanResultsController.stream;
  Stream<String> get incomingDataStream => _incomingDataController.stream;


  Stream<Map<String, dynamic>> get notificationStream => _notificationController.stream;

  StreamSubscription<List<blue_plus.ScanResult>>? _scanSubscription;
  StreamSubscription<blue_plus.BluetoothConnectionState>? _connectionSubscription;
  Timer? _continuousScanTimer;


  void _sendNotification(String message, String type) {
    _notificationController.add({
      'message': message,
      'type': type,
      'timestamp': DateTime.now(),
    });
    print('📢 Bildirim: $message [$type]');
  }

  Future<bool> requestPermissions() async {
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();

      return statuses.values.every((status) => status.isGranted);
    } catch (e) {
      print('❌ İzin hatası: $e');
      return false;
    }
  }


  Future<void> initializeBluetooth() async {
    try {
      bool hasPermissions = await requestPermissions();
      if (!hasPermissions) {
        print('❌ Bluetooth izinleri gerekli');
        _sendNotification('❌ Bluetooth izinleri gerekli', 'error');
        return;
      }

      blue_plus.FlutterBluePlus.adapterState.listen((state) async {
        _bluetoothState = state;
        _bluetoothStateController.add(state);

        if (state == blue_plus.BluetoothAdapterState.on) {
          await _getBondedDevices();
          await _getPairedDevices();
          _startContinuousScanning();
        } else {
          _stopScan();
          _updateConnectionState(BluetoothServiceState.disconnected);
        }
      });

      final initialState = await blue_plus.FlutterBluePlus.adapterState.first;
      _bluetoothState = initialState;
      _bluetoothStateController.add(initialState);

      if (_bluetoothState == blue_plus.BluetoothAdapterState.on) {
        await _getBondedDevices();
        await _getPairedDevices();
        _startContinuousScanning();
      }
    } catch (e) {
      print('❌ Bluetooth başlatma hatası: $e');
      _sendNotification('❌ Bluetooth başlatma hatası', 'error');
    }
  }


  Future<void> _getBondedDevices() async {
    try {
      List<bluetooth_serial.BluetoothDevice> bondedDevices = await bluetooth_serial.FlutterBluetoothSerial.instance.getBondedDevices();

      _bondedDevicesList = bondedDevices;

      for (var bondedDevice in _bondedDevicesList) {
        try {
          blue_plus.BluetoothDevice device = blue_plus.BluetoothDevice.fromId(bondedDevice.address);

          if (!_pairedDevicesList.any((d) => d.remoteId.str == bondedDevice.address)) {
            _pairedDevicesList.add(device);
          }

          if (bondedDevice.name != null && bondedDevice.name!.isNotEmpty) {
            _deviceNamesCache[bondedDevice.address] = bondedDevice.name!;
          }
        } catch (e) {
          print('❌ Cihaz ekleme hatası: $e');
        }
      }

      _devicesController.add(_pairedDevicesList);
    } catch (e) {
      print('❌ Eşleşmiş cihazlar alınamadı: $e');
    }
  }


  Future<void> _getPairedDevices() async {
    try {
      List<blue_plus.BluetoothDevice> connectedDevices = await blue_plus.FlutterBluePlus.connectedDevices;

      for (var device in connectedDevices) {
        if (!_pairedDevicesList.any((d) => d.remoteId == device.remoteId)) {
          _pairedDevicesList.add(device);
        }

        String deviceId = device.remoteId.str;
        if (device.platformName.isNotEmpty && !_deviceNamesCache.containsKey(deviceId)) {
          _deviceNamesCache[deviceId] = device.platformName;
        }
      }

      _devicesController.add(_pairedDevicesList);
    } catch (e) {
      print('❌ Bağlı cihazlar alınamadı: $e');
    }
  }


  void _startContinuousScanning() {
    _continuousScanTimer?.cancel();
    _continuousScanTimer = Timer.periodic(Duration(seconds: 30), (_) async {
      if (_bluetoothState != blue_plus.BluetoothAdapterState.on || _isConnecting) return;

      if (!_isScanning) {
        startScan();
        Future.delayed(Duration(seconds: 10), _stopScan);
      }
    });
  }


  void startScan() {
    if (_isScanning || _bluetoothState != blue_plus.BluetoothAdapterState.on || _isConnecting) {
      return;
    }

    _isScanning = true;
    _scanResults.clear();

    _scanSubscription?.cancel();
    _scanSubscription = blue_plus.FlutterBluePlus.scanResults.listen((results) {
      for (blue_plus.ScanResult result in results) {
        final index = _scanResults.indexWhere((r) => r.device.remoteId == result.device.remoteId);
        if (index >= 0) {
          _scanResults[index] = result;
        } else {
          _scanResults.add(result);
        }
        _rssiValues[result.device.remoteId.str] = result.rssi;

        String deviceId = result.device.remoteId.str;
        String advName = result.advertisementData.advName;
        if (advName.isNotEmpty && !_deviceNamesCache.containsKey(deviceId)) {
          _deviceNamesCache[deviceId] = advName;
        }
      }
      _scanResultsController.add(_scanResults);
    }, onError: (error) {
      print('❌ Tarama hatası: $error');
      _isScanning = false;
    });

    blue_plus.FlutterBluePlus.startScan(
      timeout: Duration(seconds: 10),
      androidUsesFineLocation: false,
    );
  }

  void _stopScan() {
    if (_isScanning) {
      blue_plus.FlutterBluePlus.stopScan();
      _scanSubscription?.cancel();
      _isScanning = false;
    }
  }


  String getDeviceDisplayName(blue_plus.BluetoothDevice device) {
    String deviceId = device.remoteId.str;

    if (_deviceNamesCache.containsKey(deviceId)) {
      return _deviceNamesCache[deviceId]!;
    }

    for (var bondedDevice in _bondedDevicesList) {
      if (bondedDevice.address == deviceId) {
        if (bondedDevice.name != null && bondedDevice.name!.isNotEmpty) {
          return bondedDevice.name!;
        }
      }
    }

    if (device.platformName.isNotEmpty) {
      return device.platformName;
    }

    try {
      final existingResult = _scanResults.firstWhere((r) => r.device.remoteId.str == deviceId);
      if (existingResult.advertisementData.advName.isNotEmpty) {
        return existingResult.advertisementData.advName;
      }
    } catch (e) {

    }

    return deviceId.length > 8 ? '${deviceId.substring(0, 8)}...' : deviceId;
  }


  Future<void> connectToDevice(blue_plus.BluetoothDevice device, {int maxRetries = 3}) async {
    if (_isConnecting) {
      print('⏳ Bağlantı zaten devam ediyor');
      return;
    }

    if (_connectionLocked) {
      print('🔒 Bağlantı kilitli! Önce bağlantıyı kesin');
      return;
    }

    _isConnecting = true;
    _updateConnectionState(BluetoothServiceState.connecting);
    String deviceName = getDeviceDisplayName(device);

    int retryCount = 0;
    Exception? lastException;

    while (retryCount <= maxRetries) {
      try {
        if (retryCount > 0) {
          print('🔄 Tekrar deneme $retryCount/$maxRetries: $deviceName');
          int delayMs = (1000 * (1 << (retryCount - 1))).clamp(1000, 4000);
          await Future.delayed(Duration(milliseconds: delayMs));
        } else {
          print('🔗 $deviceName cihazına bağlanılıyor...');
        }


        try {
          await device.disconnect();
          await Future.delayed(Duration(milliseconds: 1000));
        } catch (e) {
          print('⚠️ Disconnect hatası (göz ardı ediliyor): $e');
          await Future.delayed(Duration(milliseconds: 1000));
        }


        final adapterState = await blue_plus.FlutterBluePlus.adapterState.first;
        if (adapterState != blue_plus.BluetoothAdapterState.on) {
          throw Exception('Bluetooth adaptörü kapalı');
        }


        final currentConnectionState = await device.connectionState.first;
        if (currentConnectionState == blue_plus.BluetoothConnectionState.connected) {
          print('✅ Cihaz zaten bağlı');
          _connectedDevice = device;
          _connectionLocked = true;
          _isConnecting = false;
          _updateConnectionState(BluetoothServiceState.connected);
          _stopScan();
          _monitorConnectionState(device);


          await connectToCsServer(device.remoteId.str);
          return;
        }


        await device.connect(autoConnect: false, timeout: Duration(seconds: 15)).timeout(
          Duration(seconds: 20),
          onTimeout: () {
            throw TimeoutException('Bağlantı zaman aşımına uğradı', Duration(seconds: 20));
          },
        );


        await Future.delayed(Duration(milliseconds: 1000));
        final connectionState = await device.connectionState.first;

        if (connectionState != blue_plus.BluetoothConnectionState.connected) {
          throw Exception('Bağlantı kurulamadı. Durum: $connectionState');
        }


        await discoverServicesAfterConnection(device);


        _connectedDevice = device;
        _connectionLocked = true;
        _isConnecting = false;
        _updateConnectionState(BluetoothServiceState.connected);

        if (!_pairedDevicesList.any((d) => d.remoteId == device.remoteId)) {
          _pairedDevicesList.add(device);
          _devicesController.add(_pairedDevicesList);
        }

        _stopScan();
        _monitorConnectionState(device);

        connectedDeviceMacAddress = device.remoteId.str;
        await connectToCsServer(device.remoteId.str);

        print('✅ Bağlandı: $deviceName');
        return;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        String errorString = e.toString();
        bool isError133 = errorString.contains('133') ||
            errorString.contains('ANDROID_SPECIFIC_ERROR') ||
            errorString.contains('GATT');

        print('❌ Deneme ${retryCount + 1} başarısız: $deviceName - $e');

        if (isError133 && retryCount < maxRetries) {
          print('⚠️ Error 133 tespit edildi, ek bekleme...');
          await Future.delayed(Duration(seconds: 2));
        }

        if (retryCount < maxRetries) {
          retryCount++;
          try {
            await device.disconnect();
            await Future.delayed(Duration(milliseconds: 1000));
          } catch (_) {}
          continue;
        } else {
          break;
        }
      }
    }

    _isConnecting = false;
    _updateConnectionState(BluetoothServiceState.error);

    try {
      await device.disconnect();
    } catch (_) {}

    if (lastException != null) {
      throw lastException;
    } else {
      throw Exception('Bağlantı kurulamadı (${maxRetries + 1} deneme)');
    }
  }

  Image imageFromBase64(String base64Str) {
    try {
      // Base64 string'i temizle
      base64Str = base64Str.trim();

      // Data URL formatındaysa (data:image/...), sadece base64 kısmını al
      if (base64Str.contains(',')) {
        base64Str = base64Str.split(',').last;
      }

      // Base64 decode et
      Uint8List bytes = base64Decode(base64Str);

      // Image widget'ını oluştur
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Image memory hatası: $error');
          return Icon(Icons.broken_image, color: Colors.grey);
        },
      );
    } catch (e) {
      print('❌ imageFromBase64 hatası: $e');
      print('❌ Hatalı base64 string: ${base64Str.substring(0, math.min(100,
          base64Str.length))}');
      rethrow;
    }
  }

  Stream<Uint8List>? _connectionInputStream;

  Future<void> connectToCsServer(String address) async {
    if (_isConnectionActive && _connection != null && _connection!.isConnected) {
      print('✅ Serial bağlantı zaten aktif');
      return;
    }

    try {
      await Future.delayed(Duration(milliseconds: 500));

      print('📡 Serial bağlantı kuruluyor: $address');
      _connection = await bluetooth_serial.BluetoothConnection.toAddress(address);
      _connectionInputStream ??= _connection!.input!.asBroadcastStream();

      if (_connection == null) {
        throw Exception('Bağlantı nesnesi null');
      }

      _isConnectionActive = true;
      print('✅ Serial bağlantı kuruldu: $address');



      String deviceName = _connectedDevice != null
          ? getDeviceDisplayName(_connectedDevice!)
          : 'Cihaz';
      _sendNotification('✅ $deviceName ile seri bağlantı kuruldu', 'success');

      await Future.delayed(Duration(milliseconds: 500));

    } catch (e) {
      print('❌ Serial bağlantı hatası: $e');
      _isConnectionActive = false;
      _connection = null;


      _sendNotification('❌ Seri bağlantı kurulamadı', 'error');
      rethrow;
    }
  }


  Future<void> _closeSerialConnection() async {
    try {
      if (_dataSubscription != null) {
        await _dataSubscription!.cancel();
        _dataSubscription = null;
      }

      if (_connection != null) {
        try {
          if (_connection!.isConnected) {
            await _connection!.close();
          }
          _connection!.dispose();
        } catch (e) {
          print('⚠️ Connection dispose hatası: $e');
        }
        _connection = null;
      }

      _isConnectionActive = false;
      print('🔌 Serial bağlantı kapatıldı');

      await Future.delayed(Duration(milliseconds: 300));
    } catch (e) {
      print('⚠️ Serial bağlantı kapatma hatası: $e');
      _connection = null;
      _isConnectionActive = false;
    }
  }

  Future<void> discoverServicesAfterConnection(blue_plus.BluetoothDevice device) async {
    try {
      await Future.delayed(Duration(milliseconds: 500));
      await device.discoverServices();
    } catch (e) {
      print('⚠️ Hizmet keşfi hatası: $e');
    }
  }

  void _monitorConnectionState(blue_plus.BluetoothDevice device) {
    _connectionSubscription?.cancel();
    _connectionSubscription = device.connectionState.listen((state) {
      if (state == blue_plus.BluetoothConnectionState.disconnected) {
        print('❌ Bağlantı koptu');
        _handleDisconnection();
      }
    });
  }

  Future<bool> isConnectedToDevice() async {
    if (_connectedDevice == null) {
      return false;
    }

    try {
      List<blue_plus.BluetoothDevice> connectedDevices = await blue_plus.FlutterBluePlus.connectedDevices;
      bool isStillConnected = connectedDevices.any((d) => d.remoteId == _connectedDevice!.remoteId);

      if (!isStillConnected) {
        _handleDisconnection();
        return false;
      }

      return true;
    } catch (e) {
      print('❌ Bağlantı kontrol hatası: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      try {
        String deviceName = getDeviceDisplayName(_connectedDevice!);
        await _connectedDevice!.disconnect();
        print('✅ Bağlantı kesildi: $deviceName');
      } catch (e) {
        print('❌ Bağlantı kesme hatası: $e');
      }
    }
    _handleDisconnection();
  }

  void _handleDisconnection() {
    String? disconnectedDeviceName;
    if (_connectedDevice != null) {
      disconnectedDeviceName = getDeviceDisplayName(_connectedDevice!);
      print('🔌 Bağlantı kesildi: $disconnectedDeviceName');
    }

    _connectedDevice = null;
    _connectionLocked = false;
    _isConnecting = false;
    _connectionSubscription?.cancel();

    _closeSerialConnection();
    _updateConnectionState(BluetoothServiceState.disconnected);



    if (_bluetoothState == blue_plus.BluetoothAdapterState.on) {
      _startContinuousScanning();
    }
  }

  void _updateConnectionState(BluetoothServiceState state) {
    _connectionState = state;
    _connectionStateController.add(state);
  }

  /*void _handleIncomingData(String message) {
    try {
      Map<String, dynamic> jsonData = jsonDecode(message);
      print('📊 JSON verisi alındı: $jsonData');

      if (jsonData.containsKey('path')) {
        receivedVideoPath = jsonData['path'];
        print('✅ Path kaydedildi: $receivedVideoPath');
      }

      if (jsonData['status'] == 'ok') {
        print('✅ İşlem başarılı');
      }
    } catch (e) {
      print('⚠️ JSON parse hatası, regex deneniyor: $e');

      try {
        RegExp pathRegex = RegExp(r'"path"\s*:\s*"([^"]+)"');
        Match? match = pathRegex.firstMatch(message);
        if (match != null) {
          receivedVideoPath = match.group(1);
          print('✅ Path regex ile alındı: $receivedVideoPath');
        }
      } catch (regexError) {
        print('❌ Regex hatası: $regexError');
      }
    }
  }*/

  Future<void> sendDataToDevice(String macAddress, Map<String, dynamic> data) async {
    try {
      if (!_isConnectionActive || _connection == null || !_connection!.isConnected) {
        print('⚠️ Bağlantı aktif değil, yeniden kuruluyor...');
        await connectToCsServer(macAddress);
      }

      String jsonData = jsonEncode(data);
      print(jsonData);
      _connection!.output.add(utf8.encode(jsonData + "\r\n"));
      await _connection!.output.allSent;
      print('✅ Veri başarıyla gönderildi: $jsonData');

      await Future.delayed(Duration(milliseconds: 100));
    }
    catch (e) {
      print('❌ Veri gönderme hatası: $e');
      _isConnectionActive = false;
      _sendNotification('❌ Veri gönderilemedi', 'error');
      throw e;
    }
  }

  Future<void> isimlikAdd({
    required String name,
    required String title,
    required bool togle,
    required bool isActive,
    required String time,
  }) async {
    try {
      Map<String, dynamic> data = {
        "type": "isimlik_add",
        "title": title.trim(),
        "name": name.trim(),
        "togle": togle,
        "is_active": isActive,
        "time": time.trim()
      };

      await sendDataToDevice(connectedDeviceMacAddress!, data);
      print('İsimlik eklendi');
      _sendNotification('✅ İsimlik başarıyla eklendi', 'success');
    } catch (e) {
      print('İsimlik ekleme hatası: $e');
      _sendNotification('❌ İsimlik eklenemedi', 'error');
      rethrow;
    }
  }

  Future<void> videosend({
    required String size,
    required String name,
    required String videoPath,
    Function(double)? onProgress,
  }) async {
    try {
      if (!_isConnectionActive || _connection == null || !_connection!.isConnected) {
        print("Video göndermek için bağlantı kuruluyor...");
        await connectToCsServer(connectedDeviceMacAddress!);
        await Future.delayed(Duration(milliseconds: 1000));
      }

      File videoFile = File(videoPath);
      if (!videoFile.existsSync()) {
        throw Exception("Video dosyası bulunamadı: $videoPath");
      }

      Uint8List fileBytes = await videoFile.readAsBytes();
      int totalBytes = fileBytes.length;


      Map<String, dynamic> data = {
        "type": "video",
        "size": totalBytes,
        "name": name
      };

      print("📦 Video bilgileri gönderiliyor: $data");
      String jsonData = jsonEncode(data);


      _connection!.output.add(utf8.encode(jsonData + "\r\n"));
      await _connection!.output.allSent;


      print("⏳ C# hazırlanıyor...");
      await Future.delayed(Duration(milliseconds: 1500));


      if (!_connection!.isConnected) {
        print("⚠️ Metadata gönderimi sonrası bağlantı koptu, yeniden bağlanılıyor...");
        await connectToCsServer(connectedDeviceMacAddress!);
        await Future.delayed(Duration(milliseconds: 1000));
      }

      print("📤 Video gönderimi başlıyor...");
      print("📏 Toplam Boyut: ${(totalBytes / 1024 / 1024).toStringAsFixed(2)} MB");

      _sendNotification('📤 Video gönderimi başladı: $name', 'info');

      int offset = 0;
      int chunkSize = 1024;
      int lastProgressUpdate = 0;
      DateTime startTime = DateTime.now();
      int consecutiveErrors = 0;
      const int maxConsecutiveErrors = 3;

      while (offset < totalBytes) {

        if (!_connection!.isConnected) {
          print("⚠️ Bağlantı koptu (offset: $offset), yeniden bağlanılıyor...");

          try {
            await connectToCsServer(connectedDeviceMacAddress!);
            await Future.delayed(Duration(milliseconds: 1500));
            consecutiveErrors = 0;
          } catch (e) {
            consecutiveErrors++;
            if (consecutiveErrors >= maxConsecutiveErrors) {
              _sendNotification('❌ Video gönderilemedi - bağlantı hatası', 'error');
              throw Exception("❌ Bağlantı ${maxConsecutiveErrors} kez yeniden kurulamadı!");
            }
            print("⚠️ Yeniden bağlanma denemesi ${consecutiveErrors}/${maxConsecutiveErrors}");
            await Future.delayed(Duration(seconds: 2));
            continue;
          }
        }

        int bytesToSend = (offset + chunkSize > totalBytes)
            ? totalBytes - offset
            : chunkSize;

        Uint8List chunk = fileBytes.sublist(offset, offset + bytesToSend);

        try {
          _connection!.output.add(chunk);
          await _connection!.output.allSent;
          await Future.delayed(Duration(milliseconds: 5));
          consecutiveErrors = 0;

        } catch (e) {
          print("❌ Chunk gönderme hatası (offset: $offset): $e");
          consecutiveErrors++;

          if (consecutiveErrors >= maxConsecutiveErrors) {
            _sendNotification('❌ Video gönderimi iptal edildi', 'error');
            throw Exception("❌ ${maxConsecutiveErrors} ardışık hata, aktarım iptal edildi");
          }
          try {
            print("🔄 Bağlantı yeniden kuruluyor (deneme ${consecutiveErrors})...");
            await connectToCsServer(connectedDeviceMacAddress!);
            await Future.delayed(Duration(milliseconds: 1500));

            _connection!.output.add(chunk);
            await _connection!.output.allSent;
            await Future.delayed(Duration(milliseconds: 5));

            consecutiveErrors = 0;
          } catch (retryError) {
            print("❌ Yeniden deneme başarısız: $retryError");
            await Future.delayed(Duration(milliseconds: 500));
            continue;
          }
        }

        offset += bytesToSend;
        double percent = offset / totalBytes * 100;

        int currentProgress = (percent / 5).floor();
        if (currentProgress > lastProgressUpdate || offset == totalBytes) {
          lastProgressUpdate = currentProgress;

          Duration elapsed = DateTime.now().difference(startTime);
          double speed = elapsed.inSeconds > 0
              ? (offset / 1024 / 1024) / elapsed.inSeconds
              : 0;

          print("📤 ${percent.toStringAsFixed(1)}% (${(offset / 1024 / 1024).toStringAsFixed(2)} MB) - ${speed.toStringAsFixed(2)} MB/s");

          if (onProgress != null) {
            onProgress(percent);
          }
        }
      }

      Duration totalTime = DateTime.now().difference(startTime);
      double avgSpeed = totalTime.inSeconds > 0
          ? (totalBytes / 1024 / 1024) / totalTime.inSeconds
          : 0;

      print("\n✅ Video tamamen gönderildi: $name");




      final completer = Completer<void>();

      _dataSubscription = _connectionInputStream!.listen(
            (Uint8List packet) {
          String msg = String.fromCharCodes(packet).trim();
          print("📥 Gelen mesaj: $msg");

          try {
            Map<String, dynamic> response = jsonDecode(msg);

            if (response.containsKey('path')) {
              receivedVideoPath = response['path'];
              print('🎉 PATH ALINDI: $receivedVideoPath');

              _dataSubscription?.cancel();
              _dataSubscription = null;

              if (!completer.isCompleted) {
                completer.complete();
              }
            }
          } catch (_) {}
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        onError: (_) {
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        cancelOnError: true,
      );

      // 🔥 Path gelene kadar bekle
      await completer.future;

      /// -----------------------------------------------------

      print("✔✔✔ SON PATH: $receivedVideoPath");








      print("📊 ${(totalBytes / 1024 / 1024).toStringAsFixed(2)} MB - Süre: ${totalTime.inSeconds}s - Ort. Hız: ${avgSpeed.toStringAsFixed(2)} MB/s");

      _sendNotification('✅ Video başarıyla gönderildi: $name', 'success');

       //_waitForServerResponse();
       print("çalıştım knk $receivedVideoPath");

    } catch (e, stackTrace) {
      print("❌ Video gönderme hatası: $e");
      print("StackTrace:\n$stackTrace");
      _sendNotification('❌ Video gönderilemedi', 'error');
      rethrow;
    }
  }







  Future<void> _waitForServerResponse() async {
    final completer = Completer<void>();
    StreamSubscription<String>? responseSubscription;



    responseSubscription = _incomingDataController.stream.listen((message) {
      try {

      } catch (e) {
        print('⚠️ Yanıt parse hatası: $e');
      }


      responseSubscription?.cancel();
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    await completer.future;
  }

  /*Future<void> photoSend({
    required String imagePath,
    required String imageName,
  }) async {
    try {
      print('Fotoğraf gönderiliyor: $imageName, yol: $imagePath');
      receivedVideoPath=imagePath;
      _sendNotification('✅ Fotoğraf hazırlandı: $imageName', 'success');
    } catch (e) {
      print('Fotoğraf gönderme hatası: $e');
      _sendNotification('❌ Fotoğraf gönderilemedi', 'error');
      rethrow;
    }
  }*/

  Future<void> bilgiAdd({
    required String meeting_title,
    required String start_hour,
    required String end_hour,
    required String path,
    required bool is_active,
    required bool button_status,
  }) async {
    try {
      Map<String, dynamic> data = {
        "type": "bilgi_add",
        "meeting_title": meeting_title,
        "start_hour": start_hour,
        "end_hour": end_hour,
        "path": path,
        "is_active": is_active,
        "button_status": button_status
      };

      await sendDataToDevice(connectedDeviceMacAddress!, data);
      print("Bilgi başarıyla eklendi");
      _sendNotification('✅ Bilgi başarıyla eklendi', 'success');
    } catch (e) {
      print("Bilgi ekleme hatası: $e");
      _sendNotification('❌ Bilgi eklenemedi', 'error');
      rethrow;
    }
  }

  bool _veriIsRunning = false;

  Future<String> veri() async {
    if (_veriIsRunning) {
      print("⚠️ veri() zaten çalışıyor, yeni çağrı iptal edildi.");
      return "";
    }

    _veriIsRunning = true;
    try {
      if (!_isConnectionActive || _connection == null || !_connection!.isConnected) {
        print('⚠️ Bağlantı aktif değil, yeniden bağlanılıyor...');
        await connectToCsServer(connectedDeviceMacAddress!);
        await Future.delayed(Duration(milliseconds: 1000));
      }

      Map<String, dynamic> data = {
        "type": "full_data",
      };

      await sendDataToDevice(connectedDeviceMacAddress!, data);
      print("⏳ server yanıtı bekleniyor...");

      _dataSubscription?.cancel();

      final completer = Completer<String>();
      String toplam = "";

      _dataSubscription = _connectionInputStream!.listen(
            (Uint8List packet) {
          String msg = String.fromCharCodes(packet).trim();

          if (msg.isEmpty) return;

          if (msg != "bitti") {
            toplam += msg;
            print("📥 Parça alındı, toplam uzunluk: ${toplam.length}");
          } else {
            print("✅ Tüm veri alındı, uzunluk: ${toplam.length}");

            toplam = toplam.replaceAll("bitti", "");

            _dataSubscription?.cancel();
            completer.complete(toplam);
          }
        },
        onError: (e) {
          print('Veri alma hatası: $e');
          _dataSubscription?.cancel();
          if (!completer.isCompleted) completer.completeError(e);
        },
        onDone: () {
          print('⚠️ Stream kapandı');
          _dataSubscription?.cancel();
          if (!completer.isCompleted) {
            print('📨 Mevcut veri gönderiliyor: ${toplam.length} karakter');
            completer.complete(toplam);
          }
        },
        cancelOnError: true,
      );

      return await completer.future.timeout(
        Duration(seconds: 30),
        onTimeout: () {
          _dataSubscription?.cancel();
          throw TimeoutException('Veri alma işlemi 30 saniye içinde tamamlanmadı');
        },
      );
    } catch (e, stackTrace) {
      print('veri() fonksiyonu hatası: $e');
      print('Stack Trace: $stackTrace');
      _dataSubscription?.cancel();
      rethrow;
    } finally {
      _veriIsRunning = false;
    }
  }




  Future<Map<String, dynamic>> veriWithImages() async {
    try {
      String jsonStr = await veri();

      // Gelen veriyi debug için yazdır (ilk 500 karakter)
      print('📥 Gelen veri önizleme: ${jsonStr.substring(0, math.min(500, jsonStr
          .length))}');
      print('📊 Toplam uzunluk: ${jsonStr.length}');

      // Veriyi temizle
      jsonStr = jsonStr.trim();

      // Eğer veri JSON formatındaysa direkt parse et
      Map<String, dynamic> parsedData;

      if (jsonStr.startsWith('{') || jsonStr.startsWith('[')) {
        // Direkt JSON formatında
        print('✅ Veri JSON formatında, direkt parse ediliyor...');
        parsedData = jsonDecode(jsonStr);
      } else {
        // Base64 olup olmadığını kontrol et
        print('⚠️ Veri JSON formatında değil, base64 kontrolü yapılıyor...');
        try {
          // Base64 decode denemesi
          Uint8List decodedBytes = base64Decode(jsonStr);
          String decodedString = utf8.decode(decodedBytes);
          print('✅ Base64 decode başarılı, decoded veri: ${decodedString
              .substring(0, math.min(200, decodedString.length))}');

          if (decodedString.startsWith('{') || decodedString.startsWith('[')) {
            parsedData = jsonDecode(decodedString);
          } else {
            throw FormatException('Base64 decode edildi ancak JSON formatında değil');
          }
        } catch (e) {
          print('❌ Base64 decode başarısız: $e');
          await Future.delayed(Duration(seconds: 4)); // 🔥 2 saniye bekleme

          return await veriWithImages();




          // Son çare: string'i direkt JSON olarak parse etmeyi dene
          try {
            parsedData = jsonDecode(jsonStr);
            print('✅ String direkt JSON olarak parse edilebildi');
          } catch (e2) {
            print('❌ Tüm parse denemeleri başarısız: $e2');
            throw Exception('Geçersiz veri formatı: $e2');
          }
        }
      }

      print('✅ JSON parse başarılı, veri tipi: ${parsedData.runtimeType}');

      // Thumbnail işlemleri
      if (parsedData.containsKey('bilgi') && parsedData['bilgi'] is List) {
        List<dynamic> bilgiList = parsedData['bilgi'];
        print('📸 ${bilgiList.length} adet bilgi öğesi işleniyor...');

        for (int i = 0; i < bilgiList.length; i++) {
          try {
            if (bilgiList[i] is Map<String, dynamic> &&
                bilgiList[i]['thumbnailBase64'] != null &&
                bilgiList[i]['thumbnailBase64'].toString().isNotEmpty) {

              String base64String = bilgiList[i]['thumbnailBase64'].toString();
              print('🖼️ Öğe $i: Thumbnail base64 uzunluğu: ${base64String.length}');

              // Base64 string'i temizle (gerekiyorsa)
              base64String = base64String.trim();

              try {
                bilgiList[i]['thumbnailImage'] = imageFromBase64(base64String);
                print('✅ Öğe $i: Thumbnail başarıyla oluşturuldu');
              } catch (imgError) {
                print('❌ Öğe $i: Thumbnail oluşturma hatası: $imgError');
                bilgiList[i]['thumbnailImage'] = null;
              }
            } else {
              print('ℹ️ Öğe $i: Thumbnail bulunamadı veya geçersiz format');
              bilgiList[i]['thumbnailImage'] = null;
            }
          } catch (e) {
            print('❌ Öğe $i işlenirken hata: $e');
            bilgiList[i]['thumbnailImage'] = null;
          }
        }
      } else {
        print('ℹ️ Bilgi listesi bulunamadı veya liste değil');
      }

      // isimlik verilerini de kontrol et
      if (parsedData.containsKey('isimlik') && parsedData['isimlik'] is List) {
        print('👥 ${parsedData['isimlik'].length} adet isimlik öğesi bulundu');
      }

      print('✅ veriWithImages başarıyla tamamlandı');
      return parsedData;
    }
    catch (e, stackTrace) {
      print('❌ veriWithImages hatası: $e');
      print('Stack Trace: $stackTrace');
      return {
        "error": true,
        "message": e.toString(),
        "data": null
      };

    }
  }



    Future<void> parlaklik({
    required String id,
    required String value,
  }) async {
    try {
      Map<String, dynamic> data = {
        "type": "parlaklik",
        "id": id,
        "value": value,
      };
      await sendDataToDevice(connectedDeviceMacAddress!, data);
      print("Parlaklık başarıyla eklendi");
      _sendNotification('✅ Parlaklık ayarlandı', 'success');
    }
    catch (e) {
      print("Parlaklık ekleme hatası: $e");
      _sendNotification('❌ Parlaklık ayarlanamadı', 'error');
      rethrow;
    }
  }

  Future<void> volume({
    required String value,
  }) async {
    try {
      Map<String, dynamic> data = {
        "type": "volme",
        "value": value,
      };

      await sendDataToDevice(connectedDeviceMacAddress!, data);
      print("Volume başarıyla eklendi");
      _sendNotification('✅ Ses seviyesi ayarlandı', 'success');

    } catch (e) {
      print("Volume ekleme hatası: $e");
      _sendNotification('❌ Ses seviyesi ayarlanamadı', 'error');
      rethrow;
    }
  }

  void dispose() {
    _continuousScanTimer?.cancel();
    _connectionSubscription?.cancel();
    _scanSubscription?.cancel();
    _closeSerialConnection();

    _bluetoothStateController.close();
    _connectionStateController.close();
    _devicesController.close();
    _scanResultsController.close();
    _incomingDataController.close();
    _notificationController.close();
  }
}




class BluetoothConnectionPage extends StatefulWidget {
  @override
  _BluetoothConnectionPageState createState() => _BluetoothConnectionPageState();
}

class _BluetoothConnectionPageState extends State<BluetoothConnectionPage> {
  final BluetoothService _bluetoothService = BluetoothService();
  List<blue_plus.BluetoothDevice> _devices = [];
  bool _isScanning = false;
  bool _isConnecting = false;


  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _bluetoothService.initializeBluetooth();
    _setupListeners();


    _notificationSubscription = _bluetoothService.notificationStream.listen((notification) {
      if (!mounted) return;

      String message = notification['message'];
      String type = notification['type'];


      Color backgroundColor;
      IconData icon;

      switch (type) {
        case 'success':
          backgroundColor = Colors.green;
          icon = Icons.check_circle;
          break;
        case 'error':
          backgroundColor = Colors.red;
          icon = Icons.error;
          break;
        case 'warning':
          backgroundColor = Colors.orange;
          icon = Icons.warning;
          break;
        default:
          backgroundColor = Colors.blue;
          icon = Icons.info;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    });
  }

  void _setupListeners() {
    _bluetoothService.devicesStream.listen((devices) {
      if (mounted) {
        setState(() {
          _devices = devices;
        });
      }
    });

    _bluetoothService.scanResultsStream.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });

    _bluetoothService.bluetoothStateStream.listen((state) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Cihazları'),
        backgroundColor: Color(0xFF1D7269),
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.stop : Icons.search),
            onPressed: _toggleScan,
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return StreamBuilder<blue_plus.BluetoothAdapterState>(
      stream: _bluetoothService.bluetoothStateStream,
      builder: (context, snapshot) {
        final bluetoothState = snapshot.data ?? blue_plus.BluetoothAdapterState.unknown;

        if (bluetoothState != blue_plus.BluetoothAdapterState.on) {
          return _buildBluetoothOff();
        }

        return Column(
          children: [
            _buildConnectionStatus(),
            Expanded(
              child: _buildDevicesList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBluetoothOff() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Bluetooth Kapalı',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Bluetooth\'u açarak cihazları görebilirsiniz'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _bluetoothService.initializeBluetooth();
            },
            child: Text('Bluetooth\'u Aç'),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return StreamBuilder<BluetoothServiceState>(
      stream: _bluetoothService.connectionStateStream,
      builder: (context, snapshot) {
        final connectionState = snapshot.data ?? BluetoothServiceState.disconnected;

        Color backgroundColor;
        String statusText;

        switch (connectionState) {
          case BluetoothServiceState.connected:
            backgroundColor = Colors.green;
            statusText = 'Bağlı';
            break;
          case BluetoothServiceState.connecting:
            backgroundColor = Colors.orange;
            statusText = 'Bağlanıyor...';
            break;
          case BluetoothServiceState.weakSignal:
            backgroundColor = Colors.yellow;
            statusText = 'Zayıf Sinyal';
            break;
          case BluetoothServiceState.error:
            backgroundColor = Colors.red;
            statusText = 'Hata';
            break;
          default:
            backgroundColor = Colors.grey;
            statusText = 'Bağlı Değil';
        }

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(12),
          color: backgroundColor.withOpacity(0.1),
          child: Row(
            children: [
              Icon(
                _getConnectionIcon(connectionState),
                color: backgroundColor,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: backgroundColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_bluetoothService.connectedDevice != null)
                Text(
                  _bluetoothService.getDeviceDisplayName(_bluetoothService.connectedDevice!),
                  style: TextStyle(color: backgroundColor),
                ),
            ],
          ),
        );
      },
    );
  }

  IconData _getConnectionIcon(BluetoothServiceState state) {
    switch (state) {
      case BluetoothServiceState.connected:
        return Icons.bluetooth_connected;
      case BluetoothServiceState.connecting:
        return Icons.bluetooth_searching;
      case BluetoothServiceState.weakSignal:
        return Icons.signal_wifi_statusbar_connected_no_internet_4;
      case BluetoothServiceState.error:
        return Icons.error;
      default:
        return Icons.bluetooth_disabled;
    }
  }

  Widget _buildDevicesList() {
    if (_devices.isEmpty && !_isScanning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.devices, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Cihaz bulunamadı'),
            SizedBox(height: 8),
            Text('Tarama yapmak için arama butonuna basın'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        final isConnected = device.isConnected;
        final rssi = _bluetoothService.rssiValues[device.remoteId.str];

        return _buildDeviceTile(device, isConnected, rssi);
      },
    );
  }

  Widget _buildDeviceTile(blue_plus.BluetoothDevice device, bool isConnected, int? rssi) {
    return ListTile(
      leading: Icon(
        isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
        color: isConnected ? Colors.green : Colors.grey,
      ),
      title: Text(_bluetoothService.getDeviceDisplayName(device)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(device.remoteId.str),
          if (rssi != null) Text('Sinyal: ${rssi}dBm'),
        ],
      ),
      trailing: _isConnecting
          ? CircularProgressIndicator()
          : ElevatedButton(
        onPressed: () => _handleDeviceConnection(device, isConnected),
        style: ElevatedButton.styleFrom(
          backgroundColor: isConnected ? Colors.red : Colors.green,
        ),
        child: Text(
          isConnected ? 'Bağlantıyı Kes' : 'Bağlan',
          style: TextStyle(color: Colors.white),
        ),
      ),
      onTap: () => _showDeviceDetails(device),
    );
  }

  void _handleDeviceConnection(blue_plus.BluetoothDevice device, bool isConnected) async {
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
    });

    try {
      if (isConnected) {
        await _bluetoothService.disconnect();
      } else {
        await _bluetoothService.connectToDevice(device);
      }
    } catch (e) {
      print('Bağlantı hatası: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  void _showDeviceDetails(blue_plus.BluetoothDevice device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cihaz Detayları'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('İsim: ${_bluetoothService.getDeviceDisplayName(device)}'),
            Text('MAC: ${device.remoteId.str}'),
            Text('Bağlı: ${device.isConnected ? 'Evet' : 'Hayır'}'),
            if (_bluetoothService.rssiValues[device.remoteId.str] != null)
              Text('Sinyal: ${_bluetoothService.rssiValues[device.remoteId.str]}dBm'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _toggleScan() {
    if (_isScanning) {
      _bluetoothService._stopScan();
      setState(() {
        _isScanning = false;
      });
    } else {
      _bluetoothService.startScan();
      setState(() {
        _isScanning = true;
      });

      Future.delayed(Duration(seconds: 10), () {
        if (mounted && _isScanning) {
          _bluetoothService._stopScan();
          setState(() {
            _isScanning = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }
}