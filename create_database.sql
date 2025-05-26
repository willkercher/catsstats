/*
Assignment: Final Project - Database Creation Script
Course:     DAT 153
Term:       Spring 2025
Lab team:
  - Will Kercher
  - Jack Potter
*/

-- creating tables --
DO $$
BEGIN
    EXECUTE 'DROP TABLE IF EXISTS public.member CASCADE;';
    EXECUTE 'DROP TABLE IF EXISTS public.contact CASCADE;';
    EXECUTE 'DROP TABLE IF EXISTS public.position CASCADE;';
    EXECUTE 'DROP TABLE IF EXISTS public.membership CASCADE;';
    EXECUTE 'DROP TABLE IF EXISTS public.division CASCADE;';
    EXECUTE 'DROP TABLE IF EXISTS public.sub_division CASCADE;';
    EXECUTE 'DROP TABLE IF EXISTS public.rank CASCADE;';
    EXECUTE 'DROP TABLE IF EXISTS public.role CASCADE;';
END $$;

DROP TABLE IF EXISTS public.member_previous_division CASCADE;
DROP TABLE IF EXISTS public.member_previous_position CASCADE;
DROP TABLE IF EXISTS public.contact CASCADE;

-- create positions table --
create table if not exists public.positions (
    pk_position_id integer generated always as identity primary key,
    position_title varchar(30) not null
);

-- sub_division table --
create table if not exists public.sub_division (
    pk_sub_division_id integer generated always as identity primary key,
    sub_division_name varchar(30) not null,
    sub_division_leader varchar(40)
);

-- create division table --
create table if not exists public.division (
    pk_division_id integer generated always as identity primary key,
    division_name varchar(30) not null,
    division_leader varchar(40)
);

-- create member table --
create table if not exists public.member (
    pk_member_id integer generated always as identity primary key,
    email varchar(30) not null,
    first_name varchar(20),
    last_name varchar(20),
    full_name varchar(40),
    class_year integer,
    fk_current_division_id integer references public.division(pk_division_id),
    fk_sub_division_id integer references public.sub_division(pk_sub_division_id),
    wildcatsync boolean not null,
    graduation_date date,
    membership_type varchar(20),
    status varchar(15)
);

-- Junction table - member_position --
CREATE TABLE IF NOT EXISTS member_position (
    fk_member_id INTEGER REFERENCES member(pk_member_id) ON DELETE CASCADE,
    fk_position_id INTEGER REFERENCES positions(pk_position_id) ON DELETE CASCADE,
    PRIMARY KEY (fk_member_id, fk_position_id)
);

-- role table --
CREATE TABLE role (
    pk_role_id SERIAL PRIMARY KEY,
    role_title TEXT NOT NULL UNIQUE
);

-- Rank table --
CREATE TABLE rank (
    pk_rank_id SERIAL PRIMARY KEY,
    rank_title TEXT NOT NULL UNIQUE
);

-- Contact table --
CREATE TABLE contact (
    pk_contact_id SERIAL PRIMARY KEY,
    contact_name TEXT NOT NULL,
    contact_position INTEGER REFERENCES role(pk_role_id),
    division INTEGER REFERENCES division(pk_division_id),
    contact_email TEXT,
    contact_phone TEXT,
    contact_rank INTEGER REFERENCES rank(pk_rank_id)
);

-- function for concatenating full_name column --
CREATE OR REPLACE FUNCTION update_full_name()
RETURNS TRIGGER AS $$
BEGIN
  NEW.full_name := NEW.first_name || ' ' || NEW.last_name;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- creating trigger --
CREATE TRIGGER trg_update_full_name
BEFORE INSERT OR UPDATE ON member
FOR EACH ROW
EXECUTE FUNCTION update_full_name();

-- *the view was produced in python script as the frontend of the website* --

-- more functions for determining membership_type --
CREATE OR REPLACE FUNCTION update_member_status(member_id_input INT)
RETURNS VOID AS $$
DECLARE
  grad_year INT;
  grad_date DATE;
  has_advisor BOOLEAN;
BEGIN
  -- Get class year and compute graduation date
  SELECT class_year INTO grad_year FROM member WHERE pk_member_id = member_id_input;
  grad_date := TO_DATE(grad_year || '-05-15', 'YYYY-MM-DD');

  -- Update graduation_date
  UPDATE member
  SET graduation_date = grad_date
  WHERE pk_member_id = member_id_input;

  -- Check for Advisor position
  SELECT EXISTS (
    SELECT 1 FROM member_position mp
    JOIN positions p ON mp.fk_position_id = p.pk_position_id
    WHERE mp.fk_member_id = member_id_input AND p.name ILIKE '%Advisor%'
  ) INTO has_advisor;

  -- Determine membership_type
  UPDATE member
  SET membership_type = CASE
    WHEN grad_date < CURRENT_DATE THEN 'Alumni'
    WHEN has_advisor THEN 'Advisor'
    ELSE 'Student'
  END
  WHERE pk_member_id = member_id_input;
END;
$$ LANGUAGE plpgsql;

-- triggers for membership_type functions --
CREATE OR REPLACE FUNCTION trg_member_update()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM update_member_status(NEW.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_member_update_trigger
AFTER INSERT OR UPDATE OF class_year ON member
FOR EACH ROW
EXECUTE FUNCTION trg_member_update();








