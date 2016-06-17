CREATE TABLE users
(
  id bigserial NOT NULL,
  email character varying(255) NOT NULL,
  password text NOT NULL,
  nickname character varying(255) NOT NULL,
  status integer NOT NULL,
  confirmation_hash character varying(32) NOT NULL DEFAULT '',
  "group" character varying(255) NOT NULL DEFAULT 'unconfirmed'::character varying,
  ctime timestamp without time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  last_login timestamp without time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT users_pkey PRIMARY KEY (id),
  CONSTRAINT users_email_key UNIQUE (email),
  CONSTRAINT users_nickname_key UNIQUE (nickname)
)
WITH (
  OIDS=FALSE
);
CREATE TABLE game_rules
(
   id bigserial NOT NULL,
   creator_id bigint NOT NULL,
   title text NOT NULL,
   max_players integer NOT NULL DEFAULT 0, 
   min_level integer NOT NULL DEFAULT 0, 
   max_level integer NOT NULL DEFAULT 0,
   is_disabled boolean NOT NULL DEFAULT false,
   status smallint NOT NULL,
   level_settings jsonb NOT NULL DEFAULT '[]',
   ctime timestamp without time zone NOT NULL DEFAULT timezone('utc'::text, now()), 
   PRIMARY KEY (id),
   FOREIGN KEY (creator_id) REFERENCES users (id) ON UPDATE NO ACTION ON DELETE CASCADE,
   CHECK (max_level >= min_level)
) 
WITH (
  OIDS = FALSE
)
;
CREATE TABLE skills
(
   id bigserial NOT NULL,
   rules_id bigint NOT NULL,
   title text NOT NULL,
   category_id bigint,
   base_value integer NOT NULL,
   max_value integer NOT NULL,
   player_can_change_value boolean NOT NULL,
   formula text NOT NULL,
   priority bigserial NOT NULL,
   is_disabled boolean NOT NULL DEFAULT false,
   ctime timestamp without time zone NOT NULL DEFAULT timezone('utc'::text, now()),
   PRIMARY KEY (id),
   FOREIGN KEY (rules_id) REFERENCES game_rules (id) ON UPDATE NO ACTION ON DELETE CASCADE,
   CHECK (max_value >= base_value)
) 
WITH (
  OIDS = FALSE
)
;

CREATE TABLE skills_categories
(
   id bigserial NOT NULL,
   title text NOT NULL,
   rules_id bigint NOT NULL,
   is_disabled boolean NOT NULL DEFAULT false,
   priority bigserial NOT NULL,
   base_value integer NOT NULL,
   ctime timestamp without time zone NOT NULL DEFAULT timezone('utc'::text, now()),

   PRIMARY KEY (id),
   FOREIGN KEY (rules_id) REFERENCES game_rules (id) ON UPDATE NO ACTION ON DELETE CASCADE
)
WITH (
  OIDS = FALSE
)
;
CREATE TABLE item_groups
(
   id bigserial NOT NULL, 
   rules_id bigint NOT NULL, 
   title text NOT NULL, 
   max_worn_items integer NOT NULL,
   priority bigserial NOT NULL,
   is_equippable boolean NOT NULL,
   is_usable boolean NOT NULL,
   has_charge boolean NOT NULL,
   has_durability boolean NOT NULL,
   has_damage boolean NOT NULL,
   is_disabled boolean NOT NULL DEFAULT false,
   ctime timestamp without time zone NOT NULL DEFAULT timezone('utc'::text, now()), 
   PRIMARY KEY (id), 
   FOREIGN KEY (rules_id) REFERENCES game_rules (id) ON UPDATE NO ACTION ON DELETE CASCADE

) 
WITH (
  OIDS = FALSE
)
;CREATE TABLE items
(
   id bigserial NOT NULL, 
   rules_id bigint NOT NULL, 
   group_id bigint NOT NULL,
   title text NOT NULL,
   attrs jsonb NOT NULL,
   skills jsonb NOT NULL,
   priority bigserial NOT NULL,
   is_disabled boolean NOT NULL DEFAULT false,
   ctime timestamp without time zone NOT NULL DEFAULT timezone('utc'::text, now()), 
   PRIMARY KEY (id), 
   FOREIGN KEY (group_id) REFERENCES item_groups (id) ON UPDATE NO ACTION ON DELETE CASCADE,
   FOREIGN KEY (rules_id) REFERENCES game_rules (id) ON UPDATE NO ACTION ON DELETE CASCADE
) 
WITH (
  OIDS = FALSE
)
;CREATE TABLE races
(
   id bigserial NOT NULL, 
   rules_id bigint NOT NULL, 
   title text NOT NULL,
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
;CREATE TABLE game_sessions
(
	id bigserial NOT NULL,
	rules_id bigint NOT NULL,
	status smallint NOT NULL,
	board_image bytea NOT NULL,
	ctime timestamp without time zone NOT NULL DEFAULT timezone('utc'::text, now()),

	PRIMARY KEY (id),
	FOREIGN KEY (rules_id) REFERENCES game_rules (id) ON UPDATE NO ACTION ON DELETE CASCADE
)
WITH (
	OIDS = FALSE
)
;

CREATE TABLE game_session_playfield_objects
(
	id bigserial NOT NULL,
	game_session_id bigint NOT NULL,
	type int NOT NULL,
	x decimal NOT NULL,
	y decimal NOT NULL,
	title TEXT NOT NULL DEFAULT '',
	attrs jsonb NOT NULL DEFAULT '{}',
	is_deleted BOOLEAN NOT NULL DEFAULT FALSE,

	PRIMARY KEY (id),
	FOREIGN KEY (game_session_id) REFERENCES game_sessions (id) ON UPDATE NO ACTION ON DELETE CASCADE
) WITH (
	OIDS = FALSE
)
;CREATE TABLE character_classes
(
   id bigserial NOT NULL, 
   rules_id bigint NOT NULL, 
   title text NOT NULL,
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
;CREATE TABLE session_characters
(
   id bigserial NOT NULL,
   user_id bigint NOT NULL,
   game_session_id bigint NOT NULL, 
   user_role text NOT NULL,
   level bigint NOT NULL DEFAULT 0,
   name text NOT NULL,
   skill_points jsonb NOT NULL DEFAULT '{}',
   skills jsonb NOT NULL DEFAULT '{}',
   items jsonb NOT NULL DEFAULT '{}',
   token CHAR(64),
   ctime timestamp without time zone NOT NULL DEFAULT timezone('utc'::text, now()),

   race_id bigint,
   class_id bigint,

   PRIMARY KEY (id), 
   FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE NO ACTION ON DELETE CASCADE, 
   FOREIGN KEY (game_session_id) REFERENCES game_sessions (id) ON UPDATE NO ACTION ON DELETE CASCADE,
   FOREIGN KEY (race_id) REFERENCES races (id) ON UPDATE NO ACTION ON DELETE CASCADE,
   FOREIGN KEY (class_id) REFERENCES character_classes (id) ON UPDATE NO ACTION ON DELETE CASCADE
) 
WITH (
  OIDS = FALSE
)
;

CREATE TABLE dices
(
    id bigserial NOT NULL,
    start_num integer NOT NULL,
    step integer NOT NULL,
    num_of_sides integer NOT NULL,

    PRIMARY KEY (id)
)
WITH (
    OIDS = FALSE
)
;

CREATE TABLE game_rules__dices
(
    id bigserial NOT NULL,
    rule_id integer NOT NULL,
    dice_id integer NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (rule_id) REFERENCES game_rules (id) ON UPDATE NO ACTION ON DELETE CASCADE,
    FOREIGN KEY (dice_id) REFERENCES dices (id) ON UPDATE NO ACTION ON DELETE CASCADE,
    CONSTRAINT game_rules__dices_key UNIQUE (rule_id, dice_id)
)
WITH (
    OIDS = FALSE
)
;
