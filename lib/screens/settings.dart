import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../language.dart';
import 'package:provider/provider.dart';
import '../image.dart';
import 'connected.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double _mainScreenBrightness = 0.23;
  double _mainScreenVolume = 1.0;

  double _nameScreenBrightness = 1.0;
  double _nameScreenVolume = 1.0;

  double _infoScreenBrightness = 1.0;
  double _infoScreenVolume = 1.0;

  BluetoothService get _bluetoothService => BluetoothService();

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
              child: ImageWidget(activePage: "settings"),
            ),
            Expanded(
              child: isTablet ? _buildTabletLayout() : _buildMobileLayout(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Column(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05,
              vertical: screenHeight * 0.02,
            ),
            child: Column(
              children: [
                Expanded(
                  flex: 1,
                  child: _buildScreenCard(
                    context,
                    title: languageProvider.getTranslation('main_screen'),
                    brightnessValue: _mainScreenBrightness,
                    volumeValue: _mainScreenVolume,
                    onBrightnessChanged: (value) {
                      setState(() {
                        _mainScreenBrightness = value;
                      });
                    },
                    onBrightnessChangeEnd: (value) {
                      _bluetoothService.parlaklik(
                        id: '0',
                        value: (value * 100).round().toString(),
                      );
                    },
                    onVolumeChanged: (value) {
                      setState(() {
                        _mainScreenVolume = value;
                      });
                    },
                    onVolumeChangeEnd: (value) {
                      _bluetoothService.volume(
                        value: (value * 100).round().toString(),
                      );
                    },
                    languageProvider: languageProvider,
                    fillAvailableSpace: true,
                    showVolume: true,
                    isMainScreen: true,
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),

                Expanded(
                  flex: 1,
                  child: _buildScreenCard(
                    context,
                    title: languageProvider.getTranslation('name_screen1'),
                    brightnessValue: _nameScreenBrightness,
                    volumeValue: _nameScreenVolume,
                    onBrightnessChanged: (value) {
                      setState(() {
                        _nameScreenBrightness = value;
                      });
                    },
                    onBrightnessChangeEnd: (value) {
                      _bluetoothService.parlaklik(
                        id: '1',
                        value: (value * 100).round().toString(),
                      );
                    },
                    onVolumeChanged: (value) {
                      setState(() {
                        _nameScreenVolume = value;
                      });
                    },
                    onVolumeChangeEnd: (value) {},
                    languageProvider: languageProvider,
                    fillAvailableSpace: true,
                    showVolume: false,
                    isMainScreen: false,
                    screenType: 'name', 
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),

                Expanded(
                  flex: 1,
                  child: _buildScreenCard(
                    context,
                    title: languageProvider.getTranslation('info_screen'),
                    brightnessValue: _infoScreenBrightness,
                    volumeValue: _infoScreenVolume,
                    onBrightnessChanged: (value) {
                      setState(() {
                        _infoScreenBrightness = value;
                      });
                    },
                    onBrightnessChangeEnd: (value) {
                      _bluetoothService.parlaklik(
                        id: '2',
                        value: (value * 100).round().toString(),
                      );
                    },
                    onVolumeChanged: (value) {
                      setState(() {
                        _infoScreenVolume = value;
                      });
                    },
                    onVolumeChangeEnd: (value) {},
                    languageProvider: languageProvider,
                    fillAvailableSpace: true,
                    showVolume: false,
                    isMainScreen: false,
                    screenType: 'info', 
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Column(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.03,
              vertical: screenHeight * 0.02,
            ),
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _buildScreenCard(
                          context,
                          title: languageProvider.getTranslation('main_screen'),
                          brightnessValue: _mainScreenBrightness,
                          volumeValue: _mainScreenVolume,
                          onBrightnessChanged: (value) {
                            setState(() {
                              _mainScreenBrightness = value;
                            });
                          },
                          onBrightnessChangeEnd: (value) {
                            _bluetoothService.parlaklik(
                              id: '0',
                              value: (value * 100).round().toString(),
                            );
                          },
                          onVolumeChanged: (value) {
                            setState(() {
                              _mainScreenVolume = value;
                            });
                          },
                          onVolumeChangeEnd: (value) {
                            _bluetoothService.volume(
                              value: (value * 100).round().toString(),
                            );
                          },
                          languageProvider: languageProvider,
                          isTablet: true,
                          fillAvailableSpace: true,
                          showVolume: true,
                          isMainScreen: true,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Expanded(
                        child: _buildScreenCard(
                          context,
                          title: languageProvider.getTranslation('name_screen1'),
                          brightnessValue: _nameScreenBrightness,
                          volumeValue: 0.0,
                          onBrightnessChanged: (value) {
                            setState(() {
                              _nameScreenBrightness = value;
                            });
                          },
                          onBrightnessChangeEnd: (value) {
                            _bluetoothService.parlaklik(
                              id: '1',
                              value: (value * 100).round().toString(),
                            );
                          },
                          onVolumeChanged: (value) {},
                          onVolumeChangeEnd: (value) {},
                          languageProvider: languageProvider,
                          isTablet: true,
                          fillAvailableSpace: true,
                          showVolume: false,
                          isMainScreen: false,
                          screenType: 'name', 
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Expanded(
                        child: _buildScreenCard(
                          context,
                          title: languageProvider.getTranslation('info_screen'),
                          brightnessValue: _infoScreenBrightness,
                          volumeValue: 0.0,
                          onBrightnessChanged: (value) {
                            setState(() {
                              _infoScreenBrightness = value;
                            });
                          },
                          onBrightnessChangeEnd: (value) {
                            _bluetoothService.parlaklik(
                              id: '2',
                              value: (value * 100).round().toString(),
                            );
                          },
                          onVolumeChanged: (value) {},
                          onVolumeChangeEnd: (value) {},
                          languageProvider: languageProvider,
                          isTablet: true,
                          fillAvailableSpace: true,
                          showVolume: false,
                          isMainScreen: false,
                          screenType: 'info', 
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScreenCard(
      BuildContext context, {
        required String title,
        required double brightnessValue,
        required double volumeValue,
        required ValueChanged<double> onBrightnessChanged,
        required ValueChanged<double> onBrightnessChangeEnd,
        required ValueChanged<double> onVolumeChanged,
        required ValueChanged<double> onVolumeChangeEnd,
        required LanguageProvider languageProvider,
        bool isTablet = false,
        bool fillAvailableSpace = false,
        bool showVolume = true,
        bool isMainScreen = false,
        String screenType = 'normal', 
      }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardPadding = isTablet ? 12.0 : 16.0;

    return Container(
      width: double.infinity,
      height: fillAvailableSpace ? null : null,
      constraints: fillAvailableSpace
          ? BoxConstraints(
        minHeight: showVolume ? 180 : 120,
      )
          : null,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1D7269), width: 2), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: cardPadding,
              vertical: isTablet ? 10 : 12,
            ),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFD0F9F9),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                if (isMainScreen)
                  Image.asset(
                    'assets/images/kursu.png',
                    width: isTablet ? 22 : 24,
                    height: isTablet ? 22 : 24,
                    color: const Color(0xFF1D7269),
                  )
                else if (screenType == 'name')
                  Image.asset(
                    'assets/images/logo2.png',
                    width: isTablet ? 22 : 24,
                    height: isTablet ? 22 : 24,
                    color: const Color(0xFF1D7269),
                  )
                else if (screenType == 'info')
                    Image.asset(
                      'assets/images/3car.png',
                      width: isTablet ? 22 : 24,
                      height: isTablet ? 22 : 24,
                      color: const Color(0xFF1D7269),
                    )
                  else
                    Icon(Icons.devices_other,
                        color: const Color(0xFF1D7269), size: isTablet ? 18 : 20),
                SizedBox(width: isTablet ? 6 : 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1D7269),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: cardPadding,
              vertical: isTablet ? 16 : 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.black, width: 1),
                      ),
                      child: Container(
                        padding: EdgeInsets.all(isTablet ? 12 : 16),
                        color: Colors.white,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: isTablet ? 8 : 10),
                                  Container(
                                    height: isTablet ? 50 : 60,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          final containerWidth = constraints.maxWidth;
                                          return Stack(
                                            children: [
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: AnimatedContainer(
                                                  duration: Duration(milliseconds: 200),
                                                  width: containerWidth * brightnessValue,
                                                  height: double.infinity,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[700],
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                              ),
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Padding(
                                                  padding: EdgeInsets.only(left: isTablet ? 16 : 20),
                                                  child: Text(
                                                    "${(brightnessValue * 100).round()}%",
                                                    style: TextStyle(
                                                      fontSize: isTablet ? 16 : 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned.fill(
                                                child: SliderTheme(
                                                  data: SliderTheme.of(context).copyWith(
                                                    overlayColor: Colors.transparent,
                                                    thumbColor: Colors.transparent,
                                                    activeTrackColor: Colors.transparent,
                                                    inactiveTrackColor: Colors.transparent,
                                                    trackHeight: 0,
                                                    thumbShape: RoundSliderThumbShape(
                                                      enabledThumbRadius: 0,
                                                      disabledThumbRadius: 0,
                                                      elevation: 0,
                                                    ),
                                                  ),
                                                  child: Slider(
                                                    value: brightnessValue,
                                                    min: 0.0,
                                                    max: 1.0,
                                                    onChanged: onBrightnessChanged,
                                                    onChangeEnd: onBrightnessChangeEnd,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: isTablet ? 12 : 16),
                            Image.asset(
                              'assets/images/parlaklik.png',
                              width: isTablet ? 28 : 32,
                              height: isTablet ? 28 : 32,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: isTablet ? 16 : 20,
                      top: -4,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 6 : 8,
                        ),
                        child: Text(
                          "EKRAN PARLAKLIGI",
                          style: TextStyle(
                            fontSize: isTablet ? 12 : 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                if (showVolume) ...[
                  SizedBox(height: isTablet ? 24 : 28),

                  Stack(
                    children: [
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.black, width: 1),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(isTablet ? 12 : 16),
                          color: Colors.white,
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: isTablet ? 8 : 10),
                                    Container(
                                      height: isTablet ? 50 : 60,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: LayoutBuilder(
                                          builder: (context, constraints) {
                                            final containerWidth = constraints.maxWidth;
                                            return Stack(
                                              children: [
                                                Align(
                                                  alignment: Alignment.centerLeft,
                                                  child: AnimatedContainer(
                                                    duration: Duration(milliseconds: 200),
                                                    width: containerWidth * volumeValue,
                                                    height: double.infinity,
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[700],
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                  ),
                                                ),
                                                Align(
                                                  alignment: Alignment.centerLeft,
                                                  child: Padding(
                                                    padding: EdgeInsets.only(left: isTablet ? 16 : 20),
                                                    child: Text(
                                                      "${(volumeValue * 100).round()}%",
                                                      style: TextStyle(
                                                        fontSize: isTablet ? 16 : 18,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Positioned.fill(
                                                  child: SliderTheme(
                                                    data: SliderTheme.of(context).copyWith(
                                                      overlayColor: Colors.transparent,
                                                      thumbColor: Colors.transparent,
                                                      activeTrackColor: Colors.transparent,
                                                      inactiveTrackColor: Colors.transparent,
                                                      trackHeight: 0,
                                                      thumbShape: RoundSliderThumbShape(
                                                        enabledThumbRadius: 0,
                                                        disabledThumbRadius: 0,
                                                        elevation: 0,
                                                      ),
                                                    ),
                                                    child: Slider(
                                                      value: volumeValue,
                                                      min: 0.0,
                                                      max: 1.0,
                                                      onChanged: onVolumeChanged,
                                                      onChangeEnd: onVolumeChangeEnd,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: isTablet ? 12 : 16),
                              Image.asset(
                                'assets/images/ses.png',
                                width: isTablet ? 28 : 32,
                                height: isTablet ? 28 : 32,
                                color: Colors.grey, 
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: isTablet ? 16 : 20,
                        top: -4,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 6 : 8,
                          ),
                          child: Text(
                            languageProvider.getTranslation('volume_level'),
                            style: TextStyle(
                              fontSize: isTablet ? 12 : 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}