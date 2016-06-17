CREATE TABLE session_items
(
   id bigserial NOT NULL,
   rules_id bigint NOT NULL,
   item_id bigint NOT NULL,

   owner_id bigint,
   attrs jsonb NOT NULL DEFAULT '{}',

   ctime timestamp without time zone NOT NULL DEFAULT timezone('utc'::text, now()),
   PRIMARY KEY (id),
   FOREIGN KEY (rules_id) REFERENCES game_rules (id) ON UPDATE NO ACTION ON DELETE CASCADE,
   FOREIGN KEY (item_id) REFERENCES items (id) ON UPDATE NO ACTION ON DELETE CASCADE,
   FOREIGN KEY (owner_id) REFERENCES session_characters (id) ON UPDATE NO ACTION ON DELETE CASCADE
) 
WITH (
  OIDS = FALSE
)
;

ALTER TABLE "session_characters" DROP COLUMN "items";