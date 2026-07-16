<?php
require_once __DIR__ . '/../conexion.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    respuestaJSON(["error" => "Metodo no permitido"], 405);
}

$idJuntada = isset($_GET['id_juntada']) ? intval($_GET['id_juntada']) : 0;
$idForo    = isset($_GET['id_foro'])    ? intval($_GET['id_foro'])    : 0;

if ($idJuntada === 0 && $idForo === 0) {
    respuestaJSON(["error" => "Se requiere id_juntada o id_foro como parametro"], 400);
}

if ($idJuntada > 0 && $idForo > 0) {
    respuestaJSON(["error" => "No se puede consultar ambos a la vez"], 400);
}

if ($idJuntada > 0) {
    $stmt = $conexion->prepare("CALL historial_chat_juntada(?)");
    $stmt->bind_param("i", $idJuntada);
    $stmt->execute();
    $resultado = $stmt->get_result();

    $mensajes = [];
    while ($fila = $resultado->fetch_assoc()) {
        $mensajes[] = $fila;
    }

    respuestaJSON(["mensajes" => $mensajes, "tipo" => "juntada"], 200);
    $stmt->close();
}

if ($idForo > 0) {
    $stmt = $conexion->prepare(
        "SELECT m.id_mensaje, m.id_usuario, u.nombre AS nombre_usuario,
                m.contenido_texto, m.enviado_at
         FROM mensajes_chat m
         JOIN usuarios u ON u.id_usuario = m.id_usuario
         WHERE m.id_foro = ?
         ORDER BY m.enviado_at ASC"
    );
    $stmt->bind_param("i", $idForo);
    $stmt->execute();
    $resultado = $stmt->get_result();

    $mensajes = [];
    while ($fila = $resultado->fetch_assoc()) {
        $mensajes[] = $fila;
    }

    respuestaJSON(["mensajes" => $mensajes, "tipo" => "foro"], 200);
    $stmt->close();
}

$conexion->close();
