CREATE TABLE advantage (
    id INTEGER NOT NULL,
    code_cp TEXT NOT NULL,
    description TEXT,
    adv_type TEXT,
    status TEXT NOT NULL,
    start_date TEXT,
    end_date TEXT,
    counter INTEGER,
    credit INTEGER,
    solde_a INTEGER,
    solde_a1 INTEGER,
    travelling_class INTEGER,
    code_cb2d bytea,
    code_cb2d_2 bytea,
    mfc2_id INTEGER,
    enabled INTEGER NOT NULL,
    sync_status TEXT,
    sync_date TEXT,
    solde_a_start_date TEXT,
    solde_a_end_date TEXT,
    solde_a1_start_date TEXT,
    solde_a1_end_date TEXT,
    last_authorization_cp TEXT,
    date_debut_interruption TEXT,
    date_fin_interruption TEXT,
    cabotage INTEGER,
    id_attribution INTEGER,
    date_tolerance TEXT
);

CREATE TABLE advantage_type (
    adv_type TEXT NOT NULL,
    adv_order INTEGER,
    is_kz INTEGER,
    is_displayed INTEGER,
    has_code INTEGER,
    description TEXT NOT NULL,
    category TEXT,
    authz_description TEXT,
    need_photo INTEGER
);

CREATE TABLE alert (
    id INTEGER NOT NULL,
    read INTEGER NOT NULL,
    created_at TEXT,
    code_cp TEXT NOT NULL,
    code_cp_2 TEXT,
    code_type_alert TEXT,
    code_cp_3 TEXT
);

CREATE TABLE alert_type (
    code_type_alert TEXT NOT NULL,
    message TEXT,
    is_confirm INTEGER
);

CREATE TABLE banner (
    id INTEGER NOT NULL,
    start_date TEXT NOT NULL,
    end_date TEXT NOT NULL,
    destinataire TEXT NOT NULL,
    priority INTEGER NOT NULL,
    message TEXT NOT NULL,
    enabled INTEGER NOT NULL,
    created_at TEXT,
    modified_at TEXT,
    last_modified_by TEXT NOT NULL
);

CREATE TABLE cgu (
    id INTEGER NOT NULL,
    content TEXT,
    enabled INTEGER NOT NULL,
    created_at TEXT
);

CREATE TABLE faq (
    id INTEGER NOT NULL,
    question TEXT NOT NULL,
    reponse TEXT NOT NULL,
    enabled INTEGER NOT NULL,
    adt_displayed INTEGER NOT NULL
);

CREATE TABLE fc (
    id INTEGER NOT NULL,
    code_cp_creator TEXT NOT NULL,
    code_cp_beneficiary TEXT NOT NULL,
    adv_id INTEGER,
    start_date TEXT,
    end_date TEXT,
    travel_id INTEGER NOT NULL,
    code_cb2d bytea,
    enabled INTEGER NOT NULL,
    creation_date TEXT,
    sync_status TEXT,
    sync_date TEXT
);

CREATE TABLE file_generation_status (
    id INTEGER NOT NULL,
    start_date TEXT NOT NULL,
    end_date TEXT NOT NULL,
    status INTEGER NOT NULL,
    number_rows INTEGER NOT NULL
);

CREATE TABLE flyway_schema_history (
    installed_rank INTEGER NOT NULL,
    version TEXT,
    description TEXT NOT NULL,
    type TEXT NOT NULL,
    script TEXT NOT NULL,
    checksum INTEGER,
    installed_by TEXT NOT NULL,
    installed_on TEXT NOT NULL,
    execution_time INTEGER NOT NULL,
    success INTEGER NOT NULL
);

CREATE TABLE forbidden_password (
    password TEXT NOT NULL
);

CREATE TABLE log (
    id INTEGER NOT NULL,
    cp_connected TEXT,
    cp_creator TEXT,
    cp_beneficiary TEXT,
    level TEXT NOT NULL,
    date_action TEXT NOT NULL,
    message TEXT NOT NULL
);

CREATE TABLE mfc2children4alerttmp (
    code_cp TEXT NOT NULL,
    child_lastname TEXT NOT NULL,
    child_firstname TEXT NOT NULL
);

CREATE TABLE mfc2lientmp (
    code_cp_1 TEXT NOT NULL,
    code_cp_2 TEXT NOT NULL
);

CREATE TABLE mfc2tmp (
    code_cp TEXT NOT NULL,
    gender INTEGER NOT NULL,
    lastname TEXT NOT NULL,
    firstname TEXT NOT NULL,
    birthday date NOT NULL,
    id INTEGER NOT NULL,
    description TEXT,
    adv_type TEXT,
    status TEXT NOT NULL,
    travelling_class INTEGER,
    start_date TEXT,
    end_date TEXT,
    solde_a INTEGER,
    solde_a_start_date TEXT,
    solde_a_end_date TEXT,
    solde_a1 INTEGER,
    solde_a1_start_date TEXT,
    solde_a1_end_date TEXT,
    type_benef INTEGER NOT NULL,
    family_resp INTEGER,
    code_cp_family_manager TEXT,
    code_cp_odt TEXT,
    id_attribution INTEGER,
    date_debut_interruption TEXT,
    date_fin_interruption TEXT,
    cabotage INTEGER,
    date_tolerance TEXT
);

CREATE TABLE modif_synchro (
    code_cp TEXT NOT NULL,
    mfc2_id INTEGER,
    id_attribution INTEGER,
    type_modif TEXT NOT NULL
);

CREATE TABLE otp (
    id INTEGER NOT NULL,
    code_cp TEXT NOT NULL,
    value character(6) NOT NULL,
    date TEXT NOT NULL
);

CREATE TABLE password_history (
    id INTEGER NOT NULL,
    cp TEXT NOT NULL,
    value TEXT NOT NULL,
    created_at TEXT
);

CREATE TABLE photo (
    id INTEGER NOT NULL,
    cp_benef TEXT NOT NULL,
    picture_id TEXT,
    created_at TEXT NOT NULL,
    picture_type TEXT,
    sync_status TEXT,
    sync_date TEXT,
    cp_user TEXT,
    is_active INTEGER,
    marked_for_deletion TEXT
);

CREATE TABLE question (
    id INTEGER NOT NULL,
    question TEXT NOT NULL,
    enabled INTEGER NOT NULL
);

CREATE TABLE setting (
    setting_key TEXT NOT NULL,
    setting_value_string TEXT,
    setting_value_num INTEGER,
    setting_value_date TEXT
);

CREATE TABLE token (
    id INTEGER NOT NULL,
    code_cp TEXT,
    token TEXT,
    created_at TEXT
);

CREATE TABLE trusted_devices (
    id INTEGER NOT NULL,
    code_cp TEXT NOT NULL,
    fingerprint TEXT NOT NULL,
    os TEXT NOT NULL,
    browser TEXT NOT NULL,
    device TEXT NOT NULL,
    created_at TEXT
);

CREATE TABLE user_admin (
    id INTEGER NOT NULL,
    code_cp TEXT NOT NULL,
    start_date TEXT NOT NULL,
    end_date TEXT NOT NULL,
    entity INTEGER,
    enabled INTEGER NOT NULL,
    created_at TEXT,
    modified_at TEXT,
    last_modified_by TEXT NOT NULL
);

CREATE TABLE user_blocked (
    id INTEGER NOT NULL,
    code_cp TEXT NOT NULL,
    blocking_date TEXT NOT NULL,
    result TEXT NOT NULL,
    mail_sent TEXT NOT NULL,
    admin_lastname TEXT NOT NULL,
    admin_firstname TEXT NOT NULL
);

CREATE TABLE user_cgu (
    id INTEGER NOT NULL,
    code_cp TEXT,
    cgu_id INTEGER NOT NULL,
    created_at TEXT
);

CREATE TABLE user_children_alert (
    id INTEGER NOT NULL,
    code_cp TEXT NOT NULL,
    child_firstname TEXT NOT NULL,
    child_lastname TEXT NOT NULL,
    created_at TEXT NOT NULL
);

CREATE TABLE user_delegation (
    id INTEGER NOT NULL,
    code_cp_delegatee TEXT NOT NULL,
    code_cp_delegator TEXT NOT NULL,
    code_cp_beneficiary TEXT NOT NULL,
    start_date TEXT NOT NULL,
    end_date TEXT,
    is_delete INTEGER NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT,
    enabled INTEGER NOT NULL,
    sync_status TEXT,
    sync_date TEXT,
    code_cp_admin TEXT
);

CREATE TABLE user_entity (
    id INTEGER NOT NULL,
    name TEXT NOT NULL
);

CREATE TABLE user_link (
    id INTEGER NOT NULL,
    code_cp_delegator TEXT NOT NULL,
    code_cp_delegatee TEXT NOT NULL
);

CREATE TABLE user_question (
    code_cp TEXT NOT NULL,
    question1_id INTEGER NOT NULL,
    answer1 TEXT NOT NULL,
    question2_id INTEGER NOT NULL,
    answer2 TEXT NOT NULL
);

CREATE TABLE user_role (
    code_cp TEXT NOT NULL,
    role TEXT NOT NULL
);

CREATE TABLE user_sncf (
    code_cp TEXT NOT NULL,
    password TEXT NOT NULL,
    email TEXT NOT NULL,
    firstname TEXT NOT NULL,
    lastname TEXT NOT NULL,
    locked INTEGER NOT NULL,
    enabled INTEGER NOT NULL,
    birthday date NOT NULL,
    login_attempts INTEGER,
    questions_attempts INTEGER,
    lastlogin TEXT,
    last_questions_update TEXT,
    last_password_update TEXT,
    user_type INTEGER,
    last_locking TEXT,
    gender INTEGER NOT NULL,
    last_photo_update TEXT,
    family_resp INTEGER,
    code_cp_family_manager TEXT NOT NULL,
    code_cp_odt TEXT NOT NULL,
    otp_attempts INTEGER NOT NULL,
    birthday_attempts INTEGER NOT NULL,
    last_otp_attempt TEXT,
    last_otp_validation TEXT,
    email_creation TEXT,
    email_update TEXT,
    last_mfc2_sync TEXT
);

CREATE TABLE user_type (
    id INTEGER NOT NULL,
    type TEXT NOT NULL,
    description TEXT NOT NULL
);

ALTER TABLE ONLY advantage
    ADD CONSTRAINT advantage_pkey PRIMARY KEY (id);

ALTER TABLE ONLY advantage_type
    ADD CONSTRAINT advantage_type_pkey PRIMARY KEY (adv_type);

ALTER TABLE ONLY alert
    ADD CONSTRAINT alert_pkey PRIMARY KEY (id);

ALTER TABLE ONLY alert_type
    ADD CONSTRAINT alert_type_pkey PRIMARY KEY (code_type_alert);

ALTER TABLE ONLY banner
    ADD CONSTRAINT banner_pkey PRIMARY KEY (id);

ALTER TABLE ONLY cgu
    ADD CONSTRAINT cgu_pkey PRIMARY KEY (id);

ALTER TABLE ONLY faq
    ADD CONSTRAINT faq_pkey PRIMARY KEY (id);

ALTER TABLE ONLY fc
    ADD CONSTRAINT fc_pkey PRIMARY KEY (id);

ALTER TABLE ONLY file_generation_status
    ADD CONSTRAINT file_generation_status_pkey PRIMARY KEY (id);

ALTER TABLE ONLY flyway_schema_history
    ADD CONSTRAINT flyway_schema_history_pk PRIMARY KEY (installed_rank);

ALTER TABLE ONLY forbidden_password
    ADD CONSTRAINT forbidden_password_pkey PRIMARY KEY (password);

ALTER TABLE ONLY log
    ADD CONSTRAINT log_pkey PRIMARY KEY (id);

ALTER TABLE ONLY otp
    ADD CONSTRAINT otp_pkey PRIMARY KEY (id);

ALTER TABLE ONLY password_history
    ADD CONSTRAINT password_history_pkey PRIMARY KEY (id);

ALTER TABLE ONLY photo
    ADD CONSTRAINT photo_pkey PRIMARY KEY (id);

ALTER TABLE ONLY question
    ADD CONSTRAINT question_pkey PRIMARY KEY (id);

ALTER TABLE ONLY setting
    ADD CONSTRAINT setting_pkey PRIMARY KEY (setting_key);

ALTER TABLE ONLY token
    ADD CONSTRAINT token_pkey PRIMARY KEY (id);

ALTER TABLE ONLY trusted_devices
    ADD CONSTRAINT trusted_devices_pkey PRIMARY KEY (id);

ALTER TABLE ONLY user_admin
    ADD CONSTRAINT user_admin_code_cp_key UNIQUE (code_cp);

ALTER TABLE ONLY user_admin
    ADD CONSTRAINT user_admin_pkey PRIMARY KEY (id);

ALTER TABLE ONLY user_blocked
    ADD CONSTRAINT user_blocked_pkey PRIMARY KEY (id);

ALTER TABLE ONLY user_cgu
    ADD CONSTRAINT user_cgu_code_cp_cgu_id_key UNIQUE (code_cp, cgu_id);

ALTER TABLE ONLY user_cgu
    ADD CONSTRAINT user_cgu_pkey PRIMARY KEY (id);

ALTER TABLE ONLY user_children_alert
    ADD CONSTRAINT user_children_alert_pkey PRIMARY KEY (id);

ALTER TABLE ONLY user_delegation
    ADD CONSTRAINT user_delegation_pkey PRIMARY KEY (id);

ALTER TABLE ONLY user_entity
    ADD CONSTRAINT user_entity_name_key UNIQUE (name);

ALTER TABLE ONLY user_entity
    ADD CONSTRAINT user_entity_pkey PRIMARY KEY (id);

ALTER TABLE ONLY user_link
    ADD CONSTRAINT user_link_pkey PRIMARY KEY (id);

ALTER TABLE ONLY user_question
    ADD CONSTRAINT user_question_pkey PRIMARY KEY (code_cp);

ALTER TABLE ONLY user_role
    ADD CONSTRAINT user_role_unique_code_role UNIQUE (code_cp, role);

ALTER TABLE ONLY user_sncf
    ADD CONSTRAINT user_sncf_pkey PRIMARY KEY (code_cp);

ALTER TABLE ONLY user_type
    ADD CONSTRAINT user_type_pkey PRIMARY KEY (id);

ALTER TABLE ONLY advantage
    ADD CONSTRAINT advantage_adv_type_fkey FOREIGN KEY (adv_type) REFERENCES advantage_type(adv_type);

ALTER TABLE ONLY alert
    ADD CONSTRAINT alert_code_cp_2_fkey FOREIGN KEY (code_cp_2) REFERENCES user_sncf(code_cp) ON DELETE CASCADE;

ALTER TABLE ONLY alert
    ADD CONSTRAINT alert_code_cp_fkey FOREIGN KEY (code_cp) REFERENCES user_sncf(code_cp) ON DELETE CASCADE;

ALTER TABLE ONLY alert
    ADD CONSTRAINT alert_code_type_alert_fkey FOREIGN KEY (code_type_alert) REFERENCES alert_type(code_type_alert);

ALTER TABLE ONLY fc
    ADD CONSTRAINT fc_adv_id_fkey FOREIGN KEY (adv_id) REFERENCES advantage(id) ON DELETE CASCADE;

ALTER TABLE ONLY user_sncf
    ADD CONSTRAINT fk_user_type FOREIGN KEY (user_type) REFERENCES user_type(id);

ALTER TABLE ONLY token
    ADD CONSTRAINT token_code_cp_user_sncf_fkey FOREIGN KEY (code_cp) REFERENCES user_sncf(code_cp) ON DELETE CASCADE;

ALTER TABLE ONLY user_admin
    ADD CONSTRAINT user_admin_code_cp_fkey FOREIGN KEY (code_cp) REFERENCES user_sncf(code_cp);

ALTER TABLE ONLY user_admin
    ADD CONSTRAINT user_admin_entity_fkey FOREIGN KEY (entity) REFERENCES user_entity(id);

ALTER TABLE ONLY user_cgu
    ADD CONSTRAINT user_cgu_cgu_id_fkey FOREIGN KEY (cgu_id) REFERENCES cgu(id);

ALTER TABLE ONLY user_cgu
    ADD CONSTRAINT user_cgu_code_cp_fkey FOREIGN KEY (code_cp) REFERENCES user_sncf(code_cp) ON DELETE CASCADE;

ALTER TABLE ONLY user_children_alert
    ADD CONSTRAINT user_children_alert_code_cp_fkey FOREIGN KEY (code_cp) REFERENCES user_sncf(code_cp) ON DELETE CASCADE;

ALTER TABLE ONLY user_delegation
    ADD CONSTRAINT user_delegation_code_cp_beneficiary_fkey FOREIGN KEY (code_cp_beneficiary) REFERENCES user_sncf(code_cp) ON DELETE CASCADE;

ALTER TABLE ONLY user_delegation
    ADD CONSTRAINT user_delegation_code_cp_delegatee_fkey FOREIGN KEY (code_cp_delegatee) REFERENCES user_sncf(code_cp) ON DELETE CASCADE;

ALTER TABLE ONLY user_delegation
    ADD CONSTRAINT user_delegation_code_cp_delegator_fkey FOREIGN KEY (code_cp_delegator) REFERENCES user_sncf(code_cp) ON DELETE CASCADE;

ALTER TABLE ONLY user_question
    ADD CONSTRAINT user_question_code_cp_fkey FOREIGN KEY (code_cp) REFERENCES user_sncf(code_cp) ON DELETE CASCADE;

ALTER TABLE ONLY user_question
    ADD CONSTRAINT user_question_question1_id_fkey FOREIGN KEY (question1_id) REFERENCES question(id);

ALTER TABLE ONLY user_question
    ADD CONSTRAINT user_question_question2_id_fkey FOREIGN KEY (question2_id) REFERENCES question(id);

ALTER TABLE ONLY user_role
    ADD CONSTRAINT user_role_code_cp_user_sncf_fkey FOREIGN KEY (code_cp) REFERENCES user_sncf(code_cp) ON DELETE CASCADE;

