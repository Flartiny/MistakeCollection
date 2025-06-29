import 'package:flutter/foundation.dart';
import '../models/mistake.dart';
import '../services/database_service.dart';

class MistakeProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<Mistake> _mistakes = [];
  bool _isLoading = false;

  List<Mistake> get mistakes => _mistakes;
  bool get isLoading => _isLoading;

  // 获取所有错题
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

  // 添加错题
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

  // 更新错题
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

  // 获取复习题目
  Future<List<Mistake>> getMistakesForReview() async {
    try {
      return await _databaseService.getMistakesForReview();
    } catch (e) {
      print('获取复习题目失败: $e');
      return [];
    }
  }

  // 按学科分组获取错题
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

  // 按题型分组获取错题
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

  // 按知识点分组获取错题
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

  // 标记题目为已完成
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

  // 根据遗忘曲线计算下次复习时间
  DateTime calculateNextReviewTime(Mistake mistake) {
    final now = DateTime.now();
    final daysSinceLastReview = now.difference(mistake.lastReviewed).inDays;
    
    // 艾宾浩斯遗忘曲线间隔：1, 2, 4, 7, 15, 30天
    final intervals = [1, 2, 4, 7, 15, 30];
    final currentInterval = intervals[mistake.reviewCount % intervals.length];
    
    return mistake.lastReviewed.add(Duration(days: currentInterval));
  }
} 