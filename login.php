<?php
require_once __DIR__ . '/../conexion.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respuestaJSON(["error" => "Metodo no permitido"], 405);
}

$datos = obtenerJSON();

$email    = trim($datos['email']    ?? '');
$password = $datos['password']      ?? '';

if ($email === '' || $password === '') {
    respuestaJSON(["error" => "Email y password son obligatorios"], 400);
}

$stmt = $conexion->prepare(
    "SELECT id_usuario, dni, nombre, email, password_hash, id_equipo, estado, rol
     FROM usuarios
     WHERE email = ? LIMIT 1"
);
$stmt->bind_param("s", $email);
$stmt->execute();
$resultado = $stmt->get_result();

if ($resultado->num_rows === 0) {
    respuestaJSON(["error" => "Credenciales incorrectas: email no registrado"], 401);
}

$usuario = $resultado->fetch_assoc();

if (!password_verify($password, $usuario['password_hash'])) {
    respuestaJSON(["error" => "Credenciales incorrecta: password invalida"], 401);
}

if ($usuario['estado'] !== 'Activo') {
    respuestaJSON(["error" => "La cuenta se encuentra desactivada"], 403);
}

unset($usuario['password_hash']);

respuestaJSON([
    "mensaje"  => "Inicio de sesion exitoso",
    "usuario"  => $usuario
], 200);

$stmt->close();
$conexion->close();
