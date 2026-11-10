-- Sample Nigerian secondary-school data.
-- Run schema.sql first. This file seeds 3 classes, 8 subjects, 6 teachers,
-- 30 students, 240 results, and 150 attendance records.

START TRANSACTION;

INSERT INTO teachers
    (staff_number, first_name, last_name, email, phone, hire_date)
VALUES
    ('STF-001', 'Amina', 'Okafor', 'amina.okafor@school.example', '+2348035550101', '2018-09-03'),
    ('STF-002', 'Chinedu', 'Adeyemi', 'chinedu.adeyemi@school.example', '+2348035550102', '2019-01-14'),
    ('STF-003', 'Ngozi', 'Bello', 'ngozi.bello@school.example', '+2348035550103', '2017-09-11'),
    ('STF-004', 'Tunde', 'Eze', 'tunde.eze@school.example', '+2348035550104', '2020-02-03'),
    ('STF-005', 'Fatima', 'Yusuf', 'fatima.yusuf@school.example', '+2348035550105', '2021-09-06'),
    ('STF-006', 'Emeka', 'Ibrahim', 'emeka.ibrahim@school.example', '+2348035550106', '2016-10-10');

INSERT INTO classes (class_id, class_name, form_teacher_staff_number) VALUES
    (1, 'JSS1 A', 'STF-001'),
    (2, 'JSS2 A', 'STF-002'),
    (3, 'SSS1 A', 'STF-003');

INSERT INTO subjects (subject_code, subject_name) VALUES
    ('ENG', 'English Language'),
    ('MTH', 'Mathematics'),
    ('BSC', 'Basic Science'),
    ('BST', 'Basic Technology'),
    ('CIV', 'Civic Education'),
    ('CRS', 'Christian Religious Studies'),
    ('BUS', 'Business Studies'),
    ('YOR', 'Yoruba Language');

INSERT INTO terms (term_id, label, start_date, end_date) VALUES
    (1, '2026/2027 First Term', '2026-09-14', '2026-12-11');

INSERT INTO students
    (admission_number, first_name, last_name, date_of_birth, gender, guardian_name, guardian_phone)
VALUES
    ('STU-2026-001', 'Adaeze', 'Nwosu', '2013-02-14', 'female', 'Ifeoma Nwosu', '+2348035551001'),
    ('STU-2026-002', 'Oluwaseun', 'Adebayo', '2013-06-21', 'male', 'Kehinde Adebayo', '+2348035551002'),
    ('STU-2026-003', 'Zainab', 'Musa', '2013-01-09', 'female', 'Aisha Musa', '+2348035551003'),
    ('STU-2026-004', 'Daniel', 'Okoro', '2012-11-30', 'male', 'Grace Okoro', '+2348035551004'),
    ('STU-2026-005', 'Chiamaka', 'Eze', '2013-04-17', 'female', 'Nneka Eze', '+2348035551005'),
    ('STU-2026-006', 'Ibrahim', 'Bello', '2012-09-08', 'male', 'Abdul Bello', '+2348035551006'),
    ('STU-2026-007', 'Temiloluwa', 'Fashola', '2013-08-02', 'female', 'Bisi Fashola', '+2348035551007'),
    ('STU-2026-008', 'Peter', 'Ojo', '2012-12-19', 'male', 'Tosin Ojo', '+2348035551008'),
    ('STU-2026-009', 'Maryam', 'Abdullahi', '2013-03-26', 'female', 'Hadiza Abdullahi', '+2348035551009'),
    ('STU-2026-010', 'Kelechi', 'Ibe', '2013-07-11', 'male', 'Ngozi Ibe', '+2348035551010'),
    ('STU-2026-011', 'Fiyinfoluwa', 'Balogun', '2012-10-04', 'female', 'Morenike Balogun', '+2348035551011'),
    ('STU-2026-012', 'Samuel', 'Danjuma', '2012-08-25', 'male', 'Esther Danjuma', '+2348035551012'),
    ('STU-2026-013', 'Nneka', 'Umeh', '2012-05-13', 'female', 'Chika Umeh', '+2348035551013'),
    ('STU-2026-014', 'Abubakar', 'Sani', '2012-03-06', 'male', 'Amina Sani', '+2348035551014'),
    ('STU-2026-015', 'Oluchi', 'Nnamdi', '2012-12-01', 'female', 'Amaka Nnamdi', '+2348035551015'),
    ('STU-2026-016', 'Damilare', 'Ogunleye', '2012-01-22', 'male', 'Funmi Ogunleye', '+2348035551016'),
    ('STU-2026-017', 'Aisha', 'Garba', '2012-06-18', 'female', 'Musa Garba', '+2348035551017'),
    ('STU-2026-018', 'Victor', 'Chukwu', '2012-04-09', 'male', 'Ada Chukwu', '+2348035551018'),
    ('STU-2026-019', 'Hauwa', 'Mohammed', '2012-09-27', 'female', 'Sule Mohammed', '+2348035551019'),
    ('STU-2026-020', 'Babatunde', 'Ajayi', '2012-02-03', 'male', 'Kemi Ajayi', '+2348035551020'),
    ('STU-2026-021', 'Ifunanya', 'Obi', '2010-11-15', 'female', 'Ebere Obi', '+2348035551021'),
    ('STU-2026-022', 'Yusuf', 'Lawal', '2010-04-28', 'male', 'Rashida Lawal', '+2348035551022'),
    ('STU-2026-023', 'Modupe', 'Akinola', '2010-08-06', 'female', 'Yetunde Akinola', '+2348035551023'),
    ('STU-2026-024', 'Ebuka', 'Onyekachi', '2010-01-19', 'male', 'Nkem Onyekachi', '+2348035551024'),
    ('STU-2026-025', 'Safiya', 'Tanko', '2010-06-12', 'female', 'Mariam Tanko', '+2348035551025'),
    ('STU-2026-026', 'Adewale', 'Olatunji', '2010-03-23', 'male', 'Ronke Olatunji', '+2348035551026'),
    ('STU-2026-027', 'Chisom', 'Anya', '2010-10-02', 'female', 'Ijeoma Anya', '+2348035551027'),
    ('STU-2026-028', 'Musa', 'Ibrahim', '2010-07-16', 'male', 'Rahila Ibrahim', '+2348035551028'),
    ('STU-2026-029', 'Yetunde', 'Afolabi', '2010-02-25', 'female', 'Kudirat Afolabi', '+2348035551029'),
    ('STU-2026-030', 'Osaze', 'Ekhator', '2010-12-08', 'male', 'Ese Ekhator', '+2348035551030');

INSERT INTO enrollments (admission_number, term_id, class_id) VALUES
    ('STU-2026-001', 1, 1), ('STU-2026-002', 1, 1), ('STU-2026-003', 1, 1),
    ('STU-2026-004', 1, 1), ('STU-2026-005', 1, 1), ('STU-2026-006', 1, 1),
    ('STU-2026-007', 1, 1), ('STU-2026-008', 1, 1), ('STU-2026-009', 1, 1),
    ('STU-2026-010', 1, 1),
    ('STU-2026-011', 1, 2), ('STU-2026-012', 1, 2), ('STU-2026-013', 1, 2),
    ('STU-2026-014', 1, 2), ('STU-2026-015', 1, 2), ('STU-2026-016', 1, 2),
    ('STU-2026-017', 1, 2), ('STU-2026-018', 1, 2), ('STU-2026-019', 1, 2),
    ('STU-2026-020', 1, 2),
    ('STU-2026-021', 1, 3), ('STU-2026-022', 1, 3), ('STU-2026-023', 1, 3),
    ('STU-2026-024', 1, 3), ('STU-2026-025', 1, 3), ('STU-2026-026', 1, 3),
    ('STU-2026-027', 1, 3), ('STU-2026-028', 1, 3), ('STU-2026-029', 1, 3),
    ('STU-2026-030', 1, 3);

INSERT INTO class_subjects (class_id, subject_code, teacher_staff_number) VALUES
    (1, 'ENG', 'STF-001'), (1, 'MTH', 'STF-002'),
    (1, 'BSC', 'STF-003'), (1, 'BST', 'STF-004'),
    (1, 'CIV', 'STF-005'), (1, 'CRS', 'STF-006'),
    (1, 'BUS', 'STF-004'), (1, 'YOR', 'STF-005'),
    (2, 'ENG', 'STF-002'), (2, 'MTH', 'STF-003'),
    (2, 'BSC', 'STF-004'), (2, 'BST', 'STF-005'),
    (2, 'CIV', 'STF-006'), (2, 'CRS', 'STF-001'),
    (2, 'BUS', 'STF-005'), (2, 'YOR', 'STF-006'),
    (3, 'ENG', 'STF-003'), (3, 'MTH', 'STF-004'),
    (3, 'BSC', 'STF-005'), (3, 'BST', 'STF-006'),
    (3, 'CIV', 'STF-001'), (3, 'CRS', 'STF-002'),
    (3, 'BUS', 'STF-006'), (3, 'YOR', 'STF-001');

-- Generate a result for each enrolled student and each subject offered by
-- their class. The formulas produce CA scores from 18–40 and exam scores 35–60.
INSERT INTO results
    (admission_number, subject_code, term_id, ca_score, exam_score)
SELECT
    e.admission_number,
    cs.subject_code,
    e.term_id,
    18.00 + MOD(
        CAST(RIGHT(e.admission_number, 3) AS UNSIGNED)
        + CASE cs.subject_code
            WHEN 'ENG' THEN 1 WHEN 'MTH' THEN 2
            WHEN 'BSC' THEN 3 WHEN 'BST' THEN 4
            WHEN 'CIV' THEN 5 WHEN 'CRS' THEN 6
            WHEN 'BUS' THEN 7 WHEN 'YOR' THEN 8
          END,
        23
    ),
    35.00 + MOD(
        CAST(RIGHT(e.admission_number, 3) AS UNSIGNED)
        + CASE cs.subject_code
            WHEN 'ENG' THEN 1 WHEN 'MTH' THEN 2
            WHEN 'BSC' THEN 3 WHEN 'BST' THEN 4
            WHEN 'CIV' THEN 5 WHEN 'CRS' THEN 6
            WHEN 'BUS' THEN 7 WHEN 'YOR' THEN 8
          END,
        26
    )
FROM enrollments AS e
JOIN class_subjects AS cs
    ON cs.class_id = e.class_id;

-- Five sample school days, expanded to one attendance row per enrollment/day.
INSERT INTO attendance (admission_number, attendance_date, status)
SELECT
    e.admission_number,
    school_days.attendance_date,
    CASE MOD(
        CAST(RIGHT(e.admission_number, 3) AS UNSIGNED) + school_days.day_number,
        17
    )
        WHEN 0 THEN 'absent'
        WHEN 1 THEN 'late'
        ELSE 'present'
    END
FROM enrollments AS e
CROSS JOIN (
    SELECT 1 AS day_number, DATE('2026-11-02') AS attendance_date
    UNION ALL SELECT 2, DATE('2026-11-03')
    UNION ALL SELECT 3, DATE('2026-11-04')
    UNION ALL SELECT 4, DATE('2026-11-05')
    UNION ALL SELECT 5, DATE('2026-11-06')
) AS school_days;

COMMIT;
