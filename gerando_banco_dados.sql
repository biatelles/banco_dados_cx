-- Criando schema
CREATE SCHEMA customer_experience AUTHORIZATION dsa;

-- Criando tabela clientes
CREATE TABLE customer_experience.clientes (
    ID SERIAL,
    Data_entrada DATE NOT NULL,
    Segmento VARCHAR(255) NOT NULL,
    Porte VARCHAR(255),
    MRR NUMERIC(10, 2) NOT NULL,
    Status VARCHAR(255) NOT NULL,
    Data_cancelamento DATE
);

-- Criando tabela expansao

CREATE TABLE customer_experience.expansao (
    ID_oportunidade SERIAL,
    ID_cliente INT NOT NULL,
    Data_criacao DATE NOT NULL,
    Data_fechamento DATE,
    Etapa VARCHAR(255) NOT NULL,
    Valor NUMERIC(10, 2) NOT NULL
);

-- Criando tabela tickets

CREATE TABLE customer_experience.tickets (
    ID_ticket SERIAL,
    ID_cliente INT NOT NULL,
    Data_abertura DATE NOT NULL,
    Data_primeira_resposta DATE,
    Data_fechamento DATE,
    Categoria VARCHAR(255) NOT NULL,
    NPS NUMERIC(2,0),
    Resolvido_na_primeira_resposta BOOLEAN
);

-- Criando tabela de interações com a equipe de CS

CREATE TABLE customer_experience.interacoes_cs (
    ID_interacao SERIAL,
    ID_cliente INT NOT NULL,
    Data_interacao DATE NOT NULL,
    Tipo_interacao VARCHAR(255) NOT NULL,
    Responsavel VARCHAR(255) NOT NULL
);

-- Criando tabela de projetos de melhoria

CREATE TABLE customer_experience.projetos_melhoria (
    ID_projeto SERIAL,
    Area VARCHAR(255) NOT NULL,
    Data_inicio DATE NOT NULL,
    Data_fim_prevista DATE,
    Data_fim_real DATE,
    Status VARCHAR(255) NOT NULL,
    Impacto_esperado VARCHAR(255),
    Prioridade VARCHAR(255)
);

-- Fazendo a carga de dados:

-- Stored Procedure: clientes
CREATE OR REPLACE PROCEDURE customer_experience.inserir_dados_clientes()
LANGUAGE plpgsql
AS $$
DECLARE
    i INT := 1;
    randomDataEntrada DATE;
    randomSegmento VARCHAR(255);
    randomPorte VARCHAR(255);
    randomMRR NUMERIC(10, 2);
    randomStatus VARCHAR(255);
    randomDataCancelamento DATE;
    desligadoCount INT := 0;
BEGIN
    LOOP
        EXIT WHEN i > 1000;

        randomDataEntrada := DATE '2022-01-01' + (FLOOR(RANDOM() * (DATE '2025-12-31' - DATE '2022-01-01')))::INT;

        randomSegmento := CASE FLOOR(RANDOM() * 3)
            WHEN 0 THEN 'Tecnologia'
            WHEN 1 THEN 'Saúde'
            ELSE 'Educação'
        END;

        randomPorte := CASE FLOOR(RANDOM() * 3)
            WHEN 0 THEN 'Pequeno'
            WHEN 1 THEN 'Médio'
            ELSE 'Grande'
        END;

        randomMRR := ROUND((1000 + RANDOM() * 99000)::numeric, 2);

        -- Status: exatamente 300 'Desligado', restante 'Ativo'
        IF desligadoCount < 300 AND (RANDOM() < 0.35 OR i > 1000 - (300 - desligadoCount)) THEN
            randomStatus := 'Desligado';
            desligadoCount := desligadoCount + 1;
            randomDataCancelamento := randomDataEntrada + (1 + FLOOR(RANDOM() * (DATE '2025-12-31' - randomDataEntrada)))::INT;
            IF randomDataCancelamento > DATE '2025-12-31' THEN
                randomDataCancelamento := DATE '2025-12-31';
            END IF;
        ELSE
            randomStatus := 'Ativo';
            randomDataCancelamento := NULL;
        END IF;

        INSERT INTO customer_experience.clientes
            (Data_entrada, Segmento, Porte, MRR, Status, Data_cancelamento)
        VALUES
            (randomDataEntrada, randomSegmento, randomPorte, randomMRR, randomStatus, randomDataCancelamento);

        i := i + 1;
    END LOOP;
END;
$$;

-- Limpando a tabela clientes para rodar o ajuste da regra de negócio

TRUNCATE TABLE customer_experience.clientes RESTART IDENTITY CASCADE;

-- Chamando a procedure novamente 

CALL customer_experience.inserir_dados_clientes();

-- Stored Procedure: expansao
CREATE OR REPLACE PROCEDURE customer_experience.inserir_dados_expansao()
LANGUAGE plpgsql
AS $$
DECLARE
    i INT := 1;
    randomIDCliente INT;
    randomDataCriacao DATE;
    randomDataFechamento DATE;
    randomEtapa VARCHAR(255);
    randomValor NUMERIC(10, 2);
    maxClienteID INT;
BEGIN
    SELECT MAX(ID) INTO maxClienteID FROM customer_experience.clientes;

    LOOP
        EXIT WHEN i > 1000;

        randomIDCliente := 1 + FLOOR(RANDOM() * maxClienteID)::INT;

        randomDataCriacao := DATE '2022-01-01' + (FLOOR(RANDOM() * (DATE '2025-12-31' - DATE '2022-01-01')))::INT;

        IF RANDOM() < 0.8 THEN
            randomDataFechamento := randomDataCriacao + (1 + FLOOR(RANDOM() * (DATE '2025-12-31' - randomDataCriacao)))::INT;
            IF randomDataFechamento > DATE '2025-12-31' THEN
                randomDataFechamento := NULL;
            END IF;
        ELSE
            randomDataFechamento := NULL;
        END IF;

        randomEtapa := CASE FLOOR(RANDOM() * 6)
            WHEN 0 THEN 'Identificada'
            WHEN 1 THEN 'Qualificada'
            WHEN 2 THEN 'Proposta enviada'
            WHEN 3 THEN 'Negociação'
            WHEN 4 THEN 'Fechado ganho'
            ELSE 'Fechado perdido'
        END;

        randomValor := ROUND((300 + RANDOM() * 1700)::numeric, 2);

        INSERT INTO customer_experience.expansao
            (ID_cliente, Data_criacao, Data_fechamento, Etapa, Valor)
        VALUES
            (randomIDCliente, randomDataCriacao, randomDataFechamento, randomEtapa, randomValor);

        i := i + 1;
    END LOOP;
END;
$$;


-- Stored Procedure: tickets
CREATE OR REPLACE PROCEDURE customer_experience.inserir_dados_tickets()
LANGUAGE plpgsql
AS $$
DECLARE
    i INT := 1;
    randomIDCliente INT;
    randomDataAbertura DATE;
    randomDataPrimeiraResposta DATE;
    randomDataFechamento DATE;
    randomCategoria VARCHAR(255);
    randomNPS NUMERIC(2, 0);
    randomResolvido BOOLEAN;
    fechamentoCount INT := 0;
    maxClienteID INT;
BEGIN
    SELECT MAX(ID) INTO maxClienteID FROM customer_experience.clientes;

    LOOP
        EXIT WHEN i > 100000;

        randomIDCliente := 1 + FLOOR(RANDOM() * maxClienteID)::INT;

        randomDataAbertura := DATE '2022-01-01' + (FLOOR(RANDOM() * (DATE '2025-12-31' - DATE '2022-01-01')))::INT;

        randomDataPrimeiraResposta := randomDataAbertura + (1 + FLOOR(RANDOM() * 10))::INT;
        IF randomDataPrimeiraResposta > DATE '2025-12-31' THEN
            randomDataPrimeiraResposta := DATE '2025-12-31';
        END IF;

        IF fechamentoCount < 65000 AND RANDOM() < 0.67 THEN
            randomDataFechamento := randomDataPrimeiraResposta + (1 + FLOOR(RANDOM() * 30))::INT;
            IF randomDataFechamento > DATE '2025-12-31' THEN
                randomDataFechamento := NULL;
                randomNPS := NULL;
                randomResolvido := NULL;
            ELSE
                fechamentoCount := fechamentoCount + 1;
                randomNPS := 1 + FLOOR(RANDOM() * 10);
                randomResolvido := RANDOM() < 0.5;
            END IF;
        ELSE
            randomDataFechamento := NULL;
            randomNPS := NULL;
            randomResolvido := NULL;
        END IF;

        randomCategoria := CASE FLOOR(RANDOM() * 6)
            WHEN 0 THEN 'Bug na plataforma'
            WHEN 1 THEN 'Erro de login'
            WHEN 2 THEN 'Instabilidade'
            WHEN 3 THEN 'Lentidão'
            WHEN 4 THEN 'Integração não funcionando'
            ELSE 'Falha em relatório/exportação'
        END;

        INSERT INTO customer_experience.tickets
            (ID_cliente, Data_abertura, Data_primeira_resposta, Data_fechamento, Categoria, NPS, Resolvido_na_primeira_resposta)
        VALUES
            (randomIDCliente, randomDataAbertura, randomDataPrimeiraResposta, randomDataFechamento, randomCategoria, randomNPS, randomResolvido);

        i := i + 1;
    END LOOP;
END;
$$;


-- Stored Procedure: interacoes_cs
CREATE OR REPLACE PROCEDURE customer_experience.inserir_dados_interacoes_cs()
LANGUAGE plpgsql
AS $$
DECLARE
    i INT := 1;
    randomIDCliente INT;
    randomDataInteracao DATE;
    randomTipoInteracao VARCHAR(255);
    randomResponsavel VARCHAR(255);
    maxClienteID INT;
BEGIN
    SELECT MAX(ID) INTO maxClienteID FROM customer_experience.clientes;

    LOOP
        EXIT WHEN i > 10000;

        randomIDCliente := 1 + FLOOR(RANDOM() * maxClienteID)::INT;

        randomDataInteracao := DATE '2022-01-01' + (FLOOR(RANDOM() * (DATE '2025-12-31' - DATE '2022-01-01')))::INT;

        randomTipoInteracao := CASE FLOOR(RANDOM() * 3)
            WHEN 0 THEN 'Mensagem'
            WHEN 1 THEN 'E-mail'
            ELSE 'Reunião'
        END;

        randomResponsavel := CASE FLOOR(RANDOM() * 8)
            WHEN 0 THEN 'Maria'
            WHEN 1 THEN 'João'
            WHEN 2 THEN 'Joana'
            WHEN 3 THEN 'Carla'
            WHEN 4 THEN 'Matheus'
            WHEN 5 THEN 'Flávia'
            WHEN 6 THEN 'Marcos'
            ELSE 'Ana'
        END;

        INSERT INTO customer_experience.interacoes_cs
            (ID_cliente, Data_interacao, Tipo_interacao, Responsavel)
        VALUES
            (randomIDCliente, randomDataInteracao, randomTipoInteracao, randomResponsavel);

        i := i + 1;
    END LOOP;
END;
$$;


-- Stored Procedure: projetos_melhoria
CREATE OR REPLACE PROCEDURE customer_experience.inserir_dados_projetos_melhoria()
LANGUAGE plpgsql
AS $$
DECLARE
    i INT := 1;
    randomArea VARCHAR(255);
    randomDataInicio DATE;
    randomDataFimPrevista DATE;
    randomDataFimReal DATE;
    randomStatus VARCHAR(255);
    randomImpacto VARCHAR(255);
    randomPrioridade VARCHAR(255);
    fimRealCount INT := 0;
BEGIN
    LOOP
        EXIT WHEN i > 1000;

        randomArea := CASE FLOOR(RANDOM() * 8)
            WHEN 0 THEN 'Customer Success'
            WHEN 1 THEN 'Suporte'
            WHEN 2 THEN 'Implementação'
            WHEN 3 THEN 'Produto'
            WHEN 4 THEN 'Comercial'
            WHEN 5 THEN 'Financeiro'
            WHEN 6 THEN 'Operações'
            ELSE 'Estratégia'
        END;

        randomDataInicio := DATE '2022-01-01' + (FLOOR(RANDOM() * (DATE '2025-12-31' - DATE '2022-01-01')))::INT;

        randomDataFimPrevista := randomDataInicio + (1 + FLOOR(RANDOM() * (DATE '2025-12-31' - randomDataInicio)))::INT;
        IF randomDataFimPrevista > DATE '2025-12-31' THEN
            randomDataFimPrevista := DATE '2025-12-31';
        END IF;

        IF fimRealCount < 500 AND RANDOM() < 0.55 THEN
            randomDataFimReal := randomDataInicio + (1 + FLOOR(RANDOM() * (DATE '2025-12-31' - randomDataInicio)))::INT;
            IF randomDataFimReal > DATE '2025-12-31' THEN
                randomDataFimReal := NULL;
            ELSE
                fimRealCount := fimRealCount + 1;
            END IF;
        ELSE
            randomDataFimReal := NULL;
        END IF;

        randomStatus := CASE FLOOR(RANDOM() * 7)
            WHEN 0 THEN 'Planejado'
            WHEN 1 THEN 'Em andamento'
            WHEN 2 THEN 'Em risco'
            WHEN 3 THEN 'Atrasado'
            WHEN 4 THEN 'Concluído'
            WHEN 5 THEN 'Cancelado'
            ELSE 'Pausado'
        END;

        randomImpacto := CASE FLOOR(RANDOM() * 4)
            WHEN 0 THEN 'Financeiro'
            WHEN 1 THEN 'Operacional'
            WHEN 2 THEN 'Experiência'
            ELSE 'Estratégico'
        END;

        randomPrioridade := CASE FLOOR(RANDOM() * 3)
            WHEN 0 THEN 'Baixa'
            WHEN 1 THEN 'Média'
            ELSE 'Alta'
        END;

        INSERT INTO customer_experience.projetos_melhoria
            (Area, Data_inicio, Data_fim_prevista, Data_fim_real, Status, Impacto_esperado, Prioridade)
        VALUES
            (randomArea, randomDataInicio, randomDataFimPrevista, randomDataFimReal, randomStatus, randomImpacto, randomPrioridade);

        i := i + 1;
    END LOOP;
END;
$$;


-- Executar todas as procedures
CALL customer_experience.inserir_dados_clientes();
CALL customer_experience.inserir_dados_expansao();
CALL customer_experience.inserir_dados_tickets();
CALL customer_experience.inserir_dados_interacoes_cs();
CALL customer_experience.inserir_dados_projetos_melhoria();


-- Verificar os dados
SELECT * FROM customer_experience.clientes;
SELECT * FROM customer_experience.expansao;
SELECT * FROM customer_experience.tickets LIMIT 100;
SELECT * FROM customer_experience.interacoes_cs;
SELECT * FROM customer_experience.projetos_melhoria;