-- Secondary school database schema for MySQL/MariaDB.
-- Re-running this file drops and recreates the school tables.

DROP TABLE IF EXISTS results;
DROP TABLE IF EXISTS attendance;
DROP TABLE IF EXISTS class_subjects;
DROP TABLE IF EXISTS enrollments;
DROP TABLE IF EXISTS classes;
DROP TABLE IF EXISTS subjects;
DROP TABLE IF EXISTS terms;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS teachers;

CREATE TABLE teachers (
    staff_number VARCHAR(20) NOT NULL,
    first_name VARCHAR(80) NOT NULL,
    middle_name VARCHAR(80) NULL,
    last_name VARCHAR(80) NOT NULL,
    email VARCHAR(254) NOT NULL,
    phone VARCHAR(30) NOT NULL,
    hire_date DATE NOT NULL,
    PRIMARY KEY (staff_number),
    UNIQUE KEY uq_teachers_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE classes (
    class_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    class_name VARCHAR(30) NOT NULL,
    form_teacher_staff_number VARCHAR(20) NOT NULL,
    PRIMARY KEY (class_id),
    UNIQUE KEY uq_classes_class_name (class_name),
    -- RESTRICT prevents deleting a teacher who is still assigned to a class;
    -- CASCADE keeps the reference valid if a staff number is corrected.
    CONSTRAINT fk_classes_form_teacher
        FOREIGN KEY (form_teacher_staff_number)
        REFERENCES teachers (staff_number)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE subjects (
    subject_code VARCHAR(12) NOT NULL,
    subject_name VARCHAR(100) NOT NULL,
    PRIMARY KEY (subject_code),
    UNIQUE KEY uq_subjects_subject_name (subject_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE terms (
    term_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    label VARCHAR(60) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    PRIMARY KEY (term_id),
    UNIQUE KEY uq_terms_label (label),
    CONSTRAINT chk_terms_date_order CHECK (start_date <= end_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE students (
    admission_number VARCHAR(20) NOT NULL,
    first_name VARCHAR(80) NOT NULL,
    middle_name VARCHAR(80) NULL,
    last_name VARCHAR(80) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender ENUM('female', 'male', 'other') NOT NULL,
    guardian_name VARCHAR(150) NOT NULL,
    guardian_phone VARCHAR(30) NOT NULL,
    -- The primary key is also the required uniqueness constraint on admission number.
    PRIMARY KEY (admission_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE enrollments (
    admission_number VARCHAR(20) NOT NULL,
    term_id INT UNSIGNED NOT NULL,
    class_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (admission_number, term_id),
    -- RESTRICT preserves enrollment history; CASCADE supports correcting a student's admission number.
    CONSTRAINT fk_enrollments_student
        FOREIGN KEY (admission_number)
        REFERENCES students (admission_number)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    -- RESTRICT prevents deleting a class with enrolled students; CASCADE tracks class-ID corrections.
    CONSTRAINT fk_enrollments_class
        FOREIGN KEY (class_id)
        REFERENCES classes (class_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    -- RESTRICT preserves term history; CASCADE tracks term-ID corrections.
    CONSTRAINT fk_enrollments_term
        FOREIGN KEY (term_id)
        REFERENCES terms (term_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE class_subjects (
    class_id INT UNSIGNED NOT NULL,
    subject_code VARCHAR(12) NOT NULL,
    teacher_staff_number VARCHAR(20) NOT NULL,
    PRIMARY KEY (class_id, subject_code),
    -- RESTRICT prevents removing a class while its subject assignments exist;
    -- CASCADE tracks class-ID corrections.
    CONSTRAINT fk_class_subjects_class
        FOREIGN KEY (class_id)
        REFERENCES classes (class_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    -- RESTRICT prevents removing a subject used by a class; CASCADE tracks code corrections.
    CONSTRAINT fk_class_subjects_subject
        FOREIGN KEY (subject_code)
        REFERENCES subjects (subject_code)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    -- RESTRICT prevents deleting a teacher with active assignments;
    -- CASCADE tracks staff-number corrections.
    CONSTRAINT fk_class_subjects_teacher
        FOREIGN KEY (teacher_staff_number)
        REFERENCES teachers (staff_number)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE results (
    admission_number VARCHAR(20) NOT NULL,
    subject_code VARCHAR(12) NOT NULL,
    term_id INT UNSIGNED NOT NULL,
    ca_score DECIMAL(5,2) NOT NULL,
    exam_score DECIMAL(5,2) NOT NULL,
    -- This composite primary key enforces one result per student, subject, and term.
    PRIMARY KEY (admission_number, subject_code, term_id),
    CONSTRAINT chk_results_ca_score CHECK (ca_score >= 0.00 AND ca_score <= 40.00),
    CONSTRAINT chk_results_exam_score CHECK (exam_score >= 0.00 AND exam_score <= 60.00),
    -- RESTRICT preserves assessed work; CASCADE tracks admission-number corrections.
    CONSTRAINT fk_results_student
        FOREIGN KEY (admission_number)
        REFERENCES students (admission_number)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    -- RESTRICT prevents removing a subject with recorded results; CASCADE tracks code corrections.
    CONSTRAINT fk_results_subject
        FOREIGN KEY (subject_code)
        REFERENCES subjects (subject_code)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    -- RESTRICT preserves academic history; CASCADE tracks term-ID corrections.
    CONSTRAINT fk_results_term
        FOREIGN KEY (term_id)
        REFERENCES terms (term_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    -- Require the student to be enrolled in the recorded term.
    CONSTRAINT fk_results_enrollment
        FOREIGN KEY (admission_number, term_id)
        REFERENCES enrollments (admission_number, term_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE attendance (
    admission_number VARCHAR(20) NOT NULL,
    attendance_date DATE NOT NULL,
    status ENUM('present', 'absent', 'late') NOT NULL,
    -- This composite primary key enforces one attendance row per student per day.
    PRIMARY KEY (admission_number, attendance_date),
    -- RESTRICT retains attendance history; CASCADE tracks admission-number corrections.
    CONSTRAINT fk_attendance_student
        FOREIGN KEY (admission_number)
        REFERENCES students (admission_number)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;