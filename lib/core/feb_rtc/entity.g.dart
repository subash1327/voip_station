// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FebRtcPeerConfig _$FebRtcPeerConfigFromJson(Map<String, dynamic> json) =>
    FebRtcPeerConfig(
      video: json['video'] as bool? ?? false,
      voice: json['voice'] as bool? ?? false,
      screen: json['screen'] as bool? ?? false,
      stopped: json['stopped'] as bool? ?? false,
      face: json['face'] as bool? ?? false,
      silence: json['silence'] as bool? ?? false,
      hand: json['hand'] as bool? ?? false,
      amplitude: json['amplitude'] == null
          ? null
          : AmplitudeData.fromJson(json['amplitude'] as Map<String, dynamic>),
      userId: json['userId'] as String?,
      user: json['user'] == null
          ? null
          : User.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FebRtcPeerConfigToJson(FebRtcPeerConfig instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'video': instance.video,
      'voice': instance.voice,
      'screen': instance.screen,
      'face': instance.face,
      'hand': instance.hand,
      'stopped': instance.stopped,
      'silence': instance.silence,
      'user': instance.user,
      'amplitude': instance.amplitude,
    };

AmplitudeData _$AmplitudeDataFromJson(Map<String, dynamic> json) =>
    AmplitudeData(
      updatedAt: json['updatedAt'] as String?,
      amplitude: json['amplitude'] as num?,
    );

Map<String, dynamic> _$AmplitudeDataToJson(AmplitudeData instance) =>
    <String, dynamic>{
      'updatedAt': instance.updatedAt,
      'amplitude': instance.amplitude,
    };

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: json['id'],
      dname: json['dname'] as String?,
      uname: json['uname'] as String?,
      device: json['device'] as Map<String, dynamic>?,
      mail: json['mail'] as String?,
      business: json['business'],
      phone: json['phone'] as String?,
      wAvatar: json['avatar'] as String?,
      code: json['code'] as String?,
      gender: json['gender'] as num?,
      password: json['password'] as String?,
      token: json['token'] as String?,
      type: json['type'] as num?,
      dob: json['dob'] as String?,
    )..normalized = json['normalized'] as String?;

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'dname': instance.dname,
      'uname': instance.uname,
      'mail': instance.mail,
      'phone': instance.phone,
      'code': instance.code,
      'token': instance.token,
      'password': instance.password,
      'type': instance.type,
      'gender': instance.gender,
      'dob': instance.dob,
      'normalized': instance.normalized,
      'avatar': instance.wAvatar,
      'device': instance.device,
      'business': instance.business,
    };
