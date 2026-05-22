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
-- Written to spawnMask and phaseMask on every spawn. 3.3.5a has no phasing.
SET @spawn_mask := 1;
SET @phase_mask := 1;
