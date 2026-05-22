-- creature_template_model  ·  TrinityCore Master -> AzerothCore 3.3.5a
--
-- Builds one `INSERT IGNORE INTO creature_template_model` statement per source
-- row. Scope: the models of the creatures spawned on map @map_id. AzerothCore
-- enforces CHECK (Idx <= 3) — a 3.3.5a creature has at most four models — so
-- rows with a higher Idx are left out.

SELECT CONCAT(
  'INSERT IGNORE INTO `creature_template_model` ',
  '(`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,',
  '`VerifiedBuild`) VALUES (',
  CONCAT_WS(',',
    m.`CreatureID`,           -- CreatureID
    m.`Idx`,                  -- Idx
    m.`CreatureDisplayID`,    -- CreatureDisplayID
    m.`DisplayScale`,         -- DisplayScale
    m.`Probability`,          -- Probability
    0                         -- VerifiedBuild
  ),
  ');'
) AS `statement`
FROM `creature_template_model` m
WHERE m.`CreatureID` IN (
        SELECT DISTINCT `id` FROM `creature` WHERE `map` = @map_id
      )
  AND m.`Idx` <= 3
ORDER BY m.`CreatureID`, m.`Idx`;
