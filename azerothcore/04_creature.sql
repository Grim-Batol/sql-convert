-- creature  ·  TrinityCore Master -> AzerothCore 3.3.5a
--
-- One spawn on map @map_id produces two statements: the `creature` row and
-- its `creature_guid_map` row. 04_creature.preamble.sql runs first -- it
-- creates creature_guid_map and sets @base = MAX(creature.guid).
--
-- GUID: the source guid is not carried over. Each spawn takes `@base + N`,
-- N a stable ROW_NUMBER() over the map's spawns ordered by source guid;
-- creature_guid_map records the old (TC) guid against that `@base + N`.
--
-- ============================================================================
-- FIELD MAPPING  (TC Master `creature` -> AC 3.3.5a `creature`)
-- ============================================================================
--
-- TC columns with no AC equivalent -- dropped; the spawn falls back to its
-- creature_template:
--   modelid          per-spawn model override; AC `creature` has no such
--                    column, so the creature_template model is used.
--   phaseUseFlags    Legion phasing; 3.3.5a has only the phaseMask bitmask
--   PhaseId          -- none of these map onto it.
--   PhaseGroup
--   terrainSwapMap   phased terrain swap; no 3.3.5a equivalent.
--   unit_flags2      AC `creature` has no unit_flags2 column (the template
--                    does), so a per-spawn override is lost.
--   unit_flags3      Legion-only; 3.3.5a has no UNIT_FIELD_FLAGS_3 at all.
--   StringId         modern script identifier; no 3.3.5a equivalent.
--   curHealthPct     spawn health %; AC curhealth is absolute and core-
--                    managed ("always 1"), so a wounded spawn is not kept.
--
-- AC columns with no TC source -- synthesised:
--   id2 / id3        0 -- TC carries a single creature id (-> id1).
--   spawnMask        @spawn_mask (config.sql). TC stores the per-spawn
--                    difficulty set in spawnDifficulties; @spawn_mask is
--                    chosen deliberately per conversion instead.
--   phaseMask        @phase_mask (config.sql); PhaseId/PhaseGroup do not
--                    map onto the 3.3.5a bitmask.
--   dynamicflags     0 -> the creature_template value is used.
--   CreateObject     0 / '' -- not used by the core.
--   Comment
--
-- Flags / core-managed values:
--   npcflag      TC bigint -> AC int: the low 32 bits (classic gossip /
--                vendor / questgiver / ... flags) are kept, the Legion
--                npcflag2 high dword is dropped. AC's ChooseCreatureFlags
--                applies a creature.npcflag override only when non-zero, so
--                NULL/0 means "use the creature_template flags".
--   unit_flags   copied verbatim; same non-zero-override rule.
--   MovementType 0/1/2 = idle / random / waypoint, identical in both cores.
--                Type 2 needs a path (creature_addon + waypoint_data);
--                type 1 needs wander_distance > 0 to actually move.
--   curhealth    1, curmana 0, currentwaypoint 0 -- core-managed storage
--                fields; AC docs state these fixed values.

SELECT CONCAT(
  'INSERT IGNORE INTO `creature` ',
  '(`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,',
  '`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,',
  '`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,',
  '`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,',
  '`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (',
  CONCAT_WS(',',
    CONCAT('@base + ', c.`rn`),           -- guid: handed out above the target's MAX(guid)
    c.`id`,                               -- id1: TC single creature id
    0,                                    -- id2: no random template selection
    0,                                    -- id3
    c.`map`,                              -- map
    c.`zoneId`,                           -- zoneId
    c.`areaId`,                           -- areaId
    @spawn_mask,                          -- spawnMask: from config.sql
    @phase_mask,                          -- phaseMask: from config.sql
    c.`equipment_id`,                     -- equipment_id: -1 random / 0 none / 1+ set
    c.`position_x`,                       -- position_x
    c.`position_y`,                       -- position_y
    c.`position_z`,                       -- position_z
    c.`orientation`,                      -- orientation
    c.`spawntimesecs`,                    -- spawntimesecs
    c.`wander_distance`,                  -- wander_distance: random-movement radius
    0,                                    -- currentwaypoint: core-managed, always 0
    1,                                    -- curhealth: core-managed, always 1
    0,                                    -- curmana: core-managed, always 0
    c.`MovementType`,                     -- MovementType: 0/1/2 identical TC<->AC
    COALESCE(c.`npcflag`,0) & 0xFFFFFFFF,  -- npcflag: NULL->0, low 32 bits kept
    COALESCE(c.`unit_flags`,0),           -- unit_flags: NULL->0
    0,                                    -- dynamicflags: use creature_template value
    QUOTE(''),                            -- ScriptName: TC C++ scripts have no AC name
    0,                                    -- VerifiedBuild: not parsed from a sniff
    0,                                    -- CreateObject: not used by the core
    QUOTE('')                             -- Comment: not used by the core
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
