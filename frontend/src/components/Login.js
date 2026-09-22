import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { Trophy } from 'lucide-react';
import api from '../api';
import '../styles/Login.css';

function Login({ onLogin }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [cargando, setCargando] = useState(false);

  const manejarSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setCargando(true);

    try {
      const respuesta = await api.post('auth/login.php', { email, password });
      if (respuesta.error) {
        setError(respuesta.error);
      } else {
        onLogin(respuesta.usuario);
      }
    } catch (e) {
      setError('No se pudo conectar con el servidor. Intenta de nuevo.');
    } finally {
      // El finally garantiza que el boton siempre vuelva a
      // habilitarse, haya salido bien o mal la peticion.
      setCargando(false);
    }
  };

  return (
    <div className="login-contenedor">
      <div className="login-fondo-campo"></div>
      <div className="login-card">
        <div className="login-logo">
          <span className="logo-icono"><Trophy size={32} /></span>
          <h1>HINCHA<span className="verde">+</span></h1>
          <p className="login-subtitulo">Tu comunidad futbolera</p>
        </div>

        <form onSubmit={manejarSubmit} className="login-form">
          {error && <div className="login-error">{error}</div>}

          <div className="campo-grupo">
            <label>EMAIL</label>
            <input
              type="email"
              placeholder="tu@email.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </div>

          <div className="campo-grupo">
            <label>PASSWORD</label>
            <input
              type="password"
              placeholder="Minimo 6 caracteres"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              minLength="6"
            />
          </div>

          <button type="submit" className="btn-login" disabled={cargando}>
            {cargando ? 'INGRESANDO...' : 'INICIAR SESION'}
          </button>
        </form>

        <div className="login-footer">
          <p>
            No tenes cuenta?{' '}
            <Link to="/register" className="link-registro">
              Registrate gratis
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
}

export default Login;
