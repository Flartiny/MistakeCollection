import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expandable/expandable.dart';
import '../providers/mistake_provider.dart';
import '../models/mistake.dart';

class MistakeBookScreen extends StatefulWidget {
  /// 错题本页面，负责错题的分组展示与管理
  const MistakeBookScreen({super.key});

  @override
  State<MistakeBookScreen> createState() => _MistakeBookScreenState();
}

class _MistakeBookScreenState extends State<MistakeBookScreen> {
  String _selectedCategory = '学科'; // 当前分组方式
  final List<String> _categories = ['学科', '题型', '知识点']; // 可选分组类型

  @override
  Widget build(BuildContext context) {
    // Scaffold为页面基础结构，包含AppBar、主体内容
    return Scaffold(
      appBar: AppBar(
        title: const Text('错题本'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) {
              setState(() {
                _selectedCategory = value;
              });
            },
            itemBuilder: (BuildContext context) {
              return _categories.map((String category) {
                return PopupMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList();
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedCategory),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Consumer<MistakeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.mistakes.isEmpty) {
            // 空状态提示
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '暂无错题',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '快去添加一些错题吧！',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          // 按当前分组方式对错题进行分组
          Map<String, List<Mistake>> groupedMistakes;
          switch (_selectedCategory) {
            case '学科':
              groupedMistakes = provider.getMistakesBySubject();
              break;
            case '题型':
              groupedMistakes = provider.getMistakesByType();
              break;
            case '知识点':
              groupedMistakes = provider.getMistakesByKnowledgePoint();
              break;
            default:
              groupedMistakes = provider.getMistakesBySubject();
          }

          // 列表展示所有分组卡片，每个卡片可折叠，内含错题列表
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: groupedMistakes.length,
            itemBuilder: (context, index) {
              final category = groupedMistakes.keys.elementAt(index);
              final mistakes = groupedMistakes[category]!;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ExpandablePanel(
                  header: Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          _getCategoryIcon(_selectedCategory),
                          color: _getCategoryColor(_selectedCategory),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${mistakes.length} 道题目',
                                style: const TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(_selectedCategory).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${mistakes.where((m) => !m.isCompleted).length} 待复习',
                            style: TextStyle(
                              color: _getCategoryColor(_selectedCategory),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  collapsed: Container(),
                  expanded: Column(
                    children: mistakes.map((mistake) => _buildMistakeItem(mistake)).toList(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMistakeItem(Mistake mistake) {
    // 构建单个错题展示卡片，支持长按编辑、删除
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  mistake.content,
                  style: const TextStyle(fontSize: 16),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (String value) {
                  _handleMistakeAction(value, mistake);
                },
                itemBuilder: (BuildContext context) {
                  return [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('编辑'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('删除', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ];
                },
                child: const Icon(Icons.more_vert),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTag(mistake.subject, Colors.blue),
              const SizedBox(width: 8),
              _buildTag(mistake.questionType, Colors.green),
              const SizedBox(width: 8),
              _buildTag(mistake.knowledgePoint, Colors.orange),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                '创建于 ${_formatDate(mistake.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              if (mistake.isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '已完成',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          if (mistake.imagePath != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showImageDialog(mistake.imagePath!),
              child: Container(
                height: 100,
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
                        height: 100,
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.zoom_in,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '学科':
        return Icons.school;
      case '题型':
        return Icons.quiz;
      case '知识点':
        return Icons.lightbulb;
      default:
        return Icons.category;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case '学科':
        return Colors.blue;
      case '题型':
        return Colors.green;
      case '知识点':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _handleMistakeAction(String action, Mistake mistake) {
    switch (action) {
      case 'edit':
        _showEditDialog(mistake);
        break;
      case 'delete':
        _showDeleteDialog(mistake);
        break;
    }
  }

  void _showEditDialog(Mistake mistake) {
    final contentController = TextEditingController(text: mistake.content);
    final subjectController = TextEditingController(text: mistake.subject);
    final questionTypeController = TextEditingController(text: mistake.questionType);
    final knowledgePointController = TextEditingController(text: mistake.knowledgePoint);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('编辑错题'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: '题目内容',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(
                    labelText: '学科',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: questionTypeController,
                  decoration: const InputDecoration(
                    labelText: '题型',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: knowledgePointController,
                  decoration: const InputDecoration(
                    labelText: '知识点',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final updatedMistake = Mistake(
                  id: mistake.id,
                  content: contentController.text,
                  subject: subjectController.text,
                  questionType: questionTypeController.text,
                  knowledgePoint: knowledgePointController.text,
                  imagePath: mistake.imagePath,
                  createdAt: mistake.createdAt,
                  lastReviewed: mistake.lastReviewed,
                  reviewCount: mistake.reviewCount,
                  isCompleted: mistake.isCompleted,
                );
                
                context.read<MistakeProvider>().updateMistake(updatedMistake);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('编辑成功')),
                );
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(Mistake mistake) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: const Text('确定要删除这道错题吗？此操作不可撤销。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                context.read<MistakeProvider>().deleteMistake(mistake.id!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('删除成功')),
                );
              },
              child: const Text(
                '删除',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showImageDialog(String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  InteractiveViewer(
                    child: Image.file(
                      File(imagePath),
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.5),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
} 