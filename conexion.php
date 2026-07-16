<?php
header('Access-Control-Allow-Origin: http://localhost:3000');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json; charset=UTF-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$servidor = "localhost";
$usuario  = "root";
$clave    = "";
$base     = "hincha_plus";

$conexion = new mysqli($servidor, $usuario, $clave, $base);

if ($conexion->connect_error) {
    http_response_code(500);
    echo json_encode(["error" => "Error de conexion: " . $conexion->connect_error]);
    exit();
}

$conexion->set_charset("utf8mb4");

function respuestaJSON($datos, $codigo = 200) {
    http_response_code($codigo);
    echo json_encode($datos, JSON_UNESCAPED_UNICODE);
    exit();
}

function obtenerJSON() {
    $contenido = file_get_contents("php://input");
    $datos = json_decode($contenido, true);
    if ($datos === null) {
        respuestaJSON(["error" => "JSON invalido o cuerpo vacio"], 400);
    }
    return $datos;
}
