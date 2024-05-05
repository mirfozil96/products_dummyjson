// Author - Rashmin Dungrani

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' as getx;
import 'package:http/http.dart';

import '../../app/data/api_paths.dart';
import '../app_loader.dart';
import '../log_helper.dart';
import '../widgets/toast.dart';
import 'api_error_msg.dart';
import 'network_info.dart';

enum HttpMethod {
  post,
  get,
  delete,
  patch,
  put,
  multipartPost,
}

extension HttpMethodExtension on HttpMethod {
  String get contentType {
    switch (this) {
      case HttpMethod.post:
        return 'application/x-www-form-urlencoded';
      case HttpMethod.get:
        return 'application/json';
      case HttpMethod.delete:
        return 'application/json';
      case HttpMethod.patch:
        return 'application/x-www-form-urlencoded';
      case HttpMethod.multipartPost:
        return 'application/x-www-form-urlencoded';
      default:
        return 'application/json';
    }
  }
}

late final NetworkInfo networkInfo;

class ApiHelper {
  final String serviceName;
  final String endPoint;
  final String baseUrl;
  // final bool headerToken;
  // final bool useHeaderAccesskey;
  // final bool useHeaderSecretkey;

  final bool checkInternet;
  final bool showOverlay;
  final bool showTransparentOverlay;
  final bool showErrorDialog;
  final bool printRequest;
  final bool printResponse;
  final bool printHeaders;

  final Map<String, String>? additionalHeader;
  final Map<String, String>? useOnlyThisHeader;
  final int requestTimeoutSeconds;

  ApiHelper({
    required this.endPoint,
    this.baseUrl = ApiPaths.apiBaseUrl,
    this.serviceName = ' ',
    // this.headerToken = true,
    // this.useHeaderAccesskey = true,
    // this.useHeaderSecretkey = true,
    this.showOverlay = false,
    this.showTransparentOverlay = false,
    this.showErrorDialog = false,
    this.checkInternet = true,
    this.printRequest = true,
    this.printResponse = false,
    this.printHeaders = false,
    this.additionalHeader,
    this.useOnlyThisHeader,
    this.requestTimeoutSeconds = 60,
  });

  String get url => baseUrl + endPoint;

  Future<Either<Map<String, dynamic>, Map<String, dynamic>>> get() async {
    final result = await _execute(HttpMethod.get, {});

    return result.fold(
      (l) => Left(l.cleanDecodedReponse),
      (r) => Right(r.cleanDecodedReponse),
    );
  }

  Future<Either<Map<String, dynamic>, Map<String, dynamic>>> post({
    required Map<String, dynamic> body,
    bool isFormData = false,
  }) async {
    final result =
        await _execute(HttpMethod.post, body, isFormData: isFormData);

    return result.fold(
      (l) => Left(l.cleanDecodedReponse),
      (r) {
        return Right(r.cleanDecodedReponse);
      },
    );
  }

  Future<Either<Map<String, dynamic>, Map<String, dynamic>>> put(
      {required Map<String, dynamic> body}) async {
    final result = await _execute(HttpMethod.put, body);

    return result.fold(
      (l) => Left(l.cleanDecodedReponse),
      (r) => Right(r.cleanDecodedReponse),
    );
  }

  Future<Either<Map<String, dynamic>, Map<String, dynamic>>> patch(
      {required Map<String, dynamic> body}) async {
    final result = await _execute(HttpMethod.patch, body);

    return result.fold(
      (l) => Left(l.cleanDecodedReponse),
      (r) => Right(r.cleanDecodedReponse),
    );
  }

  Future<Either<Map<String, dynamic>, Map<String, dynamic>>> delete() async {
    final result = await _execute(HttpMethod.delete, {});

    return result.fold(
      (l) => Left(l.cleanDecodedReponse),
      (r) => Right(r.cleanDecodedReponse),
    );
  }

  Future<Either<Map<String, dynamic>, Map<String, dynamic>>> postMultipart({
    required Map<String, String> body,
    Map<String, File>? imageFile,
  }) async {
    final result =
        await _execute(HttpMethod.multipartPost, body, imageFileMap: imageFile);

    return result.fold(
      (l) => Left(l.cleanDecodedReponse),
      (r) {
        return Right(r.cleanDecodedReponse);
      },
    );
  }

  Future<Either<Response, Response>> _execute(
      HttpMethod method, Map<String, dynamic> body,
      {Map<String, File>? imageFileMap, bool isFormData = false}) async {
    _printApiDetial(method: method, body: body);
    if (showTransparentOverlay) {
      LoadingOverlay.of(getx.Get.context!).showTransparent();
    } else if (showOverlay) {
      LoadingOverlay.of(getx.Get.context!).show();
    }
    if (checkInternet && !await networkInfo.checkIsConnected) {
      if (showOverlay || showTransparentOverlay) {
        LoadingOverlay.of(getx.Get.context!).hide();
      }

      showTopFlashMessage(ToastType.info, 'No internet');
      return Left(Response('', 400));
    }

    Response response;
    StreamedResponse? streamedResponse;

    try {
      switch (method) {
        case HttpMethod.post:
          response = await Client()
              .post(
                Uri.parse(url),
                headers: await getHeaders(method),
                body: isFormData ? body : jsonEncode(body),
              )
              .timeout(Duration(seconds: requestTimeoutSeconds),
                  onTimeout: () => throw TimeoutException(null));
          break;
        case HttpMethod.get:
          response = await Client()
              .get(
                Uri.parse(url),
                headers: await getHeaders(method),
              )
              .timeout(Duration(seconds: requestTimeoutSeconds),
                  onTimeout: () => throw TimeoutException(null));
          break;
        case HttpMethod.patch:
          response = await Client()
              .patch(
                Uri.parse(url),
                headers: await getHeaders(method),
                body: body,
              )
              .timeout(Duration(seconds: requestTimeoutSeconds),
                  onTimeout: () => throw TimeoutException(null));
          break;
        case HttpMethod.put:
          response = await Client()
              .put(
                Uri.parse(url),
                headers: await getHeaders(method),
                body: body,
              )
              .timeout(Duration(seconds: requestTimeoutSeconds),
                  onTimeout: () => throw TimeoutException(null));
          break;
        case HttpMethod.delete:
          response = await Client()
              .delete(
                Uri.parse(url),
                headers: await getHeaders(method),
              )
              .timeout(Duration(seconds: requestTimeoutSeconds),
                  onTimeout: () => throw TimeoutException(null));
          break;
        case HttpMethod.multipartPost:
          final request = MultipartRequest("POST", Uri.parse(url));
          // convert Map<String, dynamic> to Map<String, String>
          final Map<String, String> stringMap = {};
          body.forEach((key, value) {
            stringMap[key] = value.toString();
          });
          request.headers.addAll(await getHeaders(method));
          // print(request.headers);
          request.fields.addAll(stringMap);
          Log.info('*** imageFileMap ***');
          Log.info(imageFileMap);
          if (imageFileMap != null) {
            imageFileMap.forEach((fieldName, imageFile) async {
              Log.info('$fieldName added');
              // from Map<String, File> every image and field_name will add to request files
              request.files.add(
                await MultipartFile.fromPath(
                  fieldName, imageFile.path,
                  // contentType: MediaType('image', 'jpg')
                ),
              );
            });
          }

          streamedResponse = await request
              .send()
              .timeout(Duration(seconds: requestTimeoutSeconds));

          final resbody = await streamedResponse.stream.bytesToString();
          // convert StreamResponse (which uses MultipartRequest) to Response (http)
          response = Response(resbody, streamedResponse.statusCode,
              headers: streamedResponse.headers);
          break;
      }
    } on TimeoutException {
      Log.error('timeout exception thrown');
      response = Response("Request Timeout",
          408); // 408 is Request Timeout response status code
      // set body message to request timeout in network info class
      networkInfo.isConnected = false;
      networkInfo.requestStatus = EnumRequestStatus.requestTimeout;
    } catch (e) {
      Log.error(e);
      response = Response(
          e.toString(), 600); // 600 is i just takes as a socket exception
    }

    if (showOverlay || showTransparentOverlay) {
      LoadingOverlay.of(getx.Get.context!).hide();
    }

    _printResponse(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = response.cleanDecodedReponse;
      return Right(response);
      // ! this is project wise conditions
      if (decoded.hasStatusNum(1) ||
          decoded.containsKey('encrypted_value') ||
          baseUrl != ApiPaths.apiBaseUrl) {
        return Right(response);
      } else if (decoded.hasStatusNum(2) &&
          decoded.containsKey('message') &&
          decoded['message'] == 'Malicious source detected') {
        // {status: 2, message: Malicious source detected}
        // ! CLEAR AND NAVIGATE WELCOME

        //   I/flutter (16256): xVEG8UKL18MlfDWGlUCNsOhqaZRHK6Dq/etpQM8usxOxlJPEUe7qWikGep8ENtIy
        // I/flutter (16256): 12jqjq7JNKI+cC3ByIUc3g==_+Si1hxlL0RsSFMQrcjLw/A==

        // print(decoded);
        // print(url);
        showTopFlashMessage(ToastType.failure, "Session expired!");

        return Left(response);
      } else {
        if (showErrorDialog) {
          Log.info(decoded);
          if (decoded.hasMessage && decoded['message'] != 'Invalid API key') {
            showTopFlashMessage(ToastType.failure,
                decoded['message'] ?? "Something went wrong");
          }
        }
        return Left(response);
      }
    } else {
      _showApiErrorDialog(response);
      return Left(response);
    }
  }

  Future<Map<String, String>> getHeaders(HttpMethod method) async {
    final Map<String, String> headers = {};
    headers['Content-Type'] = method.contentType;

    if (useOnlyThisHeader != null) {
      headers.addAll(useOnlyThisHeader!);
      return headers;
    }

    headers['User-Agent'] = Platform.isIOS ? 'iOS' : 'Android';
    headers['devicetype'] = Platform.isIOS ? '1' : '2';
    // headers['devicetoken'] = GSAPIHeaders.fcmToken ?? '123456';
    // headers['accesskey'] = GSAPIHeaders.accesskey ?? 'nousername';

    // if (useHeaderSecretkey) {

    if (additionalHeader != null) {
      headers.addAll(additionalHeader!);
    }

    if (printHeaders) {
      Log.error('*** HEADER in ${endPoint} API ***');
      Log.error(headers.toPrettyString());
    }

    return headers;
  }

  // API info...
  void _printApiDetial({
    required HttpMethod method,
    required Map<String, dynamic> body,
  }) {
    if (kReleaseMode || printRequest == false) return;
    Log.info("""

╔════════════════════════════════════════════════════════════════════════════╗
║     API REQUEST                                                            ║
╠════════════════════════════════════════════════════════════════════════════╣
║ Type   :- ${method.name}
║ URL    :- $url
║ Params :- ${jsonEncode(body)}
╚════════════════════════════════════════════════════════════════════════════╝
""");
  }

  // API resposne info...
  void _printResponse(Response response) {
    late final String responseBody;
    if (printResponse) {
      try {
        responseBody = Map<String, dynamic>.from(jsonDecode(response.body))
            .toPrettyString();
      } catch (e) {
        Log.error("-- RESPONSE BODY IS NOT PROPER in ${endPoint} API --");
        responseBody = response.body;
      }
    }
    if (printResponse &&
        response.statusCode >= 200 &&
        response.statusCode < 300) {
      Log.success("""
╔════════════════════════════════════════════════════════════════════════════╗
║      API RESPONSE                                                          ║
╠════════════════════════════════════════════════════════════════════════════╣
║ API        :- $endPoint
║ StatusCode :- ${response.statusCode}
║ Response   :- 

${responseBody}

╚════════════════════════════════════════════════════════════════════════════╝
""");
    } else if (printResponse) {
      Log.error("""
╔════════════════════════════════════════════════════════════════════════════╗
║      API RESPONSE                                                          ║
╠════════════════════════════════════════════════════════════════════════════╣
║ API        :- $endPoint
║ StatusCode :- ${response.statusCode}
║ Response   :- 

${responseBody}

╚════════════════════════════════════════════════════════════════════════════╝
""");
    }
  }

  void _showApiErrorDialog(Response response) {
    try {
      if (showErrorDialog) {
        if (response.statusCode == 600) {
          // errorDialog(
          //     title: APIErrorMsg.underMaintainanceTitle,
          //     message: APIErrorMsg.httpErrorMsg);
          return;
        }
        if (response.statusCode == 408) {
          showTopFlashMessage(
              ToastType.failure, APIErrorMsg.requestTimeOutTitle);
          return;
        }
        if (response.body.isEmpty) {
          Log.error('Response body is empty');
          showTopFlashMessage(
              ToastType.failure, APIErrorMsg.somethingWentWrong);
          return;
        }
        final decoded = jsonDecode(response.body);
        if (decoded.containsKey('error')) {
          final String errorTypeKey = decoded['error'].keys.toList()[0];
          // errorDialog(title: decoded['error'][errorTypeKey][0]);
        } else if (decoded.containsKey('data') &&
            (decoded['data'].containsKey('errors') ||
                decoded['data'].containsKey('error'))) {
          String errorName = 'errors';
          if (decoded['data'].containsKey('error')) {
            errorName = 'error';
          }
          final String errorTypeKey =
              decoded['data'][errorName].keys.toList()[0];
          // errorDialog(title: decoded['data'][errorName][errorTypeKey][0]);
        } else if (decoded.containsKey('message')) {
          // errorDialog(title: decoded['message']);
        } else {
          Log.error(
              "*******  Error key not contains so not showing errorDialog ********");
          Log.error('decoded = $decoded');
        }
      }
    } catch (e, stacktrace) {
      Log.error(
          '-------------- stacktrace _showApiErrorDialog ----------------');
      Log.error(stacktrace);
    }
  }
}

extension APIResponse on Response? {
  Map<String, dynamic> get cleanDecodedReponse {
    if (this == null) return {};
    try {
      return jsonDecode(this!.body.removeNotice);
    } catch (e, stacktrace) {
      Log.error("**** While Decoding API response");
      Log.error("response");
      Log.error(this!.body);
      Log.error("** stacktrace **");
      Log.error(stacktrace);
      throw Exception("While decoding API response");
    }
  }
}

extension APIBody on String? {
  String get removeNotice {
    if (this == null) {
      return "{}";
    }
    if (this!.startsWith('{') || this!.startsWith('[')) {
      return this!;
    }
    final startIndex = this!.indexOf('{');
    if (startIndex == -1) {
      // debugPrint("not starting with {");
      Log.info(this);
      return "{}";
    }
    return this!.substring(startIndex);
  }
}

extension APIMapBody on Map<String, dynamic> {
  bool hasStatusNum(int value, {bool printStatus = false}) {
    if (containsKey('status')) {
      final result = this['status'].toString() == value.toString();
      if (printStatus) {
        Log.info('API body status - ${this['status']}');
      }
      return result;
    }
    // print('hasStatusNumber - status param not contain');
    return false;
  }

  bool get hasMessage {
    return containsKey('message');
  }

  String toPrettyString() {
    var encoder = const JsonEncoder.withIndent("     ");
    return encoder.convert(this);
  }
}
