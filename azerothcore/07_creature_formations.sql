-- creature_formations  ·  TrinityCore Master -> AzerothCore 3.3.5a
--
-- Builds one `INSERT IGNORE INTO creature_formations` statement per formation
-- member spawned on map @map_id. leaderGUID and memberGUID are resolved at
-- apply time through creature_guid_map to the spawn guids 04_creature.sql
-- assigned -- that file must be applied before this one. A row whose leader
-- was not converted matches no creature_guid_map entry and inserts nothing.
--
-- groupAI is carried as-is: the TrinityCore values (0/1/2/3/512/515) are the
-- same in AzerothCore.

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
