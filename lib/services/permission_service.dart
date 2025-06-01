import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// 🚶 Activity Recognition
Future<bool> requestActivityPermission(BuildContext context) async {
  if (!Platform.isAndroid) return true; // iOS doesn't support this

  final status = await Permission.activityRecognition.request();

  if (context.mounted && status.isDenied) {
    _showPermissionDialog(
      context,
      'Activity Recognition',
      'To track steps, please allow Activity Recognition permission.',
    );
  }

  return status.isGranted;
}

/// 📷 Camera
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

/// 🖼️ Gallery Access (Android Scoped Storage / iOS Photos)
Future<bool> requestGalleryPermission(BuildContext context) async {
  Permission permissionToRequest;

  if (Platform.isAndroid) {
    permissionToRequest = Permission.photos; // Scoped access for Android 11+
  } else {
    permissionToRequest = Permission.photos; // iOS Photos
  }

  final status = await permissionToRequest.request();

  if (context.mounted && status.isPermanentlyDenied) {
    _showPermissionDialog(
      context,
      'Gallery',
      'Access to photos is required to choose profile pictures.',
    );
    return false;
  }

  if (context.mounted && status.isDenied) {
    _showPermissionDialog(
      context,
      'Gallery',
      'Access to photos is required to choose profile pictures.',
    );
    return false;
  }

  return status.isGranted;
}

/// ❤️ Heart Rate (BODY_SENSORS)
Future<bool> requestHeartRatePermission(BuildContext context) async {
  if (!Platform.isAndroid) return true; // Not applicable to iOS

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

/// ✅ Request All at Once
Future<void> requestAllPermissions(BuildContext context) async {
  await requestActivityPermission(context);
  await requestHeartRatePermission(context);
  await requestCameraPermission(context);
  await requestGalleryPermission(context);
}

/// 🔁 Reusable dialog + settings redirect
void _showPermissionDialog(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Permission Required: $title'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop();
            await openAppSettings();

            // Optionally auto recheck after delay
            Future.delayed(const Duration(seconds: 1), () {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Returned from settings. Please try again.'),
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
