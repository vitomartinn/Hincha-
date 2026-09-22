<?php
/**
 * GET /juntadas/obtener.php?id=ID
 * -----------------------------------------------------------
 * Devuelve los datos de UNA juntada puntual. Este endpoint no
 * existia y era necesario: el chat de juntadas (Chat.js) lo
 * usa para mostrar el encabezado (nombre, punto de encuentro,
 * cupo, etc). Al faltar, esa pantalla se quedaba "vacia" con
 * apariencia de chat pero sin datos reales cargados.
 * -----------------------------------------------------------
 */

// Cabeceras CORS obligatorias (mismo patron que el resto de /juntadas)
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

$idJuntada = intval($_GET['id'] ?? 0);

if ($idJuntada === 0) {
    respuestaJSON(['error' => 'El parametro id es obligatorio'], 400);
}

$stmt = $conexion->prepare(
    'SELECT j.id_juntada, j.nombre, j.id_organizador, j.punto_encuentro_lat, j.punto_encuentro_lng,
            j.descripcion_punto, j.cupo_maximo, j.estado, j.creado_at,
            u.nombre AS nombre_organizador,
            p.id_partido, p.fecha_partido, p.estadio_sede,
            el.nombre_club AS club_local,
            ev.nombre_club AS club_visitante,
            (SELECT COUNT(*) FROM miembros_juntada mj WHERE mj.id_juntada = j.id_juntada) AS total_miembros
     FROM juntadas j
     JOIN usuarios u   ON u.id_usuario = j.id_organizador
     JOIN partidos p   ON p.id_partido = j.id_partido
     JOIN equipos el   ON el.id_equipo = p.id_equipo_local
     JOIN equipos ev   ON ev.id_equipo = p.id_equipo_visitante
     WHERE j.id_juntada = :id_juntada'
);
$stmt->execute(['id_juntada' => $idJuntada]);
$juntada = $stmt->fetch();

if (!$juntada) {
    respuestaJSON(['error' => 'La juntada no existe'], 404);
}

respuestaJSON(['juntada' => $juntada], 200);
