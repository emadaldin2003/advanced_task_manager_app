class Task {
  String id;
  String userId;
  String title;
  bool isCompleted;
  String category;
  int priority; // 1-5 where 5 is highest
  DateTime? dueDate;
  DateTime? reminder;

  Task({
    required this.id,
    required this.userId,
    required this.title,
    this.isCompleted = false,
    this.category = 'عام',
    this.priority = 3,
    this.dueDate,
    this.reminder,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'isCompleted': isCompleted ? 1 : 0,
      'category': category,
      'priority': priority,
      'dueDate': dueDate?.toIso8601String(),
      'reminder': reminder?.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      isCompleted: map['isCompleted'] == 1,
      category: map['category'],
      priority: map['priority'],
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      reminder: map['reminder'] != null ? DateTime.parse(map['reminder']) : null,
    );
  }
}