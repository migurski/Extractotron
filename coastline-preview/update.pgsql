BEGIN;

CREATE TEMPORARY TABLE bad_new_tiles ( tile_x INT, tile_y INT );

COPY bad_new_tiles FROM STDIN;
116	182
117	182
118	182
119	182
120	182
121	182
116	181
117	181
118	181
119	181
120	181
121	181
116	180
117	180
118	180
119	180
120	180
121	180
117	179
118	179
119	179
120	179
121	179
117	207
118	207
111	238
115	244
115	254
75	228
88	267
195	278
195	270
196	265
198	265
190	253
183	215
243	190
244	188
282	216
283	215
286	209
292	219
318	211
346	238
346	239
318	335
236	303
119	221
\.

DELETE FROM coastline
WHERE gid NOT IN
(
    SELECT c.gid
    FROM coastline AS c, bad_new_tiles AS t
    WHERE c.tile_x = t.tile_x
      AND c.tile_y = t.tile_y
);

INSERT INTO coastline
    (source, error, tile_x, tile_y, the_geom)
    SELECT '2011-12-10', error, tile_x, tile_y, the_geom
    FROM processed_p
    WHERE gid NOT IN
    (
        SELECT p.gid
        FROM processed_p AS p, bad_new_tiles AS t
        WHERE p.tile_x = t.tile_x
          AND p.tile_y = t.tile_y
    );

COMMIT;
