import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { Trophy, Home, MapPin, MessageCircle, MessagesSquare, LogOut } from 'lucide-react';
import '../styles/Navbar.css';

function Navbar({ usuario, onLogout }) {
  const ubicacion = useLocation();

  const esActiva = (ruta) => ubicacion.pathname === ruta ? 'nav-link activo' : 'nav-link';

  // Obtener nombre o usar valor por defecto si usuario es null/undefined
  const nombreUsuario = usuario?.nombre || usuario?.nombre_usuario || 'Hincha';
  const inicial = nombreUsuario.charAt(0).toUpperCase();

  return (
    <nav className="navbar">
      <div className="navbar-izquierda">
        <Link to="/" className="navbar-brand">
          <span className="brand-icono"><Trophy size={20} /></span>
          <span className="brand-texto">HINCHA<span className="verde">+</span></span>
        </Link>
      </div>

      <div className="navbar-centro">
        <Link to="/" className={esActiva('/')}>
          <span className="nav-icono"><Home size={16} /></span>
          Inicio
        </Link>
        <Link to="/juntadas" className={esActiva('/juntadas')}>
          <span className="nav-icono"><MapPin size={16} /></span>
          Juntadas
        </Link>
        <Link to="/debates" className={esActiva('/debates')}>
          <span className="nav-icono"><MessageCircle size={16} /></span>
          Debates
        </Link>
        <Link to="/chat" className={esActiva('/chat')}>
          <span className="nav-icono"><MessagesSquare size={16} /></span>
          Chat
        </Link>
      </div>

      <div className="navbar-derecha">
        <div className="usuario-info">
          <div className="avatar-circulo">
            {inicial}
          </div>
          <span className="usuario-nombre">{nombreUsuario}</span>
        </div>
        {onLogout && (
          <button onClick={onLogout} className="btn-logout">
            <LogOut size={14} /> Salir
          </button>
        )}
      </div>
    </nav>
  );
}

export default Navbar;