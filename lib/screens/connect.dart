import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as blue_plus;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../bluetooth_provider.dart';
import '../language.dart';
import '../image.dart';
import 'connected.dart';

enum SnackbarType { success, error, info }

class ConnectPage extends StatefulWidget {
  @override
  _ConnectPageState createState() => _ConnectPageState();
}

class  _ConnectPageState extends State<ConnectPage> {
  final BluetoothService _bluetoothService = BluetoothService();
  blue_plus.BluetoothDevice? _selectedDevice;
  final ScrollController _pairedScrollController = ScrollController();
  final ScrollController _nearbyScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeBluetooth();
    });
  }

  @override
  void dispose() {
    _pairedScrollController.dispose();
    _nearbyScrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeBluetooth() async {
    bool granted = await _bluetoothService.requestPermissions();
    if (granted) {
      await _bluetoothService.initializeBluetooth();
    } else {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('İzin Gerekli'),
        content: Text(
          'Bluetooth ve konum izinleri gereklidir. Lütfen ayarlardan izinleri açın.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: Text('Ayarlar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Future<void> _connectToDevice(blue_plus.BluetoothDevice device) async {
    final bluetoothProvider = Provider.of<BluetoothProvider>(
      context,
      listen: false,
    );

    if (bluetoothProvider.connectedDevice != null) {
      String currentDevice = bluetoothProvider.connectedDevice!.platformName;
      String selectedDevice = _bluetoothService.getDeviceDisplayName(device);


      if (bluetoothProvider.connectedDevice!.remoteId == device.remoteId) {
        _showSnackbar(
          '✅ Zaten $selectedDevice ile bağlısınız',
          SnackbarType.success,
        );
        return;
      }

      _showSnackbar(
        '🔌 Önce $currentDevice bağlantısı kesiliyor...',
        SnackbarType.info,
      );
      await _bluetoothService.disconnect();
      bluetoothProvider.disconnect();
      await Future.delayed(Duration(seconds: 1));
    }

    if (bluetoothProvider.isConnecting) {
      _showSnackbar(
        '⏳ Bağlantı işlemi devam ediyor, lütfen bekleyin...',
        SnackbarType.info,
      );
      return;
    }

    try {
      String deviceName = _bluetoothService.getDeviceDisplayName(device);
      print('🔗 $deviceName cihazına bağlanılıyor...');

      // Provider'ı bağlanıyor durumuna ayarla
      bluetoothProvider.setConnecting(true);

      // BluetoothService ile bağlan
      await _bluetoothService.connectToDevice(device);

      // Provider'ı güncelle
      bluetoothProvider.setConnectedDevice(device);
      setState(() => _selectedDevice = device);
      _showSnackbar('✅ Bağlandı: $deviceName', SnackbarType.success);
      print('✅ Bağlantı başarılı: $deviceName');
    } catch (e) {
      String deviceName = _bluetoothService.getDeviceDisplayName(device);
      String errorMessage = _getUserFriendlyErrorMessage(e);
      print('❌ Bağlantı hatası: $deviceName -> $e');
      _showSnackbar('❌ $errorMessage', SnackbarType.error);
      _showConnectionErrorDialog(deviceName, errorMessage);

      // Provider'ı hata durumuna ayarla
      bluetoothProvider.setConnecting(false);
    }
  }

  String _getUserFriendlyErrorMessage(dynamic error) {
    String errorString = error.toString();
    if (errorString.contains('timeout') || errorString.contains('Timed out')) {
      return 'Bağlantı zaman aşımına uğradı. Lütfen cihazın yakınınızda olduğundan emin olun.';
    } else if (errorString.contains('permission')) {
      return 'Bluetooth izinleri gerekli. Lütfen uygulama ayarlarından izinleri kontrol edin.';
    } else if (errorString.contains('unavailable')) {
      return 'Cihaz bağlantıya uygun değil veya meşgul.';
    } else if (errorString.contains('133')) {
      return 'Cihaz yanıt vermiyor. Lütfen cihazı yeniden başlatıp tekrar deneyin.';
    } else {
      return 'Bağlantı kurulamadı. Lütfen tekrar deneyin.';
    }
  }

  void _showConnectionErrorDialog(String deviceName, String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bağlantı Hatası'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$deviceName cihazına bağlanılamadı.'),
            SizedBox(height: 8),
            Text(
              errorMessage,
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String message, SnackbarType type) {
    Color backgroundColor;
    IconData icon;

    switch (type) {
      case SnackbarType.success:
        backgroundColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case SnackbarType.error:
        backgroundColor = Colors.red;
        icon = Icons.error;
        break;
      case SnackbarType.info:
        backgroundColor = Colors.blue;
        icon = Icons.info;
        break;
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
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: type == SnackbarType.error ? 4 : 3),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _disconnect() async {
    final bluetoothProvider = Provider.of<BluetoothProvider>(
      context,
      listen: false,
    );

    if (bluetoothProvider.connectedDevice != null) {
      String deviceName = bluetoothProvider.connectedDevice!.platformName;
      print('🔌 $deviceName cihazından bağlantı kesiliyor');

      // Önce BluetoothService'ten bağlantıyı kes
      await _bluetoothService.disconnect();

      // Sonra Provider'ı güncelle
      bluetoothProvider.disconnect();
      _showSnackbar('🔌 $deviceName bağlantısı kesildi', SnackbarType.info);
      setState(() => _selectedDevice = null);
    }
  }
  String  deviceAddress="";
  int _getSignalStrength(int? rssi) {
    if (rssi == null) return 0;
    if (rssi >= -50) return 4;
    if (rssi >= -60) return 3;
    if (rssi >= -70) return 2;
    if (rssi >= -80) return 1;
    return 0;
  }

  Widget _buildSignalIndicator(int? rssi) {
    int level = _getSignalStrength(rssi);
    return Row(
      children: List.generate(4, (index) {
        return Container(
          width: 3,
          height: (index + 1) * 3.0,
          margin: EdgeInsets.only(right: 1),
          decoration: BoxDecoration(
            color: index < level ? _getSignalColor(level) : Colors.grey[300],
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }

  Color _getSignalColor(int level) {
    switch (level) {
      case 4:
        return Colors.green;
      case 3:
        return Colors.lightGreen;
      case 2:
        return Colors.orange;
      case 1:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getDeviceIcon(blue_plus.BluetoothDevice device) {
    String deviceName = _bluetoothService.getDeviceDisplayName(device).toLowerCase();
    if (deviceName.contains('speaker') ||
        deviceName.contains('audio') ||
        deviceName.contains('sound') ||
        deviceName.contains('podium')) {
      return Icons.speaker;
    } else if (deviceName.contains('headphone') || deviceName.contains('earbuds')) {
      return Icons.headphones;
    } else if (deviceName.contains('phone')) {
      return Icons.phone_android;
    } else if (deviceName.contains('watch')) {
      return Icons.watch;
    } else if (deviceName.contains('tv')) {
      return Icons.tv;
    } else if (deviceName.contains('keyboard')) {
      return Icons.keyboard;
    } else if (deviceName.contains('mouse')) {
      return Icons.mouse;
    } else {
      return Icons.bluetooth;
    }
  }

  Color _getButtonColor(BluetoothProvider bluetoothProvider) {
    if (_bluetoothService.bluetoothState != blue_plus.BluetoothAdapterState.on) return Colors.grey;
    if (bluetoothProvider.isConnecting) return Colors.orange;
    if (bluetoothProvider.connectedDevice != null) return Colors.red;
    if (_selectedDevice != null) return Color(0xFF00D2C8);
    return Colors.grey;
  }

  String _getButtonText(
      BluetoothProvider bluetoothProvider,
      LanguageProvider languageProvider,
      ) {
    if (bluetoothProvider.isConnecting) {
      return 'BAĞLANILIYOR...';
    } else if (bluetoothProvider.connectedDevice != null) {
      return languageProvider.getTranslation('disconnect');
    } else if (_selectedDevice != null) {
      return languageProvider.getTranslation('connect');
    } else {
      return languageProvider.getTranslation('select_device');
    }
  }

  IconData _getButtonIcon(BluetoothProvider bluetoothProvider) {
    if (bluetoothProvider.isConnecting) {
      return Icons.hourglass_empty;
    } else if (bluetoothProvider.connectedDevice != null) {
      return Icons.link_off;
    } else {
      return Icons.bluetooth;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bluetoothProvider = Provider.of<BluetoothProvider>(context);
    final bool isTablet = screenSize.width > 600;

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Scaffold(
          backgroundColor: Color(0xFFE0E0E0),
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  height: 60,
                  width: double.infinity,
                  child: ImageWidget(activePage: "connect"),
                ),

                // Bluetooth durumu
                _buildBluetoothStatusBar(),

                // Bağlantı durumu
                _buildConnectionStatusBar(),

                // Ana içerik
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        // Eşleşen Cihazlar
                        Expanded(
                          flex: 1,
                          child: _buildPairedDevicesSection(
                            languageProvider,
                            isTablet,
                          ),
                        ),
                        SizedBox(height: 16),

                        // Çevredeki Cihazlar
                        Expanded(
                          flex: 1,
                          child: _buildNearbyDevicesSection(
                            languageProvider,
                            isTablet,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bağlantı durumu göstergesi
                Consumer<BluetoothProvider>(
                  builder: (context, provider, _) {
                    if (provider.isConnecting) {
                      return Container(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        color: Colors.orange.withOpacity(0.1),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.orange,
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Bağlanılıyor...',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),

                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                    _bluetoothService.bluetoothState != blue_plus.BluetoothAdapterState.on
                        ? null
                        : () async {
                      if (bluetoothProvider.connectedDevice != null) {
                        _showDisconnectConfirmDialog();
                      } else if (_selectedDevice != null &&
                          !bluetoothProvider.isConnecting) {
                        deviceAddress = BluetoothService.connectedDeviceMacAddress!;
                        await _bluetoothService.connectToCsServer(deviceAddress);
                      }
                    },
                    icon: Icon(
                      _getButtonIcon(bluetoothProvider),
                      color: Colors.white,
                      size: 22,
                    ),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _getButtonText(bluetoothProvider, languageProvider),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 12,
                      ),
                      backgroundColor: _getButtonColor(bluetoothProvider),
                    ),
                  ),
                ),

              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBluetoothStatusBar() {
    return StreamBuilder<blue_plus.BluetoothAdapterState>(
      stream: _bluetoothService.bluetoothStateStream,
      builder: (context, snapshot) {
        if (snapshot.data != blue_plus.BluetoothAdapterState.on) {
          return Container(
            width: double.infinity,
            padding: EdgeInsets.all(8),
            color: Colors.red.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bluetooth_disabled, color: Colors.red, size: 16),
                SizedBox(width: 8),
                Text(
                  'Bluetooth kapalı - Lütfen açın',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ),
          );
        }
        return SizedBox.shrink();
      },
    );
  }

  Widget _buildConnectionStatusBar() {
    return StreamBuilder<BluetoothServiceState>(
      stream: _bluetoothService.connectionStateStream,
      builder: (context, snapshot) {
        if (snapshot.data == BluetoothServiceState.connected &&
            _bluetoothService.connectedDevice != null) {
          return Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              border: Border(bottom: BorderSide(color: Colors.green, width: 2)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _bluetoothService.getDeviceDisplayName(
                                _bluetoothService.connectedDevice!,
                              ),
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'BAĞLI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Bağlantı kilitli - Bağlantıyı kesmek için aşağıdaki butona basın',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return SizedBox.shrink();
      },
    );
  }

  Widget _buildPairedDevicesSection(
      LanguageProvider languageProvider,
      bool isTablet,
      ) {
    return StreamBuilder<List<blue_plus.BluetoothDevice>>(
      stream: _bluetoothService.devicesStream,
      builder: (context, snapshot) {
        List<blue_plus.BluetoothDevice> pairedDevices =
            snapshot.data ?? _bluetoothService.pairedDevices;
        return _buildCardSection(
          languageProvider.getTranslation('paired_podiums'),
          pairedDevices,
          false,
          languageProvider,
          _pairedScrollController,
          isTablet: isTablet,
        );
      },
    );
  }

  Widget _buildNearbyDevicesSection(
      LanguageProvider languageProvider,
      bool isTablet,
      ) {
    return StreamBuilder<List<blue_plus.ScanResult>>(
      stream: _bluetoothService.scanResultsStream,
      builder: (context, snapshot) {
        List<blue_plus.BluetoothDevice> nearbyDevices =
        (snapshot.data ?? []).map((r) => r.device).toList();
        return _buildCardSection(
          languageProvider.getTranslation('nearby_devices'),
          nearbyDevices,
          true,
          languageProvider,
          _nearbyScrollController,
          isTablet: isTablet,
        );
      },
    );
  }

  void _showDisconnectConfirmDialog() {
    final bluetoothProvider = Provider.of<BluetoothProvider>(
      context,
      listen: false,
    );
    String deviceName = bluetoothProvider.connectedDevice?.platformName ?? 'Bilinmeyen Cihaz';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bağlantıyı Kessin mi?'),
        content: Text(
          '$deviceName ile olan bağlantıyı kesmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _disconnect();
            },
            child: Text(
              'Bağlantıyı Kes',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSection(
      String title,
      List<blue_plus.BluetoothDevice> devices,
      bool isNearby,
      LanguageProvider languageProvider,
      ScrollController scrollController, {
        required bool isTablet,
      }) {
    bool isPaired = title == languageProvider.getTranslation('paired_podiums');
    Color headerColor = const Color(0xFF4DB6AC);
    Color headerTextColor = const Color(0xFF00695C);
    IconData titleIcon = isPaired ? Icons.bluetooth_connected : Icons.bluetooth_searching;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: headerColor, width: 1.5),
        color: Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            height: isTablet ? 45 : 40,
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        titleIcon,
                        color: headerTextColor,
                        size: isTablet ? 22 : 20,
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: headerTextColor,
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isNearby)
                  IconButton(
                    onPressed: _bluetoothService.isScanning
                        ? null
                        : () => _bluetoothService.startScan(),
                    icon: _bluetoothService.isScanning
                        ? SizedBox(
                      width: isTablet ? 24 : 20,
                      height: isTablet ? 24 : 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          headerTextColor,
                        ),
                      ),
                    )
                        : Icon(
                      Icons.refresh,
                      color: headerTextColor,
                      size: isTablet ? 22 : 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints.tightFor(
                      width: isTablet ? 36 : 32,
                      height: isTablet ? 36 : 32,
                    ),
                  )
                else
                  SizedBox(
                    width: isTablet ? 36 : 32,
                    height: isTablet ? 36 : 32,
                  ),
              ],
            ),
          ),
          Expanded(
            child: devices.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isNearby ? Icons.bluetooth_disabled : Icons.bluetooth_searching,
                    size: isTablet ? 42 : 36,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 6),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      isNearby
                          ? languageProvider.getTranslation('no_devices_found')
                          : languageProvider.getTranslation('no_paired_podiums'),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: isTablet ? 14 : 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            )
                : Scrollbar(
              thumbVisibility: true,
              controller: scrollController,
              child: ListView.builder(
                controller: scrollController,
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.only(top: 4),
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  blue_plus.BluetoothDevice device = devices[index];
                  final bluetoothProvider = Provider.of<BluetoothProvider>(context);
                  bool isConnected = _bluetoothService.connectedDevice?.remoteId ==
                      device.remoteId;
                  int? rssi = _bluetoothService.rssiValues[device.remoteId.str];
                  bool canSelect = !isConnected && !bluetoothProvider.isConnecting;

                  return InkWell(
                    onTap: canSelect
                        ? () {
                      setState(() {
                        _selectedDevice = device;
                        BluetoothService.connectedDeviceMacAddress = device.remoteId.str;
                      });
                    }
                        : null,

                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: isTablet ? 10 : 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isConnected
                              ? Colors.green
                              : (_selectedDevice?.remoteId == device.remoteId
                              ? Colors.green
                              : Colors.grey[300]!),
                          width: 1.5,
                        ),
                        color: isConnected
                            ? Colors.green[50]
                            : (_selectedDevice?.remoteId == device.remoteId
                            ? Colors.green[50]
                            : Colors.white),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  _getDeviceIcon(device),
                                  size: isTablet ? 18 : 16,
                                  color: Colors.grey[600],
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _bluetoothService.getDeviceDisplayName(device),
                                    style: TextStyle(
                                      fontSize: isTablet ? 16 : 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 8),
                                _buildSignalIndicator(rssi),
                              ],
                            ),
                          ),
                          if (isConnected)
                            Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'BAĞLI',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}