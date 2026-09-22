<?php
/**
 * POST /juntadas/salir.php
 * Body: { id_juntada, id_usuario }
 * -----------------------------------------------------------
 * Da de baja al usuario de una juntada a la que se habia unido.
 *
 * El organizador NO puede salir por esta via (tiene que cancelar
 * la juntada entera con juntadas/eliminar.php). Esto se valida
 * aca en PHP para devolver un mensaje claro, pero el trigger
 * trg_proteger_organizador de la base es quien realmente lo
 * garantiza pase lo que pase (aunque alguien pegue directo a la
 * base sin pasar por este endpoint).
 *
 * El contador de asistentes no hay que "actualizarlo" a mano en
 * ningun lado: total_miembros siempre se calcula al vuelo con un
 * COUNT(*) sobre miembros_juntada (ver juntadas/listar.php y
 * obtener.php), asi que borrar esta fila ya alcanza.
 *
 * Si la juntada estaba 'Cerrada' por cupo lleno, el trigger
 * trg_reabrir_juntada_con_cupo la reabre solo en cuanto detecta
 * que con esta baja volvio a haber lugar.
 * -----------------------------------------------------------
 */

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS, PUT, DELETE");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/../conexion.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respuestaJSON(['error' => 'Metodo no permitido'], 405);
}

$datos = obtenerJSON();

$idJuntada = intval($datos['id_juntada'] ?? 0);
$idUsuario = intval($datos['id_usuario'] ?? 0);

if ($idJuntada === 0 || $idUsuario === 0) {
    respuestaJSON(['error' => 'id_juntada e id_usuario son obligatorios'], 400);
}

$stmt = $conexion->prepare(
    'SELECT estado_logistico FROM miembros_juntada
     WHERE id_usuario = :id_usuario AND id_juntada = :id_juntada'
);
$stmt->execute(['id_usuario' => $idUsuario, 'id_juntada' => $idJuntada]);
$miembro = $stmt->fetch();

if (!$miembro) {
    respuestaJSON(['error' => 'No estas unido a esta juntada'], 404);
}

if ($miembro['estado_logistico'] === 'Organizador') {
    respuestaJSON([
        'error' => 'El organizador no puede abandonar su propia juntada. Si queres darla de baja, usa la opcion de eliminar juntada.',
    ], 400);
}

try {
    $conexion->beginTransaction();

    // El hito de la baja se inserta ACA, explicitamente, en vez de
    // via un trigger AFTER DELETE generico: un trigger asi tambien
    // se dispararia cuando esta misma fila se borra en cascada
    // porque la juntada ENTERA se elimino (juntadas/eliminar.php),
    // generando un hito "MiembroSalio" enganoso para ese caso. Al
    // hacerlo desde PHP, el hito solo se registra cuando es
    // realmente un abandono explicito y voluntario.
    $stmtHito = $conexion->prepare(
        "INSERT INTO hitos_transaccionales (id_juntada, id_usuario, tipo_evento, descripcion)
         VALUES (:id_juntada, :id_usuario, 'MiembroSalio', 'El usuario abandono la juntada.')"
    );
    $stmtHito->execute(['id_juntada' => $idJuntada, 'id_usuario' => $idUsuario]);

    $stmtDelete = $conexion->prepare(
        'DELETE FROM miembros_juntada WHERE id_usuario = :id_usuario AND id_juntada = :id_juntada'
    );
    $stmtDelete->execute(['id_usuario' => $idUsuario, 'id_juntada' => $idJuntada]);

    $conexion->commit();

    respuestaJSON(['mensaje' => 'Abandonaste la juntada correctamente'], 200);
} catch (PDOException $e) {
    $conexion->rollBack();
    // Si por algun motivo esto lo terminara bloqueando el trigger
    // trg_proteger_organizador (defensa de ultima linea), llega
    // como un error de SQL con este mensaje.
    if (strpos($e->getMessage(), 'no puede abandonar') !== false) {
        respuestaJSON(['error' => 'El organizador no puede abandonar su propia juntada.'], 400);
    }
    respuestaJSON(['error' => 'Error al salir de la juntada'], 500);
}
