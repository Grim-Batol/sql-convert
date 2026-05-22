-- creature_addon  ·  TrinityCore Master -> AzerothCore 3.3.5a
--
-- Links each map @map_id creature that follows a waypoint path to that path:
-- it writes creature_addon.guid + path_id only; every other creature_addon
-- column takes its AzerothCore default.
--
-- The guid is resolved at apply time through creature_guid_map, so the row
-- carries the spawn guid 04_creature.sql assigned -- that file must be applied
-- before this one. INSERT IGNORE keeps an existing creature_addon row intact.

SELECT CONCAT(
  'INSERT IGNORE INTO `creature_addon` (`guid`,`path_id`) ',
  'SELECT `new_guid`, ', a.`PathId`,
  ' FROM `creature_guid_map` WHERE `old_guid` = ', c.`guid`, ';'
) AS `statement`
FROM `creature_addon` a
JOIN `creature` c ON c.`guid` = a.`guid`
WHERE c.`map` = @map_id AND a.`PathId` > 0
ORDER BY c.`guid`;
