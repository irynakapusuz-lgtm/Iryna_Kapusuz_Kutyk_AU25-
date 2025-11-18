DROP SCHEMA IF EXISTS recrut_agency CASCADE;
CREATE SCHEMA recrut_agency; 
SET search_path to recrut_agency; ---we use it not to specify prefix schema every time;

CREATE TABLE Candidate (
candidate_id  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
first_name    VARCHAR (50) NOT NULL,
last_name     VARCHAR (50) NOT NULL,
email        VARCHAR (100) NOT NULL UNIQUE,
phone         VARCHAR (30),
degree        VARCHAR (50),
experience_years NUMERIC (3,1)
   CHECK (experience_years >= 0),   -----can not be negative;
is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE Employer (
employer_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
company_name VARCHAR (50) NOT NULL UNIQUE,
industry     VARCHAR (50),
contact_person VARCHAR (50),
contact_email  VARCHAR (100),
is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE Recruiter (
recruiter_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
first_name VARCHAR (50) NOT NULL,
last_name  VARCHAR (50) NOT NULL,
email      VARCHAR (100) NOT NULL UNIQUE,
phone      VARCHAR (30),
hired_on   DATE NOT NULL
CHECK (hired_on > DATE '2000-01-01'),    
is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE Skill (
skill_id   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
skill_name VARCHAR (50) NOT NULL UNIQUE,
category   VARCHAR (50) NOT NULL,
is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE Job_location (
location_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
city        VARCHAR(50) NOT NULL,
country     VARCHAR (50) NOT NULL,
office_address VARCHAR (100),
postal_code    VARCHAR (20),
is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE Candidate_skill( 
candidate_id INT NOT NULL,
skill_id     INT NOT NULL,
proficiency_level SMALLINT NOT NULL
CHECK (proficiency_level BETWEEN 1 AND 5),
years_with_skill NUMERIC (3,1)
CHECK (years_with_skill >= 0),
CONSTRAINT pk_candidate_skill
PRIMARY KEY (candidate_id, skill_id),

CONSTRAINT fk_candidate_skill_candidate
FOREIGN KEY (candidate_id)
REFERENCES candidate (candidate_id),

CONSTRAINT fk_candidate_skill_skill
FOREIGN KEY (skill_id)
REFERENCES skill (skill_id)
);


CREATE TABLE job_offer(
job_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
employer_id  INT NOT NULL,
recruiter_id INT NOT NULL,
location_id  INT NOT NULL,
job_title    VARCHAR (100) NOT NULL,
employment_type VARCHAR (30) NOT NULL
   CHECK (employment_type IN ('Full_time', 'Part_time')), ----specified types with restrictions
  salary  NUMERIC (6,2)
   CHECK (salary >= 0),     
status  VARCHAR (30),
CONSTRAINT fk_job_offer_employer
FOREIGN KEY (employer_id)
REFERENCES employer (employer_id),

CONSTRAINT fk_job_offer_recruiter
FOREIGN KEY (recruiter_id)
REFERENCES recruiter (recruiter_id),

CONSTRAINT fk_job_offer_location
FOREIGN KEY (location_id)
REFERENCES job_location (location_id)
 );


CREATE TABLE Job_skill (
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


CREATE TABLE application (
application_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
candidate_id INT NOT NULL,
job_id       INT NOT NULL,
applied_at DATE NOT NULL DEFAULT CURRENT_DATE
CHECK (applied_at > DATE '2000-01-01'),
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


CREATE TABLE application_stage (
stage_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
application_id INT NOT NULL,
stage_name VARCHAR (30) NOT NULL,
stage_status VARCHAR (30) NOT NULL,
updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

CONSTRAINT fk_stage_application
FOREIGN KEY (application_id)
REFERENCES application (application_id),

CONSTRAINT uq_app_stage UNIQUE (application_id, stage_name),
CONSTRAINT chk_app_stage_date
CHECK (updated_at > DATE '2000-01-01')
);


DROP TABLE IF EXISTS interview CASCADE;
CREATE TABLE Interview (
interview_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
application_id INT NOT NULL,
interviewer_name VARCHAR (100),
interview_date TIMESTAMP NOT NULL
CHECK (interview_date > '2000-01-01'),
interview_type VARCHAR (30),
result VARCHAR (30),

CONSTRAINT fk_interview_application
FOREIGN KEY (application_id)
REFERENCES application (application_id)
);
SELECT *
FROM interview;

CREATE TABLE Offer (
offer_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
application_id INT NOT NULL UNIQUE, -----only 1 offer for 1 application from 1 candidate
offered_salary NUMERIC (6,2)
CHECK (offered_salary >= 0),
start_date DATE
CHECK (start_date IS NULL or start_date > '2000-01-01'),
offer_status VARCHAR (30),

CONSTRAINT fk_offer_application
FOREIGN KEY (application_id)
REFERENCES application (application_id)
);

ALTER TABLE recruiter_perform RENAME TO recruiter_perform_old;
CREATE TABLE Recruiter_perform (
perform_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
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

ALTER TABLE recruiter_perform
ADD CONSTRAINT uq_recruiter_perform
UNIQUE (recruiter_id, period_month);

INSERT INTO Candidate (first_name, last_name, email, phone, degree, experience_years, is_active)
VALUES 
       ('Iryna', 'Kutyk', 'iryna.kutyk777@gmail.com', '+905317960776', 'Data Analysis', 2.0, TRUE),
       ('Oksana', 'Sidorenko', 'sidorenko.oks@gmail.com', '+905312457894',' Data Engineering', 4.0, TRUE),
	   ('Pavlo', 'Zibrov', 'zibrov.pav07@gmail.com', '+380967546385', 'Computer systems', 7.0, TRUE)
ON CONFLICT (email) DO NOTHING;
 -----verification check;
 SELECT *
 FROM Candidate

 INSERT INTO Employer (company_name, industry, contact_person, contact_email, is_active)
 VALUES ('Sabanci Holding', 'Powerplant systems', 'Ivan Ivanov', 'ivanov03@gmail.com', TRUE),
        ('Foo', 'FinTech', 'Ghady Rayes', 'rayesceo@gmail.com', TRUE),
		('Turkish Techologies', 'Information systems', 'Ozkan Bey', 'cfo@gmail.com', TRUE)
ON CONFLICT (company_name) DO NOTHING;

-----verification check;
 SELECT *
 FROM Employer


INSERT INTO recruiter(first_name, last_name, email, phone, hired_on, is_active)
VALUES ('Victoria', 'Alper', 'vic.alp@gmail.com', '+905342538956', DATE '2020-05-20', TRUE),
       ( 'Roman', 'Polanski', 'polanskihr@gmail.com', '+905318764567', DATE '2023-03-27', TRUE)
ON CONFLICT (email) DO NOTHING;

-----verification check;
 SELECT *
 FROM recruiter

INSERT INTO Skill (skill_name, category,is_active)
VALUES ('Python',  'Technical', TRUE),
       ('Qlick' ,  'Technical', TRUE),
	   ('Team work', 'Soft', TRUE),
	   ('Leadership', 'Soft', TRUE)
ON CONFLICT (skill_name) DO NOTHING;

-----verification check;
 SELECT *
 FROM skill

INSERT INTO Job_location (city, country, office_address, postal_code, is_active)
SELECT 'Odesa' , 'Ukraine', 'Heroiv Dnipra 5' , '65025', TRUE
WHERE NOT EXISTS (
SELECT 1 FROM job_location
WHERE city = 'Odesa' AND office_address = 'Heroiv Dnipra 5'
);

INSERT INTO Job_location (city, country, office_address, postal_code, is_active)
SELECT 'Kyiv' , 'Ukraine', 'Chreschatyk 77' , '71345', TRUE
WHERE NOT EXISTS (
SELECT 1 FROM job_location
WHERE city = 'Kyiv' AND office_address = 'Chreschatyk 77'
);

INSERT INTO Job_location (city, country, office_address, postal_code, is_active)
SELECT 'İstanbul' , 'Turkiye', 'Maslak sok, 34' , '34485', TRUE
WHERE NOT EXISTS (
SELECT 1 FROM job_location
WHERE city = 'Istanbul' AND office_address = 'Maslak sok, 34'
);


 -----verification check;
 SELECT *
 FROM job_location

INSERT INTO candidate_skill (candidate_id, skill_id, proficiency_level, years_with_skill)
SELECT c.candidate_id,
s.skill_id,
2,
2.0
FROM candidate c
JOIN skill s ON s.skill_name = 'Qlick'
WHERE c.email = 'iryna.kutyk777@gmail.com'
ON CONFLICT (candidate_id,skill_id) DO NOTHING;

INSERT INTO candidate_skill (candidate_id, skill_id, proficiency_level, years_with_skill)
SELECT c.candidate_id,
s.skill_id,
5,
4.0
FROM candidate c
JOIN skill s ON s.skill_name = 'Python'
WHERE c.email = 'sidorenko.oks@gmail.com'
ON CONFLICT (candidate_id,skill_id) DO NOTHING;

INSERT INTO candidate_skill (candidate_id, skill_id, proficiency_level, years_with_skill)
SELECT c.candidate_id,
s.skill_id,
3,
3.0
FROM candidate c
JOIN skill s ON s.skill_name = 'Leadership'
WHERE c.email = 'zibrov.pav07@gmail.com'
ON CONFLICT (candidate_id,skill_id) DO NOTHING;

-----verification check;
 SELECT c. first_name,
        s.skill_name,
		cs.proficiency_level,
		cs.years_with_skill
 FROM candidate_skill cs
 JOIN candidate c ON cs.candidate_id = c.candidate_id
 JOIN skill s ON cs.skill_id = s.skill_id;
 
INSERT INTO job_offer (employer_id, recruiter_id, location_id, job_title,
employment_type, salary, status)
SELECT e.employer_id, r.recruiter_id, location_id, 'Business Analyst', 
'Full_time', 7000.00, 'Open'
FROM employer e
JOIN recruiter r ON r.email = 'vic.alp@gmail.com'
JOIN job_location l ON l.city = 'Odesa'
WHERE e.company_name = 'Sabanci Holding'
AND NOT EXISTS (
SELECT 1 FROM job_offer jo
WHERE jo.job_title = 'Business Analyst'
AND jo.employer_id = e.employer_id
);


INSERT INTO job_offer (employer_id, recruiter_id, location_id, job_title,
employment_type, salary, status)
SELECT e.employer_id, r.recruiter_id, location_id, 'Data Engineer', 
'Part_time', 5000.00, 'Open'
FROM employer e
JOIN recruiter r ON r.email = 'vic.alp@gmail.com'
JOIN job_location l ON l.city = 'Kyiv'
WHERE e.company_name = 'Foo'
AND NOT EXISTS (
SELECT 1 FROM job_offer jo
WHERE jo.job_title = 'Data Engineer'
AND jo.employer_id = e.employer_id
);

INSERT INTO job_offer (employer_id, recruiter_id, location_id, job_title,
employment_type, salary, status)
SELECT e.employer_id, r.recruiter_id, location_id, 'Frontend Developer', 
'Part_time', 9000.00, 'Open'
FROM employer e
JOIN recruiter r ON r.email = 'vic.alp@gmail.com'
JOIN job_location l ON l.city = 'Istanbul'
WHERE e.company_name = 'Turkish Techologies'
AND NOT EXISTS (
SELECT 1 FROM job_offer jo
WHERE jo.job_title = 'Frontend Developer'
AND jo.employer_id = e.employer_id
);


INSERT INTO job_skill (job_id,skill_id, requirement_type)
VALUES (2,4, 'Required') ON CONFLICT DO NOTHING;

INSERT INTO job_skill (job_id,skill_id, requirement_type)
VALUES (2,2, 'Required') ON CONFLICT DO NOTHING;
SET search_path TO recrut_agency;

INSERT INTO job_skill (job_id,skill_id, requirement_type)
VALUES (3,1, 'Required') ON CONFLICT DO NOTHING;

INSERT INTO job_skill (job_id,skill_id, requirement_type)
VALUES (3,2, 'Required') ON CONFLICT DO NOTHING;

-----verification check;

SELECT jo.job_title, s.skill_name, js.requirement_type
FROM job_skill js
JOIN job_offer jo ON js.job_id = jo.job_id
JOIN skill s      ON js.skill_id = s.skill_id;

INSERT INTO application (candidate_id, job_id, applied_at, status)
VALUES (3,2, '2023-03-09', 'Submitted');
SELECT * FROM application ORDER BY application_id;

INSERT INTO application (candidate_id, job_id, applied_at, status)
VALUES (1,3, '2024-01-07', 'Pending');



-----verification check;
SELECT *
FROM application;





INSERT INTO application_stage (application_id, stage_name, stage_status, updated_at)
VALUES (2,'CV Review', 'Completed', '2024-01-08'),
       (2,'HR Interview', 'Pending', '2024-01-10')
	   ON CONFLICT(application_id, stage_name) DO NOTHING;

INSERT INTO application_stage (application_id, stage_name, stage_status, updated_at)
VALUES (1,'CV Review', 'Completed', '2024-01-05'),
       (1,'Technical Interview', 'Pending', '2024-01-07')
	   ON CONFLICT(application_id, stage_name) DO NOTHING;

----verification checking;
SELECT application_id, stage_name, stage_status
FROM application_stage
ORDER BY application_id, stage_name;


INSERT INTO interview (
application_id,
interviewer_name,
interview_date,
interview_type,
result)
SELECT a.application_id,
'Elena Petrova',
TIMESTAMP '2024-01-15 13:00',
'Technical',
'Passed'
FROM application a 
JOIN candidate c ON c.candidate_id = a.candidate_id
JOIN job_offer j ON j.job_id = a.job_id
WHERE c.email = 'iryna.kutyk777@gmail.com'
AND j.job_title = 'Data Engineer'
AND NOT EXISTS (
SELECT 1
FROM interview i
WHERE i.application_id = a.application_id
AND i.interview_type = 'Technical'
);



INSERT INTO interview (
application_id,
interviewer_name,
interview_date,
interview_type,
result)
SELECT a.application_id,
'Rayan Gosling',
TIMESTAMP '2024-01-20 15:00',
'HR',
'Passed'
FROM application a 
JOIN candidate c ON c.candidate_id = a.candidate_id
JOIN job_offer j ON j.job_id = a.job_id
WHERE c.email = 'zibrov.pav07@gmail.com'
AND j.job_title = 'Business Analyst'
AND NOT EXISTS (
SELECT 1
FROM interview i
WHERE i.application_id = a.application_id
AND i.interview_type = 'HR'
);



----verification checking;
SELECT i.interview_id, c.first_name, j.job_title,
i.interview_type,i.result
FROM interview i
JOIN application a on a.application_id = i.application_id
JOIN candidate c ON c.candidate_id = a.candidate_id
JOIN job_offer j ON j.job_id   = a.job_id
ORDER BY i.interview_id;


INSERT INTO offer (application_id, offered_salary, start_date, offer_status)
SELECT a.application_id,
7500.00,               
DATE '2024-02-01',            -----start date
'Accepted'
FROM application a 
JOIN candidate c ON c.candidate_id = a.candidate_id
JOIN job_offer j ON j.job_id = a.job_id
WHERE c.email = 'iryna.kutyk777@gmail.com'
AND j.job_title = 'Data Engineer'
AND NOT EXISTS (
SELECT 1
FROM offer o
WHERE o.application_id = a.application_id
);


INSERT INTO offer (application_id, offered_salary, start_date, offer_status)
SELECT a.application_id,
9000.00,               
DATE '2024-02-015',            -----start date
'Sent'
FROM application a 
JOIN candidate c ON c.candidate_id = a.candidate_id
JOIN job_offer j ON j.job_id = a.job_id
WHERE c.email = 'zibrov.pav07@gmail.com'
AND j.job_title = 'Business Analyst'
AND NOT EXISTS (
SELECT 1
FROM offer o
WHERE o.application_id = a.application_id
);

----verification checking;
SELECT o.offer_id, c.first_name, j.job_title,
o.offered_salary, o.start_date, o.offer_status
FROM offer o
JOIN application a on a.application_id = o.application_id
JOIN candidate c ON c.candidate_id = a.candidate_id
JOIN job_offer j ON j.job_id   = a.job_id
ORDER BY o.offer_id;
 
INSERT INTO recruiter_perform (recruiter_id, period_month,total_hires, avg_time_to_fill)
SELECT r.recruiter_id, 
DATE '2024-01-01',
3,                    ----3 hired vacancies this month;
14                       ----- avg days to fill;
FROM recruiter r
WHERE r.email = 'vic.alp@gmail.com'
ON CONFLICT (recruiter_id, period_month) DO NOTHING;

INSERT INTO recruiter_perform (recruiter_id, period_month,total_hires, avg_time_to_fill)
SELECT r.recruiter_id, 
DATE '2024-01-01',
4,                    ----3 hired vacancies this month;
21                       ----- avg days to fill;
FROM recruiter r
WHERE r.email = 'polanskihr@gmail.com'
ON CONFLICT (recruiter_id, period_month) DO NOTHING;

SELECT rp.perform_id,
       r.first_name || ' ' || r.last_name AS recruiter_name,
       rp.period_month,
       rp.total_hires,
       rp.avg_time_to_fill
FROM recruiter_perform rp
JOIN recruiter r 
    ON r.recruiter_id = rp.recruiter_id
ORDER BY rp.perform_id;



----ALTERATION FOR NOT NULL RECORD_TS;
SET search_path to recrut_agency;
ALTER TABLE candidate
ADD COLUMN record_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL;

ALTER TABLE employer
ADD COLUMN record_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL;

ALTER TABLE recruiter
ADD COLUMN record_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL;

ALTER TABLE job_location
ADD COLUMN record_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL;

ALTER TABLE job_offer
ADD COLUMN record_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL;

ALTER TABLE skill
ADD COLUMN record_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL;

ALTER TABLE job_skill
ADD COLUMN record_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL;

ALTER TABLE candidate_skill
ADD COLUMN record_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL;

ALTER TABLE application
ADD COLUMN record_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL;

ALTER TABLE application_stage
ADD COLUMN record_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL;

ALTER TABLE interview
ADD COLUMN record_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL;

ALTER TABLE offer
ADD COLUMN record_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL;

ALTER TABLE recruiter_perform
ADD COLUMN record_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL;


---verificatıon check;
SELECT table_name, column_name, data_type, column_default
FROM information_schema.columns
WHERE column_name = 'record_ts'
ORDER BY table_name;




