<?php
/**
 * conexion.php
 * -----------------------------------------------------------
 * Conexion unica a la base de datos (PDO) + helpers comunes
 * que usan todos los endpoints. Todo el flujo REST se apoya
 * en 2 funciones:
 *   - respuestaJSON(): siempre termina la ejecucion devolviendo
 *     un JSON con el status code correcto (evita que el
 *     frontend se quede "colgado" esperando una respuesta).
 *   - obtenerJSON(): lee el body de la request como JSON.
 * -----------------------------------------------------------
 */

// CORS + charset. Content-Type UTF-8 en todas las respuestas
// (parte del arreglo del encoding en el chat).
header('Access-Control-Allow-Origin: http://localhost:3000');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json; charset=UTF-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$servidor = 'localhost';
$usuario  = 'root';
$clave    = '';
$base     = 'plus_hincha';

try {
    $conexion = new PDO(
        "mysql:host={$servidor};dbname={$base};charset=utf8mb4",
        $usuario,
        $clave,
        [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]
    );
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Error de conexion: ' . $e->getMessage()], JSON_UNESCAPED_UNICODE);
    exit();
}

/**
 * Corta la ejecucion y devuelve un JSON. Se usa en TODOS los
 * caminos posibles de cada endpoint (exito y error) para que
 * el frontend nunca se quede esperando una respuesta que no
 * llega (esto es lo que causaba el bug de "loading" infinito
 * al crear un debate).
 */
function respuestaJSON($datos, $codigo = 200) {
    http_response_code($codigo);
    echo json_encode($datos, JSON_UNESCAPED_UNICODE);
    exit();
}

/**
 * Lee y decodifica el body de la request como JSON.
 */
function obtenerJSON() {
    $contenido = file_get_contents('php://input');
    $datos = json_decode($contenido, true);
    if ($datos === null) {
        respuestaJSON(['error' => 'JSON invalido o cuerpo vacio'], 400);
    }
    return $datos;
}

/**
 * Devuelve el rol ('admin' | 'user') del usuario, leido siempre
 * de la base de datos. Nunca hay que confiar en un campo "rol"
 * que venga del propio request: el cliente podria mandar
 * cualquier cosa. Todo endpoint que necesite verificar permisos
 * de administrador llama a esta funcion con el id_usuario de
 * quien esta haciendo el pedido.
 */
function obtenerRolUsuario($conexion, $idUsuario) {
    $stmt = $conexion->prepare('SELECT rol FROM usuarios WHERE id_usuario = :id');
    $stmt->execute(['id' => $idUsuario]);
    $fila = $stmt->fetch();
    return $fila ? $fila['rol'] : null;
}

/**
 * true si el usuario es administrador. Atajo sobre obtenerRolUsuario().
 */
function esAdmin($conexion, $idUsuario) {
    return obtenerRolUsuario($conexion, $idUsuario) === 'admin';
}
