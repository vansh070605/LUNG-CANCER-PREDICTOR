import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, accuracy_score

# Step 1: Load the dataset
data = pd.read_csv('survey lung cancer.csv')

# Step 2: Preprocess the data
# Convert target column to binary (YES -> 1, NO -> 0)
data['LUNG_CANCER'] = data['LUNG_CANCER'].map({'YES': 1, 'NO': 0})

# Encode categorical features
le = LabelEncoder()
data['GENDER'] = le.fit_transform(data['GENDER'])  # M -> 1, F -> 0

# Step 3: Split features and target
X = data.drop('LUNG_CANCER', axis=1)
y = data['LUNG_CANCER']

# Step 4: Train-test split
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Step 5: Train a Random Forest model
model = RandomForestClassifier(random_state=42)
model.fit(X_train, y_train)

# Step 6: Evaluate
y_pred = model.predict(X_test)
print("Accuracy:", accuracy_score(y_test, y_pred))
print("\nClassification Report:\n", classification_report(y_test, y_pred))

# Step 7: Predict for new data (example)
sample = pd.DataFrame([{
    'GENDER': le.transform(['M'])[0],  # or 1
    'AGE': 65,
    'SMOKING': 2,
    'YELLOW_FINGERS': 2,
    'ANXIETY': 1,
    'PEER_PRESSURE': 2,
    'CHRONIC DISEASE': 2,
    'FATIGUE ': 2,
    'ALLERGY ': 1,
    'WHEEZING': 2,
    'ALCOHOL CONSUMING': 2,
    'COUGHING': 2,
    'SHORTNESS OF BREATH': 1,
    'SWALLOWING DIFFICULTY': 2,
    'CHEST PAIN': 1
}])

prediction = model.predict(sample)
print("Predicted Lung Cancer Risk (1=Yes, 0=No):", prediction[0])

import joblib
joblib.dump(model, 'model/model.pkl')


import numpy as np

# Load the model
loaded_model = joblib.load('model/model.pkl')

def predict_lung_cancer(data):
    # Ensure the order of features matches training data
    input_array = np.array([[
        int(data['Gender']),  # 1 = M, 0 = F
        int(data['Age']),
        int(data['Smoking']),
        1,  # YELLOW_FINGERS (you can later collect from form)
        1,  # ANXIETY
        1,  # PEER_PRESSURE
        1,  # CHRONIC DISEASE
        int(data['Fatigue']),
        1,  # ALLERGY
        1,  # WHEEZING
        1,  # ALCOHOL CONSUMING
        int(data['Cough']),
        int(data['Shortness_of_breath']),
        1,  # SWALLOWING DIFFICULTY
        int(data['Chest_Pain'])
    ]])

    prediction = loaded_model.predict(input_array)[0]
    return int(prediction)
