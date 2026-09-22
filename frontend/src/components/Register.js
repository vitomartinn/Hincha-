import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Trophy } from 'lucide-react';
import api from '../api';
import '../styles/Register.css';

// Los 30 clubes de la Primera Division de la Liga Profesional
// Argentina. El orden y los id coinciden con los que inserta
// hincha_plus.sql en la tabla "equipos".
const EQUIPOS_FIJOS = [
  { id: 1,  nombre: 'Aldosivi' },
  { id: 2,  nombre: 'Argentinos Juniors' },
  { id: 3,  nombre: 'Atletico Tucuman' },
  { id: 4,  nombre: 'Banfield' },
  { id: 5,  nombre: 'Barracas Central' },
  { id: 6,  nombre: 'Belgrano' },
  { id: 7,  nombre: 'Boca Juniors' },
  { id: 8,  nombre: 'Central Cordoba (SdE)' },
  { id: 9,  nombre: 'Defensa y Justicia' },
  { id: 10, nombre: 'Deportivo Riestra' },
  { id: 11, nombre: 'Estudiantes (LP)' },
  { id: 12, nombre: 'Estudiantes (RC)' },
  { id: 13, nombre: 'Gimnasia y Esgrima (LP)' },
  { id: 14, nombre: 'Gimnasia y Esgrima (M)' },
  { id: 15, nombre: 'Huracan' },
  { id: 16, nombre: 'Independiente' },
  { id: 17, nombre: 'Independiente Rivadavia' },
  { id: 18, nombre: 'Instituto' },
  { id: 19, nombre: 'Lanus' },
  { id: 20, nombre: "Newell's Old Boys" },
  { id: 21, nombre: 'Platense' },
  { id: 22, nombre: 'Racing Club' },
  { id: 23, nombre: 'River Plate' },
  { id: 24, nombre: 'Rosario Central' },
  { id: 25, nombre: 'San Lorenzo' },
  { id: 26, nombre: 'Sarmiento (J)' },
  { id: 27, nombre: 'Talleres (C)' },
  { id: 28, nombre: 'Tigre' },
  { id: 29, nombre: 'Union' },
  { id: 30, nombre: 'Velez Sarsfield' },
];

function Register() {
  const navigate = useNavigate();
  const [form, setForm] = useState({
    dni: '', nombre: '', email: '', password: '', id_equipo: ''
  });
  const [error, setError] = useState('');
  const [exito, setExito] = useState(false);
  const [cargando, setCargando] = useState(false);

  const manejarCambio = (e) => {
    setForm({ ...form, [e.target.name]: e.target.value });
  };

  const manejarSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setExito(false);

    if (!form.dni || !form.nombre || !form.email || !form.password || !form.id_equipo) {
      setError('Todos los campos son obligatorios');
      return;
    }

    setCargando(true);

    const datosEnviar = {
      ...form,
      id_equipo: parseInt(form.id_equipo),
    };

    try {
      const respuesta = await api.post('auth/register.php', datosEnviar);
      if (respuesta.error) {
        setError(respuesta.error);
      } else {
        setExito(true);
        setTimeout(() => navigate('/login'), 2000);
      }
    } catch (e) {
      setError('No se pudo conectar con el servidor. Intenta de nuevo.');
    } finally {
      setCargando(false);
    }
  };

  return (
    <div className="register-contenedor">
      <div className="register-fondo-campo"></div>
      <div className="register-card">
        <div className="register-logo">
          <span className="logo-icono"><Trophy size={32} /></span>
          <h1>UNITE A <span className="verde">HINCHA+</span></h1>
          <p className="register-subtitulo">Crea tu cuenta y conecta con tu gente</p>
        </div>

        <form onSubmit={manejarSubmit} className="register-form">
          {error && <div className="register-error">{error}</div>}
          {exito && (
            <div className="register-exito">
              Registro exitoso! Redirigiendo al login...
            </div>
          )}

          <div className="register-fila">
            <div className="campo-grupo">
              <label>DNI</label>
              <input
                type="text"
                name="dni"
                placeholder="12345678"
                value={form.dni}
                onChange={manejarCambio}
                required
              />
            </div>
            <div className="campo-grupo">
              <label>NOMBRE</label>
              <input
                type="text"
                name="nombre"
                placeholder="Tu nombre completo"
                value={form.nombre}
                onChange={manejarCambio}
                required
              />
            </div>
          </div>

          <div className="campo-grupo">
            <label>EMAIL</label>
            <input
              type="email"
              name="email"
              placeholder="tu@email.com"
              value={form.email}
              onChange={manejarCambio}
              required
            />
          </div>

          <div className="campo-grupo">
            <label>PASSWORD</label>
            <input
              type="password"
              name="password"
              placeholder="Minimo 6 caracteres"
              value={form.password}
              onChange={manejarCambio}
              required
              minLength="6"
            />
          </div>

          <div className="campo-grupo">
            <label>TU EQUIPO</label>
            <select
              name="id_equipo"
              value={form.id_equipo}
              onChange={manejarCambio}
              required
            >
              <option value="">Selecciona tu club</option>
              {EQUIPOS_FIJOS.map((eq) => (
                <option key={eq.id} value={eq.id}>
                  {eq.nombre}
                </option>
              ))}
            </select>
          </div>

          <button type="submit" className="btn-register" disabled={cargando || exito}>
            {cargando ? 'REGISTRANDO...' : 'CREAR CUENTA'}
          </button>
        </form>

        <div className="register-footer">
          <p>
            Ya tenes cuenta?{' '}
            <Link to="/login" className="link-login">
              Inicia sesion
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
}

export default Register;
