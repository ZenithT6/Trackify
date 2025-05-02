import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// 🚶 Activity Recognition Permission
Future<void> requestActivityPermission(BuildContext context) async {
  final status = await Permission.activityRecognition.request();

  if (context.mounted && status.isDenied) {
    _showPermissionDialog(
      context,
      'Activity Recognition',
      'To track steps, please allow Activity Recognition permission.',
    );
  }
}

/// 📷 Camera Permission
Future<bool> requestCameraPermission(BuildContext context) async {
  final status = await Permission.camera.request();

  if (context.mounted && status.isPermanentlyDenied) {
    _showPermissionDialog(
      context,
      'Camera',
      'Camera access is required to take profile pictures.',
    );
    return false;
  }

  if (context.mounted && status.isDenied) {
    _showPermissionDialog(
      context,
      'Camera',
      'Camera access is required to take profile pictures.',
    );
    return false;
  }

  return status.isGranted;
}

/// 🖼️ Gallery Permission (Storage on Android 11)
Future<bool> requestGalleryPermission(BuildContext context) async {
  final status = await Permission.storage.request();

  if (context.mounted && status.isPermanentlyDenied) {
    _showPermissionDialog(
      context,
      'Gallery',
      'Storage access is required to choose profile pictures.',
    );
    return false;
  }

  if (context.mounted && status.isDenied) {
    _showPermissionDialog(
      context,
      'Gallery',
      'Storage access is required to choose profile pictures.',
    );
    return false;
  }

  return status.isGranted;
}

/// ❤️ Heart Rate Permission (BODY_SENSORS)
Future<bool> requestHeartRatePermission(BuildContext context) async {
  final status = await Permission.sensors.request();

  if (context.mounted && status.isPermanentlyDenied) {
    _showPermissionDialog(
      context,
      'Heart Rate',
      'To monitor heart rate, please enable BODY SENSORS permission.',
    );
    return false;
  }

  if (context.mounted && status.isDenied) {
    _showPermissionDialog(
      context,
      'Heart Rate',
      'To monitor heart rate, please enable BODY SENSORS permission.',
    );
    return false;
  }

  return status.isGranted;
}

/// 🔁 Reusable dialog and retry prompt after opening settings
void _showPermissionDialog(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Permission Required: $title'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            openAppSettings().then((_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Permission updated. Please try again.'),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            });
          },
          child: const Text('Open Settings'),
        ),
      ],
    ),
  );
}
