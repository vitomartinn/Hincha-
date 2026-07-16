<?php
require_once __DIR__ . '/../conexion.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respuestaJSON(["error" => "Metodo no permitido"], 405);
}

$datos = obtenerJSON();

$idOrganizador  = intval($datos['id_organizador']       ?? 0);
$idPartido      = intval($datos['id_partido']           ?? 0);
$lat            = floatval($datos['punto_encuentro_lat'] ?? 0);
$lng            = floatval($datos['punto_encuentro_lng'] ?? 0);
$descripcion    = trim($datos['descripcion_punto']      ?? '');
$cupoMaximo     = intval($datos['cupo_maximo']          ?? 0);

if ($idOrganizador === 0 || $idPartido === 0 || $cupoMaximo <= 0) {
    respuestaJSON(["error" => "Organizador, partido y cupo maximo son obligatorios"], 400);
}

if ($lat < -90 || $lat > 90 || $lng < -180 || $lng > 180) {
    respuestaJSON(["error" => "Coordenadas geograficas invalidas"], 400);
}

$stmt = $conexion->prepare(
    "INSERT INTO juntadas (id_organizador, id_partido, punto_encuentro_lat, punto_encuentro_lng, descripcion_punto, cupo_maximo)
     VALUES (?, ?, ?, ?, ?, ?)"
);
$stmt->bind_param("iiddds", $idOrganizador, $idPartido, $lat, $lng, $descripcion, $cupoMaximo);

if ($stmt->execute()) {
    $idJuntada = $stmt->insert_id;

    $stmtMiembro = $conexion->prepare(
        "INSERT INTO miembros_juntada (id_usuario, id_juntada, estado_logistico) VALUES (?, ?, 'Organizador')"
    );
    $stmtMiembro->bind_param("ii", $idOrganizador, $idJuntada);
    $stmtMiembro->execute();
    $stmtMiembro->close();

    respuestaJSON([
        "mensaje"   => "Juntada creada exitosamente",
        "id_juntada" => $idJuntada
    ], 201);
} else {
    respuestaJSON(["error" => "Error al crear la juntada"], 500);
}

$stmt->close();
$conexion->close();
