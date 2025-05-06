from flask import Flask, request, jsonify, render_template, session, redirect, url_for, flash
from flask_cors import CORS
import mysql.connector
from mysql.connector import Error
import os
from werkzeug.security import generate_password_hash, check_password_hash
import jwt
from datetime import datetime, timedelta
from functools import wraps
import uuid
import json

app = Flask(__name__, static_folder='static', template_folder='templates')
CORS(app)
app.config['SECRET_KEY'] = os.urandom(24)
app.config['JWT_EXPIRATION_DELTA'] = timedelta(days=1)
app.secret_key = 'your_secret_key_here'  # Set a secret key for sessions

# Database Connection with transaction support
def create_connection():
    try:
        connection = mysql.connector.connect(
            host='localhost',
            user='root',  # Change as per your MySQL setup
            password='root',  # Change as per your MySQL setup
            database='lung_cancer_db',
            autocommit=False  # Disable autocommit for transaction control
        )
        return connection
    except Error as e:
        print(f"Error connecting to MySQL: {e}")
        return None

# JWT token required decorator
def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        
        if 'x-access-token' in request.headers:
            token = request.headers['x-access-token']
        
        if not token:
            return jsonify({'message': 'Token is missing!'}), 401
        
        try:
            data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=["HS256"])
            connection = create_connection()
            cursor = connection.cursor(dictionary=True)
            cursor.execute("SELECT * FROM users WHERE id = %s", (data['user_id'],))
            current_user = cursor.fetchone()
            cursor.close()
            connection.close()
        except:
            return jsonify({'message': 'Token is invalid!'}), 401
            
        return f(current_user, *args, **kwargs)
    
    return decorated

# Helper: login required decorator
def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function

# Transaction management decorator
def transaction_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        connection = create_connection()
        if not connection:
            return jsonify({'message': 'Database connection error'}), 500
        
        try:
            cursor = connection.cursor()
            # Start transaction
            cursor.execute("START TRANSACTION")
            
            # Execute the function
            result = f(connection, cursor, *args, **kwargs)
            
            # Commit transaction
            connection.commit()
            return result
        except Exception as e:
            # Rollback on error
            connection.rollback()
            return jsonify({'message': f'Transaction failed: {str(e)}'}), 500
        finally:
            cursor.close()
            connection.close()
    
    return decorated

# Lock management functions
def acquire_lock(connection, cursor, table_name, record_id, lock_type, user_id, timeout_minutes=5):
    try:
        lock_id = str(uuid.uuid4())
        cursor.execute("""
            INSERT INTO lock_management 
            (table_name, record_id, lock_type, lock_holder, lock_timeout)
            VALUES (%s, %s, %s, %s, DATE_ADD(NOW(), INTERVAL %s MINUTE))
        """, (table_name, record_id, lock_type, user_id, timeout_minutes))
        connection.commit()
        return lock_id
    except Error as e:
        connection.rollback()
        return None

def release_lock(connection, cursor, table_name, record_id, user_id):
    try:
        cursor.execute("""
            DELETE FROM lock_management 
            WHERE table_name = %s AND record_id = %s AND lock_holder = %s
        """, (table_name, record_id, user_id))
        connection.commit()
        return True
    except Error as e:
        connection.rollback()
        return False

# Version control functions
def check_version(connection, cursor, table_name, record_id, expected_version):
    try:
        cursor.execute("""
            SELECT version_number 
            FROM version_control 
            WHERE table_name = %s AND record_id = %s
        """, (table_name, record_id))
        result = cursor.fetchone()
        if not result or result[0] != expected_version:
            return False
        return True
    except Error:
        return False

def update_version(connection, cursor, table_name, record_id, user_id):
    try:
        cursor.execute("""
            INSERT INTO version_control (table_name, record_id, version_number, modified_by)
            VALUES (%s, %s, 1, %s)
            ON DUPLICATE KEY UPDATE 
            version_number = version_number + 1,
            modified_by = %s
        """, (table_name, record_id, user_id, user_id))
        connection.commit()
        return True
    except Error:
        connection.rollback()
        return False

# Basic lung cancer risk assessment model
def predict_lung_cancer_risk(age, gender, smoking, cough, chest_pain, fatigue, shortness_of_breath):
    # This is a simplified risk assessment model for demonstration
    # In a real application, you'd use a trained ML model
    
    risk_score = 0
    
    # Age risk factor
    if age < 40:
        risk_score += 1
    elif 40 <= age < 50:
        risk_score += 2
    elif 50 <= age < 60:
        risk_score += 3
    else:
        risk_score += 4
    
    # Gender risk factor
    if gender == 'Male':
        risk_score += 2
    else:
        risk_score += 1
    
    # Smoking risk factor (highest weight)
    if smoking == 'yes':
        risk_score += 5
    
    # Symptoms risk factors
    if cough == 'yes':
        risk_score += 2
    if chest_pain == 'yes':
        risk_score += 3
    if fatigue == 'yes':
        risk_score += 1
    if shortness_of_breath == 'yes':
        risk_score += 3
    
    # Risk assessment based on total score
    if risk_score < 6:
        prediction = "Low risk of lung cancer"
    elif 6 <= risk_score < 10:
        prediction = "Moderate risk of lung cancer"
    else:
        prediction = "High risk of lung cancer"
    
    return {
        "prediction": prediction,
        "risk_score": float(risk_score)
    }

# Routes
@app.route('/')
def home():
    if 'user_id' in session:
        return redirect(url_for('dashboard'))
    return render_template('intro.html')

@app.route('/register', methods=['GET', 'POST'])
@transaction_required
def register(connection, cursor):
    if request.method == 'GET':
        return render_template('register.html')
    
    data = request.form if request.form else request.get_json()
    name = data.get('name')
    email = data.get('email')
    password = data.get('password')
    
    if not name or not email or not password:
        flash('Missing required fields', 'error')
        return render_template('register.html')
    
    try:
        # Check if email already exists
        cursor.execute("SELECT id FROM users WHERE email = %s", (email,))
        if cursor.fetchone():
            flash('Email already registered', 'error')
            return render_template('register.html')
        
        # Insert new user
        hashed_password = generate_password_hash(password)
        cursor.execute(
            "INSERT INTO users (name, email, password_hash) VALUES (%s, %s, %s)",
            (name, email, hashed_password)
        )
        
        user_id = cursor.lastrowid
        
        # Initialize version control
        update_version(connection, cursor, 'users', user_id, user_id)
        
        flash('User registered successfully. Please login.', 'success')
        return redirect(url_for('login'))
    except Error as e:
        flash(f'Registration failed: {str(e)}', 'error')
        return render_template('register.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'GET':
        return render_template('login.html')
    if request.method == 'POST':
        data = request.form if request.form else request.get_json()
        email = data.get('email')
        password = data.get('password')
        if not email or not password:
            flash('Missing email or password', 'error')
            return render_template('login.html')
        connection = create_connection()
        if not connection:
            flash('Database connection error', 'error')
            return render_template('login.html')
        cursor = connection.cursor(dictionary=True)
        try:
            cursor.execute("SELECT * FROM users WHERE Email = %s", (email,))
            user = cursor.fetchone()
            if not user or not check_password_hash(user['password_hash'], password):
                flash('Invalid credentials', 'error')
                return render_template('login.html')
            session['user_id'] = user['ID']
            session['name'] = user['Name']
            session['email'] = user['Email']
            return redirect(url_for('dashboard'))
        except Error as e:
            flash(f'Login failed: {str(e)}', 'error')
            return render_template('login.html')
        finally:
            cursor.close()
            connection.close()

@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))

@app.route('/dashboard')
@login_required
def dashboard():
    return render_template('dashboard.html', name=session.get('name'))

@app.route('/predict', methods=['GET', 'POST'])
@login_required
@transaction_required
def predict(connection, cursor):
    if request.method == 'GET':
        return render_template('predict.html', user_id=session.get('user_id'))
    
    user_id = session.get('user_id')
    data = request.form if request.form else request.get_json()
    
    try:
        # Acquire lock for user's predictions
        lock_id = acquire_lock(connection, cursor, 'predictions', user_id, 'EXCLUSIVE', user_id)
        if not lock_id:
            flash('System is busy. Please try again.', 'error')
            return render_template('predict.html', user_id=user_id)
        
        # Process prediction
        prediction_result = predict_lung_cancer_risk(
            int(data.get('age')),
            data.get('gender'),
            data.get('smoking'),
            data.get('cough'),
            data.get('chest_pain'),
            data.get('fatigue'),
            data.get('shortness_of_breath')
        )
        
        # Insert prediction with version control
        cursor.execute(
            """INSERT INTO predictions 
            (age, gender, smoking, cough, chest_pain, fatigue, shortness_of_breath, 
             prediction, risk_score, version)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, 1)""",
            (data.get('age'), data.get('gender'), data.get('smoking'),
             data.get('cough'), data.get('chest_pain'), data.get('fatigue'),
             data.get('shortness_of_breath'), prediction_result["prediction"],
             prediction_result["risk_score"])
        )
        
        prediction_id = cursor.lastrowid
        
        # Link prediction to user
        cursor.execute(
            "INSERT INTO user_predictions (user_id, prediction_id) VALUES (%s, %s)",
            (user_id, prediction_id)
        )
        
        # Initialize version control for prediction
        update_version(connection, cursor, 'predictions', prediction_id, user_id)
        
        # Release lock
        release_lock(connection, cursor, 'predictions', user_id, user_id)
        
        return render_template('result.html',
                             prediction=prediction_result["prediction"],
                             risk_score=prediction_result["risk_score"],
                             timestamp=datetime.now().isoformat())
    except Exception as e:
        flash(f'Error processing prediction: {str(e)}', 'error')
        return render_template('predict.html', user_id=user_id)

@app.route('/user/predictions', methods=['GET'])
@login_required
def get_user_predictions():
    connection = create_connection()
    if not connection:
        flash('Database connection error', 'error')
        return render_template('history.html', predictions=[])
    cursor = connection.cursor(dictionary=True)
    try:
        cursor.execute("""
            SELECT p.* FROM predictions p
            JOIN user_predictions up ON p.id = up.prediction_id
            WHERE up.user_id = %s
            ORDER BY p.prediction_date DESC
        """, (session.get('user_id'),))
        predictions = cursor.fetchall()
        for prediction in predictions:
            prediction['prediction_date'] = prediction['prediction_date'].isoformat() if prediction['prediction_date'] else ''
        return render_template('history.html', predictions=predictions)
    except Error as e:
        flash(f'Error fetching predictions: {str(e)}', 'error')
        return render_template('history.html', predictions=[])
    finally:
        cursor.close()
        connection.close()

@app.route('/predictions', methods=['GET'])
def get_all_predictions():
    connection = create_connection()
    if not connection:
        return jsonify({'message': 'Database connection error'}), 500
    
    cursor = connection.cursor(dictionary=True)
    
    try:
        cursor.execute("""
            SELECT p.*, u.Name AS user_name, u.Email AS user_email
            FROM predictions p
            JOIN user_predictions up ON p.id = up.prediction_id
            JOIN users u ON up.user_id = u.ID
            ORDER BY p.prediction_date DESC
        """)
        predictions = cursor.fetchall()
        
        # Convert datetime objects to strings for JSON serialization
        for prediction in predictions:
            prediction['prediction_date'] = prediction['prediction_date'].isoformat() if prediction['prediction_date'] else ''
        
        return jsonify({'predictions': predictions}), 200
    except Error as e:
        return jsonify({'message': f'Error fetching predictions: {str(e)}'}), 500
    finally:
        cursor.close()
        connection.close()

# --- Medical History ---
@app.route('/medical_history', methods=['GET', 'POST'])
@login_required
def medical_history():
    connection = create_connection()
    if not connection:
        flash('Database connection error', 'error')
        return render_template('medical_history.html', history=None)
    cursor = connection.cursor(dictionary=True)
    user_id = session.get('user_id')
    if request.method == 'POST':
        data = request.form
        try:
            cursor.execute("""
                INSERT INTO medical_history (user_id, family_history_of_cancer, years_smoking, packs_per_day, previous_lung_diseases, occupational_exposure, occupational_details)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                ON DUPLICATE KEY UPDATE family_history_of_cancer=VALUES(family_history_of_cancer), years_smoking=VALUES(years_smoking), packs_per_day=VALUES(packs_per_day), previous_lung_diseases=VALUES(previous_lung_diseases), occupational_exposure=VALUES(occupational_exposure), occupational_details=VALUES(occupational_details)
            """, (
                user_id,
                data.get('family_history_of_cancer'),
                data.get('years_smoking'),
                data.get('packs_per_day'),
                data.get('previous_lung_diseases'),
                data.get('occupational_exposure'),
                data.get('occupational_details')
            ))
            connection.commit()
            flash('Medical history updated!', 'success')
        except Error as e:
            connection.rollback()
            flash(f'Error: {str(e)}', 'error')
    cursor.execute("SELECT * FROM medical_history WHERE user_id = %s", (user_id,))
    history = cursor.fetchone()
    cursor.close()
    connection.close()
    return render_template('medical_history.html', history=history)

# --- Symptoms ---
@app.route('/symptoms')
@login_required
def symptoms():
    connection = create_connection()
    if not connection:
        flash('Database connection error', 'error')
        return render_template('symptoms.html', symptoms=[])
    cursor = connection.cursor(dictionary=True)
    cursor.execute("SELECT * FROM symptoms")
    symptoms = cursor.fetchall()
    cursor.close()
    connection.close()
    return render_template('symptoms.html', symptoms=symptoms)

# --- Recommendations ---
@app.route('/recommendations')
@login_required
def recommendations():
    connection = create_connection()
    if not connection:
        flash('Database connection error', 'error')
        return render_template('recommendations.html', recommendations=[])
    cursor = connection.cursor(dictionary=True)
    cursor.execute("SELECT * FROM recommendations")
    recommendations = cursor.fetchall()
    cursor.close()
    connection.close()
    return render_template('recommendations.html', recommendations=recommendations)

# --- User Feedback ---
@app.route('/feedback', methods=['GET', 'POST'])
@login_required
def feedback():
    connection = create_connection()
    if not connection:
        flash('Database connection error', 'error')
        return render_template('feedback.html', feedbacks=[])
    cursor = connection.cursor(dictionary=True)
    user_id = session.get('user_id')
    if request.method == 'POST':
        data = request.form
        try:
            cursor.execute("""
                INSERT INTO user_feedback (user_id, prediction_id, feedback_text, rating)
                VALUES (%s, %s, %s, %s)
            """, (user_id, data.get('prediction_id'), data.get('feedback_text'), data.get('rating')))
            connection.commit()
            flash('Feedback submitted!', 'success')
        except Error as e:
            connection.rollback()
            flash(f'Error: {str(e)}', 'error')
    cursor.execute("SELECT f.*, p.prediction FROM user_feedback f LEFT JOIN predictions p ON f.prediction_id = p.id WHERE f.user_id = %s ORDER BY f.created_at DESC", (user_id,))
    feedbacks = cursor.fetchall()
    cursor.close()
    connection.close()
    return render_template('feedback.html', feedbacks=feedbacks)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5050, debug=True)