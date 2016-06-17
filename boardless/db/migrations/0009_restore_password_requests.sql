CREATE TABLE restore_password_requests
(
   id bigserial NOT NULL,
   user_id bigint NOT NULL,
   hash text NOT NULL,
   is_used boolean NOT NULL DEFAULT false,
   ctime timestamp without time zone NOT NULL DEFAULT timezone('utc'::text, now()),
   PRIMARY KEY (id),
   FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE NO ACTION ON DELETE CASCADE
) 
WITH (
  OIDS = FALSE
)
;