/*=============================================================================
  insertion_obs_by_day_v2.sql

  Réécriture pour réduire la contention sur les tables openmrs.
  Approche: snapshot des tables openmrs dans des tables temporaires,
  puis travail uniquement sur les tables temporaires.

  Changements par rapport à la version originale:
  - READ UNCOMMITTED pour les lectures openmrs (pas de verrous partagés)
  - Snapshot des tables openmrs.obs, encounter, visit, person, patient,
    person_name, encounter_type dans des tables temporaires
  - Remplacement de toutes les références openmrs.* par _tmp_*
  - Suppression des procédures stockées (SQL plat)
  - Tables temporaires dupliquées pour MySQL 5.6 (pas de self-join)
  - DATE(column) remplacé par des comparaisons avec >= et < pour utiliser les index
=============================================================================*/
USE isanteplus;

/* ---- Tables de jour (DDL) - créées si inexistantes ---- */

CREATE TABLE IF NOT EXISTS obs_by_day(
  `obs_id` int(11) NOT NULL AUTO_INCREMENT,
  `person_id` int(11) NOT NULL,
  `concept_id` int(11) NOT NULL DEFAULT '0',
  `encounter_id` int(11) DEFAULT NULL,
  `order_id` int(11) DEFAULT NULL,
  `obs_datetime` datetime NOT NULL,
  `location_id` int(11) DEFAULT NULL,
  `obs_group_id` int(11) DEFAULT NULL,
  `accession_number` varchar(255) DEFAULT NULL,
  `value_group_id` int(11) DEFAULT NULL,
  `value_coded` int(11) DEFAULT NULL,
  `value_coded_name_id` int(11) DEFAULT NULL,
  `value_drug` int(11) DEFAULT NULL,
  `value_datetime` datetime DEFAULT NULL,
  `value_numeric` double DEFAULT NULL,
  `value_modifier` varchar(2) DEFAULT NULL,
  `value_text` text,
  `value_complex` varchar(255) DEFAULT NULL,
  `comments` varchar(255) DEFAULT NULL,
  `creator` int(11) NOT NULL DEFAULT '0',
  `date_created` datetime NOT NULL,
  `voided` tinyint(1) NOT NULL DEFAULT '0',
  `voided_by` int(11) DEFAULT NULL,
  `date_voided` datetime DEFAULT NULL,
  `void_reason` varchar(255) DEFAULT NULL,
  `uuid` char(38) NOT NULL,
  `previous_version` int(11) DEFAULT NULL,
  `form_namespace_and_path` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`obs_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS patient_dispensing_day (
  patient_id int(11) not null,
  visit_id int(11),
  location_id int(11),
  visit_date Datetime,
  encounter_id int(11) not null,
  provider_id int(11),
  drug_id int(11) not null,
  dose_day int(11),
  pills_amount int(11),
  dispensation_date date,
  next_dispensation_date Date,
  dispensation_location int(11) default 0,
  arv_drug int(11) default 1066,
  rx_or_prophy int(11),
  last_updated_date DATETIME,
  voided tinyint(1),
  CONSTRAINT pk_patient_dispensing_day PRIMARY KEY(encounter_id,location_id,drug_id),
  INDEX(visit_date),
  INDEX(encounter_id),
  INDEX(patient_id)
);

DROP TABLE IF EXISTS patient_prescription_day;
CREATE TABLE IF NOT EXISTS patient_prescription_day (
  patient_id int(11) not null,
  visit_id int(11),
  location_id int(11),
  visit_date Datetime,
  encounter_id int(11) not null,
  provider_id int(11),
  drug_id int(11) not null,
  dispensation_date DATE,
  next_dispensation_date DATE,
  dispensation_location int(11) default 0,
  arv_drug int(11) default 1066,
  dispense int(11),
  rx_or_prophy int(11),
  posology text,
  number_day int(11),
  last_updated_date DATETIME,
  voided tinyint(1),
  CONSTRAINT pk_patient_prescription_day PRIMARY KEY(encounter_id,location_id,drug_id),
  INDEX(visit_date),
  INDEX(encounter_id),
  INDEX(patient_id)
);

DROP TABLE IF EXISTS patient_status_arv_day;
CREATE TABLE IF NOT EXISTS patient_status_arv_day(
  patient_id int(11),
  id_status int,
  start_date date,
  encounter_id INT(11),
  end_date date,
  dis_reason int(11),
  last_updated_date DATETIME,
  date_started_status datetime,
  CONSTRAINT pk_patient_status_arv_day PRIMARY KEY (patient_id,id_status,start_date)
);

DROP TABLE IF EXISTS exposed_infants_day;
CREATE TABLE IF NOT EXISTS exposed_infants_day(
  patient_id int(11),
  location_id int(11),
  encounter_id int(11),
  visit_date date,
  condition_exposee int(11)
);

DROP TABLE IF EXISTS last_obs;
CREATE TABLE IF NOT EXISTS last_obs(
  obs_id int(11),
  last_updated_date DATETIME,
  CONSTRAINT pk_last_obs PRIMARY KEY (obs_id)
);


/*=============================================================================
  PHASE 1: Snapshot des tables openmrs dans des tables temporaires
  Utilisation de READ UNCOMMITTED pour éviter les verrous partagés
=============================================================================*/

SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET SQL_SAFE_UPDATES = 0;

/* Calculer les bornes du jour courant pour utiliser les index */
SET @today_start = CURDATE();
SET @today_end = CURDATE() + INTERVAL 1 DAY;

/* -- Snapshot openmrs.obs du jour -- */
DROP TEMPORARY TABLE IF EXISTS _tmp_obs;
CREATE TEMPORARY TABLE _tmp_obs (
  obs_id int(11),
  person_id int(11),
  concept_id int(11),
  encounter_id int(11),
  order_id int(11),
  obs_datetime datetime,
  location_id int(11),
  obs_group_id int(11),
  accession_number varchar(255),
  value_group_id int(11),
  value_coded int(11),
  value_coded_name_id int(11),
  value_drug int(11),
  value_datetime datetime,
  value_numeric double,
  value_modifier varchar(2),
  value_text text,
  value_complex varchar(255),
  comments varchar(255),
  creator int(11),
  date_created datetime,
  voided tinyint(1),
  voided_by int(11),
  date_voided datetime,
  void_reason varchar(255),
  uuid char(38),
  previous_version int(11),
  form_namespace_and_path varchar(255),
  PRIMARY KEY (obs_id),
  INDEX idx_person (person_id),
  INDEX idx_encounter (encounter_id),
  INDEX idx_concept (concept_id),
  INDEX idx_obs_group (obs_group_id),
  INDEX idx_value_coded (value_coded)
) ENGINE=InnoDB;

INSERT INTO _tmp_obs
SELECT obs_id, person_id, concept_id, encounter_id, order_id, obs_datetime,
  location_id, obs_group_id, accession_number, value_group_id,
  value_coded, value_coded_name_id, value_drug, value_datetime,
  value_numeric, value_modifier, value_text, value_complex, comments,
  creator, date_created, voided, voided_by,
  date_voided, void_reason, uuid, previous_version, form_namespace_and_path
FROM openmrs.obs
WHERE date_created >= @today_start AND date_created < @today_end;

/* Copie pour self-join (MySQL 5.6) */
DROP TEMPORARY TABLE IF EXISTS _tmp_obs_2;
CREATE TEMPORARY TABLE _tmp_obs_2 LIKE _tmp_obs;
INSERT INTO _tmp_obs_2 SELECT * FROM _tmp_obs;

/* -- Snapshot openmrs.obs complet pour les requêtes exposed infants/status (besoin de tout) -- */
DROP TEMPORARY TABLE IF EXISTS _tmp_obs_full;
CREATE TEMPORARY TABLE _tmp_obs_full (
  obs_id int(11),
  person_id int(11),
  concept_id int(11),
  encounter_id int(11),
  obs_group_id int(11),
  obs_datetime datetime,
  location_id int(11),
  value_coded int(11),
  value_numeric double,
  value_datetime datetime,
  voided tinyint(1),
  PRIMARY KEY (obs_id),
  INDEX idx_person (person_id),
  INDEX idx_encounter (encounter_id),
  INDEX idx_concept (concept_id),
  INDEX idx_obs_group (obs_group_id)
) ENGINE=InnoDB;

INSERT INTO _tmp_obs_full
SELECT obs_id, person_id, concept_id, encounter_id, obs_group_id, obs_datetime,
  location_id, value_coded, value_numeric, value_datetime, voided
FROM openmrs.obs
WHERE voided <> 1
  AND concept_id IN (1030, 844, 1401, 1667, 161555, 1282, 1271, 162087, 163540, 163541,
                     1444, 159368, 1443, 1276, 162549, 160742, 1442, 163711, 159394, 159946, 1284);

/* Copie pour self-join */
DROP TEMPORARY TABLE IF EXISTS _tmp_obs_full_2;
CREATE TEMPORARY TABLE _tmp_obs_full_2 LIKE _tmp_obs_full;
INSERT INTO _tmp_obs_full_2 SELECT * FROM _tmp_obs_full;

/* -- Snapshot encounter -- */
DROP TEMPORARY TABLE IF EXISTS _tmp_encounter;
CREATE TEMPORARY TABLE _tmp_encounter (
  encounter_id int(11),
  encounter_type int(11),
  patient_id int(11),
  location_id int(11),
  encounter_datetime datetime,
  visit_id int(11),
  voided tinyint(1),
  PRIMARY KEY (encounter_id),
  INDEX idx_patient (patient_id),
  INDEX idx_visit (visit_id),
  INDEX idx_type (encounter_type)
) ENGINE=InnoDB;

INSERT INTO _tmp_encounter
SELECT encounter_id, encounter_type, patient_id, location_id,
  encounter_datetime, visit_id, voided
FROM openmrs.encounter
WHERE voided <> 1;

/* -- Snapshot encounter_type -- */
DROP TEMPORARY TABLE IF EXISTS _tmp_encounter_type;
CREATE TEMPORARY TABLE _tmp_encounter_type (
  encounter_type_id int(11),
  uuid char(38),
  PRIMARY KEY (encounter_type_id),
  INDEX idx_uuid (uuid)
) ENGINE=MEMORY;

INSERT INTO _tmp_encounter_type
SELECT encounter_type_id, uuid FROM openmrs.encounter_type;

/* -- Snapshot visit -- */
DROP TEMPORARY TABLE IF EXISTS _tmp_visit;
CREATE TEMPORARY TABLE _tmp_visit (
  visit_id int(11),
  patient_id int(11),
  date_started datetime,
  voided tinyint(1),
  PRIMARY KEY (visit_id),
  INDEX idx_patient (patient_id)
) ENGINE=InnoDB;

INSERT INTO _tmp_visit
SELECT visit_id, patient_id, date_started, voided
FROM openmrs.visit
WHERE voided <> 1;

/* Copie pour self-join */
DROP TEMPORARY TABLE IF EXISTS _tmp_visit_2;
CREATE TEMPORARY TABLE _tmp_visit_2 LIKE _tmp_visit;
INSERT INTO _tmp_visit_2 SELECT * FROM _tmp_visit;

/* -- Snapshot person_name, person, patient (du jour seulement) -- */
DROP TEMPORARY TABLE IF EXISTS _tmp_person_name;
CREATE TEMPORARY TABLE _tmp_person_name (
  person_id int(11),
  given_name longtext,
  family_name longtext,
  creator varchar(20),
  date_created date,
  voided tinyint(1),
  INDEX idx_person (person_id)
) ENGINE=InnoDB;

INSERT INTO _tmp_person_name
SELECT pn.person_id, pn.given_name, pn.family_name, pn.creator, pn.date_created, pn.voided
FROM openmrs.person_name pn;

DROP TEMPORARY TABLE IF EXISTS _tmp_person;
CREATE TEMPORARY TABLE _tmp_person (
  person_id int(11),
  gender varchar(10),
  birthdate date,
  PRIMARY KEY (person_id)
) ENGINE=InnoDB;

INSERT INTO _tmp_person
SELECT person_id, gender, birthdate FROM openmrs.person;

DROP TEMPORARY TABLE IF EXISTS _tmp_patient;
CREATE TEMPORARY TABLE _tmp_patient (
  patient_id int(11),
  date_created datetime,
  PRIMARY KEY (patient_id)
) ENGINE=InnoDB;

INSERT INTO _tmp_patient
SELECT patient_id, date_created FROM openmrs.patient;

/* -- Snapshot concept (petit, MEMORY) -- */
DROP TEMPORARY TABLE IF EXISTS _tmp_concept;
CREATE TEMPORARY TABLE _tmp_concept (
  concept_id int(11),
  uuid char(38),
  PRIMARY KEY (concept_id)
) ENGINE=MEMORY;

INSERT INTO _tmp_concept
SELECT concept_id, uuid FROM openmrs.concept;

/* -- Snapshot openmrs.isanteplus_patient_arv pour écriture finale -- */
/* (On prend une copie pour la lecture, l'écriture se fera en une seule transaction à la fin) */

/* Duplicates pour MySQL 5.6/5.7 (ne peut pas référencer une table temp 2x dans la même requête) */
DROP TEMPORARY TABLE IF EXISTS _tmp_encounter_2;
CREATE TEMPORARY TABLE _tmp_encounter_2 LIKE _tmp_encounter;
INSERT INTO _tmp_encounter_2 SELECT * FROM _tmp_encounter;

DROP TEMPORARY TABLE IF EXISTS _tmp_encounter_type_2;
CREATE TEMPORARY TABLE _tmp_encounter_type_2 LIKE _tmp_encounter_type;
INSERT INTO _tmp_encounter_type_2 SELECT * FROM _tmp_encounter_type;

/* Rétablir l'isolation par défaut pour les opérations restantes */
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
COMMIT;


/*=============================================================================
  PHASE 2: ETL du jour - insertion obs_by_day
=============================================================================*/

/* Insertion obs du jour dans obs_by_day */
INSERT INTO isanteplus.obs_by_day
SELECT o.obs_id, o.person_id, o.concept_id, o.encounter_id, o.order_id, o.obs_datetime,
  o.location_id, o.obs_group_id, o.accession_number, o.value_group_id,
  o.value_coded, o.value_coded_name_id, o.value_drug, o.value_datetime,
  o.value_numeric, o.value_modifier, o.value_text, o.value_complex, o.comments,
  o.creator, o.date_created, o.voided, o.voided_by,
  o.date_voided, o.void_reason, o.uuid, o.previous_version, o.form_namespace_and_path
FROM _tmp_obs o
ON DUPLICATE KEY UPDATE
  obs_datetime = o.obs_datetime,
  obs_group_id = o.obs_group_id,
  value_datetime = o.value_datetime,
  value_coded = o.value_coded,
  value_numeric = o.value_numeric,
  value_text = o.value_text,
  voided = o.voided;


/*=============================================================================
  PHASE 3: Insertion patient du jour
=============================================================================*/

INSERT INTO patient
(patient_id, given_name, family_name, gender, birthdate,
 creator, date_created, last_inserted_date, last_updated_date, voided)
SELECT pn.person_id, pn.given_name, pn.family_name, pe.gender, pe.birthdate,
  pn.creator, pn.date_created, now() AS last_inserted_date, now() AS last_updated_date, pn.voided
FROM _tmp_person_name pn
INNER JOIN _tmp_person pe ON pe.person_id = pn.person_id
INNER JOIN _tmp_patient pa ON pe.person_id = pa.patient_id
WHERE pa.date_created >= @today_start AND pa.date_created < @today_end
ON DUPLICATE KEY UPDATE
  given_name = pn.given_name,
  family_name = pn.family_name,
  gender = pe.gender,
  birthdate = pe.birthdate,
  creator = pn.creator,
  date_created = pn.date_created,
  last_updated_date = now(),
  voided = pn.voided;

/* Mise à jour du statut VIH pour les patients du jour */
UPDATE patient p
INNER JOIN _tmp_encounter en ON p.patient_id = en.patient_id
INNER JOIN _tmp_encounter_type ent ON en.encounter_type = ent.encounter_type_id
SET p.vih_status = 1
WHERE ent.uuid IN ('17536ba6-dd7c-4f58-8014-08c7cb798ac7',
                   '204ad066-c5c2-4229-9a62-644bc5617ca2',
                   '349ae0b4-65c1-4122-aa06-480f186c8350',
                   '33491314-c352-42d0-bd5d-a9d0bffc9bf1')
AND en.voided = 0
AND p.date_created >= @today_start AND p.date_created < @today_end;


/*=============================================================================
  PHASE 4: Dispensing du jour
=============================================================================*/

INSERT INTO patient_dispensing_day
(patient_id, encounter_id, location_id, drug_id, dispensation_date, last_updated_date, voided)
SELECT DISTINCT ob.person_id, ob.encounter_id, ob.location_id, ob.value_coded,
  DATE(ob2.obs_datetime), now(), ob.voided
FROM isanteplus.obs_by_day ob
INNER JOIN isanteplus.obs_by_day ob1 ON ob.person_id = ob1.person_id
  AND ob.encounter_id = ob1.encounter_id AND ob.obs_group_id = ob1.obs_id
INNER JOIN isanteplus.obs_by_day ob2 ON ob1.obs_id = ob2.obs_group_id
WHERE ob1.concept_id = 163711
  AND ob.concept_id = 1282
  AND ob2.concept_id IN (1444, 159368, 1443, 1276)
ON DUPLICATE KEY UPDATE
  dispensation_date = ob2.obs_datetime,
  last_updated_date = now(),
  voided = ob.voided;

/* Mise à jour next_dispensation_date */
UPDATE patient_dispensing_day patdisp
INNER JOIN isanteplus.obs_by_day ob ON patdisp.encounter_id = ob.encounter_id
SET patdisp.next_dispensation_date = DATE(ob.value_datetime)
WHERE ob.concept_id = 162549 AND ob.voided = 0;

/* Mise à jour arv_drug */
UPDATE patient_dispensing_day pdis
INNER JOIN arv_drugs ad ON pdis.drug_id = ad.drug_id
SET pdis.arv_drug = 1065;

/* Mise à jour visit_id, visit_date (utilise snapshot) */
UPDATE patient_dispensing_day patdisp
INNER JOIN _tmp_encounter en ON patdisp.encounter_id = en.encounter_id
INNER JOIN _tmp_visit vi ON en.visit_id = vi.visit_id
SET patdisp.visit_id = vi.visit_id, patdisp.visit_date = vi.date_started;

/* Mise à jour rx_or_prophy */
UPDATE isanteplus.patient_dispensing_day pdisp
INNER JOIN isanteplus.obs_by_day ob1 ON pdisp.encounter_id = ob1.encounter_id
INNER JOIN isanteplus.obs_by_day ob2 ON ob1.obs_id = ob2.obs_group_id
  AND pdisp.encounter_id = ob2.encounter_id AND pdisp.patient_id = ob2.person_id
  AND pdisp.location_id = ob2.location_id
INNER JOIN isanteplus.obs_by_day ob3 ON ob1.obs_id = ob3.obs_group_id
SET pdisp.rx_or_prophy = ob2.value_coded
WHERE ob1.concept_id = 1442
  AND ob2.concept_id = 160742
  AND ob3.concept_id = 1282
  AND pdisp.drug_id = ob3.value_coded
  AND ob2.voided = 0;


/*=============================================================================
  PHASE 5: Prescription du jour
=============================================================================*/

INSERT INTO patient_prescription_day
(patient_id, encounter_id, location_id, drug_id, dispense, last_updated_date, voided)
SELECT DISTINCT ob.person_id, ob.encounter_id, ob.location_id, ob.value_coded,
  IF(ob1.concept_id = 163711, 1065, 1066), now(), ob.voided
FROM isanteplus.obs_by_day ob
INNER JOIN isanteplus.obs_by_day ob1 ON ob.person_id = ob1.person_id
  AND ob.encounter_id = ob1.encounter_id AND ob.obs_group_id = ob1.obs_id
INNER JOIN isanteplus.obs_by_day ob2 ON ob1.obs_id = ob2.obs_group_id
WHERE (ob1.concept_id = 1442 OR ob1.concept_id = 163711)
  AND ob.concept_id = 1282
  AND ob2.concept_id IN (160742, 1276, 1444, 159368, 1443)
ON DUPLICATE KEY UPDATE
  encounter_id = ob.encounter_id,
  last_updated_date = now(),
  voided = ob.voided;

/* Insertion dispensation dans prescription */
INSERT INTO patient_prescription_day
(patient_id, encounter_id, location_id, drug_id, dispensation_date, dispense, last_updated_date, voided)
SELECT DISTINCT ob.person_id, ob.encounter_id, ob.location_id, ob.value_coded,
  ob2.obs_datetime, 1065, now(), ob.voided
FROM isanteplus.obs_by_day ob
INNER JOIN isanteplus.obs_by_day ob1 ON ob.person_id = ob1.person_id
  AND ob.encounter_id = ob1.encounter_id AND ob.obs_group_id = ob1.obs_id
INNER JOIN isanteplus.obs_by_day ob2 ON ob1.obs_id = ob2.obs_group_id
WHERE ob1.concept_id = 163711
  AND ob.concept_id = 1282
  AND ob2.concept_id IN (1276, 1444, 159368, 1443)
ON DUPLICATE KEY UPDATE
  dispensation_date = ob2.obs_datetime,
  dispense = 1065,
  last_updated_date = now(),
  voided = ob.voided;

/* Mise à jour visit pour prescription (snapshot) */
UPDATE patient_prescription_day patp
INNER JOIN _tmp_encounter en ON patp.encounter_id = en.encounter_id
INNER JOIN _tmp_visit vi ON en.visit_id = vi.visit_id
SET patp.visit_id = vi.visit_id, patp.visit_date = vi.date_started;

/* Mise à jour arv_drug pour prescription */
UPDATE patient_prescription_day ppres
INNER JOIN arv_drugs ad ON ppres.drug_id = ad.drug_id
SET ppres.arv_drug = 1065;

/* Mise à jour rx_or_prophy pour prescription */
UPDATE isanteplus.patient_prescription_day pp
INNER JOIN isanteplus.obs_by_day ob1 ON pp.encounter_id = ob1.encounter_id
INNER JOIN isanteplus.obs_by_day ob2 ON ob1.obs_id = ob2.obs_group_id
INNER JOIN isanteplus.obs_by_day ob3 ON ob1.obs_id = ob3.obs_group_id
SET pp.rx_or_prophy = ob2.value_coded
WHERE ob1.concept_id = 1442
  AND ob2.concept_id = 160742
  AND ob3.concept_id = 1282
  AND pp.drug_id = ob3.value_coded
  AND ob2.voided = 0;


/*=============================================================================
  PHASE 6: Laboratoire du jour (utilise snapshot encounter)
=============================================================================*/

INSERT INTO patient_laboratory
(patient_id, encounter_id, location_id, test_id, last_updated_date, voided)
SELECT DISTINCT ob.person_id, ob.encounter_id, ob.location_id, ob.value_coded, now(), ob.voided
FROM isanteplus.obs_by_day ob
INNER JOIN _tmp_encounter enc ON ob.encounter_id = enc.encounter_id
INNER JOIN _tmp_encounter_type entype ON enc.encounter_type = entype.encounter_type_id
WHERE ob.concept_id = 1271
  AND entype.uuid = 'f037e97b-471e-4898-a07c-b8e169e0ddc4'
ON DUPLICATE KEY UPDATE
  encounter_id = ob.encounter_id,
  last_updated_date = now(),
  voided = ob.voided;

/* Mise à jour visit pour laboratoire (snapshot) */
UPDATE patient_laboratory lab
INNER JOIN _tmp_encounter en ON lab.encounter_id = en.encounter_id
INNER JOIN _tmp_visit vi ON en.visit_id = vi.visit_id
SET lab.visit_id = vi.visit_id, lab.visit_date = vi.date_started
WHERE vi.voided = 0;

/* Mise à jour résultats */
UPDATE patient_laboratory plab
INNER JOIN isanteplus.obs_by_day ob ON plab.test_id = ob.concept_id
  AND plab.encounter_id = ob.encounter_id
SET plab.test_done = 1,
  plab.test_result = CASE
    WHEN ob.value_coded <> '' THEN ob.value_coded
    WHEN ob.value_numeric <> '' THEN ob.value_numeric
    WHEN ob.value_text <> '' THEN ob.value_text
  END,
  plab.date_test_done = ob.obs_datetime,
  plab.comment_test_done = ob.comments
WHERE ob.voided = 0;


/*=============================================================================
  PHASE 7: Tests virologiques (snapshot)
=============================================================================*/

INSERT INTO virological_tests
(patient_id, encounter_id, location_id, concept_group, obs_group_id, test_id, answer_concept_id, last_updated_date, voided)
SELECT DISTINCT ob.person_id, ob.encounter_id, ob.location_id, ob1.concept_id,
  ob.obs_group_id, ob.concept_id, ob.value_coded, now(), ob.voided
FROM isanteplus.obs_by_day ob
INNER JOIN isanteplus.obs_by_day ob1 ON ob.person_id = ob1.person_id
  AND ob.encounter_id = ob1.encounter_id AND ob.obs_group_id = ob1.obs_id
INNER JOIN _tmp_concept c ON ob1.concept_id = c.concept_id
WHERE c.uuid IN ('eaa7f684-1473-4f59-acb4-686bada87846',
                 '9a05c0d5-2c03-4c3a-a810-6bc513ae7ee7',
                 '535b63e9-0773-4f4e-94af-69ff8f412411')
  AND ob.concept_id = 162087
  AND ob.value_coded = 1030
ON DUPLICATE KEY UPDATE
  encounter_id = ob.encounter_id,
  last_updated_date = now(),
  voided = ob.voided;

/* Mise à jour test_result PCR */
UPDATE virological_tests vtests
INNER JOIN isanteplus.obs_by_day ob ON vtests.obs_group_id = ob.obs_group_id
  AND vtests.encounter_id = ob.encounter_id AND vtests.location_id = ob.location_id
SET vtests.test_result = ob.value_coded
WHERE ob.concept_id = 1030 AND ob.voided = 0;

/* Mise à jour age PCR */
UPDATE virological_tests vtests
INNER JOIN isanteplus.obs_by_day ob ON vtests.obs_group_id = ob.obs_group_id
  AND vtests.encounter_id = ob.encounter_id AND vtests.location_id = ob.location_id
SET vtests.age = ob.value_numeric
WHERE ob.concept_id = 163540 AND ob.voided = 0;

/* Mise à jour age_unit PCR */
UPDATE virological_tests vtests
INNER JOIN isanteplus.obs_by_day ob ON vtests.obs_group_id = ob.obs_group_id
  AND vtests.encounter_id = ob.encounter_id AND vtests.location_id = ob.location_id
SET vtests.age_unit = ob.value_coded
WHERE ob.concept_id = 163541 AND ob.voided = 0;

/* Mise à jour encounter_date (snapshot) */
UPDATE virological_tests vtests
INNER JOIN _tmp_encounter enc ON vtests.location_id = enc.location_id
  AND vtests.encounter_id = enc.encounter_id
SET vtests.encounter_date = DATE(enc.encounter_datetime)
WHERE enc.voided = 0;

/* Mise à jour test_date */
UPDATE virological_tests vtests
INNER JOIN patient p ON vtests.patient_id = p.patient_id
SET vtests.test_date = CASE
  WHEN (vtests.age_unit = 1072 AND ADDDATE(DATE(p.birthdate), INTERVAL vtests.age DAY) < DATE(now()))
    THEN ADDDATE(DATE(p.birthdate), INTERVAL vtests.age DAY)
  WHEN (vtests.age_unit = 1074 AND ADDDATE(DATE(p.birthdate), INTERVAL vtests.age MONTH) < DATE(now()))
    THEN ADDDATE(DATE(p.birthdate), INTERVAL vtests.age MONTH)
  ELSE vtests.encounter_date
END
WHERE vtests.test_id = 162087 AND vtests.answer_concept_id = 1030;


/*=============================================================================
  PHASE 8: Enfants exposés (snapshot - requêtes lourdes sur obs)
=============================================================================*/

TRUNCATE TABLE exposed_infants_day;

/* Dernier PCR négatif */
DROP TEMPORARY TABLE IF EXISTS patient_pcr_negative;
CREATE TEMPORARY TABLE patient_pcr_negative (
  patient_id int(11),
  encounter_id int(11),
  location_id int(11),
  encounter_date datetime,
  concept_id int(11),
  value_coded int(11),
  obs_datetime datetime,
  INDEX (patient_id)
) ENGINE=InnoDB;

INSERT INTO patient_pcr_negative
SELECT o.person_id, o.encounter_id, o.location_id, e.encounter_datetime,
  o.concept_id, o.value_coded, o.obs_datetime
FROM _tmp_obs_full o
INNER JOIN _tmp_encounter e ON o.person_id = e.patient_id AND o.encounter_id = e.encounter_id
INNER JOIN _tmp_encounter_type et ON e.encounter_type = et.encounter_type_id
INNER JOIN (
  SELECT en.patient_id, MAX(en.encounter_datetime) AS visit_date
  FROM _tmp_obs_full_2 ob
  INNER JOIN _tmp_encounter_2 en ON ob.encounter_id = en.encounter_id
  INNER JOIN _tmp_encounter_type_2 ety ON en.encounter_type = ety.encounter_type_id
  WHERE ob.concept_id IN (1030, 844)
    AND ety.uuid IN ('349ae0b4-65c1-4122-aa06-480f186c8350', 'f037e97b-471e-4898-a07c-b8e169e0ddc4')
    AND ob.voided <> 1
  GROUP BY en.patient_id
) B ON e.patient_id = B.patient_id AND DATE(e.encounter_datetime) = DATE(B.visit_date)
WHERE et.uuid IN ('349ae0b4-65c1-4122-aa06-480f186c8350', 'f037e97b-471e-4898-a07c-b8e169e0ddc4')
  AND o.concept_id IN (1030, 844)
  AND (o.value_coded = 664 OR o.value_coded = 1302)
  AND o.voided <> 1;

INSERT INTO exposed_infants_day (patient_id, location_id, encounter_id, visit_date, condition_exposee)
SELECT ppn.patient_id, ppn.location_id, ppn.encounter_id, ppn.encounter_date, 1
FROM patient_pcr_negative ppn
WHERE (ppn.concept_id = 1030 AND ppn.value_coded = 664)
  OR (ppn.concept_id = 844 AND ppn.value_coded = 1302);

DROP TEMPORARY TABLE IF EXISTS patient_pcr_negative;

/* Condition B - Enfant exposé coché (snapshot) */
INSERT INTO exposed_infants_day (patient_id, location_id, encounter_id, visit_date, condition_exposee)
SELECT DISTINCT ob.person_id, ob.location_id, ob.encounter_id,
  DATE(enc.encounter_datetime), 3
FROM _tmp_obs_full ob
INNER JOIN _tmp_encounter enc ON ob.encounter_id = enc.encounter_id
INNER JOIN _tmp_encounter_type ent ON enc.encounter_type = ent.encounter_type_id
WHERE ob.concept_id = 1401 AND ob.value_coded = 1405
  AND ob.voided <> 1
  AND ent.uuid IN ('349ae0b4-65c1-4122-aa06-480f186c8350', '33491314-c352-42d0-bd5d-a9d0bffc9bf1');

/* Condition D - ARV en prophylaxie */
INSERT INTO exposed_infants_day (patient_id, location_id, encounter_id, visit_date, condition_exposee)
SELECT DISTINCT pdisp.patient_id, pdisp.location_id, pdisp.encounter_id, pdisp.visit_date, 4
FROM patient_dispensing pdisp
INNER JOIN (
  SELECT ppres.patient_id, MAX(ppres.visit_date) AS visit_date
  FROM patient_dispensing ppres
  WHERE ppres.arv_drug = 1065 AND ppres.voided <> 1
  GROUP BY ppres.patient_id
) B ON pdisp.patient_id = B.patient_id AND pdisp.visit_date = B.visit_date
WHERE pdisp.rx_or_prophy = 163768
  AND pdisp.arv_drug = 1065
  AND pdisp.voided <> 1;

/* Supprimer patients avec PCR positif (snapshot) */
DROP TEMPORARY TABLE IF EXISTS patient_pcr_positif;
CREATE TEMPORARY TABLE patient_pcr_positif (
  patient_id int(11),
  INDEX (patient_id)
) ENGINE=InnoDB;

INSERT INTO patient_pcr_positif (patient_id)
SELECT DISTINCT o.person_id
FROM _tmp_obs_full o
INNER JOIN _tmp_encounter e ON o.person_id = e.patient_id AND o.encounter_id = e.encounter_id
INNER JOIN _tmp_encounter_type et ON e.encounter_type = et.encounter_type_id
WHERE et.uuid IN ('349ae0b4-65c1-4122-aa06-480f186c8350', 'f037e97b-471e-4898-a07c-b8e169e0ddc4')
  AND ((o.concept_id = 1030 AND o.value_coded = 703)
    OR (o.concept_id = 844 AND o.value_coded = 1301))
  AND o.voided <> 1;

DELETE exposed_infants_day FROM exposed_infants_day
INNER JOIN patient_pcr_positif ON exposed_infants_day.patient_id = patient_pcr_positif.patient_id;

DROP TEMPORARY TABLE IF EXISTS patient_pcr_positif;

/* Supprimer HIV positif confirmé > 18 mois */
DELETE exposed_infants_day FROM exposed_infants_day
INNER JOIN (
  SELECT pl.patient_id FROM patient_laboratory pl
  INNER JOIN patient p ON pl.patient_id = p.patient_id
  WHERE pl.test_id = 1040 AND pl.test_done = 1 AND pl.test_result = 703
    AND pl.voided <> 1
    AND TIMESTAMPDIFF(MONTH, p.birthdate, DATE(now())) >= 18
) C ON exposed_infants_day.patient_id = C.patient_id;

/* Supprimer VIH positif confirmé sérologique (snapshot) */
DELETE exposed_infants_day FROM exposed_infants_day
INNER JOIN (
  SELECT DISTINCT ob.person_id
  FROM _tmp_obs_full ob
  INNER JOIN _tmp_encounter enc ON ob.encounter_id = enc.encounter_id
  INNER JOIN _tmp_encounter_type ent ON enc.encounter_type = ent.encounter_type_id
  WHERE ob.concept_id = 1401 AND ob.value_coded = 163717
    AND ob.voided <> 1
    AND ent.uuid IN ('349ae0b4-65c1-4122-aa06-480f186c8350', '33491314-c352-42d0-bd5d-a9d0bffc9bf1')
) C ON exposed_infants_day.patient_id = C.person_id;

/* Condition 5 - Séroréversion (snapshot) */
INSERT INTO exposed_infants_day (patient_id, location_id, encounter_id, visit_date, condition_exposee)
SELECT DISTINCT ob.person_id, ob.location_id, ob.encounter_id,
  DATE(enc.encounter_datetime), 5
FROM _tmp_obs_full ob
INNER JOIN _tmp_encounter enc ON ob.encounter_id = enc.encounter_id
INNER JOIN _tmp_encounter_type ent ON enc.encounter_type = ent.encounter_type_id
WHERE ob.concept_id = 1667 AND ob.value_coded = 165439
  AND ob.voided <> 1
  AND ent.uuid = '9d0113c6-f23a-4461-8428-7e9a7344f2ba';


/*=============================================================================
  PHASE 9: Statut ARV du jour (snapshot)
=============================================================================*/

/* Pré-calculer la dernière visite par patient */
DROP TEMPORARY TABLE IF EXISTS _tmp_latest_visit;
CREATE TEMPORARY TABLE _tmp_latest_visit (
  patient_id int(11),
  visit_date datetime,
  PRIMARY KEY (patient_id)
) ENGINE=InnoDB;

INSERT INTO _tmp_latest_visit
SELECT patient_id, MAX(DATE(date_started))
FROM _tmp_visit WHERE voided = 0
GROUP BY patient_id;

/* Décédés en Pré-ARV = 4 */
INSERT INTO patient_status_arv_day (patient_id, id_status, start_date, encounter_id, last_updated_date, date_started_status)
SELECT v.patient_id, 4, DATE(v.date_started), enc.encounter_id, now(), now()
FROM isanteplus.patient ispat
INNER JOIN _tmp_visit v ON ispat.patient_id = v.patient_id
INNER JOIN _tmp_encounter enc ON v.visit_id = enc.visit_id
INNER JOIN _tmp_encounter_type entype ON enc.encounter_type = entype.encounter_type_id
INNER JOIN _tmp_obs_full ob ON enc.encounter_id = ob.encounter_id
INNER JOIN _tmp_latest_visit B ON v.patient_id = B.patient_id AND v.date_started = B.visit_date
WHERE entype.uuid = '9d0113c6-f23a-4461-8428-7e9a7344f2ba'
  AND ob.concept_id = 161555 AND ob.value_coded = 159
  AND ispat.vih_status = 1
  AND enc.patient_id NOT IN (SELECT parv.patient_id FROM isanteplus.patient_on_arv parv)
  AND ob.voided = 0
GROUP BY v.patient_id
ON DUPLICATE KEY UPDATE last_updated_date = VALUES(last_updated_date);

/* Transférés en Pré-ARV = 5 */
INSERT INTO patient_status_arv_day (patient_id, id_status, start_date, encounter_id, last_updated_date, date_started_status)
SELECT v.patient_id, 5, DATE(v.date_started), enc.encounter_id, now(), now()
FROM isanteplus.patient ispat
INNER JOIN _tmp_visit_2 v ON ispat.patient_id = v.patient_id
INNER JOIN _tmp_encounter enc ON v.visit_id = enc.visit_id
INNER JOIN _tmp_encounter_type entype ON enc.encounter_type = entype.encounter_type_id
INNER JOIN _tmp_obs_full ob ON enc.encounter_id = ob.encounter_id
INNER JOIN _tmp_latest_visit B ON v.patient_id = B.patient_id AND v.date_started = B.visit_date
WHERE entype.uuid = '9d0113c6-f23a-4461-8428-7e9a7344f2ba'
  AND ob.concept_id = 161555 AND ob.value_coded = 159492
  AND ispat.vih_status = 1
  AND enc.patient_id NOT IN (SELECT parv.patient_id FROM isanteplus.patient_on_arv parv)
  AND ob.voided = 0
GROUP BY v.patient_id
ON DUPLICATE KEY UPDATE last_updated_date = VALUES(last_updated_date);

/* Réguliers = 6 */
INSERT INTO patient_status_arv_day (patient_id, id_status, start_date, encounter_id, last_updated_date, date_started_status)
SELECT pdis.patient_id, 6, MAX(DATE(pdis.visit_date)), pdis.encounter_id, now(), now()
FROM isanteplus.patient ipat
INNER JOIN isanteplus.patient_dispensing_day pdis ON ipat.patient_id = pdis.patient_id
INNER JOIN (
  SELECT pdisp.patient_id, MAX(pdisp.next_dispensation_date) AS mnext_disp
  FROM isanteplus.patient_dispensing_day pdisp
  WHERE pdisp.voided <> 1 AND pdisp.arv_drug = 1065
  GROUP BY pdisp.patient_id
) mndisp ON pdis.patient_id = mndisp.patient_id AND pdis.next_dispensation_date = mndisp.mnext_disp
INNER JOIN _tmp_encounter enc ON pdis.visit_id = enc.visit_id
INNER JOIN _tmp_encounter_type entype ON enc.encounter_type = entype.encounter_type_id
WHERE enc.patient_id NOT IN (
  SELECT dreason.patient_id FROM discontinuation_reason dreason WHERE dreason.reason IN (159, 1667, 159492)
)
  AND pdis.arv_drug = 1065
  AND entype.uuid IN ('10d73929-54b6-4d18-a647-8b7316bc1ae3', 'a9392241-109f-4d67-885b-57cc4b8c638f')
  AND DATE(now()) <= pdis.next_dispensation_date
GROUP BY pdis.patient_id
ON DUPLICATE KEY UPDATE last_updated_date = VALUES(last_updated_date);

/* Rendez-vous ratés = 8 */
INSERT INTO patient_status_arv_day (patient_id, id_status, start_date, encounter_id, last_updated_date, date_started_status)
SELECT pdis.patient_id, 8, MAX(DATE(pdis.visit_date)), pdis.encounter_id, now(), now()
FROM isanteplus.patient ipat
INNER JOIN isanteplus.patient_dispensing_day pdis ON ipat.patient_id = pdis.patient_id
INNER JOIN (
  SELECT pdisp.patient_id, MAX(pdisp.next_dispensation_date) AS mnext_disp
  FROM isanteplus.patient_dispensing_day pdisp
  WHERE pdisp.voided <> 1 AND pdisp.arv_drug = 1065
  GROUP BY pdisp.patient_id
) mndisp ON pdis.patient_id = mndisp.patient_id AND pdis.next_dispensation_date = mndisp.mnext_disp
INNER JOIN _tmp_encounter enc ON pdis.visit_id = enc.visit_id
INNER JOIN _tmp_encounter_type entype ON enc.encounter_type = entype.encounter_type_id
WHERE enc.patient_id NOT IN (
  SELECT dreason.patient_id FROM discontinuation_reason dreason WHERE dreason.reason IN (159, 1667, 159492)
)
  AND enc.patient_id IN (SELECT parv.patient_id FROM isanteplus.patient_on_arv parv)
  AND entype.uuid IN ('10d73929-54b6-4d18-a647-8b7316bc1ae3', 'a9392241-109f-4d67-885b-57cc4b8c638f')
  AND DATEDIFF(DATE(now()), pdis.next_dispensation_date) <= 30
  AND DATE(now()) > pdis.next_dispensation_date
GROUP BY pdis.patient_id
ON DUPLICATE KEY UPDATE last_updated_date = VALUES(last_updated_date);

/* Perdus de vue = 9 */
INSERT INTO patient_status_arv_day (patient_id, id_status, start_date, encounter_id, last_updated_date, date_started_status)
SELECT pdis.patient_id, 9, MAX(DATE(pdis.visit_date)), pdis.encounter_id, now(), now()
FROM isanteplus.patient_dispensing_day pdis
INNER JOIN (
  SELECT pdisp.patient_id, MAX(pdisp.next_dispensation_date) AS mnext_disp
  FROM isanteplus.patient_dispensing_day pdisp
  WHERE pdisp.voided <> 1 AND pdisp.arv_drug = 1065
  GROUP BY pdisp.patient_id
) mndisp ON pdis.patient_id = mndisp.patient_id AND pdis.next_dispensation_date = mndisp.mnext_disp
INNER JOIN _tmp_encounter enc ON pdis.visit_id = enc.visit_id
INNER JOIN _tmp_encounter_type entype ON enc.encounter_type = entype.encounter_type_id
WHERE enc.patient_id NOT IN (
  SELECT dreason.patient_id FROM discontinuation_reason dreason WHERE dreason.reason IN (159, 1667, 159492)
)
  AND pdis.arv_drug = 1065
  AND DATE(now()) > pdis.next_dispensation_date
  AND DATEDIFF(DATE(now()), pdis.next_dispensation_date) > 30
  AND entype.uuid IN ('10d73929-54b6-4d18-a647-8b7316bc1ae3', 'a9392241-109f-4d67-885b-57cc4b8c638f')
GROUP BY pdis.patient_id
ON DUPLICATE KEY UPDATE last_updated_date = VALUES(last_updated_date);

/* Perdus de vue en Pré-ARV = 10 */
INSERT INTO patient_status_arv_day (patient_id, id_status, start_date, encounter_id, last_updated_date, date_started_status)
SELECT v.patient_id, 10, MAX(DATE(v.date_started)), enc.encounter_id, now(), now()
FROM isanteplus.patient ispat
INNER JOIN _tmp_visit v ON ispat.patient_id = v.patient_id
INNER JOIN _tmp_encounter enc ON v.visit_id = enc.visit_id
INNER JOIN _tmp_encounter_type entype ON enc.encounter_type = entype.encounter_type_id
INNER JOIN _tmp_latest_visit B ON v.patient_id = B.patient_id AND v.date_started = B.visit_date
WHERE enc.patient_id NOT IN (
  SELECT dreason.patient_id FROM discontinuation_reason dreason WHERE dreason.reason IN (159, 159492)
)
  AND ispat.vih_status = 1
  AND ispat.patient_id NOT IN (SELECT parv.patient_id FROM isanteplus.patient_on_arv parv)
  AND entype.uuid NOT IN ('17536ba6-dd7c-4f58-8014-08c7cb798ac7', '349ae0b4-65c1-4122-aa06-480f186c8350',
    '204ad066-c5c2-4229-9a62-644bc5617ca2', '33491314-c352-42d0-bd5d-a9d0bffc9bf1',
    '10d73929-54b6-4d18-a647-8b7316bc1ae3', 'a9392241-109f-4d67-885b-57cc4b8c638f',
    'f037e97b-471e-4898-a07c-b8e169e0ddc4')
  AND TIMESTAMPDIFF(MONTH, v.date_started, DATE(now())) > 12
GROUP BY v.patient_id
ON DUPLICATE KEY UPDATE last_updated_date = VALUES(last_updated_date);

/* Recent on PRE-ART = 7 */
INSERT INTO patient_status_arv_day (patient_id, id_status, start_date, encounter_id, last_updated_date, date_started_status)
SELECT v.patient_id, 7, MAX(DATE(v.date_started)), enc.encounter_id, now(), now()
FROM isanteplus.patient ispat
INNER JOIN _tmp_visit v ON ispat.patient_id = v.patient_id
INNER JOIN _tmp_encounter enc ON v.visit_id = enc.visit_id
INNER JOIN _tmp_encounter_type entype ON enc.encounter_type = entype.encounter_type_id
INNER JOIN _tmp_latest_visit B ON v.patient_id = B.patient_id AND v.date_started = B.visit_date
WHERE enc.patient_id NOT IN (
  SELECT dreason.patient_id FROM discontinuation_reason dreason WHERE dreason.reason IN (159, 159492)
)
  AND ispat.vih_status = 1
  AND ispat.patient_id NOT IN (SELECT parv.patient_id FROM isanteplus.patient_on_arv parv)
  AND entype.uuid IN ('17536ba6-dd7c-4f58-8014-08c7cb798ac7', '349ae0b4-65c1-4122-aa06-480f186c8350')
  AND TIMESTAMPDIFF(MONTH, v.date_started, DATE(now())) <= 12
GROUP BY v.patient_id
ON DUPLICATE KEY UPDATE last_updated_date = VALUES(last_updated_date);

/* Actifs en Pré-ARV = 11 */
INSERT INTO patient_status_arv_day (patient_id, id_status, start_date, encounter_id, last_updated_date, date_started_status)
SELECT v.patient_id, 11, MAX(DATE(v.date_started)), enc.encounter_id, now(), now()
FROM isanteplus.patient ispat
INNER JOIN _tmp_visit_2 v ON ispat.patient_id = v.patient_id
INNER JOIN _tmp_encounter enc ON v.visit_id = enc.visit_id
INNER JOIN _tmp_encounter_type entype ON enc.encounter_type = entype.encounter_type_id
INNER JOIN _tmp_latest_visit B ON v.patient_id = B.patient_id AND v.date_started = B.visit_date
WHERE enc.patient_id NOT IN (
  SELECT dreason.patient_id FROM discontinuation_reason dreason WHERE dreason.reason IN (159, 159492)
)
  AND ispat.vih_status = 1
  AND ispat.patient_id NOT IN (SELECT parv.patient_id FROM isanteplus.patient_on_arv parv)
  AND entype.uuid IN ('204ad066-c5c2-4229-9a62-644bc5617ca2', '33491314-c352-42d0-bd5d-a9d0bffc9bf1',
    '10d73929-54b6-4d18-a647-8b7316bc1ae3', 'a9392241-109f-4d67-885b-57cc4b8c638f',
    'f037e97b-471e-4898-a07c-b8e169e0ddc4')
  AND TIMESTAMPDIFF(MONTH, v.date_started, DATE(now())) <= 12
GROUP BY v.patient_id
ON DUPLICATE KEY UPDATE last_updated_date = VALUES(last_updated_date);

/* Décédés = 1 (utilise obs_by_day + snapshot encounter) */
INSERT INTO patient_status_arv_day (patient_id, id_status, start_date, encounter_id, last_updated_date, date_started_status)
SELECT enc.patient_id, 1, MAX(DATE(enc.encounter_datetime)), enc.encounter_id, now(), now()
FROM _tmp_encounter enc
INNER JOIN _tmp_encounter_type entype ON enc.encounter_type = entype.encounter_type_id
INNER JOIN isanteplus.obs_by_day ob ON enc.encounter_id = ob.encounter_id AND enc.patient_id = ob.person_id
INNER JOIN isanteplus.patient_on_arv parv ON enc.patient_id = parv.patient_id
WHERE entype.uuid = '9d0113c6-f23a-4461-8428-7e9a7344f2ba'
  AND ob.concept_id = 161555 AND ob.value_coded = 159
  AND ob.voided = 0 AND enc.voided = 0
GROUP BY enc.patient_id
ON DUPLICATE KEY UPDATE last_updated_date = VALUES(last_updated_date);

/* Transférés = 2 */
INSERT INTO patient_status_arv_day (patient_id, id_status, start_date, encounter_id, last_updated_date, date_started_status)
SELECT enc.patient_id, 2, MAX(DATE(enc.encounter_datetime)), enc.encounter_id, now(), now()
FROM _tmp_encounter enc
INNER JOIN _tmp_encounter_type entype ON enc.encounter_type = entype.encounter_type_id
INNER JOIN isanteplus.obs_by_day ob ON enc.encounter_id = ob.encounter_id AND enc.patient_id = ob.person_id
INNER JOIN isanteplus.patient_on_arv parv ON enc.patient_id = parv.patient_id
WHERE entype.uuid = '9d0113c6-f23a-4461-8428-7e9a7344f2ba'
  AND ob.concept_id = 161555 AND ob.value_coded = 159492
  AND ob.voided = 0 AND enc.voided = 0
GROUP BY enc.patient_id
ON DUPLICATE KEY UPDATE last_updated_date = VALUES(last_updated_date);

/* Arrêtés = 3 */
INSERT INTO patient_status_arv_day (patient_id, id_status, start_date, encounter_id, last_updated_date, date_started_status)
SELECT enc.patient_id, 3, MAX(DATE(enc.encounter_datetime)), enc.encounter_id, now(), now()
FROM _tmp_encounter enc
INNER JOIN _tmp_encounter_type entype ON enc.encounter_type = entype.encounter_type_id
INNER JOIN isanteplus.obs_by_day ob ON enc.encounter_id = ob.encounter_id AND enc.patient_id = ob.person_id
INNER JOIN isanteplus.obs_by_day ob2 ON ob.encounter_id = ob2.encounter_id
INNER JOIN isanteplus.patient_on_arv parv ON enc.patient_id = parv.patient_id
WHERE entype.uuid = '9d0113c6-f23a-4461-8428-7e9a7344f2ba'
  AND ob.concept_id = 161555 AND ob.value_coded = 1667
  AND ob.voided = 0 AND enc.voided = 0
  AND ob2.concept_id = 1667 AND ob2.value_coded IN (115198, 159737)
GROUP BY enc.patient_id
ON DUPLICATE KEY UPDATE last_updated_date = VALUES(last_updated_date);


/*=============================================================================
  PHASE 10: Finalisation statut ARV
=============================================================================*/

/* Mise à jour raison d'arrêt */
UPDATE patient_status_arv_day psarv
INNER JOIN discontinuation_reason dreason ON psarv.patient_id = dreason.patient_id
SET psarv.dis_reason = dreason.reason
WHERE psarv.start_date <= dreason.visit_date;

/* Supprimer enfants exposés du statut ARV */
DELETE patient_status_arv_day FROM patient_status_arv_day
INNER JOIN exposed_infants_day ON patient_status_arv_day.patient_id = exposed_infants_day.patient_id;

/* Mise à jour statut dans la table patient */
UPDATE patient p
INNER JOIN patient_status_arv_day psa ON p.patient_id = psa.patient_id
INNER JOIN (
  SELECT psarv.patient_id, MAX(psarv.last_updated_date) AS last_updated_date
  FROM patient_status_arv_day psarv GROUP BY psarv.patient_id
) B ON psa.patient_id = B.patient_id AND DATE(psa.last_updated_date) = DATE(B.last_updated_date)
SET p.arv_status = psa.id_status;

/* Transfert vers patient_status_arv permanent */
DELETE patient_status_arv FROM patient_status_arv
INNER JOIN patient_status_arv_day psad
  ON patient_status_arv.patient_id = psad.patient_id
  AND patient_status_arv.id_status = psad.id_status
  AND patient_status_arv.start_date = psad.start_date
  AND DATE(patient_status_arv.date_started_status) = DATE(psad.date_started_status);

INSERT INTO patient_status_arv (patient_id, id_status, start_date, encounter_id, last_updated_date, date_started_status)
SELECT ps.patient_id, ps.id_status, ps.start_date, ps.encounter_id, ps.last_updated_date,
  MAX(ps.date_started_status)
FROM patient_status_arv_day ps
GROUP BY ps.patient_id
ON DUPLICATE KEY UPDATE last_updated_date = VALUES(last_updated_date);


/*=============================================================================
  PHASE 11: Regimen PEPFAR du jour
=============================================================================*/

INSERT INTO last_obs (obs_id, last_updated_date)
SELECT MAX(obs_id), now() FROM obs_by_day
ON DUPLICATE KEY UPDATE last_updated_date = now();

DROP TEMPORARY TABLE IF EXISTS pepfarTableTemp_day;
DROP TEMPORARY TABLE IF EXISTS oneDrugRegimenPrefixTemp_day;
DROP TEMPORARY TABLE IF EXISTS twoDrugRegimenPrefixTemp_day;

CREATE TEMPORARY TABLE pepfarTableTemp_day (
  location_id int(11), patient_id int(11), visit_date datetime,
  regimen varchar(255), rx_or_prophy int(11)
);

CREATE TEMPORARY TABLE oneDrugRegimenPrefixTemp_day (
  location_id int(11), patient_id int(11), visit_date datetime,
  drugID1 int(11), rx_or_prophy int(11)
);

INSERT INTO oneDrugRegimenPrefixTemp_day
SELECT d1.location_id, d1.patient_id, d1.visit_date, d1.drug_id, d1.rx_or_prophy
FROM patient_prescription_day d1
INNER JOIN patient p ON d1.patient_id = p.patient_id
INNER JOIN (SELECT DISTINCT drugID1 FROM regimen) r ON r.drugID1 = d1.drug_id
WHERE d1.arv_drug = 1065 AND d1.voided <> 1;

INSERT INTO pepfarTableTemp_day (location_id, patient_id, visit_date, regimen, rx_or_prophy)
SELECT DISTINCT location_id, patient_id, visit_date, shortname, rx_or_prophy
FROM oneDrugRegimenPrefixTemp_day d1
INNER JOIN regimen r ON r.drugID1 = d1.drugID1
WHERE r.drugID2 = 0 AND r.drugID3 = 0;

CREATE TEMPORARY TABLE twoDrugRegimenPrefixTemp_day (
  location_id int(11), patient_id int(11), visit_date datetime,
  drugID1 int(11), drugID2 int(11), rx_or_prophy int(11)
);

INSERT INTO twoDrugRegimenPrefixTemp_day
SELECT location_id, patient_id, visit_date, d1.drugID1, d2.drug_id, d1.rx_or_prophy
FROM oneDrugRegimenPrefixTemp_day d1
INNER JOIN patient_prescription_day d2 USING (location_id, patient_id, visit_date)
INNER JOIN (SELECT DISTINCT drugID1, drugID2 FROM regimen) r
  ON r.drugID1 = d1.drugID1 AND r.drugID2 = d2.drug_id
WHERE d2.voided <> 1;

INSERT INTO pepfarTableTemp_day (location_id, patient_id, visit_date, regimen, rx_or_prophy)
SELECT DISTINCT location_id, patient_id, visit_date, shortname, prefix.rx_or_prophy
FROM twoDrugRegimenPrefixTemp_day prefix
INNER JOIN regimen r ON prefix.drugID1 = r.drugID1 AND prefix.drugID2 = r.drugID2
WHERE r.drugID3 = 0;

INSERT INTO pepfarTableTemp_day (location_id, patient_id, visit_date, regimen, rx_or_prophy)
SELECT DISTINCT location_id, patient_id, visit_date, shortname, prefix.rx_or_prophy
FROM twoDrugRegimenPrefixTemp_day prefix
INNER JOIN patient_prescription_day USING (location_id, patient_id, visit_date)
INNER JOIN regimen r ON prefix.drugID1 = r.drugID1
  AND prefix.drugID2 = r.drugID2 AND patient_prescription_day.drug_id = r.drugID3
WHERE r.drugID3 != 0 AND patient_prescription_day.voided <> 1;

INSERT INTO pepfarTable (location_id, patient_id, visit_date, regimen, rx_or_prophy, last_updated_date)
SELECT p.location_id, p.patient_id, p.visit_date, p.regimen, p.rx_or_prophy, now()
FROM pepfarTableTemp_day p
ON DUPLICATE KEY UPDATE
  rx_or_prophy = p.rx_or_prophy,
  last_updated_date = now();

DROP TEMPORARY TABLE IF EXISTS oneDrugRegimenPrefixTemp_day;
DROP TEMPORARY TABLE IF EXISTS twoDrugRegimenPrefixTemp_day;
DROP TEMPORARY TABLE IF EXISTS pepfarTableTemp_day;


/*=============================================================================
  PHASE 12: Écriture vers openmrs (transaction courte et ciblée)
=============================================================================*/

/* Écriture des données regimen vers openmrs.isanteplus_patient_arv */
INSERT INTO openmrs.isanteplus_patient_arv (patient_id, arv_regimen, date_created, date_changed)
SELECT pft.patient_id, pft.regimen, pft.visit_date, now()
FROM pepfarTable pft
INNER JOIN _tmp_patient po ON pft.patient_id = po.patient_id
INNER JOIN (
  SELECT pf.patient_id, MAX(pf.visit_date) AS visit_date_regimen
  FROM pepfarTable pf GROUP BY pf.patient_id
) B ON pft.patient_id = B.patient_id AND pft.visit_date = B.visit_date_regimen
ON DUPLICATE KEY UPDATE
  arv_regimen = pft.regimen,
  date_changed = now();

/* Écriture statut ARV vers openmrs.isanteplus_patient_arv */
INSERT INTO openmrs.isanteplus_patient_arv
(patient_id, arv_status, date_started_arv, next_visit_date, date_created, date_changed)
SELECT p.patient_id, asl.name_fr, DATE(p.date_started_arv),
  DATE(p.next_visit_date), now(), now()
FROM isanteplus.patient p
INNER JOIN _tmp_patient po ON p.patient_id = po.patient_id
LEFT OUTER JOIN isanteplus.arv_status_loockup asl ON p.arv_status = asl.id
WHERE p.arv_status IS NOT NULL
  OR p.next_visit_date IS NOT NULL
  OR p.date_started_arv IS NOT NULL
ON DUPLICATE KEY UPDATE
  arv_status = asl.name_fr,
  date_started_arv = p.date_started_arv,
  next_visit_date = p.next_visit_date,
  date_changed = now();


/*=============================================================================
  PHASE 13: Nettoyage
=============================================================================*/

TRUNCATE TABLE patient_dispensing_day;
TRUNCATE TABLE patient_prescription_day;
TRUNCATE TABLE patient_status_arv_day;
TRUNCATE TABLE last_obs;
TRUNCATE TABLE obs_by_day;

/* Nettoyage tables temporaires */
DROP TEMPORARY TABLE IF EXISTS _tmp_obs;
DROP TEMPORARY TABLE IF EXISTS _tmp_obs_2;
DROP TEMPORARY TABLE IF EXISTS _tmp_obs_full;
DROP TEMPORARY TABLE IF EXISTS _tmp_obs_full_2;
DROP TEMPORARY TABLE IF EXISTS _tmp_encounter;
DROP TEMPORARY TABLE IF EXISTS _tmp_encounter_type;
DROP TEMPORARY TABLE IF EXISTS _tmp_visit;
DROP TEMPORARY TABLE IF EXISTS _tmp_visit_2;
DROP TEMPORARY TABLE IF EXISTS _tmp_person_name;
DROP TEMPORARY TABLE IF EXISTS _tmp_person;
DROP TEMPORARY TABLE IF EXISTS _tmp_patient;
DROP TEMPORARY TABLE IF EXISTS _tmp_concept;
DROP TEMPORARY TABLE IF EXISTS _tmp_latest_visit;


/*=============================================================================
  EVENT: Exécution toutes les 10 minutes
  Note: L'EVENT appelle maintenant un script plat via source ou
  peut être remplacé par un cron externe pour plus de contrôle.

  Pour utiliser avec un EVENT MySQL, encapsuler dans une procédure:
=============================================================================*/

DELIMITER $$
DROP PROCEDURE IF EXISTS call_all_procedure_day_v2$$
CREATE PROCEDURE call_all_procedure_day_v2()
BEGIN
  /* Cette procédure est un wrapper pour l'EVENT scheduler.
     Le contenu réel est dans le script plat ci-dessus.
     Pour l'utiliser avec l'EVENT, le script doit être chargé
     en tant que procédure stockée ou appelé via un cron externe.

     Recommandation: utiliser un cron externe au lieu de l'EVENT MySQL
     pour un meilleur contrôle et monitoring.
  */
  SELECT 'Use external cron or load script directly' AS note;
END$$
DELIMITER ;

/* Désactiver l'ancien EVENT */
DROP EVENT IF EXISTS patient_status_arv_day_event;

/* Créer le nouvel EVENT (optionnel - préférer un cron externe) */
/*
CREATE EVENT IF NOT EXISTS patient_status_arv_day_event_v2
ON SCHEDULE EVERY 10 MINUTE
STARTS now()
DO
  CALL call_all_procedure_day_v2();
*/
