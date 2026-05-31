class HistoryItem {
  final String imagePath;      // ছবির path
  final String disease;        // রোগের নাম (ইংরেজি)
  final String diseaseBangla;  // রোগের নাম (বাংলা)
  final double confidence;     // নিশ্চিততা %
  final DateTime dateTime;     // কখন করেছে

  HistoryItem({
    required this.imagePath,
    required this.disease,
    required this.diseaseBangla,
    required this.confidence,
    required this.dateTime,
  });

  // Object কে Map এ convert (save করার জন্য)
  Map<String, dynamic> toMap() {
    return {
      'imagePath': imagePath,
      'disease': disease,
      'diseaseBangla': diseaseBangla,
      'confidence': confidence,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  // Map থেকে Object বানানো (load করার জন্য)
  factory HistoryItem.fromMap(Map<String, dynamic> map) {
    return HistoryItem(
      imagePath: map['imagePath'],
      disease: map['disease'],
      diseaseBangla: map['diseaseBangla'],
      confidence: map['confidence'],
      dateTime: DateTime.parse(map['dateTime']),
    );
  }
}