-- ============================================================
-- HINCHA+ - SCRIPT SQL COMPLETO Y UNIFICADO
-- Proyecto Integrador
-- Base de datos: hincha_plus
-- Motor: MySQL / MariaDB (XAMPP)
-- ============================================================

DROP DATABASE IF EXISTS hincha_plus;
CREATE DATABASE hincha_plus
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE hincha_plus;

-- ============================================================
-- 1. TABLAS
-- ============================================================

CREATE TABLE equipos (
    id_equipo    INT AUTO_INCREMENT PRIMARY KEY,
    nombre_club  VARCHAR(100) NOT NULL UNIQUE,
    estadio      VARCHAR(150) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE usuarios (
    id_usuario     INT AUTO_INCREMENT PRIMARY KEY,
    dni            VARCHAR(15)  NOT NULL UNIQUE,
    nombre         VARCHAR(150) NOT NULL,
    email          VARCHAR(150) NOT NULL UNIQUE,
    password_hash  VARCHAR(255) NOT NULL,
    id_equipo      INT          NOT NULL,
    estado         VARCHAR(20)  NOT NULL DEFAULT 'Activo',
    -- 'rol' es el campo de permisos del usuario: 'admin' o 'user'.
    -- Ya existia en el proyecto (antes solo tenia el valor fijo
    -- 'Hincha_Comun', sin usarse para nada); en vez de agregar una
    -- columna 'role' duplicada, se reutiliza esta con los dos
    -- valores que necesita el sistema de permisos.
    rol            VARCHAR(20)  NOT NULL DEFAULT 'user',
    creado_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_equipo) REFERENCES equipos(id_equipo)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_usuarios_rol CHECK (rol IN ('admin', 'user'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE foros_debate (
    id_foro            INT AUTO_INCREMENT PRIMARY KEY,
    nombre_foro        VARCHAR(150) NOT NULL,
    descripcion        VARCHAR(255),
    tipo               VARCHAR(10)  NOT NULL DEFAULT 'Club',
    id_equipo          INT NULL,
    categoria_general  VARCHAR(60) NULL,
    id_usuario_creador INT NOT NULL,
    creado_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_equipo) REFERENCES equipos(id_equipo)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (id_usuario_creador) REFERENCES usuarios(id_usuario)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE juntadas (
    id_juntada            INT AUTO_INCREMENT PRIMARY KEY,
    id_organizador        INT           NOT NULL,
    id_partido            INT           NOT NULL,
    nombre                VARCHAR(150)  NOT NULL DEFAULT '',
    punto_encuentro_lat   DECIMAL(10,8) NOT NULL,
    punto_encuentro_lng   DECIMAL(11,8) NOT NULL,
    descripcion_punto     VARCHAR(255),
    cupo_maximo           SMALLINT      NOT NULL,
    estado                VARCHAR(20)   NOT NULL DEFAULT 'Abierta',
    creado_at             TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_organizador) REFERENCES usuarios(id_usuario)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (id_partido) REFERENCES partidos(id_partido)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE hitos_transaccionales (
    id_hito         INT AUTO_INCREMENT PRIMARY KEY,
    -- id_juntada es NULL-able y ON DELETE SET NULL (antes era
    -- NOT NULL + CASCADE). Es una tabla de auditoria/bitacora: el
    -- historial tiene que sobrevivir aunque la juntada que motivo
    -- el evento se elimine despues (por ejemplo, al usar la nueva
    -- funcionalidad de "eliminar juntada"). Con CASCADE, borrar una
    -- juntada borraba tambien su propio historial de un plumazo,
    -- lo cual va en contra del proposito de esta tabla.
    id_juntada      INT          NULL,
    id_usuario      INT          NULL,
    tipo_evento     VARCHAR(40)  NOT NULL,
    descripcion     VARCHAR(255) NOT NULL,
    registrado_at   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_juntada) REFERENCES juntadas(id_juntada)
        ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- 2. FUNCIONES ORIGINALES
-- ============================================================

DELIMITER $$

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

CREATE FUNCTION juntada_tiene_cupo(p_id_juntada INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    -- Antes esto se resolvia con un solo SELECT ... JOIN ... GROUP BY,
    -- que dependia de que existiera AL MENOS UN miembro para que el
    -- INNER JOIN devolviera una fila. Mientras la funcion solo se
    -- llamaba en trg_cerrar_juntada_llena (siempre AFTER INSERT, o
    -- sea que como minimo hay 1 miembro) nunca se notaba. Al sumar
    -- la baja de miembros (trg_reabrir_juntada_con_cupo, AFTER
    -- DELETE) una juntada puede quedar con 0 miembros, el JOIN no
    -- encuentra fila, y la funcion devolvia "sin cupo" de forma
    -- incorrecta. Separar los dos SELECT lo arregla de raiz.
    DECLARE v_ocupados INT;
    DECLARE v_maximo INT;

    SELECT cupo_maximo INTO v_maximo
    FROM juntadas WHERE id_juntada = p_id_juntada;

    SELECT COUNT(*) INTO v_ocupados
    FROM miembros_juntada WHERE id_juntada = p_id_juntada;

    IF v_maximo IS NULL THEN
        RETURN 0;
    ELSEIF v_ocupados < v_maximo THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END$$

DELIMITER ;

-- ============================================================
-- 3. PROCEDIMIENTOS ALMACENADOS ORIGINALES
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
-- 4. TRIGGERS ORIGINALES
-- ============================================================

DELIMITER $$

CREATE TRIGGER trg_cerrar_juntada_llena
AFTER INSERT ON miembros_juntada
FOR EACH ROW
BEGIN
    IF juntada_tiene_cupo(NEW.id_juntada) = 0 THEN
        UPDATE juntadas
        SET estado = 'Cerrada'
        WHERE id_juntada = NEW.id_juntada;
    END IF;
END$$

CREATE TRIGGER trg_hito_nuevo_miembro
AFTER INSERT ON miembros_juntada
FOR EACH ROW
BEGIN
    INSERT INTO hitos_transaccionales (id_juntada, id_usuario, tipo_evento, descripcion)
    VALUES (NEW.id_juntada, NEW.id_usuario, 'MiembroUnido', 'El usuario se unio a la juntada.');
END$$

CREATE TRIGGER trg_evitar_juntada_partido_pasado
BEFORE INSERT ON juntadas
FOR EACH ROW
BEGIN
    DECLARE v_fecha TIMESTAMP;
    SELECT fecha_partido INTO v_fecha FROM partidos WHERE id_partido = NEW.id_partido;
    IF v_fecha < NOW() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se puede crear una juntada para un partido que ya se jugo.';
    END IF;
END$$

CREATE TRIGGER trg_proteger_organizador
BEFORE DELETE ON miembros_juntada
FOR EACH ROW
BEGIN
    IF OLD.estado_logistico = 'Organizador' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El organizador no puede abandonar su propia juntada.';
    END IF;
END$$

-- NUEVO: espejo de trg_cerrar_juntada_llena pero para la baja de
-- miembros (funcionalidad "salir de la juntada"). Si alguien se va
-- y la juntada estaba 'Cerrada' por cupo lleno, se reabre sola en
-- cuanto vuelve a haber lugar. Si el DELETE ocurre porque la
-- juntada ENTERA se esta borrando (CASCADE de eliminar.php), el
-- UPDATE de abajo simplemente no encuentra la fila (ya no existe)
-- y no hace nada: no rompe ni duplica nada en ese caso.
CREATE TRIGGER trg_reabrir_juntada_con_cupo
AFTER DELETE ON miembros_juntada
FOR EACH ROW
BEGIN
    IF juntada_tiene_cupo(OLD.id_juntada) = 1 THEN
        UPDATE juntadas
        SET estado = 'Abierta'
        WHERE id_juntada = OLD.id_juntada AND estado = 'Cerrada';
    END IF;
END$$

DELIMITER ;

-- ============================================================
-- 5. DATOS DE PRUEBA
-- ============================================================

INSERT INTO equipos (nombre_club, estadio) VALUES
('Aldosivi',                  'Jose Maria Minella'),
('Argentinos Juniors',        'Diego Armando Maradona'),
('Atletico Tucuman',          'Monumental Jose Fierro'),
('Banfield',                  'Florencio Sola'),
('Barracas Central',          'Claudio Chiqui Tapia'),
('Belgrano',                  'Julio Cesar Villagra'),
('Boca Juniors',              'La Bombonera'),
('Central Cordoba (SdE)',     'Unico Madre de Ciudades'),
('Defensa y Justicia',        'Norberto Tito Tomaghello'),
('Deportivo Riestra',         'Guillermo Laza'),
('Estudiantes (LP)',          'Jorge Luis Hirschi'),
('Estudiantes (RC)',          'Ciudad de Rio Cuarto Antonio Candini'),
('Gimnasia y Esgrima (LP)',   'Juan Carmelo Zerillo'),
('Gimnasia y Esgrima (M)',    'Victor Legrotaglie'),
('Huracan',                   'Tomas Adolfo Duco'),
('Independiente',             'Libertadores de America'),
('Independiente Rivadavia',   'Bautista Gargantini'),
('Instituto',                 'Juan Domingo Peron'),
('Lanus',                     'Ciudad de Lanus - Nestor Diaz Perez'),
('Newells Old Boys',          'Marcelo Bielsa'),
('Platense',                  'Ciudad de Vicente Lopez'),
('Racing Club',               'El Cilindro'),
('River Plate',               'Mas Monumental'),
('Rosario Central',           'Gigante de Arroyito'),
('San Lorenzo',               'Pedro Bidegain'),
('Sarmiento (J)',             'Eva Peron'),
('Talleres (C)',              'Mario Alberto Kempes'),
('Tigre',                     'Jose Dellagiovanna'),
('Union',                     '15 de Abril'),
('Velez Sarsfield',           'Jose Amalfitani');

-- Martin Gonzalez (usuario 1) queda como 'admin' de entrada para
-- poder probar la moderacion apenas se importa la base. El resto
-- queda como 'user' comun.
INSERT INTO usuarios (dni, nombre, email, password_hash, id_equipo, estado, rol) VALUES
('40123456', 'Martin Gonzalez',   'martin.gonzalez@mail.com',   '$2y$10$WqzL9d8YV1J8dV3S1H5t0.hOe7Kk3n1lU2m4Zb6Yq8Rr0Ss2Tt4Uu', 7,  'Activo', 'admin'),
('38987654', 'Lucia Fernandez',   'lucia.fernandez@mail.com',   '$2y$10$WqzL9d8YV1J8dV3S1H5t0.hOe7Kk3n1lU2m4Zb6Yq8Rr0Ss2Tt4Uu', 23, 'Activo', 'user'),
('42345678', 'Pablo Rodriguez',   'pablo.rodriguez@mail.com',   '$2y$10$WqzL9d8YV1J8dV3S1H5t0.hOe7Kk3n1lU2m4Zb6Yq8Rr0Ss2Tt4Uu', 22, 'Activo', 'user'),
('39567890', 'Camila Lopez',      'camila.lopez@mail.com',      '$2y$10$WqzL9d8YV1J8dV3S1H5t0.hOe7Kk3n1lU2m4Zb6Yq8Rr0Ss2Tt4Uu', 16, 'Activo', 'user'),
('41234567', 'Mateo Garcia',      'mateo.garcia@mail.com',      '$2y$10$WqzL9d8YV1J8dV3S1H5t0.hOe7Kk3n1lU2m4Zb6Yq8Rr0Ss2Tt4Uu', 25, 'Activo', 'user'),
('37890123', 'Valentina Martinez','valentina.martinez@mail.com','$2y$10$WqzL9d8YV1J8dV3S1H5t0.hOe7Kk3n1lU2m4Zb6Yq8Rr0Ss2Tt4Uu', 30, 'Activo', 'user'),
('43456789', 'Santiago Perez',    'santiago.perez@mail.com',    '$2y$10$WqzL9d8YV1J8dV3S1H5t0.hOe7Kk3n1lU2m4Zb6Yq8Rr0Ss2Tt4Uu', 11, 'Activo', 'user'),
('40567891', 'Isabela Romero',    'isabela.romero@mail.com',    '$2y$10$WqzL9d8YV1J8dV3S1H5t0.hOe7Kk3n1lU2m4Zb6Yq8Rr0Ss2Tt4Uu', 13, 'Activo', 'user'),
('38678912', 'Dylan Torres',      'dylan.torres@mail.com',      '$2y$10$WqzL9d8YV1J8dV3S1H5t0.hOe7Kk3n1lU2m4Zb6Yq8Rr0Ss2Tt4Uu', 15, 'Activo', 'user'),
('41789012', 'Sofia Diaz',        'sofia.diaz@mail.com',        '$2y$10$WqzL9d8YV1J8dV3S1H5t0.hOe7Kk3n1lU2m4Zb6Yq8Rr0Ss2Tt4Uu', 27, 'Activo', 'user'),
('39890123', 'Nicolas Sanchez',   'nicolas.sanchez@mail.com',   '$2y$10$WqzL9d8YV1J8dV3S1H5t0.hOe7Kk3n1lU2m4Zb6Yq8Rr0Ss2Tt4Uu', 24, 'Activo', 'user'),
('42901234', 'Julieta Morales',   'julieta.morales@mail.com',   '$2y$10$WqzL9d8YV1J8dV3S1H5t0.hOe7Kk3n1lU2m4Zb6Yq8Rr0Ss2Tt4Uu', 29, 'Activo', 'user');

INSERT INTO partidos (id_equipo_local, id_equipo_visitante, fecha_partido, estadio_sede) VALUES
(7,  23, '2026-10-10 18:00:00', 'La Bombonera'),
(22, 16, '2026-10-11 20:30:00', 'El Cilindro'),
(25, 30, '2026-10-15 19:00:00', 'Pedro Bidegain'),
(11, 13, '2026-10-17 16:00:00', 'Jorge Luis Hirschi'),
(15, 5,  '2026-10-20 18:30:00', 'Tomas Adolfo Duco'),
(29, 3,  '2026-10-22 20:00:00', '15 de Abril'),
(23, 22, '2026-10-25 21:00:00', 'Mas Monumental'),
(30, 7,  '2026-10-28 19:30:00', 'Jose Amalfitani'),
(16, 25, '2026-11-01 18:00:00', 'Libertadores de America'),
(13, 15, '2026-11-03 20:00:00', 'Juan Carmelo Zerillo'),
(24, 29, '2026-11-05 17:00:00', 'Gigante de Arroyito'),
(27, 11, '2026-11-08 21:30:00', 'Mario Alberto Kempes');

INSERT INTO foros_debate (nombre_foro, descripcion, tipo, id_equipo, categoria_general, id_usuario_creador) VALUES
('Foro Boca Juniors',              'Debate abierto sobre la actualidad del Club Boca Juniors', 'Club', 7,  NULL, 1),
('Refuerzos que necesita Boca',    'Que jugadores deberia sumar el club para octubre',         'Club', 7,  NULL, 1),
('Foro River Plate',               'Espacio de discusion para los hinchas de River Plate',     'Club', 23, NULL, 2),
('Foro Racing Club',               'Debate sobre Racing y su campeonato',                       'Club', 22, NULL, 3),
('Foro Independiente',             'El Rojo tiene mucho que decir: unite al debate',            'Club', 16, NULL, 4),
('Independiente en la Copa',       'Analisis del camino en los torneos internacionales',        'Club', 16, NULL, 4),
('Foro San Lorenzo',               'La voz del Cuervo en la comunidad HINCHA+',                 'Club', 25, NULL, 5),
('Foro Velez Sarsfield',           'Debate sobre Velez y sus futuras figuras',                  'Club', 30, NULL, 6),
('Foro Estudiantes LP',            'El Pincha se debate aqui',                                  'Club', 11, NULL, 7),
('Foro Gimnasia LP',               'El Lobo de La Plata tiene su espacio de opinion',           'Club', 13, NULL, 8),
('Seleccion Argentina: convocatoria', 'Debate sobre los citados para la proxima fecha FIFA',   'General', NULL, 'Seleccion Argentina',    9),
('Mercado de pases: rumores',      'Todo lo que se dice sobre pases en el futbol argentino',    'General', NULL, 'Mercado de Pases',       10),
('Futbol internacional: Champions','Analisis de la fase de grupos europea',                     'General', NULL, 'Futbol Internacional',   11),
('Debates generales del futbol',   'Charla libre sobre cualquier tema futbolero',               'General', NULL, 'Debates Generales',      12);

INSERT INTO juntadas (id_organizador, id_partido, nombre, punto_encuentro_lat, punto_encuentro_lng, descripcion_punto, cupo_maximo, estado) VALUES
(1,  1,  'Banderazo en La 12',            -34.6357000, -58.3649000, 'Bar La 12 - Esquina de Brandsen y Warnes',              30, 'Abierta'),
(2,  1,  'Previa en el subte',            -34.6400000, -58.3610000, 'Estacion de subte La Boca',                              20, 'Abierta'),
(3,  2,  'Previa Racing',                 -34.5407000, -58.4498000, 'Bar Racing - Avenida Mitre 5550',                        25, 'Abierta'),
(4,  2,  'Juntada Avellaneda',            -34.5389000, -58.4512000, 'Plaza San Martin de Avellaneda',                         40, 'Abierta'),
(5,  3,  'MundoLeon previa',              -34.6292000, -58.3725000, 'MundoLeon - Avenida Juan B. Justo 9500',                 15, 'Abierta'),
(6,  4,  'Cerveceria El Pincha',          -34.9108000, -57.9521000, 'Cerveceria El Pincha - Calle 7 entre 51 y 53',          35, 'Abierta'),
(7,  5,  'Sede Social Huracan',           -34.5794000, -58.4172000, 'Sede Social Huracan - Avenida Gavilan 780',              20, 'Abierta'),
(8,  6,  'Previa en Bar Union',           -34.5833000, -60.9536000, 'Bar Union - Avenida Colon 3200',                         18, 'Abierta'),
(9,  7,  'Bar Monumental',                -34.5440000, -58.4425000, 'Bar Monumental - Calle Emilio Fabiani',                  50, 'Abierta'),
(10, 8,  'Previa Amalfitani',             -34.6280000, -58.5623000, 'Estadio Jose Amalfitani - Lado Este',                    25, 'Abierta'),
(11, 9,  'Bajo Autodromo',                -34.6642000, -58.3629000, 'Bajo Autodromo - Lateral Libertador',                    30, 'Abierta'),
(12, 10, 'Plaza Moreno',                  -34.9133000, -57.9497000, 'Plaza Moreno - Centro de La Plata',                      22, 'Cerrada');

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

INSERT INTO mensajes_chat (id_usuario, id_foro, id_juntada, contenido_texto) VALUES
(1,  1,  NULL, 'Boca viene bien este semestre, que opinan?'),
(2,  1,  NULL, 'Coincido, el equipo esta creciendo mucho'),
(3,  3,  NULL, 'River no baja el nivel, grande el Millonario'),
(4,  4,  NULL, 'Para mi Racing esta mejor que River este ano'),
(5,  7,  NULL, 'San Lorenzo tiene que apuntar al repechaje'),
(6,  8,  NULL, 'Velez esta forming buenos juveniles'),
(9,  11, NULL, 'Vieron la lista de convocados de la Seleccion?'),
(10, 12, NULL, 'Dicen que hay novedades para el libro de pases'),
(1,  NULL, 1,  'Hola gente, me acerco por el Bar La 12'),
(2,  NULL, 1,  'Perfecto, llego a las 17:30'),
(3,  NULL, 1,  'Ya estoy en la esquina, los espero'),
(5,  NULL, 3,  'Racing dale campeon! Nos vemos en el bar'),
(7,  NULL, 6,  'El Pincha esta pasando por un buen momento'),
(8,  NULL, 6,  'Siii, hay que bancar al equipo');

-- ============================================================
-- 6. VERIFICACION DE INTEGRIDAD
-- ============================================================

SELECT 'equipos' AS tabla, COUNT(*) AS total FROM equipos
UNION ALL SELECT 'usuarios',              COUNT(*) FROM usuarios
UNION ALL SELECT 'partidos',              COUNT(*) FROM partidos
UNION ALL SELECT 'foros_debate',          COUNT(*) FROM foros_debate
UNION ALL SELECT 'juntadas',              COUNT(*) FROM juntadas
UNION ALL SELECT 'miembros_juntada',      COUNT(*) FROM miembros_juntada
UNION ALL SELECT 'mensajes_chat',         COUNT(*) FROM mensajes_chat
UNION ALL SELECT 'hitos_transaccionales', COUNT(*) FROM hitos_transaccionales;

-- Probar funciones agregadas
SELECT contar_miembros_juntada(1) AS miembros_juntada_1;
SELECT juntada_tiene_cupo(1) AS juntada_1_tiene_cupo;