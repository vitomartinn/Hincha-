<?php
/**
 * POST /juntadas/eliminar.php
 * Body: { id_juntada, id_usuario }
 * -----------------------------------------------------------
 * Elimina una juntada por completo. Solo puede hacerlo:
 *   - el organizador de esa juntada puntual (id_usuario == id_organizador), o
 *   - un usuario con rol = 'admin' (moderacion, puede borrar
 *     CUALQUIER juntada, no solo las propias).
 *
 * El permiso se valida siempre contra la base (obtenerRolUsuario),
 * nunca contra un campo "rol" que venga en el body del request.
 *
 * Al borrar la juntada, MySQL se encarga solo (via las FK con
 * ON DELETE CASCADE ya definidas en el esquema) de limpiar:
 *   - sus filas en miembros_juntada
 *   - sus mensajes en mensajes_chat
 * y deja NULL el id_juntada de sus hitos_transaccionales en vez
 * de borrarlos (ON DELETE SET NULL), para que el historial de
 * auditoria sobreviva a la eliminacion.
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

$stmt = $conexion->prepare('SELECT id_organizador, nombre FROM juntadas WHERE id_juntada = :id_juntada');
$stmt->execute(['id_juntada' => $idJuntada]);
$juntada = $stmt->fetch();

if (!$juntada) {
    respuestaJSON(['error' => 'La juntada no existe'], 404);
}

$esOrganizador = intval($juntada['id_organizador']) === $idUsuario;
$esAdministrador = esAdmin($conexion, $idUsuario);

if (!$esOrganizador && !$esAdministrador) {
    respuestaJSON(['error' => 'No tenes permiso para eliminar esta juntada'], 403);
}

try {
    $conexion->beginTransaction();

    // Se deja constancia en el historial ANTES de borrar (mientras
    // la juntada todavia existe, para que la fila cumpla la FK).
    // Despues del DELETE, esta misma fila queda con id_juntada en
    // NULL (ON DELETE SET NULL) pero el resto de los datos persiste.
    $motivo = $esAdministrador && !$esOrganizador ? 'un administrador' : 'el organizador';
    $stmtHito = $conexion->prepare(
        "INSERT INTO hitos_transaccionales (id_juntada, id_usuario, tipo_evento, descripcion)
         VALUES (:id_juntada, :id_usuario, 'JuntadaEliminada', :descripcion)"
    );
    $stmtHito->execute([
        'id_juntada'  => $idJuntada,
        'id_usuario'  => $idUsuario,
        'descripcion' => "La juntada \"{$juntada['nombre']}\" fue eliminada por {$motivo}.",
    ]);

    $stmtDelete = $conexion->prepare('DELETE FROM juntadas WHERE id_juntada = :id_juntada');
    $stmtDelete->execute(['id_juntada' => $idJuntada]);

    $conexion->commit();

    respuestaJSON(['mensaje' => 'Juntada eliminada correctamente'], 200);
} catch (PDOException $e) {
    $conexion->rollBack();
    respuestaJSON(['error' => 'Error al eliminar la juntada'], 500);
}
