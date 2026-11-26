

CREATE TABLE jogadores (
    id SERIAL PRIMARY KEY,
    nome_jogador VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    senha VARCHAR(100) NOT NULL,
    status VARCHAR(20) DEFAULT 'ativo'
        CHECK (status IN ('ativo', 'inativo', 'banido')),
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE modalidades (
    id SERIAL PRIMARY KEY,
    nome_jogo VARCHAR(100) UNIQUE NOT NULL,
    categoria VARCHAR(50) NOT NULL
);


CREATE TABLE torneios (
    id SERIAL PRIMARY KEY,
    modalidade_id INT NOT NULL REFERENCES modalidades(id),
    nome_torneio VARCHAR(100) NOT NULL,
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    CHECK (data_fim >= data_inicio)
);


CREATE TABLE inscricoes (
    id SERIAL PRIMARY KEY,
    jogador_id INT NOT NULL REFERENCES jogadores(id),
    torneio_id INT NOT NULL REFERENCES torneios(id),
    data_inscricao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'confirmada'
        CHECK (status IN ('confirmada', 'pendente', 'cancelada')),
    UNIQUE (jogador_id, torneio_id)
);


CREATE TABLE partidas (
    id SERIAL PRIMARY KEY,
    jogador_id INT NOT NULL REFERENCES jogadores(id),
    torneio_id INT NOT NULL REFERENCES torneios(id),
    titulo_partida VARCHAR(100) NOT NULL,
    data_agendamento TIMESTAMP NOT NULL,
    status VARCHAR(20) DEFAULT 'agendada'
        CHECK (status IN ('agendada', 'em andamento', 'finalizada', 'cancelada')),
    data_criacao TIMESTAMP
);


CREATE TABLE historico_partidas (
    id SERIAL PRIMARY KEY,
    partida_id INT NOT NULL REFERENCES partidas(id),
    acao VARCHAR(50) NOT NULL,
    descricao VARCHAR(200),
    data_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


INSERT INTO jogadores (nome_jogador, email, senha, status)
VALUES
('Brayan de Souza', 'brayan@email.com', '123456', 'ativo'),
('Nicolas Augusto', 'nicolas@email.com', '654321', 'ativo'),
('Victor Farinha', 'victor@email.com', '987654', 'ativo'),
('Noah Navarro', 'noah@email.com', '111222', 'inativo'),
('Vitor Melao', 'vitinho@email.com', '333444', 'banido');


INSERT INTO modalidades (nome_jogo, categoria)
VALUES
('fortnite', 'fps'),
('sky wars', 'minecraft'),
('counter strike 2', 'fps');


INSERT INTO torneios
(modalidade_id, nome_torneio, data_inicio, data_fim)
VALUES
(1, 'copa fortnite', CURRENT_DATE + 1, CURRENT_DATE + 10),
(2, 'guerra no ceu', CURRENT_DATE + 5, CURRENT_DATE + 15),
(3, 'torneio cs2', CURRENT_DATE + 10, CURRENT_DATE + 20);


INSERT INTO inscricoes (jogador_id, torneio_id, status)
VALUES
(1, 1, 'confirmada'),
(2, 2, 'confirmada'),
(3, 3, 'pendente');


CREATE FUNCTION fn_validar_partida()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_status VARCHAR(20);
BEGIN
    SELECT status
    INTO v_status
    FROM jogadores
    WHERE id = NEW.jogador_id;

    IF v_status IS NULL OR v_status <> 'ativo' THEN
        RAISE EXCEPTION 'jogador nao esta ativo!';
    END IF;

    NEW.data_criacao = CURRENT_TIMESTAMP;

    RETURN NEW;
END;
$$;


CREATE TRIGGER trg_validar_partida
BEFORE INSERT ON partidas
FOR EACH ROW
EXECUTE FUNCTION fn_validar_partida();


CREATE FUNCTION fn_registrar_historico()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO historico_partidas
    (partida_id, acao, descricao)
    VALUES
    (NEW.id, 'criacao', 'partida cadastrada no sistema');

    RETURN NEW;
END;
$$;


CREATE TRIGGER trg_registrar_historico
AFTER INSERT ON partidas
FOR EACH ROW
EXECUTE FUNCTION fn_registrar_historico();


INSERT INTO partidas
(jogador_id, torneio_id, titulo_partida, data_agendamento, status)
VALUES
(1, 1, 'Brayan de Souza x jogador 2', CURRENT_TIMESTAMP + INTERVAL '3 days', 'agendada'),
(2, 2, 'Nicolas Augusto x jogador 4', CURRENT_TIMESTAMP + INTERVAL '7 days', 'agendada'),
(3, 3, 'Victor Farinha x jogador 5', CURRENT_TIMESTAMP + INTERVAL '10 days', 'agendada');


CREATE FUNCTION fn_buscar_jogadores(p_termo VARCHAR)
RETURNS TABLE (
    id INT,
    nome_jogador VARCHAR(100),
    email VARCHAR(100),
    status VARCHAR(20)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        j.id,
        j.nome_jogador,
        j.email,
        j.status
    FROM jogadores j
    WHERE j.nome_jogador ILIKE '%' || p_termo || '%'
       OR j.email ILIKE '%' || p_termo || '%';
END;
$$;


CREATE VIEW vw_painel_principal AS
SELECT
    jogadores.nome_jogador,
    partidas.titulo_partida,
    modalidades.categoria,
    partidas.data_agendamento,
    partidas.status
FROM partidas
JOIN jogadores
    ON partidas.jogador_id = jogadores.id
JOIN torneios
    ON partidas.torneio_id = torneios.id
JOIN modalidades
    ON torneios.modalidade_id = modalidades.id;


CREATE VIEW vw_cronograma_partidas AS
SELECT
    partidas.id,
    partidas.titulo_partida,
    partidas.data_agendamento,
    partidas.status,
    partidas.data_agendamento::DATE - CURRENT_DATE AS dias_restantes,
    jogadores.nome_jogador
FROM partidas
JOIN jogadores
    ON partidas.jogador_id = jogadores.id
ORDER BY partidas.data_agendamento ASC;


SELECT * FROM jogadores;

SELECT * FROM modalidades;

SELECT * FROM torneios;

SELECT * FROM inscricoes;

SELECT * FROM partidas;

SELECT * FROM historico_partidas;


SELECT * FROM fn_buscar_jogadores('Brayan de Souza');


SELECT * FROM vw_painel_principal;


SELECT * FROM vw_cronograma_partidas
ORDER BY data_agendamento ASC;
