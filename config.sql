-- sql-convert — conversion parameters.
-- convert.sh prepends this file to every query, so each query reads these
-- @-variables.

-- Selects the creatures to convert: only creature rows with this creature.map.
SET @map_id := 974;

-- creature_template -----------------------------------------------------------
-- Written to both minlevel and maxlevel. Modern TrinityCore creatures scale by
-- ContentTuning and store no fixed level, so a flat value is used.
SET @creature_level := 80;

-- creature --------------------------------------------------------------------
-- spawnMask: difficulty bitmask written to every spawn -- 1 = 10-man-normal
-- (and every non-instanced / open-world map), 2 = 25N, 4 = 10HC, 8 = 25HC,
-- 15 = all. TrinityCore stores the per-spawn difficulty set in
-- creature.spawnDifficulties instead; this constant is chosen per conversion.
SET @spawn_mask := 1;
-- phaseMask: phase bitmask written to every spawn. 3.3.5a phasing is a plain
-- bitmask (1 = base phase); TrinityCore's PhaseId/PhaseGroup do not map onto it.
SET @phase_mask := 1;
