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

$stmtExiste = $conexion->prepare(
    'SELECT estado_logistico FROM miembros_juntada WHERE id_usuario = :id_usuario AND id_juntada = :id_juntada'
);
$stmtExiste->execute(['id_usuario' => $idUsuario, 'id_juntada' => $idJuntada]);
$miembro = $stmtExiste->fetch();

if (!$miembro) {
    respuestaJSON(['error' => 'No formas parte de esta juntada'], 404);
}

if ($miembro['estado_logistico'] === 'Presente') {
    respuestaJSON(['error' => 'Ya se registro tu check-in anteriormente'], 400);
}

try {
    $conexion->beginTransaction();

    $stmtActualizar = $conexion->prepare(
        "UPDATE miembros_juntada SET estado_logistico = 'Presente'
         WHERE id_usuario = :id_usuario AND id_juntada = :id_juntada"
    );
    $stmtActualizar->execute(['id_usuario' => $idUsuario, 'id_juntada' => $idJuntada]);

    $stmtHito = $conexion->prepare(
        "INSERT INTO hitos_transaccionales (id_juntada, id_usuario, tipo_evento, descripcion)
         VALUES (:id_juntada, :id_usuario, 'CheckIn', 'El usuario confirmo su llegada al punto de encuentro.')"
    );
    $stmtHito->execute(['id_juntada' => $idJuntada, 'id_usuario' => $idUsuario]);

    $conexion->commit();

    respuestaJSON(['mensaje' => 'Check-in registrado exitosamente. Bienvenido al punto de encuentro!'], 200);
} catch (PDOException $e) {
    $conexion->rollBack();
    respuestaJSON(['error' => 'Error al registrar el check-in'], 500);
}