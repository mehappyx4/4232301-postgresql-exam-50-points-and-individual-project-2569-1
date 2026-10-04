-- สร้างฐานข้อมูลสำหรับระบบทะเบียนนักศึกษาเพื่อใช้งานจริง (Production-Ready Schema ตามโจทย์ 100%)
CREATE DATABASE IF NOT EXISTS student_registration_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE student_registration_db;

-- ==========================================
-- 1. โมดูลโครงสร้างองค์กร (Organization Module)
-- ==========================================

CREATE TABLE Faculties (
    faculty_id INT AUTO_INCREMENT PRIMARY KEY,
    faculty_code VARCHAR(10) UNIQUE NOT NULL,
    faculty_name_th VARCHAR(100) NOT NULL,
    faculty_name_en VARCHAR(100)
) ENGINE=InnoDB;

CREATE TABLE Departments (
    dept_id INT AUTO_INCREMENT PRIMARY KEY,
    faculty_id INT NOT NULL,
    dept_code VARCHAR(10) UNIQUE NOT NULL,
    dept_name_th VARCHAR(100) NOT NULL,
    FOREIGN KEY (faculty_id) REFERENCES Faculties(faculty_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Programs (
    program_id INT AUTO_INCREMENT PRIMARY KEY,
    dept_id INT NOT NULL,
    degree_level VARCHAR(20) NOT NULL,
    program_name_th VARCHAR(150) NOT NULL,
    total_credits_required INT NOT NULL,
    FOREIGN KEY (dept_id) REFERENCES Departments(dept_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ==========================================
-- 2. โมดูลบุคลากร (People Module)
-- ==========================================

CREATE TABLE Instructors (
    instructor_id INT AUTO_INCREMENT PRIMARY KEY,
    dept_id INT,
    employee_code VARCHAR(20) UNIQUE NOT NULL,
    title VARCHAR(50),
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    academic_status VARCHAR(20) DEFAULT 'Active',
    FOREIGN KEY (dept_id) REFERENCES Departments(dept_id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE Students (
    student_id VARCHAR(15) PRIMARY KEY,
    program_id INT,
    advisor_id INT,
    national_id VARCHAR(13) UNIQUE,
    title VARCHAR(20),
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    entry_year INT NOT NULL,
    entry_term VARCHAR(10) NOT NULL,
    student_status VARCHAR(20) DEFAULT 'Normal',
    cumulative_gpa DECIMAL(3,2) DEFAULT 0.00,
    FOREIGN KEY (program_id) REFERENCES Programs(program_id) ON DELETE SET NULL,
    FOREIGN KEY (advisor_id) REFERENCES Instructors(instructor_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ==========================================
-- 3. โมดูลรายวิชา (Course Module)
-- ==========================================

CREATE TABLE Courses (
    course_id VARCHAR(15) PRIMARY KEY,
    dept_id INT,
    course_name_th VARCHAR(150) NOT NULL,
    course_name_en VARCHAR(150),
    total_credits INT NOT NULL,
    lecture_hours INT DEFAULT 0,
    lab_hours INT DEFAULT 0,
    self_study_hours INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (dept_id) REFERENCES Departments(dept_id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE Prerequisites (
    prereq_id INT AUTO_INCREMENT PRIMARY KEY,
    target_course_id VARCHAR(15) NOT NULL,
    required_course_id VARCHAR(15) NOT NULL,
    min_grade_required VARCHAR(2),
    FOREIGN KEY (target_course_id) REFERENCES Courses(course_id) ON DELETE CASCADE,
    FOREIGN KEY (required_course_id) REFERENCES Courses(course_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ==========================================
-- 4. โมดูลการเปิดสอนและตารางเรียน (Class & Schedule Module)
-- ==========================================

CREATE TABLE Academic_Terms (
    term_id INT AUTO_INCREMENT PRIMARY KEY,
    academic_year INT NOT NULL,
    semester INT NOT NULL,
    start_date DATE,
    end_date DATE,
    UNIQUE KEY unique_term (academic_year, semester)
) ENGINE=InnoDB;

CREATE TABLE Classes (
    class_id INT AUTO_INCREMENT PRIMARY KEY,
    course_id VARCHAR(15) NOT NULL,
    term_id INT NOT NULL,
    section_number INT NOT NULL,
    instructor_id INT,
    max_capacity INT NOT NULL,
    current_enrolled INT DEFAULT 0,
    class_status VARCHAR(20) DEFAULT 'Open',
    FOREIGN KEY (course_id) REFERENCES Courses(course_id) ON DELETE CASCADE,
    FOREIGN KEY (term_id) REFERENCES Academic_Terms(term_id) ON DELETE CASCADE,
    FOREIGN KEY (instructor_id) REFERENCES Instructors(instructor_id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE Class_Schedules (
    schedule_id INT AUTO_INCREMENT PRIMARY KEY,
    class_id INT NOT NULL,
    day_of_week VARCHAR(10),
    start_time TIME,
    end_time TIME,
    room_number VARCHAR(30),
    type VARCHAR(10),
    FOREIGN KEY (class_id) REFERENCES Classes(class_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ==========================================
-- 5. โมดูลการลงทะเบียนและเกรด (Registration & Grading Module)
-- ==========================================

CREATE TABLE Grading_Rules (
    grade VARCHAR(2) PRIMARY KEY,
    grade_point DECIMAL(2,1),
    is_calculated BOOLEAN NOT NULL,
    description VARCHAR(50)
) ENGINE=InnoDB;

CREATE TABLE Enrollments (
    enrollment_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    student_id VARCHAR(15) NOT NULL,
    class_id INT NOT NULL,
    enrollment_status VARCHAR(20) DEFAULT 'Enrolled',
    grade VARCHAR(2) NULL,
    registration_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES Students(student_id) ON DELETE CASCADE,
    FOREIGN KEY (class_id) REFERENCES Classes(class_id) ON DELETE CASCADE,
    FOREIGN KEY (grade) REFERENCES Grading_Rules(grade) ON DELETE SET NULL,
    UNIQUE KEY unique_enrollment (student_id, class_id)
) ENGINE=InnoDB;


-- =============================================================================
-- Insert Examples (ตัวอย่างข้อมูลเพื่อการทดสอบให้ครบทุก Table ตามลำดับ)
-- =============================================================================

INSERT INTO Faculties (faculty_code, faculty_name_th, faculty_name_en) VALUES 
('SCI', 'คณะวิทยาศาสตร์และเทคโนโลยี', 'Faculty of Science and Technology'),
('ENG', 'คณะวิศวกรรมศาสตร์', 'Faculty of Engineering');

INSERT INTO Departments (faculty_id, dept_code, dept_name_th) VALUES 
(1, 'CS', 'วิทยาการคอมพิวเตอร์'),
(2, 'CPE', 'วิศวกรรมคอมพิวเตอร์');

INSERT INTO Programs (dept_id, degree_level, program_name_th, total_credits_required) VALUES 
(1, 'Bachelor', 'วิทยาศาสตรบัณฑิต สาขาวิชาวิทยาการคอมพิวเตอร์', 132),
(2, 'Bachelor', 'วิศวกรรมศาสตรบัณฑิต สาขาวิชาวิศวกรรมคอมพิวเตอร์', 144);

INSERT INTO Instructors (dept_id, employee_code, title, first_name, last_name, academic_status) VALUES 
(1, 'EMP001', 'ผศ.ดร.', 'ภานุวัฒน์', 'เกียรติยศ', 'Active'),
(2, 'EMP002', 'รศ.ดร.', 'นารี', 'รุ่งเรือง', 'Active');

INSERT INTO Students (student_id, program_id, advisor_id, national_id, title, first_name, last_name, entry_year, entry_term, student_status, cumulative_gpa) VALUES 
('66010001', 1, 1, '1101100000001', 'นาย', 'กิตติ', 'พาณิชย์', 2023, '1', 'Normal', 3.50),
('66010002', 1, 1, '1101100000002', 'นาย', 'ณัฐวุฒิ', 'ใจกล้า', 2023, '1', 'Normal', 3.25);

INSERT INTO Courses (course_id, dept_id, course_name_th, course_name_en, total_credits, lecture_hours, lab_hours, self_study_hours, is_active) VALUES 
('CS101', 1, 'วิทยาการคอมพิวเตอร์เบื้องต้น', 'Intro to Computer Science', 3, 2, 2, 5, TRUE),
('CS202', 1, 'โครงสร้างข้อมูล', 'Data Structures', 3, 3, 0, 6, TRUE);

INSERT INTO Prerequisites (target_course_id, required_course_id, min_grade_required) VALUES 
('CS202', 'CS101', 'C');

INSERT INTO Academic_Terms (academic_year, semester, start_date, end_date) VALUES 
(2026, 1, '2026-08-01', '2026-12-15');

INSERT INTO Classes (course_id, term_id, section_number, instructor_id, max_capacity, current_enrolled, class_status) VALUES 
('CS101', 1, 1, 1, 40, 2, 'Open'),
('CS202', 1, 1, 2, 40, 0, 'Open');

INSERT INTO Class_Schedules (class_id, day_of_week, start_time, end_time, room_number, type) VALUES 
(1, 'MON', '09:00:00', '11:00:00', 'IT-101', 'Lec'),
(1, 'WED', '13:00:00', '15:00:00', 'IT-102', 'Lab');

INSERT INTO Grading_Rules (grade, grade_point, is_calculated, description) VALUES 
('A', 4.0, TRUE, 'Excellent'),
('B+', 3.5, TRUE, 'Very Good'),
('B', 3.0, TRUE, 'Good'),
('C+', 2.5, TRUE, 'Fairly Good'),
('C', 2.0, TRUE, 'Fair'),
('D+', 1.5, TRUE, 'Poor'),
('D', 1.0, TRUE, 'Very Poor'),
('F', 0.0, TRUE, 'Fail'),
('W', NULL, FALSE, 'Withdraw'),
('S', NULL, FALSE, 'Satisfactory'),
('U', NULL, FALSE, 'Unsatisfactory'),
('I', NULL, FALSE, 'Incomplete');

INSERT INTO Enrollments (student_id, class_id, enrollment_status, grade) VALUES 
('66010001', 1, 'Enrolled', 'A'),
('66010002', 1, 'Enrolled', 'B+');
