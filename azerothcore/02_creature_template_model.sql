-- creature_template_model  ·  TrinityCore Master -> AzerothCore 3.3.5a
--
-- One creature_template_model row per model of the creature_template entries
-- spawned on map @map_id.
--
-- AzerothCore enforces CHECK (Idx <= 3) -- a 3.3.5a creature has at most four
-- models -- so rows with a higher Idx are filtered out. Their CreatureDisplayIDs
-- are also excluded from the 03_creature_model_info scope so nothing references
-- a model that does not appear in the converted CreatureDisplayInfo.dbc.
--
-- ============================================================================
-- FIELD MAPPING  (TC Master -> AC 3.3.5a creature_template_model)
-- ============================================================================
--
-- Carried 1:1:
--   CreatureID, Idx, CreatureDisplayID, DisplayScale, Probability.
--   - Probability does not need to be normalised: AC's worldserver rebalances
--     the sum to 1 at startup if it differs.
--   - VerifiedBuild is clamped to the AC smallint range; an out-of-range TC
--     build (> 32767) falls back to 0 ("not parsed").
--
-- Dropped -- forced by AC's CHECK constraint:
--   any source row with Idx > 3. A creature that had 5+ models keeps the first
--   four; the model is also pruned from the displays converted by 03.

SELECT CONCAT(
  'INSERT IGNORE INTO `creature_template_model` ',
  '(`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,',
  '`VerifiedBuild`) VALUES (',
  CONCAT_WS(',',
    m.`CreatureID`,                                       -- CreatureID
    m.`Idx`,                                              -- Idx: 0..3
    m.`CreatureDisplayID`,                                -- CreatureDisplayID
    m.`DisplayScale`,                                     -- DisplayScale
    m.`Probability`,                                      -- Probability
    IF(m.`VerifiedBuild` BETWEEN -32768 AND 32767,        -- VerifiedBuild: AC smallint range
       m.`VerifiedBuild`, 0)
  ),
  ');'
) AS `statement`
FROM `creature_template_model` m
WHERE m.`CreatureID` IN (
        SELECT DISTINCT `id` FROM `creature` WHERE `map` = @map_id
      )
  AND m.`Idx` <= 3
ORDER BY m.`CreatureID`, m.`Idx`;
