--
-- PostgreSQL database dump
--

\restrict 3HabKQ2Euu5WWfMOCzzvDw0ytS9NibXveEeX8MN3RSO7BZHuFWLk3jp51C4JMr6

-- Dumped from database version 16.15 (Debian 16.15-1.pgdg12+2)
-- Dumped by pg_dump version 16.15 (Debian 16.15-1.pgdg12+2)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: beauty_profiles; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.beauty_profiles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id integer NOT NULL,
    face_scores jsonb NOT NULL,
    hands_diagnosis jsonb NOT NULL,
    recommendation text NOT NULL,
    recommended_products jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    entry_point character varying(50) DEFAULT 'ideas'::character varying
);


ALTER TABLE public.beauty_profiles OWNER TO admin;

--
-- Name: biometric_consents; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.biometric_consents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id integer NOT NULL,
    version character varying(20) NOT NULL,
    accepted_at timestamp with time zone DEFAULT now(),
    ip character varying(45),
    user_agent text,
    revoked_at timestamp with time zone,
    active boolean DEFAULT true,
    consent_type character varying(50),
    granted boolean DEFAULT false,
    granted_at timestamp without time zone,
    purpose text,
    ip_address inet,
    version_terms character varying(20) DEFAULT '1.0'::character varying,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.biometric_consents OWNER TO admin;

--
-- Data for Name: beauty_profiles; Type: TABLE DATA; Schema: public; Owner: admin
--

COPY public.beauty_profiles (id, user_id, face_scores, hands_diagnosis, recommendation, recommended_products, created_at, updated_at, entry_point) FROM stdin;
d2641013-5364-4e85-82a6-02a5201031f7	7	{"score": 0.8}	{"dry": false}	Hidratación diaria	\N	2026-09-29 07:27:33.442423+00	2026-09-29 07:27:33.442423+00	ideas
baa70b71-5138-4698-8aff-ceac98e35832	4	{"score": 0.9}	{"dry": true}	Exfoliación semanal	\N	2026-09-29 07:27:33.442423+00	2026-09-29 07:27:33.442423+00	ideas
698460b3-db50-4d73-95f6-ed9350b6f24b	6	{"score": 0.7}	{"dry": false}	Protector solar	\N	2026-09-29 07:27:33.442423+00	2026-09-29 07:27:33.442423+00	ideas
\.


--
-- Data for Name: biometric_consents; Type: TABLE DATA; Schema: public; Owner: admin
--

COPY public.biometric_consents (id, user_id, version, accepted_at, ip, user_agent, revoked_at, active, consent_type, granted, granted_at, purpose, ip_address, version_terms, created_at, updated_at) FROM stdin;
fe99f50a-21a2-4a6a-8f3c-42a3c05e633b	7	1.0	2026-09-29 07:27:18.856236+00	\N	\N	\N	t	facial_analysis	t	2026-09-29 07:27:18.856236	Análisis facial para recomendaciones	192.168.1.1	1.0	2026-09-29 07:27:18.856236	2026-09-29 07:27:18.856236
5eb1112e-f2b6-4005-a6c8-cb460daee32c	4	1.0	2026-09-29 07:27:18.856236+00	\N	\N	\N	t	skin_scan	t	2026-09-29 07:27:18.856236	Escaneo de piel	192.168.1.2	1.0	2026-09-29 07:27:18.856236	2026-09-29 07:27:18.856236
a2580bbe-c17a-4ddc-a6d3-0e7c163e5cd2	6	1.0	2026-09-29 07:27:18.856236+00	\N	\N	\N	t	hair_analysis	t	2026-09-29 07:27:18.856236	Análisis capilar	192.168.1.3	1.0	2026-09-29 07:27:18.856236	2026-09-29 07:27:18.856236
\.


--
-- Name: beauty_profiles beauty_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.beauty_profiles
    ADD CONSTRAINT beauty_profiles_pkey PRIMARY KEY (id);


--
-- Name: biometric_consents biometric_consents_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.biometric_consents
    ADD CONSTRAINT biometric_consents_pkey PRIMARY KEY (id);


--
-- Name: biometric_consents biometric_consents_user_consent_version_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.biometric_consents
    ADD CONSTRAINT biometric_consents_user_consent_version_key UNIQUE (user_id, consent_type, version_terms);


--
-- Name: beauty_profiles unique_beauty_profiles_user_id; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.beauty_profiles
    ADD CONSTRAINT unique_beauty_profiles_user_id UNIQUE (user_id);


--
-- Name: idx_beauty_profiles_user_id; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_beauty_profiles_user_id ON public.beauty_profiles USING btree (user_id);


--
-- Name: idx_biometric_consents_user_id; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_biometric_consents_user_id ON public.biometric_consents USING btree (user_id);


--
-- Name: idx_consents_audit; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_consents_audit ON public.biometric_consents USING btree (granted_at, revoked_at);


--
-- Name: idx_consents_user; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_consents_user ON public.biometric_consents USING btree (user_id, consent_type, granted);


--
-- Name: unique_active_consent; Type: INDEX; Schema: public; Owner: admin
--

CREATE UNIQUE INDEX unique_active_consent ON public.biometric_consents USING btree (user_id) WHERE (active = true);


--
-- Name: biometric_consents trigger_update_consent_timestamp; Type: TRIGGER; Schema: public; Owner: admin
--

CREATE TRIGGER trigger_update_consent_timestamp BEFORE UPDATE ON public.biometric_consents FOR EACH ROW EXECUTE FUNCTION public.update_consent_timestamp();


--
-- Name: beauty_profiles beauty_profiles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.beauty_profiles
    ADD CONSTRAINT beauty_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.usuarios(id) ON DELETE CASCADE;


--
-- Name: biometric_consents biometric_consents_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.biometric_consents
    ADD CONSTRAINT biometric_consents_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.usuarios(id) ON DELETE CASCADE;


--
-- Name: TABLE beauty_profiles; Type: ACL; Schema: public; Owner: admin
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.beauty_profiles TO app_runtime_user;
GRANT ALL ON TABLE public.beauty_profiles TO beauty_app_user;
GRANT ALL ON TABLE public.beauty_profiles TO app_user;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.beauty_profiles TO app_rls_user;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.beauty_profiles TO app_system;


--
-- Name: TABLE biometric_consents; Type: ACL; Schema: public; Owner: admin
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.biometric_consents TO app_runtime_user;
GRANT ALL ON TABLE public.biometric_consents TO beauty_app_user;
GRANT ALL ON TABLE public.biometric_consents TO app_user;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.biometric_consents TO app_rls_user;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.biometric_consents TO app_system;


--
-- PostgreSQL database dump complete
--

\unrestrict 3HabKQ2Euu5WWfMOCzzvDw0ytS9NibXveEeX8MN3RSO7BZHuFWLk3jp51C4JMr6

