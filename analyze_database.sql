/*
Assignment: Final Project - Database Analysis Script
Course:     DAT 153
Term:       Spring 2025
Lab team:
  - Will Kercher
  - Jack Potter
*/

-- 1. Create a list of all the inactive members of CatStats --
SELECT
    first_name,
    last_name,
    status
FROM member
WHERE status = 'Inactive';


-- 2. Create a list of members first names, last names, and class years --
SELECT
    first_name,
    last_name,
    class_year
FROM member
ORDER BY class_year;

-- 3. Connect each division with their contacts to get a list of who is supposed to be in contact with what coaches --
SELECT
    d.division_name,
    d.division_leader,
    c.contact_name,
    c.contact_email,
    c.contact_phone
FROM division d
    JOIN contact c ON c.pk_contact_id = pk_division_id
ORDER BY division_name;

-- 4. Create a list of everyone and their division, order by division --
SELECT
    m.first_name,
    m.last_name,
    d.division_name
FROM member m
    JOIN division d ON m.fk_current_division_id = d.pk_division_id
ORDER BY fk_current_division_id;

-- 5. It is the end of the year, and you must figure out who is graduating so you can remove them from the database. --
-- Generate a list of members who are graduating in 2025, and their current position so you know where replacements will be necessary --
SELECT
    m.full_name,
    m.graduation_date,
    p.position_title
FROM member m
    JOIN member_position ON fk_member_id = pk_member_id
    JOIN positions p ON fk_position_id = pk_position_id
WHERE class_year = '2025';

-- 6. Find out how big each division is, this will help you determine how many managers you will need to keep each division running smoothly --
SELECT
    d.division_name,
    COUNT(m.full_name)
FROM division d
    JOIN member m ON fk_current_division_id = pk_division_id
GROUP BY division_name;

-- 7. Generate an output that summarizes the contact for a division. Make sure to include the contact's division, role, and rank_title --
SELECT
    c.contact_name,
    d.division_name,
    r.rank_title,
    ro.role_title
FROM contact c
    JOIN role ro ON pk_role_id = c.contact_position
    JOIN rank r ON pk_rank_id = contact_rank
    JOIN division d ON pk_division_id = division
ORDER BY contact_name;

-- 8. Find members with missing or null status --
SELECT first_name, last_name
FROM member
WHERE status IS NULL OR status = '';

-- 9. List all divisions, sub-divisions, and the corresponding members in each one. Within the ordered divisions, order the information by sub-division
SELECT
    d.division_name,
    sd.sub_division_name,
    m.first_name,
    m.last_name
FROM division d
LEFT JOIN sub_division sd ON d.pk_division_id = sd.pk_sub_division_id
LEFT JOIN member m ON d.pk_division_id = m.fk_current_division_id
ORDER BY d.division_name, sd.sub_division_name;


-- 10. You need to make an email-list of all the division and sub-division leaders so you can schedule an e-board meeting. Generate a list of all leaders and their emails --
SELECT
    m.first_name,
    m.last_name,
    d.division_name,
    d.division_leader,
    sd.sub_division_name,
    sd.sub_division_leader,
    m.email
FROM member m
    JOIN sub_division sd ON pk_sub_division_id = fk_sub_division_id
    JOIN division d ON pk_division_id = fk_current_division_id
ORDER BY division_name, sub_division_name