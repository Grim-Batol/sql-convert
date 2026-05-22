-- creature_template_locale  ·  TrinityCore Master -> AzerothCore 3.3.5a
--
-- One creature_template_locale row per (entry, locale) pair for the
-- creature_template entries spawned on map @map_id. AC's real schema uses the
-- same "long" layout as TC (a row per locale, not a wide one-row-per-entry as
-- the AC wiki documents -- the wiki is wrong on this table; the live target
-- has been verified).
--
-- ============================================================================
-- FIELD MAPPING  (TC Master -> AC 3.3.5a creature_template_locale)
-- ============================================================================
--
-- Carried 1:1:
--   entry, locale, Name, Title, VerifiedBuild.
--   - locale is the same 4-char string in both cores ('frFR', 'deDE', ...).
--   - Name / Title are NULL-able in both -- NULLs are preserved.
--
-- Dropped -- TC has the column, AC does not:
--   NameAlt   alternate (female) name; AC has no separate column.
--   TitleAlt  alternate title; AC has no separate column.
--
-- Locale coverage: TC stores 10 locales on this map (deDE, esES, esMX, frFR,
-- itIT, koKR, ptBR, ruRU, zhCN, zhTW). AC's LocaleConstant covers 8 (no itIT,
-- no ptBR). The two unsupported locale rows are kept in the table -- AC
-- ignores an unknown locale string at load (logs a warning per row, no harm)
-- and the data is there if AC ever extends support.

SELECT CONCAT(
  'INSERT IGNORE INTO `creature_template_locale` ',
  '(`entry`,`locale`,`Name`,`Title`,`VerifiedBuild`) VALUES (',
  CONCAT_WS(',',
    tl.`entry`,                                          -- entry
    QUOTE(tl.`locale`),                                  -- locale: 'frFR', 'deDE', ...
    IF(tl.`Name`  IS NULL, 'NULL', QUOTE(tl.`Name`)),    -- Name: NULL preserved
    IF(tl.`Title` IS NULL, 'NULL', QUOTE(tl.`Title`)),   -- Title: NULL preserved
    tl.`VerifiedBuild`                                   -- VerifiedBuild
  ),
  ');'
) AS `statement`
FROM `creature_template_locale` tl
WHERE tl.`entry` IN (SELECT DISTINCT `id` FROM `creature` WHERE `map` = @map_id)
ORDER BY tl.`entry`, tl.`locale`;
