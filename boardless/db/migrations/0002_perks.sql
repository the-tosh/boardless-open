CREATE TABLE perks
(
   id bigserial NOT NULL,
   rules_id bigint NOT NULL,
   title text NOT NULL,
   description text NOT NULL,
   skills jsonb NOT NULL,
   priority bigserial NOT NULL,
   is_disabled boolean NOT NULL DEFAULT false,
   ctime timestamp without time zone NOT NULL DEFAULT timezone('utc'::text, now()),
   PRIMARY KEY (id),
   FOREIGN KEY (rules_id) REFERENCES game_rules (id) ON UPDATE NO ACTION ON DELETE CASCADE
) 
WITH (
  OIDS = FALSE
)
;

ALTER TABLE game_rules ADD COLUMN base_perk_points INTEGER NOT NULL DEFAULT 0;
ALTER TABLE session_characters ADD COLUMN perk_points jsonb NOT NULL DEFAULT '{}';