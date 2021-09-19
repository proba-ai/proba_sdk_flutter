library proba_sdk_flutter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shake/shake.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'dart:convert';

part 'client.dart';
part 'storage.dart';
part 'jwt.dart';
part 'debug.dart';
part 'experiments.dart';
part 'debug_widget.dart';

typedef void ExperimentsChangedCallback(List<String> changedKeys);

class Proba {
  static Proba _instance;

  _Storage _storage = _Storage();
  _Client _client;
  _Experiments _experiments;
  _ProbaDebug _debug;
  bool _isDebugAllowed = false;

  static Future<void> initialize({
    @required String sdkToken,
    @required String appId,
    String deviceId,
    String appsFlyerId,
    String amplitudeUserId,
    @required Map<String, String> defaults,
    Map<String, dynamic> deviceProperties,
  }) async {
    assert(_instance == null, 'Proba SDK is already initialized.');

    final instance = Proba._internal();
    await instance._storage.initialize();
    instance._experiments = _Experiments(
      storage: instance._storage,
      defaults: defaults,
    );
    deviceId ??= instance._fetchDeviceId();
    instance._client = _Client(
      appId: appId,
      sdkToken: sdkToken,
      deviceId: deviceId,
      appsFlyerId: appsFlyerId,
      amplitudeUserId: amplitudeUserId,
      deviceProperties: deviceProperties,
    );
    _instance = instance;
  }

  Proba._internal();
  factory Proba.instance() => _instance;

  bool get isDebugAllowed => _isDebugAllowed;

  Map<String, String> get experiments {
    final current = _experiments.experiments ?? _experiments.defaultExperiments;
    if (!isDebugAllowed) {
      return current;
    }
    return Map.unmodifiable(Map.from(current)..addAll(_debug.debugExperiments));
  }

  Map<String, String> get experimentsWithDetails =>
      _experiments.detailedExperiments;
  String experiment(String key) => _isDebugAllowed
      ? _debug.debugExperiments[key] ?? experiments[key]
      : experiments[key];

  Future<void> showDebugLayer({
    @required BuildContext context,
    ExperimentsChangedCallback valuesChangedCallback,
  }) async {
    assert(isDebugAllowed);
    if (!_isDebugAllowed) return;

    return _debug.showDebugLayer(
      context: context,
      valuesChangedCallback: valuesChangedCallback,
      experiments: _experiments.experiments,
    );
  }

  void enableDebugOnShake({
    @required BuildContext context,
    ExperimentsChangedCallback valuesChangedCallback,
  }) {
    assert(isDebugAllowed);
    if (!_isDebugAllowed) return;

    _debug.enableDebugOnShake(
      context: context,
      valuesChangedCallback: valuesChangedCallback,
      experiments: _experiments.experiments,
    );
  }

  void disableDebugOnShake() {
    assert(isDebugAllowed);
    if (!_isDebugAllowed) return;

    _debug.disableDebugOnShake();
  }

  Future<void> loadExperiments([ExperimentsChangedCallback callback]) async {
    final loadedData = await _client.loadExperiments(
        knownExperimentsKeys: experiments.keys.toList(growable: false));

    _isDebugAllowed = loadedData['meta']['debug'];
    if (_isDebugAllowed) {
      _debug ??= _ProbaDebug(client: _client);
    } else {
      _debug?.disableDebugOnShake();
    }

    final loadedExperiments = loadedData['experiments'];
    if (loadedExperiments?.isEmpty ?? true) return;

    _experiments.update(loadedExperiments);
    if (callback != null) {
      callback(experiments.keys.toList(growable: false));
    }
  }

  String _fetchDeviceId() {
    String deviceId = _storage.readDeviceId();
    if (deviceId?.isNotEmpty ?? false) return deviceId;

    deviceId = Uuid().v4();
    _storage.writeDeviceId(deviceId);
    return deviceId;
  }
}
