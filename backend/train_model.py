import tensorflow as tf
from tensorflow.keras import layers, models
from tensorflow.keras.preprocessing.image import ImageDataGenerator
import json
import os

# Path ঠিক করছি
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATASET_PATH = os.path.join(BASE_DIR, 'dataset', 'train')
MODEL_SAVE_PATH = os.path.join(BASE_DIR, 'model', 'skin_disease_model.h5')
CLASS_NAMES_PATH = os.path.join(BASE_DIR, 'model', 'class_names.json')

IMG_SIZE = (224, 224)
BATCH_SIZE = 32
EPOCHS = 20

print(f"✅ Dataset path: {DATASET_PATH}")
print(f"✅ Dataset exists: {os.path.exists(DATASET_PATH)}")

# Data augmentation
train_datagen = ImageDataGenerator(
    rescale=1./255,
    rotation_range=20,
    width_shift_range=0.2,
    height_shift_range=0.2,
    horizontal_flip=True,
    validation_split=0.2
)

print("Dataset load হচ্ছে...")
train_generator = train_datagen.flow_from_directory(
    DATASET_PATH,
    target_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    class_mode='categorical',
    subset='training'
)

val_generator = train_datagen.flow_from_directory(
    DATASET_PATH,
    target_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    class_mode='categorical',
    subset='validation'
)

print(f"✅ মোট রোগের ধরন: {train_generator.num_classes}")

# MobileNetV2 model
print("Model তৈরি হচ্ছে...")
base_model = tf.keras.applications.MobileNetV2(
    input_shape=(224, 224, 3),
    include_top=False,
    weights='imagenet'
)
base_model.trainable = False

model = models.Sequential([
    base_model,
    layers.GlobalAveragePooling2D(),
    layers.Dense(128, activation='relu'),
    layers.Dropout(0.3),
    layers.Dense(train_generator.num_classes, activation='softmax')
])

model.compile(
    optimizer='adam',
    loss='categorical_crossentropy',
    metrics=['accuracy']
)

print("Training শুরু হচ্ছে... (১০-৩০ মিনিট সময় লাগতে পারে)")
history = model.fit(
    train_generator,
    epochs=EPOCHS,
    validation_data=val_generator
)

# Save
model.save(MODEL_SAVE_PATH)
print(f"✅ Model save হয়েছে!")

class_names = list(train_generator.class_indices.keys())
with open(CLASS_NAMES_PATH, 'w') as f:
    json.dump(class_names, f)
print(f"✅ Class names save হয়েছে! মোট: {len(class_names)} ধরনের রোগ")