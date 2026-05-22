-- creature_model_info  ·  TrinityCore Master -> AzerothCore 3.3.5a
--
-- Builds one `INSERT IGNORE INTO creature_model_info` statement per source row.
-- Scope: every CreatureDisplayID used by the in-scope creatures' models.
-- AzerothCore rejects a creature whose display has no creature_model_info row,
-- so this table must be applied before the spawns.
-- Gender is forced to 2 (genderless) and DisplayID_Other_Gender to 0 — the
-- TrinityCore table carries no gender column, so no gender swap is intended.

SELECT CONCAT(
  'INSERT IGNORE INTO `creature_model_info` ',
  '(`DisplayID`,`BoundingRadius`,`CombatReach`,`Gender`,',
  '`DisplayID_Other_Gender`) VALUES (',
  CONCAT_WS(',',
    mi.`DisplayID`,        -- DisplayID
    mi.`BoundingRadius`,   -- BoundingRadius
    mi.`CombatReach`,      -- CombatReach
    2,                     -- Gender: 2 = genderless
    0                      -- DisplayID_Other_Gender: no gender swap
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
)
ORDER BY mi.`DisplayID`;
