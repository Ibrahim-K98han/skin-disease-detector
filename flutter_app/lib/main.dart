import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'history_model.dart';
import 'history_service.dart';
import 'history_screen.dart';
import 'pdf_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skin Disease Detector',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _selectedImage;
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  // ⚠️ তোমার PC এর IP দাও
  final String apiUrl = "http://192.168.0.106:8000/predict";

  // ইংরেজি → বাংলা রোগের নাম
  final Map<String, String> diseaseInBangla = {
    'Acne and Rosacea Photos': 'ব্রণ ও রোসেসিয়া',
    'Actinic Keratosis Basal Cell Carcinoma and other Malignant Lesions':
        'ত্বকের ক্যান্সার জাতীয় রোগ',
    'Atopic Dermatitis Photos': 'এটোপিক ডার্মাটাইটিস (চুলকানি)',
    'Bullous Disease Photos': 'ফোসকা জাতীয় রোগ',
    'Cellulitis Impetigo and other Bacterial Infections':
        'ব্যাকটেরিয়াল চর্মরোগ',
    'Eczema Photos': 'একজিমা',
    'Exanthems and Drug Eruptions': 'ওষুধের পার্শ্বপ্রতিক্রিয়াজনিত ফুসকুড়ি',
    'Hair Loss Photos Alopecia and other Hair Diseases': 'চুল পড়া রোগ',
    'Herpes HPV and other STDs Photos': 'হার্পিস ও যৌনবাহিত রোগ',
    'Light Diseases and Disorders of Pigmentation': 'ত্বকের রঙের সমস্যা',
    'Lupus and other Connective Tissue diseases': 'লুপাস রোগ',
    'Melanoma Skin Cancer Nevi and Moles': 'মেলানোমা ত্বকের ক্যান্সার',
    'Nail Fungus and other Nail Disease': 'নখের ছত্রাক রোগ',
    'Poison Ivy Photos and other Contact Dermatitis': 'অ্যালার্জিক চর্মরোগ',
    'Psoriasis pictures Lichen Planus and related diseases':
        'সোরিয়াসিস ও লাইকেন প্ল্যানাস',
    'Scabies Lyme Disease and other Infestations and Bites':
        'খোস-পাঁচড়া ও পোকার কামড়',
    'Seborrheic Keratoses and other Benign Tumors': 'নিরীহ টিউমার জাতীয় রোগ',
    'Systemic Disease': 'সিস্টেমিক রোগ (অভ্যন্তরীণ)',
    'Tinea Ringworm Candidiasis and other Fungal Infections':
        'দাদ ও ছত্রাকজনিত রোগ',
    'Urticaria Hives': 'আমবাত (চাকা চাকা ফোলা)',
    'Vascular Tumors': 'রক্তনালীর টিউমার',
    'Vasculitis Photos': 'রক্তনালীর প্রদাহ',
    'Warts Molluscum and other Viral Infections': 'আঁচিল ও ভাইরাল চর্মরোগ',
  };

  // রোগ অনুযায়ী পরামর্শ
  final Map<String, String> diseaseAdvice = {
    'Acne and Rosacea Photos':
        'মুখ পরিষ্কার রাখুন। তৈলাক্ত খাবার এড়িয়ে চলুন।',
    'Eczema Photos': 'ত্বক আর্দ্র রাখুন। সুগন্ধিযুক্ত সাবান এড়িয়ে চলুন।',
    'Tinea Ringworm Candidiasis and other Fungal Infections':
        'আক্রান্ত স্থান শুকনো রাখুন। অ্যান্টিফাঙ্গাল ক্রিম ব্যবহার করুন।',
    'Scabies Lyme Disease and other Infestations and Bites':
        'কাপড় গরম পানিতে ধুন। পরিবারের সবাইকে চিকিৎসা করান।',
    'Urticaria Hives':
        'অ্যালার্জির কারণ খুঁজে বের করুন। অ্যান্টিহিস্টামিন নিন।',
    'Psoriasis pictures Lichen Planus and related diseases':
        'ত্বক আর্দ্র রাখুন। রোদ থেকে দূরে থাকুন। ডাক্তারের পরামর্শ নিন।',
    'Melanoma Skin Cancer Nevi and Moles':
        'অবিলম্বে একজন চর্মরোগ বিশেষজ্ঞের পরামর্শ নিন। দেরি করবেন না।',
    'Hair Loss Photos Alopecia and other Hair Diseases':
        'পুষ্টিকর খাবার খান। মাথার ত্বক পরিষ্কার রাখুন।',
  };

  String getBanglaName(String englishName) {
    return diseaseInBangla[englishName] ?? englishName;
  }

  String getAdvice(String englishName) {
    return diseaseAdvice[englishName] ??
        'দ্রুত একজন চর্মরোগ বিশেষজ্ঞের পরামর্শ নিন।';
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _result = null;
      });
    }
  }

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _result = null;
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;
    setState(() => _isLoading = true);

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.files.add(
        await http.MultipartFile.fromPath('file', _selectedImage!.path),
      );
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var data = json.decode(responseBody);

      setState(() {
        _result = data;
        _isLoading = false;
      });

      // ✅ History save করো
      if (data['success'] == true) {
        await HistoryService.saveHistory(
          HistoryItem(
            imagePath: _selectedImage!.path,
            disease: data['predicted_disease'],
            diseaseBangla: getBanglaName(data['predicted_disease']),
            confidence: data['confidence'],
            dateTime: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server এ connect হচ্ছে না! Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ Confidence Warning Widget
  Widget _buildConfidenceWarning(double confidence) {
    if (confidence < 30) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ ছবি স্পষ্ট নয়!',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Confidence অনেক কম। ভালো আলোতে আবার ছবি তুলুন অথবা আক্রান্ত স্থানের কাছ থেকে তুলুন।',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (confidence < 70) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber, color: Colors.orange, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚡ মাঝারি নিশ্চিততা',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Result টি সম্ভাব্য। নিশ্চিত হতে অবশ্যই একজন চর্মরোগ বিশেষজ্ঞের পরামর্শ নিন।',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✅ উচ্চ নিশ্চিততা',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'AI ভালো confidence নিয়ে রোগ শনাক্ত করেছে। তবুও ডাক্তারের পরামর্শ নিন।',
                    style: TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          '🔬 ত্বকের রোগ শনাক্তকারী',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
            tooltip: 'ইতিহাস',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ছবি দেখানোর জায়গা
            GestureDetector(
              onTap: _pickFromGallery,
              child: Container(
                height: 260,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.teal, width: 2),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 80,
                            color: Colors.teal,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'ছবি নির্বাচন করুন',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.teal,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'tap করুন অথবা নিচের বাটন ব্যবহার করুন',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 14),

            // Gallery ও Camera বাটন
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('গ্যালারি'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('ক্যামেরা'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Analyze বাটন
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedImage != null && !_isLoading
                    ? _analyzeImage
                    : null,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.biotech),
                label: Text(
                  _isLoading ? 'বিশ্লেষণ হচ্ছে...' : 'রোগ শনাক্ত করুন',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (_result != null) _buildResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    if (_result!['success'] == false) {
      return Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'সমস্যা হয়েছে: ${_result!['error']}',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    final String englishName = _result!['predicted_disease'];
    final String banglaName = getBanglaName(englishName);
    final double confidence = _result!['confidence'];
    final String advice = getAdvice(englishName);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Confidence Warning সবার উপরে
            _buildConfidenceWarning(confidence),

            // Header
            const Text(
              '🔍 শনাক্ত ফলাফল',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),

            // বাংলায় রোগের নাম
            Text(
              banglaName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            Text(
              '($englishName)',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 12),

            // Confidence
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'নিশ্চিততা:',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                Text(
                  '${confidence.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: confidence > 70
                        ? Colors.green
                        : confidence > 30
                        ? Colors.orange
                        : Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: confidence / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  confidence > 70
                      ? Colors.green
                      : confidence > 30
                      ? Colors.orange
                      : Colors.red,
                ),
                minHeight: 10,
              ),
            ),

            const SizedBox(height: 20),

            // পরামর্শ
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.tips_and_updates, color: Colors.teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'পরামর্শ:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(advice, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Top 3
            const Text(
              'অন্যান্য সম্ভাবনা:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ...(_result!['top3'] as List).map((item) {
              final String itemEnglish = item['disease'];
              final String itemBangla = getBanglaName(itemEnglish);
              final double itemConf = item['confidence'];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                itemBangla,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '($itemEnglish)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${itemConf.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: itemConf / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.teal.shade300,
                        ),
                        minHeight: 5,
                      ),
                    ),
                    const Divider(),
                  ],
                ),
              );
            }),

            const SizedBox(height: 8),

            // Warning
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⚠️ এটি শুধু AI বিশ্লেষণ। সঠিক রোগ নির্ণয়ের জন্য অবশ্যই একজন চর্মরোগ বিশেষজ্ঞ ডাক্তারের পরামর্শ নিন।',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ✅ PDF Report Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await PdfService.generateReport(
                    imagePath: _selectedImage!.path,
                    disease: englishName,
                    diseaseBangla: banglaName,
                    confidence: confidence,
                    top3: _result!['top3'],
                    advice: advice,
                    diseaseInBangla: diseaseInBangla,
                  );
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text(
                  'PDF Report তৈরি করুন',
                  style: TextStyle(fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
