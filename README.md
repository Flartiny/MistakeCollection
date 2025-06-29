# 错题收集APP

基于Flutter框架开发的错题分类及推荐APP，帮助学生高效管理错题并进行智能复习。

## 功能特性

### 📸 错题录入
- **拍照识别**：调用手机摄像头拍照，自动OCR识别题目内容
- **相册选择**：从相册选择图片进行识别
- **智能分类**：自动按学科、题型和知识点分类
- **内容编辑**：识别后可手动编辑和修改题目内容及分类

### 📚 错题本管理
- **三大分类**：按学科、题型、知识点三大类别展示错题
- **折叠展开**：不同类别的题目可折叠或展开显示
- **错题管理**：支持编辑、删除等管理功能
- **图片预览**：显示题目原图，便于复习

### 🧠 智能复习
- **复习模式**：支持日常复习和考前突击两种模式
- **遗忘曲线**：应用艾宾浩斯遗忘曲线算法，智能安排复习时间
- **进度跟踪**：实时显示复习进度和完成状态
- **掌握标记**：用户可标注题目是否已掌握

## 技术架构

### 前端框架
- **Flutter**：跨平台移动应用开发框架
- **Material Design**：现代化UI设计语言

### 状态管理
- **Provider**：轻量级状态管理方案

### 数据存储
- **SQLite**：本地数据库存储错题信息
- **SharedPreferences**：用户偏好设置存储

### 图像处理
- **Image Picker**：图片选择和拍照功能
- **Google ML Kit**：OCR文字识别
- **Image**：图片预处理和增强

### 核心算法
- **遗忘曲线算法**：基于艾宾浩斯遗忘曲线，间隔复习时间：1, 2, 4, 7, 15, 30天

## 项目结构

```
lib/
├── main.dart                 # 应用入口
├── models/
│   └── mistake.dart         # 错题数据模型
├── providers/
│   └── mistake_provider.dart # 状态管理
├── services/
│   ├── database_service.dart # 数据库服务
│   └── ocr_service.dart     # OCR识别服务
└── screens/
    ├── home_screen.dart      # 主界面
    ├── add_mistake_screen.dart # 错题录入
    ├── mistake_book_screen.dart # 错题本
    └── review_screen.dart    # 错题复习
```

## 安装和运行

### 环境要求
- Flutter SDK 3.32.5 或更高版本
- Dart SDK 3.8.0 或更高版本
- Android Studio / VS Code

### 安装步骤

1. **克隆项目**
```bash
git clone [项目地址]
cd mistake_collection
```

2. **安装依赖**
```bash
flutter pub get
```

3. **运行项目**
```bash
# 在模拟器上运行
flutter run -d emulator-5554

# 或在连接的设备上运行
flutter run
```

### 权限配置

在 `android/app/src/main/AndroidManifest.xml` 中添加以下权限：

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

## 使用说明

### 错题录入
1. 点击"错题录入"进入录入界面
2. 选择"拍照"或"相册"获取题目图片
3. 系统自动OCR识别并分类
4. 编辑确认题目内容和分类信息
5. 点击"保存"完成录入

### 错题本查看
1. 点击"错题本"进入管理界面
2. 选择分类方式（学科/题型/知识点）
3. 点击分类卡片展开查看具体题目
4. 长按题目可进行编辑或删除操作

### 错题复习
1. 点击"错题复习"进入复习界面
2. 选择复习模式（日常复习/考前突击）
3. 系统按遗忘曲线算法推送题目
4. 选择"已掌握"或"还需要复习"
5. 系统自动安排下次复习时间

## 核心算法

### 遗忘曲线算法
基于艾宾浩斯遗忘曲线，系统自动计算最佳复习间隔：

- 第1次复习：1天后
- 第2次复习：2天后  
- 第3次复习：4天后
- 第4次复习：7天后
- 第5次复习：15天后
- 第6次复习：30天后

### 智能分类算法
通过关键词匹配自动识别：
- **学科分类**：数学、物理、化学、语文、英语等
- **题型分类**：选择题、填空题、解答题、判断题等
- **知识点分类**：基础概念、计算应用、分析推理、综合运用等

## 开发计划

### 已完成功能
- ✅ 基础UI界面设计
- ✅ 错题数据模型设计
- ✅ 数据库存储功能
- ✅ OCR识别和分类
- ✅ 错题管理功能
- ✅ 遗忘曲线算法

### 待开发功能
- 🔄 云端同步功能
- 🔄 学习统计分析
- 🔄 错题分享功能
- 🔄 智能推荐算法优化
- 🔄 多语言支持

## 贡献指南

欢迎提交Issue和Pull Request来改进项目！

## 许可证

本项目采用 MIT 许可证。

## 联系方式

如有问题或建议，请通过以下方式联系：
- 邮箱：[your-email@example.com]
- GitHub Issues：[项目Issues页面] 