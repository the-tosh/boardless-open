CREATE TABLE beta_invites
(
   id bigserial NOT NULL,
   hash text NOT NULL,
   is_used boolean NOT NULL DEFAULT FALSE,
   activation_time timestamp,
   user_id bigint,
   ctime timestamp without time zone NOT NULL DEFAULT timezone('utc'::text, now()),

   PRIMARY KEY (id)
) 
WITH (
  OIDS = FALSE
)
;