CREATE OR REPLACE FUNCTION check_and_calculate_distance()
    RETURNS TRIGGER AS
$$
DECLARE
    calculated_distance bigint;
    current_distance    bigint;
BEGIN
    SELECT ROUND(SQRT(
                         POWER(dest.x - orig.x, 2) +
                         POWER(dest.y - orig.y, 2) +
                         POWER(dest.z - orig.z, 2)
                 ) * 1.25)::BIGINT
    INTO calculated_distance
    FROM coordinates orig,
         coordinates dest
    WHERE orig.id = NEW.origin_coordinates_id
      AND dest.id = NEW.destination_coordinates_id;

    SELECT t.distance FROM trajectory t INTO current_distance;

    IF calculated_distance < NEW.distance THEN calculated_distance = NEW.distance; END IF;
    NEW.distance = calculated_distance;
    return NEW;
END;
$$ language plpgsql;

CREATE TRIGGER check_and_calculate_distance
    BEFORE INSERT OR UPDATE OF origin_coordinates_id, destination_coordinates_id, distance
    ON trajectory
    FOR EACH ROW
EXECUTE FUNCTION check_and_calculate_distance();
