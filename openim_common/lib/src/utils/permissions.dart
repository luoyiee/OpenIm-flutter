import 'dart:async';
import 'dart:collection';

import 'package:permission_handler/permission_handler.dart';

class Permissions {
  Permissions._();

  static Future<bool> checkSystemAlertWindow() async {
    return await Permission.systemAlertWindow.isGranted;
  }

  static Future<bool> checkStorage() async {
    return await Permission.storage.isGranted;
  }

  static void camera(Function()? onGranted) async {
    if (await Permission.camera.request().isGranted) {
      onGranted?.call();
    }
    if (await Permission.camera.isPermanentlyDenied) {}
  }

  // static void storage(Function()? onGranted) async {
  //   if (await Permission.storage.request().isGranted) {
  //     onGranted?.call();
  //   }
  //   if (await Permission.storage.isPermanentlyDenied) {}
  // }


  static final Queue<Completer<void>> _requestQueue = Queue();

  static Future<void> storage(Function()? onGranted) async {
    final completer = Completer<void>();
    _requestQueue.add(completer);
    if (_requestQueue.length > 1) {
      await completer.future;
    } else {
      await _handleStorageRequest(onGranted);
    }
  }

  static Future<void> _handleStorageRequest(Function()? onGranted) async {
    try {
      var status = await Permission.storage.status;
      if (status.isGranted) {
        onGranted?.call();
      } else if (status.isDenied) {
        var result = await Permission.storage.request();
        if (result.isGranted) {
          onGranted?.call();
        }
      } else if (status.isPermanentlyDenied) {
        // 提示用户去设置页面打开权限
        openAppSettings();
      }
    } finally {
      _requestQueue.removeFirst();
      if (_requestQueue.isNotEmpty) {
        _requestQueue.first.complete();
        await _handleStorageRequest(onGranted);
      }
    }
  }


  static void microphone(Function()? onGranted) async {
    if (await Permission.microphone.request().isGranted) {
      onGranted?.call();
    }
    if (await Permission.microphone.isPermanentlyDenied) {}
  }



  static Future<void> location(Function()? onGranted) async {
    final completer = Completer<void>();
    _requestQueue.add(completer);
    if (_requestQueue.length > 1) {
      await completer.future;
    } else {
      await _handleLocationRequest(onGranted);
    }
  }

  static Future<void> _handleLocationRequest(Function()? onGranted) async {
    try {
      var status = await Permission.location.status;
      if (status.isGranted) {
        onGranted?.call();
      } else if (status.isDenied) {
        var result = await Permission.location.request();
        if (result.isGranted) {
          onGranted?.call();
        }
      } else if (status.isPermanentlyDenied) {
        // 提示用户去设置页面打开权限
        openAppSettings();
      }
    } finally {
      _requestQueue.removeFirst();
      if (_requestQueue.isNotEmpty) {
        _requestQueue.first.complete();
        await _handleLocationRequest(onGranted);
      }
    }
  }


  // static void location(Function()? onGranted) async {
  //   if (await Permission.location.request().isGranted) {
  //     onGranted?.call();
  //   }
  //   if (await Permission.location.isPermanentlyDenied) {}
  // }

  static void speech(Function()? onGranted) async {
    if (await Permission.speech.request().isGranted) {
      onGranted?.call();
    }
    if (await Permission.speech.isPermanentlyDenied) {
    }
  }

  // static void photos(Function()? onGranted) async {
  //   if (await Permission.photos.request().isGranted) {
  //     onGranted?.call();
  //   }
  //   if (await Permission.photos.isPermanentlyDenied) {}
  // }

  static Future<void> photos(Function()? onGranted) async {
    var status = await Permission.photos.status;
    if (status.isGranted) {
      onGranted?.call();
    } else if (status.isDenied) {
      var result = await Permission.photos.request();
      if (result.isGranted) {
        onGranted?.call();
      }
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  static void notification(Function()? onGranted) async {
    if (await Permission.notification.request().isGranted) {
      onGranted?.call();
    }
    if (await Permission.notification.isPermanentlyDenied) {}
  }

  static void ignoreBatteryOptimizations(Function()? onGranted) async {
    if (await Permission.ignoreBatteryOptimizations.request().isGranted) {
      onGranted?.call();
    }
    if (await Permission.ignoreBatteryOptimizations.isPermanentlyDenied) {}
  }

  static void cameraAndMicrophone(Function()? onGranted) async {
    final permissions = [
      Permission.camera,
      Permission.microphone,
    ];
    bool isAllGranted = true;
    for (var permission in permissions) {
      final state = await permission.request();
      isAllGranted = isAllGranted && state.isGranted;
    }
    if (isAllGranted) {
      onGranted?.call();
    }
  }

  static Future<Map<Permission, PermissionStatus>> request(
      List<Permission> permissions) async {
    Map<Permission, PermissionStatus> statuses = await permissions.request();
    return statuses;
  }
}
