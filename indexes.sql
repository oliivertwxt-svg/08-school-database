-- Supporting indexes for term-based result reports and date-based attendance.
-- Run once after schema.sql; remove existing indexes manually before re-running.

-- Queries 3 and 5 filter results by term and then group/join by student.
-- Including subject and scores makes the term-filtered result access covering.
CREATE INDEX idx_results_term_student_subject_scores
    ON results (term_id, admission_number, subject_code, ca_score, exam_score);

-- Query 7 scans attendance records in a term date range. The primary key
-- (admission_number, attendance_date) already supports per-student date lookups.
CREATE INDEX idx_attendance_date_student_status
    ON attendance (attendance_date, admission_number, status);
