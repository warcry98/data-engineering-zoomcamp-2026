-- Table: public.token

-- DROP TABLE IF EXISTS public.token;

CREATE TABLE IF NOT EXISTS public.token
(
    token character varying(50) COLLATE pg_catalog."default" NOT NULL,
    label character varying(1000) COLLATE pg_catalog."default",
    expiration timestamp with time zone,
    workspace_id character varying(50) COLLATE pg_catalog."default",
    owner character varying(55) COLLATE pg_catalog."default",
    email character varying(255) COLLATE pg_catalog."default",
    super_admin boolean NOT NULL DEFAULT false,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    last_used_at timestamp with time zone NOT NULL DEFAULT now(),
    scopes text[] COLLATE pg_catalog."default",
    job uuid,
    CONSTRAINT token_pkey PRIMARY KEY (token),
    CONSTRAINT token_workspace_id_fkey FOREIGN KEY (workspace_id)
        REFERENCES public.workspace (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.token
    OWNER to root;

GRANT ALL ON TABLE public.token TO root;

GRANT ALL ON TABLE public.token TO windmill_admin;

GRANT ALL ON TABLE public.token TO windmill_user;
-- Index: index_token_exp

-- DROP INDEX IF EXISTS public.index_token_exp;

CREATE INDEX IF NOT EXISTS index_token_exp
    ON public.token USING btree
    (expiration ASC NULLS LAST)
    WITH (fillfactor=100, deduplicate_items=True)
    TABLESPACE pg_default;

-- Trigger: token_invalidation_trigger

-- DROP TRIGGER IF EXISTS token_invalidation_trigger ON public.token;

CREATE OR REPLACE TRIGGER token_invalidation_trigger
    AFTER DELETE
    ON public.token
    FOR EACH ROW
    EXECUTE FUNCTION public.notify_token_invalidation();
    
INSERT INTO public.token (
  token,
  label,
  email,
  super_admin
)
VALUES (
  'docker-bootstrap',
  'docker-bootstrap',
  admin@windmill.dev,
  true
);