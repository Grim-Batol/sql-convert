-- creature_summon_groups  ·  TrinityCore Master -> AzerothCore 3.3.5a
--
-- Summon groups owned by content on map @map_id. summonerType selects which
-- side of the universe summonerId refers to:
--   0 = SUMMONER_TYPE_CREATURE     creature_template.entry
--   1 = SUMMONER_TYPE_GAMEOBJECT   gameobject_template.entry
--   2 = SUMMONER_TYPE_MAP          map.id
-- Scope: every row whose summoner is part of map @map_id, across the three
-- types.
--
-- Note: the source table carries no primary key, and the AC schema does not
-- declare one either. INSERT IGNORE therefore does not deduplicate -- a
-- re-apply would accumulate duplicates. Re-runs should clean the in-scope
-- rows first if the source set may have changed.
--
-- ============================================================================
-- FIELD MAPPING  (TC Master -> AC 3.3.5a creature_summon_groups)
-- ============================================================================
-- The schemas match column-for-column -- every field is carried 1:1:
--   summonerId, summonerType, groupId, entry, position_x, position_y,
--   position_z, orientation, summonType, summonTime, Comment.
-- summonType (TempSummonType 1..8) -- identical enum in both cores.
-- summonerId is an entry / map id, never a spawn guid -- no remap needed.

SELECT CONCAT(
  'INSERT IGNORE INTO `creature_summon_groups` ',
  '(`summonerId`,`summonerType`,`groupId`,`entry`,`position_x`,`position_y`,',
  '`position_z`,`orientation`,`summonType`,`summonTime`,`Comment`) VALUES (',
  CONCAT_WS(',',
    s.`summonerId`,
    s.`summonerType`,
    s.`groupId`,
    s.`entry`,
    s.`position_x`,
    s.`position_y`,
    s.`position_z`,
    s.`orientation`,
    s.`summonType`,
    s.`summonTime`,
    QUOTE(s.`Comment`)
  ),
  ');'
) AS `statement`
FROM `creature_summon_groups` s
WHERE
  (s.`summonerType` = 0
    AND s.`summonerId` IN (SELECT DISTINCT `id` FROM `creature`   WHERE `map` = @map_id))
  OR (s.`summonerType` = 1
    AND s.`summonerId` IN (SELECT DISTINCT `id` FROM `gameobject` WHERE `map` = @map_id))
  OR (s.`summonerType` = 2
    AND s.`summonerId` = @map_id)
ORDER BY s.`summonerType`, s.`summonerId`, s.`groupId`, s.`entry`;
