import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'dart:convert';
import 'dart:async';

enum BluetoothConnectionState {
  disconnected,
  connecting,
  connected,
  weakSignal,
  connectionLost
}

class BluetoothProvider with ChangeNotifier {
  fbp.BluetoothDevice? _connectedDevice;
  bool _isConnecting = false;
  fbp.BluetoothCharacteristic? _writeCharacteristic;
  fbp.BluetoothCharacteristic? _readCharacteristic;

  List<Map<String, String>> _speakers = [];
  List<Map<String, dynamic>> _contents = [];

  StreamSubscription<List<int>>? _readSubscription;
  StreamSubscription<fbp.BluetoothConnectionState>? _connectionStateSubscription;

  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;

  // Serial Port benzeri buffer mekanizması (ReadLine için)
  StringBuffer _readBuffer = StringBuffer();
  final StreamController<String> _lineStreamController = StreamController<String>.broadcast();
  Stream<String> get lineStream => _lineStreamController.stream;

  // Getters
  fbp.BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnecting => _isConnecting;
  List<Map<String, String>> get speakers => _speakers;
  List<Map<String, dynamic>> get contents => _contents;
  BluetoothConnectionState get connectionState => _connectionState;

  // Data management methods
  void updateSpeakers(List<Map<String, String>> newSpeakers) {
    _speakers = newSpeakers;
    notifyListeners();
  }

  void addSpeaker(Map<String, String> speaker) {
    _speakers.add(speaker);
    notifyListeners();
  }

  void clearSpeakers() {
    _speakers.clear();
    notifyListeners();
  }

  void updateContents(List<Map<String, dynamic>> newContents) {
    _contents = newContents;
    notifyListeners();
  }

  void addContent(Map<String, dynamic> content) {
    _contents.add(content);
    notifyListeners();
  }

  void deleteContent(int index) {
    if (index >= 0 && index < _contents.length) {
      _contents.removeAt(index);
      notifyListeners();
    }
  }

  void clearContents() {
    _contents.clear();
    notifyListeners();
  }

  // Characteristic setup
  void setWriteCharacteristic(fbp.BluetoothCharacteristic characteristic) {
    _writeCharacteristic = characteristic;
    notifyListeners();
  }

  void setReadCharacteristic(fbp.BluetoothCharacteristic characteristic) {
    _readCharacteristic = characteristic;
    _listenForData();
    notifyListeners();
  }

  void _listenForData() {
    _readSubscription?.cancel();
    _readSubscription = _readCharacteristic?.onValueReceived.listen((value) {
      if (value.isNotEmpty) {
        try {
          String receivedString = utf8.decode(value);

          _readBuffer.write(receivedString);
          String bufferContent = _readBuffer.toString();

          while (bufferContent.contains('\n')) {
            int newlineIndex = bufferContent.indexOf('\n');
            String line = bufferContent.substring(0, newlineIndex);

            line = line.replaceAll('\r', '');

            if (line.isNotEmpty) {

              _lineStreamController.add(line);

              try {
                Map<String, dynamic> receivedData = jsonDecode(line);
                _handleReceivedData(receivedData);
              } catch (e) {
                print('📨 Gelen satır: $line');
              }
            }

            bufferContent = bufferContent.substring(newlineIndex + 1);
          }

          _readBuffer.clear();
          _readBuffer.write(bufferContent);
        } catch (e) {
          print('❌ Veri okuma hatası: $e');
        }
      }
    });
  }

  void _handleReceivedData(Map<String, dynamic> data) {
    if (data.containsKey('speakers') && data['speakers'] is List) {
      List<Map<String, String>> newSpeakers = [];
      for (var speakerData in data['speakers']) {
        newSpeakers.add({
          "title": speakerData['department']?.toString() ?? '',
          "person": speakerData['name']?.toString() ?? '',
          "time": speakerData['duration']?.toString() ?? '00:00:00',
        });
      }
      updateSpeakers(newSpeakers);
    } else if (data.containsKey('department') && data.containsKey('name')) {
      addSpeaker({
        "title": data['department']?.toString() ?? '',
        "person": data['name']?.toString() ?? '',
        "time": data['duration']?.toString() ?? '00:00:00',
      });
    } else if (data.containsKey('operation') && data['operation'] == 1) {
      if (data.containsKey('contents') && data['contents'] is List) {
        List<Map<String, dynamic>> newContents = [];
        for (var contentData in data['contents']) {
          newContents.add({
            "id": contentData['id']?.toString() ?? '',
            "title": contentData['title']?.toString() ?? '',
            "startTime": contentData['startTime']?.toString() ?? '00:00:00',
            "endTime": contentData['endTime']?.toString() ?? '00:00:00',
            "type": contentData['type']?.toString() ?? 'document',
            "file": contentData['file']?.toString() ?? '',
          });
        }
        updateContents(newContents);
      } else if (data.containsKey('title')) {
        addContent({
          "id": data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          "title": data['title']?.toString() ?? '',
          "startTime": data['startTime']?.toString() ?? '00:00:00',
          "endTime": data['endTime']?.toString() ?? '00:00:00',
          "type": data['type']?.toString() ?? 'document',
          "file": data['file']?.toString() ?? '',
        });
      }
    }
  }

  Future<void> sendIsimlikAdd({
    required String title,
    required String name,
    required String toggle,
    required String isActive,
    required String time,
  }) async {
    if (_connectedDevice == null || _writeCharacteristic == null) {
      throw Exception('Bluetooth bağlantısı yok');
    }

    try {
      Map<String, dynamic> data = {
        "type": "isimlik_add",
        "title": title,
        "name": name,
        "togle": toggle,
        "is_active": isActive,
        "time": time,
      };

      String jsonData = jsonEncode(data);
      List<int> bytes = utf8.encode(jsonData);

      await _writeCharacteristic!.write(bytes, withoutResponse: false);
    } catch (e) {
      throw e;
    }
  }

  Future<void> sendSpeakerData(Map<String, dynamic> data) async {
    if (_connectedDevice == null || _writeCharacteristic == null) {
      return;
    }

    try {
      String jsonData = jsonEncode(data);
      List<int> bytes = utf8.encode(jsonData);

      await _writeCharacteristic!.write(bytes, withoutResponse: false);
    } catch (e) {
      print('Konuşmacı verisi gönderme hatası: $e');
    }
  }

  Future<void> sendContentData(Map<String, dynamic> data) async {
    if (_connectedDevice == null || _writeCharacteristic == null) {
      return;
    }

    try {
      Map<String, dynamic> sendData = {
        "operation": 1,
        "title": data['title'],
        "startTime": data['startTime'],
        "endTime": data['endTime'],
        "file": data['file']?.path ?? "",
      };

      String jsonData = jsonEncode(sendData);
      List<int> bytes = utf8.encode(jsonData);

      await _writeCharacteristic!.write(bytes, withoutResponse: false);
    } catch (e) {
      print('İçerik verisi gönderme hatası: $e');
    }
  }

  Future<void> sendDeleteContent(int index) async {
    if (_connectedDevice == null || _writeCharacteristic == null) {
      return;
    }

    try {
      Map<String, dynamic> sendData = {"operation": 1, "deleteIndex": index};

      String jsonData = jsonEncode(sendData);
      List<int> bytes = utf8.encode(jsonData);

      await _writeCharacteristic!.write(bytes, withoutResponse: false);
    } catch (e) {
      print('İçerik silme hatası: $e');
    }
  }

  Future<void> requestContentData() async {
    if (_connectedDevice == null || _writeCharacteristic == null) {
      return;
    }

    try {
      Map<String, dynamic> requestData = {
        "operation": 1,
        "request": "getContents",
      };

      String jsonData = jsonEncode(requestData);
      List<int> bytes = utf8.encode(jsonData);

      await _writeCharacteristic!.write(bytes, withoutResponse: false);
    } catch (e) {
      print('İçerik verisi isteme hatası: $e');
    }
  }

  Future<void> sendCustomJson(Map<String, dynamic> data) async {
    if (_connectedDevice == null || _writeCharacteristic == null) {
      throw Exception('Bluetooth bağlantısı yok');
    }

    try {
      String jsonData = jsonEncode(data);
      List<int> bytes = utf8.encode(jsonData);

      await _writeCharacteristic!.write(bytes, withoutResponse: false);
    } catch (e) {
      throw e;
    }
  }
  Future<void> writeLine(String message) async {
    if (_connectedDevice == null || _writeCharacteristic == null) {
      throw Exception('Bluetooth bağlantısı yok');
    }

    try {
      String lineToSend = '$message\r\n';
      List<int> bytes = utf8.encode(lineToSend);

      await _writeCharacteristic!.write(bytes, withoutResponse: false);
      print('📤 Gönderilen satır: $message');
    } catch (e) {
      print('❌ Veri gönderme hatası: $e');
      throw e;
    }
  }

  Future<void> write(String message) async {
    if (_connectedDevice == null || _writeCharacteristic == null) {
      throw Exception('Bluetooth bağlantısı yok');
    }

    try {
      List<int> bytes = utf8.encode(message);
      await _writeCharacteristic!.write(bytes, withoutResponse: false);
      print('📤 Gönderilen: $message');
    } catch (e) {
      print('❌ Veri gönderme hatası: $e');
      throw e;
    }
  }

  Future<String> readLine({Duration? timeout}) async {
    if (_connectedDevice == null) {
      throw Exception('Bluetooth bağlantısı yok');
    }

    Completer<String> completer = Completer<String>();
    StreamSubscription<String>? subscription;

    subscription = lineStream.listen(
          (line) {
        if (!completer.isCompleted) {
          subscription?.cancel();
          completer.complete(line);
        }
      },
      onError: (error) {
        if (!completer.isCompleted) {
          subscription?.cancel();
          completer.completeError(error);
        }
      },
    );

    if (timeout != null) {
      Timer(timeout, () {
        if (!completer.isCompleted) {
          subscription?.cancel();
          completer.completeError(
            Exception('ReadLine zaman aşımına uğradı (${timeout.inSeconds} saniye)'),
          );
        }
      });
    }

    try {
      String line = await completer.future;
      return line;
    } finally {
      subscription?.cancel();
    }
  }

  Stream<String> get readLineStream => lineStream;

  void disconnect() {
    _connectedDevice = null;
    _isConnecting = false;
    _connectionState = BluetoothConnectionState.disconnected;

    _writeCharacteristic = null;
    _readCharacteristic = null;

    _readSubscription?.cancel();
    _connectionStateSubscription?.cancel();

    _readBuffer.clear();

    print('✅ Bağlantı kesildi');
    notifyListeners();
  }

  void setConnecting(bool connecting) {
    _isConnecting = connecting;
    if (connecting) {
      _connectionState = BluetoothConnectionState.connecting;
    }
    notifyListeners();
  }

  void setConnectedDevice(fbp.BluetoothDevice device) {
    _connectedDevice = device;
    _isConnecting = false;
    _connectionState = BluetoothConnectionState.connected;
    print('✅ Bağlandı: ${device.platformName}');
    notifyListeners();
  }

  @override
  void dispose() {
    _readSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _lineStreamController.close();
    _readBuffer.clear();
    super.dispose();
  }
}