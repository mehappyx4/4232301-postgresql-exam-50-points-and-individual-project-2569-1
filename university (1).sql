-- ==========================================
-- University Database (Multi-Schema)
-- PostgreSQL Implementation
-- ==========================================

-- Drop schemas if they exist to allow clean recreation
DROP SCHEMA IF EXISTS u5_lib CASCADE;
DROP SCHEMA IF EXISTS u6_hr CASCADE;
DROP SCHEMA IF EXISTS u4_fee CASCADE;
DROP SCHEMA IF EXISTS u3_grade CASCADE;
DROP SCHEMA IF EXISTS u2_enroll CASCADE;
DROP SCHEMA IF EXISTS u1_reg CASCADE;
DROP SCHEMA IF EXISTS core CASCADE;

-- Create Schemas in order
CREATE SCHEMA core;
CREATE SCHEMA u1_reg;
CREATE SCHEMA u2_enroll;
CREATE SCHEMA u3_grade;
CREATE SCHEMA u4_fee;
CREATE SCHEMA u6_hr;
CREATE SCHEMA u5_lib;

-- ==========================================
-- 1. Schema core (10 tables)
-- ==========================================

CREATE TABLE core.hr_institutes (
    institute_id SERIAL PRIMARY KEY,
    institute_code VARCHAR(50) UNIQUE,
    institute_name VARCHAR(255),
    address TEXT,
    established_date DATE
);

CREATE TABLE core.faculties (
    faculty_id VARCHAR(5) PRIMARY KEY,
    faculty_name VARCHAR(255),
    institute_id INT REFERENCES core.hr_institutes(institute_id) ON DELETE SET NULL
);

CREATE TABLE core.departments (
    department_id VARCHAR(5) PRIMARY KEY,
    department_name VARCHAR(255),
    faculty_id VARCHAR(5) NOT NULL REFERENCES core.faculties(faculty_id) ON DELETE CASCADE
);

CREATE TABLE core.majors (
    major_id VARCHAR(5) PRIMARY KEY,
    major_name VARCHAR(255),
    department_id VARCHAR(5) NOT NULL REFERENCES core.departments(department_id) ON DELETE CASCADE
);

CREATE TABLE core.courses (
    course_id VARCHAR(10) PRIMARY KEY,
    course_name VARCHAR(255),
    credits INT,
    department_id VARCHAR(5) REFERENCES core.departments(department_id) ON DELETE SET NULL
);

CREATE TABLE core.semesters (
    semester_id SERIAL PRIMARY KEY,
    academic_year INT,
    term INT,
    start_date DATE,
    end_date DATE
);

CREATE TABLE core.buildings (
    building_id VARCHAR(5) PRIMARY KEY,
    building_name VARCHAR(255)
);

CREATE TABLE core.rooms (
    room_id VARCHAR(10) PRIMARY KEY,
    building_id VARCHAR(5) NOT NULL REFERENCES core.buildings(building_id) ON DELETE CASCADE,
    capacity INT
);

CREATE TABLE core.students (
    student_id VARCHAR(10) PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    faculty_id VARCHAR(5) REFERENCES core.faculties(faculty_id) ON DELETE SET NULL,
    major_id VARCHAR(5) REFERENCES core.majors(major_id) ON DELETE SET NULL,
    enrollment_year INT
);

CREATE TABLE core.instructors (
    instructor_id VARCHAR(10) PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    department_id VARCHAR(5) REFERENCES core.departments(department_id) ON DELETE SET NULL,
    email VARCHAR(255) UNIQUE
);

-- ==========================================
-- 2. Schema u1_reg (5 tables)
-- ==========================================

CREATE TABLE u1_reg.prerequisites (
    course_id VARCHAR(10) REFERENCES core.courses(course_id) ON DELETE CASCADE,
    prerequisite_course_id VARCHAR(10) REFERENCES core.courses(course_id) ON DELETE CASCADE,
    PRIMARY KEY (course_id, prerequisite_course_id)
);

CREATE TABLE u1_reg.sections (
    section_id SERIAL PRIMARY KEY,
    course_id VARCHAR(10) REFERENCES core.courses(course_id) ON DELETE CASCADE,
    semester_id INT REFERENCES core.semesters(semester_id) ON DELETE CASCADE,
    instructor_id VARCHAR(10) REFERENCES core.instructors(instructor_id) ON DELETE SET NULL,
    room_id VARCHAR(10) REFERENCES core.rooms(room_id) ON DELETE SET NULL,
    schedule_time VARCHAR(255),
    max_seats INT
);

CREATE TABLE u1_reg.advisors (
    student_id VARCHAR(10) PRIMARY KEY REFERENCES core.students(student_id) ON DELETE CASCADE,
    instructor_id VARCHAR(10) REFERENCES core.instructors(instructor_id) ON DELETE CASCADE
);

CREATE TABLE u1_reg.scholarships (
    scholarship_id SERIAL PRIMARY KEY,
    scholarship_name VARCHAR(255),
    fund_amount DECIMAL(14,2)
);

CREATE TABLE u1_reg.student_scholarships (
    student_id VARCHAR(10) REFERENCES core.students(student_id) ON DELETE CASCADE,
    scholarship_id INT REFERENCES u1_reg.scholarships(scholarship_id) ON DELETE CASCADE,
    semester_id INT REFERENCES core.semesters(semester_id) ON DELETE CASCADE,
    awarded_date DATE DEFAULT CURRENT_DATE,
    PRIMARY KEY (student_id, scholarship_id, semester_id)
);

-- ==========================================
-- 3. Schema u2_enroll (1 table)
-- ==========================================

CREATE TABLE u2_enroll.enrollments (
    enrollment_id SERIAL PRIMARY KEY,
    student_id VARCHAR(10) REFERENCES core.students(student_id) ON DELETE CASCADE,
    section_id INT REFERENCES u1_reg.sections(section_id) ON DELETE CASCADE,
    course_id VARCHAR(10) REFERENCES core.courses(course_id) ON DELETE CASCADE,
    enrollment_date DATE,
    enrollment_status VARCHAR(50) DEFAULT 'ENROLLED',
    midterm_score DECIMAL(5,2),
    final_score DECIMAL(5,2),
    total_score DECIMAL(5,2) GENERATED ALWAYS AS (COALESCE(midterm_score,0) + COALESCE(final_score,0)) STORED,
    letter_grade VARCHAR(2),
    grade_point DECIMAL(3,2)
);

-- ==========================================
-- 4. Schema u3_grade (4 tables)
-- ==========================================

CREATE TABLE u3_grade.assignments (
    assignment_id SERIAL PRIMARY KEY,
    section_id INT REFERENCES u1_reg.sections(section_id) ON DELETE CASCADE,
    title VARCHAR(255),
    max_score DECIMAL(5,2),
    due_date DATE
);

CREATE TABLE u3_grade.student_scores (
    score_id SERIAL PRIMARY KEY,
    enrollment_id INT REFERENCES u2_enroll.enrollments(enrollment_id) ON DELETE CASCADE,
    assignment_id INT REFERENCES u3_grade.assignments(assignment_id) ON DELETE CASCADE,
    score_obtained DECIMAL(5,2)
);

CREATE TABLE u3_grade.attendance (
    attendance_id SERIAL PRIMARY KEY,
    enrollment_id INT REFERENCES u2_enroll.enrollments(enrollment_id) ON DELETE CASCADE,
    class_date DATE,
    status VARCHAR(50)
);

CREATE TABLE u3_grade.grade_change_logs (
    log_id SERIAL PRIMARY KEY,
    enrollment_id INT REFERENCES u2_enroll.enrollments(enrollment_id) ON DELETE CASCADE,
    old_grade VARCHAR(10),
    new_grade VARCHAR(10),
    changed_by VARCHAR(100),
    reason TEXT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- 5. Schema u4_fee (4 tables)
-- ==========================================

CREATE TABLE u4_fee.fee_types (
    fee_type_id SERIAL PRIMARY KEY,
    fee_name VARCHAR(255),
    description TEXT
);

CREATE TABLE u4_fee.invoices (
    invoice_id SERIAL PRIMARY KEY,
    student_id VARCHAR(10) REFERENCES core.students(student_id) ON DELETE CASCADE,
    semester_id INT REFERENCES core.semesters(semester_id) ON DELETE CASCADE,
    total_amount DECIMAL(14,2),
    issue_date DATE,
    due_date DATE,
    is_paid BOOLEAN
);

CREATE TABLE u4_fee.invoice_items (
    item_id SERIAL PRIMARY KEY,
    invoice_id INT REFERENCES u4_fee.invoices(invoice_id) ON DELETE CASCADE,
    fee_type_id INT REFERENCES u4_fee.fee_types(fee_type_id) ON DELETE CASCADE,
    enrollment_id INT REFERENCES u2_enroll.enrollments(enrollment_id) ON DELETE SET NULL,
    amount DECIMAL(14,2),
    description TEXT
);

CREATE TABLE u4_fee.payments (
    payment_id SERIAL PRIMARY KEY,
    invoice_id INT REFERENCES u4_fee.invoices(invoice_id) ON DELETE CASCADE,
    amount_paid DECIMAL(14,2),
    payment_date TIMESTAMP,
    payment_method VARCHAR(50)
);

-- ==========================================
-- 6. Schema u6_hr (32 tables)
-- ==========================================

CREATE TABLE u6_hr.academic_ranks (
    rank_id SERIAL PRIMARY KEY,
    rank_name VARCHAR(255),
    abbreviation VARCHAR(50)
);

CREATE TABLE u6_hr.employment_types (
    employment_type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(255),
    description TEXT
);

CREATE TABLE u6_hr.positions (
    position_id SERIAL PRIMARY KEY,
    position_title VARCHAR(255),
    description TEXT,
    salary_level INT
);

CREATE TABLE u6_hr.leave_types (
    leave_type_id SERIAL PRIMARY KEY,
    leave_name VARCHAR(255),
    max_days_per_year INT
);

CREATE TABLE u6_hr.certifications (
    certification_id SERIAL PRIMARY KEY,
    cert_name VARCHAR(255),
    issuing_org VARCHAR(255)
);

CREATE TABLE u6_hr.committees (
    committee_id SERIAL PRIMARY KEY,
    committee_name VARCHAR(255),
    description TEXT
);

CREATE TABLE u6_hr.internal_trainings (
    training_id SERIAL PRIMARY KEY,
    topic_name VARCHAR(255),
    organizer VARCHAR(255),
    training_date DATE
);

CREATE TABLE u6_hr.faculty_members (
    faculty_member_id SERIAL PRIMARY KEY,
    employee_code VARCHAR(50),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255),
    department_id VARCHAR(5) REFERENCES core.departments(department_id) ON DELETE SET NULL,
    rank_id INT REFERENCES u6_hr.academic_ranks(rank_id) ON DELETE SET NULL,
    employment_type_id INT REFERENCES u6_hr.employment_types(employment_type_id) ON DELETE SET NULL,
    instructor_id VARCHAR(10) REFERENCES core.instructors(instructor_id) ON DELETE SET NULL,
    hire_date DATE,
    status VARCHAR(50)
);

CREATE TABLE u6_hr.staff (
    staff_id SERIAL PRIMARY KEY,
    staff_code VARCHAR(50),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255),
    department_id VARCHAR(5) REFERENCES core.departments(department_id) ON DELETE SET NULL,
    position_id INT REFERENCES u6_hr.positions(position_id) ON DELETE SET NULL,
    employment_type_id INT REFERENCES u6_hr.employment_types(employment_type_id) ON DELETE SET NULL,
    hire_date DATE,
    status VARCHAR(50)
);

CREATE TABLE u6_hr.assets (
    asset_id SERIAL PRIMARY KEY,
    asset_code VARCHAR(50),
    asset_name VARCHAR(255)
);

CREATE TABLE u6_hr.payroll_runs (
    payroll_run_id SERIAL PRIMARY KEY,
    pay_month INT,
    pay_year INT
);

CREATE TABLE u6_hr.curricula (
    curriculum_id SERIAL PRIMARY KEY,
    curriculum_name VARCHAR(255),
    department_id VARCHAR(5) REFERENCES core.departments(department_id) ON DELETE SET NULL,
    effective_year INT
);

CREATE TABLE u6_hr.publications (
    publication_id SERIAL PRIMARY KEY,
    faculty_member_id INT REFERENCES u6_hr.faculty_members(faculty_member_id) ON DELETE CASCADE,
    title TEXT,
    published_year INT
);

CREATE TABLE u6_hr.research_grants (
    grant_id SERIAL PRIMARY KEY,
    grant_name VARCHAR(255),
    faculty_member_id INT REFERENCES u6_hr.faculty_members(faculty_member_id) ON DELETE SET NULL,
    allocated_budget DECIMAL(14,2)
);

CREATE TABLE u6_hr.department_budgets (
    budget_id SERIAL PRIMARY KEY,
    department_id VARCHAR(5) REFERENCES core.departments(department_id) ON DELETE CASCADE,
    fiscal_year INT,
    allocated_amount DECIMAL(14,2)
);

-- Polymorphic Tables in u6_hr
CREATE TABLE u6_hr.employee_dependents (
    dependent_id SERIAL PRIMARY KEY,
    owner_type VARCHAR(50),
    owner_id INT,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    relationship VARCHAR(100),
    birth_date DATE,
    education_level VARCHAR(100),
    is_eligible_benefit BOOLEAN
);

CREATE TABLE u6_hr.employee_addresses (
    address_id SERIAL PRIMARY KEY,
    owner_type VARCHAR(50),
    owner_id INT,
    address_line1 TEXT,
    city VARCHAR(100),
    province VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100) DEFAULT 'Thailand'
);

CREATE TABLE u6_hr.employee_documents (
    document_id SERIAL PRIMARY KEY,
    owner_type VARCHAR(50),
    owner_id INT,
    document_type VARCHAR(100),
    file_path TEXT,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE u6_hr.asset_allocations (
    allocation_id SERIAL PRIMARY KEY,
    asset_id INT REFERENCES u6_hr.assets(asset_id) ON DELETE CASCADE,
    owner_type VARCHAR(50),
    owner_id INT,
    assigned_date DATE,
    return_date DATE
);

CREATE TABLE u6_hr.attendance_logs (
    attendance_id SERIAL PRIMARY KEY,
    owner_type VARCHAR(50),
    owner_id INT,
    check_in TIMESTAMP,
    check_out TIMESTAMP,
    status VARCHAR(50) DEFAULT 'Present'
);

CREATE TABLE u6_hr.performance_appraisals (
    appraisal_id SERIAL PRIMARY KEY,
    owner_type VARCHAR(50),
    owner_id INT,
    evaluator_id INT,
    fiscal_year INT,
    score DECIMAL(5,2),
    comments TEXT
);

CREATE TABLE u6_hr.employee_certifications (
    emp_cert_id SERIAL PRIMARY KEY,
    owner_type VARCHAR(50),
    owner_id INT,
    certification_id INT REFERENCES u6_hr.certifications(certification_id) ON DELETE CASCADE,
    issue_date DATE,
    expire_date DATE
);

CREATE TABLE u6_hr.leave_requests (
    request_id SERIAL PRIMARY KEY,
    owner_type VARCHAR(50),
    owner_id INT,
    leave_type_id INT REFERENCES u6_hr.leave_types(leave_type_id) ON DELETE SET NULL,
    start_date DATE,
    end_date DATE,
    reason TEXT,
    status VARCHAR(50) DEFAULT 'Pending'
);

CREATE TABLE u6_hr.leave_approvals (
    approval_id SERIAL PRIMARY KEY,
    request_id INT REFERENCES u6_hr.leave_requests(request_id) ON DELETE CASCADE,
    approver_id INT,
    approval_status VARCHAR(50),
    approval_date DATE
);

CREATE TABLE u6_hr.salaries (
    salary_id SERIAL PRIMARY KEY,
    owner_type VARCHAR(50),
    owner_id INT,
    base_salary DECIMAL(14,2),
    effective_date DATE
);

CREATE TABLE u6_hr.salary_increments (
    increment_id SERIAL PRIMARY KEY,
    owner_type VARCHAR(50),
    owner_id INT,
    previous_salary DECIMAL(14,2),
    new_salary DECIMAL(14,2),
    increment_date DATE,
    reason TEXT
);

CREATE TABLE u6_hr.payroll_details (
    detail_id SERIAL PRIMARY KEY,
    payroll_run_id INT REFERENCES u6_hr.payroll_runs(payroll_run_id) ON DELETE CASCADE,
    owner_type VARCHAR(50),
    owner_id INT,
    earnings DECIMAL(14,2),
    deductions DECIMAL(14,2),
    net_pay DECIMAL(14,2)
);

CREATE TABLE u6_hr.committee_members (
    member_id SERIAL PRIMARY KEY,
    committee_id INT REFERENCES u6_hr.committees(committee_id) ON DELETE CASCADE,
    owner_type VARCHAR(50),
    owner_id INT,
    role_in_committee VARCHAR(100) DEFAULT 'Member'
);

CREATE TABLE u6_hr.employee_trainings (
    emp_training_id SERIAL PRIMARY KEY,
    owner_type VARCHAR(50),
    owner_id INT,
    training_id INT REFERENCES u6_hr.internal_trainings(training_id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'Completed'
);

CREATE TABLE u6_hr.exit_interviews (
    exit_id SERIAL PRIMARY KEY,
    owner_type VARCHAR(50),
    owner_id INT,
    resignation_date DATE,
    reason TEXT,
    feedback TEXT
);

CREATE TABLE u6_hr.room_bookings (
    booking_id SERIAL PRIMARY KEY,
    room_number VARCHAR(100),
    owner_type VARCHAR(50),
    owner_id INT,
    booking_date DATE,
    start_time TIME,
    end_time TIME,
    purpose TEXT
);

CREATE TABLE u6_hr.emergency_contacts (
    contact_id SERIAL PRIMARY KEY,
    owner_type VARCHAR(50),
    owner_id INT,
    contact_name VARCHAR(255),
    relationship VARCHAR(100),
    phone_number VARCHAR(50)
);

-- ==========================================
-- 7. Schema u5_lib (11 tables)
-- ==========================================

CREATE TABLE u5_lib.media_types (
    media_type_id VARCHAR(10) PRIMARY KEY,
    type_name VARCHAR(255)
);

CREATE TABLE u5_lib.categories (
    category_id VARCHAR(10) PRIMARY KEY,
    dewey_code VARCHAR(50),
    category_name VARCHAR(255)
);

CREATE TABLE u5_lib.resources (
    resource_id VARCHAR(20) PRIMARY KEY,
    title TEXT,
    author VARCHAR(255),
    publisher VARCHAR(255),
    publish_year INT,
    isbn VARCHAR(50),
    category_id VARCHAR(10) REFERENCES u5_lib.categories(category_id) ON DELETE SET NULL,
    media_type_id VARCHAR(10) REFERENCES u5_lib.media_types(media_type_id) ON DELETE SET NULL
);

CREATE TABLE u5_lib.resource_items (
    item_id VARCHAR(20) PRIMARY KEY,
    resource_id VARCHAR(20) REFERENCES u5_lib.resources(resource_id) ON DELETE CASCADE,
    location_zone VARCHAR(100),
    status VARCHAR(50) DEFAULT 'Available'
);

CREATE TABLE u5_lib.digital_resources (
    digital_id VARCHAR(20) PRIMARY KEY,
    resource_id VARCHAR(20) REFERENCES u5_lib.resources(resource_id) ON DELETE CASCADE,
    file_path_url TEXT,
    file_format VARCHAR(50),
    access_level VARCHAR(50)
);

CREATE TABLE u5_lib.members (
    member_id VARCHAR(20) PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(50),
    member_type VARCHAR(50),
    faculty_department VARCHAR(255),
    student_id VARCHAR(10) REFERENCES core.students(student_id) ON DELETE SET NULL,
    hr_faculty_member_id INT REFERENCES u6_hr.faculty_members(faculty_member_id) ON DELETE SET NULL,
    hr_staff_id INT REFERENCES u6_hr.staff(staff_id) ON DELETE SET NULL
);

CREATE TABLE u5_lib.borrow_transactions (
    transaction_id VARCHAR(20) PRIMARY KEY,
    member_id VARCHAR(20) REFERENCES u5_lib.members(member_id) ON DELETE SET NULL,
    item_id VARCHAR(20) REFERENCES u5_lib.resource_items(item_id) ON DELETE SET NULL,
    borrow_date DATE,
    due_date DATE,
    return_date DATE,
    status VARCHAR(50)
);

CREATE TABLE u5_lib.reservations (
    reservation_id VARCHAR(20) PRIMARY KEY,
    member_id VARCHAR(20) REFERENCES u5_lib.members(member_id) ON DELETE SET NULL,
    resource_id VARCHAR(20) REFERENCES u5_lib.resources(resource_id) ON DELETE SET NULL,
    reserve_date DATE,
    status VARCHAR(50) DEFAULT 'Pending'
);

CREATE TABLE u5_lib.fines (
    fine_id VARCHAR(20) PRIMARY KEY,
    transaction_id VARCHAR(20) REFERENCES u5_lib.borrow_transactions(transaction_id) ON DELETE CASCADE,
    fine_amount DECIMAL(10,2),
    fine_status VARCHAR(50) DEFAULT 'Unpaid',
    payment_date DATE
);

CREATE TABLE u5_lib.meeting_rooms (
    room_id VARCHAR(10) PRIMARY KEY,
    room_name VARCHAR(255),
    capacity INT,
    location_floor VARCHAR(50),
    status VARCHAR(50) DEFAULT 'Available'
);

CREATE TABLE u5_lib.room_reservations (
    room_reservation_id VARCHAR(20) PRIMARY KEY,
    room_id VARCHAR(10) REFERENCES u5_lib.meeting_rooms(room_id) ON DELETE SET NULL,
    member_id VARCHAR(20) REFERENCES u5_lib.members(member_id) ON DELETE SET NULL,
    booker_name VARCHAR(255),
    booker_phone VARCHAR(50),
    booking_date DATE,
    start_time TIME,
    end_time TIME,
    purpose TEXT,
    status VARCHAR(50) DEFAULT 'Confirmed',
    CONSTRAINT chk_lib_max_3_hours CHECK (
        (end_time - start_time) <= interval '3 hours' 
        AND end_time > start_time
    )
);


-- ==========================================
-- SAMPLE DATA (10 rows per table)
-- ==========================================

-- Schema: core
INSERT INTO core.hr_institutes (institute_code, institute_name, address, established_date) VALUES
('INST01', 'Institute 1', 'Address 1', '2000-01-01'),
('INST02', 'Institute 2', 'Address 2', '2000-01-01'),
('INST03', 'Institute 3', 'Address 3', '2000-01-01'),
('INST04', 'Institute 4', 'Address 4', '2000-01-01'),
('INST05', 'Institute 5', 'Address 5', '2000-01-01'),
('INST06', 'Institute 6', 'Address 6', '2000-01-01'),
('INST07', 'Institute 7', 'Address 7', '2000-01-01'),
('INST08', 'Institute 8', 'Address 8', '2000-01-01'),
('INST09', 'Institute 9', 'Address 9', '2000-01-01'),
('INST10', 'Institute 10', 'Address 10', '2000-01-01');
INSERT INTO core.faculties (faculty_id, faculty_name, institute_id) VALUES
('F01', 'Faculty 1', 1),
('F02', 'Faculty 2', 2),
('F03', 'Faculty 3', 3),
('F04', 'Faculty 4', 4),
('F05', 'Faculty 5', 5),
('F06', 'Faculty 6', 6),
('F07', 'Faculty 7', 7),
('F08', 'Faculty 8', 8),
('F09', 'Faculty 9', 9),
('F10', 'Faculty 10', 10);
INSERT INTO core.departments (department_id, department_name, faculty_id) VALUES
('D01', 'Department 1', 'F01'),
('D02', 'Department 2', 'F02'),
('D03', 'Department 3', 'F03'),
('D04', 'Department 4', 'F04'),
('D05', 'Department 5', 'F05'),
('D06', 'Department 6', 'F06'),
('D07', 'Department 7', 'F07'),
('D08', 'Department 8', 'F08'),
('D09', 'Department 9', 'F09'),
('D10', 'Department 10', 'F10');
INSERT INTO core.majors (major_id, major_name, department_id) VALUES
('M01', 'Major 1', 'D01'),
('M02', 'Major 2', 'D02'),
('M03', 'Major 3', 'D03'),
('M04', 'Major 4', 'D04'),
('M05', 'Major 5', 'D05'),
('M06', 'Major 6', 'D06'),
('M07', 'Major 7', 'D07'),
('M08', 'Major 8', 'D08'),
('M09', 'Major 9', 'D09'),
('M10', 'Major 10', 'D10');
INSERT INTO core.courses (course_id, course_name, credits, department_id) VALUES
('C01', 'Course 1', 3, 'D01'),
('C02', 'Course 2', 3, 'D02'),
('C03', 'Course 3', 3, 'D03'),
('C04', 'Course 4', 3, 'D04'),
('C05', 'Course 5', 3, 'D05'),
('C06', 'Course 6', 3, 'D06'),
('C07', 'Course 7', 3, 'D07'),
('C08', 'Course 8', 3, 'D08'),
('C09', 'Course 9', 3, 'D09'),
('C10', 'Course 10', 3, 'D10');
INSERT INTO core.semesters (academic_year, term, start_date, end_date) VALUES
(2021, 1, '2021-08-01', '2021-12-15'),
(2022, 1, '2022-08-01', '2022-12-15'),
(2023, 1, '2023-08-01', '2023-12-15'),
(2024, 1, '2024-08-01', '2024-12-15'),
(2025, 1, '2025-08-01', '2025-12-15'),
(2026, 1, '2026-08-01', '2026-12-15'),
(2027, 1, '2027-08-01', '2027-12-15'),
(2028, 1, '2028-08-01', '2028-12-15'),
(2029, 1, '2029-08-01', '2029-12-15'),
(2020, 1, '2020-08-01', '2020-12-15');
INSERT INTO core.buildings (building_id, building_name) VALUES
('B01', 'Building 1'),
('B02', 'Building 2'),
('B03', 'Building 3'),
('B04', 'Building 4'),
('B05', 'Building 5'),
('B06', 'Building 6'),
('B07', 'Building 7'),
('B08', 'Building 8'),
('B09', 'Building 9'),
('B10', 'Building 10');
INSERT INTO core.rooms (room_id, building_id, capacity) VALUES
('R01', 'B01', 50),
('R02', 'B02', 50),
('R03', 'B03', 50),
('R04', 'B04', 50),
('R05', 'B05', 50),
('R06', 'B06', 50),
('R07', 'B07', 50),
('R08', 'B08', 50),
('R09', 'B09', 50),
('R10', 'B10', 50);
INSERT INTO core.students (student_id, first_name, last_name, faculty_id, major_id, enrollment_year) VALUES
('S01', 'FName1', 'LName1', 'F01', 'M01', 2020),
('S02', 'FName2', 'LName2', 'F02', 'M02', 2020),
('S03', 'FName3', 'LName3', 'F03', 'M03', 2020),
('S04', 'FName4', 'LName4', 'F04', 'M04', 2020),
('S05', 'FName5', 'LName5', 'F05', 'M05', 2020),
('S06', 'FName6', 'LName6', 'F06', 'M06', 2020),
('S07', 'FName7', 'LName7', 'F07', 'M07', 2020),
('S08', 'FName8', 'LName8', 'F08', 'M08', 2020),
('S09', 'FName9', 'LName9', 'F09', 'M09', 2020),
('S10', 'FName10', 'LName10', 'F10', 'M10', 2020);
INSERT INTO core.instructors (instructor_id, first_name, last_name, department_id, email) VALUES
('I01', 'IFName1', 'ILName1', 'D01', 'inst1@uni.edu'),
('I02', 'IFName2', 'ILName2', 'D02', 'inst2@uni.edu'),
('I03', 'IFName3', 'ILName3', 'D03', 'inst3@uni.edu'),
('I04', 'IFName4', 'ILName4', 'D04', 'inst4@uni.edu'),
('I05', 'IFName5', 'ILName5', 'D05', 'inst5@uni.edu'),
('I06', 'IFName6', 'ILName6', 'D06', 'inst6@uni.edu'),
('I07', 'IFName7', 'ILName7', 'D07', 'inst7@uni.edu'),
('I08', 'IFName8', 'ILName8', 'D08', 'inst8@uni.edu'),
('I09', 'IFName9', 'ILName9', 'D09', 'inst9@uni.edu'),
('I10', 'IFName10', 'ILName10', 'D10', 'inst10@uni.edu');

-- Schema: u1_reg
INSERT INTO u1_reg.prerequisites (course_id, prerequisite_course_id) VALUES
('C01', 'C10'),
('C02', 'C01'),
('C03', 'C02'),
('C04', 'C03'),
('C05', 'C04'),
('C06', 'C05'),
('C07', 'C06'),
('C08', 'C07'),
('C09', 'C08'),
('C10', 'C09');
INSERT INTO u1_reg.sections (course_id, semester_id, instructor_id, room_id, schedule_time, max_seats) VALUES
('C01', 1, 'I01', 'R01', 'Mon 9:00', 30),
('C02', 2, 'I02', 'R02', 'Mon 9:00', 30),
('C03', 3, 'I03', 'R03', 'Mon 9:00', 30),
('C04', 4, 'I04', 'R04', 'Mon 9:00', 30),
('C05', 5, 'I05', 'R05', 'Mon 9:00', 30),
('C06', 6, 'I06', 'R06', 'Mon 9:00', 30),
('C07', 7, 'I07', 'R07', 'Mon 9:00', 30),
('C08', 8, 'I08', 'R08', 'Mon 9:00', 30),
('C09', 9, 'I09', 'R09', 'Mon 9:00', 30),
('C10', 10, 'I10', 'R10', 'Mon 9:00', 30);
INSERT INTO u1_reg.advisors (student_id, instructor_id) VALUES
('S01', 'I01'),
('S02', 'I02'),
('S03', 'I03'),
('S04', 'I04'),
('S05', 'I05'),
('S06', 'I06'),
('S07', 'I07'),
('S08', 'I08'),
('S09', 'I09'),
('S10', 'I10');
INSERT INTO u1_reg.scholarships (scholarship_name, fund_amount) VALUES
('Scholarship 1', 10000.00),
('Scholarship 2', 10000.00),
('Scholarship 3', 10000.00),
('Scholarship 4', 10000.00),
('Scholarship 5', 10000.00),
('Scholarship 6', 10000.00),
('Scholarship 7', 10000.00),
('Scholarship 8', 10000.00),
('Scholarship 9', 10000.00),
('Scholarship 10', 10000.00);
INSERT INTO u1_reg.student_scholarships (student_id, scholarship_id, semester_id, awarded_date) VALUES
('S01', 1, 1, '2020-01-01'),
('S02', 2, 2, '2020-01-01'),
('S03', 3, 3, '2020-01-01'),
('S04', 4, 4, '2020-01-01'),
('S05', 5, 5, '2020-01-01'),
('S06', 6, 6, '2020-01-01'),
('S07', 7, 7, '2020-01-01'),
('S08', 8, 8, '2020-01-01'),
('S09', 9, 9, '2020-01-01'),
('S10', 10, 10, '2020-01-01');

-- Schema: u2_enroll
INSERT INTO u2_enroll.enrollments (student_id, section_id, course_id, enrollment_date, enrollment_status, midterm_score, final_score, letter_grade, grade_point) VALUES
('S01', 1, 'C01', '2020-08-01', 'ENROLLED', 40.0, 45.0, 'A', 4.0),
('S02', 2, 'C02', '2020-08-01', 'ENROLLED', 40.0, 45.0, 'A', 4.0),
('S03', 3, 'C03', '2020-08-01', 'ENROLLED', 40.0, 45.0, 'A', 4.0),
('S04', 4, 'C04', '2020-08-01', 'ENROLLED', 40.0, 45.0, 'A', 4.0),
('S05', 5, 'C05', '2020-08-01', 'ENROLLED', 40.0, 45.0, 'A', 4.0),
('S06', 6, 'C06', '2020-08-01', 'ENROLLED', 40.0, 45.0, 'A', 4.0),
('S07', 7, 'C07', '2020-08-01', 'ENROLLED', 40.0, 45.0, 'A', 4.0),
('S08', 8, 'C08', '2020-08-01', 'ENROLLED', 40.0, 45.0, 'A', 4.0),
('S09', 9, 'C09', '2020-08-01', 'ENROLLED', 40.0, 45.0, 'A', 4.0),
('S10', 10, 'C10', '2020-08-01', 'ENROLLED', 40.0, 45.0, 'A', 4.0);

-- Schema: u3_grade
INSERT INTO u3_grade.assignments (section_id, title, max_score, due_date) VALUES
(1, 'Assignment 1', 100.0, '2020-09-01'),
(2, 'Assignment 2', 100.0, '2020-09-01'),
(3, 'Assignment 3', 100.0, '2020-09-01'),
(4, 'Assignment 4', 100.0, '2020-09-01'),
(5, 'Assignment 5', 100.0, '2020-09-01'),
(6, 'Assignment 6', 100.0, '2020-09-01'),
(7, 'Assignment 7', 100.0, '2020-09-01'),
(8, 'Assignment 8', 100.0, '2020-09-01'),
(9, 'Assignment 9', 100.0, '2020-09-01'),
(10, 'Assignment 10', 100.0, '2020-09-01');
INSERT INTO u3_grade.student_scores (enrollment_id, assignment_id, score_obtained) VALUES
(1, 1, 85.0),
(2, 2, 85.0),
(3, 3, 85.0),
(4, 4, 85.0),
(5, 5, 85.0),
(6, 6, 85.0),
(7, 7, 85.0),
(8, 8, 85.0),
(9, 9, 85.0),
(10, 10, 85.0);
INSERT INTO u3_grade.attendance (enrollment_id, class_date, status) VALUES
(1, '2020-09-01', 'Present'),
(2, '2020-09-01', 'Present'),
(3, '2020-09-01', 'Present'),
(4, '2020-09-01', 'Present'),
(5, '2020-09-01', 'Present'),
(6, '2020-09-01', 'Present'),
(7, '2020-09-01', 'Present'),
(8, '2020-09-01', 'Present'),
(9, '2020-09-01', 'Present'),
(10, '2020-09-01', 'Present');
INSERT INTO u3_grade.grade_change_logs (enrollment_id, old_grade, new_grade, changed_by, reason) VALUES
(1, 'B', 'A', 'Admin', 'Re-evaluation'),
(2, 'B', 'A', 'Admin', 'Re-evaluation'),
(3, 'B', 'A', 'Admin', 'Re-evaluation'),
(4, 'B', 'A', 'Admin', 'Re-evaluation'),
(5, 'B', 'A', 'Admin', 'Re-evaluation'),
(6, 'B', 'A', 'Admin', 'Re-evaluation'),
(7, 'B', 'A', 'Admin', 'Re-evaluation'),
(8, 'B', 'A', 'Admin', 'Re-evaluation'),
(9, 'B', 'A', 'Admin', 'Re-evaluation'),
(10, 'B', 'A', 'Admin', 'Re-evaluation');

-- Schema: u4_fee
INSERT INTO u4_fee.fee_types (fee_name, description) VALUES
('Fee 1', 'Desc 1'),
('Fee 2', 'Desc 2'),
('Fee 3', 'Desc 3'),
('Fee 4', 'Desc 4'),
('Fee 5', 'Desc 5'),
('Fee 6', 'Desc 6'),
('Fee 7', 'Desc 7'),
('Fee 8', 'Desc 8'),
('Fee 9', 'Desc 9'),
('Fee 10', 'Desc 10');
INSERT INTO u4_fee.invoices (student_id, semester_id, total_amount, issue_date, due_date, is_paid) VALUES
('S01', 1, 5000.00, '2020-08-01', '2020-08-15', FALSE),
('S02', 2, 5000.00, '2020-08-01', '2020-08-15', FALSE),
('S03', 3, 5000.00, '2020-08-01', '2020-08-15', FALSE),
('S04', 4, 5000.00, '2020-08-01', '2020-08-15', FALSE),
('S05', 5, 5000.00, '2020-08-01', '2020-08-15', FALSE),
('S06', 6, 5000.00, '2020-08-01', '2020-08-15', FALSE),
('S07', 7, 5000.00, '2020-08-01', '2020-08-15', FALSE),
('S08', 8, 5000.00, '2020-08-01', '2020-08-15', FALSE),
('S09', 9, 5000.00, '2020-08-01', '2020-08-15', FALSE),
('S10', 10, 5000.00, '2020-08-01', '2020-08-15', FALSE);
INSERT INTO u4_fee.invoice_items (invoice_id, fee_type_id, enrollment_id, amount, description) VALUES
(1, 1, 1, 5000.00, 'Item 1'),
(2, 2, 2, 5000.00, 'Item 2'),
(3, 3, 3, 5000.00, 'Item 3'),
(4, 4, 4, 5000.00, 'Item 4'),
(5, 5, 5, 5000.00, 'Item 5'),
(6, 6, 6, 5000.00, 'Item 6'),
(7, 7, 7, 5000.00, 'Item 7'),
(8, 8, 8, 5000.00, 'Item 8'),
(9, 9, 9, 5000.00, 'Item 9'),
(10, 10, 10, 5000.00, 'Item 10');
INSERT INTO u4_fee.payments (invoice_id, amount_paid, payment_date, payment_method) VALUES
(1, 5000.00, '2020-08-10 10:00:00', 'Transfer'),
(2, 5000.00, '2020-08-10 10:00:00', 'Transfer'),
(3, 5000.00, '2020-08-10 10:00:00', 'Transfer'),
(4, 5000.00, '2020-08-10 10:00:00', 'Transfer'),
(5, 5000.00, '2020-08-10 10:00:00', 'Transfer'),
(6, 5000.00, '2020-08-10 10:00:00', 'Transfer'),
(7, 5000.00, '2020-08-10 10:00:00', 'Transfer'),
(8, 5000.00, '2020-08-10 10:00:00', 'Transfer'),
(9, 5000.00, '2020-08-10 10:00:00', 'Transfer'),
(10, 5000.00, '2020-08-10 10:00:00', 'Transfer');

-- Schema: u6_hr
INSERT INTO u6_hr.academic_ranks (rank_name, abbreviation) VALUES
('Rank 1', 'R1'),
('Rank 2', 'R2'),
('Rank 3', 'R3'),
('Rank 4', 'R4'),
('Rank 5', 'R5'),
('Rank 6', 'R6'),
('Rank 7', 'R7'),
('Rank 8', 'R8'),
('Rank 9', 'R9'),
('Rank 10', 'R10');
INSERT INTO u6_hr.employment_types (type_name, description) VALUES
('Type 1', 'Desc 1'),
('Type 2', 'Desc 2'),
('Type 3', 'Desc 3'),
('Type 4', 'Desc 4'),
('Type 5', 'Desc 5'),
('Type 6', 'Desc 6'),
('Type 7', 'Desc 7'),
('Type 8', 'Desc 8'),
('Type 9', 'Desc 9'),
('Type 10', 'Desc 10');
INSERT INTO u6_hr.positions (position_title, description, salary_level) VALUES
('Position 1', 'Desc 1', 1),
('Position 2', 'Desc 2', 2),
('Position 3', 'Desc 3', 3),
('Position 4', 'Desc 4', 4),
('Position 5', 'Desc 5', 5),
('Position 6', 'Desc 6', 6),
('Position 7', 'Desc 7', 7),
('Position 8', 'Desc 8', 8),
('Position 9', 'Desc 9', 9),
('Position 10', 'Desc 10', 10);
INSERT INTO u6_hr.leave_types (leave_name, max_days_per_year) VALUES
('Leave 1', 10),
('Leave 2', 10),
('Leave 3', 10),
('Leave 4', 10),
('Leave 5', 10),
('Leave 6', 10),
('Leave 7', 10),
('Leave 8', 10),
('Leave 9', 10),
('Leave 10', 10);
INSERT INTO u6_hr.certifications (cert_name, issuing_org) VALUES
('Cert 1', 'Org 1'),
('Cert 2', 'Org 2'),
('Cert 3', 'Org 3'),
('Cert 4', 'Org 4'),
('Cert 5', 'Org 5'),
('Cert 6', 'Org 6'),
('Cert 7', 'Org 7'),
('Cert 8', 'Org 8'),
('Cert 9', 'Org 9'),
('Cert 10', 'Org 10');
INSERT INTO u6_hr.committees (committee_name, description) VALUES
('Committee 1', 'Desc 1'),
('Committee 2', 'Desc 2'),
('Committee 3', 'Desc 3'),
('Committee 4', 'Desc 4'),
('Committee 5', 'Desc 5'),
('Committee 6', 'Desc 6'),
('Committee 7', 'Desc 7'),
('Committee 8', 'Desc 8'),
('Committee 9', 'Desc 9'),
('Committee 10', 'Desc 10');
INSERT INTO u6_hr.internal_trainings (topic_name, organizer, training_date) VALUES
('Topic 1', 'Org 1', '2020-01-01'),
('Topic 2', 'Org 2', '2020-01-01'),
('Topic 3', 'Org 3', '2020-01-01'),
('Topic 4', 'Org 4', '2020-01-01'),
('Topic 5', 'Org 5', '2020-01-01'),
('Topic 6', 'Org 6', '2020-01-01'),
('Topic 7', 'Org 7', '2020-01-01'),
('Topic 8', 'Org 8', '2020-01-01'),
('Topic 9', 'Org 9', '2020-01-01'),
('Topic 10', 'Org 10', '2020-01-01');
INSERT INTO u6_hr.faculty_members (employee_code, first_name, last_name, email, department_id, rank_id, employment_type_id, instructor_id, hire_date, status) VALUES
('FC01', 'FFName1', 'FLName1', 'fc1@uni.edu', 'D01', 1, 1, 'I01', '2020-01-01', 'Active'),
('FC02', 'FFName2', 'FLName2', 'fc2@uni.edu', 'D02', 2, 2, 'I02', '2020-01-01', 'Active'),
('FC03', 'FFName3', 'FLName3', 'fc3@uni.edu', 'D03', 3, 3, 'I03', '2020-01-01', 'Active'),
('FC04', 'FFName4', 'FLName4', 'fc4@uni.edu', 'D04', 4, 4, 'I04', '2020-01-01', 'Active'),
('FC05', 'FFName5', 'FLName5', 'fc5@uni.edu', 'D05', 5, 5, 'I05', '2020-01-01', 'Active'),
('FC06', 'FFName6', 'FLName6', 'fc6@uni.edu', 'D06', 6, 6, 'I06', '2020-01-01', 'Active'),
('FC07', 'FFName7', 'FLName7', 'fc7@uni.edu', 'D07', 7, 7, 'I07', '2020-01-01', 'Active'),
('FC08', 'FFName8', 'FLName8', 'fc8@uni.edu', 'D08', 8, 8, 'I08', '2020-01-01', 'Active'),
('FC09', 'FFName9', 'FLName9', 'fc9@uni.edu', 'D09', 9, 9, 'I09', '2020-01-01', 'Active'),
('FC10', 'FFName10', 'FLName10', 'fc10@uni.edu', 'D10', 10, 10, 'I10', '2020-01-01', 'Active');
INSERT INTO u6_hr.staff (staff_code, first_name, last_name, email, department_id, position_id, employment_type_id, hire_date, status) VALUES
('ST01', 'SFName1', 'SLName1', 'st1@uni.edu', 'D01', 1, 1, '2020-01-01', 'Active'),
('ST02', 'SFName2', 'SLName2', 'st2@uni.edu', 'D02', 2, 2, '2020-01-01', 'Active'),
('ST03', 'SFName3', 'SLName3', 'st3@uni.edu', 'D03', 3, 3, '2020-01-01', 'Active'),
('ST04', 'SFName4', 'SLName4', 'st4@uni.edu', 'D04', 4, 4, '2020-01-01', 'Active'),
('ST05', 'SFName5', 'SLName5', 'st5@uni.edu', 'D05', 5, 5, '2020-01-01', 'Active'),
('ST06', 'SFName6', 'SLName6', 'st6@uni.edu', 'D06', 6, 6, '2020-01-01', 'Active'),
('ST07', 'SFName7', 'SLName7', 'st7@uni.edu', 'D07', 7, 7, '2020-01-01', 'Active'),
('ST08', 'SFName8', 'SLName8', 'st8@uni.edu', 'D08', 8, 8, '2020-01-01', 'Active'),
('ST09', 'SFName9', 'SLName9', 'st9@uni.edu', 'D09', 9, 9, '2020-01-01', 'Active'),
('ST10', 'SFName10', 'SLName10', 'st10@uni.edu', 'D10', 10, 10, '2020-01-01', 'Active');
INSERT INTO u6_hr.assets (asset_code, asset_name) VALUES
('A01', 'Asset 1'),
('A02', 'Asset 2'),
('A03', 'Asset 3'),
('A04', 'Asset 4'),
('A05', 'Asset 5'),
('A06', 'Asset 6'),
('A07', 'Asset 7'),
('A08', 'Asset 8'),
('A09', 'Asset 9'),
('A10', 'Asset 10');
INSERT INTO u6_hr.payroll_runs (pay_month, pay_year) VALUES
(2, 2020),
(3, 2020),
(4, 2020),
(5, 2020),
(6, 2020),
(7, 2020),
(8, 2020),
(9, 2020),
(10, 2020),
(11, 2020);
INSERT INTO u6_hr.curricula (curriculum_name, department_id, effective_year) VALUES
('Curriculum 1', 'D01', 2020),
('Curriculum 2', 'D02', 2020),
('Curriculum 3', 'D03', 2020),
('Curriculum 4', 'D04', 2020),
('Curriculum 5', 'D05', 2020),
('Curriculum 6', 'D06', 2020),
('Curriculum 7', 'D07', 2020),
('Curriculum 8', 'D08', 2020),
('Curriculum 9', 'D09', 2020),
('Curriculum 10', 'D10', 2020);
INSERT INTO u6_hr.publications (faculty_member_id, title, published_year) VALUES
(1, 'Publication 1', 2020),
(2, 'Publication 2', 2020),
(3, 'Publication 3', 2020),
(4, 'Publication 4', 2020),
(5, 'Publication 5', 2020),
(6, 'Publication 6', 2020),
(7, 'Publication 7', 2020),
(8, 'Publication 8', 2020),
(9, 'Publication 9', 2020),
(10, 'Publication 10', 2020);
INSERT INTO u6_hr.research_grants (grant_name, faculty_member_id, allocated_budget) VALUES
('Grant 1', 1, 50000.00),
('Grant 2', 2, 50000.00),
('Grant 3', 3, 50000.00),
('Grant 4', 4, 50000.00),
('Grant 5', 5, 50000.00),
('Grant 6', 6, 50000.00),
('Grant 7', 7, 50000.00),
('Grant 8', 8, 50000.00),
('Grant 9', 9, 50000.00),
('Grant 10', 10, 50000.00);
INSERT INTO u6_hr.department_budgets (department_id, fiscal_year, allocated_amount) VALUES
('D01', 2020, 100000.00),
('D02', 2020, 100000.00),
('D03', 2020, 100000.00),
('D04', 2020, 100000.00),
('D05', 2020, 100000.00),
('D06', 2020, 100000.00),
('D07', 2020, 100000.00),
('D08', 2020, 100000.00),
('D09', 2020, 100000.00),
('D10', 2020, 100000.00);
INSERT INTO u6_hr.employee_dependents (owner_type, owner_id, first_name, last_name, relationship, birth_date, education_level, is_eligible_benefit) VALUES
('FACULTY', 1, 'Dep1', 'Last1', 'Child', '2010-01-01', 'Primary', TRUE),
('FACULTY', 2, 'Dep2', 'Last2', 'Child', '2010-01-01', 'Primary', TRUE),
('FACULTY', 3, 'Dep3', 'Last3', 'Child', '2010-01-01', 'Primary', TRUE),
('FACULTY', 4, 'Dep4', 'Last4', 'Child', '2010-01-01', 'Primary', TRUE),
('FACULTY', 5, 'Dep5', 'Last5', 'Child', '2010-01-01', 'Primary', TRUE),
('STAFF', 1, 'Dep6', 'Last6', 'Child', '2010-01-01', 'Primary', TRUE),
('STAFF', 2, 'Dep7', 'Last7', 'Child', '2010-01-01', 'Primary', TRUE),
('STAFF', 3, 'Dep8', 'Last8', 'Child', '2010-01-01', 'Primary', TRUE),
('STAFF', 4, 'Dep9', 'Last9', 'Child', '2010-01-01', 'Primary', TRUE),
('STAFF', 5, 'Dep10', 'Last10', 'Child', '2010-01-01', 'Primary', TRUE);
INSERT INTO u6_hr.employee_addresses (owner_type, owner_id, address_line1, city, province, postal_code, country) VALUES
('FACULTY', 1, 'Add1', 'City1', 'Prov1', '10000', 'Thailand'),
('FACULTY', 2, 'Add2', 'City2', 'Prov2', '10000', 'Thailand'),
('FACULTY', 3, 'Add3', 'City3', 'Prov3', '10000', 'Thailand'),
('FACULTY', 4, 'Add4', 'City4', 'Prov4', '10000', 'Thailand'),
('FACULTY', 5, 'Add5', 'City5', 'Prov5', '10000', 'Thailand'),
('STAFF', 1, 'Add6', 'City6', 'Prov6', '10000', 'Thailand'),
('STAFF', 2, 'Add7', 'City7', 'Prov7', '10000', 'Thailand'),
('STAFF', 3, 'Add8', 'City8', 'Prov8', '10000', 'Thailand'),
('STAFF', 4, 'Add9', 'City9', 'Prov9', '10000', 'Thailand'),
('STAFF', 5, 'Add10', 'City10', 'Prov10', '10000', 'Thailand');
INSERT INTO u6_hr.employee_documents (owner_type, owner_id, document_type, file_path) VALUES
('FACULTY', 1, 'ID', '/docs/1.pdf'),
('FACULTY', 2, 'ID', '/docs/2.pdf'),
('FACULTY', 3, 'ID', '/docs/3.pdf'),
('FACULTY', 4, 'ID', '/docs/4.pdf'),
('FACULTY', 5, 'ID', '/docs/5.pdf'),
('STAFF', 1, 'ID', '/docs/6.pdf'),
('STAFF', 2, 'ID', '/docs/7.pdf'),
('STAFF', 3, 'ID', '/docs/8.pdf'),
('STAFF', 4, 'ID', '/docs/9.pdf'),
('STAFF', 5, 'ID', '/docs/10.pdf');
INSERT INTO u6_hr.asset_allocations (asset_id, owner_type, owner_id, assigned_date, return_date) VALUES
(1, 'FACULTY', 1, '2020-01-01', '2021-01-01'),
(2, 'FACULTY', 2, '2020-01-01', '2021-01-01'),
(3, 'FACULTY', 3, '2020-01-01', '2021-01-01'),
(4, 'FACULTY', 4, '2020-01-01', '2021-01-01'),
(5, 'FACULTY', 5, '2020-01-01', '2021-01-01'),
(6, 'STAFF', 1, '2020-01-01', '2021-01-01'),
(7, 'STAFF', 2, '2020-01-01', '2021-01-01'),
(8, 'STAFF', 3, '2020-01-01', '2021-01-01'),
(9, 'STAFF', 4, '2020-01-01', '2021-01-01'),
(10, 'STAFF', 5, '2020-01-01', '2021-01-01');
INSERT INTO u6_hr.attendance_logs (owner_type, owner_id, check_in, check_out, status) VALUES
('FACULTY', 1, '2020-01-01 08:00:00', '2020-01-01 17:00:00', 'Present'),
('FACULTY', 2, '2020-01-01 08:00:00', '2020-01-01 17:00:00', 'Present'),
('FACULTY', 3, '2020-01-01 08:00:00', '2020-01-01 17:00:00', 'Present'),
('FACULTY', 4, '2020-01-01 08:00:00', '2020-01-01 17:00:00', 'Present'),
('FACULTY', 5, '2020-01-01 08:00:00', '2020-01-01 17:00:00', 'Present'),
('STAFF', 1, '2020-01-01 08:00:00', '2020-01-01 17:00:00', 'Present'),
('STAFF', 2, '2020-01-01 08:00:00', '2020-01-01 17:00:00', 'Present'),
('STAFF', 3, '2020-01-01 08:00:00', '2020-01-01 17:00:00', 'Present'),
('STAFF', 4, '2020-01-01 08:00:00', '2020-01-01 17:00:00', 'Present'),
('STAFF', 5, '2020-01-01 08:00:00', '2020-01-01 17:00:00', 'Present');
INSERT INTO u6_hr.performance_appraisals (owner_type, owner_id, evaluator_id, fiscal_year, score, comments) VALUES
('FACULTY', 1, 1, 2020, 95.0, 'Good'),
('FACULTY', 2, 1, 2020, 95.0, 'Good'),
('FACULTY', 3, 1, 2020, 95.0, 'Good'),
('FACULTY', 4, 1, 2020, 95.0, 'Good'),
('FACULTY', 5, 1, 2020, 95.0, 'Good'),
('STAFF', 1, 1, 2020, 95.0, 'Good'),
('STAFF', 2, 1, 2020, 95.0, 'Good'),
('STAFF', 3, 1, 2020, 95.0, 'Good'),
('STAFF', 4, 1, 2020, 95.0, 'Good'),
('STAFF', 5, 1, 2020, 95.0, 'Good');
INSERT INTO u6_hr.employee_certifications (owner_type, owner_id, certification_id, issue_date, expire_date) VALUES
('FACULTY', 1, 1, '2020-01-01', '2025-01-01'),
('FACULTY', 2, 2, '2020-01-01', '2025-01-01'),
('FACULTY', 3, 3, '2020-01-01', '2025-01-01'),
('FACULTY', 4, 4, '2020-01-01', '2025-01-01'),
('FACULTY', 5, 5, '2020-01-01', '2025-01-01'),
('STAFF', 1, 6, '2020-01-01', '2025-01-01'),
('STAFF', 2, 7, '2020-01-01', '2025-01-01'),
('STAFF', 3, 8, '2020-01-01', '2025-01-01'),
('STAFF', 4, 9, '2020-01-01', '2025-01-01'),
('STAFF', 5, 10, '2020-01-01', '2025-01-01');
INSERT INTO u6_hr.leave_requests (owner_type, owner_id, leave_type_id, start_date, end_date, reason, status) VALUES
('FACULTY', 1, 1, '2020-01-01', '2020-01-02', 'Sick', 'Pending'),
('FACULTY', 2, 2, '2020-01-01', '2020-01-02', 'Sick', 'Pending'),
('FACULTY', 3, 3, '2020-01-01', '2020-01-02', 'Sick', 'Pending'),
('FACULTY', 4, 4, '2020-01-01', '2020-01-02', 'Sick', 'Pending'),
('FACULTY', 5, 5, '2020-01-01', '2020-01-02', 'Sick', 'Pending'),
('STAFF', 1, 6, '2020-01-01', '2020-01-02', 'Sick', 'Pending'),
('STAFF', 2, 7, '2020-01-01', '2020-01-02', 'Sick', 'Pending'),
('STAFF', 3, 8, '2020-01-01', '2020-01-02', 'Sick', 'Pending'),
('STAFF', 4, 9, '2020-01-01', '2020-01-02', 'Sick', 'Pending'),
('STAFF', 5, 10, '2020-01-01', '2020-01-02', 'Sick', 'Pending');
INSERT INTO u6_hr.leave_approvals (request_id, approver_id, approval_status, approval_date) VALUES
(1, 1, 'Approved', '2020-01-01'),
(2, 1, 'Approved', '2020-01-01'),
(3, 1, 'Approved', '2020-01-01'),
(4, 1, 'Approved', '2020-01-01'),
(5, 1, 'Approved', '2020-01-01'),
(6, 1, 'Approved', '2020-01-01'),
(7, 1, 'Approved', '2020-01-01'),
(8, 1, 'Approved', '2020-01-01'),
(9, 1, 'Approved', '2020-01-01'),
(10, 1, 'Approved', '2020-01-01');
INSERT INTO u6_hr.salaries (owner_type, owner_id, base_salary, effective_date) VALUES
('FACULTY', 1, 50000.00, '2020-01-01'),
('FACULTY', 2, 50000.00, '2020-01-01'),
('FACULTY', 3, 50000.00, '2020-01-01'),
('FACULTY', 4, 50000.00, '2020-01-01'),
('FACULTY', 5, 50000.00, '2020-01-01'),
('STAFF', 1, 50000.00, '2020-01-01'),
('STAFF', 2, 50000.00, '2020-01-01'),
('STAFF', 3, 50000.00, '2020-01-01'),
('STAFF', 4, 50000.00, '2020-01-01'),
('STAFF', 5, 50000.00, '2020-01-01');
INSERT INTO u6_hr.salary_increments (owner_type, owner_id, previous_salary, new_salary, increment_date, reason) VALUES
('FACULTY', 1, 40000.00, 50000.00, '2020-01-01', 'Promo'),
('FACULTY', 2, 40000.00, 50000.00, '2020-01-01', 'Promo'),
('FACULTY', 3, 40000.00, 50000.00, '2020-01-01', 'Promo'),
('FACULTY', 4, 40000.00, 50000.00, '2020-01-01', 'Promo'),
('FACULTY', 5, 40000.00, 50000.00, '2020-01-01', 'Promo'),
('STAFF', 1, 40000.00, 50000.00, '2020-01-01', 'Promo'),
('STAFF', 2, 40000.00, 50000.00, '2020-01-01', 'Promo'),
('STAFF', 3, 40000.00, 50000.00, '2020-01-01', 'Promo'),
('STAFF', 4, 40000.00, 50000.00, '2020-01-01', 'Promo'),
('STAFF', 5, 40000.00, 50000.00, '2020-01-01', 'Promo');
INSERT INTO u6_hr.payroll_details (payroll_run_id, owner_type, owner_id, earnings, deductions, net_pay) VALUES
(1, 'FACULTY', 1, 50000.00, 2000.00, 48000.00),
(2, 'FACULTY', 2, 50000.00, 2000.00, 48000.00),
(3, 'FACULTY', 3, 50000.00, 2000.00, 48000.00),
(4, 'FACULTY', 4, 50000.00, 2000.00, 48000.00),
(5, 'FACULTY', 5, 50000.00, 2000.00, 48000.00),
(6, 'STAFF', 1, 50000.00, 2000.00, 48000.00),
(7, 'STAFF', 2, 50000.00, 2000.00, 48000.00),
(8, 'STAFF', 3, 50000.00, 2000.00, 48000.00),
(9, 'STAFF', 4, 50000.00, 2000.00, 48000.00),
(10, 'STAFF', 5, 50000.00, 2000.00, 48000.00);
INSERT INTO u6_hr.committee_members (committee_id, owner_type, owner_id, role_in_committee) VALUES
(1, 'FACULTY', 1, 'Member'),
(2, 'FACULTY', 2, 'Member'),
(3, 'FACULTY', 3, 'Member'),
(4, 'FACULTY', 4, 'Member'),
(5, 'FACULTY', 5, 'Member'),
(6, 'STAFF', 1, 'Member'),
(7, 'STAFF', 2, 'Member'),
(8, 'STAFF', 3, 'Member'),
(9, 'STAFF', 4, 'Member'),
(10, 'STAFF', 5, 'Member');
INSERT INTO u6_hr.employee_trainings (owner_type, owner_id, training_id, status) VALUES
('FACULTY', 1, 1, 'Completed'),
('FACULTY', 2, 2, 'Completed'),
('FACULTY', 3, 3, 'Completed'),
('FACULTY', 4, 4, 'Completed'),
('FACULTY', 5, 5, 'Completed'),
('STAFF', 1, 6, 'Completed'),
('STAFF', 2, 7, 'Completed'),
('STAFF', 3, 8, 'Completed'),
('STAFF', 4, 9, 'Completed'),
('STAFF', 5, 10, 'Completed');
INSERT INTO u6_hr.exit_interviews (owner_type, owner_id, resignation_date, reason, feedback) VALUES
('FACULTY', 1, '2021-01-01', 'Relocation', 'Good'),
('FACULTY', 2, '2021-01-01', 'Relocation', 'Good'),
('FACULTY', 3, '2021-01-01', 'Relocation', 'Good'),
('FACULTY', 4, '2021-01-01', 'Relocation', 'Good'),
('FACULTY', 5, '2021-01-01', 'Relocation', 'Good'),
('STAFF', 1, '2021-01-01', 'Relocation', 'Good'),
('STAFF', 2, '2021-01-01', 'Relocation', 'Good'),
('STAFF', 3, '2021-01-01', 'Relocation', 'Good'),
('STAFF', 4, '2021-01-01', 'Relocation', 'Good'),
('STAFF', 5, '2021-01-01', 'Relocation', 'Good');
INSERT INTO u6_hr.room_bookings (room_number, owner_type, owner_id, booking_date, start_time, end_time, purpose) VALUES
('R01', 'FACULTY', 1, '2020-01-01', '09:00:00', '10:00:00', 'Meeting'),
('R02', 'FACULTY', 2, '2020-01-01', '09:00:00', '10:00:00', 'Meeting'),
('R03', 'FACULTY', 3, '2020-01-01', '09:00:00', '10:00:00', 'Meeting'),
('R04', 'FACULTY', 4, '2020-01-01', '09:00:00', '10:00:00', 'Meeting'),
('R05', 'FACULTY', 5, '2020-01-01', '09:00:00', '10:00:00', 'Meeting'),
('R06', 'STAFF', 1, '2020-01-01', '09:00:00', '10:00:00', 'Meeting'),
('R07', 'STAFF', 2, '2020-01-01', '09:00:00', '10:00:00', 'Meeting'),
('R08', 'STAFF', 3, '2020-01-01', '09:00:00', '10:00:00', 'Meeting'),
('R09', 'STAFF', 4, '2020-01-01', '09:00:00', '10:00:00', 'Meeting'),
('R10', 'STAFF', 5, '2020-01-01', '09:00:00', '10:00:00', 'Meeting');
INSERT INTO u6_hr.emergency_contacts (owner_type, owner_id, contact_name, relationship, phone_number) VALUES
('FACULTY', 1, 'Cont1', 'Parent', '0800000000'),
('FACULTY', 2, 'Cont2', 'Parent', '0800000000'),
('FACULTY', 3, 'Cont3', 'Parent', '0800000000'),
('FACULTY', 4, 'Cont4', 'Parent', '0800000000'),
('FACULTY', 5, 'Cont5', 'Parent', '0800000000'),
('STAFF', 1, 'Cont6', 'Parent', '0800000000'),
('STAFF', 2, 'Cont7', 'Parent', '0800000000'),
('STAFF', 3, 'Cont8', 'Parent', '0800000000'),
('STAFF', 4, 'Cont9', 'Parent', '0800000000'),
('STAFF', 5, 'Cont10', 'Parent', '0800000000');

-- Schema: u5_lib
INSERT INTO u5_lib.media_types (media_type_id, type_name) VALUES
('MT01', 'Media 1'),
('MT02', 'Media 2'),
('MT03', 'Media 3'),
('MT04', 'Media 4'),
('MT05', 'Media 5'),
('MT06', 'Media 6'),
('MT07', 'Media 7'),
('MT08', 'Media 8'),
('MT09', 'Media 9'),
('MT10', 'Media 10');
INSERT INTO u5_lib.categories (category_id, dewey_code, category_name) VALUES
('CAT01', '001', 'Category 1'),
('CAT02', '002', 'Category 2'),
('CAT03', '003', 'Category 3'),
('CAT04', '004', 'Category 4'),
('CAT05', '005', 'Category 5'),
('CAT06', '006', 'Category 6'),
('CAT07', '007', 'Category 7'),
('CAT08', '008', 'Category 8'),
('CAT09', '009', 'Category 9'),
('CAT10', '0010', 'Category 10');
INSERT INTO u5_lib.resources (resource_id, title, author, publisher, publish_year, isbn, category_id, media_type_id) VALUES
('RES01', 'Book 1', 'Author 1', 'Pub 1', 2010, 'ISBN1', 'CAT01', 'MT01'),
('RES02', 'Book 2', 'Author 2', 'Pub 2', 2010, 'ISBN2', 'CAT02', 'MT02'),
('RES03', 'Book 3', 'Author 3', 'Pub 3', 2010, 'ISBN3', 'CAT03', 'MT03'),
('RES04', 'Book 4', 'Author 4', 'Pub 4', 2010, 'ISBN4', 'CAT04', 'MT04'),
('RES05', 'Book 5', 'Author 5', 'Pub 5', 2010, 'ISBN5', 'CAT05', 'MT05'),
('RES06', 'Book 6', 'Author 6', 'Pub 6', 2010, 'ISBN6', 'CAT06', 'MT06'),
('RES07', 'Book 7', 'Author 7', 'Pub 7', 2010, 'ISBN7', 'CAT07', 'MT07'),
('RES08', 'Book 8', 'Author 8', 'Pub 8', 2010, 'ISBN8', 'CAT08', 'MT08'),
('RES09', 'Book 9', 'Author 9', 'Pub 9', 2010, 'ISBN9', 'CAT09', 'MT09'),
('RES10', 'Book 10', 'Author 10', 'Pub 10', 2010, 'ISBN10', 'CAT10', 'MT10');
INSERT INTO u5_lib.resource_items (item_id, resource_id, location_zone, status) VALUES
('ITEM01', 'RES01', 'Zone 1', 'Available'),
('ITEM02', 'RES02', 'Zone 2', 'Available'),
('ITEM03', 'RES03', 'Zone 3', 'Available'),
('ITEM04', 'RES04', 'Zone 4', 'Available'),
('ITEM05', 'RES05', 'Zone 5', 'Available'),
('ITEM06', 'RES06', 'Zone 6', 'Available'),
('ITEM07', 'RES07', 'Zone 7', 'Available'),
('ITEM08', 'RES08', 'Zone 8', 'Available'),
('ITEM09', 'RES09', 'Zone 9', 'Available'),
('ITEM10', 'RES10', 'Zone 10', 'Available');
INSERT INTO u5_lib.digital_resources (digital_id, resource_id, file_path_url, file_format, access_level) VALUES
('DIG01', 'RES01', '/dig/1.pdf', 'PDF', 'Public'),
('DIG02', 'RES02', '/dig/2.pdf', 'PDF', 'Public'),
('DIG03', 'RES03', '/dig/3.pdf', 'PDF', 'Public'),
('DIG04', 'RES04', '/dig/4.pdf', 'PDF', 'Public'),
('DIG05', 'RES05', '/dig/5.pdf', 'PDF', 'Public'),
('DIG06', 'RES06', '/dig/6.pdf', 'PDF', 'Public'),
('DIG07', 'RES07', '/dig/7.pdf', 'PDF', 'Public'),
('DIG08', 'RES08', '/dig/8.pdf', 'PDF', 'Public'),
('DIG09', 'RES09', '/dig/9.pdf', 'PDF', 'Public'),
('DIG10', 'RES10', '/dig/10.pdf', 'PDF', 'Public');
INSERT INTO u5_lib.members (member_id, first_name, last_name, email, phone, member_type, faculty_department, student_id, hr_faculty_member_id, hr_staff_id) VALUES
('M01', 'Lib1', 'Last1', 'lib1@uni.edu', '0810000001', 'STUDENT', 'D01', 'S01', NULL, NULL),
('M02', 'Lib2', 'Last2', 'lib2@uni.edu', '0810000002', 'STUDENT', 'D01', 'S02', NULL, NULL),
('M03', 'Lib3', 'Last3', 'lib3@uni.edu', '0810000003', 'STUDENT', 'D01', 'S03', NULL, NULL),
('M04', 'Lib4', 'Last4', 'lib4@uni.edu', '0810000004', 'STUDENT', 'D01', 'S04', NULL, NULL),
('M05', 'Lib5', 'Last5', 'lib5@uni.edu', '0810000005', 'STUDENT', 'D01', 'S05', NULL, NULL),
('M06', 'Lib6', 'Last6', 'lib6@uni.edu', '0810000006', 'STUDENT', 'D01', 'S06', NULL, NULL),
('M07', 'Lib7', 'Last7', 'lib7@uni.edu', '0810000007', 'STUDENT', 'D01', 'S07', NULL, NULL),
('M08', 'Lib8', 'Last8', 'lib8@uni.edu', '0810000008', 'STUDENT', 'D01', 'S08', NULL, NULL),
('M09', 'Lib9', 'Last9', 'lib9@uni.edu', '0810000009', 'STUDENT', 'D01', 'S09', NULL, NULL),
('M10', 'Lib10', 'Last10', 'lib10@uni.edu', '08100000010', 'STUDENT', 'D01', 'S10', NULL, NULL);
INSERT INTO u5_lib.borrow_transactions (transaction_id, member_id, item_id, borrow_date, due_date, return_date, status) VALUES
('T01', 'M01', 'ITEM01', '2020-01-01', '2020-01-15', '2020-01-10', 'Returned'),
('T02', 'M02', 'ITEM02', '2020-01-01', '2020-01-15', '2020-01-10', 'Returned'),
('T03', 'M03', 'ITEM03', '2020-01-01', '2020-01-15', '2020-01-10', 'Returned'),
('T04', 'M04', 'ITEM04', '2020-01-01', '2020-01-15', '2020-01-10', 'Returned'),
('T05', 'M05', 'ITEM05', '2020-01-01', '2020-01-15', '2020-01-10', 'Returned'),
('T06', 'M06', 'ITEM06', '2020-01-01', '2020-01-15', '2020-01-10', 'Returned'),
('T07', 'M07', 'ITEM07', '2020-01-01', '2020-01-15', '2020-01-10', 'Returned'),
('T08', 'M08', 'ITEM08', '2020-01-01', '2020-01-15', '2020-01-10', 'Returned'),
('T09', 'M09', 'ITEM09', '2020-01-01', '2020-01-15', '2020-01-10', 'Returned'),
('T10', 'M10', 'ITEM10', '2020-01-01', '2020-01-15', '2020-01-10', 'Returned');
INSERT INTO u5_lib.reservations (reservation_id, member_id, resource_id, reserve_date, status) VALUES
('REV01', 'M01', 'RES01', '2020-01-01', 'Pending'),
('REV02', 'M02', 'RES02', '2020-01-01', 'Pending'),
('REV03', 'M03', 'RES03', '2020-01-01', 'Pending'),
('REV04', 'M04', 'RES04', '2020-01-01', 'Pending'),
('REV05', 'M05', 'RES05', '2020-01-01', 'Pending'),
('REV06', 'M06', 'RES06', '2020-01-01', 'Pending'),
('REV07', 'M07', 'RES07', '2020-01-01', 'Pending'),
('REV08', 'M08', 'RES08', '2020-01-01', 'Pending'),
('REV09', 'M09', 'RES09', '2020-01-01', 'Pending'),
('REV10', 'M10', 'RES10', '2020-01-01', 'Pending');
INSERT INTO u5_lib.fines (fine_id, transaction_id, fine_amount, fine_status, payment_date) VALUES
('F01', 'T01', 50.00, 'Paid', '2020-01-15'),
('F02', 'T02', 50.00, 'Paid', '2020-01-15'),
('F03', 'T03', 50.00, 'Paid', '2020-01-15'),
('F04', 'T04', 50.00, 'Paid', '2020-01-15'),
('F05', 'T05', 50.00, 'Paid', '2020-01-15'),
('F06', 'T06', 50.00, 'Paid', '2020-01-15'),
('F07', 'T07', 50.00, 'Paid', '2020-01-15'),
('F08', 'T08', 50.00, 'Paid', '2020-01-15'),
('F09', 'T09', 50.00, 'Paid', '2020-01-15'),
('F10', 'T10', 50.00, 'Paid', '2020-01-15');
INSERT INTO u5_lib.meeting_rooms (room_id, room_name, capacity, location_floor, status) VALUES
('MR01', 'Meeting Room 1', 10, '1F', 'Available'),
('MR02', 'Meeting Room 2', 10, '1F', 'Available'),
('MR03', 'Meeting Room 3', 10, '1F', 'Available'),
('MR04', 'Meeting Room 4', 10, '1F', 'Available'),
('MR05', 'Meeting Room 5', 10, '1F', 'Available'),
('MR06', 'Meeting Room 6', 10, '1F', 'Available'),
('MR07', 'Meeting Room 7', 10, '1F', 'Available'),
('MR08', 'Meeting Room 8', 10, '1F', 'Available'),
('MR09', 'Meeting Room 9', 10, '1F', 'Available'),
('MR10', 'Meeting Room 10', 10, '1F', 'Available');
INSERT INTO u5_lib.room_reservations (room_reservation_id, room_id, member_id, booker_name, booker_phone, booking_date, start_time, end_time, purpose, status) VALUES
('RR01', 'MR01', 'M01', 'Lib1', '080000', '2020-01-01', '09:00:00', '11:00:00', 'Study', 'Confirmed'),
('RR02', 'MR02', 'M02', 'Lib2', '080000', '2020-01-01', '09:00:00', '11:00:00', 'Study', 'Confirmed'),
('RR03', 'MR03', 'M03', 'Lib3', '080000', '2020-01-01', '09:00:00', '11:00:00', 'Study', 'Confirmed'),
('RR04', 'MR04', 'M04', 'Lib4', '080000', '2020-01-01', '09:00:00', '11:00:00', 'Study', 'Confirmed'),
('RR05', 'MR05', 'M05', 'Lib5', '080000', '2020-01-01', '09:00:00', '11:00:00', 'Study', 'Confirmed'),
('RR06', 'MR06', 'M06', 'Lib6', '080000', '2020-01-01', '09:00:00', '11:00:00', 'Study', 'Confirmed'),
('RR07', 'MR07', 'M07', 'Lib7', '080000', '2020-01-01', '09:00:00', '11:00:00', 'Study', 'Confirmed'),
('RR08', 'MR08', 'M08', 'Lib8', '080000', '2020-01-01', '09:00:00', '11:00:00', 'Study', 'Confirmed'),
('RR09', 'MR09', 'M09', 'Lib9', '080000', '2020-01-01', '09:00:00', '11:00:00', 'Study', 'Confirmed'),
('RR10', 'MR10', 'M10', 'Lib10', '080000', '2020-01-01', '09:00:00', '11:00:00', 'Study', 'Confirmed');
