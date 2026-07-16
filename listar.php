<?php
require_once __DIR__ . '/../conexion.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    respuestaJSON(["error" => "Metodo no permitido"], 405);
}

$stmt = $conexion->prepare(
    "SELECT j.id_juntada, j.id_organizador, j.punto_encuentro_lat, j.punto_encuentro_lng,
            j.descripcion_punto, j.cupo_maximo, j.estado, j.creado_at,
            u.nombre AS nombre_organizador,
            p.id_partido, p.fecha_partido, p.estadio_sede,
            el.nombre_club AS club_local,
            ev.nombre_club AS club_visitante,
            (SELECT COUNT(*) FROM miembros_juntada mj WHERE mj.id_juntada = j.id_juntada) AS total_miembros
     FROM juntadas j
     JOIN usuarios u   ON u.id_usuario = j.id_organizador
     JOIN partidos p   ON p.id_partido = j.id_partido
     JOIN equipos el   ON el.id_equipo = p.id_equipo_local
     JOIN equipos ev   ON ev.id_equipo = p.id_equipo_visitante
     ORDER BY j.creado_at DESC"
);
$stmt->execute();
$resultado = $stmt->get_result();

$juntadas = [];
while ($fila = $resultado->fetch_assoc()) {
    $juntadas[] = $fila;
}

respuestaJSON(["juntadas" => $juntadas], 200);

$stmt->close();
$conexion->close();
