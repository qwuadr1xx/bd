\set random_person random(1, 10000000)
\set random_country random(1, 10000)

UPDATE itmo_bd.person_citizen 
SET country_id = :random_country 
WHERE person_id = :random_person;
