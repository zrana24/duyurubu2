import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as blue_plus;
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart' as bluetooth_serial;
import 'package:permission_handler/permission_handler.dart';

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

  // Bluetooth state
  blue_plus.BluetoothAdapterState _bluetoothState = blue_plus.BluetoothAdapterState.unknown;
  List<blue_plus.BluetoothDevice> _pairedDevicesList = [];
  List<blue_plus.ScanResult> _scanResults = [];

  // Connection state
  BluetoothServiceState _connectionState = BluetoothServiceState.disconnected;
  blue_plus.BluetoothDevice? _connectedDevice;
  bool _isConnecting = false;
  bool _isScanning = false;
  bool _connectionLocked = false;

  // Data storage
  Map<String, int?> _rssiValues = {};
  List<bluetooth_serial.BluetoothDevice> _bondedDevicesList = [];
  Map<String, String> _deviceNamesCache = {};

  // İsimlik listesi için yeni değişken
  List<Map<String, dynamic>> _isimlikList = [];

  // Stream controllers
  final _bluetoothStateController = StreamController<blue_plus.BluetoothAdapterState>.broadcast();
  final _connectionStateController = StreamController<BluetoothServiceState>.broadcast();
  final _devicesController = StreamController<List<blue_plus.BluetoothDevice>>.broadcast();
  final _scanResultsController = StreamController<List<blue_plus.ScanResult>>.broadcast();

  // Connection - PERSISTENT CONNECTION
  bluetooth_serial.BluetoothConnection? _connection;
  bool _isConnectionActive = false;
  StreamSubscription<Uint8List>? _dataSubscription;
  final _incomingDataController = StreamController<String>.broadcast();

  // Video path storage
  String? receivedVideoPath;

  // Getters
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

  // Streams
  Stream<blue_plus.BluetoothAdapterState> get bluetoothStateStream => _bluetoothStateController.stream;
  Stream<BluetoothServiceState> get connectionStateStream => _connectionStateController.stream;
  Stream<List<blue_plus.BluetoothDevice>> get devicesStream => _devicesController.stream;
  Stream<List<blue_plus.ScanResult>> get scanResultsStream => _scanResultsController.stream;
  Stream<String> get incomingDataStream => _incomingDataController.stream;

  StreamSubscription<List<blue_plus.ScanResult>>? _scanSubscription;
  StreamSubscription<blue_plus.BluetoothConnectionState>? _connectionSubscription;
  Timer? _continuousScanTimer;

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

  // Bluetooth Başlatma
  Future<void> initializeBluetooth() async {
    try {
      bool hasPermissions = await requestPermissions();
      if (!hasPermissions) {
        print('❌ Bluetooth izinleri gerekli');
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
    }
  }

  // Eşleşmiş Cihazları Getirme
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

  // Bağlı Cihazları Getirme
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

  // Otomatik Tarama Sistemi
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

  // Tarama Sistemi
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

  // Cihaz adını getir
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
      // Hiçbir şey yapma
    }

    return deviceId.length > 8 ? '${deviceId.substring(0, 8)}...' : deviceId;
  }

  // Bağlantı Kurma
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

        // Önce mevcut bağlantıyı kes
        try {
          await device.disconnect();
          await Future.delayed(Duration(milliseconds: 1000));
        } catch (e) {
          print('⚠️ Disconnect hatası (göz ardı ediliyor): $e');
          await Future.delayed(Duration(milliseconds: 1000));
        }

        // Bluetooth adapter durumunu kontrol et
        final adapterState = await blue_plus.FlutterBluePlus.adapterState.first;
        if (adapterState != blue_plus.BluetoothAdapterState.on) {
          throw Exception('Bluetooth adaptörü kapalı');
        }

        // Bağlantı durumunu kontrol et
        final currentConnectionState = await device.connectionState.first;
        if (currentConnectionState == blue_plus.BluetoothConnectionState.connected) {
          print('✅ Cihaz zaten bağlı');
          _connectedDevice = device;
          _connectionLocked = true;
          _isConnecting = false;
          _updateConnectionState(BluetoothServiceState.connected);
          _stopScan();
          _monitorConnectionState(device);

          // Serial bağlantıyı kur
          await connectToCsServer(device.remoteId.str);
          return;
        }

        // Connect with timeout
        await device.connect(autoConnect: false, timeout: Duration(seconds: 15)).timeout(
          Duration(seconds: 20),
          onTimeout: () {
            throw TimeoutException('Bağlantı zaman aşımına uğradı', Duration(seconds: 20));
          },
        );

        // Bağlantı başarılı olup olmadığını kontrol et
        await Future.delayed(Duration(milliseconds: 1000));
        final connectionState = await device.connectionState.first;

        if (connectionState != blue_plus.BluetoothConnectionState.connected) {
          throw Exception('Bağlantı kurulamadı. Durum: $connectionState');
        }

        // Servisleri keşfet
        await discoverServicesAfterConnection(device);

        // Başarılı
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

        // Serial bağlantıyı kur
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

  // PERSISTENT Serial Connection - connectToCsServer
  Future<void> connectToCsServer(String address) async {
    // Zaten aktif ve aynı adrese bağlıysa, yeni bağlantı kurma
    if (_isConnectionActive && _connection != null && _connection!.isConnected) {
      print('✅ Serial bağlantı zaten aktif');
      return;
    }

    try {
      // Eski bağlantıyı tamamen temizle
      await _closeSerialConnection();

      // Temizlik sonrası bekle
      await Future.delayed(Duration(milliseconds: 1000));

      print('📡 Serial bağlantı kuruluyor: $address');
      _connection = await bluetooth_serial.BluetoothConnection.toAddress(address);

      if (_connection == null) {
        throw Exception('Bağlantı nesnesi null');
      }

      _isConnectionActive = true;
      print('✅ Serial bağlantı kuruldu: $address');

      // Veri dinleyicisini kur
      _dataSubscription = _connection!.input!.listen(
            (Uint8List data) {
          String message = String.fromCharCodes(data).trim();
          if (message.isNotEmpty) {
            print('📨 Gelen veri: $message');
            _handleIncomingData(message);
            _incomingDataController.add(message);
          }
        },
        onDone: () {
          print('⚠️ Bağlantı kesildi!');
          _isConnectionActive = false;
        },
        onError: (error) {
          print('❌ Veri okuma hatası: $error');
          _isConnectionActive = false;
        },
        cancelOnError: false,
      );

      // Bağlantının stabil olmasını bekle
      await Future.delayed(Duration(milliseconds: 500));

    } catch (e) {
      print('❌ Serial bağlantı hatası: $e');
      _isConnectionActive = false;
      _connection = null;
      rethrow;
    }
  }

  // Serial bağlantıyı kapat
  Future<void> _closeSerialConnection() async {
    try {
      // Önce listener'ı iptal et
      if (_dataSubscription != null) {
        await _dataSubscription!.cancel();
        _dataSubscription = null;
      }

      // Sonra bağlantıyı kapat
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

      // Temizlik sonrası kısa bekleme
      await Future.delayed(Duration(milliseconds: 300));
    } catch (e) {
      print('⚠️ Serial bağlantı kapatma hatası: $e');
      _connection = null;
      _isConnectionActive = false;
    }
  }

  // Hizmetleri Keşfet
  Future<void> discoverServicesAfterConnection(blue_plus.BluetoothDevice device) async {
    try {
      await Future.delayed(Duration(milliseconds: 500));
      await device.discoverServices();
    } catch (e) {
      print('⚠️ Hizmet keşfi hatası: $e');
    }
  }

  // Bağlantı Durumunu İzle
  void _monitorConnectionState(blue_plus.BluetoothDevice device) {
    _connectionSubscription?.cancel();
    _connectionSubscription = device.connectionState.listen((state) {
      if (state == blue_plus.BluetoothConnectionState.disconnected) {
        print('❌ Bağlantı koptu');
        _handleDisconnection();
      }
    });
  }

  // Bağlantı Kontrolü
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
    _connectedDevice = null;
    _connectionLocked = false;
    _isConnecting = false;
    _connectionSubscription?.cancel();

    // Serial bağlantıyı kapat
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

  void _handleIncomingData(String message) {
    try {
      // Önce direk JSON parse dene
      Map<String, dynamic> jsonData = jsonDecode(message);
      print('📊 JSON verisi alındı: $jsonData');

      // Path varsa kaydet
      if (jsonData.containsKey('path')) {
        receivedVideoPath = jsonData['path'];
        print('✅ Path kaydedildi: $receivedVideoPath');
      }

      if (jsonData['status'] == 'ok') {
        print('✅ İşlem başarılı');
      }
    } catch (e) {
      print('⚠️ JSON parse hatası, regex deneniyor: $e');

      // Regex ile path çıkar
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
  }

  // Veri gönderme - Mevcut bağlantıyı kullan
  Future<void> sendDataToDevice(String macAddress, Map<String, dynamic> data) async {
    try {
      // Bağlantı kontrolü
      if (!_isConnectionActive || _connection == null || !_connection!.isConnected) {
        print('⚠️ Bağlantı aktif değil, yeniden kuruluyor...');
        await connectToCsServer(macAddress);
      }

      String jsonData = jsonEncode(data);
      _connection!.output.add(utf8.encode(jsonData + "\r\n"));
      await _connection!.output.allSent;
      print('✅ Veri başarıyla gönderildi: $jsonData');

      // Küçük bir bekleme ekle
      await Future.delayed(Duration(milliseconds: 100));
    } catch (e) {
      print('❌ Veri gönderme hatası: $e');
      _isConnectionActive = false;
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
      print('✅ İsimlik eklendi');
    } catch (e) {
      print('❌ İsimlik ekleme hatası: $e');
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
      // Bağlantı kontrolü
      if (!_isConnectionActive || _connection == null || !_connection!.isConnected) {
        print("📡 Video göndermek için bağlantı kuruluyor...");
        await connectToCsServer(connectedDeviceMacAddress!);
      }

      File videoFile = File(videoPath);

      if (!videoFile.existsSync()) {
        throw Exception("❌ Video dosyası bulunamadı: $videoPath");
      }

      Uint8List fileBytes = await videoFile.readAsBytes();
      int totalBytes = fileBytes.length;

      // Video header gönder - C# ile uyumlu format
      Map<String, dynamic> data = {
        "type": "video",
        "size": totalBytes,
        "name": name
      };

      print("📦 Video bilgileri gönderiliyor: $data");
      String jsonData = jsonEncode(data);
      _connection!.output.add(utf8.encode(jsonData + "\r\n"));
      await _connection!.output.allSent;

      // CRITICAL: C# tarafının FileStream hazırlaması için bekle
      // C# while döngüsünün video byte'larını okumaya hazır olması gerekiyor
      print("⏳ C# FileStream hazırlanıyor...");
      await Future.delayed(Duration(seconds: 3));

      print("📤 Video gönderimi başlıyor...");
      print("📏 Toplam Boyut: ${(totalBytes / 1024 / 1024).toStringAsFixed(2)} MB");

      int offset = 0;
      int chunkSize = 512; // Daha küçük chunk size (512 -> 256)
      int lastProgressUpdate = 0;
      DateTime startTime = DateTime.now();

      while (offset < totalBytes) {
        // Bağlantı kontrolü ve otomatik yeniden bağlanma
        if (!_isConnectionActive || _connection == null || !_connection!.isConnected) {
          print("⚠️ Bağlantı koptu, yeniden bağlanılıyor...");
          try {
            await connectToCsServer(connectedDeviceMacAddress!);
            await Future.delayed(Duration(milliseconds: 1000));
          } catch (e) {
            throw Exception("❌ Bağlantı koptu ve yeniden kurulamadı!");
          }
        }

        int bytesToSend = (offset + chunkSize > totalBytes)
            ? totalBytes - offset
            : chunkSize;

        Uint8List chunk = fileBytes.sublist(offset, offset + bytesToSend);

        try {
          _connection!.output.add(chunk);
          await _connection!.output.allSent;
          await Future.delayed(Duration(milliseconds: 10)); // 5ms -> 10ms
        } catch (e) {
          print("❌ Chunk gönderme hatası: $e");

          // Bağlantıyı yeniden kur ve chunk'ı tekrar gönder
          try {
            print("🔄 Bağlantı yeniden kuruluyor...");
            await connectToCsServer(connectedDeviceMacAddress!);
            await Future.delayed(Duration(milliseconds: 1000));

            _connection!.output.add(chunk);
            await _connection!.output.allSent;
            await Future.delayed(Duration(milliseconds: 10));
          } catch (retryError) {
            throw Exception("Veri gönderimi başarısız: $e (Retry: $retryError)");
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
      print("📊 ${(totalBytes / 1024 / 1024).toStringAsFixed(2)} MB - Süre: ${totalTime.inSeconds}s - Ort. Hız: ${avgSpeed.toStringAsFixed(2)} MB/s");

      // Sunucu yanıtını bekle
      final completer = Completer<void>();
      StreamSubscription<String>? responseSubscription;

      Timer? timeoutTimer = Timer(Duration(seconds: 10), () {
        print('⚠️ Sunucu yanıtı timeout');
        responseSubscription?.cancel();
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      responseSubscription = _incomingDataController.stream.listen((message) {
        try {
          Map<String, dynamic> response = jsonDecode(message);
          if (response.containsKey('path')) {
            receivedVideoPath = response['path'];
            print('✅ Video yolu alındı: $receivedVideoPath');
          }
        } catch (e) {
          print('⚠️ Yanıt parse hatası: $e');
        }

        timeoutTimer?.cancel();
        responseSubscription?.cancel();
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      await completer.future;

    } catch (e, stackTrace) {
      print("❌ Video gönderme hatası: $e");
      print("StackTrace:\n$stackTrace");
      rethrow;
    }
  }

  Future<void> bilgiAdd({
    required String meeting_title,
    required String start_hour,
    required String end_hour,
  }) async {
    try {
      Map<String, dynamic> data = {
        "type": "bilgi_add",
        "meeting_title": meeting_title,
        "start_hour": start_hour,
        "end_hour": end_hour,
        "path": receivedVideoPath ?? "",
        "is_active": false,
        "button_status": false
      };

      await sendDataToDevice(connectedDeviceMacAddress!, data);
      print("✅ Bilgi başarıyla eklendi");

      // Path'i temizle
      receivedVideoPath = null;
    } catch (e) {
      print("❌ Bilgi ekleme hatası: $e");
      rethrow;
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

      receivedVideoPath = null;
    } catch (e) {
      print("Parlaklık ekleme hatası: $e");
      rethrow;
    }
  }

  Future<void> volume({
    required String value,
  }) async {
    try {
      Map<String, dynamic> data = {
        "type": "volume",
        "value": value,
      };

      await sendDataToDevice(connectedDeviceMacAddress!, data);
      print("Volume başarıyla eklendi");

    } catch (e) {
      print("Volume ekleme hatası: $e");
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

  @override
  void initState() {
    super.initState();
    _bluetoothService.initializeBluetooth();
    _setupListeners();
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Hata: ${e.toString()}'),
        backgroundColor: Colors.red,
      ));
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
    super.dispose();
  }
}