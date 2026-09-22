# HINCHA+ - Tu Comunidad Futbolera

Plataforma web para que los hinchas de clubes argentinos organicen juntadas
previas a los partidos, debatan en foros y se comuniquen en tiempo real.

**Stack**: PHP (API REST con PDO) + React + MySQL

La lógica de negocio está repartida en dos capas: las validaciones y el
flujo de cada acción viven en los archivos PHP (usando consultas PDO
preparadas), y **algunas reglas críticas además están protegidas a nivel
de base de datos** con funciones, procedimientos almacenados y triggers
(cerrar una juntada sola cuando se llena el cupo, reabrirla sola cuando
alguien se va y libera un lugar, registrar los hitos de auditoría,
impedir crear una juntada para un partido que ya se jugó, proteger al
organizador). Ver la sección [Funciones, procedimientos y
triggers](#funciones-procedimientos-y-triggers) para el detalle de cada
uno.

Además, el sistema tiene **roles de usuario** (`admin` / `user`): un
administrador puede moderar contenido (eliminar cualquier juntada o
foro), el organizador puede cancelar su propia juntada, y cualquier
miembro puede abandonar una juntada a la que se unió. Ver la sección
[Roles y permisos](#roles-y-permisos).

---

## Requisitos

- [XAMPP](https://www.apachefriends.org/) con Apache y MySQL activos
- [Node.js](https://nodejs.org/) v16+ con npm
- [draw.io](https://app.diagrams.net/) (opcional, para el diagrama MER)

---

## Instalacion Rapida

### 1. Base de Datos

Abri phpMyAdmin (`http://localhost/phpmyadmin`) y hace esto:

1. Abri la pestaña **"SQL"** de phpMyAdmin (no hace falta crear la base
   antes, el script la crea solo).
2. Pega el contenido completo de **`hincha_plus.sql`** y ejecuta.

Eso crea la base `hincha_plus`, las 8 tablas con sus relaciones, las 2
funciones, los 2 procedimientos almacenados, los **5 triggers**, y datos
de prueba: los **30 equipos** de la Primera Division de la Liga
Profesional Argentina, 12 usuarios (el primero, Martin Gonzalez, ya
queda cargado como `admin`; el resto como `user`), 12 partidos, 14 foros
de debate (algunos clubes tienen mas de uno, y hay 4 foros generales sin
club), 12 juntadas y sus mensajes de chat.

> **¿Ya tenias la base creada de antes y no queres perder tus datos?**
> Corre en su lugar, en este orden, los dos scripts de migracion:
> 1. `backend/migracion_add_nombre_juntada.sql` (agrega la columna
>    `nombre` a `juntadas`, si todavia no la corriste)
> 2. `backend/migracion_roles_y_bajas.sql` (agrega el sistema de roles,
>    corrige `juntada_tiene_cupo()` y agrega el trigger de reapertura)
>
> Ninguno de los dos borra datos existentes.

### 2. Backend (PHP)

1. Copia toda la carpeta `backend/` dentro de `C:\xampp\htdocs\hincha_plus\`
   ```
   C:\xampp\htdocs\hincha_plus\backend\
   C:\xampp\htdocs\hincha_plus\backend\conexion.php
   C:\xampp\htdocs\hincha_plus\backend\auth\...
   ```
   ⚠️ El nombre de la carpeta tiene que ser **exactamente** `hincha_plus`
   (todo en minúscula, con guión bajo, sin el "+"). El frontend tiene
   hardcodeada esa ruta en `frontend/src/api.js`
   (`const API_BASE = 'http://localhost/hincha_plus/backend'`), así que
   si la carpeta se llama distinto (por ejemplo `HINCHA+`), el navegador
   va a devolver un 404 y eso se ve en la consola como si fuera un error
   de CORS, aunque el verdadero problema es que la ruta no existe.
2. Asegurate de que Apache y MySQL esten **iniciados** en el panel de XAMPP
3. Verifica que funcione abriendo en el navegador:
   ```
   http://localhost/hincha_plus/backend/juntadas/listar.php
   ```
   Deberia mostrar `{"juntadas":[...]}` con los datos de ejemplo.

### 3. Frontend (React)

Desde PowerShell o CMD:

```powershell
cd C:\HINCHA+\frontend
npm install
npm start
```

Se abre automaticamente en `http://localhost:3000`.

---

## Probar el Sistema

| Paso | Que hacer |
|------|-----------|
| 1 | Registrate con un DNI, nombre, email, password y selecciona uno de los 30 clubes (queda como `user`) |
| 2 | Inicia sesion con esas credenciales (o usa un usuario de prueba, ver abajo) |
| 3 | Desde el Dashboard, anda a **Juntadas** y crea una nueva (necesitas el ID de un partido, usa `1`) |
| 4 | Unite a esa juntada y hace **Check-In** |
| 5 | Andá a **Debates**, crea un foro: elegi si es de tipo "Club" (podes crear mas de uno para el mismo club) o "General" (Seleccion Argentina, Futbol Internacional, Debates Generales o Mercado de Pases) |
| 6 | Andá al **Chat**, selecciona el foro o la juntada y envia mensajes |
| 7 | Iniciando sesion como `martin.gonzalez@mail.com` (es `admin`), fijate que en **Juntadas** y **Debates** aparecen botones "ELIMINAR" que con tu usuario `user` no se ven |
| 8 | Con un usuario `user` que se haya unido a una juntada (no el organizador), probá el boton **SALIR** y confirma en phpMyAdmin que la fila desaparece de `miembros_juntada` |
| 9 | Abrí phpMyAdmin y verifica que los registros aparecen en las tablas, incluidos los hitos en `hitos_transaccionales` (los inserta el trigger o el propio endpoint, segun el caso — ver la tabla de triggers) |

**Usuarios de prueba** (todos con password `hincha123`): cualquier email de
la tabla `usuarios` del script SQL. `martin.gonzalez@mail.com` es `admin`;
el resto son `user`.

> **¿Cómo promuevo a otro usuario a admin?** No hay pantalla para esto
> (a proposito: nadie se autoasigna admin desde el registro). Se hace
> directo en la base:
> ```sql
> UPDATE usuarios SET rol = 'admin' WHERE email = 'el-email-que-quieras@mail.com';
> ```

---

## Endpoints de la API

Todos los archivos PHP estan en `backend/` y devuelven JSON puro (siempre
con `http_response_code()` + `json_encode()`, incluso en los caminos de
error, para que el frontend nunca se quede esperando una respuesta que no
llega).

| Endpoint | Metodo | Que hace |
|----------|--------|----------|
| `auth/register.php` | POST | Registra un usuario nuevo (DNI, nombre, email, password, equipo). Siempre queda con `rol = 'user'` |
| `auth/login.php` | POST | Valida credenciales y devuelve los datos del usuario, incluido su `rol` |
| `juntadas/listar.php` | GET | Devuelve todas las juntadas con datos del partido y equipo |
| `juntadas/obtener.php` | GET | Devuelve UNA juntada puntual por `id` (la usa la pantalla de Chat) |
| `juntadas/crear.php` | POST | Crea una juntada nueva (valida en PHP que el partido no haya pasado; el trigger `trg_evitar_juntada_partido_pasado` valida lo mismo a nivel de base como ultima linea de defensa) |
| `juntadas/unirse.php` | POST | Suma un usuario a una juntada. El hito de auditoria y el cierre automatico por cupo lleno los maneja MySQL solo (triggers `trg_hito_nuevo_miembro` y `trg_cerrar_juntada_llena`), PHP no los duplica |
| `juntadas/salir.php` | POST | **Nuevo.** Un miembro abandona una juntada. El organizador no puede (bloqueado en PHP y por el trigger `trg_proteger_organizador`). Si la juntada estaba cerrada por cupo lleno, `trg_reabrir_juntada_con_cupo` la reabre sola |
| `juntadas/eliminar.php` | POST | **Nuevo.** Elimina una juntada entera. Solo el organizador o un `admin`. Deja un hito `'JuntadaEliminada'` antes de borrar (sobrevive gracias al `ON DELETE SET NULL`) |
| `juntadas/checkin.php` | POST | Marca presente al usuario y registra el hito, en una transaccion PDO |
| `juntadas/mis_juntadas.php` | GET | Devuelve las juntadas de las que un usuario puntual es miembro (`?id_usuario=`) |
| `debates/listar.php` | GET | Lista foros de club y generales, con cantidad de mensajes y su `id_usuario_creador` |
| `debates/obtener.php` | GET | Devuelve UN foro puntual por `id` (la usa la pantalla de Chat) |
| `debates/crear.php` | POST | Crea un foro nuevo, de tipo `Club` (con `id_equipo`) o `General` (con `categoria_general`). No hay limite de foros por club |
| `debates/eliminar.php` | POST | **Nuevo.** Elimina un foro entero (y en cascada sus mensajes). Solo `admin`; a diferencia de las juntadas, el creador del foro **no** puede borrarlo el mismo |
| `chat/obtener.php` | GET | Historial de mensajes de un foro (`?id_foro=`) o de una juntada (`?id_juntada=`) |
| `chat/enviar.php` | POST | Envia un mensaje a un foro O una juntada (nunca a ambos), y devuelve el mensaje ya armado con el nombre del usuario |

**Ejemplo de peticion** (crear un foro general):
```json
POST /HINCHA+/backend/debates/crear.php
{
  "tipo": "General",
  "categoria_general": "Mercado de Pases",
  "nombre_foro": "Refuerzos de verano",
  "descripcion": "Rumores y confirmaciones",
  "id_usuario_creador": 1
}
```

---

## Roles y permisos

Cada usuario tiene un campo `rol` en la tabla `usuarios`, con dos
valores posibles: `admin` o `user`. Nadie puede autoasignarse `admin`
desde el formulario de registro (`auth/register.php` siempre inserta
`'user'`); promover a alguien es una accion manual en la base de datos
(ver la tabla de arriba, "¿Cómo promuevo a otro usuario a admin?").

| Accion | Quién puede | Dónde se valida |
|---|---|---|
| Eliminar cualquier juntada | `admin` | `juntadas/eliminar.php` (`esAdmin()` contra la base) |
| Eliminar/cancelar su propia juntada | El organizador de esa juntada | `juntadas/eliminar.php` (`id_organizador === id_usuario`) |
| Eliminar cualquier foro de debate | Solo `admin` (ni siquiera el creador del foro puede) | `debates/eliminar.php` |
| Abandonar una juntada a la que se unió | Cualquier miembro, **excepto el organizador** | `juntadas/salir.php` + trigger `trg_proteger_organizador` como ultima defensa |

**Importante — el permiso nunca se confía al cliente.** El frontend usa
`usuario.rol` (guardado en `localStorage` tras el login) unicamente para
decidir que botones mostrar; el backend jamas confia en eso. Cada
endpoint sensible vuelve a preguntarle a la base "¿este `id_usuario` es
admin?" con la funcion `esAdmin()` de `conexion.php`, asi que aunque
alguien arme el request a mano (por ejemplo con Postman) sin pasar por
la interfaz, el chequeo se sigue cumpliendo igual.

**Sobre el contador de asistentes**: no existe una columna que guarde
"cantidad de miembros" en la tabla `juntadas`. El numero que se ve en la
UI (`total_miembros`) siempre se calcula al vuelo con un
`(SELECT COUNT(*) FROM miembros_juntada WHERE id_juntada = ...)` en
`listar.php`/`obtener.php`. Esto es a proposito: al no duplicar el dato,
unirse o salir de una juntada nunca puede dejar ese contador
desactualizado — no hay nada que "actualizar", ya se recalcula solo en
cada lectura.

---

## Funciones, procedimientos y triggers

Estan definidos en `hincha_plus.sql`, en las secciones `2`, `3` y `4`.

### Funciones

- **`contar_miembros_juntada(p_id_juntada)`**: devuelve cuantos miembros
  tiene una juntada.
- **`juntada_tiene_cupo(p_id_juntada)`**: devuelve `1` si todavia hay
  lugar, `0` si no. La usan los triggers `trg_cerrar_juntada_llena` y
  `trg_reabrir_juntada_con_cupo`. *(Version corregida: antes calculaba
  mal el resultado cuando una juntada se quedaba sin ningun miembro, algo
  que recien podia pasar con la nueva funcionalidad de "salir".)*

### Procedimientos almacenados

- **`historial_chat_juntada(juntada_id)`**: trae todos los mensajes de
  una juntada con el nombre de cada usuario. No lo invoca ningun
  endpoint PHP (los endpoints hacen el `SELECT` directo), pero se puede
  probar a mano desde phpMyAdmin: `CALL historial_chat_juntada(1);`
- **`registrar_checkin(usuario_id, juntada_id)`**: marca presente al
  usuario y registra el hito de check-in. Tampoco lo invoca PHP
  (`juntadas/checkin.php` hace el equivalente con PDO para controlar la
  transaccion y la respuesta HTTP desde ahi), pero funciona igual desde
  phpMyAdmin: `CALL registrar_checkin(1, 1);`

### Triggers

| Trigger | Se dispara en | Que hace |
|---|---|---|
| `trg_cerrar_juntada_llena` | `AFTER INSERT ON miembros_juntada` | Si al unirse alguien la juntada llega al cupo maximo, la pasa a `estado = 'Cerrada'` sola |
| `trg_hito_nuevo_miembro` | `AFTER INSERT ON miembros_juntada` | Inserta un hito `'MiembroUnido'` en `hitos_transaccionales` cada vez que alguien se une |
| `trg_evitar_juntada_partido_pasado` | `BEFORE INSERT ON juntadas` | Bloquea la creacion de una juntada si el partido asociado ya se jugo (`SIGNAL SQLSTATE '45000'`) |
| `trg_proteger_organizador` | `BEFORE DELETE ON miembros_juntada` | Impide borrar la fila del organizador de `miembros_juntada` (protege tanto a `juntadas/salir.php` como a cualquier DELETE manual) |
| `trg_reabrir_juntada_con_cupo` | `AFTER DELETE ON miembros_juntada` | **Nuevo.** Si alguien abandona una juntada que estaba `'Cerrada'` por cupo lleno, la vuelve a poner `'Abierta'` en cuanto detecta lugar disponible |

> Los primeros dos triggers son los que reemplazan lo que antes hacia
> `juntadas/unirse.php` a mano en PHP (insertar el hito y cerrar la
> juntada). Se saco esa logica duplicada del PHP para que no queden
> filas repetidas en `hitos_transaccionales`.
>
> El hito de **abandonar** una juntada (`'MiembroSalio'`), en cambio, NO
> se agrego como un trigger `AFTER DELETE` equivalente a
> `trg_hito_nuevo_miembro`. Motivo: ese mismo DELETE tambien ocurre en
> cascada cuando se borra la juntada ENTERA (`juntadas/eliminar.php`), y
> un trigger generico generaria un hito enganoso de "abandono" en ese
> caso. Por eso ese hito puntual se inserta explicitamente desde
> `juntadas/salir.php`, solo cuando es un abandono voluntario real.

---

## Estructura del Proyecto

```
HINCHA+/
├── hincha_plus.sql                          <-- Importar esto en phpMyAdmin (con roles, funciones, procedimientos y 5 triggers)
├── backend/migracion_add_nombre_juntada.sql <-- Migracion 1: columna `nombre` en juntadas
├── backend/migracion_roles_y_bajas.sql      <-- Migracion 2: roles admin/user + salir/eliminar
├── DOCUMENTACION.docx
├── GUIA_EXPOSICION_HINCHA_PLUS.md           <-- Guia de estudio para defender el proyecto (triggers, preguntas tipicas, checklist)
├── MER_HINCHA_PLUS.drawio                   <-- Abrir en draw.io y exportar PNG
├── README.md
│
├── backend/                        <-- API REST en PHP con PDO (sin HTML)
│   ├── conexion.php                <-- Conexion PDO + headers CORS/UTF-8 + helpers JSON + esAdmin()
│   ├── auth/
│   │   ├── register.php            <-- Registro con password_hash(). Siempre rol='user'
│   │   └── login.php               <-- Login con password_verify(), devuelve el rol
│   ├── juntadas/
│   │   ├── listar.php
│   │   ├── obtener.php             <-- Una juntada puntual (usada por el Chat)
│   │   ├── crear.php               <-- Valida fecha del partido antes de insertar
│   │   ├── unirse.php              <-- El hito y el cierre por cupo lleno los hacen los triggers
│   │   ├── salir.php                <-- NUEVO: abandonar una juntada (bloqueado para el organizador)
│   │   ├── eliminar.php            <-- NUEVO: eliminar juntada (organizador o admin)
│   │   ├── checkin.php             <-- Transaccion PDO (update + hito)
│   │   └── mis_juntadas.php        <-- Juntadas de las que un usuario es miembro
│   ├── debates/
│   │   ├── listar.php              <-- Foros de club (LEFT JOIN equipos) + generales
│   │   ├── obtener.php             <-- Un foro puntual (usado por el Chat)
│   │   ├── crear.php               <-- Sin limite de 1 foro por club
│   │   └── eliminar.php            <-- NUEVO: eliminar foro (solo admin)
│   └── chat/
│       ├── obtener.php             <-- Misma consulta simple para foro o juntada
│       └── enviar.php              <-- Devuelve el mensaje ya armado con nombre y fecha
│
└── frontend/                       <-- React (100% del UI)
    ├── package.json                <-- Incluye lucide-react para los iconos
    ├── public/index.html
    └── src/
        ├── api.js                  <-- Fetch helper con try/catch (nunca deja el loading colgado)
        ├── App.js                  <-- Router + estado global
        ├── components/
        │   ├── Login.js            <-- Formulario de inicio de sesion
        │   ├── Register.js         <-- Formulario de registro (30 clubes)
        │   ├── Dashboard.js        <-- Vista principal con stats
        │   ├── Navbar.js           <-- Barra de navegacion
        │   ├── Juntadas.js         <-- Cards + crear/unir/salir/eliminar/check-in segun rol
        │   ├── Debates.js          <-- Listado de foros + crear + eliminar (solo admin)
        │   └── Chat.js             <-- Split-screen con sidebar, soporta juntadas y debates + acciones de moderacion
        └── styles/                 <-- CSS puro (tema deportivo oscuro/verde), con Bebas Neue en los titulos
```

---

## Solucion de Problemas

| Error | Causa | Solucion |
|-------|-------|----------|
| `Error de conexion` | MySQL no esta corriendo | Inicia MySQL desde el panel de XAMPP |
| `{"error":"JSON invalido"}` | Cuerpo vacio o malformado | Verifica que envies `Content-Type: application/json` |
| `CORS error / fetch failed` | Backend no accesible, o la carpeta en `htdocs` no se llama `hincha_plus` | Verifica que Apache este en puerto 80 y React en `localhost:3000`. Abri la URL del endpoint directo en el navegador (ej. `http://localhost/hincha_plus/backend/juntadas/listar.php`): si te devuelve un 404 o la pagina de error de Apache (en vez de JSON), el problema no es CORS en si, es que la carpeta esta mal ubicada o mal nombrada — Chrome muestra un error de CORS enganoso cuando el recurso ni siquiera existe |
| `404 Not Found` en la API | Ruta incorrecta | La carpeta `backend` debe estar en `C:\xampp\htdocs\hincha_plus\backend\` (el nombre debe ser exactamente `hincha_plus`, así lo tiene hardcodeado `frontend/src/api.js`) |
| `npm start` no funciona | Dependencias faltantes | Ejecuta `npm install` desde la carpeta `frontend/` (instala tambien `lucide-react`) |
| Registro falla con duplicado | DNI o email ya existe | Usa otros datos o revisa la tabla `usuarios` en phpMyAdmin |
| Las juntadas no cargan / vienen vacias | La tabla `juntadas` no tiene la columna `nombre`, o el script SQL se corto a la mitad al importarlo | Reimporta `hincha_plus.sql` completo, o corre `backend/migracion_add_nombre_juntada.sql` |
| El chat de una juntada o debate no carga nada | Estas en una version vieja del frontend que llamaba a endpoints que no existian (`juntadas/obtener.php`, `chat/listar.php`) | Actualiza `frontend/src/components/Chat.js` a la version actual del proyecto |
| No veo los botones de ELIMINAR aunque deberia ser admin | El `usuario` guardado en `localStorage` es de una sesion vieja, de antes de correr la migracion de roles | Cerra sesion y volve a loguearte (o `localStorage.removeItem('hincha_usuario')` desde la consola del navegador) para traer el `rol` actualizado |
| `Error al eliminar la juntada` / `Error al salir de la juntada` con 500 | Tu base todavia tiene la version vieja de `hitos_transaccionales` (con `id_juntada NOT NULL` + `ON DELETE CASCADE`) o la version vieja de `juntada_tiene_cupo()` | Corre `backend/migracion_roles_y_bajas.sql`, o reimporta `hincha_plus.sql` completo |
