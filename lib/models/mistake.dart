class Mistake {
  final int? id;
  final String content;
  final String subject;
  final String questionType;
  final String knowledgePoint;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime lastReviewed;
  final int reviewCount;
  final double difficulty;
  final bool isCompleted;

  Mistake({
    this.id,
    required this.content,
    required this.subject,
    required this.questionType,
    required this.knowledgePoint,
    this.imagePath,
    required this.createdAt,
    required this.lastReviewed,
    this.reviewCount = 0,
    this.difficulty = 0.5,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'subject': subject,
      'questionType': questionType,
      'knowledgePoint': knowledgePoint,
      'imagePath': imagePath,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastReviewed': lastReviewed.millisecondsSinceEpoch,
      'reviewCount': reviewCount,
      'difficulty': difficulty,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory Mistake.fromMap(Map<String, dynamic> map) {
    return Mistake(
      id: map['id'],
      content: map['content'],
      subject: map['subject'],
      questionType: map['questionType'],
      knowledgePoint: map['knowledgePoint'],
      imagePath: map['imagePath'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      lastReviewed: DateTime.fromMillisecondsSinceEpoch(map['lastReviewed']),
      reviewCount: map['reviewCount'],
      difficulty: map['difficulty'],
      isCompleted: map['isCompleted'] == 1,
    );
  }

  Mistake copyWith({
    int? id,
    String? content,
    String? subject,
    String? questionType,
    String? knowledgePoint,
    String? imagePath,
    DateTime? createdAt,
    DateTime? lastReviewed,
    int? reviewCount,
    double? difficulty,
    bool? isCompleted,
  }) {
    return Mistake(
      id: id ?? this.id,
      content: content ?? this.content,
      subject: subject ?? this.subject,
      questionType: questionType ?? this.questionType,
      knowledgePoint: knowledgePoint ?? this.knowledgePoint,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      reviewCount: reviewCount ?? this.reviewCount,
      difficulty: difficulty ?? this.difficulty,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
} 