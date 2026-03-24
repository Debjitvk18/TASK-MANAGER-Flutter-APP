class Task {
  final int id;
  final String title;
  final String description;
  final String dueDate;
  final String status;
  final int? blockedBy;
  final String? isRecurring;
  final int sortOrder;
  final bool isBlocked;
  final String? blockerTitle;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    this.blockedBy,
    this.isRecurring,
    required this.sortOrder,
    this.isBlocked = false,
    this.blockerTitle,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dueDate: json['due_date'],
      status: json['status'],
      blockedBy: json['blocked_by'],
      isRecurring: json['is_recurring'],
      sortOrder: json['sort_order'],
      isBlocked: json['is_blocked'] ?? false,
      blockerTitle: json['blocker_title'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'due_date': dueDate,
      'status': status,
      'blocked_by': blockedBy,
      'is_recurring': isRecurring,
    };
  }

  Task copyWith({
    int? id,
    String? title,
    String? description,
    String? dueDate,
    String? status,
    int? blockedBy,
    String? isRecurring,
    int? sortOrder,
    bool? isBlocked,
    String? blockerTitle,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      blockedBy: blockedBy ?? this.blockedBy,
      isRecurring: isRecurring ?? this.isRecurring,
      sortOrder: sortOrder ?? this.sortOrder,
      isBlocked: isBlocked ?? this.isBlocked,
      blockerTitle: blockerTitle ?? this.blockerTitle,
    );
  }
}
