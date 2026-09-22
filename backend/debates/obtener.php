<?php
/**
 * GET /debates/obtener.php?id=ID
 * -----------------------------------------------------------
 * Devuelve los datos de UN foro de debate puntual. Hacia falta
 * para que el chat de debates (Chat.js con tipo="debate") tenga
 * de donde sacar el nombre del foro, su descripcion, etc, en
 * vez de tratar todo como si fuera una juntada.
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

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    respuestaJSON(['error' => 'Metodo no permitido'], 405);
}

$idForo = intval($_GET['id'] ?? 0);

if ($idForo === 0) {
    respuestaJSON(['error' => 'El parametro id es obligatorio'], 400);
}

$stmt = $conexion->prepare(
    'SELECT f.id_foro, f.nombre_foro, f.descripcion, f.tipo,
            e.id_equipo, e.nombre_club, e.estadio,
            f.categoria_general, f.id_usuario_creador,
            u.nombre AS nombre_creador,
            (SELECT COUNT(*) FROM mensajes_chat m WHERE m.id_foro = f.id_foro) AS total_mensajes
     FROM foros_debate f
     LEFT JOIN equipos e ON e.id_equipo = f.id_equipo
     JOIN usuarios u ON u.id_usuario = f.id_usuario_creador
     WHERE f.id_foro = :id_foro'
);
$stmt->execute(['id_foro' => $idForo]);
$foro = $stmt->fetch();

if (!$foro) {
    respuestaJSON(['error' => 'El foro de debate no existe'], 404);
}

respuestaJSON(['foro' => $foro], 200);
