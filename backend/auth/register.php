<?php
// 1. Cabeceras CORS y tipo de contenido
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS, PUT, DELETE");
header("Content-Type: application/json; charset=UTF-8");

// 2. Manejo del Preflight (OPTIONS)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// 3. Incluir la conexión y funciones auxiliares
require_once __DIR__ . '/../conexion.php';

// 4. Validar que la petición sea POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respuestaJSON(['error' => 'Metodo no permitido'], 405);
}

// 5. Obtener los datos JSON
$datos = obtenerJSON();

$dni      = trim($datos['dni']      ?? '');
$nombre   = trim($datos['nombre']   ?? '');
$email    = trim($datos['email']    ?? '');
$password = $datos['password']      ?? '';
$idEquipo = intval($datos['id_equipo'] ?? 0);

// 6. Validaciones de negocio
if ($dni === '' || $nombre === '' || $email === '' || $password === '' || $idEquipo === 0) {
    respuestaJSON(['error' => 'Todos los campos son obligatorios'], 400);
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    respuestaJSON(['error' => 'El formato del email no es valido'], 400);
}

if (strlen($password) < 6) {
    respuestaJSON(['error' => 'La password debe tener al menos 6 caracteres'], 400);
}

// 7. Hash de la contraseña e inserción en BD
$hash = password_hash($password, PASSWORD_BCRYPT);

try {
    // 'rol' se fija explicitamente en 'user' (no se deja librado
    // al DEFAULT de la columna): nadie puede autorregistrarse como
    // 'admin' desde este formulario. Promover a un usuario a admin
    // es una accion deliberada que se hace directo en la base
    // (ver README.md).
    $stmt = $conexion->prepare(
        "INSERT INTO usuarios (dni, nombre, email, password_hash, id_equipo, rol)
         VALUES (:dni, :nombre, :email, :password_hash, :id_equipo, 'user')"
    );
    $stmt->execute([
        'dni'           => $dni,
        'nombre'        => $nombre,
        'email'         => $email,
        'password_hash' => $hash,
        'id_equipo'     => $idEquipo,
    ]);

    respuestaJSON([
        'mensaje' => 'Usuario registrado correctamente',
        'usuario' => [
            'id_usuario' => $conexion->lastInsertId(),
            'dni'        => $dni,
            'nombre'     => $nombre,
            'email'      => $email,
            'id_equipo'  => $idEquipo,
            'estado'     => 'Activo',
            'rol'        => 'user',
        ],
    ], 201);
} catch (PDOException $e) {
    // Código 23000 = violación de restricción UNIQUE (DNI o Email duplicados)
    if ($e->getCode() === '23000') {
        respuestaJSON(['error' => 'El DNI o el email ya se encuentran registrados'], 409);
    }
    respuestaJSON(['error' => 'Error al registrar usuario en la base de datos'], 500);
}