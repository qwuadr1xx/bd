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
CREATE TYPE spaceship_type AS ENUM ('liner', 'cargo', 'commercial', 'dreadnought', 'battleship');

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
    CONSTRAINT pk_character_peculiarity
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
    id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name           VARCHAR(63) NOT NULL,
    max_speed      INTEGER,
    capacity       INTEGER,
    type           spaceship_type,
    captain_id     BIGINT      NOT NULL,
    captain_name   VARCHAR(63) NOT NULL,
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

CREATE INDEX idx_spaceships_planet_history_spaceship_id ON spaceships_planet_history (spaceship_id);
CREATE INDEX idx_spaceships_planet_history_planet_id ON spaceships_planet_history (planet_id);
CREATE INDEX idx_spaceship_planet_history ON spaceships_planet_history (spaceship_id, planet_id);

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
