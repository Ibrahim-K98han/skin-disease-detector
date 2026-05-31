# FastAPI দিয়ে API বানাচ্ছি যেটা Flutter call করবে
from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
import tensorflow as tf
import numpy as np
from PIL import Image
import io
import json

# FastAPI app তৈরি
app = FastAPI(title="Skin Disease Detection API")

# CORS — Flutter app কে API access দেওয়ার জন্য
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # সব origin থেকে access দিচ্ছি
    allow_methods=["*"],
    allow_headers=["*"],
)

# Model এবং class names load করা
print("Model load হচ্ছে...")
model = tf.keras.models.load_model('model/skin_disease_model.h5')

with open('model/class_names.json', 'r') as f:
    class_names = json.load(f)

print(f"✅ Model ready! {len(class_names)} ধরনের রোগ detect করতে পারব")

# ছবি প্রসেস করার function
def prepare_image(image_bytes):
    # Bytes থেকে ছবি খুলছি
    img = Image.open(io.BytesIO(image_bytes))
    
    # RGB তে convert (কিছু ছবি RGBA বা Grayscale হতে পারে)
    img = img.convert('RGB')
    
    # Model এর জন্য 224x224 size এ আনছি
    img = img.resize((224, 224))
    
    # Numpy array তে convert
    img_array = np.array(img)
    
    # Pixel value 0-1 এর মধ্যে আনছি
    img_array = img_array / 255.0
    
    # Batch dimension যোগ করছি (1, 224, 224, 3)
    img_array = np.expand_dims(img_array, axis=0)
    
    return img_array

# Main API endpoint — Flutter এখানে ছবি পাঠাবে
@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    try:
        # Flutter থেকে পাঠানো ছবি read করছি
        image_bytes = await file.read()
        
        # ছবি প্রসেস করছি
        img_array = prepare_image(image_bytes)
        
        # Model দিয়ে predict করছি
        predictions = model.predict(img_array)
        
        # সবচেয়ে বেশি probability কোনটার
        predicted_index = np.argmax(predictions[0])
        predicted_disease = class_names[predicted_index]
        confidence = float(predictions[0][predicted_index]) * 100
        
        # Top 3 result বের করছি
        top3_indices = np.argsort(predictions[0])[-3:][::-1]
        top3_results = [
            {
                "disease": class_names[i],
                "confidence": round(float(predictions[0][i]) * 100, 2)
            }
            for i in top3_indices
        ]
        
        # Flutter এ result পাঠাচ্ছি
        return {
            "success": True,
            "predicted_disease": predicted_disease,
            "confidence": round(confidence, 2),
            "top3": top3_results
        }
        
    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }

# Server চালু আছে কিনা check করার endpoint
@app.get("/")
def health_check():
    return {"status": "✅ Server চলছে!"}