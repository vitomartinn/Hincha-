<?php
require_once __DIR__ . '/../conexion.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respuestaJSON(["error" => "Metodo no permitido"], 405);
}

$datos = obtenerJSON();

$dni      = trim($datos['dni']      ?? '');
$nombre   = trim($datos['nombre']   ?? '');
$email    = trim($datos['email']    ?? '');
$password = $datos['password']      ?? '';
$idEquipo = intval($datos['id_equipo'] ?? 0);

if ($dni === '' || $nombre === '' || $email === '' || $password === '' || $idEquipo === 0) {
    respuestaJSON(["error" => "Todos los campos son obligatorios"], 400);
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    respuestaJSON(["error" => "El formato del email no es valido"], 400);
}

if (strlen($password) < 6) {
    respuestaJSON(["error" => "La password debe tener al menos 6 caracteres"], 400);
}

$hash = password_hash($password, PASSWORD_BCRYPT);

$stmt = $conexion->prepare(
    "INSERT INTO usuarios (dni, nombre, email, password_hash, id_equipo) VALUES (?, ?, ?, ?, ?)"
);
$stmt->bind_param("ssssi", $dni, $nombre, $email, $hash, $idEquipo);

if ($stmt->execute()) {
    respuestaJSON([
        "mensaje"  => "Usuario registrado correctamente",
        "usuario"  => [
            "id_usuario" => $stmt->insert_id,
            "dni"        => $dni,
            "nombre"     => $nombre,
            "email"      => $email,
            "id_equipo"  => $idEquipo,
            "estado"     => "Activo",
            "rol"        => "Hincha_Comun"
        ]
    ], 201);
} else {
    if ($errno = $conexion->errno) {
        if ($errno == 1062) {
            respuestaJSON(["error" => "El DNI, email o equipo ya se encuentra registrado"], 409);
        }
    }
    respuestaJSON(["error" => "Error al registrar usuario"], 500);
}

$stmt->close();
$conexion->close();
