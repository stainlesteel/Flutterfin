import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:jellyfin/providers/providers.dart';
import 'package:jellyfin/providers/provider_extensions/jellyfin_api/jellyfin_api.dart';
import 'package:jellyfin/objects/objects.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:dio/dio.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:jellyfin/pages/pages.dart';

extension PostFutures on JellyfinAPI {
  Future<void> stopPlayback(BaseItemDto dto, Duration time) async {
    final timeTicks = time.inTicks;

    final playbackStop = await psAPI.reportPlaybackStopped(
      playbackStopInfo: PlaybackStopInfo(
        item: dto,
        itemId: dto.id,
        positionTicks: timeTicks,
      ),
    );

    print(
      'Stopped PlayBack Session! ITEM ID: ${dto.id}, POSITION TICKS: $timeTicks',
    );
  }

  Future<void> reportPlayback(BaseItemDto dto, Duration time) async {
    final timeTicks = time.inTicks;

    final playbackReport = await psAPI.reportPlaybackProgress(
      playbackProgressInfo: PlaybackProgressInfo(
        item: dto,
        itemId: dto.id,
        positionTicks: timeTicks,
      ),
    );

    print(
      'Reported PlayBack Session! ITEM ID: ${dto.id}, POSITION TICKS: $timeTicks, in seconds: ${time.inSeconds}',
    );
  }

  // stop playback report section

  Future<UserItemDataDto?> markFavorite(String itemId) async {
    final Response<UserItemDataDto> _data = await ulAPI.markFavoriteItem(
      itemId: itemId,
      userId: userID,
    );

    return _data.data;
  }

  Future<UserItemDataDto?> unmarkFavorite(String itemId) async {
    final Response<UserItemDataDto> _data = await ulAPI.unmarkFavoriteItem(
      itemId: itemId,
      userId: userID,
    );

    return _data.data;
  }

  Future<UserItemDataDto?> markPlayed(String itemId) async {
    final Response<UserItemDataDto> _data = await psAPI.markPlayedItem(
      itemId: itemId,
      userId: userID,
    );

    return _data.data;
  }

  Future<UserItemDataDto?> markunPlayed(String itemId) async {
    final Response<UserItemDataDto> _data = await psAPI.markUnplayedItem(
      itemId: itemId,
      userId: userID,
    );

    return _data.data;
  }

  Future<SearchHintResult?> runSearch(String term) async {
    final _data = await seAPI.getSearchHints(
      searchTerm: term,
      userId: userID,
      includeItemTypes: [BaseItemKind.episode, BaseItemKind.movie, BaseItemKind.series],
    );

    return _data.data;
  }

  Future<DioException?> scanLibrary() async {
    try {
      final _data = await lAPI.refreshLibrary();
      return null;
    } on DioException catch (e) {
      return e;
    }
  }

  Future<DioException?> restartServer() async {
    try {
      final _data = await appClient.getSystemApi().restartApplication();
      return null;
    } on DioException catch (e) {
      return e;
    }
  }

  Future<DioException?> shutDownServer() async {
    try {
      final _data = await appClient.getSystemApi().shutdownApplication();
      return null;
    } on DioException catch (e) {
      return e;
    }
  }

  Future<void> updateConfiguration(ServerConfiguration config) async { 
    try {
      final _data = await appClient.getConfigurationApi().updateConfiguration(
        serverConfiguration: config,
      );
    } on DioException catch (e) {
      print('updateConfiguration: ${e.message}');
    }
  }

  Future<void> updateBrandingConfiguration(BrandingOptionsDto config) async { 
    try {
      final _data = await appClient.getConfigurationApi().updateBrandingConfiguration(
        brandingOptionsDto: config,
      );
    } on DioException catch (e) {
      print('updateBrandingConfiguration: ${e.message}');
    }
  }

  Future<void> deleteCustomSplashscreen() async { 
    try {
      final _data = await appClient.getImageApi().deleteCustomSplashscreen();
    } on DioException catch (e) {
      print('deleteCustomSplashscreen: ${e.message}');
    }
  }

  Future<void> makeUser({required String name, String? pwd, bool enableAllFolders = false, List<BaseItemDto>? enabledFolderIds}) async {
    List<String> foldersIds = []; 

    if (enabledFolderIds != null) {
      enabledFolderIds!.forEach(
        (dto) {
          foldersIds.add(dto.id!);
        }
      );
    }

    try {
      final Response<UserDto> _data = await appClient.getUserApi().createUserByName(
        createUserByName: CreateUserByName(name: name, password: pwd),
      );

      await updateUser(
        dto: _data.data!.copyWith(
          policy: _data.data!.policy!.copyWith(
            enableAllFolders: enableAllFolders,
            enabledFolders: foldersIds,
          ),
        ),
        policy: _data.data!.policy!.copyWith(
          enableAllFolders: enableAllFolders,
          enabledFolders: foldersIds,
        ),
      );
    } on DioException catch (e) {
      print('makeUser: ${e.message}');
    }

    pwd = null;
  }

  Future<DioException?> updateUser({required UserDto dto, required UserPolicy policy}) async {
    try {
      await appClient.getUserApi().updateUser(
        userId: dto.id,
        userDto: dto,
      );
      await appClient.getUserApi().updateUserPolicy(
        userId: dto.id!, 
        userPolicy: policy,
      );
    } on DioException catch (e) {
      print('updateUserPolicy: ${e.message}');
      return e;
    }
  }

  Future<DioException?> deleteUser({required String userId}) async { 
    try {
      final _data = await appClient.getUserApi().deleteUser(
        userId: userId,
      );
    } on DioException catch (e) {
      print('deleteUser: ${e.message}');
      return e;
    }
  }

  Future<DioException?> updateUserPassword({required String newPw, String? currentPw, required String userId}) async {
    try {
      final _data = await appClient.getUserApi().updateUserPassword(
        updateUserPassword: UpdateUserPassword(
          newPw: newPw,
        ),
        userId: userId,
      );
      return null;
    } on DioException catch (e) {
      print('deleteUser: ${e.response?.data}');
      return e;
    }
  }

  Future<DioException?> deleteDevice(String id) async {
    try {
      final _data = await JellyfinDart().getDevicesApi().deleteDevice(id: id);
      return null;
    } on DioException catch (e) {
      print('deleteUser: ${e.response?.data}');
      return e;
    }
  }
}
