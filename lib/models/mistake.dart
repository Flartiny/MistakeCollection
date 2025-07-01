/// 错题数据模型，包含内容、学科、题型、知识点、图片、时间、复习等属性
class Mistake {
  final int? id; // 主键，自增
  final String content; // 题目内容
  final String subject; // 学科
  final String questionType; // 题型
  final String knowledgePoint; // 知识点
  final String? imagePath; // 图片路径
  final DateTime createdAt; // 创建时间
  final DateTime lastReviewed; // 上次复习时间
  final int reviewCount; // 复习次数
  final double difficulty; // 难度系数
  final bool isCompleted; // 是否已完成

  /// 构造函数，支持必填和可选字段
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

  /// 转为Map，便于数据库存储
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

  /// 从Map反序列化为Mistake对象
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

  /// 拷贝方法，支持部分字段变更
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