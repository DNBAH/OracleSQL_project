CREATE TABLE Players (
    player_id NUMBER(10) CONSTRAINT pk_players PRIMARY KEY,
    username VARCHAR2(50) NOT NULL CONSTRAINT uk_players_username UNIQUE,
    display_name VARCHAR2(100) NOT NULL,
    created_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL
);

CREATE TABLE Themes (
    theme_id NUMBER(10) CONSTRAINT pk_themes PRIMARY KEY,
    name VARCHAR2(50) NOT NULL CONSTRAINT uk_themes_name UNIQUE
);

CREATE TABLE WordRoots (
    root_id NUMBER(10) CONSTRAINT pk_wordroots PRIMARY KEY,
    root_text VARCHAR2(50) NOT NULL CONSTRAINT uk_wordroots_text UNIQUE
);

CREATE TABLE Words (
    word_id NUMBER(10) CONSTRAINT pk_words PRIMARY KEY,
    theme_id NUMBER(10) NOT NULL,
    root_id NUMBER(10),
    word VARCHAR2(100) NOT NULL CONSTRAINT uk_words_word UNIQUE,
    is_active NUMBER(1) DEFAULT 1 NOT NULL,
    CONSTRAINT fk_words_theme FOREIGN KEY (theme_id) REFERENCES Themes(theme_id),
    CONSTRAINT fk_words_root FOREIGN KEY (root_id) REFERENCES WordRoots(root_id),
    CONSTRAINT chk_words_active CHECK (is_active IN (0,1))
);
CREATE INDEX ix_words_theme_active ON Words(theme_id, is_active);

CREATE TABLE Sessions (
    session_id NUMBER(10) CONSTRAINT pk_sessions PRIMARY KEY,
    player1_id NUMBER(10) NOT NULL,
    player2_id NUMBER(10) NOT NULL,
    theme_id NUMBER(10) NOT NULL,
    round_limit NUMBER(3) NOT NULL,
    round_time_sec NUMBER(5) NOT NULL,
    created_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    finished_at TIMESTAMP,
    final_score NUMBER(10),
    CONSTRAINT fk_sessions_p1 FOREIGN KEY (player1_id) REFERENCES Players(player_id),
    CONSTRAINT fk_sessions_p2 FOREIGN KEY (player2_id) REFERENCES Players(player_id),
    CONSTRAINT fk_sessions_theme FOREIGN KEY (theme_id) REFERENCES Themes(theme_id),
    CONSTRAINT chk_sessions_players CHECK (player1_id <> player2_id),
    CONSTRAINT chk_sessions_limit CHECK (round_limit BETWEEN 1 AND 100),
    CONSTRAINT chk_sessions_time CHECK (round_time_sec BETWEEN 1 AND 86400),
    CONSTRAINT chk_sessions_finish CHECK (
        (finished_at IS NULL AND final_score IS NULL)
        OR (finished_at IS NOT NULL AND final_score >= 0 AND finished_at >= created_at))
);

CREATE TABLE Rounds (
    round_id NUMBER(10) CONSTRAINT pk_rounds PRIMARY KEY,
    session_id NUMBER(10) NOT NULL,
    round_number NUMBER(3) NOT NULL,
    explainer_id NUMBER(10) NOT NULL,
    guesser_id NUMBER(10) NOT NULL,
    started_at TIMESTAMP NOT NULL,
    ended_at TIMESTAMP,
    CONSTRAINT uk_rounds_session_num UNIQUE (session_id,round_number),
    CONSTRAINT fk_rounds_session FOREIGN KEY (session_id) REFERENCES Sessions(session_id),
    CONSTRAINT fk_rounds_explainer FOREIGN KEY (explainer_id) REFERENCES Players(player_id),
    CONSTRAINT fk_rounds_guesser FOREIGN KEY (guesser_id) REFERENCES Players(player_id),
    CONSTRAINT chk_rounds_num CHECK (round_number >= 1),
    CONSTRAINT chk_rounds_players CHECK (explainer_id <> guesser_id),
    CONSTRAINT chk_rounds_end CHECK (ended_at IS NULL OR ended_at >= started_at)
);

CREATE UNIQUE INDEX ux_rounds_one_open
    ON Rounds (CASE WHEN ended_at IS NULL THEN session_id END);


CREATE TABLE ActiveWords (
    round_id NUMBER(10) NOT NULL,
    issue_no NUMBER(5) NOT NULL,
    word_id NUMBER(10) NOT NULL,
    assigned_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    skipped_at TIMESTAMP,
    CONSTRAINT pk_activewords PRIMARY KEY (round_id,issue_no),
    CONSTRAINT fk_aw_round FOREIGN KEY (round_id) REFERENCES Rounds(round_id),
    CONSTRAINT fk_aw_word FOREIGN KEY (word_id) REFERENCES Words(word_id),
    CONSTRAINT chk_aw_issue CHECK (issue_no >= 1),
    CONSTRAINT chk_aw_skip CHECK (skipped_at IS NULL OR skipped_at >= assigned_at)
);
CREATE INDEX ix_aw_word ON ActiveWords(word_id);


CREATE TABLE Hints (
    hint_id NUMBER(10) CONSTRAINT pk_hints PRIMARY KEY,
    round_id NUMBER(10) NOT NULL,
    issue_no NUMBER(5) NOT NULL,
    hint_text VARCHAR2(200) NOT NULL,
    created_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT fk_hints_issue FOREIGN KEY (round_id,issue_no)
        REFERENCES ActiveWords(round_id,issue_no)
);
CREATE INDEX ix_hints_issue ON Hints(round_id,issue_no);

CREATE TABLE Guesses (
    guess_id NUMBER(10) CONSTRAINT pk_guesses PRIMARY KEY,
    round_id NUMBER(10) NOT NULL,
    issue_no NUMBER(5) NOT NULL,
    guess_text VARCHAR2(100) NOT NULL,
    guessed_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT fk_guesses_issue FOREIGN KEY (round_id,issue_no)
        REFERENCES ActiveWords(round_id,issue_no)
);
CREATE INDEX ix_guesses_issue ON Guesses(round_id,issue_no);

CREATE TABLE Notifications (
    notif_id NUMBER(10) CONSTRAINT pk_notifications PRIMARY KEY,
    session_id NUMBER(10) NOT NULL,
    player_id NUMBER(10) NOT NULL,
    message VARCHAR2(200) NOT NULL,
    created_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    read_at TIMESTAMP,
    CONSTRAINT fk_notif_session FOREIGN KEY (session_id) REFERENCES Sessions(session_id),
    CONSTRAINT fk_notif_player FOREIGN KEY (player_id) REFERENCES Players(player_id),
    CONSTRAINT chk_notif_read CHECK (read_at IS NULL OR read_at >= created_at)
);
CREATE INDEX ix_notif_recipient ON Notifications(session_id,player_id,read_at);


CREATE TABLE Records (
    record_id NUMBER(10) CONSTRAINT pk_records PRIMARY KEY,
    round_id NUMBER(10) NOT NULL CONSTRAINT uk_records_round UNIQUE,
    recorded_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT fk_records_round FOREIGN KEY (round_id) REFERENCES Rounds(round_id)
);

CREATE SEQUENCE seq_players START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_themes START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_roots START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_words START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_sessions START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_rounds START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_hints START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_guesses START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_notif START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_records START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;





------------------------------------------------------------------
INSERT INTO Themes(theme_id,name) VALUES(seq_themes.NEXTVAL,'Животные');
INSERT INTO Themes(theme_id,name) VALUES(seq_themes.NEXTVAL,'Еда');
INSERT INTO Themes(theme_id,name) VALUES(seq_themes.NEXTVAL,'IT');
INSERT INTO Themes(theme_id,name) VALUES(seq_themes.NEXTVAL,'Нефтегаз');
INSERT INTO Themes(theme_id,name) VALUES(seq_themes.NEXTVAL,'Сложные понятия');

INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'собак');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'кошк');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'коров');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'лошад');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'свин');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'овц');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'коз');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'кур');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'утк');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'гус');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'волк');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'лис');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'медвед');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'заяц');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'ёж');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'белк');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'лось');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'олен');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'тигр');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'лев');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'слон');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'жираф');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'обезьян');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'крокодил');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'змей');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'яблок');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'банан');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'апельсин');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'хлеб');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'молок');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'сыр');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'колбас');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'мяс');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'рыб');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'картофель');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'морков');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'лук');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'чеснок');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'сахар');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'соль');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'масл');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'яйц');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'творог');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'кефир');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'пирог');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'сервер');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'баз');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'операцион');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'процессор');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'памят');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'сет');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'роутер');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'коммутатор');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'брандмауэр');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'шифр');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'алгоритм');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'программ');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'прилож');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'драйвер');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'интерфейс');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'бит');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'байт');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'килобайт');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'мегабайт');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'гигабайт');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'кэш');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'порт');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'нефт');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'газ');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'скважин');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'буров');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'платформ');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'трубопровод');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'переработк');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'бензин');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'дизель');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'мазут');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'битум');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'керосин');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'пропан');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'метан');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'этан');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'бутан');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'месторожд');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'геолог');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'разведк');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'добыч');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'транспортировк');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'нефтепровод');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'газопровод');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'бурен');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'насос');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'компрессор');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'резервуар');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'цистерн');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'танкер');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'барж');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'любов');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'счаст');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'свобод');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'справедлив');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'добр');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'зл');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'истин');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'крас');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'мудр');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'вер');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'надежд');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'совест');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'чест');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'достоинств');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'гармон');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'баланс');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'энерг');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'времен');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'пространств');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'бесконечн');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'сознани');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'подсознани');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'интуиц');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'вдохновен');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'творчеств');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'смысл');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'цель');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'мечт');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'идеал');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'принцип');
INSERT INTO WordRoots(root_id,root_text) VALUES(seq_roots.NEXTVAL,'ценност');

-- Тема и корень подставляются из справочников по их уникальным именам.
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Животные'),(SELECT root_id FROM WordRoots WHERE root_text='собак'),'собака',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Животные'),(SELECT root_id FROM WordRoots WHERE root_text='кошк'),'кошка',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Животные'),(SELECT root_id FROM WordRoots WHERE root_text='коров'),'корова',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Животные'),(SELECT root_id FROM WordRoots WHERE root_text='лошад'),'лошадь',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Животные'),(SELECT root_id FROM WordRoots WHERE root_text='свин'),'свинья',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Животные'),(SELECT root_id FROM WordRoots WHERE root_text='овц'),'овца',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Животные'),(SELECT root_id FROM WordRoots WHERE root_text='коз'),'коза',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Животные'),(SELECT root_id FROM WordRoots WHERE root_text='кур'),'курица',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Животные'),(SELECT root_id FROM WordRoots WHERE root_text='утк'),'утка',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Животные'),(SELECT root_id FROM WordRoots WHERE root_text='гус'),'гусь',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Животные'),(SELECT root_id FROM WordRoots WHERE root_text='волк'),'волк',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Животные'),(SELECT root_id FROM WordRoots WHERE root_text='лис'),'лиса',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Животные'),(SELECT root_id FROM WordRoots WHERE root_text='медвед'),'медведь',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Животные'),(SELECT root_id FROM WordRoots WHERE root_text='заяц'),'заяц',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Животные'),(SELECT root_id FROM WordRoots WHERE root_text='ёж'),'ёж',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Животные'),(SELECT root_id FROM WordRoots WHERE root_text='белк'),'белка',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Животные'),(SELECT root_id FROM WordRoots WHERE root_text='лось'),'лось',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Животные'),(SELECT root_id FROM WordRoots WHERE root_text='олен'),'олень',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Животные'),(SELECT root_id FROM WordRoots WHERE root_text='тигр'),'тигр',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Животные'),(SELECT root_id FROM WordRoots WHERE root_text='лев'),'лев',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Животные'),(SELECT root_id FROM WordRoots WHERE root_text='слон'),'слон',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Животные'),(SELECT root_id FROM WordRoots WHERE root_text='жираф'),'жираф',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Животные'),(SELECT root_id FROM WordRoots WHERE root_text='обезьян'),'обезьяна',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Животные'),(SELECT root_id FROM WordRoots WHERE root_text='крокодил'),'крокодил',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Животные'),(SELECT root_id FROM WordRoots WHERE root_text='змей'),'змея',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Еда'),(SELECT root_id FROM WordRoots WHERE root_text='яблок'),'яблоко',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Еда'),(SELECT root_id FROM WordRoots WHERE root_text='банан'),'банан',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Еда'),(SELECT root_id FROM WordRoots WHERE root_text='апельсин'),'апельсин',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Еда'),(SELECT root_id FROM WordRoots WHERE root_text='хлеб'),'хлеб',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Еда'),(SELECT root_id FROM WordRoots WHERE root_text='молок'),'молоко',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Еда'),(SELECT root_id FROM WordRoots WHERE root_text='сыр'),'сыр',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Еда'),(SELECT root_id FROM WordRoots WHERE root_text='колбас'),'колбаса',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Еда'),(SELECT root_id FROM WordRoots WHERE root_text='мяс'),'мясо',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Еда'),(SELECT root_id FROM WordRoots WHERE root_text='рыб'),'рыба',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Еда'),(SELECT root_id FROM WordRoots WHERE root_text='картофель'),'картофель',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Еда'),(SELECT root_id FROM WordRoots WHERE root_text='морков'),'морковь',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Еда'),(SELECT root_id FROM WordRoots WHERE root_text='лук'),'лук',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Еда'),(SELECT root_id FROM WordRoots WHERE root_text='чеснок'),'чеснок',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Еда'),(SELECT root_id FROM WordRoots WHERE root_text='сахар'),'сахар',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Еда'),(SELECT root_id FROM WordRoots WHERE root_text='соль'),'соль',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Еда'),(SELECT root_id FROM WordRoots WHERE root_text='масл'),'масло',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Еда'),(SELECT root_id FROM WordRoots WHERE root_text='яйц'),'яйцо',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Еда'),(SELECT root_id FROM WordRoots WHERE root_text='творог'),'творог',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Еда'),(SELECT root_id FROM WordRoots WHERE root_text='кефир'),'кефир',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Еда'),(SELECT root_id FROM WordRoots WHERE root_text='пирог'),'пирог',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='IT'),(SELECT root_id FROM WordRoots WHERE root_text='сервер'),'сервер',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='IT'),(SELECT root_id FROM WordRoots WHERE root_text='баз'),'база данных',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='IT'),(SELECT root_id FROM WordRoots WHERE root_text='операцион'),'операционная система',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='IT'),(SELECT root_id FROM WordRoots WHERE root_text='процессор'),'процессор',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='IT'),(SELECT root_id FROM WordRoots WHERE root_text='памят'),'память',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='IT'),(SELECT root_id FROM WordRoots WHERE root_text='сет'),'сеть',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='IT'),(SELECT root_id FROM WordRoots WHERE root_text='роутер'),'роутер',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='IT'),(SELECT root_id FROM WordRoots WHERE root_text='коммутатор'),'коммутатор',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='IT'),(SELECT root_id FROM WordRoots WHERE root_text='брандмауэр'),'брандмауэр',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='IT'),(SELECT root_id FROM WordRoots WHERE root_text='шифр'),'шифрование',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='IT'),(SELECT root_id FROM WordRoots WHERE root_text='алгоритм'),'алгоритм',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='IT'),(SELECT root_id FROM WordRoots WHERE root_text='программ'),'программа',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='IT'),(SELECT root_id FROM WordRoots WHERE root_text='прилож'),'приложение',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='IT'),(SELECT root_id FROM WordRoots WHERE root_text='драйвер'),'драйвер',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='IT'),(SELECT root_id FROM WordRoots WHERE root_text='интерфейс'),'интерфейс',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='IT'),(SELECT root_id FROM WordRoots WHERE root_text='бит'),'бит',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='IT'),(SELECT root_id FROM WordRoots WHERE root_text='байт'),'байт',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='IT'),(SELECT root_id FROM WordRoots WHERE root_text='килобайт'),'килобайт',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='IT'),(SELECT root_id FROM WordRoots WHERE root_text='мегабайт'),'мегабайт',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='IT'),(SELECT root_id FROM WordRoots WHERE root_text='гигабайт'),'гигабайт',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='IT'),(SELECT root_id FROM WordRoots WHERE root_text='кэш'),'кэш',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='IT'),(SELECT root_id FROM WordRoots WHERE root_text='порт'),'порт',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='IT'),NULL,'DNS',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='IT'),NULL,'HTTP',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='IT'),NULL,'HTML',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='IT'),NULL,'CSS',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='IT'),NULL,'JavaScript',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='IT'),NULL,'Python',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='IT'),NULL,'Java',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='IT'),NULL,'SQL',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='IT'),NULL,'Linux',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='IT'),NULL,'Windows',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='IT'),NULL,'Oracle',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Нефтегаз'),(SELECT root_id FROM WordRoots WHERE root_text='нефт'),'нефть',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Нефтегаз'),(SELECT root_id FROM WordRoots WHERE root_text='газ'),'газ',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Нефтегаз'),(SELECT root_id FROM WordRoots WHERE root_text='скважин'),'скважина',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Нефтегаз'),(SELECT root_id FROM WordRoots WHERE root_text='буров'),'буровая',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Нефтегаз'),(SELECT root_id FROM WordRoots WHERE root_text='платформ'),'платформа',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Нефтегаз'),(SELECT root_id FROM WordRoots WHERE root_text='трубопровод'),'трубопровод',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Нефтегаз'),(SELECT root_id FROM WordRoots WHERE root_text='переработк'),'переработка',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Нефтегаз'),(SELECT root_id FROM WordRoots WHERE root_text='бензин'),'бензин',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Нефтегаз'),(SELECT root_id FROM WordRoots WHERE root_text='дизель'),'дизель',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Нефтегаз'),(SELECT root_id FROM WordRoots WHERE root_text='мазут'),'мазут',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Нефтегаз'),(SELECT root_id FROM WordRoots WHERE root_text='битум'),'битум',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Нефтегаз'),(SELECT root_id FROM WordRoots WHERE root_text='керосин'),'керосин',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Нефтегаз'),(SELECT root_id FROM WordRoots WHERE root_text='пропан'),'пропан',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Нефтегаз'),(SELECT root_id FROM WordRoots WHERE root_text='метан'),'метан',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Нефтегаз'),(SELECT root_id FROM WordRoots WHERE root_text='этан'),'этан',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Нефтегаз'),(SELECT root_id FROM WordRoots WHERE root_text='бутан'),'бутан',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Нефтегаз'),(SELECT root_id FROM WordRoots WHERE root_text='месторожд'),'месторождение',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Нефтегаз'),(SELECT root_id FROM WordRoots WHERE root_text='геолог'),'геология',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Нефтегаз'),(SELECT root_id FROM WordRoots WHERE root_text='разведк'),'разведка',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Нефтегаз'),(SELECT root_id FROM WordRoots WHERE root_text='добыч'),'добыча',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Нефтегаз'),(SELECT root_id FROM WordRoots WHERE root_text='транспортировк'),'транспортировка',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Нефтегаз'),(SELECT root_id FROM WordRoots WHERE root_text='нефтепровод'),'нефтепровод',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Нефтегаз'),(SELECT root_id FROM WordRoots WHERE root_text='газопровод'),'газопровод',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Нефтегаз'),(SELECT root_id FROM WordRoots WHERE root_text='бурен'),'бурение',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Нефтегаз'),(SELECT root_id FROM WordRoots WHERE root_text='насос'),'насос',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Нефтегаз'),(SELECT root_id FROM WordRoots WHERE root_text='компрессор'),'компрессор',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Нефтегаз'),(SELECT root_id FROM WordRoots WHERE root_text='резервуар'),'резервуар',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Нефтегаз'),(SELECT root_id FROM WordRoots WHERE root_text='цистерн'),'цистерна',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Нефтегаз'),(SELECT root_id FROM WordRoots WHERE root_text='танкер'),'танкер',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Нефтегаз'),(SELECT root_id FROM WordRoots WHERE root_text='барж'),'баржа',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Сложные понятия'),(SELECT root_id FROM WordRoots WHERE root_text='любов'),'любовь',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Сложные понятия'),(SELECT root_id FROM WordRoots WHERE root_text='счаст'),'счастье',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Сложные понятия'),(SELECT root_id FROM WordRoots WHERE root_text='свобод'),'свобода',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Сложные понятия'),(SELECT root_id FROM WordRoots WHERE root_text='справедлив'),'справедливость',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Сложные понятия'),(SELECT root_id FROM WordRoots WHERE root_text='добр'),'добро',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Сложные понятия'),(SELECT root_id FROM WordRoots WHERE root_text='зл'),'зло',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Сложные понятия'),(SELECT root_id FROM WordRoots WHERE root_text='истин'),'истина',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Сложные понятия'),(SELECT root_id FROM WordRoots WHERE root_text='крас'),'красота',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Сложные понятия'),(SELECT root_id FROM WordRoots WHERE root_text='мудр'),'мудрость',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Сложные понятия'),(SELECT root_id FROM WordRoots WHERE root_text='вер'),'вера',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Сложные понятия'),(SELECT root_id FROM WordRoots WHERE root_text='надежд'),'надежда',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Сложные понятия'),(SELECT root_id FROM WordRoots WHERE root_text='совест'),'совесть',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Сложные понятия'),(SELECT root_id FROM WordRoots WHERE root_text='чест'),'честь',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Сложные понятия'),(SELECT root_id FROM WordRoots WHERE root_text='достоинств'),'достоинство',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Сложные понятия'),(SELECT root_id FROM WordRoots WHERE root_text='гармон'),'гармония',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Сложные понятия'),(SELECT root_id FROM WordRoots WHERE root_text='баланс'),'баланс',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Сложные понятия'),(SELECT root_id FROM WordRoots WHERE root_text='энерг'),'энергия',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Сложные понятия'),(SELECT root_id FROM WordRoots WHERE root_text='времен'),'время',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Сложные понятия'),(SELECT root_id FROM WordRoots WHERE root_text='пространств'),'пространство',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Сложные понятия'),(SELECT root_id FROM WordRoots WHERE root_text='бесконечн'),'бесконечность',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Сложные понятия'),(SELECT root_id FROM WordRoots WHERE root_text='сознани'),'сознание',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Сложные понятия'),(SELECT root_id FROM WordRoots WHERE root_text='подсознани'),'подсознание',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Сложные понятия'),(SELECT root_id FROM WordRoots WHERE root_text='интуиц'),'интуиция',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Сложные понятия'),(SELECT root_id FROM WordRoots WHERE root_text='вдохновен'),'вдохновение',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Сложные понятия'),(SELECT root_id FROM WordRoots WHERE root_text='творчеств'),'творчество',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Сложные понятия'),(SELECT root_id FROM WordRoots WHERE root_text='смысл'),'смысл',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Сложные понятия'),(SELECT root_id FROM WordRoots WHERE root_text='цель'),'цель',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Сложные понятия'),(SELECT root_id FROM WordRoots WHERE root_text='мечт'),'мечта',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Сложные понятия'),(SELECT root_id FROM WordRoots WHERE root_text='идеал'),'идеал',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Сложные понятия'),(SELECT root_id FROM WordRoots WHERE root_text='принцип'),'принцип',1);
INSERT INTO Words(word_id,theme_id,root_id,word,is_active) VALUES(seq_words.NEXTVAL,(SELECT theme_id FROM Themes WHERE name='Сложные понятия'),(SELECT root_id FROM WordRoots WHERE root_text='ценност'),'ценность',1);

COMMIT;







------------------------------------------------------------------



CREATE OR REPLACE FUNCTION IS_SAME_ROOT(
    p_word_id IN NUMBER, p_hint IN VARCHAR2
) RETURN BOOLEAN IS
    v_root WordRoots.root_text%TYPE;
    v_word Words.word%TYPE;
    v_hint VARCHAR2(200);
    v_key VARCHAR2(100);
BEGIN
    SELECT w.word, r.root_text INTO v_word, v_root
      FROM Words w LEFT JOIN WordRoots r ON r.root_id = w.root_id
     WHERE w.word_id = p_word_id;
    v_hint := REPLACE(LOWER(TRIM(p_hint)), 'ё', 'е');
    v_key := REPLACE(LOWER(NVL(v_root, v_word)), 'ё', 'е');
    RETURN v_hint IS NOT NULL AND INSTR(v_hint, v_key) > 0;
END IS_SAME_ROOT;
/

CREATE OR REPLACE TRIGGER trg_hints_check_root
BEFORE INSERT ON Hints
FOR EACH ROW
DECLARE
    v_word_id Words.word_id%TYPE;
BEGIN
    IF TRIM(:NEW.hint_text) IS NULL THEN
        RAISE_APPLICATION_ERROR(-20009, 'Подсказка не должна быть пустой.');
    END IF;
    SELECT word_id INTO v_word_id
      FROM ActiveWords
     WHERE round_id = :NEW.round_id AND issue_no = :NEW.issue_no;
    IF IS_SAME_ROOT(v_word_id, :NEW.hint_text) THEN
        RAISE_APPLICATION_ERROR(-20001, 'Подсказка содержит корень загаданного слова.');
    END IF;
END trg_hints_check_root;
/


CREATE OR REPLACE TRIGGER trg_words_history
BEFORE UPDATE OF word,theme_id,root_id OR DELETE ON Words
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM ActiveWords
     WHERE word_id=:OLD.word_id;
    IF v_count>0 THEN
        RAISE_APPLICATION_ERROR(-20020,
            'Нельзя менять или удалять уже использованное слово.');
    END IF;
END trg_words_history;
/


CREATE OR REPLACE TRIGGER trg_sessions_identity
BEFORE UPDATE OF player1_id,player2_id,theme_id,round_limit,round_time_sec,created_at
OR DELETE ON Sessions
FOR EACH ROW
BEGIN
    RAISE_APPLICATION_ERROR(-20026,
        'Правила и участники созданной сессии неизменяемы.');
END trg_sessions_identity;
/


CREATE OR REPLACE TRIGGER trg_rounds_history
BEFORE UPDATE OF session_id,round_number,explainer_id,guesser_id,started_at
OR DELETE ON Rounds
FOR EACH ROW
BEGIN
    RAISE_APPLICATION_ERROR(-20027,
        'Принадлежность, роли и начало раунда неизменяемы.');
END trg_rounds_history;
/


CREATE OR REPLACE TRIGGER trg_activewords_history
BEFORE UPDATE OR DELETE ON ActiveWords
FOR EACH ROW
BEGIN
    IF DELETING THEN
        RAISE_APPLICATION_ERROR(-20028,'Выдачу нельзя удалить.');
    END IF;
    IF :OLD.round_id != :NEW.round_id OR
       :OLD.issue_no != :NEW.issue_no OR :OLD.word_id != :NEW.word_id OR
       :OLD.assigned_at != :NEW.assigned_at OR :OLD.skipped_at IS NOT NULL OR
       :NEW.skipped_at IS NULL THEN
        RAISE_APPLICATION_ERROR(-20028,
            'Выдачу нельзя удалить, изменить или пропустить повторно.');
    END IF;
END trg_activewords_history;
/

CREATE OR REPLACE TRIGGER trg_hints_history
BEFORE UPDATE OR DELETE ON Hints
FOR EACH ROW
BEGIN
    RAISE_APPLICATION_ERROR(-20029,
        'Историю подсказок нельзя изменять или удалять.');
END trg_hints_history;
/


CREATE OR REPLACE TRIGGER trg_guesses_history
BEFORE INSERT OR UPDATE OR DELETE ON Guesses
FOR EACH ROW
DECLARE
    v_started Rounds.started_at%TYPE;
    v_ended Rounds.ended_at%TYPE;
    v_seconds Sessions.round_time_sec%TYPE;
    v_assigned ActiveWords.assigned_at%TYPE;
    v_skipped ActiveWords.skipped_at%TYPE;
    v_hints NUMBER;
BEGIN
    IF UPDATING OR DELETING THEN
        RAISE_APPLICATION_ERROR(-20021,
            'Историю ответов нельзя изменять или удалять.');
    END IF;
    SELECT r.started_at,r.ended_at,s.round_time_sec,aw.assigned_at,aw.skipped_at
      INTO v_started,v_ended,v_seconds,v_assigned,v_skipped
      FROM ActiveWords aw JOIN Rounds r ON r.round_id=aw.round_id
      JOIN Sessions s ON s.session_id=r.session_id
     WHERE aw.round_id=:NEW.round_id AND aw.issue_no=:NEW.issue_no;
    IF v_ended IS NOT NULL OR :NEW.guessed_at < v_assigned OR
       :NEW.guessed_at >= v_started + NUMTODSINTERVAL(v_seconds,'SECOND') OR
       (v_skipped IS NOT NULL AND :NEW.guessed_at >= v_skipped) THEN
        RAISE_APPLICATION_ERROR(-20022,
            'Ответ вне времени активной выдачи запрещён.');
    END IF;
    SELECT COUNT(*) INTO v_hints FROM Hints
     WHERE round_id=:NEW.round_id AND issue_no=:NEW.issue_no
       AND created_at<=:NEW.guessed_at;
    IF v_hints=0 THEN
        RAISE_APPLICATION_ERROR(-20005,
            'До ответа объясняющий должен дать подсказку.');
    END IF;
END trg_guesses_history;
/


CREATE OR REPLACE TRIGGER trg_rounds_members
BEFORE INSERT OR UPDATE OF session_id,round_number,explainer_id,guesser_id
ON Rounds
FOR EACH ROW
DECLARE
    v_p1 NUMBER; v_p2 NUMBER; v_limit NUMBER;
BEGIN
    SELECT player1_id,player2_id,round_limit INTO v_p1,v_p2,v_limit
      FROM Sessions WHERE session_id=:NEW.session_id;
    IF :NEW.round_number>v_limit OR
       NOT ((:NEW.explainer_id=v_p1 AND :NEW.guesser_id=v_p2)
         OR (:NEW.explainer_id=v_p2 AND :NEW.guesser_id=v_p1)) THEN
        RAISE_APPLICATION_ERROR(-20023,
            'Роли раунда должны принадлежать двум участникам сессии.');
    END IF;
END trg_rounds_members;
/


CREATE OR REPLACE TRIGGER trg_activewords_theme
BEFORE INSERT OR UPDATE OF round_id,word_id,assigned_at ON ActiveWords
FOR EACH ROW
DECLARE
    v_theme NUMBER; v_word_theme NUMBER; v_active NUMBER;
    v_start TIMESTAMP; v_end TIMESTAMP; v_seconds NUMBER;
BEGIN
    SELECT s.theme_id,r.started_at,r.ended_at,s.round_time_sec
      INTO v_theme,v_start,v_end,v_seconds
      FROM Rounds r JOIN Sessions s ON s.session_id=r.session_id
     WHERE r.round_id=:NEW.round_id;
    SELECT theme_id,is_active INTO v_word_theme,v_active
      FROM Words WHERE word_id=:NEW.word_id;
    IF v_word_theme!=v_theme OR v_active!=1 OR v_end IS NOT NULL OR
       :NEW.assigned_at<v_start OR
       :NEW.assigned_at>=v_start+NUMTODSINTERVAL(v_seconds,'SECOND') THEN
        RAISE_APPLICATION_ERROR(-20024,
            'Слово должно быть активно в теме открытого раунда.');
    END IF;
END trg_activewords_theme;
/


CREATE OR REPLACE TRIGGER trg_notifications_member
BEFORE INSERT OR UPDATE OF session_id,player_id ON Notifications
FOR EACH ROW
DECLARE
    v_p1 NUMBER; v_p2 NUMBER;
BEGIN
    SELECT player1_id,player2_id INTO v_p1,v_p2
      FROM Sessions WHERE session_id=:NEW.session_id;
    IF :NEW.player_id NOT IN (v_p1,v_p2) THEN
        RAISE_APPLICATION_ERROR(-20025,
            'Адресат уведомления не участвует в сессии.');
    END IF;
END trg_notifications_member;
/






-----------------------------------------------------------------------






CREATE OR REPLACE PACKAGE GAME_PKG IS
    PROCEDURE create_session(
        p_player1_id IN NUMBER, p_player2_id IN NUMBER, p_theme IN VARCHAR2,
        p_round_limit IN NUMBER, p_round_time_sec IN NUMBER,
        p_session_id OUT NUMBER, p_round_id OUT NUMBER,
        p_explainer_id OUT NUMBER, p_guesser_id OUT NUMBER);

    PROCEDURE advance_session(p_session_id IN NUMBER);
    PROCEDURE advance_due_sessions;
    FUNCTION round_score(p_round_id IN NUMBER) RETURN NUMBER;

    FUNCTION get_current_word(p_session_id IN NUMBER, p_player_id IN NUMBER)
        RETURN VARCHAR2;
    PROCEDURE submit_hint(p_session_id IN NUMBER, p_player_id IN NUMBER,
                          p_hint_text IN VARCHAR2);
    FUNCTION submit_guess(p_session_id IN NUMBER, p_player_id IN NUMBER,
                          p_guess_text IN VARCHAR2) RETURN BOOLEAN;
    PROCEDURE skip_word(p_session_id IN NUMBER, p_player_id IN NUMBER);

    PROCEDURE get_state(
        p_session_id IN NUMBER, p_status OUT VARCHAR2, p_round_num OUT NUMBER,
        p_total_score OUT NUMBER, p_time_left OUT NUMBER,
        p_explainer_id OUT NUMBER, p_guesser_id OUT NUMBER,
        p_explainer_name OUT VARCHAR2, p_guesser_name OUT VARCHAR2);
    FUNCTION get_notifications(p_session_id IN NUMBER, p_player_id IN NUMBER)
        RETURN SYS_REFCURSOR;
    PROCEDURE mark_notifications_read(p_session_id IN NUMBER, p_player_id IN NUMBER);
    FUNCTION get_guesses_history(p_session_id IN NUMBER, p_round_num IN NUMBER)
        RETURN SYS_REFCURSOR;
END GAME_PKG;
/

CREATE OR REPLACE PACKAGE BODY GAME_PKG IS
    FUNCTION now_ts RETURN TIMESTAMP IS
    BEGIN
        RETURN CAST(SYSTIMESTAMP AS TIMESTAMP);
    END now_ts;

    PROCEDURE broadcast_message(p_session_id NUMBER, p_text VARCHAR2) IS
        v_p1 Sessions.player1_id%TYPE;
        v_p2 Sessions.player2_id%TYPE;
    BEGIN
        SELECT player1_id, player2_id INTO v_p1, v_p2
          FROM Sessions WHERE session_id = p_session_id;
        INSERT INTO Notifications(notif_id,session_id,player_id,message)
          VALUES(seq_notif.NEXTVAL,p_session_id,v_p1,p_text);
        INSERT INTO Notifications(notif_id,session_id,player_id,message)
          VALUES(seq_notif.NEXTVAL,p_session_id,v_p2,p_text);
    END broadcast_message;


    PROCEDURE issue_word(p_round_id NUMBER, p_assigned_at TIMESTAMP,
                         p_required BOOLEAN DEFAULT TRUE) IS
        v_theme_id NUMBER;
        v_word_id NUMBER;
        v_next NUMBER;
    BEGIN
        SELECT s.theme_id INTO v_theme_id
          FROM Rounds r JOIN Sessions s ON s.session_id = r.session_id
         WHERE r.round_id = p_round_id;
        BEGIN
            SELECT word_id INTO v_word_id FROM (
                SELECT w.word_id FROM Words w
                 WHERE w.theme_id = v_theme_id AND w.is_active = 1
                   AND NOT EXISTS (
                       SELECT 1 FROM ActiveWords aw
                        WHERE aw.round_id = p_round_id AND aw.word_id = w.word_id)
                 ORDER BY DBMS_RANDOM.VALUE
            ) WHERE ROWNUM = 1;
        EXCEPTION WHEN NO_DATA_FOUND THEN
            BEGIN
                SELECT word_id INTO v_word_id FROM (
                    SELECT w.word_id FROM Words w
                     WHERE w.theme_id = v_theme_id AND w.is_active = 1
                     ORDER BY DBMS_RANDOM.VALUE
                ) WHERE ROWNUM = 1;
            EXCEPTION WHEN NO_DATA_FOUND THEN
                IF p_required THEN
                    RAISE_APPLICATION_ERROR(-20002,'В теме нет активных слов.');
                END IF;
                RETURN;
            END;
        END;
        SELECT NVL(MAX(issue_no),0) + 1 INTO v_next
          FROM ActiveWords WHERE round_id = p_round_id;
        INSERT INTO ActiveWords(round_id,issue_no,word_id,assigned_at)
          VALUES(p_round_id,v_next,v_word_id,p_assigned_at);
    END issue_word;

    PROCEDURE ensure_word(p_round_id NUMBER) IS
        v_issue NUMBER;
        v_skipped TIMESTAMP;
        v_correct NUMBER;
    BEGIN
        BEGIN
            SELECT issue_no,skipped_at INTO v_issue,v_skipped
              FROM ActiveWords
             WHERE round_id = p_round_id
               AND issue_no = (SELECT MAX(issue_no) FROM ActiveWords
                                WHERE round_id = p_round_id);
        EXCEPTION WHEN NO_DATA_FOUND THEN
            issue_word(p_round_id,now_ts);
            RETURN;
        END;
        SELECT COUNT(*) INTO v_correct
          FROM Guesses g JOIN ActiveWords aw
            ON aw.round_id = g.round_id AND aw.issue_no = g.issue_no
            JOIN Words w ON w.word_id = aw.word_id
         WHERE g.round_id = p_round_id AND g.issue_no = v_issue
           AND UTL_RAW.COMPARE(UTL_RAW.CAST_TO_RAW(g.guess_text),
                               UTL_RAW.CAST_TO_RAW(w.word)) = 0;
        IF v_skipped IS NOT NULL OR v_correct > 0 THEN
            issue_word(p_round_id,now_ts);
        END IF;
    END ensure_word;

    FUNCTION round_score(p_round_id IN NUMBER) RETURN NUMBER IS
        v_score NUMBER;
    BEGIN
        
        SELECT COUNT(*) INTO v_score
          FROM ActiveWords aw JOIN Words w ON w.word_id = aw.word_id
          JOIN Rounds r ON r.round_id = aw.round_id
          JOIN Sessions s ON s.session_id = r.session_id
         WHERE aw.round_id = p_round_id
           AND EXISTS (
               SELECT 1 FROM Guesses g
                WHERE g.round_id = aw.round_id AND g.issue_no = aw.issue_no
                  AND g.guessed_at >= aw.assigned_at
                  AND g.guessed_at <
                      r.started_at + NUMTODSINTERVAL(s.round_time_sec,'SECOND')
                  AND (aw.skipped_at IS NULL OR g.guessed_at < aw.skipped_at)
                  AND UTL_RAW.COMPARE(UTL_RAW.CAST_TO_RAW(g.guess_text),
                                      UTL_RAW.CAST_TO_RAW(w.word)) = 0);
        RETURN v_score;
    END round_score;


    PROCEDURE record_if_best(p_round_id NUMBER, p_score NUMBER) IS
        v_p1 NUMBER; v_p2 NUMBER; v_best NUMBER := 0;
    BEGIN
        IF p_score = 0 THEN RETURN; END IF;
        SELECT s.player1_id,s.player2_id INTO v_p1,v_p2
          FROM Rounds r JOIN Sessions s ON s.session_id = r.session_id
         WHERE r.round_id = p_round_id;
        FOR player_row IN (
            SELECT player_id FROM Players
             WHERE player_id IN (v_p1,v_p2)
             ORDER BY player_id FOR UPDATE
        ) LOOP
            NULL;
        END LOOP;
        FOR rec IN (
            SELECT rr.round_id FROM Records x
              JOIN Rounds rr ON rr.round_id = x.round_id
              JOIN Sessions ss ON ss.session_id = rr.session_id
             WHERE LEAST(ss.player1_id,ss.player2_id) = LEAST(v_p1,v_p2)
               AND GREATEST(ss.player1_id,ss.player2_id) = GREATEST(v_p1,v_p2)
        ) LOOP
            v_best := GREATEST(v_best,round_score(rec.round_id));
        END LOOP;
        IF p_score > v_best THEN
            INSERT INTO Records(record_id,round_id,recorded_at)
              VALUES(seq_records.NEXTVAL,p_round_id,
                     CAST(SYSTIMESTAMP AS TIMESTAMP));
        END IF;
    END record_if_best;

    PROCEDURE advance_session(p_session_id IN NUMBER) IS
        v_session Sessions%ROWTYPE;
        v_round Rounds%ROWTYPE;
        v_now TIMESTAMP := now_ts;
        v_due TIMESTAMP;
        v_score NUMBER;
        v_total NUMBER;
        v_next_id NUMBER;
    BEGIN
       
        SELECT * INTO v_session FROM Sessions
         WHERE session_id = p_session_id FOR UPDATE;
        WHILE v_session.finished_at IS NULL LOOP
            SELECT * INTO v_round FROM Rounds
             WHERE session_id = p_session_id AND ended_at IS NULL;
            v_due := v_round.started_at
                     + NUMTODSINTERVAL(v_session.round_time_sec,'SECOND');
            EXIT WHEN v_now < v_due;
            
            UPDATE Rounds SET ended_at = v_due WHERE round_id = v_round.round_id;
            v_score := round_score(v_round.round_id);
            record_if_best(v_round.round_id,v_score);

            IF v_round.round_number = v_session.round_limit THEN
                v_total := 0;
                FOR closed_round IN (
                    SELECT round_id FROM Rounds WHERE session_id = p_session_id
                ) LOOP
                    v_total := v_total + round_score(closed_round.round_id);
                END LOOP;
                UPDATE Sessions SET finished_at = v_due, final_score = v_total
                 WHERE session_id = p_session_id;
                broadcast_message(p_session_id,
                    'Сессия завершена. Общий счёт: ' || v_total);
                v_session.finished_at := v_due;
            ELSE
                v_next_id := seq_rounds.NEXTVAL;
                INSERT INTO Rounds(round_id,session_id,round_number,
                                   explainer_id,guesser_id,started_at)
                VALUES(v_next_id,p_session_id,v_round.round_number+1,
                       v_round.guesser_id,v_round.explainer_id,v_due);
                
                IF v_now < v_due
                           + NUMTODSINTERVAL(v_session.round_time_sec,'SECOND') THEN
                    issue_word(v_next_id,v_now,FALSE);
                END IF;
                broadcast_message(p_session_id,
                    'Раунд ' || v_round.round_number || ' завершён. Раунд ' ||
                    (v_round.round_number+1) || ': объясняет игрок ' ||
                    v_round.guesser_id);
            END IF;
        END LOOP;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20010,'Сессия или открытый раунд не найдены: ' ||
                                        p_session_id);
    END advance_session;

    PROCEDURE advance_due_sessions IS
    BEGIN
        FOR sess IN (
            SELECT s.session_id FROM Sessions s JOIN Rounds r
              ON r.session_id = s.session_id
             WHERE s.finished_at IS NULL AND r.ended_at IS NULL
               AND r.started_at + NUMTODSINTERVAL(s.round_time_sec,'SECOND')
                     <= CAST(SYSTIMESTAMP AS TIMESTAMP)
             ORDER BY s.session_id
        ) LOOP
            advance_session(sess.session_id);
            COMMIT;
        END LOOP;
    END advance_due_sessions;

    PROCEDURE create_session(
        p_player1_id IN NUMBER,p_player2_id IN NUMBER,p_theme IN VARCHAR2,
        p_round_limit IN NUMBER,p_round_time_sec IN NUMBER,
        p_session_id OUT NUMBER,p_round_id OUT NUMBER,
        p_explainer_id OUT NUMBER,p_guesser_id OUT NUMBER) IS
        v_theme_id NUMBER;
        v_count NUMBER;
        v_at TIMESTAMP := now_ts;
    BEGIN
        SAVEPOINT game_create_session;
        IF p_player1_id IS NULL OR p_player2_id IS NULL
           OR p_player1_id = p_player2_id THEN
            RAISE_APPLICATION_ERROR(-20011,'Нужны два разных игрока.');
        END IF;
        IF p_round_limit IS NULL OR p_round_limit != TRUNC(p_round_limit)
           OR p_round_limit NOT BETWEEN 1 AND 100
           OR p_round_time_sec IS NULL
           OR p_round_time_sec != TRUNC(p_round_time_sec)
           OR p_round_time_sec NOT BETWEEN 1 AND 86400 THEN
            RAISE_APPLICATION_ERROR(-20012,
                'Число раундов 1..100, длительность 1..86400 секунд.');
        END IF;
        SELECT COUNT(*) INTO v_count FROM Players
         WHERE player_id IN (p_player1_id,p_player2_id);
        IF v_count != 2 THEN
            RAISE_APPLICATION_ERROR(-20011,'Оба игрока должны существовать.');
        END IF;
        BEGIN
            SELECT theme_id INTO v_theme_id FROM Themes WHERE name = p_theme;
        EXCEPTION WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002,'Тема не найдена.');
        END;
        SELECT COUNT(*) INTO v_count FROM Words
         WHERE theme_id = v_theme_id AND is_active = 1;
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20002,'В теме нет активных слов.');
        END IF;
        IF DBMS_RANDOM.VALUE < 0.5 THEN
            p_explainer_id := p_player1_id;
            p_guesser_id := p_player2_id;
        ELSE
            p_explainer_id := p_player2_id;
            p_guesser_id := p_player1_id;
        END IF;
        p_session_id := seq_sessions.NEXTVAL;
        p_round_id := seq_rounds.NEXTVAL;
        INSERT INTO Sessions(session_id,player1_id,player2_id,theme_id,
                             round_limit,round_time_sec,created_at)
        VALUES(p_session_id,p_player1_id,p_player2_id,v_theme_id,
               p_round_limit,p_round_time_sec,v_at);
        INSERT INTO Rounds(round_id,session_id,round_number,
                           explainer_id,guesser_id,started_at)
        VALUES(p_round_id,p_session_id,1,p_explainer_id,p_guesser_id,v_at);
        issue_word(p_round_id,v_at);
        COMMIT;
    EXCEPTION WHEN OTHERS THEN
        ROLLBACK TO game_create_session;
        RAISE;
    END create_session;

    
    PROCEDURE lock_action(p_session_id NUMBER,p_player_id NUMBER,
                          p_role VARCHAR2,p_round OUT Rounds%ROWTYPE) IS
        v_session Sessions%ROWTYPE;
        v_due TIMESTAMP;
    BEGIN
        advance_session(p_session_id);
        COMMIT; 
        SELECT * INTO v_session FROM Sessions
         WHERE session_id = p_session_id FOR UPDATE;
        IF v_session.finished_at IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20006,'Сессия завершена.');
        END IF;
        SELECT * INTO p_round FROM Rounds
         WHERE session_id = p_session_id AND ended_at IS NULL;
        v_due := p_round.started_at +
                 NUMTODSINTERVAL(v_session.round_time_sec,'SECOND');
        IF now_ts >= v_due THEN
            advance_session(p_session_id);
            COMMIT;
            RAISE_APPLICATION_ERROR(-20004,'Время раунда истекло; проверьте роли.');
        END IF;
        IF p_player_id IS NULL OR
           (p_role = 'EXPLAINER' AND p_player_id != p_round.explainer_id) OR
           (p_role = 'GUESSER' AND p_player_id != p_round.guesser_id) THEN
            RAISE_APPLICATION_ERROR(-20007,'Действие недоступно для текущей роли.');
        END IF;
    END lock_action;

    
    PROCEDURE require_time(p_session_id NUMBER,p_round Rounds%ROWTYPE) IS
        v_seconds Sessions.round_time_sec%TYPE;
    BEGIN
        SELECT round_time_sec INTO v_seconds FROM Sessions
         WHERE session_id = p_session_id;
        IF now_ts >= p_round.started_at +
                     NUMTODSINTERVAL(v_seconds,'SECOND') THEN
            advance_session(p_session_id);
            COMMIT;
            RAISE_APPLICATION_ERROR(-20004,'Время раунда истекло; проверьте роли.');
        END IF;
    END require_time;

    PROCEDURE latest_issue(p_round_id NUMBER,p_issue OUT NUMBER,
                           p_word_id OUT NUMBER,p_skipped OUT TIMESTAMP) IS
        v_correct NUMBER;
    BEGIN
        SELECT issue_no,word_id,skipped_at
          INTO p_issue,p_word_id,p_skipped FROM ActiveWords
         WHERE round_id = p_round_id
           AND issue_no = (SELECT MAX(issue_no) FROM ActiveWords
                            WHERE round_id = p_round_id);
        IF p_skipped IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20003,'Открытого слова нет.');
        END IF;
        SELECT COUNT(*) INTO v_correct
          FROM Guesses g JOIN Words w ON w.word_id = p_word_id
         WHERE g.round_id = p_round_id AND g.issue_no = p_issue
           AND UTL_RAW.COMPARE(UTL_RAW.CAST_TO_RAW(g.guess_text),
                               UTL_RAW.CAST_TO_RAW(w.word)) = 0;
        IF v_correct > 0 THEN
            RAISE_APPLICATION_ERROR(-20003,'Открытого слова нет.');
        END IF;
    END latest_issue;

    FUNCTION get_current_word(p_session_id IN NUMBER,p_player_id IN NUMBER)
        RETURN VARCHAR2 IS
        v_round Rounds%ROWTYPE;
        v_issue NUMBER; v_word_id NUMBER; v_skipped TIMESTAMP;
        v_word Words.word%TYPE;
    BEGIN
        lock_action(p_session_id,p_player_id,'EXPLAINER',v_round);
        require_time(p_session_id,v_round);
        ensure_word(v_round.round_id);
        latest_issue(v_round.round_id,v_issue,v_word_id,v_skipped);
        SELECT word INTO v_word FROM Words WHERE word_id = v_word_id;
        COMMIT;
        RETURN v_word;
    END get_current_word;

    PROCEDURE submit_hint(p_session_id IN NUMBER,p_player_id IN NUMBER,
                          p_hint_text IN VARCHAR2) IS
        v_round Rounds%ROWTYPE;
        v_issue NUMBER; v_word_id NUMBER; v_skipped TIMESTAMP;
    BEGIN
        lock_action(p_session_id,p_player_id,'EXPLAINER',v_round);
        IF TRIM(p_hint_text) IS NULL THEN
            RAISE_APPLICATION_ERROR(-20009,'Подсказка не должна быть пустой.');
        END IF;
        require_time(p_session_id,v_round);
        ensure_word(v_round.round_id);
        latest_issue(v_round.round_id,v_issue,v_word_id,v_skipped);
        require_time(p_session_id,v_round);
        INSERT INTO Hints(hint_id,round_id,issue_no,hint_text,created_at)
        VALUES(seq_hints.NEXTVAL,v_round.round_id,v_issue,p_hint_text,
               CAST(SYSTIMESTAMP AS TIMESTAMP));
        COMMIT;
    END submit_hint;

    FUNCTION submit_guess(p_session_id IN NUMBER,p_player_id IN NUMBER,
                          p_guess_text IN VARCHAR2) RETURN BOOLEAN IS
        v_round Rounds%ROWTYPE;
        v_issue NUMBER; v_word_id NUMBER; v_skipped TIMESTAMP;
        v_word Words.word%TYPE;
        v_hints NUMBER;
        v_correct BOOLEAN;
        v_at TIMESTAMP;
    BEGIN
        lock_action(p_session_id,p_player_id,'GUESSER',v_round);
        IF TRIM(p_guess_text) IS NULL THEN
            RAISE_APPLICATION_ERROR(-20013,'Ответ не должен быть пустым.');
        END IF;
        latest_issue(v_round.round_id,v_issue,v_word_id,v_skipped);
        SELECT COUNT(*) INTO v_hints FROM Hints
         WHERE round_id = v_round.round_id AND issue_no = v_issue;
        IF v_hints = 0 THEN
            RAISE_APPLICATION_ERROR(-20005,'Сначала нужна подсказка.');
        END IF;
        SELECT word INTO v_word FROM Words WHERE word_id = v_word_id;
        v_correct := UTL_RAW.COMPARE(UTL_RAW.CAST_TO_RAW(p_guess_text),
                                     UTL_RAW.CAST_TO_RAW(v_word)) = 0;
        require_time(p_session_id,v_round);
        v_at := now_ts;
        INSERT INTO Guesses(guess_id,round_id,issue_no,guess_text,guessed_at)
          VALUES(seq_guesses.NEXTVAL,v_round.round_id,v_issue,p_guess_text,v_at);
        IF v_correct THEN
            issue_word(v_round.round_id,v_at,FALSE);
            broadcast_message(p_session_id,'Слово отгадано. Выдано новое слово.');
        END IF;
        COMMIT;
        RETURN v_correct;
    END submit_guess;

    PROCEDURE skip_word(p_session_id IN NUMBER,p_player_id IN NUMBER) IS
        v_round Rounds%ROWTYPE;
        v_issue NUMBER; v_word_id NUMBER; v_skipped TIMESTAMP;
        v_at TIMESTAMP;
    BEGIN
        lock_action(p_session_id,p_player_id,'EXPLAINER',v_round);
        latest_issue(v_round.round_id,v_issue,v_word_id,v_skipped);
        require_time(p_session_id,v_round);
        v_at := now_ts;
        UPDATE ActiveWords SET skipped_at = v_at
         WHERE round_id = v_round.round_id AND issue_no = v_issue;
        issue_word(v_round.round_id,v_at,FALSE);
        broadcast_message(p_session_id,'Слово пропущено. Выдано новое слово.');
        COMMIT;
    END skip_word;

    PROCEDURE get_state(
        p_session_id IN NUMBER,p_status OUT VARCHAR2,p_round_num OUT NUMBER,
        p_total_score OUT NUMBER,p_time_left OUT NUMBER,
        p_explainer_id OUT NUMBER,p_guesser_id OUT NUMBER,
        p_explainer_name OUT VARCHAR2,p_guesser_name OUT VARCHAR2) IS
        v_session Sessions%ROWTYPE;
        v_round Rounds%ROWTYPE;
        v_remaining INTERVAL DAY TO SECOND;
    BEGIN
        advance_session(p_session_id);
        COMMIT;
        SELECT * INTO v_session FROM Sessions WHERE session_id = p_session_id;
        IF v_session.finished_at IS NULL THEN
            SELECT * INTO v_round FROM Rounds
             WHERE session_id = p_session_id AND ended_at IS NULL;
            v_remaining :=
                v_round.started_at +
                NUMTODSINTERVAL(v_session.round_time_sec,'SECOND') - now_ts;
            p_time_left := GREATEST(0,
                EXTRACT(DAY FROM v_remaining)*86400 +
                EXTRACT(HOUR FROM v_remaining)*3600 +
                EXTRACT(MINUTE FROM v_remaining)*60 +
                EXTRACT(SECOND FROM v_remaining));
            p_total_score := 0;
            FOR rr IN (SELECT round_id FROM Rounds
                        WHERE session_id = p_session_id) LOOP
                p_total_score := p_total_score + round_score(rr.round_id);
            END LOOP;
            p_status := 'Активна';
        ELSE
            SELECT * INTO v_round FROM Rounds
             WHERE session_id = p_session_id
               AND round_number = v_session.round_limit;
            p_time_left := 0;
            p_total_score := v_session.final_score;
            p_status := 'Завершена';
        END IF;
        p_round_num := v_round.round_number;
        p_explainer_id := v_round.explainer_id;
        p_guesser_id := v_round.guesser_id;
        SELECT display_name INTO p_explainer_name FROM Players
         WHERE player_id = p_explainer_id;
        SELECT display_name INTO p_guesser_name FROM Players
         WHERE player_id = p_guesser_id;
    END get_state;

    FUNCTION get_notifications(p_session_id IN NUMBER,p_player_id IN NUMBER)
        RETURN SYS_REFCURSOR IS
        v_result SYS_REFCURSOR;
    BEGIN
        advance_session(p_session_id);
        COMMIT;
        OPEN v_result FOR
          SELECT notif_id,message,created_at FROM Notifications
           WHERE session_id = p_session_id AND player_id = p_player_id
             AND read_at IS NULL
           ORDER BY created_at,notif_id;
        RETURN v_result;
    END get_notifications;

    PROCEDURE mark_notifications_read(p_session_id IN NUMBER,p_player_id IN NUMBER) IS
    BEGIN
        UPDATE Notifications SET read_at = CAST(SYSTIMESTAMP AS TIMESTAMP)
         WHERE session_id = p_session_id AND player_id = p_player_id
           AND read_at IS NULL;
        COMMIT;
    END mark_notifications_read;

    FUNCTION get_guesses_history(p_session_id IN NUMBER,p_round_num IN NUMBER)
        RETURN SYS_REFCURSOR IS
        v_result SYS_REFCURSOR;
    BEGIN
        OPEN v_result FOR
          SELECT g.guess_text,g.guessed_at,
                 CASE WHEN UTL_RAW.COMPARE(
                     UTL_RAW.CAST_TO_RAW(g.guess_text),
                     UTL_RAW.CAST_TO_RAW(w.word)) = 0 THEN 1 ELSE 0 END
            FROM Guesses g JOIN ActiveWords aw
              ON aw.round_id = g.round_id AND aw.issue_no = g.issue_no
              JOIN Words w ON w.word_id = aw.word_id
              JOIN Rounds r ON r.round_id = g.round_id
           WHERE r.session_id = p_session_id AND r.round_number = p_round_num
           ORDER BY g.guessed_at DESC,g.guess_id DESC;
        RETURN v_result;
    END get_guesses_history;
END GAME_PKG;
/





---------------------------------------------------------------------------





CREATE OR REPLACE PROCEDURE check_round_timeout IS
BEGIN
    GAME_PKG.advance_due_sessions;
END check_round_timeout;
/

BEGIN
    DBMS_SCHEDULER.CREATE_JOB(
        job_name        => 'CHECK_ROUND_TIMEOUT_JOB',
        job_type        => 'STORED_PROCEDURE',
        job_action      => 'CHECK_ROUND_TIMEOUT',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=SECONDLY;INTERVAL=1',
        enabled         => TRUE,
        auto_drop       => FALSE,
        comments        => 'Переход между раундами игры Угадай слово по времени'
    );
END;
/















