use hospital_1;

CREATE TABLE patient(
    patient_id INT PRIMARY KEY AUTO_INCREMENT,
    patient_name VARCHAR(50)
);

CREATE TABLE doctor(
    doctor_id INT PRIMARY KEY AUTO_INCREMENT,
    doctor_name VARCHAR(50),
    doctor_specialization VARCHAR(50)
);
alter table doctor
add column department_id int ,
add constraint fk_department
foreign key(department_id) references department(department_id);

create table department(
department_id int primary key auto_increment,
department_name varchar(30));



CREATE TABLE appoinment(
    appoinment_id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT,
    doctor_id INT,
    date DATETIME,
    FOREIGN KEY(patient_id) REFERENCES patient(patient_id),
    FOREIGN KEY(doctor_id) REFERENCES doctor(doctor_id)
);

CREATE TABLE diagnosis(
    diagnosis_id INT PRIMARY KEY AUTO_INCREMENT,
    appoinment_id INT,
    doctor_id INT,
    description VARCHAR(200),
    FOREIGN KEY(appoinment_id) REFERENCES appoinment(appoinment_id),
    FOREIGN KEY(doctor_id) REFERENCES doctor(doctor_id)
);

CREATE TABLE treatment(
    treatment_id INT PRIMARY KEY AUTO_INCREMENT,
    diagnosis_id INT,
    treatment_type VARCHAR(20),
    FOREIGN KEY(diagnosis_id) REFERENCES diagnosis(diagnosis_id)
);

CREATE TABLE medicine(
    medicine_id INT PRIMARY KEY AUTO_INCREMENT,
    medicine_price INT,
    medicine_name VARCHAR(20)
);

CREATE TABLE prescription(
    prescription_id INT PRIMARY KEY AUTO_INCREMENT,
    treatment_id INT,
    medicine_id INT,
    quantity INT,
    frequency VARCHAR(4),
    AF_BF VARCHAR(2),
    FOREIGN KEY(treatment_id) REFERENCES treatment(treatment_id),
    FOREIGN KEY(medicine_id) REFERENCES medicine(medicine_id)
);

CREATE TABLE billing(
    billing_id INT PRIMARY KEY AUTO_INCREMENT,
    appoinment_id INT,
    total_amount INT,
    FOREIGN KEY(appoinment_id) REFERENCES appoinment(appoinment_id)
);

CREATE TABLE payment_status(
    status_id INT PRIMARY KEY AUTO_INCREMENT,
    billing_id INT,
    status VARCHAR(10),
    FOREIGN KEY(billing_id) REFERENCES billing(billing_id)
);

INSERT INTO patient (patient_name) VALUES
('Ravi Kumar'),
('Anjali Sharma'),
('Kiran Shetty');

ALTER TABLE doctor AUTO_INCREMENT = 4;

INSERT INTO doctor (doctor_name, doctor_specialization) VALUES
('Dr. Mehta', 'General Physician'),
('Dr. Rao', 'Dermatologist'),
('Dr. Iyer', 'Ophthalmologist');

INSERT INTO department (department_name) VALUES
('General Medicine'),
('Dermatology'),
('Ophthalmology');

UPDATE doctor
SET department_id = (
    SELECT department_id FROM department 
    WHERE department_name = 'General Medicine'
)
WHERE doctor_specialization = 'General Physician';

UPDATE doctor
SET department_id = (
    SELECT department_id FROM department 
    WHERE department_name = 'Dermatology'
)
WHERE doctor_specialization = 'Dermatologist';

UPDATE doctor
SET department_id = (
    SELECT department_id FROM department 
    WHERE department_name = 'Ophthalmology'
)
WHERE doctor_specialization = 'Ophthalmologist';

INSERT INTO appoinment (patient_id, doctor_id, date) VALUES
(1, 4, '2026-04-28 10:00:00'),
(2, 4, '2026-04-28 11:00:00'),
(3, 5, '2026-04-28 12:00:00');

INSERT INTO diagnosis (appoinment_id, doctor_id, description) VALUES
(1, 4, 'Fever'),
(1, 5, 'Skin Allergy'),
(1, 6, 'Eye Irritation'),
(2, 4, 'Cold and Cough'),
(3, 5, 'Acne');

INSERT INTO treatment (diagnosis_id, treatment_type) VALUES
(1, 'Medication'),
(2, 'Ointment'),
(3, 'EyeDrops'),
(4, 'Medication'),
(5, 'SkinCare');

INSERT INTO medicine (medicine_price, medicine_name) VALUES
(50, 'Paracetamol'),
(120, 'Antihistamine'),
(80, 'EyeDrops'),
(60, 'CoughSyrup'),
(150, 'AcneCream');

INSERT INTO prescription (treatment_id, medicine_id, quantity, frequency, AF_BF) VALUES
(1, 1, 10, '2xd', 'AF'),
(2, 2, 5, '1xd', 'BF'),
(3, 3, 7, '3xd', 'AF'),
(4, 4, 6, '2xd', 'AF'),
(5, 5, 4, '1xd', 'BF');

INSERT INTO billing (appoinment_id, total_amount) VALUES
(1, 500),
(2, 200),
(3, 300);

INSERT INTO payment_status (billing_id, status) VALUES
(1, 'Paid'),
(2, 'Pending'),
(3, 'Paid');

SELECT 
    p.patient_name,
    a.appoinment_id,
    a.date AS appointment_date,
    
    d1.doctor_name AS consulting_doctor,
    
    d2.doctor_name AS diagnosing_doctor,
    dg.description AS diagnosis,
    
    m.medicine_name,
    pr.quantity,
    pr.frequency,
    pr.AF_BF

FROM patient p

JOIN appoinment a 
    ON p.patient_id = a.patient_id

JOIN doctor d1 
    ON a.doctor_id = d1.doctor_id

JOIN diagnosis dg 
    ON a.appoinment_id = dg.appoinment_id

JOIN doctor d2 
    ON dg.doctor_id = d2.doctor_id

JOIN treatment t 
    ON dg.diagnosis_id = t.diagnosis_id

JOIN prescription pr 
    ON t.treatment_id = pr.treatment_id

JOIN medicine m 
    ON pr.medicine_id = m.medicine_id

ORDER BY p.patient_id, a.appoinment_id;

SELECT 
    d.doctor_id,
    d.doctor_name,
    COUNT(a.appoinment_id) AS total_consultations
FROM doctor d
JOIN appoinment a 
    ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_id, d.doctor_name
HAVING COUNT(a.appoinment_id) = (
    SELECT MAX(consult_count)
    FROM (
        SELECT COUNT(*) AS consult_count
        FROM appoinment
        GROUP BY doctor_id
    ) AS temp
);

SELECT 
    p.patient_id,
    p.patient_name,
    COUNT(ps.status_id) AS unpaid_bills
FROM patient p
JOIN appoinment a 
    ON p.patient_id = a.patient_id
JOIN billing b 
    ON a.appoinment_id = b.appoinment_id
JOIN payment_status ps 
    ON b.billing_id = ps.billing_id
WHERE ps.status = 'Pending'
GROUP BY p.patient_id, p.patient_name;

DELIMITER $$

CREATE PROCEDURE process_consultation()
BEGIN
DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
ROLLBACK;
END;

START TRANSACTION;

INSERT INTO appoinment (patient_id, doctor_id, date)
VALUES (1, 4, NOW());

SET @app_id = LAST_INSERT_ID();

INSERT INTO diagnosis (appoinment_id, doctor_id, description)
VALUES (@app_id, 4, 'Fever');
SET @diag_id = LAST_INSERT_ID();
INSERT INTO treatment (diagnosis_id, treatment_type)
VALUES (@diag_id, 'Medication');
SET @treat_id = LAST_INSERT_ID();
INSERT INTO prescription (treatment_id, medicine_id, quantity, frequency, AF_BF)
VALUES (@treat_id, 1, 10, '2xd', 'AF');
INSERT INTO billing (appoinment_id, total_amount)
VALUES (@app_id, 500);
SET @bill_id = LAST_INSERT_ID();
INSERT INTO payment_status (billing_id, status)
VALUES (@bill_id, 'Pending');
COMMIT;
END$$
DELIMITER ;

CALL process_consultation();
SELECT * FROM appoinment ORDER BY appoinment_id DESC LIMIT 1;
SELECT * FROM diagnosis ORDER BY diagnosis_id DESC LIMIT 5;
SELECT * FROM billing ORDER BY billing_id DESC LIMIT 1;
SELECT * FROM payment_status ORDER BY status_id DESC LIMIT 1;
