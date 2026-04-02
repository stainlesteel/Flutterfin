import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:jellyfin/providers/providers.dart';
import 'package:jellyfin/objects/objects.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:dio/dio.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:jellyfin/pages/pages.dart';

extension LogIn on JellyfinAPI {
  Future<bool> logInByName(
    String user,
    String pwd,
    BuildContext context,
    int index
  ) async {
    late final Response<AuthenticationResult> response;
    try {
      response = await uAPI.authenticateUserByName(
        authenticateUserByName: AuthenticateUserByName(username: user, pw: pwd),
      );
    } on DioException catch (e) {
      print('Login Status Code: ${e.response?.statusCode}');

      List<String> text = [];

      await Future.delayed(Duration(seconds: 1));

      if (e.response!.statusCode == 500) {
        ServerConnectErrorDiag(context);
      } else if (e.response!.statusCode == 503) {
        text = [
          "Server is Down",
          "Server is currently down and is under maintenance or got into an error. Check the URL in your browser for more info.",
        ];
        SimpleErrorDiag(title: text[0], desc: text[1], context: context);
      } else if (e.type == DioExceptionType.badResponse) {
        LogInErrorDiag(context);
      }
      throw DioException; // if this isn't here, the app will load the homepage even if user isn't logged in
      return false;
    }

    final token = response.data?.accessToken;
    if (token != null) {
      await saveUser(token, response.data!.sessionInfo!.userId!, index);
      setUser(UserData(accessToken: token, userId: response.data!.sessionInfo?.userId));
      print('APPCLIENT HEADERS: ${
        appClient.dio.interceptors.firstWhere((i) => i is MediaBrowserAuthInterceptor).token
      }'); 

      return true;
    } else {
      return false;
    }
  }

  void setUser(UserData data) {
    setToken(data.accessToken);
    userID = data.userId;
    notifyListeners();
  }

  void setToken(String? tolkien) {
    appClient.dio.interceptors.firstWhere((i) => i is MediaBrowserAuthInterceptor).token = tolkien;
  }

  // start: functions related to quick connect

  // make request for quick connect to server
  Future<QuickConnectResult?> makeQCRequest(BuildContext context) async {
    late final result;
    try {
      result = await qc.initiateQuickConnect();
    } on DioException catch (e) {
      showDialog(
        context: context,
        builder: (context) => popUpDiag(
          title: 'Quick Connect Error',
          content: [Text('Quick Connect is disabled by this server.')],
        ),
      );
    }

    return result?.data;
  }

  // check if user has accepted quick connect state
  Stream<QuickConnectResult?> getQCState(String secret) async* {
    while (true) {
      try {
        final data = await qc.getQuickConnectState(secret: secret);
        if (data.data?.authenticated == false) {
          await Future.delayed(Duration(seconds: 5));
        } else {
          yield data.data;
          break;
        }
      } catch (e) {
        await Future.delayed(Duration(seconds: 5));
      }
    }
  }

  Future<bool> logInByQC(String res_secret, BuildContext context, int index) async {
    late final response;
    try {
      response = await uAPI.authenticateWithQuickConnect(
        quickConnectDto: QuickConnectDto(secret: res_secret),
      );
      serverList[index].lastLogIsQC = true;

    } on DioException catch (e) {
      late String text;
      print('Login Status Code: ${e.response?.statusCode}');
      if (e.type == DioExceptionType.badResponse) {
        LogInErrorDiag(context);
      } else if (e.response!.statusCode == 500) {
        ServerConnectErrorDiag(context);
      }

      return false;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => StartingPage()),
        (route) => false,
      );
      throw DioException;
    }

    final token = response.data?.accessToken;
    if (token != null) {
      await saveUser(token, response.data!.user!.id!, index);
      await appClient.setToken(
        UserData(
          accessToken: token, 
          userId: response.data!.user?.id,
        )
      );
      userID = response.data!.user?.id;

      serverList[index].userData = UserData(
        accessToken: token, 
        userId: response.data!.user?.id,
      );
      serverList[index].save();
      print('thy token: $token');

      notifyListeners();
      return true;
    } else {
      return false;
    }
  }
  
  Future<bool> authQC(String code) async {
    late bool response;
    try {
      Response<bool> tempData = await qc.authorizeQuickConnect(code: code, userId: userID);
      print('authQC(): calling request now!');
      response = tempData.data!;
      return response;
    } on DioException catch (e) {
      print('authQC(): ${e.message}');
      return false;
    }
    
  }

  // end: functions related to quick connect
}
