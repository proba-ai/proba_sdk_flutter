part of proba_sdk_flutter;

class _Client {
  static const _host = 'api.proba.ai';
  static const _experimentsEndpoint = '/api/mobile/experiments';
  static const _experimentsOptionsEndpoint = '/api/mobile/experiments/options';

  Map<String, String> _headers;

  _Client({
    @required String sdkToken,
    @required String appId,
    String deviceId,
    String appsFlyerId,
    String amplitudeUserId,
    Map<String, dynamic> deviceProperties,
  }) {
    assert(sdkToken != null);
    assert(appId != null);

    final jwt = _generateJwt(
      sdkToken: sdkToken,
      amplitudeUserId: amplitudeUserId,
      appsFlyerId: appsFlyerId,
      deviceId: deviceId,
      deviceProperties: deviceProperties,
    );
    _headers = {
      'Authorization': 'Bearer $jwt',
      'SDK-App-ID': appId,
    };
  }

  Future<Map<String, dynamic>> loadExperiments({
    @required List<String> knownExperimentsKeys,
  }) async {
    final result = await _performRequest(
      endpoint: _experimentsEndpoint,
      knownExperimentsKeys: knownExperimentsKeys,
    );
    return Map<String, dynamic>.from(result);
  }

  Future<List<Map<String, dynamic>>> loadExperimentsOptions({
    @required List<String> knownExperimentsKeys,
  }) async {
    final result = await _performRequest(
      endpoint: _experimentsOptionsEndpoint,
      knownExperimentsKeys: knownExperimentsKeys,
    );
    return List<Map<String, dynamic>>.from(result['experiments']);
  }

  Future<dynamic> _performRequest({
    @required String endpoint,
    @required List<String> knownExperimentsKeys,
  }) async {
    final uri = Uri(
      scheme: 'https',
      host: _host,
      path: endpoint,
      query: knownExperimentsKeys.map<String>((k) => "knownKeys[]=$k").join('&')
    );
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode != 200) _throwError(response);

    return jsonDecode(response.body);
  }

  void _throwError(http.Response response) {
    final message = """
      Proba SDK request error.
      Status Code: ${response.statusCode}.
      Body: ${response.body}.
    """;
    throw (message);
  }
}
