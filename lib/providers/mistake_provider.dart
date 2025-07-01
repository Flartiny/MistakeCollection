import 'package:flutter/foundation.dart';
import '../models/mistake.dart';
import '../services/database_service.dart';

/// MistakeProvider：错题全局状态管理，负责数据加载、增删改查、分组、复习等
class MistakeProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService(); // 数据库服务
  List<Mistake> _mistakes = []; // 错题列表
  bool _isLoading = false; // 是否正在加载

  List<Mistake> get mistakes => _mistakes;
  bool get isLoading => _isLoading;

  // 获取所有错题（异步加载，自动通知界面刷新）
  Future<void> loadMistakes() async {
    _isLoading = true;
    notifyListeners();

    try {
      _mistakes = await _databaseService.getAllMistakes();
    } catch (e) {
      print('加载错题失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 添加错题，插入数据库并更新本地列表
  Future<void> addMistake(Mistake mistake) async {
    try {
      final id = await _databaseService.insertMistake(mistake);
      final newMistake = mistake.copyWith(id: id);
      _mistakes.add(newMistake);
      notifyListeners();
    } catch (e) {
      print('添加错题失败: $e');
    }
  }

  // 更新错题，数据库和本地同步
  Future<void> updateMistake(Mistake mistake) async {
    try {
      await _databaseService.updateMistake(mistake);
      final index = _mistakes.indexWhere((m) => m.id == mistake.id);
      if (index != -1) {
        _mistakes[index] = mistake;
        notifyListeners();
      }
    } catch (e) {
      print('更新错题失败: $e');
    }
  }

  // 删除错题
  Future<void> deleteMistake(int id) async {
    try {
      await _databaseService.deleteMistake(id);
      _mistakes.removeWhere((m) => m.id == id);
      notifyListeners();
    } catch (e) {
      print('删除错题失败: $e');
    }
  }

  // 获取待复习错题（未完成）
  Future<List<Mistake>> getMistakesForReview() async {
    try {
      return await _databaseService.getMistakesForReview();
    } catch (e) {
      print('获取复习题目失败: $e');
      return [];
    }
  }

  // 按学科分组错题，返回Map<学科, List<Mistake>>
  Map<String, List<Mistake>> getMistakesBySubject() {
    final Map<String, List<Mistake>> grouped = {};
    for (final mistake in _mistakes) {
      if (!grouped.containsKey(mistake.subject)) {
        grouped[mistake.subject] = [];
      }
      grouped[mistake.subject]!.add(mistake);
    }
    return grouped;
  }

  // 按题型分组错题
  Map<String, List<Mistake>> getMistakesByType() {
    final Map<String, List<Mistake>> grouped = {};
    for (final mistake in _mistakes) {
      if (!grouped.containsKey(mistake.questionType)) {
        grouped[mistake.questionType] = [];
      }
      grouped[mistake.questionType]!.add(mistake);
    }
    return grouped;
  }

  // 按知识点分组错题
  Map<String, List<Mistake>> getMistakesByKnowledgePoint() {
    final Map<String, List<Mistake>> grouped = {};
    for (final mistake in _mistakes) {
      if (!grouped.containsKey(mistake.knowledgePoint)) {
        grouped[mistake.knowledgePoint] = [];
      }
      grouped[mistake.knowledgePoint]!.add(mistake);
    }
    return grouped;
  }

  // 标记题目为已完成，自动更新时间和复习次数
  Future<void> markAsCompleted(int id) async {
    final index = _mistakes.indexWhere((m) => m.id == id);
    if (index != -1) {
      final updatedMistake = _mistakes[index].copyWith(
        isCompleted: true,
        lastReviewed: DateTime.now(),
        reviewCount: _mistakes[index].reviewCount + 1,
      );
      await updateMistake(updatedMistake);
    }
  }

  // 根据遗忘曲线计算下次复习时间，间隔递增
  DateTime calculateNextReviewTime(Mistake mistake) {
    final now = DateTime.now();
    final daysSinceLastReview = now.difference(mistake.lastReviewed).inDays;
    
    // 艾宾浩斯遗忘曲线间隔：1, 2, 4, 7, 15, 30天
    final intervals = [1, 2, 4, 7, 15, 30];
    final currentInterval = intervals[mistake.reviewCount % intervals.length];
    
    return mistake.lastReviewed.add(Duration(days: currentInterval));
  }
} 