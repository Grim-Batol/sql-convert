-- creature_addon  ·  TrinityCore Master -> AzerothCore 3.3.5a
--
-- One creature_addon row per map @map_id creature that has one. The spawn
-- guid is resolved at apply time through creature_guid_map (04_creature.sql
-- must run first): the INSERT ... SELECT looks the new guid up by old guid.
-- INSERT IGNORE keeps an existing creature_addon row intact.
--
-- ============================================================================
-- FIELD MAPPING  (TC Master `creature_addon` -> AC 3.3.5a `creature_addon`)
-- ============================================================================
--
-- Carried 1:1 (same column, same meaning):
--   PathId   -> path_id   waypoint path. 05_waypoint_data keeps the TC PathId
--                         as waypoint_data.id, so this value matches it.
--   mount    -> mount     mount CreatureDisplayInfo id (UNIT_FIELD_MOUNTDISPLAYID).
--   emote    -> emote     emote state played continuously.
--   visibilityDistanceType  same enum (0 Normal .. 5 Infinite).
--   auras    -> auras     space-separated spell-id list (see note below).
--
-- Packed -- TC splits the UNIT_FIELD_BYTES_* unit fields into one column
-- each; AC stores the raw packed 32-bit field. Byte offsets per the 3.3.5
-- core, cross-checked with the AC bytes1/bytes2 documentation:
--   bytes1 (UNIT_FIELD_BYTES_1):
--     byte 0 = StandState  0 stand .. 9 submerged -- identical TC<->AC enum,
--                          and identical to the AC bytes1 doc values 1-9.
--     byte 1 = pet talents -> 0
--     byte 2 = UNIT_BYTE1_FLAG (3.3.5: always-stand / hover). TC's VisFlags
--              column is the modern invisible/stealth enum -- a different
--              meaning -- so carrying it raw would misbehave: it is dropped.
--     byte 3 = AnimTier    ground / hover / fly (AC bytes1 doc: 0x03000000).
--     => bytes1 = StandState + (AnimTier << 24)
--   bytes2 (UNIT_FIELD_BYTES_2):
--     byte 0 = SheathState 0 unarmed / 1 melee / 2 ranged -- identical enum.
--     byte 1 = PvPFlags    PVP / FFA / sanctuary -- identical enum.
--     byte 2-3 = pet flags / shapeshift form -> 0
--     => bytes2 = SheathState + (PvPFlags << 8)
--
-- Dropped -- no 3.3.5 equivalent:
--   MountCreatureID  AC keeps only the mount display id (`mount`).
--   VisFlags         incompatible byte-2 semantics (see bytes1 above).
--   aiAnimKit / movementAnimKit / meleeAnimKit  the AnimKit system did not
--                    exist in 3.3.5; the AC 3.3.5a creature_addon table has
--                    no such columns, so they are left out entirely.
--
-- auras: the spell-id list is copied verbatim. Ids absent from the 3.3.5
-- Spell.dbc (Legion-era spells) are rejected by the worldserver at load --
-- porting those spells is a separate effort.

SELECT CONCAT(
  'INSERT IGNORE INTO `creature_addon` ',
  '(`guid`,`path_id`,`mount`,`bytes1`,`bytes2`,`emote`,',
  '`visibilityDistanceType`,`auras`) ',
  'SELECT `new_guid`,',
  CONCAT_WS(',',
    a.`PathId`,                                -- path_id
    a.`mount`,                                 -- mount: mount display id
    a.`StandState` + (a.`AnimTier` << 24),     -- bytes1: byte0 StandState, byte3 AnimTier
    a.`SheathState` + (a.`PvPFlags` << 8),     -- bytes2: byte0 SheathState, byte1 PvPFlags
    a.`emote`,                                 -- emote
    a.`visibilityDistanceType`,                -- visibilityDistanceType
    IF(a.`auras` IS NULL OR a.`auras` = '',    -- auras: NULL when empty, else quoted
       'NULL', QUOTE(a.`auras`))
  ),
  ' FROM `creature_guid_map` WHERE `old_guid` = ', a.`guid`, ';'
) AS `statement`
FROM `creature_addon` a
JOIN `creature` c ON c.`guid` = a.`guid`
WHERE c.`map` = @map_id
ORDER BY a.`guid`;
