-- creature  ·  TrinityCore Master -> AzerothCore 3.3.5a
--
-- Builds, per spawn on map @map_id, two statements: the `creature` row and a
-- `creature_guid_map` row. Both are emitted by 04_creature.preamble.sql first
-- (it creates creature_guid_map and sets @base = MAX(creature.guid)).
--
-- The spawn guid is not carried over: each spawn takes `@base + N`, with N a
-- stable ROW_NUMBER() over the map's spawns ordered by source guid. The
-- creature_guid_map row keeps the old (TC) guid against that `@base + N`.

SELECT CONCAT(
  'INSERT IGNORE INTO `creature` ',
  '(`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,',
  '`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,',
  '`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,',
  '`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,',
  '`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (',
  CONCAT_WS(',',
    CONCAT('@base + ', c.`rn`),          -- guid: handed out above the target's MAX(guid)
    c.`id`,                              -- id1
    0,                                   -- id2
    0,                                   -- id3
    c.`map`,                             -- map
    c.`zoneId`,                          -- zoneId
    c.`areaId`,                          -- areaId
    @spawn_mask,                         -- spawnMask: from config.sql
    @phase_mask,                         -- phaseMask: from config.sql
    c.`equipment_id`,                    -- equipment_id
    c.`position_x`,                      -- position_x
    c.`position_y`,                      -- position_y
    c.`position_z`,                      -- position_z
    c.`orientation`,                     -- orientation
    c.`spawntimesecs`,                   -- spawntimesecs
    c.`wander_distance`,                 -- wander_distance
    c.`currentwaypoint`,                 -- currentwaypoint
    1,                                   -- curhealth
    1,                                   -- curmana
    c.`MovementType`,                    -- MovementType
    COALESCE(c.`npcflag`,0) & 0xFFFFFFFF, -- npcflag: NULL->0, low 32 bits kept
    COALESCE(c.`unit_flags`,0),          -- unit_flags: NULL->0
    0,                                   -- dynamicflags
    QUOTE(''),                           -- ScriptName: empty
    0,                                   -- VerifiedBuild
    0,                                   -- CreateObject
    QUOTE('')                            -- Comment: empty
  ),
  ');',
  '\n',
  'INSERT IGNORE INTO `creature_guid_map` (`old_guid`,`new_guid`) VALUES (',
  CONCAT_WS(',', c.`guid`, CONCAT('@base + ', c.`rn`)),
  ');'
) AS `statement`
FROM (
  SELECT `creature`.*,
         ROW_NUMBER() OVER (ORDER BY `guid`) AS `rn`
  FROM `creature`
  WHERE `map` = @map_id
) c
ORDER BY c.`rn`;
