part of proba_sdk_flutter;

String _generateJwt({
  required String sdkToken,
  String? deviceId,
  String? appsFlyerId,
  String? amplitudeUserId,
  Map<String, dynamic>? deviceProperties,
}) {
  final jwt = JWT({
    'deviceId': deviceId,
    if (appsFlyerId?.isNotEmpty ?? false) 'appsFlyerId': appsFlyerId,
    if (amplitudeUserId?.isNotEmpty ?? false) 'amplitudeId': amplitudeUserId,
    if (deviceProperties?.isNotEmpty ?? false)
      'deviceProperties': deviceProperties,
  });
  return jwt.sign(SecretKey(sdkToken), algorithm: JWTAlgorithm.HS256);
}
