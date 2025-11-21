import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'language.dart';
import '../screens/settings.dart';
import '../screens/connect.dart';
import '../screens/management.dart';

class ImageWidget extends StatefulWidget {
  final double? height;
  final double? width;
  final BoxFit fit;
  final String activePage;

  const ImageWidget({
    Key? key,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.activePage = "home",
  }) : super(key: key);

  @override
  _ImageWidgetState createState() => _ImageWidgetState();
}

class _ImageWidgetState extends State<ImageWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        bool isConnectPage = widget.activePage == "connect";

        return Container(
          width: widget.width ?? double.infinity,
          height: widget.height ?? 60,
          decoration: BoxDecoration(
            color: Color(0xFF1E2832),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: 150,
                    maxHeight: 40,
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),

                SizedBox(width: 40),

                Container(
                  width: 2,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF4DB6AC).withOpacity(0.2),
                        Color(0xFF4DB6AC),
                        Color(0xFF4DB6AC).withOpacity(0.2),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: 24),

                _buildNavButton(
                  context: context,
                  text: languageProvider.getTranslation('content_management') ?? "İÇERİK YÖNETİMİ",
                  icon: 'assets/images/icerik.png', 
                  isActive: widget.activePage == "management",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Management()),
                    );
                  },
                ),

                SizedBox(width: 16),
                _buildNavButton(
                  context: context,
                  text: languageProvider.getTranslation('settings') ?? "AYARLAR",
                  icon: Icons.settings_outlined, 
                  isActive: widget.activePage == "settings",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsPage()),
                    );
                  },
                ),

                Spacer(),
                _buildIconButton(
                  context: context,
                  icon: 'assets/images/eslestirme.png', 
                  label: languageProvider.getTranslation('pairing') ?? "EŞLEŞTİRME",
                  isActive: isConnectPage,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ConnectPage()),
                    );
                  },
                ),

                SizedBox(width: 12),
                _buildIconButton(
                  context: context,
                  icon: 'assets/images/dil.png', 
                  label: languageProvider.getTranslation('language_selection') ?? "DİL SEÇİMİ",
                  isActive: widget.activePage == "language",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LanguagePage()),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavButton({
    required BuildContext context,
    required String text,
    required dynamic icon, 
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Color(0xFF6D8094) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              
              if (icon is IconData)
                Icon(
                  icon,
                  color: Colors.white,
                  size: 18,
                )
              else if (icon is String)
                Container(
                  width: 18,
                  height: 18,
                  child: Image.asset(
                    icon,
                    color: Colors.white,
                    fit: BoxFit.contain,
                  ),
                ),
              SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0.8,
                  fontFamily: 'Roboto',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required BuildContext context,
    required String icon, 
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? Color(0xFF00D2C8) : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive ? Color(0xFF00D2C8) : Color(0xFF176D63).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                child: Image.asset(
                  icon,
                  color: isActive ? Colors.white : Color(0xFF176D63),
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : Color(0xFF176D63),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  fontFamily: 'Roboto',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}