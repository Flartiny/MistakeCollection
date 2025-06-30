import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/mistake_provider.dart';
import '../models/mistake.dart';
import '../services/ocr_service.dart';
import 'package:image_cropper/image_cropper.dart';

class AddMistakeScreen extends StatefulWidget {
  const AddMistakeScreen({super.key});

  @override
  State<AddMistakeScreen> createState() => _AddMistakeScreenState();
}

class _AddMistakeScreenState extends State<AddMistakeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _subjectController = TextEditingController();
  final _questionTypeController = TextEditingController();
  final _knowledgePointController = TextEditingController();
  
  final OCRService _ocrService = OCRService();
  final ImagePicker _picker = ImagePicker();
  
  String? _imagePath;
  bool _isProcessing = false;
  String _processingStatus = '';
  bool _canCancel = false;

  @override
  void dispose() {
    _contentController.dispose();
    _subjectController.dispose();
    _questionTypeController.dispose();
    _knowledgePointController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920, // 限制图片最大宽度
        maxHeight: 1920, // 限制图片最大高度
        imageQuality: 85, // 压缩质量
      );
      if (image != null) {
        // 先进入图片编辑
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: '编辑图片',
              toolbarColor: Colors.blue,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
            ),
            IOSUiSettings(
              title: '编辑图片',
            ),
            WebUiSettings(
              context: context,
              presentStyle: WebPresentStyle.dialog,
            ),
          ],
        );
        if (croppedFile != null) {
          setState(() {
            _imagePath = croppedFile.path;
            _isProcessing = false;
            _processingStatus = '';
          });
          // 编辑后自动识别
          await Future.delayed(const Duration(milliseconds: 500));
          _processImageAsync(croppedFile.path);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('图片选择失败: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _processImageAsync(String imagePath) async {
    if (!mounted) return;
    
    setState(() {
      _isProcessing = true;
      _processingStatus = '正在识别文字...';
      _canCancel = true;
    });

    try {
      // 第一步：OCR识别
      final recognizedText = await _ocrService.recognizeText(imagePath);
      
      if (!mounted) return;
      
      setState(() {
        _processingStatus = '正在分析题目类型...';
      });

      // 第二步：AI分类
      final classification = await _ocrService.classifyQuestionWithAI(recognizedText);
      
      if (!mounted) return;
      
      // 更新UI
      setState(() {
        _contentController.text = recognizedText;
        _subjectController.text = classification['subject'] ?? '';
        _questionTypeController.text = classification['questionType'] ?? '';
        _knowledgePointController.text = classification['knowledgePoint'] ?? '';
        _isProcessing = false;
        _processingStatus = '';
        _canCancel = false;
      });
      
      // 如果OCR识别结果为空，提示用户
      if (recognizedText.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('图片识别失败，请手动输入题目内容'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        // 成功提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('图片识别完成！'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (ocrError) {
      if (!mounted) return;
      
      setState(() {
        _isProcessing = false;
        _processingStatus = '';
        _canCancel = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OCR识别失败: $ocrError，请手动输入题目内容'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _cancelProcessing() {
    setState(() {
      _isProcessing = false;
      _processingStatus = '';
      _canCancel = false;
    });
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择图片来源'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('拍照'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('相册'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveMistake() async {
    if (_formKey.currentState!.validate()) {
      final mistake = Mistake(
        content: _contentController.text,
        subject: _subjectController.text,
        questionType: _questionTypeController.text,
        knowledgePoint: _knowledgePointController.text,
        imagePath: _imagePath,
        createdAt: DateTime.now(),
        lastReviewed: DateTime.now(),
      );

      await context.read<MistakeProvider>().addMistake(mistake);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('错题保存成功！')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('错题录入'),
        actions: [
          TextButton(
            onPressed: _saveMistake,
            child: const Text(
              '保存',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 图片选择区域
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        '题目图片',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_imagePath != null) ...[
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_imagePath!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isProcessing ? null : _showImageSourceDialog,
                              icon: const Icon(Icons.camera_alt),
                              label: Text(_imagePath == null ? '选择图片' : '重新选择'),
                            ),
                          ),
                          if (_imagePath != null && !_isProcessing) ...[
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _processImageAsync(_imagePath!),
                                icon: const Icon(Icons.refresh),
                                label: const Text('重新识别'),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (_isProcessing) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _processingStatus,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          '请稍候，正在处理中...',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (_canCancel) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: TextButton(
                                    onPressed: _cancelProcessing,
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    child: const Text('取消处理'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 题目内容
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: '题目内容',
                  border: OutlineInputBorder(),
                  hintText: '请输入或识别题目内容',
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入题目内容';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 学科选择
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: '学科',
                  border: OutlineInputBorder(),
                  hintText: '如：数学、物理、化学等',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请选择学科';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 题型选择
              TextFormField(
                controller: _questionTypeController,
                decoration: const InputDecoration(
                  labelText: '题型',
                  border: OutlineInputBorder(),
                  hintText: '如：选择题、填空题、解答题等',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请选择题型';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 知识点
              TextFormField(
                controller: _knowledgePointController,
                decoration: const InputDecoration(
                  labelText: '知识点',
                  border: OutlineInputBorder(),
                  hintText: '如：函数、方程、几何等',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入知识点';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // 保存按钮
              ElevatedButton(
                onPressed: _saveMistake,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  '保存错题',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 