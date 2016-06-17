ALTER TABLE "game_sessions" ADD COLUMN "players_joined" INTEGER NOT NULL DEFAULT 0;

UPDATE "game_sessions" SET "players_joined" = (SELECT count(*) FROM "session_characters" WHERE "session_characters"."game_session_id" = "game_sessions"."id");