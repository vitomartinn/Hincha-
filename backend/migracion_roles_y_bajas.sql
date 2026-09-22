-- ============================================================
-- MIGRACION: roles (admin/user) + salir de juntada + eliminar
-- ------------------------------------------------------------
-- Usar esto SOLO si ya tenes la base hincha_plus creada y con
-- datos que no queres perder. Si preferis, tambien podes correr
-- el hincha_plus.sql completo de nuevo (borra y recrea todo).
-- ============================================================

USE hincha_plus;

-- 1) Reutilizar la columna 'rol' como el campo de permisos.
--    Si tu tabla ya tenia usuarios con 'Hincha_Comun', los pasamos
--    todos a 'user' antes de aplicar el CHECK, para que no rompa.
UPDATE usuarios SET rol = 'user' WHERE rol NOT IN ('admin', 'user');

ALTER TABLE usuarios
  MODIFY COLUMN rol VARCHAR(20) NOT NULL DEFAULT 'user';

ALTER TABLE usuarios
  ADD CONSTRAINT chk_usuarios_rol CHECK (rol IN ('admin', 'user'));

-- Promove a admin al usuario que quieras probar (cambia el email):
-- UPDATE usuarios SET rol = 'admin' WHERE email = 'martin.gonzalez@mail.com';

-- 2) hitos_transaccionales.id_juntada pasa a ser NULL-able con
--    ON DELETE SET NULL (antes era NOT NULL + CASCADE), para que
--    el historial sobreviva a la eliminacion de una juntada.
--    Hay que borrar la FK vieja, modificar la columna, y crear la
--    FK nueva. El nombre de la constraint puede variar segun como
--    la haya nombrado tu motor; si el ALTER de abajo falla por
--    nombre, mira el nombre real con:
--    SHOW CREATE TABLE hitos_transaccionales;
ALTER TABLE hitos_transaccionales
  DROP FOREIGN KEY hitos_transaccionales_ibfk_1;

ALTER TABLE hitos_transaccionales
  MODIFY COLUMN id_juntada INT NULL;

ALTER TABLE hitos_transaccionales
  ADD CONSTRAINT fk_hitos_juntada
  FOREIGN KEY (id_juntada) REFERENCES juntadas(id_juntada)
  ON DELETE SET NULL ON UPDATE CASCADE;

-- 3) Reemplazar juntada_tiene_cupo() por la version corregida
--    (la anterior calculaba mal el cupo cuando una juntada se
--    queda sin ningun miembro, algo que ahora puede pasar con
--    la nueva funcionalidad de "salir de la juntada").
DROP FUNCTION IF EXISTS juntada_tiene_cupo;

DELIMITER $$

CREATE FUNCTION juntada_tiene_cupo(p_id_juntada INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
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

-- 4) Nuevo trigger: reabre una juntada 'Cerrada' cuando alguien
--    se va y vuelve a haber cupo.
DROP TRIGGER IF EXISTS trg_reabrir_juntada_con_cupo;

DELIMITER $$

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
