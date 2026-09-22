<?php
require_once __DIR__ . '/../conexion.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    respuestaJSON(['error' => 'Metodo no permitido'], 405);
}

$idJuntada = isset($_GET['id_juntada']) ? intval($_GET['id_juntada']) : 0;
$idForo    = isset($_GET['id_foro'])    ? intval($_GET['id_foro'])    : 0;

if ($idJuntada === 0 && $idForo === 0) {
    respuestaJSON(['error' => 'Se requiere id_juntada o id_foro como parametro'], 400);
}

if ($idJuntada > 0 && $idForo > 0) {
    respuestaJSON(['error' => 'No se puede consultar ambos a la vez'], 400);
}

// Antes el historial de la juntada se pedia con "CALL historial_chat_juntada(?)"
// (un procedimiento almacenado) y el del foro con una consulta aparte.
// Ahora es la misma consulta simple para los dos casos, solo cambia
// el WHERE, para que se pueda leer y explicar en un solo lugar.
$columna = $idJuntada > 0 ? 'm.id_juntada' : 'm.id_foro';
$valor   = $idJuntada > 0 ? $idJuntada     : $idForo;
$tipo    = $idJuntada > 0 ? 'juntada'      : 'foro';

$stmt = $conexion->prepare(
    "SELECT m.id_mensaje, m.id_usuario, u.nombre AS nombre_usuario,
            m.contenido_texto, m.enviado_at
     FROM mensajes_chat m
     JOIN usuarios u ON u.id_usuario = m.id_usuario
     WHERE {$columna} = :valor
     ORDER BY m.enviado_at ASC"
);
$stmt->execute(['valor' => $valor]);
$mensajes = $stmt->fetchAll();

respuestaJSON(['mensajes' => $mensajes, 'tipo' => $tipo], 200);
