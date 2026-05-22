-- creature_model_info  ·  TrinityCore Master -> AzerothCore 3.3.5a
--
-- One creature_model_info row per CreatureDisplayID used by the in-scope
-- creatures' models. The worldserver rejects a creature whose display has no
-- creature_model_info row, so this table must be applied before the spawns.
--
-- Scope: the CreatureDisplayIDs of creature_template_model rows with Idx <= 3
-- (3.3.5 supports at most 4 models, matching 02_creature_template_model) for
-- the creature_template entries spawned on map @map_id.
--
-- ============================================================================
-- FIELD MAPPING  (TC Master -> AC 3.3.5a creature_model_info)
-- ============================================================================
--
-- Carried 1:1:
--   DisplayID, BoundingRadius, CombatReach.
--
-- Synthesised -- AC has the column, TC Master does not:
--   Gender    TC Master dropped this column (the modern core reads gender
--             from the client db2). With no source value it is set to 2
--             (None); the AC docs warn against setting a gender without
--             sniff data, so "None" is the correct default.
--
-- Overridden:
--   DisplayID_Other_Gender  the male<->female display swap counterpart. TC
--             still carries it, but the core only consults it when Gender is
--             0 or 1 -- with Gender = 2 it is inert. It is written 0: keeping
--             the TC value would be half a gender system with no gender to
--             drive it.
--
-- Dropped:
--   VerifiedBuild  present in the TC table; the AC 3.3.5a creature_model_info
--                  documents only the five columns above, so it is omitted.

SELECT CONCAT(
  'INSERT IGNORE INTO `creature_model_info` ',
  '(`DisplayID`,`BoundingRadius`,`CombatReach`,`Gender`,',
  '`DisplayID_Other_Gender`) VALUES (',
  CONCAT_WS(',',
    mi.`DisplayID`,        -- DisplayID
    mi.`BoundingRadius`,   -- BoundingRadius
    mi.`CombatReach`,      -- CombatReach
    2,                     -- Gender: 2 = None (TC dropped the column)
    0                      -- DisplayID_Other_Gender: inert under Gender 2
  ),
  ');'
) AS `statement`
FROM `creature_model_info` mi
WHERE mi.`DisplayID` IN (
  SELECT DISTINCT `CreatureDisplayID`
  FROM `creature_template_model`
  WHERE `CreatureID` IN (
    SELECT DISTINCT `id` FROM `creature` WHERE `map` = @map_id
  )
  AND `Idx` <= 3
)
ORDER BY mi.`DisplayID`;
