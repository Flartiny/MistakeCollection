import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mistake_collection/providers/mistake_provider.dart';
import 'package:mistake_collection/screens/home_screen.dart';
import 'package:mistake_collection/screens/add_mistake_screen.dart';
import 'package:mistake_collection/screens/mistake_book_screen.dart';
import 'package:mistake_collection/screens/review_screen.dart';
import 'package:mistake_collection/screens/settings_screen.dart';

/// 应用主入口，负责全局状态管理、主题配置、路由注册
/// 应用入口函数，启动Flutter应用
void main() {
  runApp(const MyApp());
}

/// MyApp为应用根组件，负责全局状态管理和路由配置
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用Provider进行全局状态管理，MistakeProvider负责错题数据
    return ChangeNotifierProvider(
      create: (context) => MistakeProvider(),
      child: MaterialApp(
        title: '错题收集',
        // 全局主题设置，采用Material3风格
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
        // 路由配置，定义各个页面的访问路径
        initialRoute: '/', // 初始页面为首页
        routes: {
          '/': (context) => const HomeScreen(), // 首页
          '/add': (context) => const AddMistakeScreen(), // 错题录入页
          '/book': (context) => const MistakeBookScreen(), // 错题本页
          '/review': (context) => const ReviewScreen(), // 复习页
          '/settings': (context) => const SettingsScreen(), // 设置页
        },
      ),
    );
  }
} 