-- ============================================================
-- MIGRACION: agrega la columna faltante `nombre` a `juntadas`
-- ------------------------------------------------------------
-- Usar esto SOLO si ya tenes la base de datos hincha_plus
-- creada y con datos que no queres perder.
-- Si preferis, tambien podes correr el hincha_plus.sql
-- completo de nuevo (eso borra y recrea todo desde cero).
--
-- Por que hace falta: el codigo de crear.php, listar.php,
-- mis_juntadas.php y el frontend ya leen/escriben una columna
-- `nombre` en `juntadas`, pero esa columna nunca se creo en la
-- base de datos. Por eso listar.php tiraba error de SQL
-- ("Unknown column j.nombre") y las juntadas no cargaban bien.
-- ============================================================

USE hincha_plus;

ALTER TABLE juntadas
  ADD COLUMN nombre VARCHAR(150) NOT NULL DEFAULT '' AFTER id_partido;

-- Si ya tenias juntadas cargadas sin nombre, les pone uno por
-- defecto en base al punto de encuentro, para que no queden en blanco.
UPDATE juntadas
SET nombre = CONCAT('Juntada en ', descripcion_punto)
WHERE nombre = '' AND descripcion_punto IS NOT NULL AND descripcion_punto <> '';

UPDATE juntadas
SET nombre = CONCAT('Juntada #', id_juntada)
WHERE nombre = '';
