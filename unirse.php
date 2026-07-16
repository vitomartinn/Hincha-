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

$stmtEstado = $conexion->prepare("SELECT estado, cupo_maximo FROM juntadas WHERE id_juntada = ?");
$stmtEstado->bind_param("i", $idJuntada);
$stmtEstado->execute();
$resEstado = $stmtEstado->get_result();

if ($resEstado->num_rows === 0) {
    respuestaJSON(["error" => "La juntada no existe"], 404);
}

$juntada = $resEstado->fetch_assoc();
$stmtEstado->close();

if ($juntada['estado'] !== 'Abierta') {
    respuestaJSON(["error" => "La juntada ya no se encuentra abierta"], 400);
}

$stmtCount = $conexion->prepare(
    "SELECT COUNT(*) AS total FROM miembros_juntada WHERE id_juntada = ?"
);
$stmtCount->bind_param("i", $idJuntada);
$stmtCount->execute();
$resCount = $stmtCount->get_result();
$countRow = $resCount->fetch_assoc();
$stmtCount->close();

if ($countRow['total'] >= $juntada['cupo_maximo']) {
    respuestaJSON(["error" => "La juntada ha alcanzado su cupo maximo"], 400);
}

$stmt = $conexion->prepare(
    "INSERT INTO miembros_juntada (id_usuario, id_juntada, estado_logistico) VALUES (?, ?, 'Pendiente')"
);
$stmt->bind_param("ii", $idUsuario, $idJuntada);

if ($stmt->execute()) {
    respuestaJSON([
        "mensaje" => "Te has unido a la juntada correctamente",
        "id_miembro" => $stmt->insert_id
    ], 201);
} else {
    if ($conexion->errno == 1062) {
        respuestaJSON(["error" => "Ya te encuentras unido a esta juntada"], 409);
    }
    respuestaJSON(["error" => "Error al unirse a la juntada"], 500);
}

$stmt->close();
$conexion->close();
