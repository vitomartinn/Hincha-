<?php
require_once __DIR__ . '/../conexion.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respuestaJSON(["error" => "Metodo no permitido"], 405);
}

$datos = obtenerJSON();

$idUsuario = intval($datos['id_usuario'] ?? 0);
$idJuntada = intval($datos['id_juntada'] ?? 0);

if ($idUsuario === 0 || $idJuntada === 0) {
    respuestaJSON(["error" => "id_usuario e id_juntada son obligatorios"], 400);
}

$stmtExiste = $conexion->prepare(
    "SELECT estado_logistico FROM miembros_juntada WHERE id_usuario = ? AND id_juntada = ?"
);
$stmtExiste->bind_param("ii", $idUsuario, $idJuntada);
$stmtExiste->execute();
$resExiste = $stmtExiste->get_result();

if ($resExiste->num_rows === 0) {
    respuestaJSON(["error" => "No formas parte de esta juntada"], 404);
}

$miembro = $resExiste->fetch_assoc();
$stmtExiste->close();

if ($miembro['estado_logistico'] === 'Presente') {
    respuestaJSON(["error" => "Ya se registro tu check-in anteriormente"], 400);
}

$stmt = $conexion->prepare("CALL registrar_checkin(?, ?)");
$stmt->bind_param("ii", $idUsuario, $idJuntada);

if ($stmt->execute()) {
    respuestaJSON([
        "mensaje" => "Check-in registrado exitosamente. Bienvenido al punto de encuentro!"
    ], 200);
} else {
    respuestaJSON(["error" => "Error al registrar el check-in"], 500);
}

$stmt->close();
$conexion->close();
