import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

class OCRService {
  // Gemini API配置
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent';
  
  // 获取API密钥
  Future<String?> _getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('gemini_api_key');
  }

  // OCR识别图片文字
  Future<String> recognizeText(String imagePath) async {
    try {
      final apiKey = await _getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('请先配置Gemini API密钥');
      }

      // 读取图片文件
      final File imageFile = File(imagePath);
      final Uint8List imageBytes = await imageFile.readAsBytes();
      
      // 将图片转换为base64
      final String base64Image = base64Encode(imageBytes);
      
      // 构建请求体
      final Map<String, dynamic> requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text': '请识别这张图片中的文字内容，只返回识别到的文字，不要添加任何解释或格式。'
              },
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Image
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'topK': 1,
          'topP': 1,
          'maxOutputTokens': 2048,
        }
      };

      // 发送请求
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String text = responseData['candidates'][0]['content']['parts'][0]['text'];
        return text.trim();
      } else {
        print('Gemini API请求失败: ${response.statusCode} - ${response.body}');
        return '';
      }
    } catch (e) {
      print('OCR识别失败: $e');
      return '';
    }
  }

  // 自动分类题目
  Map<String, String> classifyQuestion(String text) {
    // 学科分类关键词
    final subjectKeywords = {
      '数学': ['函数', '方程', '几何', '代数', '微积分', '概率', '统计', '三角函数', '导数', '积分', '向量', '矩阵'],
      '物理': ['力学', '电学', '光学', '热学', '原子', '分子', '能量', '速度', '加速度', '力', '电场', '磁场', '波'],
      '化学': ['元素', '化合物', '反应', '分子', '原子', '化学键', '溶液', '酸碱', '氧化还原', '有机化学'],
      '语文': ['文言文', '现代文', '诗歌', '散文', '小说', '作文', '阅读理解', '古诗词', '文学常识'],
      '英语': ['grammar', 'vocabulary', 'reading', 'writing', 'listening', 'speaking', '时态', '从句'],
      '生物': ['细胞', '遗传', '进化', '生态', '生理', '解剖', '基因', 'DNA', '蛋白质'],
      '历史': ['古代史', '近代史', '现代史', '世界史', '中国史', '朝代', '事件', '人物'],
      '地理': ['地形', '气候', '人口', '经济', '区域', '地图', '经纬度', '自然地理'],
    };

    // 题型分类关键词
    final typeKeywords = {
      '选择题': ['选择', 'A.', 'B.', 'C.', 'D.', '下列', '正确的是', '错误的是', '单选', '多选'],
      '填空题': ['填空', '_____', '___', '空白', '填入', '补充', '填写'],
      '解答题': ['解答', '计算', '证明', '求', '解', '分析', '说明', '论述'],
      '判断题': ['判断', '对错', '正确', '错误', '√', '×', '是非', '正误'],
      '简答题': ['简答', '简述', '简要', '简单', '回答'],
      '论述题': ['论述', '分析', '阐述', '说明', '解释'],
    };

    // 知识点分类（简化版）
    final knowledgeKeywords = {
      '基础概念': ['定义', '概念', '基本', '原理', '性质', '特征'],
      '计算应用': ['计算', '求解', '应用', '运用', '公式', '算法'],
      '分析推理': ['分析', '推理', '证明', '推导', '逻辑', '判断'],
      '综合运用': ['综合', '综合运用', '实际应用', '联系', '结合'],
      '记忆理解': ['记忆', '理解', '识记', '背诵', '掌握'],
    };

    String subject = '其他';
    String questionType = '其他';
    String knowledgePoint = '其他';

    // 识别学科
    for (final entry in subjectKeywords.entries) {
      for (final keyword in entry.value) {
        if (text.contains(keyword)) {
          subject = entry.key;
          break;
        }
      }
      if (subject != '其他') break;
    }

    // 识别题型
    for (final entry in typeKeywords.entries) {
      for (final keyword in entry.value) {
        if (text.contains(keyword)) {
          questionType = entry.key;
          break;
        }
      }
      if (questionType != '其他') break;
    }

    // 识别知识点
    for (final entry in knowledgeKeywords.entries) {
      for (final keyword in entry.value) {
        if (text.contains(keyword)) {
          knowledgePoint = entry.key;
          break;
        }
      }
      if (knowledgePoint != '其他') break;
    }

    return {
      'subject': subject,
      'questionType': questionType,
      'knowledgePoint': knowledgePoint,
    };
  }

  // 使用Gemini API进行智能分类
  Future<Map<String, String>> classifyQuestionWithAI(String text) async {
    try {
      final apiKey = await _getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('请先配置Gemini API密钥');
      }

      final Map<String, dynamic> requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text': '''请分析以下题目内容，并按照以下格式返回JSON：
{
  "subject": "学科名称（数学/物理/化学/语文/英语/生物/历史/地理/其他）",
  "questionType": "题型（选择题/填空题/解答题/判断题/简答题/论述题/其他）",
  "knowledgePoint": "知识点类型（基础概念/计算应用/分析推理/综合运用/记忆理解/其他）"
}

题目内容：$text

请只返回JSON格式的结果，不要添加任何其他文字。'''
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'topK': 1,
          'topP': 1,
          'maxOutputTokens': 512,
        }
      };

      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String resultText = responseData['candidates'][0]['content']['parts'][0]['text'];
        
        // 尝试解析JSON
        try {
          final Map<String, dynamic> result = jsonDecode(resultText);
          return {
            'subject': result['subject'] ?? '其他',
            'questionType': result['questionType'] ?? '其他',
            'knowledgePoint': result['knowledgePoint'] ?? '其他',
          };
        } catch (e) {
          print('AI分类结果解析失败: $e');
          return classifyQuestion(text); // 回退到关键词分类
        }
      } else {
        print('AI分类请求失败: ${response.statusCode}');
        return classifyQuestion(text); // 回退到关键词分类
      }
    } catch (e) {
      print('AI分类失败: $e');
      return classifyQuestion(text); // 回退到关键词分类
    }
  }

  // 图片预处理
  Future<String> preprocessImage(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final img.Image? image = img.decodeImage(imageBytes);
      
      if (image == null) return imagePath;

      // 图片增强处理
      img.Image processedImage = image;
      
      // 调整对比度
      processedImage = img.contrast(processedImage, contrast: 150);
      
      // 调整亮度（使用gamma调整）
      processedImage = img.gamma(processedImage, gamma: 0.8);
      
      // 保存处理后的图片
      final String processedPath = imagePath.replaceAll('.jpg', '_processed.jpg');
      final File processedFile = File(processedPath);
      await processedFile.writeAsBytes(img.encodeJpg(processedImage));
      
      return processedPath;
    } catch (e) {
      print('图片预处理失败: $e');
      return imagePath;
    }
  }

  void dispose() {
    // 不需要释放资源
  }
} 