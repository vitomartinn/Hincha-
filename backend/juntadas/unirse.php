<?php
// Cabeceras CORS obligatorias
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS, PUT, DELETE");
header("Content-Type: application/json; charset=UTF-8");

// Manejo de Preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/../conexion.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respuestaJSON(['error' => 'Metodo no permitido'], 405);
}

$datos = obtenerJSON();

$idUsuario = intval($datos['id_usuario'] ?? 0);
$idJuntada = intval($datos['id_juntada'] ?? 0);

if ($idUsuario === 0 || $idJuntada === 0) {
    respuestaJSON(['error' => 'id_usuario e id_juntada son obligatorios'], 400);
}

$stmtJuntada = $conexion->prepare('SELECT estado, cupo_maximo FROM juntadas WHERE id_juntada = :id_juntada');
$stmtJuntada->execute(['id_juntada' => $idJuntada]);
$juntada = $stmtJuntada->fetch();

if (!$juntada) {
    respuestaJSON(['error' => 'La juntada no existe'], 404);
}

if ($juntada['estado'] !== 'Abierta') {
    respuestaJSON(['error' => 'La juntada ya no se encuentra abierta'], 400);
}

$stmtCount = $conexion->prepare('SELECT COUNT(*) AS total FROM miembros_juntada WHERE id_juntada = :id_juntada');
$stmtCount->execute(['id_juntada' => $idJuntada]);
$totalActual = (int) $stmtCount->fetch()['total'];

if ($totalActual >= $juntada['cupo_maximo']) {
    respuestaJSON(['error' => 'La juntada ha alcanzado su cupo maximo'], 400);
}

try {
    $conexion->beginTransaction();

    // OJO: no insertamos el hito 'MiembroUnido' ni cerramos la
    // juntada aca a mano. Los triggers trg_hito_nuevo_miembro y
    // trg_cerrar_juntada_llena de hincha_plus.sql ya se disparan
    // solos, automaticamente, sobre este mismo INSERT en
    // miembros_juntada (AFTER INSERT ON miembros_juntada). Si
    // tambien lo haciamos aca desde PHP, quedaba duplicado: dos
    // filas de hito por cada union y dos UPDATE innecesarios.
    $stmt = $conexion->prepare(
        "INSERT INTO miembros_juntada (id_usuario, id_juntada, estado_logistico) VALUES (:id_usuario, :id_juntada, 'Pendiente')"
    );
    $stmt->execute(['id_usuario' => $idUsuario, 'id_juntada' => $idJuntada]);
    $idMiembro = $conexion->lastInsertId();

    $conexion->commit();

    respuestaJSON([
        'mensaje'    => 'Te has unido a la juntada correctamente',
        'id_miembro' => $idMiembro,
    ], 201);
} catch (PDOException $e) {
    $conexion->rollBack();
    if ($e->getCode() === '23000') {
        respuestaJSON(['error' => 'Ya te encuentras unido a esta juntada'], 409);
    }
    respuestaJSON(['error' => 'Error al unirse a la juntada'], 500);
}