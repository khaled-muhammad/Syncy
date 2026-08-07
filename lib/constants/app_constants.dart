import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

const List<String> imageExtensions = ['jpg', 'jpeg', 'png', 'webp', 'tiff'];

/// Video containers that Syncy can discover on-device.
///
/// Actual playback still depends on the codecs available on the device. Keep
/// these values lowercase because discovery normalizes file extensions.
const List<String> videoExtensions = [
  'mp4',
  'm4v',
  'mov',
  'qt',
  'webm',
  'mkv',
  'avi',
  '3gp',
  '3g2',
  'ts',
  'mts',
  'm2ts',
  'mpg',
  'mpeg',
  'mpe',
  'vob',
  'ogv',
  'flv',
  'f4v',
  'wmv',
  'asf',
  'rm',
  'rmvb',
];

final List<String> mediaExtensions = imageExtensions + videoExtensions;

class AppConstants {
  // API URLs
  static const String baseDomain = 'syncy-backend.mywire.org';

  static const String baseUrl = 'https://$baseDomain';
  static const String apiBaseUrl = '$baseUrl/api';
  static final Dio dio = Dio(BaseOptions(baseUrl: apiBaseUrl));

  static const String wssBaseUrl = 'wss://$baseDomain/ws';

  static String roomInviteUrl(String roomReference) =>
      '$baseUrl/join/${Uri.encodeComponent(roomReference)}';

  // API Endpoints
  static const String loginEndpoint = '$apiBaseUrl/auth/login';
  static const String registerEndpoint = '$apiBaseUrl/auth/register';
  static const String userProfileEndpoint = '$apiBaseUrl/user/profile';

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String isDarkModeKey = 'is_dark_mode';
  static const String notificationsEnabledKey = 'notifications_enabled';
  static const String syncFrequencyKey = 'sync_frequency';

  // App Settings
  static const String appName = 'Syncy';
  static const String appVersion = '1.0.9';

  // Colors
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color accentColor = Color(0xFF03A9F4);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color infoColor = Color(0xFF2196F3);

  // Durations
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration toastDuration = Duration(seconds: 3);
  static const Duration animationDuration = Duration(milliseconds: 300);

  // Sizes
  static const double borderRadius = 8.0;
  static const double buttonHeight = 50.0;
  static const double iconSize = 24.0;

  // Paddings
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
}
