-- Create database if not exists
CREATE DATABASE IF NOT EXISTS massardb;
USE massardb;

-- Drop tables if they exist to allow clean re-runs
DROP TABLE IF EXISTS subject_results;
DROP TABLE IF EXISTS students;

-- Table: students
CREATE TABLE students (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code_massar VARCHAR(50) UNIQUE NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    result ENUM('Admis', 'Ajourné') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: subject_results
CREATE TABLE subject_results (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    subject_name VARCHAR(100) NOT NULL,
    grade DECIMAL(4,2) NOT NULL,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert 5 mock students with realistic Moroccan names, taalim.ma emails, and phone numbers
INSERT INTO students (code_massar, full_name, email, phone, result) VALUES
('K130029841', 'Yassine El Idrissi', 'y.elidrissi@taalim.ma', '+212661234567', 'Admis'),
('D145690832', 'Fatim-Zahra El Alami', 'fz.elalami@taalim.ma', '+212675987654', 'Admis'),
('R130987452', 'Amina Benslimane', 'a.benslimane@taalim.ma', '+212654321098', 'Ajourné'),
('M120934857', 'Mehdi Tagnaouti', 'm.tagnaouti@taalim.ma', '+212612987456', 'Admis'),
('G135764201', 'Ayoub Cherkaoui', 'a.cherkaoui@taalim.ma', '+212623456789', 'Ajourné');

-- Insert 3-4 subject results per student
-- Student 1: Yassine El Idrissi (K130029841) -> Admis
INSERT INTO subject_results (student_id, subject_name, grade) VALUES
(1, 'Mathématiques', 16.50),
(1, 'Physique-Chimie', 17.25),
(1, 'Sciences de la Vie et de la Terre', 15.00),
(1, 'Philosophie', 12.00);

-- Student 2: Fatim-Zahra El Alami (D145690832) -> Admis
INSERT INTO subject_results (student_id, subject_name, grade) VALUES
(2, 'Mathématiques', 19.00),
(2, 'Physique-Chimie', 18.50),
(2, 'Sciences de la Vie et de la Terre', 17.75),
(2, 'Philosophie', 14.50);

-- Student 3: Amina Benslimane (R130987452) -> Ajourné
INSERT INTO subject_results (student_id, subject_name, grade) VALUES
(3, 'Mathématiques', 08.50),
(3, 'Physique-Chimie', 09.00),
(3, 'Sciences de la Vie et de la Terre', 11.25),
(3, 'Philosophie', 09.50);

-- Student 4: Mehdi Tagnaouti (M120934857) -> Admis
INSERT INTO subject_results (student_id, subject_name, grade) VALUES
(4, 'Mathématiques', 13.00),
(4, 'Physique-Chimie', 12.50),
(4, 'Sciences de la Vie et de la Terre', 14.00),
(4, 'Philosophie', 11.00);

-- Student 5: Ayoub Cherkaoui (G135764201) -> Ajourné
INSERT INTO subject_results (student_id, subject_name, grade) VALUES
(5, 'Mathématiques', 07.00),
(5, 'Physique-Chimie', 08.50),
(5, 'Sciences de la Vie et de la Terre', 09.75),
(5, 'Philosophie', 10.00);
