/*
Assignment: Final Project - Database Population Script
Course:     DAT 153
Term:       Spring 2025
Lab team:
  - Will Kercher
  - Jack Potter
*/

-- inserting data into tables --
-- Insert positions
INSERT INTO public.positions (position_title)
SELECT DISTINCT unnest(string_to_array(positions, ','))
FROM staging.members
WHERE positions IS NOT NULL;

-- Insert divisions
INSERT INTO public.division (division_name, division_leader)
SELECT DISTINCT current_division, division_leader
FROM staging.members
WHERE current_division IS NOT NULL;

-- Insert into member --
WITH inserted_members AS (
    INSERT INTO public.member (
        email, first_name, last_name, full_name, class_year,
        fk_current_division_id, wildcatsync,
        graduation_date, membership_type, status
    )
    SELECT
        s.email, s.first_name, s.last_name, s.full_name, s.class_year::integer,
        d.pk_division_id,
        s.wildcatsync, s.graduation_date, s.membership_type, s.status
    FROM staging.members s
    LEFT JOIN public.division d ON d.division_name = s.current_division
    RETURNING pk_member_id, email
)

-- Insert into member_position using the inserted members and matched positions
INSERT INTO public.member_position (fk_member_id, fk_position_id)
SELECT
    im.pk_member_id,
    p.pk_position_id
FROM staging.members s
JOIN inserted_members im ON s.email = im.email
JOIN public.positions p ON p.position_title = ANY(string_to_array(s.positions, ','))
WHERE s.positions IS NOT NULL;

-- insert into role --
INSERT INTO role (role_title)
VALUES
('Head Coach'),
('Staff')
ON CONFLICT (role_title) DO NOTHING;

-- insert into rank --
INSERT INTO rank (rank_title)
VALUES
('Primary'),
('Secondary'),
('Third')
ON CONFLICT (rank_title) DO NOTHING;

-- insert into contact --
INSERT INTO contact (
    contact_name, contact_position, division, contact_email, contact_phone, contact_rank
)
SELECT
    s.contact_name,
    r.pk_role_id,
    d.pk_division_id,
    s.contact_email,
    s.contact_phone,
    rk.pk_rank_id
FROM staging.contacts_consolidated s
LEFT JOIN role r ON r.role_title = s.contact_position
LEFT JOIN rank rk ON rk.rank_title = s.contact_rank
LEFT JOIN division d ON d.division_name = s.division;





