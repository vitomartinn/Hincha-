<?php
/**
 * POST /debates/crear.php
 * -----------------------------------------------------------
 * Antes este endpoint (a) exigia siempre un id_equipo y (b)
 * cortaba con un error 409 si ese club ya tenia un foro,
 * impidiendo crear un segundo foro para el mismo club y sin
 * soportar foros que no fueran de un club puntual.
 *
 * Ahora admite dos tipos de foro:
 *   tipo = "Club"    -> requiere id_equipo. Puede haber muchos
 *                        foros para el mismo club (no se valida
 *                        unicidad).
 *   tipo = "General" -> requiere categoria_general (Seleccion
 *                        Argentina, Futbol Internacional,
 *                        Debates Generales o Mercado de Pases).
 *
 * El fix del bug de "loading infinito": TODOS los caminos de
 * este archivo terminan en un respuestaJSON(), que siempre
 * hace http_response_code() + json_encode() + exit(). El
 * frontend jamas se queda sin respuesta.
 * -----------------------------------------------------------
 */

require_once __DIR__ . '/../conexion.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respuestaJSON(['error' => 'Metodo no permitido'], 405);
}

$datos = obtenerJSON();

$nombreForo  = trim($datos['nombre_foro']          ?? '');
$descripcion = trim($datos['descripcion']          ?? '');
$tipo        = trim($datos['tipo']                 ?? 'Club');
$idEquipo    = intval($datos['id_equipo']          ?? 0);
$categoria   = trim($datos['categoria_general']    ?? '');
$idCreador   = intval($datos['id_usuario_creador'] ?? 0);

$categoriasValidas = ['Seleccion Argentina', 'Futbol Internacional', 'Debates Generales', 'Mercado de Pases'];

if ($nombreForo === '' || $idCreador === 0) {
    respuestaJSON(['error' => 'El nombre del foro y el usuario creador son obligatorios'], 400);
}

if ($tipo !== 'Club' && $tipo !== 'General') {
    respuestaJSON(['error' => 'El tipo de foro debe ser "Club" o "General"'], 400);
}

if ($tipo === 'Club' && $idEquipo === 0) {
    respuestaJSON(['error' => 'Un foro de tipo Club necesita un equipo'], 400);
}

if ($tipo === 'General' && !in_array($categoria, $categoriasValidas, true)) {
    respuestaJSON(['error' => 'Un foro General necesita una categoria valida'], 400);
}

try {
    $stmt = $conexion->prepare(
        'INSERT INTO foros_debate (nombre_foro, descripcion, tipo, id_equipo, categoria_general, id_usuario_creador)
         VALUES (:nombre_foro, :descripcion, :tipo, :id_equipo, :categoria_general, :id_usuario_creador)'
    );
    $stmt->execute([
        'nombre_foro'        => $nombreForo,
        'descripcion'        => $descripcion,
        'tipo'               => $tipo,
        'id_equipo'          => $tipo === 'Club' ? $idEquipo : null,
        'categoria_general'  => $tipo === 'General' ? $categoria : null,
        'id_usuario_creador' => $idCreador,
    ]);

    respuestaJSON([
        'mensaje' => 'Foro de debate creado exitosamente',
        'id_foro' => $conexion->lastInsertId(),
    ], 201);
} catch (PDOException $e) {
    respuestaJSON(['error' => 'Error al crear el foro de debate'], 500);
}
