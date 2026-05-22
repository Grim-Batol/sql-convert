-- creature_questender  ·  TrinityCore Master -> AzerothCore 3.3.5a
--
-- Which creature_template entries FINISH which quests, for the creatures
-- spawned on map @map_id.
--
-- ----------------------------------------------------------------------------
-- WHY A DELETE, NOT REPLACE
-- ----------------------------------------------------------------------------
-- The target may already carry stock quest links for these creature entries
-- (e.g. its built-in Darkmoon Faire) that are not wanted. REPLACE cannot fix
-- that: `id` and `quest` are the entire row -- both are the primary key, there
-- is no payload column -- so REPLACE and INSERT IGNORE leave the identical
-- state, and neither removes a *different*, stale (id, quest) pair.
--
-- So this file first DELETEs every creature_questender row of every creature
-- entry this conversion places on map @map_id, then inserts the converted set
-- -- making the converted links authoritative. The DELETE reads the target's
-- `creature` table, so 04_creature.sql must be applied before this file.
--
-- ============================================================================
-- FIELD MAPPING  (TC Master -> AC 3.3.5a creature_questender)
-- ============================================================================
--   id, quest      carried 1:1 (creature_template.entry, quest_template.id).
--   VerifiedBuild  present in the TC table; not in the AC creature_questender
--                  -- omitted (a column AC defaults if its build carries it).

SELECT `statement` FROM (
  -- sort 0: wipe the stale links of every creature placed on the map
  SELECT 0 AS `sort`, 0 AS `k1`, 0 AS `k2`,
    CONCAT('DELETE FROM `creature_questender` WHERE `id` IN ',
           '(SELECT DISTINCT `id1` FROM `creature` WHERE `map` = ', @map_id, ');')
    AS `statement`
  UNION ALL
  -- sort 1: the converted quest-end links
  SELECT 1 AS `sort`, qe.`id` AS `k1`, qe.`quest` AS `k2`,
    CONCAT('INSERT IGNORE INTO `creature_questender` (`id`,`quest`) VALUES (',
           qe.`id`, ',', qe.`quest`, ');') AS `statement`
  FROM `creature_questender` qe
  WHERE qe.`id` IN (SELECT DISTINCT `id` FROM `creature` WHERE `map` = @map_id)
) `x`
ORDER BY `sort`, `k1`, `k2`;
