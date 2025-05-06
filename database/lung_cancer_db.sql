-- Create the database
CREATE DATABASE IF NOT EXISTS lung_cancer_db;
USE lung_cancer_db;

-- Set transaction isolation level
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Table: Transaction Log
CREATE TABLE IF NOT EXISTS transaction_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_id VARCHAR(36) NOT NULL,
    table_name VARCHAR(50) NOT NULL,
    operation_type ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    record_id INT NOT NULL,
    old_values JSON,
    new_values JSON,
    user_id INT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('COMMITTED', 'ROLLED_BACK', 'PENDING') DEFAULT 'PENDING'
);

-- Table: Version Control
CREATE TABLE IF NOT EXISTS version_control (
    id INT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id INT NOT NULL,
    version_number INT NOT NULL DEFAULT 1,
    last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    modified_by INT,
    UNIQUE KEY (table_name, record_id)
);

-- Table: Lock Management
CREATE TABLE IF NOT EXISTS lock_management (
    id INT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id INT NOT NULL,
    lock_type ENUM('SHARED', 'EXCLUSIVE') NOT NULL,
    lock_holder INT NOT NULL,
    lock_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    lock_timeout TIMESTAMP,
    UNIQUE KEY (table_name, record_id)
);

-- Table: Users (for authentication)
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    date_of_birth DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    version INT DEFAULT 1
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
    version INT DEFAULT 1,
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
    prediction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    version INT DEFAULT 1
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

-- Create backup table for critical data
CREATE TABLE IF NOT EXISTS users_backup LIKE users;
CREATE TABLE IF NOT EXISTS predictions_backup LIKE predictions;
CREATE TABLE IF NOT EXISTS medical_history_backup LIKE medical_history;

-- Create stored procedure for backup
DELIMITER $$
CREATE PROCEDURE create_backup()
BEGIN
    DECLARE backup_timestamp TIMESTAMP;
    SET backup_timestamp = CURRENT_TIMESTAMP;
    
    -- Backup users
    INSERT INTO users_backup 
    SELECT *, backup_timestamp FROM users;
    
    -- Backup predictions
    INSERT INTO predictions_backup 
    SELECT *, backup_timestamp FROM predictions;
    
    -- Backup medical history
    INSERT INTO medical_history_backup 
    SELECT *, backup_timestamp FROM medical_history;
END $$
DELIMITER ;

-- Create stored procedure for point-in-time recovery
DELIMITER $$
CREATE PROCEDURE point_in_time_recovery(IN recovery_timestamp TIMESTAMP)
BEGIN
    -- Restore users
    UPDATE users u
    JOIN users_backup b ON u.id = b.id
    SET u.* = b.*
    WHERE b.backup_timestamp <= recovery_timestamp;
    
    -- Restore predictions
    UPDATE predictions p
    JOIN predictions_backup b ON p.id = b.id
    SET p.* = b.*
    WHERE b.backup_timestamp <= recovery_timestamp;
    
    -- Restore medical history
    UPDATE medical_history m
    JOIN medical_history_backup b ON m.id = b.id
    SET m.* = b.*
    WHERE b.backup_timestamp <= recovery_timestamp;
END $$
DELIMITER ;

-- Create trigger for transaction logging
DELIMITER $$
CREATE TRIGGER log_user_changes
AFTER UPDATE ON users
FOR EACH ROW
BEGIN
    INSERT INTO transaction_log (transaction_id, table_name, operation_type, record_id, old_values, new_values)
    VALUES (
        UUID(),
        'users',
        'UPDATE',
        NEW.id,
        JSON_OBJECT(
            'name', OLD.name,
            'email', OLD.email,
            'version', OLD.version
        ),
        JSON_OBJECT(
            'name', NEW.name,
            'email', NEW.email,
            'version', NEW.version
        )
    );
END $$
DELIMITER ;

-- Create stored procedure for deadlock detection
DELIMITER $$
CREATE PROCEDURE detect_deadlocks()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE lock_id INT;
    DECLARE cur CURSOR FOR 
        SELECT id FROM lock_management 
        WHERE lock_timeout < CURRENT_TIMESTAMP;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    
    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO lock_id;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Release expired locks
        DELETE FROM lock_management WHERE id = lock_id;
    END LOOP;
    CLOSE cur;
END $$
DELIMITER ;

-- Create event scheduler for regular maintenance
CREATE EVENT IF NOT EXISTS maintenance_schedule
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
    -- Create daily backup
    CALL create_backup();
    
    -- Clean up old transaction logs (keep last 30 days)
    DELETE FROM transaction_log 
    WHERE timestamp < DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 30 DAY);
    
    -- Check for deadlocks
    CALL detect_deadlocks();
END;

-- Enable event scheduler
SET GLOBAL event_scheduler = ON;

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

SELECT * FROM lock_management;

SELECT * FROM lock_management WHERE table_name = 'predictions' AND record_id = <user_id>;