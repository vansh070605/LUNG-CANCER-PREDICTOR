-- Create the database
CREATE DATABASE IF NOT EXISTS lung_cancer_db;
USE lung_cancer_db;

-- Table: Users (for authentication)
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    date_of_birth DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL
);

-- Table: User Medical History
CREATE TABLE IF NOT EXISTS medical_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    family_history_of_cancer ENUM('yes', 'no', 'unknown') DEFAULT 'unknown',
    years_smoking INT DEFAULT 0,
    packs_per_day DECIMAL(3,1) DEFAULT 0.0,
    previous_lung_diseases TEXT,
    occupational_exposure ENUM('yes', 'no', 'unknown') DEFAULT 'unknown',
    occupational_details TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Table: Symptoms (stores detailed symptom information)
CREATE TABLE IF NOT EXISTS symptoms (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    severity_scale INT DEFAULT 3 COMMENT 'Scale from 1-5, with 5 being most severe',
    related_to_lung_cancer BOOLEAN DEFAULT TRUE
);

-- Table: Predictions (stores user symptoms and prediction results)
CREATE TABLE IF NOT EXISTS predictions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    age INT CHECK (age BETWEEN 0 AND 120),
    gender ENUM('Male', 'Female', 'Other') NOT NULL,
    smoking ENUM('yes', 'no') NOT NULL,
    cough ENUM('yes', 'no') NOT NULL,
    chest_pain ENUM('yes', 'no') NOT NULL,
    fatigue ENUM('yes', 'no') NOT NULL,
    shortness_of_breath ENUM('yes', 'no') NOT NULL,
    prediction VARCHAR(255) NOT NULL,
    risk_score DECIMAL(5,2) DEFAULT 0.0,
    prediction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: User Predictions (links users to their predictions)
CREATE TABLE IF NOT EXISTS user_predictions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    prediction_id INT,
    notes TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (prediction_id) REFERENCES predictions(id) ON DELETE CASCADE
);

-- Table: Medical Recommendations
CREATE TABLE IF NOT EXISTS recommendations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    risk_level ENUM('Low', 'Moderate', 'High') NOT NULL,
    recommendation_text TEXT NOT NULL,
    resource_links TEXT
);

-- Table: User Feedback (for system improvement)
CREATE TABLE IF NOT EXISTS user_feedback (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    prediction_id INT,
    feedback_text TEXT NOT NULL,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (prediction_id) REFERENCES predictions(id) ON DELETE SET NULL
);

-- Table: Deleted Predictions Log
CREATE TABLE IF NOT EXISTS deleted_predictions_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    deleted_prediction_id INT,
    deleted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data for testing
-- Users
-- INSERT INTO users (name, email, password_hash, date_of_birth) 
-- VALUES 
-- ('John Doe', 'john@example.com', '$2b$12$ILv4xGHgz0DzFOEI8WtCre6GX6KtSQa/D1Yyz7.TqVw9AYyRlGK6y', '1980-05-15'),  -- Password: password123
-- ('Jane Smith', 'jane@example.com', '$2b$12$ILv4xGHgz0DzFOEI8WtCre6GX6KtSQa/D1Yyz7.TqVw9AYyRlGK6y', '1992-03-21');

-- Medical History
-- INSERT INTO medical_history (user_id, family_history_of_cancer, years_smoking, packs_per_day, previous_lung_diseases, occupational_exposure)
-- VALUES
-- (1, 'yes', 15, 1.5, 'Chronic bronchitis', 'yes'),
-- (2, 'no', 0, 0.0, 'None', 'no');

-- Symptoms
-- INSERT INTO symptoms (name, description, severity_scale, related_to_lung_cancer)
-- VALUES
-- ('Persistent Cough', 'A cough that lasts for more than 2-3 weeks and doesn\'t improve', 4, TRUE),
-- ('Chest Pain', 'Pain in the chest area that may worsen with deep breathing or coughing', 5, TRUE),
-- ('Shortness of Breath', 'Feeling breathless or having difficulty breathing', 4, TRUE),
-- ('Fatigue', 'Feeling unusually tired or lacking energy', 3, TRUE),
-- ('Hoarseness', 'Changes in voice, such as hoarseness or raspiness', 2, TRUE),
-- ('Unexplained Weight Loss', 'Losing weight without trying', 5, TRUE);

-- Predictions
-- INSERT INTO predictions (age, gender, smoking, cough, chest_pain, fatigue, shortness_of_breath, prediction, risk_score) 
-- VALUES 
-- (45, 'Male', 'yes', 'yes', 'no', 'yes', 'yes', 'High risk of lung cancer', 12.5),
-- (32, 'Female', 'no', 'yes', 'no', 'no', 'no', 'Low risk of lung cancer', 3.2),
-- (67, 'Male', 'yes', 'yes', 'yes', 'yes', 'yes', 'High risk of lung cancer', 15.8),
-- (28, 'Female', 'no', 'no', 'no', 'yes', 'no', 'Low risk of lung cancer', 2.1);

-- Link users to predictions
-- INSERT INTO user_predictions (user_id, prediction_id, notes) 
-- VALUES 
-- (1, 1, 'Initial assessment after developing cough'),
-- (1, 3, 'Follow-up after chest pain developed'),
-- (2, 2, 'Routine checkup');

-- Recommendations
-- INSERT INTO recommendations (risk_level, recommendation_text, resource_links)
-- VALUES
-- ('Low', 'Maintain a healthy lifestyle. If you smoke, consider quitting. Schedule regular check-ups with your doctor.', 'https://www.cancer.org/healthy/stay-away-from-tobacco.html'),
-- ('Moderate', 'Schedule an appointment with your doctor to discuss your symptoms. Consider a chest X-ray or CT scan for further evaluation.', 'https://www.cancer.org/cancer/lung-cancer/detection-diagnosis-staging.html'),
-- ('High', 'Contact your doctor immediately to schedule comprehensive testing. This may include imaging tests and possibly a biopsy.', 'https://www.cancer.org/cancer/lung-cancer/treating.html');

-- User Feedback
-- INSERT INTO user_feedback (user_id, prediction_id, feedback_text, rating)
-- VALUES
-- (1, 1, 'The assessment was helpful and matched what my doctor told me.', 5),
-- (2, 2, 'I would have liked more detailed recommendations.', 3);

SELECT * from users;
SELECT * FROM user_predictions;
SHOW TABLES;

DROP TABLE IF EXISTS user_prediction;
DROP TABLE IF EXISTS prediction;
DROP TABLE IF EXISTS deleted_predictions;

CREATE OR REPLACE VIEW user_prediction_history AS
SELECT
    u.id AS user_id,
    u.name AS user_name,
    u.email AS user_email,
    p.id AS prediction_id,
    p.age, p.gender, p.smoking, p.cough, p.chest_pain, p.fatigue, p.shortness_of_breath,
    p.prediction, p.risk_score, p.prediction_date
FROM users u
JOIN user_predictions up ON u.id = up.user_id
JOIN predictions p ON up.prediction_id = p.id
ORDER BY p.prediction_date DESC;

DELIMITER $$
CREATE TRIGGER after_prediction_delete
AFTER DELETE ON predictions
FOR EACH ROW
BEGIN
    INSERT INTO deleted_predictions_log (deleted_prediction_id) VALUES (OLD.id);
END $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE update_all_risk_scores()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE pred_id INT;
    DECLARE cur CURSOR FOR SELECT id FROM predictions;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO pred_id;
        IF done THEN
            LEAVE read_loop;
        END IF;
        -- Example: set risk_score to 0 for demonstration
        UPDATE predictions SET risk_score = 0 WHERE id = pred_id;
    END LOOP;
    CLOSE cur;
END $$
DELIMITER ;