<?php
require_once __DIR__ . '/../conexion.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    respuestaJSON(['error' => 'Metodo no permitido'], 405);
}

// LEFT JOIN con equipos porque los foros Generales no tienen
// club asociado (id_equipo es NULL en ese caso).
$stmt = $conexion->prepare(
    'SELECT f.id_foro, f.nombre_foro, f.descripcion, f.tipo,
            e.id_equipo, e.nombre_club, e.estadio,
            f.categoria_general, f.id_usuario_creador,
            (SELECT COUNT(*) FROM mensajes_chat m WHERE m.id_foro = f.id_foro) AS total_mensajes
     FROM foros_debate f
     LEFT JOIN equipos e ON e.id_equipo = f.id_equipo
     ORDER BY f.id_foro DESC'
);
$stmt->execute();
$foros = $stmt->fetchAll();

respuestaJSON(['foros' => $foros], 200);
