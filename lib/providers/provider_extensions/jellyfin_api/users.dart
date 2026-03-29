import 'package:jellyfin/providers/providers.dart';
import 'package:jellyfin/objects/objects.dart';
import 'package:dio/dio.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';

extension Users on JellyfinAPI {
  Future<List<UserDto>?> getPublicUsers() async {
    late final _data;
    try {
      _data = await uAPI.getPublicUsers();
    } on DioException catch (e) {
      print(e.response);
    }
    return _data?.data;
  }

  Future<void> saveUser(String token, String userID, int? index) async {
    serverList[index!].userData = serverList[index!].userData ?? UserData();

    serverList[index].userData = UserData(accessToken: token, userId: userID);
    lastUsedServer = index;

    serverList[index].save();
    // ends saving actual user data

    updateServerList();
    notifyListeners();
  }

  Future<UserDto?> getCurrentUser() async {
    late final data;

    try {
      data = await uAPI.getCurrentUser();
    } on DioException catch (e) {
      print('getCurrentUser(): ${e.message}');
      return null;
    }

    return data?.data;
  }
}
