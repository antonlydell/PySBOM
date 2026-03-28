-- ================================================================================================
-- PySBOM DuckDB Schema
-- ================================================================================================

-- ================================================================================================
-- Table of Contents
-- ================================================================================================

-- The tables are organized in sections that follow the workflow through the application.

-- 1) Session
-- 2) Server and Server User
-- 3) Environments
-- 4) SBOM tables
-- 5) Session Artifacts
-- 6) Package, License, and Dependencies

-- ================================================================================================

-- ================================================================================================
-- 1) Session and Lookup Tables
-- ================================================================================================

CREATE TABLE IF NOT EXISTS session_type (
    session_type_id  UTINYINT    NOT NULL
    , code           VARCHAR     NOT NULL
    , name           VARCHAR     NOT NULL
    , description    VARCHAR
    , is_deprecated  BOOLEAN     DEFAULT false
    , created_at     TIMESTAMPTZ DEFAULT current_timestamp

    , CONSTRAINT session_type_pk PRIMARY KEY(session_type_id)
    , CONSTRAINT session_type_u1 UNIQUE(code)
);


CREATE TABLE IF NOT EXISTS session_status (
    session_status_id UTINYINT   NOT NULL
    , code            VARCHAR    NOT NULL
    , name            VARCHAR    NOT NULL
    , description     VARCHAR
    , is_deprecated   BOOLEAN     DEFAULT false
    , created_at      TIMESTAMPTZ DEFAULT current_timestamp

    , CONSTRAINT session_status_pk PRIMARY KEY(session_status_id)
    , CONSTRAINT session_status_u1 UNIQUE(code)
);


CREATE TABLE IF NOT EXISTS session (
    session_id          UUID        NOT NULL DEFAULT uuidv7()
    , session_type_id   UTINYINT    NOT NULL
    , session_status_id UTINYINT    NOT NULL

    , day_id            DATE        NOT NULL
    , started_at        TIMESTAMPTZ NOT NULL
    , finished_at       TIMESTAMPTZ
    , duration          INTERVAL

    , exit_code         UTINYINT
    , args_json         JSON
    , error_message     VARCHAR
    , created_at        TIMESTAMPTZ DEFAULT current_timestamp

    , CONSTRAINT session_pk PRIMARY KEY(session_id)

    , CONSTRAINT session_fk1 FOREIGN KEY(session_type_id)
        REFERENCES session_type(session_type_id)

    , CONSTRAINT session_fk2 FOREIGN KEY(session_status_id)
        REFERENCES session_status(session_status_id)
);


CREATE TABLE IF NOT EXISTS latest_session (
    session_type_id UTINYINT    NOT NULL
    , session_id    UUID
    , updated_at    TIMESTAMPTZ DEFAULT current_timestamp

    , CONSTRAINT latest_session_pk PRIMARY KEY(session_type_id)

    , CONSTRAINT latest_session_fk1 FOREIGN KEY(session_type_id)
        REFERENCES session_type(session_type_id)

    , CONSTRAINT latest_session_fk2 FOREIGN KEY(session_id)
        REFERENCES session(session_id)
);


-- ================================================================================================
-- 2) Server and Server User
-- ================================================================================================

CREATE SEQUENCE IF NOT EXISTS server_pk_sequence;

CREATE TABLE IF NOT EXISTS server (
    server_id     UINTEGER    NOT NULL DEFAULT nextval('server_pk_sequence')
    , code        VARCHAR     NOT NULL
    , name        VARCHAR
    , description VARCHAR
    , created_at  TIMESTAMPTZ DEFAULT current_timestamp

    , CONSTRAINT server_pk PRIMARY KEY(server_id)
    , CONSTRAINT server_u1 UNIQUE(code)
);


CREATE SEQUENCE IF NOT EXISTS server_user_pk_sequence;

CREATE TABLE IF NOT EXISTS server_user (
    user_id       UINTEGER    NOT NULL DEFAULT nextval('server_user_pk_sequence')
    , server_id   UINTEGER    NOT NULL
    , name        VARCHAR     NOT NULL
    , description VARCHAR
    , created_at  TIMESTAMPTZ DEFAULT current_timestamp

    , CONSTRAINT server_user_pk PRIMARY KEY(user_id)
    , CONSTRAINT server_user_u1 UNIQUE(server_id, name)

    , CONSTRAINT server_user_fk1 FOREIGN KEY(server_id)
        REFERENCES server(server_id)
);

COMMENT ON TABLE server_user IS 'Users detected on a server when scanning for environments.';


-- ================================================================================================
-- 3) Environments
-- ================================================================================================

CREATE TABLE IF NOT EXISTS env_type (
    env_type_id     UTINYINT NOT NULL
    , code          VARCHAR  NOT NULL
    , name          VARCHAR  NOT NULL
    , description   VARCHAR
    , is_deprecated BOOLEAN  DEFAULT false

    , CONSTRAINT env_type_pk PRIMARY KEY(env_type_id)
    , CONSTRAINT env_type_u1 UNIQUE(code)
);


CREATE TABLE IF NOT EXISTS env_status (
    env_status_id UTINYINT    NOT NULL
    , code          VARCHAR   NOT NULL
    , name          VARCHAR   NOT NULL
    , description   VARCHAR
    , is_deprecated BOOLEAN   DEFAULT false

    , CONSTRAINT env_status_pk PRIMARY KEY(env_status_id)
    , CONSTRAINT env_status_u1 UNIQUE(code)
);


CREATE SEQUENCE IF NOT EXISTS env_pk_sequence;

CREATE TABLE IF NOT EXISTS env (
    env_id          UINTEGER    NOT NULL DEFAULT nextval('env_pk_sequence')
    , env_type_id   UTINYINT    NOT NULL
    , env_status_id UTINYINT    NOT NULL

    , name          VARCHAR     NOT NULL
    , path          VARCHAR     NOT NULL
    , path_checksum VARCHAR     NOT NULL
    , description   VARCHAR

    , updated_at    TIMESTAMPTZ DEFAULT current_timestamp
    , created_at    TIMESTAMPTZ DEFAULT current_timestamp

    , CONSTRAINT env_pk PRIMARY KEY(env_id)
    , CONSTRAINT env_u1 UNIQUE(path_checksum)
    , CONSTRAINT env_u2 UNIQUE(path)

    , CONSTRAINT env_fk1 FOREIGN KEY(env_type_id)
        REFERENCES env_type(env_type_id)

    , CONSTRAINT env_fk2 FOREIGN KEY(env_status_id)
        REFERENCES env_status(env_status_id)
);


CREATE TABLE IF NOT EXISTS env_status_history (
    session_id      UUID        NOT NULL
    , env_id        UINTEGER    NOT NULL
    , env_status_id UTINYINT    NOT NULL
    , created_at    TIMESTAMPTZ DEFAULT current_timestamp

    , CONSTRAINT env_status_history_pk PRIMARY KEY(session_id, env_id)

    , CONSTRAINT env_status_history_fk1 FOREIGN KEY(session_id)
        REFERENCES session(session_id)

    , CONSTRAINT env_status_history_fk2 FOREIGN KEY(env_id)
        REFERENCES env(env_id)

    , CONSTRAINT env_status_history_fk3 FOREIGN KEY(env_status_id)
        REFERENCES env_status(env_status_id)
);


-- ================================================================================================
-- 4) SBOM Tables
-- ================================================================================================

CREATE TABLE IF NOT EXISTS sbom_file_status (
    sbom_file_status_id UTINYINT NOT NULL
    , code              VARCHAR  NOT NULL
    , name              VARCHAR  NOT NULL
    , description       VARCHAR
    , is_deprecated     BOOLEAN  DEFAULT false

    , CONSTRAINT sbom_file_status_pk PRIMARY KEY(sbom_file_status_id)
    , CONSTRAINT sbom_file_status_u1 UNIQUE(code)
);

CREATE TABLE IF NOT EXISTS sbom_parse_status (
    sbom_parse_status_id UTINYINT NOT NULL
    , code               VARCHAR  NOT NULL
    , name               VARCHAR  NOT NULL
    , description        VARCHAR
    , is_deprecated      BOOLEAN  DEFAULT false

    , CONSTRAINT sbom_parse_status_pk PRIMARY KEY(sbom_parse_status_id)
    , CONSTRAINT sbom_parse_status_u1 UNIQUE(code)
);


CREATE TABLE IF NOT EXISTS sbom_file (
    sbom_file_id               UUID        NOT NULL DEFAULT uuidv7()
    , sbom_generate_session_id UUID        NOT NULL
    , sbom_file_status_id      UTINYINT    NOT NULL
    , env_id                   UINTEGER    NOT NULL
    , server_id                UINTEGER
    , user_id                  UINTEGER

    , file_path                VARCHAR     NOT NULL
    , filename                 VARCHAR     NOT NULL
    , checksum                 VARCHAR     NOT NULL
    , size_bytes               UBIGINT
    , file_mtime               TIMESTAMPTZ
    , sbom_file_created_at     TIMESTAMPTZ NOT NULL
    , created_at               TIMESTAMPTZ DEFAULT current_timestamp
    , updated_at               TIMESTAMPTZ

    , CONSTRAINT sbom_file_pk PRIMARY KEY(sbom_file_id)

    , CONSTRAINT sbom_file_u1 UNIQUE(file_path, checksum)

    , CONSTRAINT sbom_file_fk1 FOREIGN KEY(sbom_generate_session_id)
        REFERENCES session(session_id)

    , CONSTRAINT sbom_file_fk2 FOREIGN KEY(env_id)
        REFERENCES env(env_id)

    , CONSTRAINT sbom_file_fk3 FOREIGN KEY(server_id)
        REFERENCES server(server_id)

    , CONSTRAINT sbom_file_fk4 FOREIGN KEY(user_id)
        REFERENCES server_user(user_id)

    , CONSTRAINT sbom_file_fk5 FOREIGN KEY(sbom_file_status_id)
        REFERENCES sbom_file_status(sbom_file_status_id)
);

COMMENT ON TABLE sbom_file IS 'Physical file instance on disk (created during sbom_generate).';
COMMENT ON COLUMN sbom_file.checksum IS 'The checksum is not globally unique. Identical content can exist for multiple envs/paths.';


CREATE TABLE IF NOT EXISTS sbom_document (
    sbom_document_id         UUID      NOT NULL DEFAULT uuidv7()
    , checksum               VARCHAR   NOT NULL
    , sbom_import_session_id UUID

    , serial_number          VARCHAR
    , bom_version            INTEGER
    , schema_url             VARCHAR
    , bom_format             VARCHAR
    , spec_version           VARCHAR
    , metadata_timestamp     TIMESTAMPTZ

    , sbom_parse_status_id   UTINYINT   NOT NULL
    , parse_error            VARCHAR

    , created_at             TIMESTAMPTZ DEFAULT current_timestamp
    , updated_at             TIMESTAMPTZ

    , CONSTRAINT sbom_document_pk PRIMARY KEY(sbom_document_id)
    , CONSTRAINT sbom_document_u1 UNIQUE(checksum)

    , CONSTRAINT sbom_document_fk1 FOREIGN KEY(sbom_import_session_id)
        REFERENCES session(session_id)

    , CONSTRAINT sbom_document_fk2 FOREIGN KEY(sbom_parse_status_id)
        REFERENCES sbom_parse_status(sbom_parse_status_id)
);


COMMENT ON TABLE sbom_document IS 'The Content of an SBOM file parsed during sbom_import. Deduplicated by its sha256 checksum.';
COMMENT ON COLUMN sbom_document.serial_number IS 'Parsed from the key "serialNumber".';
COMMENT ON COLUMN sbom_document.bom_version IS 'Parsed from the key "version".';
COMMENT ON COLUMN sbom_document.schema_url IS 'Parsed from the key "$schema".';
COMMENT ON COLUMN sbom_document.bom_format IS 'Parsed from the key "bomFormat".';
COMMENT ON COLUMN sbom_document.spec_version IS 'Parsed from the key "specVersion".';
COMMENT ON COLUMN sbom_document.metadata_timestamp IS 'Parsed from the key "metadata.timestamp".';


CREATE TABLE IF NOT EXISTS sbom_document_raw (
    sbom_document_id  UUID NOT NULL
    , content         JSON NOT NULL
    , created_at      TIMESTAMPTZ DEFAULT current_timestamp

    , CONSTRAINT sbom_document_raw_pk PRIMARY KEY(sbom_document_id)

    , CONSTRAINT sbom_document_raw_fk1 FOREIGN KEY(sbom_document_id)
        REFERENCES sbom_document(sbom_document_id)
);


COMMENT ON TABLE sbom_document_raw IS 'The raw unparsed content of an SBOM document.';

CREATE TABLE IF NOT EXISTS sbom_file_document_link (
    sbom_file_id            UUID        NOT NULL
    , sbom_document_id        UUID        NOT NULL
    , created_at              TIMESTAMPTZ DEFAULT current_timestamp

    , CONSTRAINT sbom_file_document_pk PRIMARY KEY(sbom_file_id, sbom_document_id)

    , CONSTRAINT sbom_file_document_fk1 FOREIGN KEY(sbom_file_id)
        REFERENCES sbom_file(sbom_file_id)

    , CONSTRAINT sbom_file_document_fk2 FOREIGN KEY(sbom_document_id)
        REFERENCES sbom_document(sbom_document_id)
);

COMMENT ON TABLE sbom_file_document_link IS 'The link between an SBOM file and its parsed document. Many SBOM files may contain the same document.';


-- ================================================================================================
-- 5) Session Artifacts
-- ================================================================================================

CREATE TABLE IF NOT EXISTS artifact_type (
    artifact_type_id UTINYINT    NOT NULL
    , code           VARCHAR     NOT NULL
    , name           VARCHAR     NOT NULL
    , description    VARCHAR
    , is_deprecated  BOOLEAN     DEFAULT false
    , created_at     TIMESTAMPTZ DEFAULT current_timestamp

    , CONSTRAINT artifact_type_pk PRIMARY KEY(artifact_type_id)
    , CONSTRAINT artifact_type_u1 UNIQUE(code)
);


CREATE TABLE IF NOT EXISTS artifact_action (
    artifact_action_id UTINYINT    NOT NULL
    , code             VARCHAR     NOT NULL
    , name             VARCHAR     NOT NULL
    , description      VARCHAR
    , is_deprecated    BOOLEAN     DEFAULT false
    , created_at       TIMESTAMPTZ DEFAULT current_timestamp

    , CONSTRAINT artifact_action_pk PRIMARY KEY(artifact_action_id)
    , CONSTRAINT artifact_action_u1 UNIQUE(code)
);


CREATE TABLE IF NOT EXISTS artifact_status (
    artifact_status_id UTINYINT    NOT NULL
    , code             VARCHAR     NOT NULL
    , name             VARCHAR     NOT NULL
    , description      VARCHAR
    , is_deprecated    BOOLEAN     DEFAULT false
    , created_at       TIMESTAMPTZ DEFAULT current_timestamp

    , CONSTRAINT artifact_status_pk PRIMARY KEY(artifact_status_id)
    , CONSTRAINT artifact_status_u1 UNIQUE(code)
);


CREATE SEQUENCE IF NOT EXISTS session_artifact_pk_sequence;

CREATE TABLE IF NOT EXISTS session_artifact (
    session_artifact_id  UBIGINT     NOT NULL DEFAULT nextval('session_artifact_pk_sequence')
    , session_id         UUID        NOT NULL

    , artifact_type_id   UTINYINT    NOT NULL
    , artifact_action_id UTINYINT    NOT NULL
    , artifact_status_id UTINYINT    NOT NULL

    -- Artifact references (exactly one must be set)
    , env_id             UINTEGER
    , sbom_file_id       UUID
    , sbom_document_id   UUID

    , message            VARCHAR
    , details_json       JSON
    , created_at         TIMESTAMPTZ DEFAULT current_timestamp

    , CONSTRAINT session_artifact_pk PRIMARY KEY(session_artifact_id)

    , CONSTRAINT session_artifact_fk1 FOREIGN KEY(session_id)
        REFERENCES session(session_id)

    , CONSTRAINT session_artifact_fk2 FOREIGN KEY(artifact_type_id)
        REFERENCES artifact_type(artifact_type_id)

    , CONSTRAINT session_artifact_fk3 FOREIGN KEY(artifact_action_id)
        REFERENCES artifact_action(artifact_action_id)

    , CONSTRAINT session_artifact_fk4 FOREIGN KEY(artifact_status_id)
        REFERENCES artifact_status(artifact_status_id)

    , CONSTRAINT session_artifact_fk5 FOREIGN KEY(env_id)
        REFERENCES env(env_id)

    , CONSTRAINT session_artifact_fk6 FOREIGN KEY(sbom_file_id)
        REFERENCES sbom_file(sbom_file_id)

    , CONSTRAINT session_artifact_fk7 FOREIGN KEY(sbom_document_id)
        REFERENCES sbom_document(sbom_document_id)

    -- exactly one referenced object
    , CONSTRAINT session_artifact_ck1 CHECK (
        (CASE WHEN env_id IS NULL THEN 0 ELSE 1 END) +
        (CASE WHEN sbom_file_id IS NULL THEN 0 ELSE 1 END) +
        (CASE WHEN sbom_document_id IS NULL THEN 0 ELSE 1 END)
        = 1
    )

    -- artifact_type_id must match the populated FK
    , CONSTRAINT session_artifact_ck2 CHECK (
        (artifact_type_id = 1 AND env_id IS NOT NULL AND sbom_file_id IS NULL AND sbom_document_id IS NULL)
        OR
        (artifact_type_id = 2 AND env_id IS NULL AND sbom_file_id IS NOT NULL AND sbom_document_id IS NULL)
        OR
        (artifact_type_id = 3 AND env_id IS NULL AND sbom_file_id IS NULL AND sbom_document_id IS NOT NULL)
    )
);

CREATE INDEX IF NOT EXISTS session_artifact_i1
    ON session_artifact(session_id);

CREATE INDEX IF NOT EXISTS session_artifact_i2
    ON session_artifact(session_id, created_at);



-- ================================================================================================
-- 6) Package, License and Dependencies
-- ================================================================================================

CREATE SEQUENCE IF NOT EXISTS package_type_pk_sequence;

CREATE TABLE IF NOT EXISTS package_type (
    package_type_id UINTEGER   NOT NULL DEFAULT nextval('package_type_pk_sequence')
    , code          VARCHAR    NOT NULL
    , name          VARCHAR    NOT NULL
    , description   VARCHAR
    , is_deprecated BOOLEAN     DEFAULT false
    , created_at    TIMESTAMPTZ DEFAULT current_timestamp

    , CONSTRAINT package_type_pk PRIMARY KEY(package_type_id)
    , CONSTRAINT package_type_u1 UNIQUE(code)
);

CREATE TABLE IF NOT EXISTS package_source (
    package_source_id UTINYINT    NOT NULL
    , code            VARCHAR     NOT NULL
    , name            VARCHAR     NOT NULL
    , description     VARCHAR
    , is_deprecated   BOOLEAN     DEFAULT false
    , created_at      TIMESTAMPTZ DEFAULT current_timestamp

    , CONSTRAINT package_source_pk PRIMARY KEY(package_source_id)
    , CONSTRAINT package_source_u1 UNIQUE(code)
);

COMMENT ON TABLE package_source IS 'Where a package-like object was found within the SBOM.';
COMMENT ON COLUMN package_source.code IS 'Examples: components, metadata_tools';


CREATE TABLE IF NOT EXISTS package (
    package_id            UUID        NOT NULL DEFAULT uuidv7()
    , sbom_document_id    UUID        NOT NULL
    , package_source_id   UTINYINT    NOT NULL
    , package_type_id     UINTEGER

    , bom_ref             VARCHAR
    , name                VARCHAR     NOT NULL
    , version             VARCHAR
    , purl                VARCHAR
    , group_name          VARCHAR
    , description         VARCHAR

    , external_references STRUCT(
        comment  VARCHAR
        , type   VARCHAR
        , url    VARCHAR
        , hashes STRUCT(alg VARCHAR, content VARCHAR)[]
    )[]

    , properties          STRUCT(
        name    VARCHAR
        , value VARCHAR
    )[]

    , component_json      JSON
    , created_at          TIMESTAMPTZ DEFAULT current_timestamp

    , CONSTRAINT package_pk PRIMARY KEY(package_id)

    -- Needed later for composite FK protection in package_dependency
    , CONSTRAINT package_u1 UNIQUE(package_id)
    , CONSTRAINT package_u2 UNIQUE(sbom_document_id, package_id)

    -- bom_ref is source-faithful and nullable
    , CONSTRAINT package_u3 UNIQUE(sbom_document_id, bom_ref)

    , CONSTRAINT package_fk1 FOREIGN KEY(sbom_document_id)
        REFERENCES sbom_document(sbom_document_id)

    , CONSTRAINT package_fk2 FOREIGN KEY(package_type_id)
        REFERENCES package_type(package_type_id)

    , CONSTRAINT package_fk3 FOREIGN KEY(package_source_id)
        REFERENCES package_source(package_source_id)
);

COMMENT ON TABLE package IS 'A package-like object found in an SBOM document, including regular components and metadata tools.';
COMMENT ON COLUMN package.bom_ref IS 'Nullable because metadata.tools.components may not provide bom-ref.';
COMMENT ON COLUMN package.package_source_id IS 'Distinguishes regular components from metadata tools without requiring separate tables.';


CREATE SEQUENCE IF NOT EXISTS license_pk_sequence;

CREATE TABLE IF NOT EXISTS license (
    license_id   UINTEGER   NOT NULL DEFAULT nextval('license_pk_sequence')
    , spdx_id    VARCHAR
    , name       VARCHAR
    , text       VARCHAR
    , url        VARCHAR
    , created_at TIMESTAMPTZ DEFAULT current_timestamp

    , CONSTRAINT license_pk PRIMARY KEY(license_id)
    , CONSTRAINT license_u1 UNIQUE(spdx_id, name)
);


CREATE TABLE IF NOT EXISTS package_license_link (
    package_id         UUID        NOT NULL
    , license_id       UINTEGER    NOT NULL
    , acknowledgement  VARCHAR
    , created_at       TIMESTAMPTZ DEFAULT current_timestamp

    , CONSTRAINT package_license_link_pk PRIMARY KEY(package_id, license_id)

    , CONSTRAINT package_license_link_fk1 FOREIGN KEY(package_id)
        REFERENCES package(package_id)

    , CONSTRAINT package_license_link_fk2 FOREIGN KEY(license_id)
        REFERENCES license(license_id)
);

COMMENT ON TABLE package_license_link IS 'The link between a package and its licenses.';



CREATE TABLE IF NOT EXISTS package_dependency (
    sbom_document_id  UUID        NOT NULL
    , from_package_id UUID        NOT NULL
    , to_package_id   UUID        NOT NULL
    , created_at      TIMESTAMPTZ DEFAULT current_timestamp

    , CONSTRAINT package_dependency_pk PRIMARY KEY(sbom_document_id, from_package_id, to_package_id)

    , CONSTRAINT package_dependency_fk1 FOREIGN KEY(sbom_document_id)
        REFERENCES sbom_document(sbom_document_id)

    , CONSTRAINT package_dependency_fk2 FOREIGN KEY(sbom_document_id, from_package_id)
        REFERENCES package(sbom_document_id, package_id)

    , CONSTRAINT package_dependency_fk3 FOREIGN KEY(sbom_document_id, to_package_id)
        REFERENCES package(sbom_document_id, package_id)

    , CONSTRAINT package_dependency_ck1 CHECK (from_package_id <> to_package_id)
);

COMMENT ON TABLE package_dependency IS 'Dependencies between packages within a single SBOM document.';
COMMENT ON COLUMN package_dependency.from_package_id IS 'The dependent package.';
COMMENT ON COLUMN package_dependency.to_package_id IS 'The package being depended upon.';
