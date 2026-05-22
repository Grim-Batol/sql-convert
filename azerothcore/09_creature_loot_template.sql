-- creature_loot_template  ·  TrinityCore Master -> AzerothCore 3.3.5a
--
-- One creature_loot_template row per loot entry used by a creature spawned on
-- map @map_id. Scope: the LootIDs 01_creature_template.sql writes as
-- creature_template.lootid -- creature_template_difficulty.LootID at
-- DifficultyID 0 for the in-scope creatures.
--
-- ============================================================================
-- FIELD MAPPING  (TC Master -> AC 3.3.5a creature_loot_template)
-- ============================================================================
--
-- TC marks each row's kind with an ItemType column; AC instead splits the
-- item drop and the reference into two columns (Item, Reference). ItemType
-- was verified against the live data -- every ItemType=1 Item is present in
-- reference_loot_template.Entry:
--   ItemType 0 = item       -> Item = TC.Item,  Reference = 0
--   ItemType 1 = reference  -> Item = 0,        Reference = TC.Item
--   ItemType 2 = currency   -> dropped: 3.3.5 has no creature currency loot.
--
-- Carried 1:1:
--   Entry, Chance, QuestRequired, LootMode, GroupId, MinCount, MaxCount,
--   Comment.
--
-- Dependencies / caveats:
--   * A reference row points at reference_loot_template; that table needs
--     its own conversion (it shares this ItemType layout) or the reference
--     resolves to nothing.
--   * Item ids are 3.3.5 item_template entries. A Legion item absent from
--     the target item_template is rejected by the worldserver at load --
--     porting those items is a separate effort.

SELECT CONCAT(
  'INSERT IGNORE INTO `creature_loot_template` ',
  '(`Entry`,`Item`,`Reference`,`Chance`,`QuestRequired`,`LootMode`,',
  '`GroupId`,`MinCount`,`MaxCount`,`Comment`) VALUES (',
  CONCAT_WS(',',
    clt.`Entry`,                                  -- Entry: creature_template.lootid
    IF(clt.`ItemType` = 1, 0, clt.`Item`),        -- Item: 0 on a reference row
    IF(clt.`ItemType` = 1, clt.`Item`, 0),        -- Reference: ref entry, else 0
    clt.`Chance`,                                 -- Chance
    clt.`QuestRequired`,                          -- QuestRequired
    clt.`LootMode`,                               -- LootMode
    clt.`GroupId`,                                -- GroupId
    clt.`MinCount`,                               -- MinCount
    clt.`MaxCount`,                               -- MaxCount
    IF(clt.`Comment` IS NULL OR clt.`Comment` = '',  -- Comment: NULL when empty
       'NULL', QUOTE(clt.`Comment`))
  ),
  ');'
) AS `statement`
FROM `creature_loot_template` clt
WHERE clt.`ItemType` <> 2                         -- drop currency: no 3.3.5 equivalent
  AND clt.`Entry` IN (
    SELECT DISTINCT d.`LootID`
    FROM `creature_template_difficulty` d
    WHERE d.`DifficultyID` = 0 AND d.`LootID` > 0
      AND d.`Entry` IN (SELECT DISTINCT `id` FROM `creature` WHERE `map` = @map_id)
  )
ORDER BY clt.`Entry`, clt.`GroupId`, clt.`Item`;
