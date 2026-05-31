# 🔬 Skin Disease Detector

AI-powered mobile application for detecting skin diseases using
Flutter and Python CNN (MobileNetV2).

## 📱 Features

- 23 ধরনের ত্বকের রোগ detect করতে পারে
- বাংলায় রোগের নাম ও পরামর্শ
- Scan history save হয়
- Top 3 সম্ভাবনা দেখায়

## 🛠️ Tech Stack

| Part        | Technology                           |
| ----------- | ------------------------------------ |
| Mobile App  | Flutter (Dart)                       |
| AI Model    | Python + TensorFlow + MobileNetV2    |
| Backend API | FastAPI                              |
| Dataset     | DermNet (15,000+ images, 23 classes) |

## 📊 Model Performance

- Training Images: 12,453
- Validation Images: 3,104
- Classes: 23
- Epochs: 10
- Accuracy: ~34% (CPU trained)

## 🚀 How to Run

### Backend (Python)

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Frontend (Flutter)

```bash
cd flutter_app
flutter pub get
flutter run
```

## 📁 Project Structure

skin-disease-detector/
├── backend/
│   ├── model/          ← AI Model
│   ├── main.py         ← FastAPI Server
│   ├── train_model.py  ← CNN Training
│   └── requirements.txt
└── flutter_app/
└── lib/
└── main.dart   ← Flutter UI


## 👨‍💻 Developer
- Name: Ibrahim Khan
- University: Bangladesh University of Business and Technology (BUBT)
- Country: Bangladesh 🇧🇩


