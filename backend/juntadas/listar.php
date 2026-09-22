<?php
// backend/juntadas/listar.php

// 1. Incluir la conexion (ya gestiona CORS, cabeceras y conexion PDO)
require_once __DIR__ . '/../conexion.php';

// 2. Validar metodo HTTP
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    respuestaJSON(['error' => 'Metodo no permitido'], 405);
}

// 3. Consulta SQL con bloque try-catch para capturar cualquier excepcion
try {
    $stmt = $conexion->prepare(
        'SELECT j.id_juntada, j.nombre, j.id_organizador, j.punto_encuentro_lat, j.punto_encuentro_lng,
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
         ORDER BY j.creado_at DESC'
    );
    $stmt->execute();
    $juntadas = $stmt->fetchAll();

    respuestaJSON(['juntadas' => $juntadas], 200);

} catch (PDOException $e) {
    respuestaJSON(['error' => 'Error al listar juntadas: ' . $e->getMessage()], 500);
}