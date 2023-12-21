import 'package:json_annotation/json_annotation.dart';

part 'entity.g.dart';

@JsonSerializable()
class FebRtcPeerConfig {
  String? userId;
  bool video, voice, screen, face, hand, stopped = false, silence = false;
  User? user;
  AmplitudeData? amplitude;
  FebRtcPeerConfig({
    this.video = false,
    this.voice = false,
    this.screen = false,
    this.stopped = false,
    this.face = false,
    this.silence = false,
    this.hand = false,
    this.amplitude,
    this.userId,
    this.user,
  });

  factory FebRtcPeerConfig.fromJson(Map<String, dynamic> json) => _$FebRtcPeerConfigFromJson(json);
  Map<String, dynamic> toJson() => _$FebRtcPeerConfigToJson(this);
}

@JsonSerializable()
class AmplitudeData {
  String? updatedAt;
  num? amplitude;
  AmplitudeData({
    this.updatedAt,
    this.amplitude,
  });

  factory AmplitudeData.fromJson(Map<String, dynamic> json) => _$AmplitudeDataFromJson(json);
  Map<String, dynamic> toJson() => _$AmplitudeDataToJson(this);
}


@JsonSerializable()
class User {
  dynamic id;
  String? dname;
  String? uname;
  String? mail;
  String? phone;
  String? code;
  String? token;
  String? password;
  num? type;
  num? gender;
  String? dob;
  String? normalized;
  @JsonKey(name: 'avatar')
  String? wAvatar;
  Map<String, dynamic>? device;
  dynamic business;


  User(
      {this.id,
        this.dname,
        this.uname,
        this.device,
        this.mail,
        this.business,
        this.phone,
        this.wAvatar,
        this.code,
        this.gender,
        this.password,
        this.token,
        this.type,this.dob});

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  static const fromJsonFactory = _$UserFromJson;

  Map<String, dynamic> toJson() => _$UserToJson(this);

  static User get unknown => User(dname: 'Unknown', uname: 'unknown');

}


