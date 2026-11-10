# Secondary School Database

MySQL/MariaDB relational model for students, teachers, classes, subjects,
terms, results, attendance, and class-transfer history. Tables use InnoDB and
utf8mb4.

## Load the database

The following PowerShell commands use the default XAMPP install path and root
without a password. Adjust the executable path, username, or connection options
for your local setup.

```powershell
& 'C:\xampp\mysql\bin\mysql.exe' -u root -e "CREATE DATABASE school_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
Get-Content .\schema.sql -Raw | & 'C:\xampp\mysql\bin\mysql.exe' -u root school_db
Get-Content .\seed.sql -Raw | & 'C:\xampp\mysql\bin\mysql.exe' -u root school_db
Get-Content .\indexes.sql -Raw | & 'C:\xampp\mysql\bin\mysql.exe' -u root school_db
Get-Content .\procedures.sql -Raw | & 'C:\xampp\mysql\bin\mysql.exe' -u root school_db
Get-Content .\queries.sql -Raw | & 'C:\xampp\mysql\bin\mysql.exe' -u root school_db
```

Run `schema.sql` first; it drops and recreates the school tables. Run `seed.sql`
once on a fresh schema. `indexes.sql` also runs once, because its indexes
already exist after the first run. `queries.sql` runs the eight reports and
creates the two views. It initially selects the term labeled
`2026/2027 First Term`; change that label in the file to report on another term.

`transactions.sql` contains an example transfer that commits a data change.
Review its variables and execute it manually only when you intend to move that
student. The file also defines `sp_transfer_student`, which rejects invalid
transfers and rolls back. `schema.sql` is for a fresh/rebuilt database, not for
upgrading a database whose data must be retained.

## File guide

| File | Purpose |
|---|---|
| [schema.sql](./schema.sql) | InnoDB tables, keys, score/date checks, transfer audit table, and foreign-key rules |
| [seed.sql](./seed.sql) | Nigerian sample data: 3 classes, 8 subjects, 6 teachers, 30 students, generated results and attendance |
| [queries.sql](./queries.sql) | Eight commented reporting queries and the `v_student_results` and `v_class_summary` views |
| [indexes.sql](./indexes.sql) | Supporting indexes for term-based result reports and attendance date scans |
| [procedures.sql](./procedures.sql) | Validated `sp_record_result` procedure with an upsert |
| [transactions.sql](./transactions.sql) | Atomic class-transfer examples and the rollback-safe `sp_transfer_student` procedure |

## ERD

```mermaid
erDiagram
    STUDENT {
        string admission_number PK
        string first_name
        string middle_name
        string last_name
        date date_of_birth
        string gender
        string guardian_name
        string guardian_phone
    }

    TEACHER {
        string staff_number PK
        string first_name
        string middle_name
        string last_name
        string email UK
        string phone
        date hire_date
    }

    CLASS {
        int class_id PK
        string class_name UK
        string form_teacher_staff_number FK
    }

    SUBJECT {
        string subject_code PK
        string subject_name UK
    }

    TERM {
        int term_id PK
        string label UK
        date start_date
        date end_date
    }

    ENROLLMENT {
        string admission_number PK, FK
        int term_id PK, FK
        int class_id FK
    }

    CLASS_SUBJECT {
        int class_id PK, FK
        string subject_code PK, FK
        string teacher_staff_number FK
    }

    RESULT {
        string admission_number PK, FK
        string subject_code PK, FK
        int term_id PK, FK
        decimal ca_score
        decimal exam_score
    }

    ATTENDANCE {
        string admission_number PK, FK
        date attendance_date PK
        string status
    }

    CLASS_TRANSFER {
        int transfer_id PK
        string admission_number FK
        int term_id FK
        int from_class_id FK
        int to_class_id FK
        datetime transferred_at
        string actor_staff_number FK
    }

    TEACHER ||--o{ CLASS : "is form teacher for"
    STUDENT ||--o{ ENROLLMENT : "has term placement"
    CLASS ||--o{ ENROLLMENT : "has enrolled students"
    TERM ||--o{ ENROLLMENT : "covers"
    CLASS ||--o{ CLASS_SUBJECT : "offers"
    SUBJECT ||--o{ CLASS_SUBJECT : "is offered in"
    TEACHER ||--o{ CLASS_SUBJECT : "teaches"
    STUDENT ||--o{ RESULT : "earns"
    SUBJECT ||--o{ RESULT : "is assessed in"
    TERM ||--o{ RESULT : "records"
    ENROLLMENT ||--o{ RESULT : "must exist for"
    STUDENT ||--o{ ATTENDANCE : "has daily records"
    STUDENT ||--o{ CLASS_TRANSFER : "has transfer history"
    TERM ||--o{ CLASS_TRANSFER : "records"
    CLASS ||--o{ CLASS_TRANSFER : "is source or destination"
    TEACHER o|--o{ CLASS_TRANSFER : "records"
```

Enrollment records a student's class per term, rather than storing a single
class on the student. Results are unique per student, subject, and term and
require an enrollment in that term. `sp_record_result` additionally checks that
the subject is offered by the student's enrolled class before inserting or
updating the score.

## Three useful query patterns

The examples use the selected term (`@term_id`) in [queries.sql](./queries.sql).

### Query 3: class averages and position

The inner query groups results into one average per student and class. The
outer `RANK() OVER (PARTITION BY class_id ORDER BY average_score DESC)` ranks
those averages within each class, assigning equal scores the same rank. The
file also includes a correlated-count fallback for MySQL versions before 8.0,
which do not support window functions.

### Query 5: students failing at least two subjects

`WHERE` first filters individual results to totals below 40. `GROUP BY`
collects the failing subjects per student, and `HAVING COUNT(*) >= 2` filters
those groups. `WHERE` filters rows before aggregation; `HAVING` filters groups
after aggregation.

### Query 7: attendance below 80%

The CTEs count distinct dates with attendance records during the term and each
student's attended days (`present` or `late`). The `LEFT JOIN` keeps enrolled
students who have no attendance entries; `NULLIF` protects against division by
zero. The denominator is recorded attendance dates, not all calendar weekdays
or a school timetable.

## EXPLAIN and index lesson

The following plans were captured with ordinary `EXPLAIN` on MariaDB
10.4.32. For a useful comparison, I used the seed plus two older terms (720
result rows total) and 730 out-of-term attendance rows (880 attendance rows
total) in an isolated test database. Those extra rows were only for the plan
experiment; the supplied seed remains one term with 240 results and 150
attendance records.

In the plan, `type` describes access (`ALL` is a table scan, `index` a full
index scan, `range` a range scan, `ref` an indexed lookup, and `eq_ref` at most
one matching row from a unique key). `key` is the index chosen (`NULL` means no
index), and `rows` is the optimizer's estimated rows per access, not an actual
count. `possible_keys` lists candidates, but only `key` is selected.

### Query 3: average and rank

The `results` lookup is the access that changes. The other join access paths
remain the same.

| Access | Before: `type` / `key` / `rows` | After: `type` / `key` / `rows` |
|---|---|---|
| Materialized student averages (`<derived2>`) | `ALL` / `NULL` / 180 | `ALL` / `NULL` / 60 |
| `classes` | `index` / `uq_classes_class_name` / 3 | `index` / `uq_classes_class_name` / 3 |
| `enrollments` | `ref` / `fk_enrollments_class` / 5 | `ref` / `fk_enrollments_class` / 5 |
| `students` | `eq_ref` / `PRIMARY` / 1 | `eq_ref` / `PRIMARY` / 1 |
| `results` | `ref` / `PRIMARY` / 12 | `ref` / `idx_results_term_student_subject_scores` / 4 |

### Query 5: two or more failing subjects

| Access | Before: `type` / `key` / `rows` | After: `type` / `key` / `rows` |
|---|---|---|
| `classes` | `index` / `uq_classes_class_name` / 3 | `index` / `uq_classes_class_name` / 3 |
| `enrollments` | `ref` / `fk_enrollments_class` / 5 | `ref` / `fk_enrollments_class` / 5 |
| `students` | `eq_ref` / `PRIMARY` / 1 | `eq_ref` / `PRIMARY` / 1 |
| `results` | `ref` / `PRIMARY` / 12 | `ref` / `idx_results_term_student_subject_scores` / 4 |

### Query 7: attendance percentage

The term-days CTE scans attendance by date. The per-student lookup continues
to use the primary key, which already starts with `admission_number`.

| Access | Before: `type` / `key` / `rows` | After: `type` / `key` / `rows` |
|---|---|---|
| Outer `classes` lookup | `index` / `uq_classes_class_name` / 3 | `index` / `uq_classes_class_name` / 3 |
| Per-student attendance lookup | `ref` / `PRIMARY` / 14 | `ref` / `PRIMARY` / 14 |
| Term-days attendance scan | `index` / `PRIMARY` / 880 | `range` / `idx_attendance_date_student_status` / 150 |

The results index begins with `(term_id, admission_number)`, so a term-filtered
student lookup no longer reads that student's result rows for other terms. It
also includes subject and both scores, allowing these report accesses to be
covered by the index. It cannot directly seek on Query 5's calculated
`ca_score + exam_score < 40` expression. The attendance index begins with
`attendance_date` to support the term-wide date range; it does not replace the
student/date primary key for per-student lookups.

The sample is deliberately small, and a real optimizer may choose differently
depending on row counts, data distribution, and statistics. Always compare
plans on representative data; `rows` is an estimate, not a runtime benchmark.

## Export the full database in phpMyAdmin

1. Select **school_db** in phpMyAdmin's left navigation, then click **Export**.
   Select the database, not an individual table.
2. Choose **Custom** export and keep **SQL** as the format.
3. Select all tables and include both structure and data. Enable routines and
   triggers if the options are available and you want stored procedures
   included.
4. Choose compression if desired, then click **Export** or **Go**.
5. Save the downloaded file as `database.sql`.

phpMyAdmin versions place view, routine, and trigger options in different
sections. Review the export options to confirm which objects are included.
