-- Reporting examples use the selected term; change the label to query another term.
SET @term_id := (
    SELECT term_id
    FROM terms
    WHERE label = '2026/2027 First Term'
);

-- 1. Business question: Which students are in JSS1 A, and who is their form teacher?
-- Technique: JOIN follows the class-to-teacher and enrollment-to-student relationships.
SELECT
    c.class_name,
    s.admission_number,
    CONCAT_WS(' ', s.first_name, s.middle_name, s.last_name) AS student_name,
    CONCAT_WS(' ', t.first_name, t.middle_name, t.last_name) AS form_teacher_name
FROM classes AS c
JOIN teachers AS t
    ON t.staff_number = c.form_teacher_staff_number
JOIN enrollments AS e
    ON e.class_id = c.class_id
JOIN students AS s
    ON s.admission_number = e.admission_number
WHERE c.class_name = 'JSS1 A'
  AND e.term_id = @term_id
ORDER BY s.last_name, s.first_name;

-- 2. Business question: What is each student's total score and letter grade per subject this term?
-- Technique: Add CA and exam scores, then CASE maps the total to a grade band.
SELECT
    s.admission_number,
    CONCAT_WS(' ', s.first_name, s.middle_name, s.last_name) AS student_name,
    c.class_name,
    sub.subject_name,
    r.ca_score,
    r.exam_score,
    r.ca_score + r.exam_score AS total_score,
    CASE
        WHEN r.ca_score + r.exam_score >= 80 THEN 'A'
        WHEN r.ca_score + r.exam_score >= 70 THEN 'B'
        WHEN r.ca_score + r.exam_score >= 60 THEN 'C'
        WHEN r.ca_score + r.exam_score >= 50 THEN 'D'
        WHEN r.ca_score + r.exam_score >= 40 THEN 'E'
        ELSE 'F'
    END AS grade
FROM results AS r
JOIN students AS s
    ON s.admission_number = r.admission_number
JOIN enrollments AS e
    ON e.admission_number = r.admission_number
   AND e.term_id = r.term_id
JOIN classes AS c
    ON c.class_id = e.class_id
JOIN subjects AS sub
    ON sub.subject_code = r.subject_code
WHERE r.term_id = @term_id
ORDER BY c.class_name, s.last_name, s.first_name, sub.subject_name;

-- 3. Business question: What is each student's average score and position in class this term?
-- Technique: Aggregate one average per student, then RANK() ranks averages within each class.
-- Tied averages receive the same rank, with gaps after ties.
SELECT
    averages.class_name,
    averages.admission_number,
    averages.student_name,
    averages.average_score,
    RANK() OVER (
        PARTITION BY averages.class_id
        ORDER BY averages.average_score DESC
    ) AS class_position
FROM (
    SELECT
        c.class_id,
        c.class_name,
        s.admission_number,
        CONCAT_WS(' ', s.first_name, s.middle_name, s.last_name) AS student_name,
        AVG(r.ca_score + r.exam_score) AS average_score
    FROM results AS r
    JOIN students AS s
        ON s.admission_number = r.admission_number
    JOIN enrollments AS e
        ON e.admission_number = r.admission_number
       AND e.term_id = r.term_id
    JOIN classes AS c
        ON c.class_id = e.class_id
    WHERE r.term_id = @term_id
    GROUP BY
        c.class_id,
        c.class_name,
        s.admission_number,
        s.first_name,
        s.middle_name,
        s.last_name
) AS averages
ORDER BY averages.class_name, class_position, averages.student_name;

-- Query 3 fallback for MySQL versions before 8.0, which do not support window functions.
-- Technique: Count students with a strictly higher average in the same class;
-- tied students share a competition rank (1, 1, 3).
SELECT
    averages.class_name,
    averages.admission_number,
    averages.student_name,
    averages.average_score,
    1 + (
        SELECT COUNT(*)
        FROM (
            SELECT
                e2.class_id,
                r2.admission_number,
                AVG(r2.ca_score + r2.exam_score) AS average_score
            FROM results AS r2
            JOIN enrollments AS e2
                ON e2.admission_number = r2.admission_number
               AND e2.term_id = r2.term_id
            WHERE r2.term_id = @term_id
            GROUP BY e2.class_id, r2.admission_number
        ) AS other_averages
        WHERE other_averages.class_id = averages.class_id
          AND other_averages.average_score > averages.average_score
    ) AS class_position
FROM (
    SELECT
        c.class_id,
        c.class_name,
        s.admission_number,
        CONCAT_WS(' ', s.first_name, s.middle_name, s.last_name) AS student_name,
        AVG(r.ca_score + r.exam_score) AS average_score
    FROM results AS r
    JOIN students AS s
        ON s.admission_number = r.admission_number
    JOIN enrollments AS e
        ON e.admission_number = r.admission_number
       AND e.term_id = r.term_id
    JOIN classes AS c
        ON c.class_id = e.class_id
    WHERE r.term_id = @term_id
    GROUP BY
        c.class_id,
        c.class_name,
        s.admission_number,
        s.first_name,
        s.middle_name,
        s.last_name
) AS averages
ORDER BY averages.class_name, class_position, averages.student_name;

-- 4. Business question: What are the average, highest, and lowest scores per subject in each class?
-- Technique: GROUP BY class and subject, with AVG, MAX, and MIN aggregates.
SELECT
    c.class_name,
    sub.subject_name,
    COUNT(*) AS students_with_results,
    ROUND(AVG(r.ca_score + r.exam_score), 2) AS average_score,
    MAX(r.ca_score + r.exam_score) AS highest_score,
    MIN(r.ca_score + r.exam_score) AS lowest_score
FROM results AS r
JOIN enrollments AS e
    ON e.admission_number = r.admission_number
   AND e.term_id = r.term_id
JOIN classes AS c
    ON c.class_id = e.class_id
JOIN subjects AS sub
    ON sub.subject_code = r.subject_code
WHERE r.term_id = @term_id
GROUP BY c.class_id, c.class_name, sub.subject_code, sub.subject_name
ORDER BY c.class_name, sub.subject_name;

-- 5. Business question: Which students scored below 40 in at least two subjects this term?
-- Technique: WHERE filters failing result rows; HAVING filters student groups by fail count.
SELECT
    s.admission_number,
    CONCAT_WS(' ', s.first_name, s.middle_name, s.last_name) AS student_name,
    c.class_name,
    COUNT(*) AS failed_subject_count
FROM results AS r
JOIN students AS s
    ON s.admission_number = r.admission_number
JOIN enrollments AS e
    ON e.admission_number = r.admission_number
   AND e.term_id = r.term_id
JOIN classes AS c
    ON c.class_id = e.class_id
WHERE r.term_id = @term_id
  AND r.ca_score + r.exam_score < 40
GROUP BY
    s.admission_number,
    s.first_name,
    s.middle_name,
    s.last_name,
    c.class_id,
    c.class_name
HAVING COUNT(*) >= 2
ORDER BY failed_subject_count DESC, c.class_name, student_name;

-- 6. Business question: How many subjects and classes does each teacher teach?
-- Technique: LEFT JOIN preserves teachers with no assignments; DISTINCT avoids
-- counting the same class more than once when a teacher teaches several subjects there.
SELECT
    t.staff_number,
    CONCAT_WS(' ', t.first_name, t.middle_name, t.last_name) AS teacher_name,
    COUNT(DISTINCT cs.subject_code) AS subject_count,
    COUNT(DISTINCT cs.class_id) AS class_count,
    COUNT(cs.class_id) AS class_subject_assignments
FROM teachers AS t
LEFT JOIN class_subjects AS cs
    ON cs.teacher_staff_number = t.staff_number
GROUP BY
    t.staff_number,
    t.first_name,
    t.middle_name,
    t.last_name
ORDER BY teacher_name;

-- 7. Business question: What percentage of recorded school days did each student attend,
-- and who is below 80% this term?
-- Technique: CTEs count distinct recorded dates and each student's present/late days.
-- LEFT JOIN retains students with no attendance rows; the denominator is recorded
-- attendance dates, not all calendar weekdays or scheduled school days.
WITH term_days AS (
    SELECT COUNT(DISTINCT a.attendance_date) AS recorded_days
    FROM attendance AS a
    JOIN terms AS t
        ON a.attendance_date BETWEEN t.start_date AND t.end_date
    WHERE t.term_id = @term_id
),
student_attendance AS (
    SELECT
        e.admission_number,
        e.class_id,
        COUNT(DISTINCT CASE
            WHEN a.status IN ('present', 'late') THEN a.attendance_date
        END) AS attended_days
    FROM enrollments AS e
    JOIN terms AS t
        ON t.term_id = e.term_id
    LEFT JOIN attendance AS a
        ON a.admission_number = e.admission_number
       AND a.attendance_date BETWEEN t.start_date AND t.end_date
    WHERE e.term_id = @term_id
    GROUP BY e.admission_number, e.class_id
)
SELECT
    s.admission_number,
    CONCAT_WS(' ', s.first_name, s.middle_name, s.last_name) AS student_name,
    c.class_name,
    sa.attended_days,
    td.recorded_days,
    ROUND(100.0 * sa.attended_days / NULLIF(td.recorded_days, 0), 2) AS attendance_percentage
FROM student_attendance AS sa
JOIN students AS s
    ON s.admission_number = sa.admission_number
JOIN classes AS c
    ON c.class_id = sa.class_id
CROSS JOIN term_days AS td
WHERE td.recorded_days > 0
  AND 100.0 * sa.attended_days / td.recorded_days < 80
ORDER BY attendance_percentage, c.class_name, student_name;

-- 8. Business question: Who is the top-scoring student or students in each class this term?
-- Technique: RANK() assigns rank 1 to the highest average and includes ties.
SELECT
    ranked.class_name,
    ranked.admission_number,
    ranked.student_name,
    ranked.average_score
FROM (
    SELECT
        c.class_id,
        c.class_name,
        s.admission_number,
        CONCAT_WS(' ', s.first_name, s.middle_name, s.last_name) AS student_name,
        AVG(r.ca_score + r.exam_score) AS average_score,
        RANK() OVER (
            PARTITION BY c.class_id
            ORDER BY AVG(r.ca_score + r.exam_score) DESC
        ) AS class_position
    FROM results AS r
    JOIN students AS s
        ON s.admission_number = r.admission_number
    JOIN enrollments AS e
        ON e.admission_number = r.admission_number
       AND e.term_id = r.term_id
    JOIN classes AS c
        ON c.class_id = e.class_id
    WHERE r.term_id = @term_id
    GROUP BY
        c.class_id,
        c.class_name,
        s.admission_number,
        s.first_name,
        s.middle_name,
        s.last_name
) AS ranked
WHERE ranked.class_position = 1
ORDER BY ranked.class_name, ranked.student_name;

-- View: One row per student, subject, and term, with the enrolled class,
-- computed total, and letter grade.
CREATE OR REPLACE VIEW v_student_results AS
SELECT
    r.admission_number,
    CONCAT_WS(' ', s.first_name, s.middle_name, s.last_name) AS student_name,
    e.class_id,
    c.class_name,
    r.term_id,
    t.label AS term_label,
    r.subject_code,
    sub.subject_name,
    r.ca_score,
    r.exam_score,
    r.ca_score + r.exam_score AS total_score,
    CASE
        WHEN r.ca_score + r.exam_score >= 80 THEN 'A'
        WHEN r.ca_score + r.exam_score >= 70 THEN 'B'
        WHEN r.ca_score + r.exam_score >= 60 THEN 'C'
        WHEN r.ca_score + r.exam_score >= 50 THEN 'D'
        WHEN r.ca_score + r.exam_score >= 40 THEN 'E'
        ELSE 'F'
    END AS grade
FROM results AS r
JOIN students AS s
    ON s.admission_number = r.admission_number
JOIN enrollments AS e
    ON e.admission_number = r.admission_number
   AND e.term_id = r.term_id
JOIN classes AS c
    ON c.class_id = e.class_id
JOIN terms AS t
    ON t.term_id = r.term_id
JOIN subjects AS sub
    ON sub.subject_code = r.subject_code;

-- View: One row per class and enrolled term, with enrollment, subject,
-- and result summaries. Separate aggregate subqueries avoid multiplying rows.
CREATE OR REPLACE VIEW v_class_summary AS
SELECT
    c.class_id,
    c.class_name,
    t.term_id,
    t.label AS term_label,
    enrollment_summary.student_count,
    COALESCE(subject_summary.subject_count, 0) AS subject_count,
    COALESCE(result_summary.result_count, 0) AS result_count,
    result_summary.average_score
FROM classes AS c
JOIN (
    SELECT class_id, term_id, COUNT(*) AS student_count
    FROM enrollments
    GROUP BY class_id, term_id
) AS enrollment_summary
    ON enrollment_summary.class_id = c.class_id
JOIN terms AS t
    ON t.term_id = enrollment_summary.term_id
LEFT JOIN (
    SELECT class_id, COUNT(*) AS subject_count
    FROM class_subjects
    GROUP BY class_id
) AS subject_summary
    ON subject_summary.class_id = c.class_id
LEFT JOIN (
    SELECT
        e.class_id,
        r.term_id,
        COUNT(*) AS result_count,
        ROUND(AVG(r.ca_score + r.exam_score), 2) AS average_score
    FROM results AS r
    JOIN enrollments AS e
        ON e.admission_number = r.admission_number
       AND e.term_id = r.term_id
    GROUP BY e.class_id, r.term_id
) AS result_summary
    ON result_summary.class_id = enrollment_summary.class_id
   AND result_summary.term_id = enrollment_summary.term_id;
