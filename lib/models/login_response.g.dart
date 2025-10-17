// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginResponse _$LoginResponseFromJson(Map<String, dynamic> json) =>
    LoginResponse(
      status: json['status'] as String,
      message: json['message'] as String?,
      userId: (json['user_id'] as num?)?.toInt(),
      partnerId: (json['partner_id'] as num?)?.toInt(),
      sessionId: json['session_id'] as String?,
    );

Map<String, dynamic> _$LoginResponseToJson(LoginResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message': instance.message,
      'user_id': instance.userId,
      'partner_id': instance.partnerId,
      'session_id': instance.sessionId,
    };
