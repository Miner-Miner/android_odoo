import 'package:json_annotation/json_annotation.dart';

part 'login_response.g.dart';

@JsonSerializable()
class LoginResponse {
  final String status;
  final String? message;

  @JsonKey(name: 'user_id')
  final int? userId;

  @JsonKey(name: 'partner_id')
  final int? partnerId;

  @JsonKey(name: 'session_id')
  final String? sessionId;

  LoginResponse({
    required this.status,
    this.message,
    this.userId,
    this.partnerId,
    this.sessionId,
  });

  /// **Custom factory** to read from JSON-RPC `result` field
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'] as Map<String, dynamic>?;

    if (result == null) {
      // fallback in case of error response
      return LoginResponse(
        status: json['error'] != null ? 'error' : 'unknown',
        message: json['error']?['message'] as String? ?? 'Unknown error',
      );
    }

    return _$LoginResponseFromJson(result);
  }

  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
}
