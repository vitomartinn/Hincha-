<?php
// 1. Cabeceras CORS obligatorias (DEBEN IR AL PRINCIPIO)
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS, PUT, DELETE");
header("Content-Type: application/json; charset=UTF-8");

// 2. Responder con exito a la peticion Preflight (OPTIONS) de React
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/../conexion.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respuestaJSON(['error' => 'Metodo no permitido'], 405);
}

$datos = obtenerJSON();

$idOrganizador  = intval($datos['id_organizador']       ?? 0);
$idPartido      = intval($datos['id_partido']           ?? 0);
$nombre         = trim($datos['nombre']                 ?? '');
$lat            = floatval($datos['punto_encuentro_lat'] ?? 0);
$lng            = floatval($datos['punto_encuentro_lng'] ?? 0);
$descripcion    = trim($datos['descripcion_punto']      ?? '');
$cupoMaximo     = intval($datos['cupo_maximo']          ?? 0);

if ($nombre === '' || $idOrganizador === 0 || $idPartido === 0 || $cupoMaximo <= 0) {
    respuestaJSON(['error' => 'El nombre, organizador, partido y cupo maximo son obligatorios'], 400);
}

if ($lat < -90 || $lat > 90 || $lng < -180 || $lng > 180) {
    respuestaJSON(['error' => 'Coordenadas geograficas invalidas'], 400);
}

// Regla de negocio: no se puede crear una juntada para un partido que ya se jugo.
$stmtPartido = $conexion->prepare('SELECT fecha_partido FROM partidos WHERE id_partido = :id_partido');
$stmtPartido->execute(['id_partido' => $idPartido]);
$partido = $stmtPartido->fetch();

if (!$partido) {
    respuestaJSON(['error' => 'El partido indicado no existe'], 404);
}

if (strtotime($partido['fecha_partido']) < time()) {
    respuestaJSON(['error' => 'No se puede crear una juntada para un partido que ya se jugo'], 400);
}

try {
    $conexion->beginTransaction();

    $stmt = $conexion->prepare(
        'INSERT INTO juntadas (id_organizador, id_partido, nombre, punto_encuentro_lat, punto_encuentro_lng, descripcion_punto, cupo_maximo)
         VALUES (:id_organizador, :id_partido, :nombre, :lat, :lng, :descripcion, :cupo_maximo)'
    );
    $stmt->execute([
        'id_organizador' => $idOrganizador,
        'id_partido'     => $idPartido,
        'nombre'         => $nombre,
        'lat'            => $lat,
        'lng'            => $lng,
        'descripcion'    => $descripcion,
        'cupo_maximo'    => $cupoMaximo,
    ]);
    $idJuntada = $conexion->lastInsertId();

    // El organizador queda como primer miembro de su propia juntada.
    $stmtMiembro = $conexion->prepare(
        "INSERT INTO miembros_juntada (id_usuario, id_juntada, estado_logistico) VALUES (:id_usuario, :id_juntada, 'Organizador')"
    );
    $stmtMiembro->execute(['id_usuario' => $idOrganizador, 'id_juntada' => $idJuntada]);

    // Hito de bitacora
    $stmtHito = $conexion->prepare(
        "INSERT INTO hitos_transaccionales (id_juntada, id_usuario, tipo_evento, descripcion)
         VALUES (:id_juntada, :id_usuario, 'JuntadaCreada', 'Se creo la juntada.')"
    );
    $stmtHito->execute(['id_juntada' => $idJuntada, 'id_usuario' => $idOrganizador]);

    $conexion->commit();

    respuestaJSON([
        'mensaje'    => 'Juntada creada exitosamente',
        'id_juntada' => $idJuntada,
    ], 201);
} catch (PDOException $e) {
    $conexion->rollBack();
    respuestaJSON(['error' => 'Error al crear la juntada'], 500);
}