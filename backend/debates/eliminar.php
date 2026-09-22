<?php
/**
 * POST /debates/eliminar.php
 * Body: { id_foro, id_usuario }
 * -----------------------------------------------------------
 * Elimina un foro de debate (hilo) completo. A diferencia de
 * juntadas/eliminar.php, ESTO ES SOLO PARA ADMIN: el creador de
 * un foro no tiene, por consigna, permiso para borrarlo el mismo
 * (a diferencia del organizador de una juntada). Es moderacion
 * pura de contenido no deseado.
 *
 * Al borrar el foro, la FK de mensajes_chat.id_foro (ON DELETE
 * CASCADE, ya definida en el esquema original) borra en cadena
 * todos los mensajes de ese hilo.
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

$idForo    = intval($datos['id_foro'] ?? 0);
$idUsuario = intval($datos['id_usuario'] ?? 0);

if ($idForo === 0 || $idUsuario === 0) {
    respuestaJSON(['error' => 'id_foro e id_usuario son obligatorios'], 400);
}

if (!esAdmin($conexion, $idUsuario)) {
    respuestaJSON(['error' => 'Solo un administrador puede eliminar un foro de debate'], 403);
}

$stmt = $conexion->prepare('SELECT id_foro FROM foros_debate WHERE id_foro = :id_foro');
$stmt->execute(['id_foro' => $idForo]);
if (!$stmt->fetch()) {
    respuestaJSON(['error' => 'El foro de debate no existe'], 404);
}

try {
    $stmtDelete = $conexion->prepare('DELETE FROM foros_debate WHERE id_foro = :id_foro');
    $stmtDelete->execute(['id_foro' => $idForo]);

    respuestaJSON(['mensaje' => 'Foro de debate eliminado correctamente'], 200);
} catch (PDOException $e) {
    respuestaJSON(['error' => 'Error al eliminar el foro de debate'], 500);
}
