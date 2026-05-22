-- creature_movement_override  ·  TrinityCore Master -> AzerothCore 3.3.5a
--
-- One creature_movement_override row per map @map_id spawn that has one.
-- SpawnId is a spawn guid, resolved at apply time through creature_guid_map
-- to the guid 04_creature.sql assigned -- that file must be applied first.
-- A spawn not converted matches no creature_guid_map entry and inserts nothing.
--
-- ============================================================================
-- FIELD MAPPING  (TC Master -> AC 3.3.5a creature_movement_override)
-- ============================================================================
--
-- Both cores have this table, but the column sets differ -- AC's is the
-- per-spawn twin of creature_template_movement; TC Master's is smaller.
--
-- Remapped:
--   SpawnId   spawn guid (TC bigint -> AC int), via creature_guid_map.
--
-- Carried 1:1 (nullable; a NULL means "no override, use the default"):
--   Chase, Random, InteractionPauseTimer.
--
-- AC-only -- TC's per-spawn override does not carry these (they live in the
-- per-template creature_template_movement). Written NULL = no override:
--   Ground, Swim, Flight, Rooted.
--
-- Dropped -- TC-only:
--   HoverInitiallyEnabled   AC's creature_movement_override has no hover
--                           column. Hover is not flight, so it is not folded
--                           into Flight; in 3.3.5 hover is a creature_addon
--                           bytes1 flag, set there if needed.

SELECT CONCAT(
  'INSERT IGNORE INTO `creature_movement_override` ',
  '(`SpawnId`,`Ground`,`Swim`,`Flight`,`Rooted`,`Chase`,`Random`,',
  '`InteractionPauseTimer`) ',
  'SELECT `new_guid`,NULL,NULL,NULL,NULL,',
  CONCAT_WS(',',
    IFNULL(o.`Chase`,  'NULL'),                  -- Chase
    IFNULL(o.`Random`, 'NULL'),                  -- Random
    IFNULL(o.`InteractionPauseTimer`, 'NULL')    -- InteractionPauseTimer
  ),
  ' FROM `creature_guid_map` WHERE `old_guid` = ', o.`SpawnId`, ';'
) AS `statement`
FROM `creature_movement_override` o
JOIN `creature` c ON c.`guid` = o.`SpawnId`
WHERE c.`map` = @map_id
ORDER BY o.`SpawnId`;
