BEGIN;

CREATE TEMPORARY TABLE bad_new_tiles ( tile_x INT, tile_y INT );

--
-- Manually note which coastline tiles should be held back due to new errors.
--
COPY bad_new_tiles FROM STDIN;
116	246
94	234
140	260
58	266
\.

--
-- Delete everything from the old good coastline that has a good replacement.
--
DELETE FROM coastline
WHERE gid NOT IN
(
    SELECT c.gid
    FROM coastline AS c, bad_new_tiles AS t
    WHERE c.tile_x = t.tile_x
      AND c.tile_y = t.tile_y
);

--
-- Copy everything from the newly-processed coastline that has a good replacement.
--
INSERT INTO coastline
    (source, error, tile_x, tile_y, the_geom)
    SELECT '2011-12-15', error, tile_x, tile_y, the_geom
    FROM processed_p
    WHERE gid NOT IN
    (
        SELECT p.gid
        FROM processed_p AS p, bad_new_tiles AS t
        WHERE p.tile_x = t.tile_x
          AND p.tile_y = t.tile_y
    );

COMMIT;
