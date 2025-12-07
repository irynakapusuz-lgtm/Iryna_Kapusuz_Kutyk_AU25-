---Task 1. Creating database and schema
CREATE DATABASE recruit_agency;
CREATE SCHEMA recruit_core; 
SET search_path to recruit_core; ---we use it not to specify prefix schema each time;
---- Creating tables.
CREATE TABLE IF NOT EXISTS Candidate (
candidate_id      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
first_name        VARCHAR (50) NOT NULL,
last_name         VARCHAR (50) NOT NULL,
email             VARCHAR (100) NOT NULL UNIQUE,
phone             VARCHAR (30),
degree            VARCHAR (50),
experience_years  NUMERIC (3,1)
CHECK (experience_years >= 0),    -----can not be negative;
is_active         BOOLEAN NOT NULL DEFAULT TRUE
);

SELECT *
FROM candidate;

CREATE TABLE IF NOT EXISTS Employer (
employer_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
company_name VARCHAR (50) NOT NULL UNIQUE,
industry     VARCHAR (50),
contact_person VARCHAR (50),
contact_email  VARCHAR (100),
is_active BOOLEAN NOT NULL DEFAULT TRUE
);

SELECT *
FROM employer;


CREATE TABLE IF NOT EXISTS Recruiter (
recruiter_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
first_name VARCHAR (50) NOT NULL,
last_name  VARCHAR (50) NOT NULL,
email      VARCHAR (100) NOT NULL UNIQUE,
phone      VARCHAR (30),
hired_on   DATE NOT NULL
CHECK (hired_on > DATE '2000-01-01'),    
is_active BOOLEAN NOT NULL DEFAULT TRUE
);

SELECT *
FROM recruiter;


CREATE TABLE IF NOT EXISTS Skill (
skill_id   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
skill_name VARCHAR (50) NOT NULL UNIQUE,
category   VARCHAR (50) NOT NULL,
is_active BOOLEAN NOT NULL DEFAULT TRUE
);

SELECT *
FROM skill;

CREATE TABLE IF NOT EXISTS Job_Location (
location_id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
city            VARCHAR(50) NOT NULL,
country         VARCHAR(50) NOT NULL,
office_address  VARCHAR(100),
postal_code     VARCHAR(20),
is_active       BOOLEAN NOT NULL DEFAULT TRUE
);

SELECT*
FROM job_location;


CREATE TABLE IF NOT EXISTS Job_Offer (
job_id          INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
employer_id     INT NOT NULL,
recruiter_id    INT NOT NULL,
location_id     INT NOT NULL,
job_title       VARCHAR(100) NOT NULL,
employment_type VARCHAR(30) NOT NULL
CHECK (employment_type IN ('Full_time', 'Part_time')),
salary          NUMERIC(10,2) NOT NULL
CHECK (salary >= 0),
status          VARCHAR(30),
CONSTRAINT fk_job_offer_employer
FOREIGN KEY (employer_id)
REFERENCES Employer (employer_id),
CONSTRAINT fk_job_offer_recruiter
FOREIGN KEY (recruiter_id)
REFERENCES Recruiter (recruiter_id),
CONSTRAINT fk_job_offer_location
FOREIGN KEY (location_id)
REFERENCES Job_Location (location_id)
);

SELECT*
FROM job_offer;


CREATE TABLE IF NOT EXISTS Job_skill (
job_id INT NOT NULL,
skill_id INT NOT NULL,
requirement_type VARCHAR (30) NOT NULL
CHECK (requirement_type IN ('Required', 'Prefered')),
CONSTRAINT pk_job_skill
PRIMARY KEY (job_id, skill_id),
CONSTRAINT fk_job_skill_job
FOREIGN KEY (job_id)
REFERENCES job_offer (job_id),
CONSTRAINT fk_job_skill_skill
FOREIGN KEY (skill_id)
REFERENCES skill (skill_id)
);

SELECT*
FROM job_skill;



CREATE TABLE IF NOT EXISTS application (
application_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
candidate_id INT NOT NULL,
job_id       INT NOT NULL,
applied_at DATE NOT NULL DEFAULT CURRENT_DATE,
status VARCHAR (30),
CONSTRAINT fk_application_candidate
FOREIGN KEY (candidate_id)
REFERENCES candidate (candidate_id),

CONSTRAINT fk_application_id
FOREIGN KEY (job_id)
REFERENCES job_offer (job_id),

CONSTRAINT uq_application_candidate_job
UNIQUE (candidate_id,job_id)   ----- same candidate cant apply on same position twice
);

SELECT*
FROM application;


CREATE TABLE IF NOT EXISTS application_stage (
stage_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
application_id INT NOT NULL,
stage_name VARCHAR (30) NOT NULL,
stage_status VARCHAR (30) NOT NULL,
updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_DATE,

CONSTRAINT fk_stage_application
FOREIGN KEY (application_id)
REFERENCES application (application_id),

CONSTRAINT uq_app_stage UNIQUE (application_id, stage_name),
CONSTRAINT chk_app_stage_date
CHECK (updated_at > DATE '2000-01-01')
);

SELECT*
FROM application_stage;

CREATE TABLE IF NOT EXISTS Interview (
interview_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
application_id INT NOT NULL,
interviewer_name VARCHAR (100),
interview_date TIMESTAMP NOT NULL,
interview_type VARCHAR (30),
result VARCHAR (30),

CONSTRAINT fk_interview_application
FOREIGN KEY (application_id)
REFERENCES application (application_id)
);

SELECT *
FROM interview;


CREATE TABLE IF NOT EXISTS Offer (
offer_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
application_id INT NOT NULL UNIQUE, -----only 1 offer for 1 application from 1 candidate
offered_salary NUMERIC (6,2)
CHECK (offered_salary >= 0),
start_date DATE,
offer_status VARCHAR (30),

CONSTRAINT fk_offer_application
FOREIGN KEY (application_id)
REFERENCES application (application_id)
);

SELECT *
FROM interview;


CREATE TABLE IF NOT EXISTS Recruiter_performance (
performance_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
recruiter_id INT NOT NULL,
period_month DATE NOT NULL,
total_hires INT NOT NULL DEFAULT 0
CHECK (total_hires >= 0),                -----can not be negative 
avg_time_to_fill NUMERIC (5,2)
CHECK (avg_time_to_fill >= 0),
CONSTRAINT fk_perf_recruiter
FOREIGN KEY (recruiter_id)
REFERENCES recruiter (recruiter_id)
);

SELECT *
FROM recruiter_performance;

----Inserting into Tables;

INSERT INTO candidate (first_name, last_name, email, phone, degree, experience_years)
VALUES 
('Iryna',  'Kutyk',    'iryna.kutyk777@gmail.com',   '+905317960776', 'Data Analysis',    2.0),
('Oksana', 'Sidorenko','sidorenko.oks@gmail.com',    '+905312457894', 'Data Engineering', 4.0),
('Pavlo',  'Zibrov',   'zibrov.pav07@gmail.com',     '+380967546385', 'Computer systems', 7.0)
ON CONFLICT (email) DO NOTHING;

SELECT *
FROM candidate;


INSERT INTO employer (company_name, industry, contact_person, contact_email)
VALUES
('Sabanci Holding',      'Powerplant systems',   'Ivan Ivanov', 'ivanov03@gmail.com'),
('Foo',                  'FinTech',              'Ghady Rayes', 'rayesceo@gmail.com'),
('Turkish Technologies', 'Information systems',  'Ozkan Bey',   'cfo@gmail.com')
ON CONFLICT (company_name) DO NOTHING;

SELECT *
FROM employer;

INSERT INTO Recruiter (first_name, last_name, email, phone, hired_on)
VALUES
('Victoria', 'Alper',    'vic.alp@gmail.com',    '+905342538956', DATE '2020-05-20'),
('Roman',    'Polanski', 'polanskihr@gmail.com', '+905318764567', DATE '2023-03-27')
ON CONFLICT (email) DO NOTHING;

SELECT *
FROM recruiter;


INSERT INTO Skill (skill_name, category)
VALUES 
('Python',     'Technical'),
('Qlick',      'Technical'),
('Team work',  'Soft'),
('Leadership', 'Soft')
ON CONFLICT (skill_name) DO NOTHING;

SELECT *
FROM skill;


INSERT INTO job_location (city, country, office_address, postal_code)
SELECT 'Odesa', 'Ukraine', 'Heroiv Dnipra 5', '65025'
WHERE NOT EXISTS (
SELECT 1 FROM job_location
WHERE LOWER(city) = LOWER('Odesa')
AND LOWER(office_address) = LOWER('Heroiv Dnipra 5'));


INSERT INTO job_location (city, country, office_address, postal_code)
SELECT 'Kyiv', 'Ukraine', 'Chreschatyk 77', '71345'
WHERE NOT EXISTS (
SELECT 1 FROM job_location
WHERE LOWER(city) = LOWER('Kyiv')
AND LOWER(office_address) = LOWER('Chreschatyk 77'));

INSERT INTO job_location (city, country, office_address, postal_code)
SELECT 'Istanbul', 'Türkiye', 'Maslak sok, 34', '34485'
WHERE NOT EXISTS (
SELECT 1 FROM job_location
WHERE LOWER(city) = LOWER('Istanbul')
AND LOWER(office_address) = LOWER('Maslak sok, 34'));

SELECT *
FROM job_location;


---Business Analyst 
INSERT INTO job_offer (
employer_id, recruiter_id, location_id, job_title,
employment_type, salary, status)
SELECT e.employer_id, r.recruiter_id,l.location_id,
    'Business Analyst',
    'Full_time',
    7000.00,
    'Open'
FROM employer e
JOIN recruiter    r ON LOWER(r.email) = LOWER('vic.alp@gmail.com')
JOIN job_location l ON LOWER(l.city) = LOWER('Odesa')
WHERE LOWER(e.company_name) = LOWER('Sabanci Holding')
AND NOT EXISTS (SELECT 1
FROM job_offer jo
WHERE jo.employer_id = e.employer_id
AND LOWER(jo.job_title) = LOWER('Business Analyst'));

SELECT *
FROM Job_offer;

-- Data Engineer 
INSERT INTO job_offer (employer_id, recruiter_id, location_id, job_title,
employment_type, salary, status)
SELECT e.employer_id, r.recruiter_id,l.location_id,
    'Data Engineer',
    'Part_time',
    5000.00,
    'Open'
FROM employer e
JOIN recruiter    r ON LOWER(r.email) = LOWER('vic.alp@gmail.com')
JOIN job_location l ON LOWER(l.city) = LOWER('Kyiv')
WHERE LOWER(e.company_name) = LOWER('Foo')
AND NOT EXISTS (SELECT 1 FROM job_offer jo
WHERE jo.employer_id = e.employer_id
AND LOWER(jo.job_title) = LOWER('Data Engineer'));


-- Frontend Developer 
INSERT INTO job_offer (employer_id, recruiter_id, location_id, job_title,
employment_type, salary, status)
SELECT e.employer_id, r.recruiter_id, l.location_id,
    'Frontend Developer',
    'Part_time',
    9000.00,
    'Open'
FROM employer e
JOIN recruiter    r ON LOWER(r.email) = LOWER('vic.alp@gmail.com')
JOIN job_location l ON LOWER(l.city) = LOWER('Istanbul')
WHERE LOWER(e.company_name) = LOWER('Turkish Technologies')
AND NOT EXISTS (SELECT 1
FROM job_offer jo
WHERE jo.employer_id = e.employer_id
AND LOWER(jo.job_title) = LOWER('Frontend Developer'));

SELECT *
FROM Job_offer;

-- Required skills for Data Engineer @ Foo, Kyiv
INSERT INTO job_skill (job_id, skill_id, requirement_type)
SELECT jo.job_id, s.skill_id,
    'Required'
FROM job_offer jo
JOIN employer e   ON e.employer_id = jo.employer_id
JOIN skill    s   ON LOWER(s.skill_name) = LOWER('Leadership')
WHERE LOWER(jo.job_title) = LOWER('Data Engineer')
AND LOWER(e.company_name) = LOWER('Foo')
ON CONFLICT (job_id, skill_id) DO NOTHING;


INSERT INTO job_skill (job_id, skill_id, requirement_type)
SELECT jo.job_id, s.skill_id, 'Required'
FROM job_offer jo
JOIN employer e   ON e.employer_id = jo.employer_id
JOIN skill    s   ON LOWER(s.skill_name) = LOWER('Qlick')
WHERE LOWER(jo.job_title) = LOWER('Data Engineer')
  AND LOWER(e.company_name) = LOWER('Foo')
ON CONFLICT (job_id, skill_id) DO NOTHING;



-- Required skills for Frontend Developer @ Turkish Technologies, Istanbul
INSERT INTO job_skill (job_id, skill_id, requirement_type)
SELECT jo.job_id, s.skill_id, 'Required'
FROM job_offer jo
JOIN employer e   ON e.employer_id = jo.employer_id
JOIN skill    s   ON LOWER(s.skill_name) = LOWER('Python')
WHERE LOWER(jo.job_title) = LOWER('Frontend Developer')
  AND LOWER(e.company_name) = LOWER('Turkish Technologies')
ON CONFLICT (job_id, skill_id) DO NOTHING;


INSERT INTO job_skill (job_id, skill_id, requirement_type)
SELECT jo.job_id, s.skill_id, 'Prefered'
FROM job_offer jo
JOIN employer e   ON e.employer_id = jo.employer_id
JOIN skill    s   ON LOWER(s.skill_name) = LOWER('Qlick')
WHERE LOWER(jo.job_title) = LOWER('Frontend Developer')
  AND LOWER(e.company_name) = LOWER('Turkish Technologies')
ON CONFLICT (job_id, skill_id) DO NOTHING;

SELECT *
FROM job_skill;


INSERT INTO application (candidate_id, job_id, applied_at, status)
SELECT c.candidate_id, j.job_id, DATE '2023-03-09', 'Submitted'
FROM candidate c
JOIN job_offer j ON 1 = 1
JOIN employer  e ON e.employer_id = j.employer_id
WHERE LOWER(c.email)        = LOWER('iryna.kutyk777@gmail.com')
AND LOWER(j.job_title)    = LOWER('Data Engineer')
AND LOWER(e.company_name) = LOWER('Foo')
ON CONFLICT (candidate_id, job_id) DO NOTHING;




INSERT INTO application (candidate_id, job_id, applied_at, status)
SELECT c.candidate_id, j.job_id, DATE '2024-01-07', 'Pending'
FROM candidate c
JOIN job_offer j ON 1 = 1
JOIN employer  e ON e.employer_id = j.employer_id
WHERE LOWER(c.email)        = LOWER('zibrov.pav07@gmail.com')
  AND LOWER(j.job_title)    = LOWER('Business Analyst')
  AND LOWER(e.company_name) = LOWER('Sabanci Holding')
ON CONFLICT (candidate_id, job_id) DO NOTHING;

SELECT*
FROM application;


INSERT INTO application_stage (application_id, stage_name, stage_status, updated_at)
SELECT a.application_id, 'CV Review', 'Completed', TIMESTAMP '2024-01-05'
FROM application a
JOIN candidate  c ON c.candidate_id = a.candidate_id
JOIN job_offer  j ON j.job_id       = a.job_id
JOIN employer   e ON e.employer_id  = j.employer_id
WHERE LOWER(c.email)        = LOWER('iryna.kutyk777@gmail.com')
AND LOWER(j.job_title)    = LOWER('Data Engineer')
AND LOWER(e.company_name) = LOWER('Foo')
ON CONFLICT (application_id, stage_name) DO NOTHING;


INSERT INTO application_stage (application_id, stage_name, stage_status, updated_at)
SELECT a.application_id, 'Technical Interview', 'Pending', TIMESTAMP '2024-01-07'
FROM application a
JOIN candidate  c ON c.candidate_id = a.candidate_id
JOIN job_offer  j ON j.job_id       = a.job_id
JOIN employer   e ON e.employer_id  = j.employer_id
WHERE LOWER(c.email)        = LOWER('iryna.kutyk777@gmail.com')
AND LOWER(j.job_title)    = LOWER('Data Engineer')
AND LOWER(e.company_name) = LOWER('Foo')
ON CONFLICT (application_id, stage_name) DO NOTHING;



---for Pavlo:
INSERT INTO application_stage (application_id, stage_name, stage_status, updated_at)
SELECT a.application_id, 'CV Review', 'Completed', TIMESTAMP '2024-01-08'
FROM application a
JOIN candidate  c ON c.candidate_id = a.candidate_id
JOIN job_offer  j ON j.job_id       = a.job_id
JOIN employer   e ON e.employer_id  = j.employer_id
WHERE LOWER(c.email)        = LOWER('zibrov.pav07@gmail.com')
AND LOWER(j.job_title)    = LOWER('Business Analyst')
AND LOWER(e.company_name) = LOWER('Sabanci Holding')
ON CONFLICT (application_id, stage_name) DO NOTHING;

---for Iryna:
INSERT INTO application_stage (application_id, stage_name, stage_status, updated_at)
SELECT a.application_id, 'HR Interview', 'Pending', TIMESTAMP '2024-01-10'
FROM application a
JOIN candidate  c ON c.candidate_id = a.candidate_id
JOIN job_offer  j ON j.job_id       = a.job_id
JOIN employer   e ON e.employer_id  = j.employer_id
WHERE LOWER(c.email)        = LOWER('zibrov.pav07@gmail.com')
AND LOWER(j.job_title)    = LOWER('Business Analyst')
AND LOWER(e.company_name) = LOWER('Sabanci Holding')
ON CONFLICT (application_id, stage_name) DO NOTHING;

SELECT*
FROM application_stage;


--Technical interview for Iryna (Data Engineer @ Foo)
INSERT INTO interview (application_id, interviewer_name, interview_date,
interview_type, result)
SELECT a.application_id,
    'Elena Petrova',
    TIMESTAMP '2024-01-15 13:00',
    'Technical',
    'Passed'
FROM application a
JOIN candidate  c ON c.candidate_id = a.candidate_id
JOIN job_offer  j ON j.job_id       = a.job_id
JOIN employer   e ON e.employer_id  = j.employer_id
WHERE LOWER(c.email)        = LOWER('iryna.kutyk777@gmail.com')
AND LOWER(j.job_title)    = LOWER('Data Engineer')
AND LOWER(e.company_name) = LOWER('Foo')
AND NOT EXISTS (SELECT 1 FROM interview i
WHERE i.application_id = a.application_id
AND LOWER(i.interview_type) = LOWER('Technical'));


-- HR interview for Pavlo (Business Analyst @ Sabanci Holding)
INSERT INTO interview (application_id, interviewer_name, interview_date,
interview_type, result)
SELECT a.application_id,
    'Ryan Gosling',
    TIMESTAMP '2024-01-20 15:00',
    'HR',
    'Passed'
FROM application a
JOIN candidate  c ON c.candidate_id = a.candidate_id
JOIN job_offer  j ON j.job_id       = a.job_id
JOIN employer   e ON e.employer_id  = j.employer_id
WHERE LOWER(c.email)        = LOWER('zibrov.pav07@gmail.com')
AND LOWER(j.job_title)    = LOWER('Business Analyst')
AND LOWER(e.company_name) = LOWER('Sabanci Holding')
AND NOT EXISTS (SELECT 1
FROM interview i
WHERE i.application_id = a.application_id
AND LOWER(i.interview_type) = LOWER('HR'));

SELECT*
FROM application;

---Technical interview for Iryna (Data Engineer @ Foo)
INSERT INTO interview (application_id, interviewer_name,interview_date,
interview_type,result)
SELECT a.application_id,
    'Elena Petrova',
    TIMESTAMP '2024-01-15 13:00',
    'Technical',
    'Passed'
FROM application a
JOIN candidate  c ON c.candidate_id = a.candidate_id
JOIN job_offer  j ON j.job_id       = a.job_id
JOIN employer   e ON e.employer_id  = j.employer_id
WHERE LOWER(c.email)        = LOWER('iryna.kutyk777@gmail.com')
AND LOWER(j.job_title)    = LOWER('Data Engineer')
AND LOWER(e.company_name) = LOWER('Foo')
AND NOT EXISTS (SELECT 1
FROM interview i
WHERE i.application_id = a.application_id
AND LOWER(i.interview_type) = LOWER('Technical'));

SELECT *
FROM interview;

INSERT INTO offer (application_id, offered_salary, start_date, offer_status)
SELECT a.application_id,
    7500.00,
    DATE '2024-02-01',
    'Accepted'
FROM application a
JOIN candidate  c ON c.candidate_id = a.candidate_id
JOIN job_offer  j ON j.job_id       = a.job_id
JOIN employer   e ON e.employer_id  = j.employer_id
WHERE LOWER(c.email)        = LOWER('iryna.kutyk777@gmail.com')
AND LOWER(j.job_title)    = LOWER('Data Engineer')
AND LOWER(e.company_name) = LOWER('Foo')
ON CONFLICT (application_id) DO NOTHING;


-- Offer for Pavlo (Business Analyst @ Sabanci Holding)
INSERT INTO offer (application_id, offered_salary, start_date, offer_status)
SELECT a.application_id,
    9000.00,
    DATE '2024-02-15',
    'Sent'
FROM application a
JOIN candidate  c ON c.candidate_id = a.candidate_id
JOIN job_offer  j ON j.job_id       = a.job_id
JOIN employer   e ON e.employer_id  = j.employer_id
WHERE LOWER(c.email)        = LOWER('zibrov.pav07@gmail.com')
AND LOWER(j.job_title)    = LOWER('Business Analyst')
AND LOWER(e.company_name) = LOWER('Sabanci Holding')
ON CONFLICT (application_id) DO NOTHING;

SELECT *
FROM offer;


ALTER TABLE Recruiter_performance
ADD CONSTRAINT uq_recruiter_performance
UNIQUE (recruiter_id, period_month);

-- Performance for Victoria Alper in Jan 2024
INSERT INTO recruiter_performance (recruiter_id, period_month,
total_hires, avg_time_to_fill)
SELECT 
    r.recruiter_id,
    DATE '2024-01-01',   -- month period (e.g., Jan 2024)
    3,                   -- 3 hires
    14.0                 -- avg 14 days to fill
FROM recruiter r
WHERE LOWER(r.email) = LOWER('vic.alp@gmail.com')
ON CONFLICT (recruiter_id, period_month) DO NOTHING;


-- Performance for Roman Polanski in Jan 2024
INSERT INTO recruiter_performance (recruiter_id, period_month,
total_hires, avg_time_to_fill)
SELECT r.recruiter_id,
    DATE '2024-01-01',   -- month period (Jan 2024)
    4,                   -- 4 hires
    21.0                 -- avg 21 days to fill
FROM recruiter r
WHERE LOWER(r.email) = LOWER('polanskihr@gmail.com')
ON CONFLICT (recruiter_id, period_month) DO NOTHING;

SELECT*
FROM recruiter_performance;


---ALTERATION FOR NOT NULL RECORD_TS;
SET search_path TO recrut_agency; 

ALTER TABLE candidate
ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE employer
ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE recruiter
ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE job_location
ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE job_offer
ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE skill
ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE job_skill
ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE candidate_skill
ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE application
ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE application_stage
ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE interview
ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE offer
ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE recruiter_performance
ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

--verificatıon check;
SELECT table_name, column_name, data_type, column_default
FROM information_schema.columns
WHERE column_name = 'record_ts'
ORDER BY table_name;

