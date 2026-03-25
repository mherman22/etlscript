USE isanteplus;

/* Reference tables for surveillance indicators */

DROP TABLE IF EXISTS isanteplus.report_type;
CREATE TABLE IF NOT EXISTS isanteplus.report_type (
  report_type_id INT(11),
  report_type_name_fr text NOT NULL,
  report_type_name_en text NOT NULL,
  report_type_description text NOT NULL,
  created_date datetime NOT NULL,
  CONSTRAINT pk_report_type PRIMARY KEY (report_type_id)
) ENGINE=INNODB DEFAULT CHARSET=utf8;

INSERT INTO isanteplus.report_type (report_type_id,report_type_name_fr,report_type_name_en,
report_type_description,created_date)
VALUES(1,'Rapport de surveillance hebdomadaire','Weekly monitoring report',
'Rapport de surveillance hebdomadaire',now());

DROP TABLE IF EXISTS isanteplus.indicator_type;
CREATE TABLE IF NOT EXISTS isanteplus.indicator_type (
  indicator_type_id INT(11) NOT NULL,
  report_type_id INT(11) NOT NULL,
  indicator_name_fr text NOT NULL,
  indicator_name_en text NOT NULL,
  indicator_type_description text,
  date_created datetime NOT NULL,
  CONSTRAINT pk_indicator_type PRIMARY KEY (indicator_type_id,report_type_id)
) ENGINE=INNODB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS isanteplus.indicators;
CREATE TABLE IF NOT EXISTS isanteplus.indicators (
  indicator_id INT(11) NOT NULL,
  indicator_type_id INT(11) NOT NULL,
  patient_id INT(11) NOT NULL,
  location_id INT(11) NOT NULL,
  encounter_id INT(11) NOT NULL,
  indicator_date DATETIME NOT NULL,
  voided TINYINT(1) NOT NULL DEFAULT 0,
  created_date date NOT NULL,
  last_updated_date DATE NOT NULL,
  CONSTRAINT pk_indicators PRIMARY KEY (indicator_type_id,patient_id,indicator_date)
) ENGINE=INNODB DEFAULT CHARSET=utf8;

/* Indicator type reference data (1-37) */
INSERT INTO isanteplus.indicator_type VALUES(1,1,'Agression par animal suspecte de rage','Animal aggression suspected of rabies','Agression par animal suspecte de rage', now());
INSERT INTO isanteplus.indicator_type VALUES(2,1,'Coqueluche Suspect','Whooping Cough Suspect','Coqueluche Suspect', now());
INSERT INTO isanteplus.indicator_type VALUES(3,1,'Cholera Suspect','Cholera Suspect','Cholera Suspect', now());
INSERT INTO isanteplus.indicator_type VALUES(4,1,'Deces Maternel','Maternal Death','Maternal Death', now());
INSERT INTO isanteplus.indicator_type VALUES(5,1,'Diphterie probable','Probable Diphtheria','Diphterie probable', now());
INSERT INTO isanteplus.indicator_type VALUES(6,1,'ESAVI','Event attributable to vaccination and immunization (ESAVI)','ESAVI', now());
INSERT INTO isanteplus.indicator_type VALUES(7,1,'Meningite Suspect','Suspected Meningitis','Meningite Suspect', now());
INSERT INTO isanteplus.indicator_type VALUES(8,1,'Microcephalie congenitale','Congenital microcephaly','Microcephalie congenitale', now());
INSERT INTO isanteplus.indicator_type VALUES(9,1,'Paludisme confirme','Confirmed Malaria','Paludisme confirme', now());
INSERT INTO isanteplus.indicator_type VALUES(10,1,'Paralysie flasque aigue (PFA)','Acute flaccid paralysis (AFP)','Paralysie flasque aigue (PFA)', now());
INSERT INTO isanteplus.indicator_type VALUES(11,1,'Peste suspecte','Suspected Plague','Peste suspecte', now());
INSERT INTO isanteplus.indicator_type VALUES(12,1,'Rage humaine','Human rabies','Rage humaine', now());
INSERT INTO isanteplus.indicator_type VALUES(13,1,'Rougeole/rubeole suspecte','Suspected Measles/Rubella','Rougeole/rubeole suspecte', now());
INSERT INTO isanteplus.indicator_type VALUES(14,1,'Syndrome de Guillain-Barre','Guillain-Barre syndrome','Syndrome de Guillain-Barre', now());
INSERT INTO isanteplus.indicator_type VALUES(15,1,'Syndrome de fievre hemorragique aigue','Acute hemorrhagic fever syndrome','Syndrome de fievre hemorragique aigue', now());
INSERT INTO isanteplus.indicator_type VALUES(16,1,'Syndrome de rubeole congenitale','Congenital rubella syndrome','Syndrome de rubeole congenitale', now());
INSERT INTO isanteplus.indicator_type VALUES(17,1,'Tetanos neonatal (TNN)','Neonatal tetanus (NNT)','Tetanos neonatal (TNN)', now());
INSERT INTO isanteplus.indicator_type VALUES(18,1,'Toxi-infection alimentaire collective (TIAC)','Collective food poisoning (TIAC)','Toxi-infection alimentaire collective (TIAC)', now());
INSERT INTO isanteplus.indicator_type VALUES(19,1,'Charbon cutane suspect','Suspected cutaneous anthrax','Charbon cutane suspect', now());
INSERT INTO isanteplus.indicator_type VALUES(20,1,'Dengue suspecte','Suspected Dengue','Dengue suspecte', now());
INSERT INTO isanteplus.indicator_type VALUES(21,1,'Diabete','Diabetes','Diabete', now());
INSERT INTO isanteplus.indicator_type VALUES(22,1,'Diarrhee aigue aqueuse','Acute watery diarrhea','Diarrhee aigue aqueuse', now());
INSERT INTO isanteplus.indicator_type VALUES(23,1,'Diarrhee aigue sanglante','Acute bloody diarrhea','Diarrhee aigue sanglante', now());
INSERT INTO isanteplus.indicator_type VALUES(24,1,'Fievre typhoide suspecte','Suspected typhoid fever','Fievre typhoide suspecte', now());
INSERT INTO isanteplus.indicator_type VALUES(25,1,'Filariose probable','Probable filariasis','Filariose probable', now());
INSERT INTO isanteplus.indicator_type VALUES(26,1,'Infection respiratoire aigue','Acute respiratory infection','Infection respiratoire aigue', now());
INSERT INTO isanteplus.indicator_type VALUES(27,1,'Syndrome icterique febrile','Febrile jaundice syndrome','Syndrome icterique febrile', now());
INSERT INTO isanteplus.indicator_type VALUES(28,1,'Tetanos','Tetanus','Tetanos', now());
INSERT INTO isanteplus.indicator_type VALUES(29,1,'Accidents (domestiques, voie publique)','Accidents (domestic, public roads)','Accidents (domestiques, voie publique)', now());
INSERT INTO isanteplus.indicator_type VALUES(30,1,'Cancers (seins, col uterus, prostate, autres)','Cancers (breast, cervical, prostate, other)','Cancers', now());
INSERT INTO isanteplus.indicator_type VALUES(31,1,'Epilepsie','Epilepsy','Epilepsie', now());
INSERT INTO isanteplus.indicator_type VALUES(32,1,'Hypertension arterielle (HTA)','High blood pressure (HTN)','Hypertension arterielle (HTA)', now());
INSERT INTO isanteplus.indicator_type VALUES(33,1,'Infection sexuellement transmissible (IST)','Sexually transmitted infection (STI)','Infection sexuellement transmissible (IST)', now());
INSERT INTO isanteplus.indicator_type VALUES(34,1,'Lepre suspecte','Suspected leprosy','Lepre suspecte', now());
INSERT INTO isanteplus.indicator_type VALUES(35,1,'Malnutrition','Malnutrition','Malnutrition', now());
INSERT INTO isanteplus.indicator_type VALUES(36,1,'Syphilis congenitale','Congenital syphilis','Syphilis congenitale', now());
INSERT INTO isanteplus.indicator_type VALUES(37,1,'Violences (physique, sexuelle)','Violence (physical, sexual)','Violences (physique, sexuelle)', now());


/*==========================================================================
  Snapshot openmrs tables for patient_diagnosis procedure
==========================================================================*/

SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET SQL_SAFE_UPDATES = 0;

/* Snapshot: openmrs.obs (only concepts needed for diagnosis) */
DROP TEMPORARY TABLE IF EXISTS _tmp_obs;
CREATE TEMPORARY TABLE _tmp_obs (
  obs_id int(11),
  person_id int(11),
  concept_id int(11),
  encounter_id int(11),
  location_id int(11),
  obs_group_id int(11),
  value_coded int(11),
  voided tinyint(1),
  PRIMARY KEY (obs_id),
  INDEX idx_person (person_id),
  INDEX idx_encounter (encounter_id),
  INDEX idx_concept (concept_id),
  INDEX idx_obs_group (obs_group_id)
) ENGINE=InnoDB;

INSERT INTO _tmp_obs
SELECT obs_id, person_id, concept_id, encounter_id, location_id, obs_group_id, value_coded, voided
FROM openmrs.obs
WHERE voided <> 1
  AND concept_id IN (1284, 159394, 159946);

/* Duplicate for self-join (MySQL 5.6/5.7) */
DROP TEMPORARY TABLE IF EXISTS _tmp_obs_2;
CREATE TEMPORARY TABLE _tmp_obs_2 LIKE _tmp_obs;
INSERT INTO _tmp_obs_2 SELECT * FROM _tmp_obs;

/* Snapshot: openmrs.encounter */
DROP TEMPORARY TABLE IF EXISTS _tmp_encounter;
CREATE TEMPORARY TABLE _tmp_encounter (
  encounter_id int(11),
  encounter_type int(11),
  patient_id int(11),
  location_id int(11),
  encounter_datetime datetime,
  voided tinyint(1),
  PRIMARY KEY (encounter_id),
  INDEX idx_type (encounter_type)
) ENGINE=InnoDB;

INSERT INTO _tmp_encounter
SELECT encounter_id, encounter_type, patient_id, location_id, encounter_datetime, voided
FROM openmrs.encounter
WHERE voided <> 1;

/* Snapshot: openmrs.encounter_type */
DROP TEMPORARY TABLE IF EXISTS _tmp_encounter_type;
CREATE TEMPORARY TABLE _tmp_encounter_type (
  encounter_type_id int(11),
  uuid char(38),
  PRIMARY KEY (encounter_type_id),
  INDEX idx_uuid (uuid)
) ENGINE=MEMORY;

INSERT INTO _tmp_encounter_type
SELECT encounter_type_id, uuid FROM openmrs.encounter_type;

/* Snapshot: openmrs.concept (small, MEMORY) */
DROP TEMPORARY TABLE IF EXISTS _tmp_concept;
CREATE TEMPORARY TABLE _tmp_concept (
  concept_id int(11),
  uuid char(38),
  PRIMARY KEY (concept_id),
  INDEX idx_uuid (uuid)
) ENGINE=MEMORY;

INSERT INTO _tmp_concept
SELECT concept_id, uuid FROM openmrs.concept;

SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
COMMIT;


/*==========================================================================
  Patient diagnosis (uses snapshots)
==========================================================================*/

INSERT INTO patient_diagnosis
(patient_id, encounter_id, location_id, concept_group, obs_group_id, concept_id, answer_concept_id, voided)
SELECT DISTINCT ob.person_id, ob.encounter_id, ob.location_id, ob1.concept_id,
  ob.obs_group_id, ob.concept_id, ob.value_coded, ob.voided
FROM _tmp_obs ob
INNER JOIN _tmp_obs_2 ob1 ON ob.person_id = ob1.person_id
  AND ob.encounter_id = ob1.encounter_id AND ob.obs_group_id = ob1.obs_id
INNER JOIN _tmp_encounter e ON ob.encounter_id = e.encounter_id
INNER JOIN _tmp_encounter_type et ON e.encounter_type = et.encounter_type_id
WHERE ob.concept_id = 1284
  AND (ob.value_coded <> '' OR ob.value_coded IS NOT NULL)
  AND et.uuid IN (
    '5c312603-25c1-4dbe-be18-1a167eb85f97',
    '49592bec-dd22-4b6c-a97f-4dd2af6f2171',
    '12f4d7c3-e047-4455-a607-47a40fe32460',
    'a5600919-4dde-4eb8-a45b-05c204af8284',
    '709610ff-5e39-4a47-9c27-a60e740b0944',
    'fdb5b14f-555f-4282-b4c1-9286addf0aae'
  )
ON DUPLICATE KEY UPDATE
  encounter_id = ob.encounter_id,
  voided = ob.voided;

/* Update suspected_confirmed */
UPDATE patient_diagnosis pdiag
INNER JOIN _tmp_obs ob ON pdiag.patient_id = ob.person_id
  AND pdiag.obs_group_id = ob.obs_group_id
  AND pdiag.encounter_id = ob.encounter_id
SET pdiag.suspected_confirmed = ob.value_coded
WHERE ob.concept_id = 159394
  AND ob.value_coded IN (159392, 159393)
  AND ob.voided = 0;

/* Update primary_secondary */
UPDATE patient_diagnosis pdiag
INNER JOIN _tmp_obs_2 ob ON pdiag.patient_id = ob.person_id
  AND pdiag.obs_group_id = ob.obs_group_id
  AND pdiag.encounter_id = ob.encounter_id
SET pdiag.primary_secondary = ob.value_coded
WHERE ob.concept_id = 159946
  AND ob.value_coded IN (159943, 159944)
  AND ob.voided = 0;

/* Update encounter_date */
UPDATE patient_diagnosis pdiag
INNER JOIN _tmp_encounter enc ON pdiag.location_id = enc.location_id
  AND pdiag.encounter_id = enc.encounter_id
SET pdiag.encounter_date = DATE(enc.encounter_datetime)
WHERE enc.voided = 0;


/*==========================================================================
  Report indicators (reads from isanteplus tables, minimal openmrs access)
  openmrs.concept lookups replaced with _tmp_concept snapshot
==========================================================================*/

/* 1: Animal aggression suspected of rabies */
INSERT INTO isanteplus.indicators (indicator_id,indicator_type_id,patient_id,location_id,encounter_id,indicator_date,voided,created_date,last_updated_date)
SELECT 1,1,pdiag.patient_id, pdiag.location_id, pdiag.encounter_id, pdiag.encounter_date, pdiag.voided, now(), now()
FROM isanteplus.patient p INNER JOIN isanteplus.patient_diagnosis pdiag ON p.patient_id = pdiag.patient_id
WHERE pdiag.concept_id = 1284 AND pdiag.answer_concept_id = 160146 AND pdiag.suspected_confirmed = 159393 AND pdiag.voided <> 1
ON DUPLICATE KEY UPDATE last_updated_date = NOW(), voided = pdiag.voided;

/* 2: Whooping Cough Suspect */
INSERT INTO isanteplus.indicators (indicator_id,indicator_type_id,patient_id,location_id,encounter_id,indicator_date,voided,created_date,last_updated_date)
SELECT 2,2,pdiag.patient_id, pdiag.location_id, pdiag.encounter_id, pdiag.encounter_date, pdiag.voided, now(), now()
FROM isanteplus.patient p INNER JOIN isanteplus.patient_diagnosis pdiag ON p.patient_id = pdiag.patient_id
WHERE pdiag.concept_id = 1284 AND pdiag.answer_concept_id = 114190 AND pdiag.suspected_confirmed = 159393 AND pdiag.voided <> 1
ON DUPLICATE KEY UPDATE last_updated_date = NOW(), voided = pdiag.voided;

/* 3: Cholera Suspect */
INSERT INTO isanteplus.indicators (indicator_id,indicator_type_id,patient_id,location_id,encounter_id,indicator_date,voided,created_date,last_updated_date)
SELECT 3,3,pdiag.patient_id, pdiag.location_id, pdiag.encounter_id, pdiag.encounter_date, pdiag.voided, now(), now()
FROM isanteplus.patient p INNER JOIN isanteplus.patient_diagnosis pdiag ON p.patient_id = pdiag.patient_id
WHERE pdiag.concept_id = 1284 AND pdiag.answer_concept_id = 122604 AND pdiag.suspected_confirmed = 159393 AND pdiag.voided <> 1
ON DUPLICATE KEY UPDATE last_updated_date = NOW(), voided = pdiag.voided;

/* 4: Maternal Death */
INSERT INTO isanteplus.indicators (indicator_id,indicator_type_id,patient_id,location_id,encounter_id,indicator_date,voided,created_date,last_updated_date)
SELECT 4,4,pdiag.patient_id, pdiag.location_id, pdiag.encounter_id, pdiag.encounter_date, pdiag.voided, now(), now()
FROM isanteplus.patient p INNER JOIN isanteplus.patient_diagnosis pdiag ON p.patient_id = pdiag.patient_id
WHERE pdiag.concept_id = 1284 AND pdiag.answer_concept_id = 134612 AND pdiag.voided <> 1
ON DUPLICATE KEY UPDATE last_updated_date = NOW(), voided = pdiag.voided;

/* 5: Probable Diphtheria */
INSERT INTO isanteplus.indicators (indicator_id,indicator_type_id,patient_id,location_id,encounter_id,indicator_date,voided,created_date,last_updated_date)
SELECT 5,5,pdiag.patient_id, pdiag.location_id, pdiag.encounter_id, pdiag.encounter_date, pdiag.voided, now(), now()
FROM isanteplus.patient p INNER JOIN isanteplus.patient_diagnosis pdiag ON p.patient_id = pdiag.patient_id
WHERE pdiag.concept_id = 1284 AND pdiag.answer_concept_id = 119399 AND pdiag.suspected_confirmed = 159393 AND pdiag.voided <> 1
ON DUPLICATE KEY UPDATE last_updated_date = NOW(), voided = pdiag.voided;

/* 6: ESAVI (concept by UUID) */
INSERT INTO isanteplus.indicators (indicator_id,indicator_type_id,patient_id,location_id,encounter_id,indicator_date,voided,created_date,last_updated_date)
SELECT 6,6,pdiag.patient_id, pdiag.location_id, pdiag.encounter_id, pdiag.encounter_date, pdiag.voided, now(), now()
FROM isanteplus.patient p
INNER JOIN isanteplus.patient_diagnosis pdiag ON p.patient_id = pdiag.patient_id
INNER JOIN _tmp_concept c ON pdiag.answer_concept_id = c.concept_id
WHERE pdiag.concept_id = 1284 AND c.uuid = '1b4d09df-4f9f-44ff-9e7b-c1eba6514289' AND pdiag.voided <> 1
ON DUPLICATE KEY UPDATE last_updated_date = NOW(), voided = pdiag.voided;

/* 7: Suspected Meningitis */
INSERT INTO isanteplus.indicators (indicator_id,indicator_type_id,patient_id,location_id,encounter_id,indicator_date,voided,created_date,last_updated_date)
SELECT 7,7,pdiag.patient_id, pdiag.location_id, pdiag.encounter_id, pdiag.encounter_date, pdiag.voided, now(), now()
FROM isanteplus.patient p INNER JOIN isanteplus.patient_diagnosis pdiag ON p.patient_id = pdiag.patient_id
WHERE pdiag.concept_id = 1284 AND pdiag.answer_concept_id = 115835 AND pdiag.suspected_confirmed = 159393 AND pdiag.voided <> 1
ON DUPLICATE KEY UPDATE last_updated_date = NOW(), voided = pdiag.voided;

/* 8: Congenital microcephaly (concept by UUID) */
INSERT INTO isanteplus.indicators (indicator_id,indicator_type_id,patient_id,location_id,encounter_id,indicator_date,voided,created_date,last_updated_date)
SELECT 8,8,pdiag.patient_id, pdiag.location_id, pdiag.encounter_id, pdiag.encounter_date, pdiag.voided, now(), now()
FROM isanteplus.patient p
INNER JOIN isanteplus.patient_diagnosis pdiag ON p.patient_id = pdiag.patient_id
INNER JOIN _tmp_concept c ON pdiag.answer_concept_id = c.concept_id
WHERE pdiag.concept_id = 1284 AND c.uuid = '87275706-5e87-4562-8cdc-b9d1e1649f83' AND pdiag.voided <> 1
ON DUPLICATE KEY UPDATE last_updated_date = NOW(), voided = pdiag.voided;

/* 9: Confirmed Malaria */
INSERT INTO isanteplus.indicators (indicator_id,indicator_type_id,patient_id,location_id,encounter_id,indicator_date,voided,created_date,last_updated_date)
SELECT 9,9,pdiag.patient_id, pdiag.location_id, pdiag.encounter_id, pdiag.encounter_date, pdiag.voided, now(), now()
FROM isanteplus.patient p INNER JOIN isanteplus.patient_diagnosis pdiag ON p.patient_id = pdiag.patient_id
WHERE pdiag.concept_id = 1284 AND pdiag.answer_concept_id = 116128 AND pdiag.suspected_confirmed = 159392 AND pdiag.voided <> 1
ON DUPLICATE KEY UPDATE last_updated_date = NOW(), voided = pdiag.voided;

/* 10: Acute flaccid paralysis */
INSERT INTO isanteplus.indicators (indicator_id,indicator_type_id,patient_id,location_id,encounter_id,indicator_date,voided,created_date,last_updated_date)
SELECT 10,10,pdiag.patient_id, pdiag.location_id, pdiag.encounter_id, pdiag.encounter_date, pdiag.voided, now(), now()
FROM isanteplus.patient p INNER JOIN isanteplus.patient_diagnosis pdiag ON p.patient_id = pdiag.patient_id
WHERE pdiag.concept_id = 1284 AND pdiag.answer_concept_id = 160426 AND pdiag.voided <> 1
ON DUPLICATE KEY UPDATE last_updated_date = NOW(), voided = pdiag.voided;

/* 11: Suspected Plague */
INSERT INTO isanteplus.indicators (indicator_id,indicator_type_id,patient_id,location_id,encounter_id,indicator_date,voided,created_date,last_updated_date)
SELECT 11,11,pdiag.patient_id, pdiag.location_id, pdiag.encounter_id, pdiag.encounter_date, pdiag.voided, now(), now()
FROM isanteplus.patient p INNER JOIN isanteplus.patient_diagnosis pdiag ON p.patient_id = pdiag.patient_id
WHERE pdiag.concept_id = 1284 AND pdiag.answer_concept_id = 114120 AND pdiag.suspected_confirmed = 159393 AND pdiag.voided <> 1
ON DUPLICATE KEY UPDATE last_updated_date = NOW(), voided = pdiag.voided;

/* 12: Human rabies */
INSERT INTO isanteplus.indicators (indicator_id,indicator_type_id,patient_id,location_id,encounter_id,indicator_date,voided,created_date,last_updated_date)
SELECT 12,12,pdiag.patient_id, pdiag.location_id, pdiag.encounter_id, pdiag.encounter_date, pdiag.voided, now(), now()
FROM isanteplus.patient p INNER JOIN isanteplus.patient_diagnosis pdiag ON p.patient_id = pdiag.patient_id
WHERE pdiag.concept_id = 1284 AND pdiag.answer_concept_id = 160146 AND pdiag.voided <> 1
ON DUPLICATE KEY UPDATE last_updated_date = NOW(), voided = pdiag.voided;

/* 13: Suspected Measles/Rubella */
INSERT INTO isanteplus.indicators (indicator_id,indicator_type_id,patient_id,location_id,encounter_id,indicator_date,voided,created_date,last_updated_date)
SELECT 13,13,pdiag.patient_id, pdiag.location_id, pdiag.encounter_id, pdiag.encounter_date, pdiag.voided, now(), now()
FROM isanteplus.patient p INNER JOIN isanteplus.patient_diagnosis pdiag ON p.patient_id = pdiag.patient_id
WHERE pdiag.concept_id = 1284 AND pdiag.answer_concept_id = 134561 AND pdiag.suspected_confirmed = 159393 AND pdiag.voided <> 1
ON DUPLICATE KEY UPDATE last_updated_date = NOW(), voided = pdiag.voided;

/* 14: Guillain-Barre syndrome */
INSERT INTO isanteplus.indicators (indicator_id,indicator_type_id,patient_id,location_id,encounter_id,indicator_date,voided,created_date,last_updated_date)
SELECT 14,14,pdiag.patient_id, pdiag.location_id, pdiag.encounter_id, pdiag.encounter_date, pdiag.voided, now(), now()
FROM isanteplus.patient p INNER JOIN isanteplus.patient_diagnosis pdiag ON p.patient_id = pdiag.patient_id
WHERE pdiag.concept_id = 1284 AND pdiag.answer_concept_id = 139233 AND pdiag.voided <> 1
ON DUPLICATE KEY UPDATE last_updated_date = NOW(), voided = pdiag.voided;

/* 15: Acute hemorrhagic fever syndrome */
INSERT INTO isanteplus.indicators (indicator_id,indicator_type_id,patient_id,location_id,encounter_id,indicator_date,voided,created_date,last_updated_date)
SELECT 15,15,pdiag.patient_id, pdiag.location_id, pdiag.encounter_id, pdiag.encounter_date, pdiag.voided, now(), now()
FROM isanteplus.patient p INNER JOIN isanteplus.patient_diagnosis pdiag ON p.patient_id = pdiag.patient_id
WHERE pdiag.concept_id = 1284 AND pdiag.answer_concept_id = 163392 AND pdiag.voided <> 1
ON DUPLICATE KEY UPDATE last_updated_date = NOW(), voided = pdiag.voided;

/* 16: Congenital rubella syndrome */
INSERT INTO isanteplus.indicators (indicator_id,indicator_type_id,patient_id,location_id,encounter_id,indicator_date,voided,created_date,last_updated_date)
SELECT 16,16,pdiag.patient_id, pdiag.location_id, pdiag.encounter_id, pdiag.encounter_date, pdiag.voided, now(), now()
FROM isanteplus.patient p INNER JOIN isanteplus.patient_diagnosis pdiag ON p.patient_id = pdiag.patient_id
WHERE pdiag.concept_id = 1284 AND pdiag.answer_concept_id = 113205 AND pdiag.voided <> 1
ON DUPLICATE KEY UPDATE last_updated_date = NOW(), voided = pdiag.voided;

/* 17: Neonatal tetanus */
INSERT INTO isanteplus.indicators (indicator_id,indicator_type_id,patient_id,location_id,encounter_id,indicator_date,voided,created_date,last_updated_date)
SELECT 17,17,pdiag.patient_id, pdiag.location_id, pdiag.encounter_id, pdiag.encounter_date, pdiag.voided, now(), now()
FROM isanteplus.patient p INNER JOIN isanteplus.patient_diagnosis pdiag ON p.patient_id = pdiag.patient_id
WHERE pdiag.concept_id = 1284 AND pdiag.answer_concept_id = 124957 AND pdiag.voided <> 1
ON DUPLICATE KEY UPDATE last_updated_date = NOW(), voided = pdiag.voided;

/* 18: Collective food poisoning (TIAC) (concept by UUID) */
INSERT INTO isanteplus.indicators (indicator_id,indicator_type_id,patient_id,location_id,encounter_id,indicator_date,voided,created_date,last_updated_date)
SELECT 18,18,pdiag.patient_id, pdiag.location_id, pdiag.encounter_id, pdiag.encounter_date, pdiag.voided, now(), now()
FROM isanteplus.patient p
INNER JOIN isanteplus.patient_diagnosis pdiag ON p.patient_id = pdiag.patient_id
INNER JOIN _tmp_concept c ON pdiag.answer_concept_id = c.concept_id
WHERE pdiag.concept_id = 1284 AND c.uuid = '50d568a4-2e65-420c-8d9c-8b63f146e2c5' AND pdiag.voided <> 1
ON DUPLICATE KEY UPDATE last_updated_date = NOW(), voided = pdiag.voided;

/* 19: Suspected cutaneous anthrax */
INSERT INTO isanteplus.indicators (indicator_id,indicator_type_id,patient_id,location_id,encounter_id,indicator_date,voided,created_date,last_updated_date)
SELECT 19,19,pdiag.patient_id, pdiag.location_id, pdiag.encounter_id, pdiag.encounter_date, pdiag.voided, now(), now()
FROM isanteplus.patient p INNER JOIN isanteplus.patient_diagnosis pdiag ON p.patient_id = pdiag.patient_id
WHERE pdiag.concept_id = 1284 AND pdiag.answer_concept_id = 121555 AND pdiag.suspected_confirmed = 159393 AND pdiag.voided <> 1
ON DUPLICATE KEY UPDATE last_updated_date = NOW(), voided = pdiag.voided;

/* 20: Suspected Dengue */
INSERT INTO isanteplus.indicators (indicator_id,indicator_type_id,patient_id,location_id,encounter_id,indicator_date,voided,created_date,last_updated_date)
SELECT 20,20,pdiag.patient_id, pdiag.location_id, pdiag.encounter_id, pdiag.encounter_date, pdiag.voided, now(), now()
FROM isanteplus.patient p INNER JOIN isanteplus.patient_diagnosis pdiag ON p.patient_id = pdiag.patient_id
WHERE pdiag.concept_id = 1284 AND pdiag.answer_concept_id = 142592 AND pdiag.suspected_confirmed = 159393 AND pdiag.voided <> 1
ON DUPLICATE KEY UPDATE last_updated_date = NOW(), voided = pdiag.voided;

/* 21: Diabetes */
INSERT INTO isanteplus.indicators (indicator_id,indicator_type_id,patient_id,location_id,encounter_id,indicator_date,voided,created_date,last_updated_date)
SELECT 21,21,pdiag.patient_id, pdiag.location_id, pdiag.encounter_id, pdiag.encounter_date, pdiag.voided, now(), now()
FROM isanteplus.patient p INNER JOIN isanteplus.patient_diagnosis pdiag ON p.patient_id = pdiag.patient_id
WHERE pdiag.concept_id = 1284 AND pdiag.answer_concept_id IN (142473,142474) AND pdiag.voided <> 1
ON DUPLICATE KEY UPDATE last_updated_date = NOW(), voided = pdiag.voided;

/* 22: Acute watery diarrhea */
INSERT INTO isanteplus.indicators (indicator_id,indicator_type_id,patient_id,location_id,encounter_id,indicator_date,voided,created_date,last_updated_date)
SELECT 22,22,pdiag.patient_id, pdiag.location_id, pdiag.encounter_id, pdiag.encounter_date, pdiag.voided, now(), now()
FROM isanteplus.patient p INNER JOIN isanteplus.patient_diagnosis pdiag ON p.patient_id = pdiag.patient_id
WHERE pdiag.concept_id = 1284 AND pdiag.answer_concept_id = 161887 AND pdiag.voided <> 1
ON DUPLICATE KEY UPDATE last_updated_date = NOW(), voided = pdiag.voided;

/* 23: Acute bloody diarrhea */
INSERT INTO isanteplus.indicators (indicator_id,indicator_type_id,patient_id,location_id,encounter_id,indicator_date,voided,created_date,last_updated_date)
SELECT 23,23,pdiag.patient_id, pdiag.location_id, pdiag.encounter_id, pdiag.encounter_date, pdiag.voided, now(), now()
FROM isanteplus.patient p INNER JOIN isanteplus.patient_diagnosis pdiag ON p.patient_id = pdiag.patient_id
WHERE pdiag.concept_id = 1284 AND pdiag.answer_concept_id = 138868 AND pdiag.voided <> 1
ON DUPLICATE KEY UPDATE last_updated_date = NOW(), voided = pdiag.voided;

/* 24: Suspected typhoid fever */
INSERT INTO isanteplus.indicators (indicator_id,indicator_type_id,patient_id,location_id,encounter_id,indicator_date,voided,created_date,last_updated_date)
SELECT 24,24,pdiag.patient_id, pdiag.location_id, pdiag.encounter_id, pdiag.encounter_date, pdiag.voided, now(), now()
FROM isanteplus.patient p INNER JOIN isanteplus.patient_diagnosis pdiag ON p.patient_id = pdiag.patient_id
WHERE pdiag.concept_id = 1284 AND pdiag.answer_concept_id = 141 AND pdiag.suspected_confirmed = 159393 AND pdiag.voided <> 1
ON DUPLICATE KEY UPDATE last_updated_date = NOW(), voided = pdiag.voided;

/* 25: Probable filariasis */
INSERT INTO isanteplus.indicators (indicator_id,indicator_type_id,patient_id,location_id,encounter_id,indicator_date,voided,created_date,last_updated_date)
SELECT 25,25,pdiag.patient_id, pdiag.location_id, pdiag.encounter_id, pdiag.encounter_date, pdiag.voided, now(), now()
FROM isanteplus.patient p INNER JOIN isanteplus.patient_diagnosis pdiag ON p.patient_id = pdiag.patient_id
WHERE pdiag.concept_id = 1284 AND pdiag.answer_concept_id = 119354 AND pdiag.suspected_confirmed = 159393 AND pdiag.voided <> 1
ON DUPLICATE KEY UPDATE last_updated_date = NOW(), voided = pdiag.voided;

/* 26: Acute respiratory infection */
INSERT INTO isanteplus.indicators (indicator_id,indicator_type_id,patient_id,location_id,encounter_id,indicator_date,voided,created_date,last_updated_date)
SELECT 26,26,pdiag.patient_id, pdiag.location_id, pdiag.encounter_id, pdiag.encounter_date, pdiag.voided, now(), now()
FROM isanteplus.patient p INNER JOIN isanteplus.patient_diagnosis pdiag ON p.patient_id = pdiag.patient_id
WHERE pdiag.concept_id = 1284 AND pdiag.answer_concept_id = 154983 AND pdiag.voided <> 1
ON DUPLICATE KEY UPDATE last_updated_date = NOW(), voided = pdiag.voided;

/* 27: Febrile jaundice syndrome */
INSERT INTO isanteplus.indicators (indicator_id,indicator_type_id,patient_id,location_id,encounter_id,indicator_date,voided,created_date,last_updated_date)
SELECT 27,27,pdiag.patient_id, pdiag.location_id, pdiag.encounter_id, pdiag.encounter_date, pdiag.voided, now(), now()
FROM isanteplus.patient p INNER JOIN isanteplus.patient_diagnosis pdiag ON p.patient_id = pdiag.patient_id
WHERE pdiag.concept_id = 1284 AND pdiag.answer_concept_id = 163402 AND pdiag.voided <> 1
ON DUPLICATE KEY UPDATE last_updated_date = NOW(), voided = pdiag.voided;

/* 28: Tetanus */
INSERT INTO isanteplus.indicators (indicator_id,indicator_type_id,patient_id,location_id,encounter_id,indicator_date,voided,created_date,last_updated_date)
SELECT 28,28,pdiag.patient_id, pdiag.location_id, pdiag.encounter_id, pdiag.encounter_date, pdiag.voided, now(), now()
FROM isanteplus.patient p INNER JOIN isanteplus.patient_diagnosis pdiag ON p.patient_id = pdiag.patient_id
WHERE pdiag.concept_id = 1284 AND pdiag.answer_concept_id = 124957 AND pdiag.voided <> 1
ON DUPLICATE KEY UPDATE last_updated_date = NOW(), voided = pdiag.voided;

/* 29: Accidents */
INSERT INTO isanteplus.indicators (indicator_id,indicator_type_id,patient_id,location_id,encounter_id,indicator_date,voided,created_date,last_updated_date)
SELECT 29,29,pdiag.patient_id, pdiag.location_id, pdiag.encounter_id, pdiag.encounter_date, pdiag.voided, now(), now()
FROM isanteplus.patient p INNER JOIN isanteplus.patient_diagnosis pdiag ON p.patient_id = pdiag.patient_id
WHERE pdiag.concept_id = 1284 AND pdiag.answer_concept_id = 150452 AND pdiag.voided <> 1
ON DUPLICATE KEY UPDATE last_updated_date = NOW(), voided = pdiag.voided;

/* 30: Cancers */
INSERT INTO isanteplus.indicators (indicator_id,indicator_type_id,patient_id,location_id,encounter_id,indicator_date,voided,created_date,last_updated_date)
SELECT 30,30,pdiag.patient_id, pdiag.location_id, pdiag.encounter_id, pdiag.encounter_date, pdiag.voided, now(), now()
FROM isanteplus.patient p INNER JOIN isanteplus.patient_diagnosis pdiag ON p.patient_id = pdiag.patient_id
WHERE pdiag.concept_id = 1284 AND pdiag.answer_concept_id IN (113753,146221,116023) AND pdiag.voided <> 1
ON DUPLICATE KEY UPDATE last_updated_date = NOW(), voided = pdiag.voided;

/* 31: Epilepsy */
INSERT INTO isanteplus.indicators (indicator_id,indicator_type_id,patient_id,location_id,encounter_id,indicator_date,voided,created_date,last_updated_date)
SELECT 31,31,pdiag.patient_id, pdiag.location_id, pdiag.encounter_id, pdiag.encounter_date, pdiag.voided, now(), now()
FROM isanteplus.patient p INNER JOIN isanteplus.patient_diagnosis pdiag ON p.patient_id = pdiag.patient_id
WHERE pdiag.concept_id = 1284 AND pdiag.answer_concept_id = 155 AND pdiag.voided <> 1
ON DUPLICATE KEY UPDATE last_updated_date = NOW(), voided = pdiag.voided;

/* 32: High blood pressure */
INSERT INTO isanteplus.indicators (indicator_id,indicator_type_id,patient_id,location_id,encounter_id,indicator_date,voided,created_date,last_updated_date)
SELECT 32,32,pdiag.patient_id, pdiag.location_id, pdiag.encounter_id, pdiag.encounter_date, pdiag.voided, now(), now()
FROM isanteplus.patient p INNER JOIN isanteplus.patient_diagnosis pdiag ON p.patient_id = pdiag.patient_id
WHERE pdiag.concept_id = 1284 AND pdiag.answer_concept_id = 117399 AND pdiag.voided <> 1
ON DUPLICATE KEY UPDATE last_updated_date = NOW(), voided = pdiag.voided;

/* 33: Sexually transmitted infection */
INSERT INTO isanteplus.indicators (indicator_id,indicator_type_id,patient_id,location_id,encounter_id,indicator_date,voided,created_date,last_updated_date)
SELECT 33,33,pdiag.patient_id, pdiag.location_id, pdiag.encounter_id, pdiag.encounter_date, pdiag.voided, now(), now()
FROM isanteplus.patient p INNER JOIN isanteplus.patient_diagnosis pdiag ON p.patient_id = pdiag.patient_id
WHERE pdiag.concept_id = 1284 AND pdiag.answer_concept_id = 112992 AND pdiag.voided <> 1
ON DUPLICATE KEY UPDATE last_updated_date = NOW(), voided = pdiag.voided;

/* 34: Suspected leprosy */
INSERT INTO isanteplus.indicators (indicator_id,indicator_type_id,patient_id,location_id,encounter_id,indicator_date,voided,created_date,last_updated_date)
SELECT 34,34,pdiag.patient_id, pdiag.location_id, pdiag.encounter_id, pdiag.encounter_date, pdiag.voided, now(), now()
FROM isanteplus.patient p INNER JOIN isanteplus.patient_diagnosis pdiag ON p.patient_id = pdiag.patient_id
WHERE pdiag.concept_id = 1284 AND pdiag.answer_concept_id = 116344 AND pdiag.suspected_confirmed = 159393 AND pdiag.voided <> 1
ON DUPLICATE KEY UPDATE last_updated_date = NOW(), voided = pdiag.voided;

/* 35: Malnutrition */
INSERT INTO isanteplus.indicators (indicator_id,indicator_type_id,patient_id,location_id,encounter_id,indicator_date,voided,created_date,last_updated_date)
SELECT 35,35,pdiag.patient_id, pdiag.location_id, pdiag.encounter_id, pdiag.encounter_date, pdiag.voided, now(), now()
FROM isanteplus.patient p INNER JOIN isanteplus.patient_diagnosis pdiag ON p.patient_id = pdiag.patient_id
WHERE pdiag.concept_id = 1284 AND pdiag.answer_concept_id IN (832,126598,134722,134723) AND pdiag.voided <> 1
ON DUPLICATE KEY UPDATE last_updated_date = NOW(), voided = pdiag.voided;

/* 36: Congenital syphilis */
INSERT INTO isanteplus.indicators (indicator_id,indicator_type_id,patient_id,location_id,encounter_id,indicator_date,voided,created_date,last_updated_date)
SELECT 36,36,pdiag.patient_id, pdiag.location_id, pdiag.encounter_id, pdiag.encounter_date, pdiag.voided, now(), now()
FROM isanteplus.patient p INNER JOIN isanteplus.patient_diagnosis pdiag ON p.patient_id = pdiag.patient_id
WHERE pdiag.concept_id = 1284 AND pdiag.answer_concept_id = 143672 AND pdiag.voided <> 1
ON DUPLICATE KEY UPDATE last_updated_date = NOW(), voided = pdiag.voided;

/* 37: Violence (physical, sexual) */
INSERT INTO isanteplus.indicators (indicator_id,indicator_type_id,patient_id,location_id,encounter_id,indicator_date,voided,created_date,last_updated_date)
SELECT 37,37,pdiag.patient_id, pdiag.location_id, pdiag.encounter_id, pdiag.encounter_date, pdiag.voided, now(), now()
FROM isanteplus.patient p INNER JOIN isanteplus.patient_diagnosis pdiag ON p.patient_id = pdiag.patient_id
WHERE pdiag.concept_id = 1284 AND pdiag.answer_concept_id = 158358 AND pdiag.voided <> 1
ON DUPLICATE KEY UPDATE last_updated_date = NOW(), voided = pdiag.voided;


/* Clean up temp tables */
DROP TEMPORARY TABLE IF EXISTS _tmp_obs;
DROP TEMPORARY TABLE IF EXISTS _tmp_obs_2;
DROP TEMPORARY TABLE IF EXISTS _tmp_encounter;
DROP TEMPORARY TABLE IF EXISTS _tmp_encounter_type;
DROP TEMPORARY TABLE IF EXISTS _tmp_concept;

/* EVENT: disabled. Use external cron instead. */
DROP EVENT IF EXISTS report_indicators_event;
