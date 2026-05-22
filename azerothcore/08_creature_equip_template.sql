-- creature_equip_template  ·  TrinityCore Master -> AzerothCore 3.3.5a
--
-- One creature_equip_template row per equip set owned by a creature spawned
-- on map @map_id. A creature carries an `equipment_id`; the worldserver looks
-- the matching (CreatureID, ID) pair up here, so a missing row leaves the
-- creature unarmed. CreatureID references creature_template.entry, not a
-- spawn guid, so no guid remap is needed.
--
-- ============================================================================
-- FIELD MAPPING  (TC Master -> AC 3.3.5a creature_equip_template)
-- ============================================================================
--
-- Carried 1:1:
--   CreatureID   the creature_template entry the equip set belongs to.
--   ID           equip-set selector (1+); copied verbatim so it stays
--                consistent with creature.equipment_id (04_creature.sql
--                copies that column verbatim too).
--   ItemID1/2/3  right-hand / left-hand / ranged item, from Item.dbc. An id
--                absent from the 3.3.5 Item.dbc is dropped to 0 by the
--                worldserver -- the items pipeline supplies the missing ones.
--
-- Dropped -- no 3.3.5 equivalent:
--   AppearanceModID1/2/3   transmog appearance modifier; 3.3.5 has no
--                          transmog, so the item shows its base appearance.
--   ItemVisual1/2/3        item visual / illusion override; no 3.3.5
--                          equivalent for creature equipment.
--   VerifiedBuild          present in the TC table; the AC 3.3.5a
--                          creature_equip_template documents only the five
--                          columns below, so it is omitted -- a column AC
--                          defaults on its own if its build does carry it.

SELECT CONCAT(
  'INSERT IGNORE INTO `creature_equip_template` ',
  '(`CreatureID`,`ID`,`ItemID1`,`ItemID2`,`ItemID3`) VALUES (',
  CONCAT_WS(',',
    et.`CreatureID`,   -- CreatureID: the creature_template entry
    et.`ID`,           -- ID: equip-set selector, matched by creature.equipment_id
    et.`ItemID1`,      -- ItemID1: right hand (main hand)
    et.`ItemID2`,      -- ItemID2: left hand (off hand)
    et.`ItemID3`       -- ItemID3: ranged
  ),
  ');'
) AS `statement`
FROM `creature_equip_template` et
WHERE et.`CreatureID` IN (
  SELECT DISTINCT `id` FROM `creature` WHERE `map` = @map_id
)
ORDER BY et.`CreatureID`, et.`ID`;
