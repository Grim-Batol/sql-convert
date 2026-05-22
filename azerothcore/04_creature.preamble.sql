-- creature spawns, map @map_id — applied on the target (AzerothCore) DB.
--
-- creature_guid_map records the old (TrinityCore) <-> new (target) guid pair,
-- so the source guid is never lost.
CREATE TABLE IF NOT EXISTS `creature_guid_map` (
  `old_guid` BIGINT UNSIGNED NOT NULL PRIMARY KEY,
  `new_guid` BIGINT UNSIGNED NOT NULL,
  UNIQUE KEY `uq_new_guid` (`new_guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- @base holds the target creature table's current highest guid; each spawn
-- below is inserted at @base + N, the way the worldserver hands out guids.
SET @base := (SELECT COALESCE(MAX(`guid`),0) FROM `creature`);
