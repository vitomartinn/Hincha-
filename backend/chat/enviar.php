<?php
require_once __DIR__ . '/../conexion.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respuestaJSON(['error' => 'Metodo no permitido'], 405);
}

$datos = obtenerJSON();

$idUsuario = intval($datos['id_usuario']    ?? 0);
$idForo    = isset($datos['id_foro'])    ? intval($datos['id_foro'])    : null;
$idJuntada = isset($datos['id_juntada']) ? intval($datos['id_juntada']) : null;
$contenido = trim($datos['contenido_texto'] ?? '');

if ($idUsuario === 0 || $contenido === '') {
    respuestaJSON(['error' => 'id_usuario y contenido son obligatorios'], 400);
}

if (mb_strlen($contenido) > 1000) {
    respuestaJSON(['error' => 'El mensaje no puede superar los 1000 caracteres'], 400);
}

$tieneForo    = ($idForo    !== null && $idForo    > 0);
$tieneJuntada = ($idJuntada !== null && $idJuntada > 0);

if (!$tieneForo && !$tieneJuntada) {
    respuestaJSON(['error' => 'El mensaje debe dirigirse a un foro o a una juntada'], 400);
}

if ($tieneForo && $tieneJuntada) {
    respuestaJSON(['error' => 'El mensaje no puede dirigirse a ambos simultaneamente'], 400);
}

if ($tieneForo) {
    $stmtCheck = $conexion->prepare('SELECT id_foro FROM foros_debate WHERE id_foro = :id_foro');
    $stmtCheck->execute(['id_foro' => $idForo]);
    if (!$stmtCheck->fetch()) {
        respuestaJSON(['error' => 'El foro de debate no existe'], 404);
    }
}

if ($tieneJuntada) {
    $stmtCheck = $conexion->prepare('SELECT id_juntada FROM juntadas WHERE id_juntada = :id_juntada');
    $stmtCheck->execute(['id_juntada' => $idJuntada]);
    if (!$stmtCheck->fetch()) {
        respuestaJSON(['error' => 'La juntada no existe'], 404);
    }
}

try {
    $stmt = $conexion->prepare(
        'INSERT INTO mensajes_chat (id_usuario, id_foro, id_juntada, contenido_texto)
         VALUES (:id_usuario, :id_foro, :id_juntada, :contenido)'
    );
    $stmt->execute([
        'id_usuario' => $idUsuario,
        'id_foro'    => $tieneForo ? $idForo : null,
        'id_juntada' => $tieneJuntada ? $idJuntada : null,
        'contenido'  => $contenido,
    ]);

    $idMensaje = $conexion->lastInsertId();

    // Devolvemos el mensaje ya armado (con nombre de usuario y
    // fecha) para que el frontend lo pueda pintar directamente
    // en la lista de mensajes sin tener que volver a pedir todo
    // el historial.
    $stmtMensaje = $conexion->prepare(
        'SELECT m.id_mensaje, m.id_usuario, u.nombre AS nombre_usuario,
                m.contenido_texto, m.enviado_at
         FROM mensajes_chat m
         JOIN usuarios u ON u.id_usuario = m.id_usuario
         WHERE m.id_mensaje = :id_mensaje'
    );
    $stmtMensaje->execute(['id_mensaje' => $idMensaje]);
    $mensajeCreado = $stmtMensaje->fetch();

    respuestaJSON([
        'exito'   => true,
        'mensaje' => $mensajeCreado,
    ], 201);
} catch (PDOException $e) {
    respuestaJSON(['error' => 'Error al enviar el mensaje'], 500);
}
