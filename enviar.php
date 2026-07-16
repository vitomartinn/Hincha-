<?php
require_once __DIR__ . '/../conexion.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respuestaJSON(["error" => "Metodo no permitido"], 405);
}

$datos = obtenerJSON();

$idUsuario   = intval($datos['id_usuario']     ?? 0);
$idForo      = isset($datos['id_foro'])        ? intval($datos['id_foro'])   : null;
$idJuntada   = isset($datos['id_juntada'])     ? intval($datos['id_juntada']): null;
$contenido   = trim($datos['contenido_texto']  ?? '');

if ($idUsuario === 0 || $contenido === '') {
    respuestaJSON(["error" => "id_usuario y contenido son obligatorios"], 400);
}

if (mb_strlen($contenido) > 1000) {
    respuestaJSON(["error" => "El mensaje no puede superar los 1000 caracteres"], 400);
}

$tieneForo    = ($idForo    !== null && $idForo    > 0);
$tieneJuntada = ($idJuntada !== null && $idJuntada > 0);

if (!$tieneForo && !$tieneJuntada) {
    respuestaJSON(["error" => "El mensaje debe dirigirse a un foro o a una juntada"], 400);
}

if ($tieneForo && $tieneJuntada) {
    respuestaJSON(["error" => "El mensaje no puede dirigirse a ambos simultaneamente"], 400);
}

if ($tieneForo) {
    $stmtCheck = $conexion->prepare("SELECT id_foro FROM foros_debate WHERE id_foro = ?");
    $stmtCheck->bind_param("i", $idForo);
    $stmtCheck->execute();
    $resCheck = $stmtCheck->get_result();
    if ($resCheck->num_rows === 0) {
        respuestaJSON(["error" => "El foro de debate no existe"], 404);
    }
    $stmtCheck->close();
}

if ($tieneJuntada) {
    $stmtCheck = $conexion->prepare("SELECT id_juntada FROM juntadas WHERE id_juntada = ?");
    $stmtCheck->bind_param("i", $idJuntada);
    $stmtCheck->execute();
    $resCheck = $stmtCheck->get_result();
    if ($resCheck->num_rows === 0) {
        respuestaJSON(["error" => "La juntada no existe"], 404);
    }
    $stmtCheck->close();
}

$stmt = $conexion->prepare(
    "INSERT INTO mensajes_chat (id_usuario, id_foro, id_juntada, contenido_texto) VALUES (?, ?, ?, ?)"
);
$stmt->bind_param("iiis", $idUsuario, $idForo, $idJuntada, $contenido);

if ($stmt->execute()) {
    $destino = $tieneForo ? "foro" : "juntada";
    respuestaJSON([
        "mensaje"    => "Mensaje enviado al $destino correctamente",
        "id_mensaje" => $stmt->insert_id
    ], 201);
} else {
    respuestaJSON(["error" => "Error al enviar el mensaje"], 500);
}

$stmt->close();
$conexion->close();
