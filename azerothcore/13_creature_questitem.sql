-- creature_questitem  ·  TrinityCore Master -> AzerothCore 3.3.5a
--
-- The quest items linked to a creature (Idx 0..3), for the creature_template
-- entries spawned on map @map_id.
--
-- ----------------------------------------------------------------------------
-- WHY A DELETE, NOT REPLACE
-- ----------------------------------------------------------------------------
-- Same reasoning as creature_queststarter / creature_questender: the converted
-- set must be authoritative over any stock rows the target already carries for
-- these creature entries. This file DELETEs every creature_questitem row of
-- every creature entry this conversion places on map @map_id, then inserts the
-- converted set. The DELETE reads the target's `creature` table, so
-- 04_creature.sql must be applied before this file. If a creature has no
-- converted quest item, the DELETE alone still clears its stale rows.
--
-- ============================================================================
-- FIELD MAPPING  (TC Master -> AC 3.3.5a creature_questitem)
-- ============================================================================
--   CreatureEntry, Idx, ItemId   carried 1:1. ItemId is an item_template
--                                entry; a Legion item absent from the target
--                                item_template is rejected at load.
--   DifficultyID  TC keys rows by difficulty; 3.3.5 has none -- only the
--                 DifficultyID 0 rows are taken, and the column is dropped.
--   VerifiedBuild present in the TC table; omitted (AC defaults it).

SELECT `statement` FROM (
  -- sort 0: wipe the stale quest items of every creature placed on the map
  SELECT 0 AS `sort`, 0 AS `k1`, 0 AS `k2`,
    CONCAT('DELETE FROM `creature_questitem` WHERE `CreatureEntry` IN ',
           '(SELECT DISTINCT `id1` FROM `creature` WHERE `map` = ', @map_id, ');')
    AS `statement`
  UNION ALL
  -- sort 1: the converted quest items (base difficulty only)
  SELECT 1 AS `sort`, qi.`CreatureEntry` AS `k1`, qi.`Idx` AS `k2`,
    CONCAT('INSERT IGNORE INTO `creature_questitem` ',
           '(`CreatureEntry`,`Idx`,`ItemId`) VALUES (',
           qi.`CreatureEntry`, ',', qi.`Idx`, ',', qi.`ItemId`, ');') AS `statement`
  FROM `creature_questitem` qi
  WHERE qi.`DifficultyID` = 0
    AND qi.`CreatureEntry` IN (SELECT DISTINCT `id` FROM `creature` WHERE `map` = @map_id)
) `x`
ORDER BY `sort`, `k1`, `k2`;
