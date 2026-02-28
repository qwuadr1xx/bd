DROP TABLE IF EXISTS trajectory CASCADE;
DROP TABLE IF EXISTS coordinates CASCADE;
DROP TABLE IF EXISTS crew CASCADE;
DROP TABLE IF EXISTS spaceships_planet_history CASCADE;
DROP TABLE IF EXISTS characters_planet_history CASCADE;
DROP TABLE IF EXISTS spaceships CASCADE;
DROP TABLE IF EXISTS character_peculiarity CASCADE;
DROP TABLE IF EXISTS peculiarity CASCADE;
DROP TABLE IF EXISTS characters CASCADE;
DROP TABLE IF EXISTS planets CASCADE;

DROP TYPE IF EXISTS species CASCADE;
DROP TYPE IF EXISTS spaceship_type CASCADE;

CREATE TYPE species AS ENUM ('robot', 'human', 'humanoid', 'reptile');
CREATE TYPE spaceship_type AS ENUM ('liner', 'cargo', 'commerical', 'dreadnought', 'battleship');

CREATE TABLE IF NOT EXISTS planets
(
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name            VARCHAR(63) NOT NULL,
    population_size BIGINT,
    radius          INTEGER,
    pressure        REAL,
    temperature     REAL,
    humidity        REAL
);

CREATE TABLE IF NOT EXISTS characters
(
    id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name           VARCHAR(63) NOT NULL,
    type           species     NOT NULL,
    age            INTEGER DEFAULT 0,
    home_planet_id BIGINT,
    alive          boolean     NOT NULL,
    CONSTRAINT fk_planet_id
        FOREIGN KEY (home_planet_id) REFERENCES planets (id)
);

CREATE INDEX idx_home_planet_id ON characters (home_planet_id);

CREATE TABLE IF NOT EXISTS characters_planet_history
(
    character_id  BIGINT,
    planet_id     BIGINT,
    date_of_visit TIMESTAMP DEFAULT NOW(),
    is_there      BOOLEAN,
    CONSTRAINT characters_planet_history_pk
        PRIMARY KEY (character_id, planet_id, date_of_visit),
    CONSTRAINT characters_planet_history_character_id
        FOREIGN KEY (character_id) REFERENCES characters (id),
    CONSTRAINT characters_planet_history_planet_id
        FOREIGN KEY (planet_id) REFERENCES planets (id)
);

CREATE INDEX idx_characters_planet_history_character_id ON characters_planet_history (character_id);
CREATE INDEX idx_characters_planet_history_planet_id ON characters_planet_history (planet_id);
CREATE INDEX idx_character_planet_history ON characters_planet_history (character_id, planet_id);

CREATE TABLE IF NOT EXISTS peculiarity
(
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    peculiarity VARCHAR(63) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS character_peculiarity
(
    peculiarity_id BIGINT,
    character_id   BIGINT,
    description    TEXT NOT NULL,
    CONSTRAINT pk_character_peculiairty
        PRIMARY KEY (peculiarity_id, character_id),
    CONSTRAINT fk_junction_peculiarity_id
        FOREIGN KEY (peculiarity_id) REFERENCES peculiarity (id) ON DELETE CASCADE,
    CONSTRAINT fk_junction_character_id
        FOREIGN KEY (character_id) REFERENCES characters (id) ON DELETE CASCADE
);

CREATE INDEX idx_junction_characters_peculiarity_id ON character_peculiarity (peculiarity_id);
CREATE INDEX idx_junction_peculiarity_character_id ON character_peculiarity (character_id);

CREATE TABLE IF NOT EXISTS spaceships
(
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name       VARCHAR(63) NOT NULL,
    max_speed  INTEGER,
    capacity   INTEGER,
    type       spaceship_type,
    captain_id BIGINT      NOT NULL,
    CONSTRAINT fk_captain_id
        FOREIGN KEY (captain_id) REFERENCES characters (id)
);

CREATE INDEX idx_captain_id ON spaceships (captain_id);

CREATE TABLE IF NOT EXISTS spaceships_planet_history
(
    spaceship_id  BIGINT,
    planet_id     BIGINT,
    date_of_visit TIMESTAMP DEFAULT NOW(),
    is_there      BOOLEAN,
    CONSTRAINT spaceships_planet_history_pk
        PRIMARY KEY (spaceship_id, planet_id, date_of_visit),
    CONSTRAINT spaceships_planet_history_character_id
        FOREIGN KEY (spaceship_id) REFERENCES spaceships (id),
    CONSTRAINT spaceships_planet_history_planet_id
        FOREIGN KEY (planet_id) REFERENCES planets (id)
);

CREATE INDEX idx_spaceships_planet_history_character_id ON characters_planet_history (character_id);
CREATE INDEX idx_spaceships_planet_history_planet_id ON characters_planet_history (planet_id);
CREATE INDEX idx_spaceship_planet_history ON characters_planet_history (character_id, planet_id);

CREATE TABLE IF NOT EXISTS crew
(
    spaceship_id BIGINT,
    character_id BIGINT,
    role         VARCHAR(63) NOT NULL,
    CONSTRAINT pk_spaceship_character
        PRIMARY KEY (spaceship_id, character_id),
    CONSTRAINT fk_junction_spaceship_id
        FOREIGN KEY (spaceship_id) REFERENCES spaceships (id) ON DELETE CASCADE,
    CONSTRAINT fk_junction_character_id
        FOREIGN KEY (character_id) REFERENCES characters (id) ON DELETE CASCADE
);

CREATE INDEX idx_crews_spaceship_id ON crew (spaceship_id);
CREATE INDEX idx_crews_character_id ON crew (character_id);

CREATE TABLE IF NOT EXISTS coordinates
(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    x  REAL NOT NULL,
    y  REAL NOT NULL,
    z  REAL NOT NULL
);

CREATE TABLE IF NOT EXISTS trajectory
(
    id                         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    spaceship_id               BIGINT,
    origin_coordinates_id      BIGINT,
    destination_coordinates_id BIGINT,
    start_time                 TIMESTAMP,
    end_time                   TIMESTAMP,
    distance                   BIGINT NOT NULL,
    is_safe                    BOOLEAN,
    CONSTRAINT fk_trajectory_spaceship_id
        FOREIGN KEY (spaceship_id) REFERENCES spaceships (id),
    CONSTRAINT fk_origin_coordinates_id
        FOREIGN KEY (origin_coordinates_id) REFERENCES coordinates (id),
    CONSTRAINT fk_destination_coordinates_id
        FOREIGN KEY (destination_coordinates_id) REFERENCES coordinates (id)
);

CREATE INDEX idx_trajectory_of_spaceship_id ON trajectory (spaceship_id);
CREATE INDEX idx_trajectory_origin_coordinates_id ON trajectory (origin_coordinates_id);
CREATE INDEX idx_trajectory_destination_coordinates_id ON trajectory (destination_coordinates_id);

INSERT INTO planets (name, population_size, radius, pressure, temperature, humidity)
VALUES ('Earth', 8000000000, 6400, 101325, 15.1, 0.75),
       ('Mercury', 0, 2400, 0.000015, 167, 0),
       ('Mars', 105148432, 3200, 555, 777, 0.5);

INSERT INTO characters (name, type, age, home_planet_id, alive)
VALUES ('Zakhar', 'human', 19, 1, true),
       ('HAL', 'robot', 34, null, true),
       ('Yasher', 'reptile', 25, 3, true);

INSERT INTO characters_planet_history (character_id, planet_id, date_of_visit, is_there)
VALUES (1, 1, '2007-02-08 10:10:10', true),
       (3, 3, '1990-10-10 10:10:10', false),
       (3, 2, NOW(), true);

INSERT INTO peculiarity (peculiarity)
VALUES ('Broken arm'),
       ('Absence of an eye'),
       ('Lot of tails');

INSERT INTO character_peculiarity (peculiarity_id, character_id, description)
VALUES (1, 1, 'My arm was broken in training.'),
       (3, 3, 'Real a lot of tails');

INSERT INTO spaceships (name, max_speed, capacity, type, captain_id)
VALUES ('Discovery one', 10000, 200, 'liner', 1),
       ('Yasher corabl', 5555, 1000, 'dreadnought', 3);

INSERT INTO spaceships_planet_history (spaceship_id, planet_id, date_of_visit, is_there)
VALUES (2, 1, '2000-1-1 15:15:15', false),
       (2, 2, '2005-11-11 11:11:11', false),
       (2, 3, NOW(), true),
       (1, 1, NOW(), true);

INSERT INTO crew (spaceship_id, character_id, role)
VALUES (1, 1, 'Captain'),
       (1, 2, 'AI'),
       (2, 3, 'Captain');

INSERT INTO coordinates (x, y, z)
VALUES (100, 200, 300),
       (232030, 5235344, 8243431);

INSERT INTO trajectory (spaceship_id, origin_coordinates_id, destination_coordinates_id, start_time, end_time, distance,
                        is_safe)
VALUES (1, 1, 2, '1997-10-10 12:00:00', '2000-10-10 14:10:10', 10000000, true);

INSERT INTO characters (name, type, age, home_planet_id, alive)
VALUES ('EEE', 'human', 28, null, true);
INSERT INTO crew (spaceship_id, character_id, role)
VALUES (1, 4, 'lll');
INSERT INTO characters_planet_history (character_id, planet_id, is_there)
VALUES (4, 1, false),
       (4, 3, true);

SELECT characters.*, spaceships.id, spaceships.captain_id, crew.role
FROM characters
         INNER JOIN crew ON crew.character_id = characters.id
         INNER JOIN spaceships ON spaceships.id = crew.spaceship_id
WHERE characters.id IN (SELECT characters_planet_history.character_id
                        FROM characters_planet_history
                        WHERE planet_id IN (1, 3)
                          AND planet_id NOT IN (2))
  AND characters.age > 26
  AND characters.type = 'human'
GROUP BY crew.role, characters.id, spaceships.id, spaceships.captain_id, spaceships.max_speed
ORDER BY spaceships.max_speed DESC;
