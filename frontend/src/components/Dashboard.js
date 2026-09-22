import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { Trophy, MapPin, MessageCircle, Award } from 'lucide-react';
import Navbar from './Navbar';
import api from '../api';
import '../styles/Dashboard.css';

function Dashboard({ usuario, onLogout }) {
  const [juntadas, setJuntadas] = useState([]);
  const [foros, setForos] = useState([]);
  const [stats, setStats] = useState({ juntadas: 0, foros: 0 });

  useEffect(() => {
    const cargarDatos = async () => {
      try {
        const [resJuntadas, resForos] = await Promise.all([
          api.get('juntadas/listar.php'),
          api.get('debates/listar.php'),
        ]);

        if (resJuntadas.juntadas) {
          setJuntadas(resJuntadas.juntadas.slice(0, 3));
          setStats((prev) => ({ ...prev, juntadas: resJuntadas.juntadas.length }));
        }
        if (resForos.foros) {
          setForos(resForos.foros.slice(0, 3));
          setStats((prev) => ({ ...prev, foros: resForos.foros.length }));
        }
      } catch (e) {
        // Si falla la carga inicial, el dashboard simplemente
        // queda con las listas vacias en vez de romperse.
      }
    };
    cargarDatos();
  }, []);

  return (
    <div className="dashboard">
      <Navbar usuario={usuario} onLogout={onLogout} />

      <main className="dashboard-contenido">
        <section className="hero-bienvenida">
          <div className="hero-texto">
            <h1>
              HOLA, <span className="verde">{usuario.nombre?.split(' ')[0]?.toUpperCase()}</span>
            </h1>
            <p>Bienvenido a tu comunidad de hinchada. Conecta, debate y juntate con la gente.</p>
          </div>
          <div className="hero-icono"><Trophy size={48} /></div>
        </section>

        <section className="stats-fila">
          <div className="stat-card">
            <div className="stat-numero">{stats.juntadas}</div>
            <div className="stat-label">Juntadas Activas</div>
            <div className="stat-icono"><MapPin size={20} /></div>
          </div>
          <div className="stat-card">
            <div className="stat-numero">{stats.foros}</div>
            <div className="stat-label">Foros de Debate</div>
            <div className="stat-icono"><MessageCircle size={20} /></div>
          </div>
          <div className="stat-card">
            <div className="stat-numero">30</div>
            <div className="stat-label">Clubes</div>
            <div className="stat-icono"><Award size={20} /></div>
          </div>
        </section>

        <div className="dashboard-grid">
          <section className="dashboard-seccion">
            <div className="seccion-header">
              <h2><MapPin size={18} /> Juntadas Recientes</h2>
              <Link to="/juntadas" className="ver-todas">Ver todas &rarr;</Link>
            </div>
            <div className="seccion-lista">
              {juntadas.length === 0 ? (
                <p className="seccion-vacio">No hay juntadas creadas aun</p>
              ) : (
                juntadas.map((j) => (
                  <div key={j.id_juntada} className="mini-card">
                    <div className="mini-card-izq">
                      <span className={`badge badge-${j.estado?.toLowerCase()}`}>
                        {j.estado}
                      </span>
                    </div>
                    <div className="mini-card-centro">
                      <strong>{j.club_local} vs {j.club_visitante}</strong>
                      <span className="mini-organizador">Organiza: {j.nombre_organizador}</span>
                    </div>
                    <div className="mini-card-der">
                      <span className="mini-cupos">
                        {j.total_miembros}/{j.cupo_maximo}
                      </span>
                    </div>
                  </div>
                ))
              )}
            </div>
          </section>

          <section className="dashboard-seccion">
            <div className="seccion-header">
              <h2><MessageCircle size={18} /> Foros de Debate</h2>
              <Link to="/debates" className="ver-todas">Ver todos &rarr;</Link>
            </div>
            <div className="seccion-lista">
              {foros.length === 0 ? (
                <p className="seccion-vacio">No hay foros de debate aun</p>
              ) : (
                foros.map((f) => (
                  <div key={f.id_foro} className="mini-card">
                    <div className="mini-card-izq">
                      <span className="badge badge-foro"><MessageCircle size={14} /></span>
                    </div>
                    <div className="mini-card-centro">
                      <strong>{f.nombre_foro}</strong>
                      <span className="mini-organizador">{f.nombre_club || f.categoria_general}</span>
                    </div>
                    <div className="mini-card-der">
                      <span className="mini-cupos">{f.total_mensajes} msgs</span>
                    </div>
                  </div>
                ))
              )}
            </div>
          </section>
        </div>
      </main>
    </div>
  );
}

export default Dashboard;
