import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mistake_provider.dart';

// 主界面：首页，展示统计信息、功能入口（错题录入、错题本、错题复习）
class HomeScreen extends StatefulWidget {
  /// APP主界面，负责展示统计卡片和主要功能入口
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 首次进入时自动加载错题数据，保证统计信息和功能入口数据实时
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MistakeProvider>().loadMistakes();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold为页面基础结构，包含AppBar、主体内容
    return Scaffold(
      appBar: AppBar(
        title: const Text('错题收集'),
        centerTitle: true,
        actions: [
          // 右上角设置按钮，跳转到设置页
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            tooltip: '设置',
          ),
        ],
      ),
      body: Consumer<MistakeProvider>(
        builder: (context, provider, child) {
          // 外层Padding保证整体留白美观
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 统计信息卡片，展示总题数、待复习、已完成
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          '学习统计',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 三个统计项横向排列
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('总题数', provider.mistakes.length.toString()),
                            _buildStatItem('待复习', provider.mistakes.where((m) => !m.isCompleted).length.toString()),
                            _buildStatItem('已完成', provider.mistakes.where((m) => m.isCompleted).length.toString()),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // 功能按钮区，包含错题录入、错题本、错题复习三个入口
                Expanded(
                  child: Column(
                    children: [
                      // 错题录入功能卡片
                      _buildFunctionCard(
                        context,
                        '错题录入',
                        '拍照或选择图片录入错题',
                        Icons.camera_alt,
                        Colors.blue,
                        () => Navigator.pushNamed(context, '/add'),
                      ),
                      const SizedBox(height: 16),
                      // 错题本功能卡片
                      _buildFunctionCard(
                        context,
                        '错题本',
                        '查看和管理所有错题',
                        Icons.book,
                        Colors.green,
                        () => Navigator.pushNamed(context, '/book'),
                      ),
                      const SizedBox(height: 16),
                      // 错题复习功能卡片
                      _buildFunctionCard(
                        context,
                        '错题复习',
                        '智能复习推荐',
                        Icons.school,
                        Colors.orange,
                        () => Navigator.pushNamed(context, '/review'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 构建统计信息单元（总题数/待复习/已完成）
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        // 数字部分，蓝色高亮
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        // 标签部分，灰色说明
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  /// 构建功能入口卡片，点击跳转到对应功能页
  Widget _buildFunctionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // 左侧图标区，带圆角背景
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              // 右侧文字区，标题+副标题
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              // 右侧箭头，提示可点击
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 