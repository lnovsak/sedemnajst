--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- Name: posts_after_delete_row_tr(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION posts_after_delete_row_tr() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE users SET posts_count = posts_count - 1 WHERE id = OLD.user_id;
    UPDATE topics SET posts_count = posts_count - 1 WHERE id = OLD.topic_id;
    IF (OLD.remote_id IS NOT NULL AND OLD.remote_id =
        (SELECT last_post_remote_id FROM topics WHERE id = OLD.topic_id)) OR
         OLD.remote_created_at =
          (SELECT last_post_remote_created_at
           FROM topics WHERE id = OLD.topic_id) THEN
      UPDATE topics
      SET last_post_remote_created_at = last_posts.remote_created_at,
          last_post_remote_id = last_posts.remote_id
      FROM (
        SELECT max(remote_created_at) AS remote_created_at,
               max(remote_id) AS remote_id
        FROM posts
        WHERE topic_id = OLD.topic_id
      ) AS last_posts
      WHERE id = OLD.topic_id;
    END IF;
    RETURN NULL;
END;
$$;


--
-- Name: posts_after_insert_row_tr(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION posts_after_insert_row_tr() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE topics SET posts_count = posts_count + 1 WHERE id = NEW.topic_id;
    UPDATE topics SET last_post_remote_created_at = NEW.remote_created_at,
                      last_post_remote_id = NEW.remote_id
    WHERE id = NEW.topic_id;
    UPDATE users SET posts_count = posts_count + 1 WHERE id = NEW.user_id;
    RETURN NULL;
END;
$$;


--
-- Name: posts_after_update_row_tr(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION posts_after_update_row_tr() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.user_id != OLD.user_id THEN
      UPDATE users SET posts_count = posts_count - 1 WHERE id = OLD.user_id;
      UPDATE users SET posts_count = posts_count + 1 WHERE id = NEW.user_id;
    END IF;
    RETURN NULL;
END;
$$;


--
-- Name: posts_before_update_row_tr(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION posts_before_update_row_tr() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;


--
-- Name: topics_after_delete_row_tr(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION topics_after_delete_row_tr() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE users SET topics_count = topics_count - 1 WHERE id = OLD.user_id;
    RETURN NULL;
END;
$$;


--
-- Name: topics_after_insert_row_tr(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION topics_after_insert_row_tr() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE users SET topics_count = topics_count + 1 WHERE id = NEW.user_id;
    RETURN NULL;
END;
$$;


--
-- Name: topics_after_update_row_tr(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION topics_after_update_row_tr() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.user_id != OLD.user_id THEN
      UPDATE users SET topics_count = topics_count - 1 WHERE id = OLD.user_id;
      UPDATE users SET topics_count = topics_count + 1 WHERE id = NEW.user_id;
    END IF;
    RETURN NULL;
END;
$$;


--
-- Name: topics_before_update_row_tr(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION topics_before_update_row_tr() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;


--
-- Name: users_before_update_row_tr(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION users_before_update_row_tr() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: posts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE posts (
    id integer NOT NULL,
    body text NOT NULL,
    topic_id integer NOT NULL,
    user_id integer,
    remote_created_at timestamp with time zone NOT NULL,
    remote_id integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT remote_id_not_null_post_legacy CHECK (((timezone('UTC'::text, remote_created_at) <= '2013-02-03 13:12:55'::timestamp without time zone) OR (remote_id IS NOT NULL)))
);


--
-- Name: posts_by_dow; Type: MATERIALIZED VIEW; Schema: public; Owner: -; Tablespace: 
--

CREATE MATERIALIZED VIEW posts_by_dow AS
 SELECT (date_trunc('day'::text, posts.remote_created_at))::date AS day,
    (date_part('isodow'::text, posts.remote_created_at))::integer AS dow,
    count(*) AS posts_count
   FROM posts
  GROUP BY (date_trunc('day'::text, posts.remote_created_at))::date, (date_part('isodow'::text, posts.remote_created_at))::integer
  WITH NO DATA;


--
-- Name: posts_by_hod; Type: MATERIALIZED VIEW; Schema: public; Owner: -; Tablespace: 
--

CREATE MATERIALIZED VIEW posts_by_hod AS
 SELECT (date_trunc('day'::text, posts.remote_created_at))::date AS day,
    (date_part('hour'::text, posts.remote_created_at))::integer AS hod,
    count(*) AS posts_count
   FROM posts
  GROUP BY (date_trunc('day'::text, posts.remote_created_at))::date, (date_part('hour'::text, posts.remote_created_at))::integer
  WITH NO DATA;


--
-- Name: posts_by_hour; Type: MATERIALIZED VIEW; Schema: public; Owner: -; Tablespace: 
--

CREATE MATERIALIZED VIEW posts_by_hour AS
 SELECT date_trunc('hour'::text, posts.remote_created_at) AS hour,
    count(*) AS posts_count
   FROM posts
  GROUP BY date_trunc('hour'::text, posts.remote_created_at)
  WITH NO DATA;


--
-- Name: posts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE posts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE posts_id_seq OWNED BY posts.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: topics; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE topics (
    id integer NOT NULL,
    title character varying(255) NOT NULL,
    user_id integer,
    remote_id integer NOT NULL,
    posts_count integer DEFAULT 0 NOT NULL,
    last_post_remote_created_at timestamp with time zone,
    last_post_remote_id integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: topics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE topics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: topics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE topics_id_seq OWNED BY topics.id;


--
-- Name: user_posts_by_dow; Type: MATERIALIZED VIEW; Schema: public; Owner: -; Tablespace: 
--

CREATE MATERIALIZED VIEW user_posts_by_dow AS
 SELECT posts.user_id,
    (date_trunc('day'::text, posts.remote_created_at))::date AS day,
    (date_part('isodow'::text, posts.remote_created_at))::integer AS dow,
    count(*) AS posts_count
   FROM posts
  GROUP BY posts.user_id, (date_trunc('day'::text, posts.remote_created_at))::date, (date_part('isodow'::text, posts.remote_created_at))::integer
  WITH NO DATA;


--
-- Name: user_posts_by_hod; Type: MATERIALIZED VIEW; Schema: public; Owner: -; Tablespace: 
--

CREATE MATERIALIZED VIEW user_posts_by_hod AS
 SELECT posts.user_id,
    (date_trunc('day'::text, posts.remote_created_at))::date AS day,
    (date_part('hour'::text, posts.remote_created_at))::integer AS hod,
    count(*) AS posts_count
   FROM posts
  GROUP BY posts.user_id, (date_trunc('day'::text, posts.remote_created_at))::date, (date_part('hour'::text, posts.remote_created_at))::integer
  WITH NO DATA;


--
-- Name: user_posts_by_hour; Type: MATERIALIZED VIEW; Schema: public; Owner: -; Tablespace: 
--

CREATE MATERIALIZED VIEW user_posts_by_hour AS
 SELECT posts.user_id,
    date_trunc('hour'::text, posts.remote_created_at) AS hour,
    count(*) AS posts_count
   FROM posts
  GROUP BY posts.user_id, date_trunc('hour'::text, posts.remote_created_at)
  WITH NO DATA;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    remote_id integer NOT NULL,
    posts_count integer DEFAULT 0 NOT NULL,
    topics_count integer DEFAULT 0 NOT NULL,
    avatar_file_name character varying(255),
    avatar_content_type character varying(255),
    avatar_file_size integer,
    avatar_updated_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    password_requested_by_ip character varying(255),
    password_digest character varying(255),
    password_request_token character varying(255),
    password_requested_at timestamp with time zone
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY posts ALTER COLUMN id SET DEFAULT nextval('posts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY topics ALTER COLUMN id SET DEFAULT nextval('topics_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (id);


--
-- Name: topics_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY topics
    ADD CONSTRAINT topics_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_posts_by_dow_on_day; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_posts_by_dow_on_day ON posts_by_dow USING btree (day);


--
-- Name: index_posts_by_dow_on_dow; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_posts_by_dow_on_dow ON posts_by_dow USING btree (dow);


--
-- Name: index_posts_by_hod_on_day; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_posts_by_hod_on_day ON posts_by_hod USING btree (day);


--
-- Name: index_posts_by_hod_on_hod; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_posts_by_hod_on_hod ON posts_by_hod USING btree (hod);


--
-- Name: index_posts_by_hour_on_hour; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_posts_by_hour_on_hour ON posts_by_hour USING btree (hour);


--
-- Name: index_posts_on_remote_created_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_posts_on_remote_created_at ON posts USING btree (remote_created_at);


--
-- Name: index_posts_on_remote_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_posts_on_remote_id ON posts USING btree (remote_id);


--
-- Name: index_posts_on_topic_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_posts_on_topic_id ON posts USING btree (topic_id);


--
-- Name: index_posts_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_posts_on_user_id ON posts USING btree (user_id);


--
-- Name: index_topics_on_last_post_remote_created_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_topics_on_last_post_remote_created_at ON topics USING btree (last_post_remote_created_at);


--
-- Name: index_topics_on_last_post_remote_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_topics_on_last_post_remote_id ON topics USING btree (last_post_remote_id);


--
-- Name: index_topics_on_remote_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_topics_on_remote_id ON topics USING btree (remote_id);


--
-- Name: index_topics_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_topics_on_user_id ON topics USING btree (user_id);


--
-- Name: index_user_posts_by_dow_on_day; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_user_posts_by_dow_on_day ON user_posts_by_dow USING btree (day);


--
-- Name: index_user_posts_by_dow_on_dow; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_user_posts_by_dow_on_dow ON user_posts_by_dow USING btree (dow);


--
-- Name: index_user_posts_by_dow_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_user_posts_by_dow_on_user_id ON user_posts_by_dow USING btree (user_id);


--
-- Name: index_user_posts_by_hod_on_day; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_user_posts_by_hod_on_day ON user_posts_by_hod USING btree (day);


--
-- Name: index_user_posts_by_hod_on_hod; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_user_posts_by_hod_on_hod ON user_posts_by_hod USING btree (hod);


--
-- Name: index_user_posts_by_hod_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_user_posts_by_hod_on_user_id ON user_posts_by_hod USING btree (user_id);


--
-- Name: index_user_posts_by_hour_on_hour; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_user_posts_by_hour_on_hour ON user_posts_by_hour USING btree (hour);


--
-- Name: index_user_posts_by_hour_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_user_posts_by_hour_on_user_id ON user_posts_by_hour USING btree (user_id);


--
-- Name: index_users_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_name ON users USING btree (lower((name)::text));


--
-- Name: index_users_on_password_request_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_password_request_token ON users USING btree (password_request_token);


--
-- Name: index_users_on_remote_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_remote_id ON users USING btree (remote_id);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: posts_after_delete_row_tr; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER posts_after_delete_row_tr AFTER DELETE ON posts FOR EACH ROW EXECUTE PROCEDURE posts_after_delete_row_tr();


--
-- Name: posts_after_insert_row_tr; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER posts_after_insert_row_tr AFTER INSERT ON posts FOR EACH ROW EXECUTE PROCEDURE posts_after_insert_row_tr();


--
-- Name: posts_after_update_row_tr; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER posts_after_update_row_tr AFTER UPDATE ON posts FOR EACH ROW EXECUTE PROCEDURE posts_after_update_row_tr();


--
-- Name: posts_before_update_row_tr; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER posts_before_update_row_tr BEFORE UPDATE ON posts FOR EACH ROW EXECUTE PROCEDURE posts_before_update_row_tr();


--
-- Name: topics_after_delete_row_tr; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER topics_after_delete_row_tr AFTER DELETE ON topics FOR EACH ROW EXECUTE PROCEDURE topics_after_delete_row_tr();


--
-- Name: topics_after_insert_row_tr; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER topics_after_insert_row_tr AFTER INSERT ON topics FOR EACH ROW EXECUTE PROCEDURE topics_after_insert_row_tr();


--
-- Name: topics_after_update_row_tr; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER topics_after_update_row_tr AFTER UPDATE ON topics FOR EACH ROW EXECUTE PROCEDURE topics_after_update_row_tr();


--
-- Name: topics_before_update_row_tr; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER topics_before_update_row_tr BEFORE UPDATE ON topics FOR EACH ROW EXECUTE PROCEDURE topics_before_update_row_tr();


--
-- Name: users_before_update_row_tr; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER users_before_update_row_tr BEFORE UPDATE ON users FOR EACH ROW EXECUTE PROCEDURE users_before_update_row_tr();


--
-- Name: posts_topic_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY posts
    ADD CONSTRAINT posts_topic_id_fk FOREIGN KEY (topic_id) REFERENCES topics(id);


--
-- Name: posts_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY posts
    ADD CONSTRAINT posts_user_id_fk FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: topics_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY topics
    ADD CONSTRAINT topics_user_id_fk FOREIGN KEY (user_id) REFERENCES users(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user",public;

INSERT INTO schema_migrations (version) VALUES ('20140609205518');

INSERT INTO schema_migrations (version) VALUES ('20140701124753');

INSERT INTO schema_migrations (version) VALUES ('20140704091318');

INSERT INTO schema_migrations (version) VALUES ('20140712092031');

INSERT INTO schema_migrations (version) VALUES ('20140712124444');

INSERT INTO schema_migrations (version) VALUES ('20140712140036');

INSERT INTO schema_migrations (version) VALUES ('20140712143841');

INSERT INTO schema_migrations (version) VALUES ('20140712174114');

INSERT INTO schema_migrations (version) VALUES ('20140712211229');

INSERT INTO schema_migrations (version) VALUES ('20140712211240');

INSERT INTO schema_migrations (version) VALUES ('20140712214123');

INSERT INTO schema_migrations (version) VALUES ('20140714115051');

INSERT INTO schema_migrations (version) VALUES ('20140714154002');

INSERT INTO schema_migrations (version) VALUES ('20140717214142');

INSERT INTO schema_migrations (version) VALUES ('20140717220325');

INSERT INTO schema_migrations (version) VALUES ('20140717222059');

INSERT INTO schema_migrations (version) VALUES ('20140717225102');

INSERT INTO schema_migrations (version) VALUES ('20140718200851');

INSERT INTO schema_migrations (version) VALUES ('20140718211128');

INSERT INTO schema_migrations (version) VALUES ('20140719142420');

INSERT INTO schema_migrations (version) VALUES ('20140719213305');

