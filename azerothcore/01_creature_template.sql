-- creature_template  ·  TrinityCore Master -> AzerothCore 3.3.5a
--
-- One creature_template row per creature_template entry referenced by a spawn
-- on map @map_id. The WotLK-era stat fields modern TrinityCore moved out of
-- creature_template are read back from creature_template_difficulty at
-- DifficultyID 0.
--
-- Source coverage note: Legion creature.db2 carries only ~9.9k rows (a small
-- client-facing subset); the map @map_id creatures are not in it, so the TC
-- SQL pair is the complete source. No db2 cross-reference is needed.
--
-- ============================================================================
-- FIELD MAPPING  (TC Master -> AC 3.3.5a creature_template)
-- ============================================================================
--
-- Carried 1:1 from TC creature_template (no transformation):
--   entry, KillCredit1, KillCredit2, name, subname, IconName, faction,
--   speed_walk, speed_run, dmgschool, BaseAttackTime, RangeAttackTime,
--   BaseVariance, RangeVariance, unit_flags, unit_flags2, VehicleId, AIName,
--   MovementType, ExperienceModifier, RacialLeader, movementId, RegenHealth,
--   CreatureImmunitiesId, ScriptName.
--   - name/subname/IconName: NULL -> '', truncated to AC's char(100), QUOTEd.
--   - AIName/ScriptName: QUOTEd verbatim (TC C++ script names do not name an
--     AC script, but they are useful as a marker; AC logs an unknown-script
--     warning at load).
--   - CreatureImmunitiesId: references the AC creature_immunities table -- a
--     row absent from that table just disables the immunity at load.
--
-- Carried 1:1 from TC creature_template_difficulty (DifficultyID = 0):
--   HealthModifier, ManaModifier, ArmorModifier, DamageModifier,
--   LootID -> lootid, PickPocketLootID -> pickpocketloot,
--   SkinLootID -> skinloot, GoldMin -> mingold, GoldMax -> maxgold,
--   TypeFlags -> type_flags.
--
-- Coerced / clamped (transformation forced by AC constraints):
--   exp = LEAST(d.HealthScalingExpansion, 2)  -- AC's stats table goes only
--         up to 2 (WotLK); a Legion creature (HealthScalingExpansion 6) caps
--         to WotLK stats.
--   rank = t.Classification clamped to 0..4 -- TC defines 5 (Trivial) and 6
--          (Minus Mob) that 3.3.5 has no rank for; out-of-range goes to 0.
--   unit_class -- AC requires a power type 1/2/4/8 (Warrior/Paladin/Rogue/
--                 Mage). Any other value is coerced to 1 to avoid AC's
--                 startup warning ("Not setting this value will report a
--                 minor warning in the DB_Errors.log").
--   family -- AC stores it in a tinyint SIGNED, range -128..127. TC int may
--             carry a Legion family > 127; out-of-range goes to 0.
--   npcflag -- TC bigint -> AC int via & 0xFFFFFFFF. The low 32 bits cover
--              every 3.3.5-known npcflag (gossip/quest/vendor/trainer/...,
--              up to bit 26 Mailbox). The high dword is npcflag2 (Legion
--              transmog/vault/wild battle pet/... ), dropped.
--   flags_extra -- t.flags_extra & 0xEFFFFFFF. The low 28 bits of TC and AC
--                  share the same meaning (the AC enum is a superset of TC's).
--                  Only bit 28 (CREATURE_FLAG_EXTRA_DUNGEON_BOSS, 0x10000000)
--                  must be stripped -- both the TC and AC docs warn that
--                  setting it in the DB triggers a worldserver startup error
--                  (the core sets it at runtime). Bits 29 (IGNORE_PATHFINDING)
--                  and 30 (IMMUNITY_KNOCKBACK) carry the same meaning in both
--                  cores and are kept.
--   VerifiedBuild -- AC stores it in a smallint signed; an out-of-range TC
--                    value (build > 32767) is clamped to 0 ("not parsed").
--
-- Synthesised (AC has it, TC does not):
--   difficulty_entry_1/2/3 = 0  -- 3.3.5a has no difficulty entries.
--   gossip_menu_id = 0  -- TC stores it in npc_text/gossip_menu, not here.
--   minlevel = maxlevel = @creature_level  -- modern TC scales by
--              ContentTuning, so a flat config value is used.
--   speed_swim = speed_flight = 1, HoverHeight = 1, detection_range = 18
--              -- no TC source column, AC defaults / common sniff values.
--   PetSpellDataId = 0  -- not exposed in TC creature_template.
--   dynamicflags = 0  -- no per-template TC source; AC takes the default.
--
-- Dropped -- TC has the column, AC does not (data loss is unavoidable):
--   TC creature_template: scale, femaleName, TitleAlt, RequiredExpansion,
--     VignetteID, unit_flags3, WidgetSetID, WidgetSetUnitConditionID,
--     StringId, trainer_class.
--     (scale -- the AC wiki documents the column but the real AC 3.3.5a
--      creature_template does not have it; verified against the live target.)
--   TC creature_template_difficulty: LevelScalingDeltaMin/Max, ContentTuningID,
--     CreatureDifficultyID, TypeFlags2, TypeFlags3, StaticFlags1..8.

SELECT CONCAT(
  'INSERT IGNORE INTO `creature_template` ',
  '(`entry`,`difficulty_entry_1`,`difficulty_entry_2`,`difficulty_entry_3`,',
  '`KillCredit1`,`KillCredit2`,`name`,`subname`,`IconName`,`gossip_menu_id`,',
  '`minlevel`,`maxlevel`,`exp`,`faction`,`npcflag`,`speed_walk`,`speed_run`,',
  '`speed_swim`,`speed_flight`,`detection_range`,`rank`,`dmgschool`,',
  '`BaseAttackTime`,`RangeAttackTime`,`BaseVariance`,`RangeVariance`,',
  '`unit_class`,`unit_flags`,`unit_flags2`,`dynamicflags`,`family`,`type`,',
  '`type_flags`,`lootid`,`pickpocketloot`,`skinloot`,`PetSpellDataId`,',
  '`VehicleId`,`mingold`,`maxgold`,`AIName`,`MovementType`,`HoverHeight`,',
  '`HealthModifier`,`ManaModifier`,`ArmorModifier`,`DamageModifier`,',
  '`ExperienceModifier`,`RacialLeader`,`movementId`,`RegenHealth`,',
  '`CreatureImmunitiesId`,`flags_extra`,`ScriptName`,`VerifiedBuild`) VALUES (',
  CONCAT_WS(',',
    t.`entry`,                                            -- entry
    0,                                                    -- difficulty_entry_1: no 3.3.5 difficulty entries
    0,                                                    -- difficulty_entry_2
    0,                                                    -- difficulty_entry_3
    t.`KillCredit1`,                                      -- KillCredit1
    t.`KillCredit2`,                                      -- KillCredit2
    QUOTE(LEFT(COALESCE(t.`name`,''),100)),               -- name: NULL->'', cut to char(100), SQL-quoted
    QUOTE(LEFT(COALESCE(t.`subname`,''),100)),            -- subname
    QUOTE(LEFT(COALESCE(t.`IconName`,''),100)),           -- IconName
    0,                                                    -- gossip_menu_id: no TC source on this table
    @creature_level,                                      -- minlevel: from config.sql
    @creature_level,                                      -- maxlevel
    LEAST(COALESCE(d.`HealthScalingExpansion`,2), 2),     -- exp: AC stats table 0..2 (Classic/TBC/WotLK)
    t.`faction`,                                          -- faction
    COALESCE(t.`npcflag`,0) & 0xFFFFFFFF,                 -- npcflag: TC bigint -> AC int, low 32 bits
    t.`speed_walk`,                                       -- speed_walk
    t.`speed_run`,                                        -- speed_run
    1,                                                    -- speed_swim: no TC column
    1,                                                    -- speed_flight: no TC column
    18,                                                   -- detection_range: no TC column, common sniff
    IF(t.`Classification` BETWEEN 0 AND 4,                -- rank: clamped to 3.3.5 ranks 0..4
       t.`Classification`, 0),
    t.`dmgschool`,                                        -- dmgschool: spell-school enum 0..6 (stable)
    t.`BaseAttackTime`,                                   -- BaseAttackTime
    t.`RangeAttackTime`,                                  -- RangeAttackTime
    t.`BaseVariance`,                                     -- BaseVariance
    t.`RangeVariance`,                                    -- RangeVariance
    IF(t.`unit_class` IN (1,2,4,8),                       -- unit_class: must be 1/2/4/8
       t.`unit_class`, 1),
    t.`unit_flags`,                                       -- unit_flags
    t.`unit_flags2`,                                      -- unit_flags2
    0,                                                    -- dynamicflags: no per-template TC source
    IF(t.`family` BETWEEN 0 AND 127, t.`family`, 0),      -- family: signed-tinyint range
    t.`type`,                                             -- type
    COALESCE(d.`TypeFlags`, 0),                           -- type_flags
    COALESCE(d.`LootID`, 0),                              -- lootid
    COALESCE(d.`PickPocketLootID`, 0),                    -- pickpocketloot
    COALESCE(d.`SkinLootID`, 0),                          -- skinloot
    0,                                                    -- PetSpellDataId
    t.`VehicleId`,                                        -- VehicleId
    COALESCE(d.`GoldMin`, 0),                             -- mingold
    COALESCE(d.`GoldMax`, 0),                             -- maxgold
    QUOTE(t.`AIName`),                                    -- AIName
    t.`MovementType`,                                     -- MovementType
    1,                                                    -- HoverHeight: no TC column
    COALESCE(d.`HealthModifier`, 1),                      -- HealthModifier
    COALESCE(d.`ManaModifier`, 1),                        -- ManaModifier
    COALESCE(d.`ArmorModifier`, 1),                       -- ArmorModifier
    COALESCE(d.`DamageModifier`, 1),                      -- DamageModifier
    t.`ExperienceModifier`,                               -- ExperienceModifier
    t.`RacialLeader`,                                     -- RacialLeader
    t.`movementId`,                                       -- movementId
    t.`RegenHealth`,                                      -- RegenHealth
    t.`CreatureImmunitiesId`,                             -- CreatureImmunitiesId: depends on AC creature_immunities
    t.`flags_extra` & 0xEFFFFFFF,                         -- flags_extra: strip only DUNGEON_BOSS (bit 28)
    QUOTE(t.`ScriptName`),                                -- ScriptName: carried as a marker for later wiring
    IF(t.`VerifiedBuild` BETWEEN -32768 AND 32767,        -- VerifiedBuild: clamped to AC smallint range
       t.`VerifiedBuild`, 0)
  ),
  ');'
) AS `statement`
FROM `creature_template` t
LEFT JOIN `creature_template_difficulty` d
       ON d.`Entry` = t.`entry` AND d.`DifficultyID` = 0
WHERE t.`entry` IN (
  SELECT DISTINCT `id` FROM `creature` WHERE `map` = @map_id
)
ORDER BY t.`entry`;
