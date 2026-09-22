<?php
// backend/juntadas/mis_juntadas.php

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/../conexion.php';

$idUsuario = intval($_GET['id_usuario'] ?? 0);

if ($idUsuario === 0) {
    respuestaJSON(['juntadas' => []], 200);
}

try {
    // NOTA: antes esta consulta usaba los alias inexistentes
    // el.club_local / ev.club_visitante (la tabla equipos solo
    // tiene la columna nombre_club) y un GROUP BY innecesario.
    // Eso hacia que MySQL tirara error de SQL en cada llamada,
    // el catch de abajo lo silenciaba y el frontend siempre
    // recibia una lista vacia: por eso el usuario nunca aparecia
    // como "miembro" de la juntada aunque el join se hubiera
    // guardado bien en la base de datos.
    $stmt = $conexion->prepare("
        SELECT
            j.id_juntada,
            j.nombre,
            j.descripcion_punto,
            j.estado,
            j.cupo_maximo,
            j.id_organizador,
            mj.estado_logistico,
            p.fecha_partido,
            p.estadio_sede,
            el.nombre_club AS club_local,
            ev.nombre_club AS club_visitante,
            (SELECT COUNT(*) FROM miembros_juntada m2 WHERE m2.id_juntada = j.id_juntada) AS total_miembros
        FROM miembros_juntada mj
        INNER JOIN juntadas j ON j.id_juntada = mj.id_juntada
        LEFT JOIN partidos p ON j.id_partido = p.id_partido
        LEFT JOIN equipos el ON p.id_equipo_local = el.id_equipo
        LEFT JOIN equipos ev ON p.id_equipo_visitante = ev.id_equipo
        WHERE mj.id_usuario = :id_usuario
        ORDER BY j.creado_at DESC
    ");

    $stmt->execute(['id_usuario' => $idUsuario]);
    $juntadas = $stmt->fetchAll(PDO::FETCH_ASSOC);

    respuestaJSON(['juntadas' => $juntadas], 200);
} catch (PDOException $e) {
    respuestaJSON(['juntadas' => []], 200);
}