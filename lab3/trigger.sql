CREATE OR REPLACE FUNCTION check_and_calculate_distance()
    RETURNS TRIGGER AS
$function$
DECLARE
    calculated_distance bigint;
    spaceships_type     spaceship_type;
BEGIN
    SELECT ROUND(SQRT(
            POWER(dest.x - orig.x, 2) +
            POWER(dest.y - orig.y, 2) +
            POWER(dest.z - orig.z, 2)
                 ))::BIGINT
    INTO calculated_distance
    FROM coordinates orig,
         coordinates dest
    WHERE orig.id = NEW.origin_coordinates_id
      AND dest.id = NEW.destination_coordinates_id;

    SELECT type
    INTO spaceships_type
    FROM spaceships
    WHERE id = NEW.spaceship_id
    LIMIT 1;

    IF spaceships_type = liner THEN
        calculated_distance = calculated_distance * 1.1;
    ELSEIF spaceships_type = dreadnought THEN
        calculated_distance = calculated_distance * 2;
    ELSEIF spaceships_type = commercial THEN
        calculated_distance = calculated_distance * 1.5;
    ELSE
        calculated_distance = calculated_distance * 1.25;
    END IF;

    IF calculated_distance < NEW.distance THEN
        calculated_distance = NEW.distance;
    END IF;
    NEW.distance = calculated_distance;
    return NEW;
END;
$function$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER check_and_calculate_distance
    BEFORE INSERT OR UPDATE OF origin_coordinates_id, destination_coordinates_id, distance
    ON trajectory
    FOR EACH ROW
EXECUTE FUNCTION check_and_calculate_distance();
