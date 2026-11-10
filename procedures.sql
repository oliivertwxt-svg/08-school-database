-- Run schema.sql first. This single upsert is atomic and can participate in
-- a caller's larger transaction.
DELIMITER //
DROP PROCEDURE IF EXISTS sp_record_result//
CREATE PROCEDURE sp_record_result(
    IN p_admission_number VARCHAR(20),
    IN p_subject_code VARCHAR(12),
    IN p_term_id INT UNSIGNED,
    IN p_ca_score DECIMAL(5,2),
    IN p_exam_score DECIMAL(5,2)
)
BEGIN
    DECLARE v_class_id INT UNSIGNED DEFAULT NULL;

    IF p_admission_number IS NULL OR TRIM(p_admission_number) = ''
       OR p_subject_code IS NULL OR TRIM(p_subject_code) = ''
       OR p_term_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Student, subject, and term are required';
    END IF;

    IF p_ca_score IS NULL OR p_ca_score < 0 OR p_ca_score > 40 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'CA score must be between 0 and 40';
    END IF;

    IF p_exam_score IS NULL OR p_exam_score < 0 OR p_exam_score > 60 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Exam score must be between 0 and 60';
    END IF;

    SELECT MAX(e.class_id)
    INTO v_class_id
    FROM enrollments AS e
    JOIN class_subjects AS cs
        ON cs.class_id = e.class_id
       AND cs.subject_code = p_subject_code
    WHERE e.admission_number = p_admission_number
      AND e.term_id = p_term_id;

    IF v_class_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Student enrollment or class subject assignment not found';
    END IF;

    INSERT INTO results
        (admission_number, subject_code, term_id, ca_score, exam_score)
    VALUES
        (p_admission_number, p_subject_code, p_term_id, p_ca_score, p_exam_score)
    ON DUPLICATE KEY UPDATE
        ca_score = VALUES(ca_score),
        exam_score = VALUES(exam_score);
END//
DELIMITER ;
