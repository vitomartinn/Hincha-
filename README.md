# HINCHA+ - Tu Comunidad Futbolera

Plataforma web para que los hinchas de clubes argentinos organicen juntadas previas a los partidos, debatan sobre su equipo y se comuniquen en tiempo real.

**Stack**: PHP (API REST) + React + MySQL

---

## Requisitos

- [XAMPP](https://www.apachefriends.org/) con Apache y MySQL activos
- [Node.js](https://nodejs.org/) v16+ con npm
- [draw.io](https://app.diagrams.net/) (opcional, para el diagrama MER)

---

## Instalacion Rapida

### 1. Base de Datos

Abri phpMyAdmin (`http://localhost/phpmyadmin`) y hace esto:

1. **Crear base**: Click en "Nueva" > Nombre: `hincha_plus` > Cotejamiento: `utf8mb4_general_ci` > Crear
2. **Importar el SQL**: Click en la pestana "Importar" > Seleccionar archivo > Elegi `hincha_plus_completo.sql` > Continuar

Eso crea todas las tablas, relaciones, funciones, procedimientos almacenados y datos de ejemplo (12 equipos, 12 usuarios, 12 partidos, etc.).

> Si preferis hacerlo paso a paso, abri la pestana "SQL" de phpMyAdmin y pega el contenido de `hincha_plus_completo.sql` en bloques.

### 2. Backend (PHP)

1. Copia toda la carpeta `backend/` dentro de `C:\xampp\htdocs\HINCHA+\`
   ```
   C:\xampp\htdocs\HINCHA+\backend\
   C:\xampp\htdocs\HINCHA+\backend\conexion.php
   C:\xampp\htdocs\HINCHA+\backend\auth\...
   ```
2. Asegurate de que Apache este **iniciado** en el panel de XAMPP
3. Verificá que funcione abriendo en el navegador:
   ```
   http://localhost/HINCHA+/backend/juntadas/listar.php
   ```
   Deberia mostrar: `{"juntadas":[...]}` con los datos de ejemplo

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
| 1 | Registrate con un DNI, nombre, email, password y selecciona un equipo |
| 2 | Inicia sesion con esas credenciales |
| 3 | Desde el Dashboard, anda a **Juntadas** y crea una nueva (necesitas el ID de un partido, usa `1`) |
| 4 | Unite a esa juntada y hace **Check-In** |
| 5 | Andá a **Debates**, crea un foro para tu equipo |
| 6 | Andá al **Chat**, selecciona el foro o la juntada y envia mensajes |
| 7 | Abrí phpMyAdmin y verifica que los registros aparecen en las tablas |

---

## Endpoints de la API

Todos los archivos PHP estan en `backend/` y devuelven JSON puro.

| Endpoint | Metodo | Que hace |
|----------|--------|----------|
| `auth/register.php` | POST | Registra un usuario nuevo (DNI, nombre, email, password, equipo) |
| `auth/login.php` | POST | Valida credenciales y devuelve los datos del usuario |
| `juntadas/listar.php` | GET | Devuelve todas las juntadas con datos del partido y equipo |
| `juntadas/crear.php` | POST | Crea una juntada nueva (organizador, partido, coordenadas, cupo) |
| `juntadas/unirse.php` | POST | Suma un usuario a una juntada (estado: Pendiente) |
| `juntadas/checkin.php` | POST | Ejecuta `CALL registrar_checkin()` y registra el hito |
| `debates/listar.php` | GET | Lista todos los foros de debate con el club y cantidad de mensajes |
| `debates/crear.php` | POST | Crea un foro nuevo para un equipo |
| `chat/obtener.php` | GET | Historial de mensajes (usa SP para juntadas, SELECT para foros) |
| `chat/enviar.php` | POST | Envia un mensaje a un foro O una juntada (nunca a ambos) |

**Ejemplo de peticion** (register):
```json
POST /HINCHA+/backend/auth/register.php
{
  "dni": "40123456",
  "nombre": "Martin Gonzalez",
  "email": "martin@mail.com",
  "password": "123456",
  "id_equipo": 1
}
```

---

## Estructura del Proyecto

```
HINCHA+/
├── hincha_plus_completo.sql        <-- Importar esto en phpMyAdmin
├── DOCUMENTACION_ACADEMICA.md
├── DOCUMENTACION_ACADEMICA.docx    <-- Listo para Word
├── MER_HINCHA_PLUS.drawio          <-- Abrir en draw.io y exportar PNG
├── README.md
│
├── backend/                        <-- API REST en PHP (sin HTML)
│   ├── conexion.php                <-- Conexion mysqli + headers CORS
│   ├── auth/
│   │   ├── register.php            <-- Registro con password_hash()
│   │   └── login.php               <-- Login con password_verify()
│   ├── juntadas/
│   │   ├── listar.php
│   │   ├── crear.php
│   │   ├── unirse.php
│   │   └── checkin.php             <-- Usa CALL registrar_checkin()
│   ├── debates/
│   │   ├── listar.php
│   │   └── crear.php
│   └── chat/
│       ├── obtener.php             <-- Usa CALL historial_chat_juntada()
│       └── enviar.php
│
└── frontend/                       <-- React (100% del UI)
    ├── package.json
    ├── public/index.html
    └── src/
        ├── api.js                  <-- Fetch helper hacia el backend
        ├── App.js                  <-- Router + estado global
        ├── components/
        │   ├── Login.js            <-- Formulario de inicio de sesion
        │   ├── Register.js         <-- Formulario de registro
        │   ├── Dashboard.js        <-- Vista principal con stats
        │   ├── Navbar.js           <-- Barra de navegacion
        │   ├── Juntadas.js         <-- Cards de juntadas + crear/unir/check-in
        │   ├── Debates.js          <-- Listado de foros
        │   └── Chat.js             <-- Split-screen con sidebar y burbujas
        └── styles/                 <-- CSS puro (tema deportivo oscuro/verde)
```

---

## Solucion de Problemas

| Error | Causa | Solucion |
|-------|-------|----------|
| `Error de conexion a BD` | MySQL no esta corriendo | Inicia MySQL desde el panel de XAMPP |
| `{"error":"JSON invalido"}` | Cuerpo vacio o malformado | Verifica que envies Content-Type: application/json |
| `CORS error / fetch failed` | Backend no accesible | Verifica que Apache este en puerto 80 y React en localhost:3000 |
| `404 Not Found` en la API | Ruta incorrecta | La carpeta `backend` debe estar en `C:\xampp\htdocs\HINCHA+\backend\` |
| `npm start` no funciona | Dependencias faltantes | Ejecuta `npm install` desde la carpeta `frontend/` |
| Procedimiento no encontrado | SP no creado | Importa el SQL completo o crea los SP desde phpMyAdmin > Procedimientos |
| Registro falla con duplicado | DNI o email ya existe | Usa otros datos o revisa la tabla `usuarios` en phpMyAdmin |
