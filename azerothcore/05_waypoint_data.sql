-- waypoint_data  ·  TrinityCore Master -> AzerothCore 3.3.5a
--
-- Builds one `INSERT IGNORE INTO waypoint_data` statement per source node.
-- Source: waypoint_path_node, joined to waypoint_path for the per-path
-- MoveType and Velocity. Scope: the paths referenced by creature_addon.PathId
-- of the creatures spawned on map @map_id.
-- waypoint_data.id keeps the TrinityCore PathId unchanged; 06_creature_addon.sql
-- links each creature to that id. Per-node actions do not exist in TrinityCore
-- (they are SmartAI SMART_EVENT_WAYPOINT_* events), so action stays 0.

SELECT CONCAT(
  'INSERT IGNORE INTO `waypoint_data` ',
  '(`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,',
  '`velocity`,`delay`,`smoothTransition`,`move_type`,`action`,',
  '`action_chance`,`wpguid`) VALUES (',
  CONCAT_WS(',',
    n.`PathId`,                       -- id: the TrinityCore PathId, kept as-is
    n.`NodeId`,                       -- point
    n.`PositionX`,                    -- position_x
    n.`PositionY`,                    -- position_y
    n.`PositionZ`,                    -- position_z
    IFNULL(n.`Orientation`,'NULL'),   -- orientation: NULL keeps "face travel direction"
    COALESCE(p.`Velocity`,0),         -- velocity: 0 = the creature's default speed
    n.`Delay`,                        -- delay
    0,                                -- smoothTransition: 0 = stop at each point
    COALESCE(p.`MoveType`,1),         -- move_type: same enum as TC (0 Walk/1 Run/2 Land/3 Takeoff)
    0,                                -- action: TC has no per-node action
    100,                              -- action_chance
    0                                 -- wpguid: set by the core, never by hand
  ),
  ');'
) AS `statement`
FROM `waypoint_path_node` n
LEFT JOIN `waypoint_path` p ON p.`PathId` = n.`PathId`
WHERE n.`PathId` IN (
  SELECT a.`PathId`
  FROM `creature_addon` a
  JOIN `creature` c ON c.`guid` = a.`guid`
  WHERE c.`map` = @map_id AND a.`PathId` > 0
)
ORDER BY n.`PathId`, n.`NodeId`;
