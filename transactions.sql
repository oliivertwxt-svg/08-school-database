-- Run schema.sql first. These examples change enrollment data; update the
-- variables before running, and do not execute both examples for the same move.

-- Example 1: Valid transfer. Audit the old/new class and update the enrollment
-- in the same transaction so either both statements succeed or neither does.
SET @transfer_student = 'STU-2026-001';
SET @transfer_term = 1;
SET @target_class = 2;
SET @actor_staff = 'STF-001';

START TRANSACTION;

INSERT INTO class_transfers
    (admission_number, term_id, from_class_id, to_class_id, actor_staff_number)
SELECT
    e.admission_number,
    e.term_id,
    e.class_id,
    @target_class,
    @actor_staff
FROM enrollments AS e
JOIN classes AS target_class
    ON target_class.class_id = @target_class
WHERE e.admission_number = @transfer_student
  AND e.term_id = @transfer_term
  AND e.class_id <> @target_class;

UPDATE enrollments
SET class_id = @target_class
WHERE admission_number = @transfer_student
  AND term_id = @transfer_term
  AND class_id <> @target_class;

COMMIT;

-- Example 2: Defensive version. A missing target class raises an error and
-- the EXIT handler rolls back the transaction before returning that error.
DELIMITER //
DROP PROCEDURE IF EXISTS sp_transfer_student//
CREATE PROCEDURE sp_transfer_student(
    IN p_admission_number VARCHAR(20),
    IN p_term_id INT UNSIGNED,
    IN p_target_class_id INT UNSIGNED,
    IN p_actor_staff_number VARCHAR(20)
)
BEGIN
    DECLARE v_current_class_id INT UNSIGNED DEFAULT NULL;
    DECLARE v_enrollment_count INT DEFAULT 0;
    DECLARE v_target_count INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT COUNT(*)
    INTO v_enrollment_count
    FROM enrollments
    WHERE admission_number = p_admission_number
      AND term_id = p_term_id;

    IF v_enrollment_count = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Student has no enrollment in the specified term';
    END IF;

    SELECT class_id
    INTO v_current_class_id
    FROM enrollments
    WHERE admission_number = p_admission_number
      AND term_id = p_term_id
    FOR UPDATE;

    SELECT COUNT(*)
    INTO v_target_count
    FROM classes
    WHERE class_id = p_target_class_id;

    IF v_target_count = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Target class does not exist; transfer rolled back';
    END IF;

    IF v_current_class_id = p_target_class_id THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Student is already enrolled in the target class';
    END IF;

    INSERT INTO class_transfers
        (admission_number, term_id, from_class_id, to_class_id, actor_staff_number)
    VALUES
        (p_admission_number, p_term_id, v_current_class_id, p_target_class_id, p_actor_staff_number);

    UPDATE enrollments
    SET class_id = p_target_class_id
    WHERE admission_number = p_admission_number
      AND term_id = p_term_id
      AND class_id = v_current_class_id;

    COMMIT;
END//
DELIMITER ;

-- Demonstrate the rejected-target case manually (expected SQLSTATE 45000):
-- CALL sp_transfer_student('STU-2026-001', 1, 999999, 'STF-001');
