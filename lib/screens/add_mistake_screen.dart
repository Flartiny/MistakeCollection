import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/mistake_provider.dart';
import '../models/mistake.dart';
import '../services/ocr_service.dart';
import 'package:image_cropper/image_cropper.dart';

class AddMistakeScreen extends StatefulWidget {
  /// 错题录入页，负责图片选择、裁剪、OCR识别、AI分类、表单编辑与保存
  const AddMistakeScreen({super.key});

  @override
  State<AddMistakeScreen> createState() => _AddMistakeScreenState();
}

class _AddMistakeScreenState extends State<AddMistakeScreen> {
  // 表单控制器，分别对应题目内容、学科、题型、知识点
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _subjectController = TextEditingController();
  final _questionTypeController = TextEditingController();
  final _knowledgePointController = TextEditingController();
  
  final OCRService _ocrService = OCRService(); // OCR与AI分类服务
  final ImagePicker _picker = ImagePicker();   // 图片选择器
  
  String? _imagePath; // 当前选中的图片路径
  bool _isProcessing = false; // 是否正在处理图片
  String _processingStatus = ''; // 处理进度提示
  bool _canCancel = false; // 是否可取消处理

  @override
  void dispose() {
    // 释放所有表单控制器资源，防止内存泄漏
    _contentController.dispose();
    _subjectController.dispose();
    _questionTypeController.dispose();
    _knowledgePointController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  /// 选择图片（拍照或相册），并支持裁剪，完成后自动进入OCR识别
  Future<void> _pickImage(ImageSource source) async {
    try {
      // 弹出系统图片选择器，限制最大宽高和压缩质量
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920, // 限制图片最大宽度，防止过大导致内存溢出
        maxHeight: 1920, // 限制图片最大高度
        imageQuality: 85, // 压缩图片质量，兼顾清晰度和体积
      );
      if (image != null) {
        // 进入图片裁剪界面，支持多端UI配置
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
          // 裁剪完成后，更新图片路径并重置处理状态
          setState(() {
            _imagePath = croppedFile.path;
            _isProcessing = false;
            _processingStatus = '';
          });
          // 延迟500ms，避免UI卡顿后立即开始OCR
          await Future.delayed(const Duration(milliseconds: 500));
          // 自动进入图片识别流程
          _processImageAsync(croppedFile.path);
        }
      }
    } catch (e) {
      // 捕获所有异常，弹出错误提示，防止界面崩溃
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

  /// 异步处理图片：1. OCR识别文字 2. AI智能分类 3. 更新表单内容
  Future<void> _processImageAsync(String imagePath) async {
    if (!mounted) return;
    // 进入处理状态，显示进度提示，允许用户取消
    setState(() {
      _isProcessing = true;
      _processingStatus = '正在识别文字...';
      _canCancel = true;
    });

    try {
      // 步骤1：OCR识别图片文字，调用OCRService
      final recognizedText = await _ocrService.recognizeText(imagePath);
      if (!mounted) return;
      // 步骤2：AI智能分类，调用OCRService
      setState(() {
        _processingStatus = '正在分析题目类别...';
      });
      final classification = await _ocrService.classifyQuestionWithAI(recognizedText);
      if (!mounted) return;
      // 步骤3：更新表单内容，填充识别结果和分类信息
      setState(() {
        _contentController.text = recognizedText;
        _subjectController.text = classification['subject'] ?? '';
        _questionTypeController.text = classification['questionType'] ?? '';
        _knowledgePointController.text = classification['knowledgePoint'] ?? '';
        _isProcessing = false;
        _processingStatus = '';
        _canCancel = false;
      });
      // 识别结果为空时，提示用户手动输入
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
        // 识别成功，弹出完成提示
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
      // 捕获OCR或AI分类异常，重置状态并提示用户
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

  /// 取消图片处理，重置所有处理相关状态
  void _cancelProcessing() {
    setState(() {
      _isProcessing = false;
      _processingStatus = '';
      _canCancel = false;
    });
  }

  /// 弹窗选择图片来源（拍照/相册），点击后进入_pickImage
  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择图片来源'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 拍照入口
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('拍照'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              // 相册入口
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

  @override
  Widget build(BuildContext context) {
    // 主体为表单+图片+处理进度+保存按钮
    return Scaffold(
      appBar: AppBar(
        title: const Text('错题录入'),
        actions: [
          // 右上角帮助按钮，可扩展为弹窗说明
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('使用说明'),
                  content: const Text('拍照或选择图片，自动识别题目内容和分类，支持手动编辑。'),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('确定'))],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图片选择与展示区域
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _imagePath == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_a_photo, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('点击选择图片', style: TextStyle(color: Colors.grey)),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_imagePath!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 180,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            // 处理进度与取消按钮
            if (_isProcessing)
              Row(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_processingStatus)),
                  if (_canCancel)
                    TextButton(
                      onPressed: _cancelProcessing,
                      child: const Text('取消'),
                    ),
                ],
              ),
            const SizedBox(height: 16),
            // 表单区域，包含题目内容、学科、题型、知识点
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // 题目内容输入框
                  TextFormField(
                    controller: _contentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: '题目内容',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) => (value == null || value.trim().isEmpty) ? '请输入题目内容' : null,
                  ),
                  const SizedBox(height: 16),
                  // 学科输入框
                  TextFormField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      labelText: '学科',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 题型输入框
                  TextFormField(
                    controller: _questionTypeController,
                    decoration: const InputDecoration(
                      labelText: '题型',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 知识点输入框
                  TextFormField(
                    controller: _knowledgePointController,
                    decoration: const InputDecoration(
                      labelText: '知识点',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 保存按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('保存'),
                onPressed: _isProcessing
                    ? null
                    : () async {
                        // 校验表单，内容不能为空
                        if (_formKey.currentState?.validate() ?? false) {
                          // 构造Mistake对象，准备保存
                          final newMistake = Mistake(
                            content: _contentController.text.trim(),
                            subject: _subjectController.text.trim(),
                            questionType: _questionTypeController.text.trim(),
                            knowledgePoint: _knowledgePointController.text.trim(),
                            imagePath: _imagePath,
                            createdAt: DateTime.now(),
                            lastReviewed: DateTime.now(),
                          );
                          // 调用Provider保存到数据库
                          await Provider.of<MistakeProvider>(context, listen: false).addMistake(newMistake);
                          // 返回上一页并弹出提示
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('错题已保存')),
                            );
                          }
                        }
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 