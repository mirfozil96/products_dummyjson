import 'dart:async';

import 'package:flash/flash.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../log_helper.dart';

enum ToastType {
  success,
  failure,
  info,
}

extension CheckToastType on ToastType {
  bool get isSuccess => this == ToastType.success;
  bool get isFailure => this == ToastType.failure;
  bool get isInfo => this == ToastType.info;
}

void showTopFlashMessage(ToastType toastType, String message,
    {BuildContext? context}) {
  // if (!mounted) return;
  try {
    final currContext = context ?? Get.context!;
    showFlash(
        context: currContext,
        duration: const Duration(seconds: 3),
        builder: (_, controller) {
          return Flash(
            controller: controller, // Pass your FlashController instance here
            position: FlashPosition.top, // Set the position to top
            child: FlashBar(
              icon: Icon(
                toastType.isFailure
                    ? Icons.close_sharp
                    : toastType.isSuccess
                        ? Icons.check_circle
                        : Icons.priority_high_rounded,
                size: 30,
                color: Colors.black,
              ),
              content: Text(
                message,
                style: const TextStyle(fontSize: 16, color: Colors.black),
              ),
              controller: controller,
            ),
          );
        });
  } catch (e) {
    Log.error('showTopFlashMessage catch error : ($e)');
  }
}

RxBool isTimerRunning = false.obs;

Future<bool> willPopCallBack() async {
  if (!isTimerRunning.value) {
    isTimerRunning.value = true;
    Timer.periodic(const Duration(seconds: 2), (time) {
      isTimerRunning.value = false;
      time.cancel();
    });
    showTopFlashMessage(ToastType.info, 'Press back again to exit');
    return false;
  }
  await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
  return true;
}
