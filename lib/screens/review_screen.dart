import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mistake_provider.dart';
import '../models/mistake.dart';

// 错题复习界面，支持遗忘曲线推送、进度展示、复习操作
class ReviewScreen extends StatefulWidget {
  /// 错题复习页，负责按遗忘曲线推送题目，支持标记完成、进度展示
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _currentIndex = 0; // 当前复习题目索引
  List<Mistake> _reviewMistakes = []; // 待复习题目列表
  PageController? _pageController; // 翻页控制器

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadReviewMistakes(); // 初始化时加载待复习题目
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _loadReviewMistakes() async {
    final provider = context.read<MistakeProvider>();
    final allMistakes = await provider.getMistakesForReview();
    
    // 根据遗忘曲线算法排序，优先推送最需要复习的题目
    allMistakes.sort((a, b) {
      final aNextReview = provider.calculateNextReviewTime(a);
      final bNextReview = provider.calculateNextReviewTime(b);
      return aNextReview.compareTo(bNextReview);
    });

    setState(() {
      _reviewMistakes = allMistakes;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold为页面基础结构，包含AppBar、主体内容
    return Scaffold(
      appBar: AppBar(
        title: const Text('错题复习'),
      ),
      body: _reviewMistakes.isEmpty
          ? _buildEmptyState() // 无题目时展示空状态
          : Column(
              children: [
                _buildProgressIndicator(), // 顶部进度条
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _reviewMistakes.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          _buildReviewCard(index), // 题目卡片
                          _buildActionButtons(),   // 操作按钮
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    // 构建空状态提示（全部复习完成）
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.green,
          ),
          SizedBox(height: 16),
          Text(
            '太棒了！',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '所有错题都已复习完成',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 16),
          Text(
            '继续保持，学习进步！',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    // 构建顶部进度条，显示当前进度
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '进度',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '${_currentIndex + 1} / ${_reviewMistakes.length}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _reviewMistakes.isEmpty ? 0 : (_currentIndex + 1) / _reviewMistakes.length,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard([int? index]) {
    // 构建单个复习题目卡片，展示题目信息、标签、复习次数等
    final int showIndex = index ?? _currentIndex;
    if (showIndex >= _reviewMistakes.length) {
      return _buildEmptyState();
    }
    final mistake = _reviewMistakes[showIndex];
    final provider = context.read<MistakeProvider>();
    final nextReviewTime = provider.calculateNextReviewTime(mistake);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 题目信息
            Row(
              children: [
                _buildTag(mistake.subject, Colors.blue),
                const SizedBox(width: 8),
                _buildTag(mistake.questionType, Colors.green),
                const SizedBox(width: 8),
                _buildTag(mistake.knowledgePoint, Colors.orange),
                const Spacer(),
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '复习 ${mistake.reviewCount} 次',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 题目内容
            Text(
              '题目：',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mistake.content,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            // 题目图片
            if (mistake.imagePath != null) ...[
              GestureDetector(
                onTap: () => _showImageDialog(mistake.imagePath!),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Image.file(
                          File(mistake.imagePath!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 200,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.zoom_in,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 复习信息
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '下次复习时间',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(nextReviewTime),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _handleReviewResult(false),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                '还需要复习',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _handleReviewResult(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                '已掌握',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _handleReviewResult(bool isCompleted) async {
    if (_currentIndex >= _reviewMistakes.length) return;
    final mistake = _reviewMistakes[_currentIndex];
    final provider = context.read<MistakeProvider>();

    if (isCompleted) {
      // 标记为已完成
      await provider.markAsCompleted(mistake.id!);
      // 本地移除该题
      setState(() {
        _reviewMistakes.removeAt(_currentIndex);
        // 如果已到最后一题，回退一页
        if (_currentIndex >= _reviewMistakes.length && _currentIndex > 0) {
          _currentIndex--;
        }
      });
      // 显示成功消息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('太棒了！继续加油！'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: '确定',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } else {
      // 更新复习时间，超时未复习的题目，lastReviewed至少更新到今天
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      DateTime lastReviewed = mistake.lastReviewed;
      if (lastReviewed.isBefore(today)) {
        lastReviewed = today;
      }
      final updatedMistake = mistake.copyWith(
        lastReviewed: lastReviewed,
        reviewCount: mistake.reviewCount + 1,
      );
      await provider.updateMistake(updatedMistake);
      setState(() {
        // 替换本地该题为新数据
        _reviewMistakes[_currentIndex] = updatedMistake;
        // 按下次复习时间重新排序
        _reviewMistakes.sort((a, b) {
          final aNext = provider.calculateNextReviewTime(a);
          final bNext = provider.calculateNextReviewTime(b);
          return aNext.compareTo(bNext);
        });
        // 找到新位置
        final newIndex = _reviewMistakes.indexWhere((m) => m.id == updatedMistake.id);
        // 跳转到新位置或下一个题目
        if (newIndex < _reviewMistakes.length - 1) {
          _currentIndex = newIndex + 1;
        } else {
          _currentIndex = newIndex;
        }
      });
      // 跳转动画
      if (_reviewMistakes.isNotEmpty) {
        _pageController?.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已记录，下次继续复习'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showImageDialog(String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: InteractiveViewer(
            child: Image.file(
              File(imagePath),
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }
} 