class MessagePayload {
  String? type, userId;
  Map<String, dynamic>? data;

  MessagePayload({this.type, this.data, this.userId});

  factory MessagePayload.fromJson(dynamic json) {
    return MessagePayload(type: json['type'], data: json['data'], userId: json['userId']);
  }
}
