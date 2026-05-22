-- creature_formations  ·  TrinityCore Master -> AzerothCore 3.3.5a
--
-- One creature_formations row per formation member whose member creature is
-- spawned on map @map_id. leaderGUID and memberGUID are spawn guids, resolved
-- at apply time through creature_guid_map to the guids 04_creature.sql
-- assigned -- that file must be applied first. A row whose leader was not
-- converted matches no creature_guid_map entry and inserts nothing.
--
-- ============================================================================
-- FIELD MAPPING  (TC Master -> AC 3.3.5a creature_formations)
-- ============================================================================
--
-- The column set is identical in both cores; only the guid columns need work.
--
-- Remapped:
--   leaderGUID / memberGUID   spawn guids (TC bigint -> AC int). Each is
--                             looked up in creature_guid_map; the leader's
--                             own self-row (leaderGUID = memberGUID), which
--                             AC requires for the group to work, is carried
--                             over from the source.
--
-- Carried 1:1:
--   dist      leader<->member distance. AC's creature_formations_chk_1 CHECK
--             rejects a negative value.
--   angle     leader<->member angle, in degrees in both cores (0..360); the
--             same CHECK applies.
--   groupAI   assist / follow bitmask -- the values (0/1/2/3/512/515, plus
--             the AC-only evade flags) carry the same meaning in both cores.
--   point_1   leader path points that flip the member's side on a straight
--   point_2   return path (TC smallint -> AC int -- a plain widening).

SELECT CONCAT(
  'INSERT IGNORE INTO `creature_formations` ',
  '(`leaderGUID`,`memberGUID`,`dist`,`angle`,`groupAI`,`point_1`,`point_2`) ',
  'SELECT l.`new_guid`, m.`new_guid`, ',
  CONCAT_WS(',',
    f.`dist`,        -- dist
    f.`angle`,       -- angle
    f.`groupAI`,     -- groupAI
    f.`point_1`,     -- point_1
    f.`point_2`      -- point_2
  ),
  ' FROM `creature_guid_map` l, `creature_guid_map` m',
  ' WHERE l.`old_guid` = ', f.`leaderGUID`,
  ' AND m.`old_guid` = ', f.`memberGUID`, ';'
) AS `statement`
FROM `creature_formations` f
JOIN `creature` c ON c.`guid` = f.`memberGUID`
WHERE c.`map` = @map_id
ORDER BY f.`leaderGUID`, f.`memberGUID`;
