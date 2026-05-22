-- creature_template  ·  TrinityCore Master -> AzerothCore 3.3.5a
--
-- Builds one `INSERT IGNORE INTO creature_template` statement per source row.
-- Scope: the creature_template rows used by the spawns on map @map_id.
-- The WotLK-era stat fields modern TrinityCore moved out of creature_template
-- are read back from creature_template_difficulty at DifficultyID 0.

SELECT CONCAT(
  'INSERT IGNORE INTO `creature_template` ',
  '(`entry`,`difficulty_entry_1`,`difficulty_entry_2`,`difficulty_entry_3`,',
  '`KillCredit1`,`KillCredit2`,`name`,`subname`,`IconName`,`gossip_menu_id`,',
  '`minlevel`,`maxlevel`,`exp`,`faction`,`npcflag`,`speed_walk`,`speed_run`,',
  '`speed_swim`,`speed_flight`,`detection_range`,`rank`,`dmgschool`,',
  '`DamageModifier`,`BaseAttackTime`,`RangeAttackTime`,`BaseVariance`,',
  '`RangeVariance`,`unit_class`,`unit_flags`,`unit_flags2`,`dynamicflags`,',
  '`family`,`type`,`type_flags`,`lootid`,`pickpocketloot`,`skinloot`,',
  '`PetSpellDataId`,`VehicleId`,`mingold`,`maxgold`,`AIName`,`MovementType`,',
  '`HoverHeight`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,',
  '`ExperienceModifier`,`RacialLeader`,`movementId`,`RegenHealth`,',
  '`CreatureImmunitiesId`,`flags_extra`,`ScriptName`,`VerifiedBuild`) VALUES (',
  CONCAT_WS(',',
    t.`entry`,                                      -- entry
    0,                                              -- difficulty_entry_1: 3.3.5a has no difficulty entries
    0,                                              -- difficulty_entry_2
    0,                                              -- difficulty_entry_3
    t.`KillCredit1`,                                -- KillCredit1
    t.`KillCredit2`,                                -- KillCredit2
    QUOTE(LEFT(COALESCE(t.`name`,''),100)),         -- name: NULL->'', cut to 100 chars, SQL-quoted
    QUOTE(LEFT(COALESCE(t.`subname`,''),100)),      -- subname: NULL->'', cut to 100 chars, SQL-quoted
    QUOTE(LEFT(COALESCE(t.`IconName`,''),100)),     -- IconName: NULL->'', cut to 100 chars, SQL-quoted
    0,                                              -- gossip_menu_id
    @creature_level,                                -- minlevel: from config.sql
    @creature_level,                                -- maxlevel: from config.sql
    2,                                              -- exp: 2 = Wrath of the Lich King
    t.`faction`,                                    -- faction
    t.`npcflag` & 0xFFFFFFFF,                       -- npcflag: low 32 bits kept
    t.`speed_walk`,                                 -- speed_walk
    t.`speed_run`,                                  -- speed_run
    1,                                              -- speed_swim
    1,                                              -- speed_flight
    18,                                             -- detection_range
    t.`Classification`,                             -- rank: TC Classification
    t.`dmgschool`,                                  -- dmgschool
    COALESCE(d.`DamageModifier`,1),                 -- DamageModifier: from _difficulty, 1 when absent
    t.`BaseAttackTime`,                             -- BaseAttackTime
    t.`RangeAttackTime`,                            -- RangeAttackTime
    t.`BaseVariance`,                               -- BaseVariance
    t.`RangeVariance`,                              -- RangeVariance
    IF(t.`unit_class` IN (1,2,4,8),t.`unit_class`,1), -- unit_class: coerced to a power type (1/2/4/8)
    t.`unit_flags`,                                 -- unit_flags
    t.`unit_flags2`,                                -- unit_flags2
    0,                                              -- dynamicflags
    IF(t.`family` BETWEEN 0 AND 127,t.`family`,0),  -- family: kept only within the signed-tinyint range
    t.`type`,                                       -- type
    COALESCE(d.`TypeFlags`,0),                      -- type_flags: from _difficulty
    COALESCE(d.`LootID`,0),                         -- lootid: from _difficulty
    COALESCE(d.`PickPocketLootID`,0),               -- pickpocketloot: from _difficulty
    COALESCE(d.`SkinLootID`,0),                     -- skinloot: from _difficulty
    0,                                              -- PetSpellDataId
    t.`VehicleId`,                                  -- VehicleId
    COALESCE(d.`GoldMin`,0),                        -- mingold: from _difficulty
    COALESCE(d.`GoldMax`,0),                        -- maxgold: from _difficulty
    QUOTE(t.`AIName`),                              -- AIName: SQL-quoted
    t.`MovementType`,                               -- MovementType
    1,                                              -- HoverHeight
    COALESCE(d.`HealthModifier`,1),                 -- HealthModifier: from _difficulty
    COALESCE(d.`ManaModifier`,1),                   -- ManaModifier: from _difficulty
    COALESCE(d.`ArmorModifier`,1),                  -- ArmorModifier: from _difficulty
    t.`ExperienceModifier`,                         -- ExperienceModifier
    t.`RacialLeader`,                               -- RacialLeader
    t.`movementId`,                                 -- movementId
    t.`RegenHealth`,                                -- RegenHealth
    0,                                              -- CreatureImmunitiesId
    t.`flags_extra` & 0x0FFFFFFF,                   -- flags_extra: low 28 bits kept
    QUOTE(''),                                      -- ScriptName: empty (TC C++ scripts have no AC equivalent)
    0                                               -- VerifiedBuild
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
