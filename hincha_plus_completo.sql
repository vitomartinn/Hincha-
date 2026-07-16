-- ============================================================
-- HINCHA+ - SCRIPT SQL COMPLETO
-- Proyecto Integrador - Primer Ano
-- Base de datos: hincha_plus
-- Motor: MySQL / MariaDB (XAMPP)
-- ============================================================

-- ============================================================
-- 1. CREACION DE LA BASE DE DATOS
-- ============================================================
DROP DATABASE IF EXISTS hincha_plus;
CREATE DATABASE hincha_plus
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_ci;

USE hincha_plus;

-- ============================================================
-- 2. DEFINICION DE TABLAS
-- ============================================================

CREATE TABLE equipos (
    id_equipo    INT AUTO_INCREMENT PRIMARY KEY,
    nombre_club  VARCHAR(100) NOT NULL UNIQUE,
    estadio      VARCHAR(150) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE usuarios (
    id_usuario     INT AUTO_INCREMENT PRIMARY KEY,
    dni            VARCHAR(15)  NOT NULL UNIQUE,
    nombre         VARCHAR(150) NOT NULL,
    email          VARCHAR(150) NOT NULL UNIQUE,
    password_hash  VARCHAR(255) NOT NULL,
    id_equipo      INT          NOT NULL,
    estado         VARCHAR(20)  NOT NULL DEFAULT 'Activo',
    rol            VARCHAR(30)  NOT NULL DEFAULT 'Hincha_Comun',
    creado_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_equipo) REFERENCES equipos(id_equipo)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE partidos (
    id_partido           INT AUTO_INCREMENT PRIMARY KEY,
    id_equipo_local      INT       NOT NULL,
    id_equipo_visitante  INT       NOT NULL,
    fecha_partido        TIMESTAMP NOT NULL,
    estadio_sede         VARCHAR(150),
    FOREIGN KEY (id_equipo_local) REFERENCES equipos(id_equipo)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (id_equipo_visitante) REFERENCES equipos(id_equipo)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE foros_debate (
    id_foro      INT AUTO_INCREMENT PRIMARY KEY,
    id_equipo    INT NOT NULL UNIQUE,
    nombre_foro  VARCHAR(150) NOT NULL,
    descripcion  VARCHAR(255),
    FOREIGN KEY (id_equipo) REFERENCES equipos(id_equipo)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE juntadas (
    id_juntada            INT AUTO_INCREMENT PRIMARY KEY,
    id_organizador        INT           NOT NULL,
    id_partido            INT           NOT NULL,
    punto_encuentro_lat   NUMERIC(10,7) NOT NULL,
    punto_encuentro_lng   NUMERIC(10,7) NOT NULL,
    descripcion_punto     VARCHAR(255),
    cupo_maximo           SMALLINT      NOT NULL,
    estado                VARCHAR(20)   NOT NULL DEFAULT 'Abierta',
    creado_at             TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_organizador) REFERENCES usuarios(id_usuario)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (id_partido) REFERENCES partidos(id_partido)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE miembros_juntada (
    id_miembro         INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario         INT     NOT NULL,
    id_juntada         INT     NOT NULL,
    estado_logistico   VARCHAR(20) NOT NULL DEFAULT 'Pendiente',
    solicitado_at      TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (id_usuario, id_juntada),
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (id_juntada) REFERENCES juntadas(id_juntada)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE mensajes_chat (
    id_mensaje        INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario        INT           NOT NULL,
    id_foro           INT           NULL,
    id_juntada        INT           NULL,
    contenido_texto   VARCHAR(1000) NOT NULL,
    enviado_at        TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (id_foro) REFERENCES foros_debate(id_foro)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (id_juntada) REFERENCES juntadas(id_juntada)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE hitos_transaccionales (
    id_hito         INT AUTO_INCREMENT PRIMARY KEY,
    id_juntada      INT          NOT NULL,
    id_usuario      INT          NULL,
    tipo_evento     VARCHAR(40)  NOT NULL,
    descripcion     VARCHAR(255) NOT NULL,
    registrado_at   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_juntada) REFERENCES juntadas(id_juntada)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- 3. FUNCIONES
-- ============================================================

DELIMITER $$

-- Funcion: contar_miembros_juntada
-- Proposito: Retorna la cantidad actual de miembros inscriptos en una juntada
CREATE FUNCTION contar_miembros_juntada(p_id_juntada INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total INT;
    SELECT COUNT(*) INTO v_total
    FROM miembros_juntada
    WHERE id_juntada = p_id_juntada;
    RETURN v_total;
END$$

-- Funcion: juntada_tiene_cupo
-- Proposito: Retorna 1 si la juntada tiene cupo disponible, 0 si esta llena
CREATE FUNCTION juntada_tiene_cupo(p_id_juntada INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_ocupados INT;
    DECLARE v_maximo INT;
    SELECT COUNT(*), j.cupo_maximo INTO v_ocupados, v_maximo
    FROM miembros_juntada mj
    JOIN juntadas j ON j.id_juntada = mj.id_juntada
    WHERE mj.id_juntada = p_id_juntada
    GROUP BY j.cupo_maximo;
    IF v_ocupados < v_maximo THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END$$

DELIMITER ;

-- ============================================================
-- 4. PROCEDIMIENTOS ALMACENADOS
-- ============================================================

DELIMITER $$

CREATE PROCEDURE historial_chat_juntada(IN juntada_id INT)
BEGIN
    SELECT u.nombre AS nombre_usuario, m.id_usuario, m.contenido_texto, m.enviado_at
    FROM mensajes_chat m
    JOIN usuarios u ON u.id_usuario = m.id_usuario
    WHERE m.id_juntada = juntada_id
    ORDER BY m.enviado_at ASC;
END$$

CREATE PROCEDURE registrar_checkin(IN usuario_id INT, IN juntada_id INT)
BEGIN
    UPDATE miembros_juntada
    SET estado_logistico = 'Presente'
    WHERE id_usuario = usuario_id AND id_juntada = juntada_id;

    INSERT INTO hitos_transaccionales (id_juntada, id_usuario, tipo_evento, descripcion)
    VALUES (juntada_id, usuario_id, 'CheckIn', 'El usuario confirmo su llegada al punto de encuentro.');
END$$

DELIMITER ;

-- ============================================================
-- 5. INSERCION DE DATOS (MINIMO 10 REGISTROS POR TABLA)
-- ============================================================

-- -----------------------------------------------------------
-- 5.1 EQUIPOS (12 registros)
-- -----------------------------------------------------------
INSERT INTO equipos (nombre_club, estadio) VALUES
('Boca Juniors',           'La Bombonera'),
('River Plate',            'Estadio Monumental Antonio Vespucio Liberti'),
('Racing Club',            'Estadio Presidente Peron'),
('Independiente',          'Estadio Libertadores de America'),
('San Lorenzo',            'Estadio Pedro Bidegain'),
('Velez Sarsfield',        'Estadio Jose Amalfitani'),
('Estudiantes LP',         'Estadio Jorge Luis Hirschi'),
('Gimnasia LP',            'Estadio Juan Carmelo Zerillo'),
('Huracan',                'Estadio Tomas Adolfo Duco'),
('Ferro Carril Oeste',     'Estadio Armando Marchetti'),
('Defensa y Justicia',     'Estadio Norberto Tomaghello'),
('Talleres de Cordoba',    'Estadio Mario Alberto Kempes');

-- -----------------------------------------------------------
-- 5.2 USUARIOS (12 registros)
-- -----------------------------------------------------------
INSERT INTO usuarios (dni, nombre, email, password_hash, id_equipo, estado, rol) VALUES
('40123456', 'Martin Gonzalez',   'martin.gonzalez@mail.com',   '$2y$10$8KzQxG5r3v2u1v9QxKxKxOxKxKxKxKxKxKxKxKxKxKxKxKxKxK', 1,  'Activo', 'Hincha_Comun'),
('38987654', 'Lucia Fernandez',   'lucia.fernandez@mail.com',   '$2y$10$8KzQxG5r3v2u1v9QxKxKxOxKxKxKxKxKxKxKxKxKxKxKxKxKxK', 2,  'Activo', 'Hincha_Comun'),
('42345678', 'Pablo Rodriguez',   'pablo.rodriguez@mail.com',   '$2y$10$8KzQxG5r3v2u1v9QxKxKxOxKxKxKxKxKxKxKxKxKxKxKxKxKxK', 3,  'Activo', 'Hincha_Comun'),
('39567890', 'Camila Lopez',      'camila.lopez@mail.com',      '$2y$10$8KzQxG5r3v2u1v9QxKxKxOxKxKxKxKxKxKxKxKxKxKxKxKxKxK', 4,  'Activo', 'Hincha_Comun'),
('41234567', 'Mateo Garcia',      'mateo.garcia@mail.com',      '$2y$10$8KzQxG5r3v2u1v9QxKxKxOxKxKxKxKxKxKxKxKxKxKxKxKxKxK', 5,  'Activo', 'Hincha_Comun'),
('37890123', 'Valentina Martinez','valentina.martinez@mail.com','$2y$10$8KzQxG5r3v2u1v9QxKxKxOxKxKxKxKxKxKxKxKxKxKxKxKxKxK', 6,  'Activo', 'Hincha_Comun'),
('43456789', 'Santiago Perez',    'santiago.perez@mail.com',    '$2y$10$8KzQxG5r3v2u1v9QxKxKxOxKxKxKxKxKxKxKxKxKxKxKxKxKxK', 7,  'Activo', 'Hincha_Comun'),
('40567891', 'Isabela Romero',    'isabela.romero@mail.com',    '$2y$10$8KzQxG5r3v2u1v9QxKxKxOxKxKxKxKxKxKxKxKxKxKxKxKxKxK', 8,  'Activo', 'Hincha_Comun'),
('38678912', 'Dylan Torres',      'dylan.torres@mail.com',      '$2y$10$8KzQxG5r3v2u1v9QxKxKxOxKxKxKxKxKxKxKxKxKxKxKxKxKxK', 9,  'Activo', 'Hincha_Comun'),
('41789012', 'Sofia Diaz',        'sofia.diaz@mail.com',        '$2y$10$8KzQxG5r3v2u1v9QxKxKxOxKxKxKxKxKxKxKxKxKxKxKxKxKxK', 10, 'Activo', 'Hincha_Comun'),
('39890123', 'Nicolas Sanchez',   'nicolas.sanchez@mail.com',   '$2y$10$8KzQxG5r3v2u1v9QxKxKxOxKxKxKxKxKxKxKxKxKxKxKxKxKxK', 11, 'Activo', 'Hincha_Comun'),
('42901234', 'Julieta Morales',   'julieta.morales@mail.com',   '$2y$10$8KzQxG5r3v2u1v9QxKxKxOxKxKxKxKxKxKxKxKxKxKxKxKxKxK', 12, 'Activo', 'Hincha_Comun');

-- -----------------------------------------------------------
-- 5.3 PARTIDOS (12 registros)
-- -----------------------------------------------------------
INSERT INTO partidos (id_equipo_local, id_equipo_visitante, fecha_partido, estadio_sede) VALUES
(1,  2,  '2026-08-10 18:00:00', 'La Bombonera'),
(3,  4,  '2026-08-11 20:30:00', 'Estadio Presidente Peron'),
(5,  6,  '2026-08-15 19:00:00', 'Estadio Pedro Bidegain'),
(7,  8,  '2026-08-17 16:00:00', 'Estadio Jorge Luis Hirschi'),
(9,  10, '2026-08-20 18:30:00', 'Estadio Tomas Adolfo Duco'),
(11, 12, '2026-08-22 20:00:00', 'Estadio Norberto Tomaghello'),
(2,  3,  '2026-08-25 21:00:00', 'Estadio Monumental'),
(6,  1,  '2026-08-28 19:30:00', 'Estadio Jose Amalfitani'),
(4,  5,  '2026-09-01 18:00:00', 'Estadio Libertadores de America'),
(8,  9,  '2026-09-03 20:00:00', 'Estadio Juan Carmelo Zerillo'),
(10, 11, '2026-09-05 17:00:00', 'Estadio Armando Marchetti'),
(12, 7,  '2026-09-08 21:30:00', 'Estadio Mario Alberto Kempes');

-- -----------------------------------------------------------
-- 5.4 FOROS_DEBATE (12 registros - 1 por equipo)
-- -----------------------------------------------------------
INSERT INTO foros_debate (id_equipo, nombre_foro, descripcion) VALUES
(1,  'Foro Boca Juniors',          'Debate abierto sobre la actualidad del Club Boca Juniors'),
(2,  'Foro River Plate',           'Espacio de discusion para los hinchas de River Plate'),
(3,  'Foro Racing Club',           'Debate sobre Racing y su campeonato'),
(4,  'Foro Independiente',         'El Rojo tiene mucho que decir: unite al debate'),
(5,  'Foro San Lorenzo',           'La voz del Cuervo en la comunidad HINCHA+'),
(6,  'Foro Velez Sarsfield',       'Debate sobre Velez y sus futuras figuretas'),
(7,  'Foro Estudiantes LP',        'El Pincha se debate aqui'),
(8,  'Foro Gimnasia LP',           'El Lobo de La Plata tiene su espacio de opinion'),
(9,  'Foro Huracan',               'El Globo infla su debate en HINCHA+'),
(10, 'Foro Ferro Carril Oeste',    'La Verde tiene su foro oficial en la plataforma'),
(11, 'Foro Defensa y Justicia',    'El Halcon debate sobre su crecimiento en el futbol argentino'),
(12, 'Foro Talleres de Cordoba',   'La Gladiadora de Cordoba tiene su espacio de discusion');

-- -----------------------------------------------------------
-- 5.5 JUNTADAS (12 registros)
-- -----------------------------------------------------------
INSERT INTO juntadas (id_organizador, id_partido, punto_encuentro_lat, punto_encuentro_lng, descripcion_punto, cupo_maximo, estado) VALUES
(1,  1,  -34.6357000, -58.3649000, 'Bar La 12 - Esquina de Brandsen y Warnes',              30, 'Abierta'),
(2,  1,  -34.6400000, -58.3610000, 'Estacion de subte La Boca',                              20, 'Abierta'),
(3,  2,  -34.5407000, -58.4498000, 'Bar Racing - Avenida Mitre 5550',                        25, 'Abierta'),
(4,  2,  -34.5389000, -58.4512000, 'Plaza San Martin de Avellaneda',                         40, 'Abierta'),
(5,  3,  -34.6292000, -58.3725000, 'MundoLeon - Avenida Juan B. Justo 9500',                 15, 'Abierta'),
(6,  4,  -34.9108000, -57.9521000, 'Cerveceria El Pincha - Calle 7 entre 51 y 53',          35, 'Abierta'),
(7,  5,  -34.5794000, -58.4172000, 'Sede Social Huracan - Avenida Gavilán 780',             20, 'Abierta'),
(8,  6,  -34.6268000, -58.5623000, 'Bar Ferro - Avenida Juan Aguirre 4850',                 18, 'Abierta'),
(9,  7,  -34.5440000, -58.4425000, 'Bar Monumental - Calle Emilio Fabiani',                  50, 'Abierta'),
(10, 8,  -34.5833000, -58.4167000, 'Estadio Jose Amalfitani - Lado Este',                    25, 'Abierta'),
(11, 9,  -34.6642000, -58.3629000, 'Bajo Autodromo - Lateral Libertador',                    30, 'Abierta'),
(12, 10, -34.9133000, -57.9497000, 'Plaza Moreno - Centro de La Plata',                      22, 'Cerrada');

-- -----------------------------------------------------------
-- 5.6 MIEMBROS_JUNTADA (minimo 12 registros)
-- -----------------------------------------------------------
INSERT INTO miembros_juntada (id_usuario, id_juntada, estado_logistico) VALUES
(1,  1,  'Organizador'),
(2,  1,  'Pendiente'),
(3,  1,  'Presente'),
(2,  2,  'Organizador'),
(1,  2,  'Pendiente'),
(3,  3,  'Organizador'),
(4,  3,  'Presente'),
(5,  3,  'Pendiente'),
(4,  4,  'Organizador'),
(5,  5,  'Organizador'),
(6,  5,  'Presente'),
(7,  6,  'Organizador'),
(8,  6,  'Pendiente'),
(9,  7,  'Organizador'),
(10, 8,  'Organizador'),
(11, 9,  'Organizador'),
(12, 10, 'Organizador'),
(1,  9,  'Pendiente'),
(6,  10, 'Presente'),
(3,  11, 'Pendiente');

-- -----------------------------------------------------------
-- 5.7 MENSAJES_CHAT (minimo 12 registros)
-- -----------------------------------------------------------
INSERT INTO mensajes_chat (id_usuario, id_foro, id_juntada, contenido_texto) VALUES
-- Mensajes en foros
(1,  1,  NULL, 'Boca viene bien este semestre, que opinan?'),
(2,  1,  NULL, 'Coincido, el equipo esta creciendo mucho'),
(3,  2,  NULL, 'River no baja el nivel, grande elMillonario'),
(4,  2,  NULL, 'Para mi Racing esta mejor que River este ano'),
(5,  5,  NULL, 'San Lorenzo tiene que apuntar al repechaje'),
(6,  6,  NULL, 'Velez esta formando buenos juveniles'),
-- Mensajes en juntadas
(1,  NULL, 1,  'Hola gente, me acerco por el Bar La 12'),
(2,  NULL, 1,  'Perfecto, llego a las 17:30'),
(3,  NULL, 1,  'Ya estoy en la esquina, los espero'),
(5,  NULL, 3,  'Racing dale campeon! Nos vemos en el bar'),
(7,  NULL, 6,  'El Ferro esta pasando por un buen momento'),
(8,  NULL, 6,  'Siii, hay que bancar al equipo');

-- -----------------------------------------------------------
-- 5.8 HITOS_TRANSACCIONALES (minimo 12 registros)
-- -----------------------------------------------------------
INSERT INTO hitos_transaccionales (id_juntada, id_usuario, tipo_evento, descripcion) VALUES
(1,  1,  'JuntadaCreada',  'Martin creo la juntada para Boca vs River'),
(1,  3,  'CheckIn',        'Pablo confirmo su llegada al Bar La 12'),
(1,  2,  'CheckIn',        'Lucia confirmo su llegada al punto de encuentro'),
(2,  2,  'JuntadaCreada',  'Lucia creo la juntada alternativa para Boca vs River'),
(3,  3,  'JuntadaCreada',  'Pablo creo la juntada para Racing vs Independiente'),
(3,  4,  'CheckIn',        'Camila confirmo su llegada al Bar Racing'),
(5,  5,  'JuntadaCreada',  'Mateo creo la juntada para San Lorenzo vs Velez'),
(5,  6,  'CheckIn',        'Valentina confirmo su llegada a MundoLeon'),
(6,  7,  'JuntadaCreada',  'Santiago creo la juntada para Estudiantes vs Gimnasia'),
(9,  11, 'JuntadaCreada',  'Nicolas creo la juntada para River vs Racing'),
(10, 12, 'JuntadaCreada',  'Julieta creo la juntada para Velez vs Boca'),
(11, 3,  'MiembroUnido',   'Pablo se unio a la juntada del Bajo Autodromo');

-- ============================================================
-- 6. VERIFICACION DE INTEGRIDAD
-- ============================================================

-- Verificar cantidad de registros por tabla
SELECT 'equipos' AS tabla, COUNT(*) AS total FROM equipos
UNION ALL
SELECT 'usuarios',              COUNT(*) FROM usuarios
UNION ALL
SELECT 'partidos',              COUNT(*) FROM partidos
UNION ALL
SELECT 'foros_debate',          COUNT(*) FROM foros_debate
UNION ALL
SELECT 'juntadas',              COUNT(*) FROM juntadas
UNION ALL
SELECT 'miembros_juntada',      COUNT(*) FROM miembros_juntada
UNION ALL
SELECT 'mensajes_chat',         COUNT(*) FROM mensajes_chat
UNION ALL
SELECT 'hitos_transaccionales', COUNT(*) FROM hitos_transaccionales;

-- Verificar funciones
SELECT contar_miembros_juntada(1) AS miembros_juntada_1;
SELECT juntada_tiene_cupo(1) AS juntada_1_tiene_cupo;

-- ============================================================
-- FIN DEL SCRIPT
-- ============================================================
