ALTER TABLE "skills" DROP COLUMN IF EXISTS "player_can_change_value";
ALTER TABLE "skills" DROP COLUMN IF EXISTS "formula_parent_ids";

ALTER TABLE "game_rules" DROP COLUMN IF EXISTS "base_perk_points";
ALTER TABLE "game_rules" DROP COLUMN IF EXISTS "min_level";
ALTER TABLE "game_rules" DROP COLUMN IF EXISTS "max_level";


ALTER TABLE "game_sessions" DROP COLUMN IF EXISTS "primary_stat_points";
ALTER TABLE "game_sessions" DROP COLUMN IF EXISTS "secondary_stat_points";

DROP TABLE IF EXISTS "game_session_races";
DROP TABLE IF EXISTS "game_session_stats";
DROP TABLE IF EXISTS "game_session_stat_categories";
DROP TABLE IF EXISTS "items__stats";