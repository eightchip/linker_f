import 'package:hive/hive.dart';

part 'sent_mail_log.g.dart';

@HiveType(typeId: 10)
class SentMailLog {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String taskId;
  @HiveField(2)
  final String app; // 'gmail' | 'outlook'
  @HiveField(3)
  final String token;
  @HiveField(4)
  final String to;
  @HiveField(5)
  final String cc;
  @HiveField(6)
  final String bcc;
  @HiveField(7)
  final String subject;
  @HiveField(8)
  final String body;
  @HiveField(9)
  final DateTime composedAt;

  SentMailLog({
    required this.id,
    required this.taskId,
    required this.app,
    required this.token,
    required this.to,
    required this.cc,
    required this.bcc,
    required this.subject,
    required this.body,
    required this.composedAt,
  });

  SentMailLog copyWith({
    String? id,
    String? taskId,
    String? app,
    String? token,
    String? to,
    String? cc,
    String? bcc,
    String? subject,
    String? body,
    DateTime? composedAt,
  }) {
    return SentMailLog(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      app: app ?? this.app,
      token: token ?? this.token,
      to: to ?? this.to,
      cc: cc ?? this.cc,
      bcc: bcc ?? this.bcc,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      composedAt: composedAt ?? this.composedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'app': app,
      'token': token,
      'to': to,
      'cc': cc,
      'bcc': bcc,
      'subject': subject,
      'body': body,
      'composedAt': composedAt.toIso8601String(),
    };
  }

  factory SentMailLog.fromJson(Map<String, dynamic> json) {
    return SentMailLog(
      id: json['id'],
      taskId: json['taskId'],
      app: json['app'],
      token: json['token'],
      to: json['to'],
      cc: json['cc'],
      bcc: json['bcc'],
      subject: json['subject'],
      body: json['body'],
      composedAt: DateTime.parse(json['composedAt']),
    );
  }

  @override
  String toString() {
    return 'SentMailLog(id: $id, taskId: $taskId, app: $app, token: $token, to: $to, cc: $cc, bcc: $bcc, subject: $subject, body: $body, composedAt: $composedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SentMailLog && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
