/// メールタスク割り当てモデル
class EmailTaskAssignment {
  final String emailId;
  final String emailSubject;
  final String emailBody;
  final String requesterEmail;
  final String requesterName;
  final String taskTitle;
  final String taskDescription;
  final DateTime? dueDate;
  final EmailTaskPriority priority;
  final DateTime receivedAt;
  final String source; // 'gmail' or 'outlook'
  
  const EmailTaskAssignment({
    required this.emailId,
    required this.emailSubject,
    required this.emailBody,
    required this.requesterEmail,
    required this.requesterName,
    required this.taskTitle,
    required this.taskDescription,
    this.dueDate,
    this.priority = EmailTaskPriority.medium,
    required this.receivedAt,
    this.source = 'unknown',
  });
  
  factory EmailTaskAssignment.fromJson(Map<String, dynamic> json) {
    return EmailTaskAssignment(
      emailId: json['emailId'] ?? '',
      emailSubject: json['emailSubject'] ?? '',
      emailBody: json['emailBody'] ?? '',
      requesterEmail: json['requesterEmail'] ?? '',
      requesterName: json['requesterName'] ?? '',
      taskTitle: json['taskTitle'] ?? '',
      taskDescription: json['taskDescription'] ?? '',
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      priority: _parsePriority(json['priority']),
      receivedAt: DateTime.parse(json['receivedAt']),
      source: json['source'] ?? 'unknown',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'emailId': emailId,
      'emailSubject': emailSubject,
      'emailBody': emailBody,
      'requesterEmail': requesterEmail,
      'requesterName': requesterName,
      'taskTitle': taskTitle,
      'taskDescription': taskDescription,
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority.name,
      'receivedAt': receivedAt.toIso8601String(),
      'source': source,
    };
  }
  
  static EmailTaskPriority _parsePriority(String? priorityString) {
    switch (priorityString?.toLowerCase()) {
      case 'high':
      case 'urgent':
      case '緊急':
        return EmailTaskPriority.high;
      case 'low':
      case '低':
        return EmailTaskPriority.low;
      case 'medium':
      case '中':
      default:
        return EmailTaskPriority.medium;
    }
  }
}

/// メールタスク優先度列挙型
enum EmailTaskPriority {
  low,
  medium,
  high,
}
