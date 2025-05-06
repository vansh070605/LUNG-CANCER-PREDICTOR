# 🫁 LUNG CANCER PREDICTOR

![Python](https://img.shields.io/badge/Python-3.12-blue)
![Flask](https://img.shields.io/badge/Flask-3.0.2-green)
![MySQL](https://img.shields.io/badge/MySQL-8.0-orange)
![License](https://img.shields.io/badge/License-MIT-yellow)

---

	⁠Welcome! 🚀
>
	⁠*LUNG CANCER PREDICTOR* is a modern web application for predicting lung cancer risk based on user symptoms and medical history. Built with Flask and MySQL, featuring a beautiful glassmorphism UI design.

---

## ✨ Features

•⁠  ⁠🔐 *User Authentication*
  - Secure registration and login
  - Password hashing
  - Session management
  - JWT token support

•⁠  ⁠🎯 *Risk Assessment*
  - Age and gender-based analysis
  - Smoking status evaluation
  - Symptom assessment
  - Real-time risk score calculation

•⁠  ⁠📊 *Medical History*
  - Family history tracking
  - Smoking history
  - Previous lung diseases
  - Occupational exposure

•⁠  ⁠📱 *Modern UI/UX*
  - Glassmorphism design
  - Dark theme with red accents
  - Responsive layout
  - Interactive forms
  - Real-time feedback

•⁠  ⁠📈 *Data Management*
  - Prediction history
  - User feedback system
  - Medical recommendations
  - Symptom database

---

## 🖼️ Screenshots & GIFs

> _See the app in action!_

### 🔑 Login & Registration
![Login GIF](https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExbG9naW4tc2FtcGxlLWdpZi9naXBoLmdpZg/giphy.gif)

### 🩺 Lung Cancer Risk Prediction
![Prediction GIF](https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExcHJlZGljdC1zYW1wbGUtZ2lmL2dpcGguZ2lm/giphy.gif)

### 📊 Dashboard & Results
![Dashboard GIF](https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExZGFzaGJvYXJkLXNob3ctZ2lmL2dpcGguZ2lm/giphy.gif)

> _Have you deployed or used this app? [Contribute your own screenshots or GIFs!](https://github.com/vansh070605/LUNG-CANCER-PREDICTOR/pulls)_

---

## 🎬 Quick Demo

> _Watch a quick walkthrough of the main features!_
>
	⁠![Demo Placeholder](https://via.placeholder.com/600x300?text=Demo+GIF)

---

## 🛠️ Technologies Used

•⁠  ⁠*Backend*
  - Python 3.12
  - Flask 3.0.2
  - MySQL 8.0
  - Flask-Login
  - Flask-Bcrypt
  - PyJWT

•⁠  ⁠*Frontend*
  - HTML5
  - CSS3
  - JavaScript
  - Glassmorphism Design

•⁠  ⁠*Database*
  - MySQL
  - Stored Procedures
  - Views
  - Triggers

---

## 🚀 Getting Started

### Prerequisites

•⁠  ⁠Python 3.12 or higher
•⁠  ⁠MySQL 8.0 or higher
•⁠  ⁠pip (Python package manager)

### Installation

1.⁠ ⁠*Clone the repository*
   ⁠ bash
   git clone https://github.com/vansh070605/LUNG-CANCER-PREDICTOR.git
   cd LUNG-CANCER-PREDICTOR
    ⁠

2.⁠ ⁠*Create and activate virtual environment*
   ⁠ bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
    ⁠

3.⁠ ⁠*Install dependencies*
   ⁠ bash
   pip install -r requirements.txt
    ⁠

4.⁠ ⁠*Set up the database*
   ⁠ bash
   mysql -u root -p < database/lung_cancer_db.sql
    ⁠

5.⁠ ⁠*Configure environment variables*
   Create a ⁠ .env ⁠ file in the root directory:
   
⁠    SECRET_KEY=your-secret-key
   JWT_SECRET_KEY=your-jwt-secret-key
   DB_PASSWORD=your-mysql-password
    ⁠

6.⁠ ⁠*Run the application*
   ⁠ bash
   python app.py
    ⁠

---

## 🗂️ Project Structure

```
LUNG-CANCER-PREDICTOR/
├── app.py                 # Main Flask application
├── config.py              # Configuration settings
├── requirements.txt       # Python dependencies
├── README.md              # Project documentation
├── survey lung cancer.csv # Sample dataset
├── database/
│   └── lung_cancer_db.sql # MySQL database schema & procedures
├── model/
│   ├── dummy_model.py     # Placeholder for ML model code
│   └── model.pkl          # (Optional) Trained model file
├── static/
│   └── styles.css         # CSS styles
├── templates/
│   ├── base.html          # Base template
│   ├── dashboard.html     # User dashboard
│   ├── history.html       # Prediction history
│   ├── index.html         # Landing page
│   ├── intro.html         # Introduction page
│   ├── login.html         # Login form
│   ├── predict.html       # Prediction form
│   ├── register.html      # Registration form
│   └── result.html        # Prediction result
└── .gitignore             # Git ignore file
```

---

## 🚀 Features
- User registration and login (with hashed passwords)
- Lung cancer risk prediction based on symptoms and history
- Prediction history and feedback
- Medical recommendations
- Concurrency control: Only one user can make a prediction at a time (global lock)
- Recovery mechanisms: Transaction logging, backup, and point-in-time recovery
- Modern, responsive UI

---

## 🧩 Key Database Features
- **Lock Management:** Only one user can make a prediction at a time (global lock on `predictions` table).
- **Version Control:** Prevents lost updates and supports optimistic concurrency.
- **Transaction Log:** All changes are logged for audit and recovery.
- **Backup & Recovery:** Daily backups and point-in-time recovery procedures.
- **Deadlock Detection:** Automatic cleanup of expired locks.

---

## 💡 Usage
- Register a new user or log in.
- Navigate to the Predict page and fill out the form.
- If another user is already predicting, you will see an error message.
- View your prediction history and feedback.

---

## 📄 License
This project is for educational purposes.

---

## 🔒 Security Features

•⁠  ⁠Password hashing using Flask-Bcrypt
•⁠  ⁠JWT token authentication
•⁠  ⁠SQL injection prevention
•⁠  ⁠Input validation
•⁠  ⁠Session management
•⁠  ⁠Protected routes

---

## 🎨 UI Features

•⁠  ⁠Modern glassmorphism design
•⁠  ⁠Dark theme with red accents
•⁠  ⁠Responsive layout
•⁠  ⁠Interactive forms
•⁠  ⁠Real-time feedback
•⁠  ⁠Animated transitions
•⁠  ⁠Mobile-friendly design

---

## 📊 Database Schema

•⁠  ⁠*users*: User information
•⁠  ⁠*medical_history*: Medical background
•⁠  ⁠*predictions*: Risk assessment results
•⁠  ⁠*user_predictions*: User-prediction mapping
•⁠  ⁠*symptoms*: Symptom database
•⁠  ⁠*recommendations*: Medical advice
•⁠  ⁠*user_feedback*: User feedback

---

## 🤝 Contributing

1.⁠ ⁠Fork the repository
2.⁠ ⁠Create your feature branch (⁠ git checkout -b feature/AmazingFeature ⁠)
3.⁠ ⁠Commit your changes (⁠ git commit -m 'Add some AmazingFeature' ⁠)
4.⁠ ⁠Push to the branch (⁠ git push origin feature/AmazingFeature ⁠)
5.⁠ ⁠Open a Pull Request

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👥 Authors

•⁠  ⁠*Vansh*  
•⁠  ⁠*Hirav Kadikar*

---

## 🙏 Acknowledgments

•⁠  ⁠Medical data sources
•⁠  ⁠Open source community
•⁠  ⁠Flask documentation
•⁠  ⁠MySQL documentation

---

## 💬 Community & Support

•⁠  ⁠[GitHub Discussions](https://github.com/vansh070605/LUNG-CANCER-PREDICTOR/discussions)
•⁠  ⁠[Report Issues](https://github.com/vansh070605/LUNG-CANCER-PREDICTOR/issues)
•⁠  ⁠[Contact Vansh on Twitter](https://twitter.com/vansh070605)

---

## ⭐ Show your support

	⁠*Give a ⭐️ if this project helped you!*
> 
	⁠We appreciate your feedback and contributions!

## 📞 Contact

Vansh - [@vansh070605](https://twitter.com/vansh070605)
Project Link: [https://github.com/vansh070605/LUNG-CANCER-PREDICTOR](https://github.com/vansh070605/LUNG-CANCER-PREDICTOR)
