-- Role: windmill_user
-- DROP ROLE IF EXISTS windmill_user;

CREATE ROLE windmill_user WITH
  NOLOGIN
  NOSUPERUSER
  INHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION
  NOBYPASSRLS;

-- Role: windmill_admin
-- DROP ROLE IF EXISTS windmill_admin;

CREATE ROLE windmill_admin WITH
  NOLOGIN
  NOSUPERUSER
  INHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION
  BYPASSRLS;

GRANT windmill_user TO windmill_admin;

-- FUNCTION: public.notify_workspace_premium_change()

-- DROP FUNCTION IF EXISTS public.notify_workspace_premium_change();

CREATE OR REPLACE FUNCTION public.notify_workspace_premium_change()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
BEGIN
    PERFORM pg_notify('notify_workspace_premium_change', NEW.id);
    RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.notify_workspace_premium_change()
    OWNER TO root;

-- FUNCTION: public.notify_token_invalidation()

-- DROP FUNCTION IF EXISTS public.notify_token_invalidation();

CREATE OR REPLACE FUNCTION public.notify_token_invalidation()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
BEGIN
    -- Only notify for session token deletions when the invalidation settings are enabled
    IF OLD.label = 'session' AND OLD.email IS NOT NULL THEN
        PERFORM pg_notify('notify_token_invalidation', OLD.token);
    END IF;
    RETURN OLD;
END;
$BODY$;

ALTER FUNCTION public.notify_token_invalidation()
    OWNER TO root;

-- Table: public.workspace

-- DROP TABLE IF EXISTS public.workspace;

CREATE TABLE IF NOT EXISTS public.workspace
(
    id character varying(50) COLLATE pg_catalog."default" NOT NULL,
    name character varying(50) COLLATE pg_catalog."default" NOT NULL,
    owner character varying(50) COLLATE pg_catalog."default" NOT NULL,
    deleted boolean NOT NULL DEFAULT false,
    premium boolean NOT NULL DEFAULT false,
    parent_workspace_id character varying(50) COLLATE pg_catalog."default",
    CONSTRAINT workspace_pkey PRIMARY KEY (id),
    CONSTRAINT workspace_parent_workspace_id_fkey FOREIGN KEY (parent_workspace_id)
        REFERENCES public.workspace (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE SET NULL,
    CONSTRAINT proper_id CHECK (id::text ~ '^\w+(-\w+)*$'::text)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.workspace
    OWNER to root;

GRANT ALL ON TABLE public.workspace TO root;

GRANT ALL ON TABLE public.workspace TO windmill_admin;

GRANT ALL ON TABLE public.workspace TO windmill_user;
-- Index: workspace_parent_idx

-- DROP INDEX IF EXISTS public.workspace_parent_idx;

CREATE INDEX IF NOT EXISTS workspace_parent_idx
    ON public.workspace USING btree
    (parent_workspace_id COLLATE pg_catalog."default" ASC NULLS LAST)
    WITH (fillfactor=100, deduplicate_items=True)
    TABLESPACE pg_default
    WHERE parent_workspace_id IS NOT NULL;

-- Trigger: workspace_premium_change_trigger

-- DROP TRIGGER IF EXISTS workspace_premium_change_trigger ON public.workspace;

CREATE OR REPLACE TRIGGER workspace_premium_change_trigger
    AFTER UPDATE OF premium
    ON public.workspace
    FOR EACH ROW
    EXECUTE FUNCTION public.notify_workspace_premium_change();

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
  'admin@windmill.dev',
  true
);