import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import Navbar from './Navbar';
import api from '../api';
import '../styles/Juntadas.css';

export default function Juntadas({ usuario }) {
  const navigate = useNavigate();
  const [juntadas, setJuntadas] = useState([]);
  const [partidos, setPartidos] = useState([]);
  const [error, setError] = useState('');
  const [exito, setExito] = useState('');
  const [cargando, setCargando] = useState(false);
  const [mostrarForm, setMostrarForm] = useState(false);

  // Se saca el fallback fijo a { id_usuario: 1 }: si no hay usuario
  // logueado, no tiene que actuar "como si fuera" un usuario
  // cualquiera (eso es lo que podia hacer que una cuenta pareciera
  // unida a juntadas que en realidad unio otra persona). En vez de
  // eso, redirige al login.
  const usuarioLogueado = usuario || JSON.parse(localStorage.getItem('hincha_usuario') || 'null');

  useEffect(() => {
    if (!usuarioLogueado) {
      navigate('/login');
    }
  }, [usuarioLogueado, navigate]);

  const [form, setForm] = useState({
    nombre: '',
    id_partido: '',
    punto_encuentro_lat: '',
    punto_encuentro_lng: '',
    descripcion_punto: '',
    cupo_maximo: ''
  });

  // Set con los id_juntada a los que el usuario logueado ya esta
  // unido, para decidir por card si mostrar UNIRSE o SALIR.
  const [misJuntadasIds, setMisJuntadasIds] = useState(new Set());

  const cargarJuntadas = async () => {
    try {
      const res = await api.get('juntadas/listar.php');
      if (res.juntadas) {
        setJuntadas(res.juntadas);

        const mapaPartidos = new Map();
        res.juntadas.forEach((j) => {
          if (j.id_partido && !mapaPartidos.has(j.id_partido)) {
            mapaPartidos.set(j.id_partido, {
              id_partido: j.id_partido,
              club_local: j.club_local,
              club_visitante: j.club_visitante,
              estadio_sede: j.estadio_sede
            });
          }
        });
        setPartidos(Array.from(mapaPartidos.values()));
      }
    } catch (e) {
      setError('Error al obtener las juntadas.');
    }
  };

  const cargarMisJuntadas = async () => {
    try {
      const res = await api.get(`juntadas/mis_juntadas.php?id_usuario=${usuarioLogueado.id_usuario}`);
      const ids = new Set((res.juntadas || []).map((j) => j.id_juntada));
      setMisJuntadasIds(ids);
    } catch (e) {
      // No es critico: si falla, las cards simplemente vuelven a
      // mostrar UNIRSE (comportamiento previo) en vez de SALIR.
    }
  };

  useEffect(() => {
    cargarJuntadas();
    cargarMisJuntadas();
  }, []);

  const manejarCambio = (e) => {
    setForm({ ...form, [e.target.name]: e.target.value });
  };

  const unirseAJuntada = async (e, idJuntada) => {
    if (e) e.stopPropagation();
    setError('');
    setExito('');
    try {
      const res = await api.post('juntadas/unirse.php', {
        id_juntada: idJuntada,
        id_usuario: usuarioLogueado.id_usuario
      });

      if (res.error) {
        setError(res.error);
        return;
      }

      setExito('¡Te uniste a la juntada!');
      setMisJuntadasIds((prev) => new Set(prev).add(idJuntada));
      await cargarJuntadas();
      setTimeout(() => navigate(`/chat/juntada/${idJuntada}`), 500);
    } catch (e) {
      // "Ya te encuentras unido a esta juntada" llega como error HTTP
      // (409) y api.js lo convierte en excepcion con ese mensaje.
      // En ese caso puntual, igual lo llevamos al chat porque ya es
      // miembro; cualquier otro error se muestra tal cual.
      if (e.message && e.message.includes('Ya te encuentras unido')) {
        navigate(`/chat/juntada/${idJuntada}`);
      } else {
        setError(e.message || 'No se pudo conectar con el servidor. Intenta de nuevo.');
      }
    }
  };

  const irAChat = (e, idJuntada) => {
    e.stopPropagation();
    navigate(`/chat/juntada/${idJuntada}`);
  };

  const salirDeJuntada = async (e, idJuntada) => {
    if (e) e.stopPropagation();
    setError('');
    setExito('');
    try {
      const res = await api.post('juntadas/salir.php', {
        id_juntada: idJuntada,
        id_usuario: usuarioLogueado.id_usuario,
      });
      if (res.error) {
        setError(res.error);
        return;
      }
      setExito('Abandonaste la juntada.');
      setMisJuntadasIds((prev) => {
        const copia = new Set(prev);
        copia.delete(idJuntada);
        return copia;
      });
      await cargarJuntadas();
    } catch (e) {
      setError(e.message || 'No se pudo salir de la juntada.');
    }
  };

  // Visible solo si el usuario logueado es el organizador de ESTA
  // juntada puntual, o si es admin (moderacion). El backend vuelve
  // a validar este mismo permiso por su cuenta antes de borrar
  // nada: este chequeo del lado de React es solo para la UI.
  const puedeEliminarJuntada = (j) =>
    usuarioLogueado.rol === 'admin' || j.id_organizador === usuarioLogueado.id_usuario;

  const eliminarJuntada = async (e, j) => {
    if (e) e.stopPropagation();
    setError('');
    setExito('');
    const esPropia = j.id_organizador === usuarioLogueado.id_usuario;
    const confirmacion = window.confirm(
      esPropia
        ? `¿Seguro que queres eliminar tu juntada "${j.nombre}"? Esta acción no se puede deshacer.`
        : `Estas por eliminar la juntada "${j.nombre}" como administrador. ¿Continuar?`
    );
    if (!confirmacion) return;

    try {
      const res = await api.post('juntadas/eliminar.php', {
        id_juntada: j.id_juntada,
        id_usuario: usuarioLogueado.id_usuario,
      });
      if (res.error) {
        setError(res.error);
        return;
      }
      setExito('Juntada eliminada.');
      await cargarJuntadas();
    } catch (e) {
      setError(e.message || 'No se pudo eliminar la juntada.');
    }
  };

  const crearJuntada = async (e) => {
    e.preventDefault();
    setError('');
    setExito('');
    setCargando(true);

    const lat = parseFloat(form.punto_encuentro_lat);
    const lng = parseFloat(form.punto_encuentro_lng);

    if (isNaN(lat) || isNaN(lng)) {
      setError('Por favor ingresá coordenadas válidas.');
      setCargando(false);
      return;
    }

    const datos = {
      id_organizador: usuarioLogueado.id_usuario,
      nombre: form.nombre,
      id_partido: parseInt(form.id_partido, 10),
      punto_encuentro_lat: lat,
      punto_encuentro_lng: lng,
      descripcion_punto: form.descripcion_punto,
      cupo_maximo: parseInt(form.cupo_maximo, 10)
    };

    try {
      const res = await api.post('juntadas/crear.php', datos);
      if (res.error) {
        setError(res.error);
      } else {
        setExito('¡Juntada creada con éxito!');
        setMostrarForm(false);
        setForm({
          nombre: '',
          id_partido: '',
          punto_encuentro_lat: '',
          punto_encuentro_lng: '',
          descripcion_punto: '',
          cupo_maximo: ''
        });
        await cargarJuntadas();
        setTimeout(() => setExito(''), 3000);
      }
    } catch (e) {
      setError(e.message || 'Error al conectar con el servidor.');
    } finally {
      setCargando(false);
    }
  };

  const logout = () => {
    localStorage.removeItem('hincha_usuario');
    window.location.href = '/login';
  };

  if (!usuarioLogueado) {
    return null;
  }

  return (
    <div className="juntadas-pagina">
      <Navbar usuario={usuarioLogueado} onLogout={logout} />

      <div className="juntadas-contenido">
        <div className="juntadas-header">
          <div>
            <h1>JUNTADAS DE HINCHAS</h1>
            <p>Encontrá o creá un punto de encuentro previa al partido</p>
          </div>
          <button className="btn-crear" onClick={() => setMostrarForm(!mostrarForm)}>
            {mostrarForm ? 'CANCELAR' : 'CREAR JUNTADA'}
          </button>
        </div>

        {error && <div className="alerta alerta-error">{error}</div>}
        {exito && <div className="alerta alerta-exito">{exito}</div>}

        {mostrarForm && (
          <form className="form-crear" onSubmit={crearJuntada}>
            <h3>NUEVA JUNTADA</h3>
            <div className="form-grid">
              <div className="campo-grupo">
                <label>NOMBRE DE LA JUNTADA</label>
                <input
                  type="text"
                  name="nombre"
                  placeholder="Ej: BANDERAZO EN LA ESQUINA"
                  value={form.nombre}
                  onChange={manejarCambio}
                  required
                />
              </div>

              <div className="campo-grupo">
                <label>SELECCIONAR PARTIDO</label>
                <select
                  name="id_partido"
                  value={form.id_partido}
                  onChange={manejarCambio}
                  required
                >
                  <option value="">-- Selecciona un partido --</option>
                  {partidos.map((p) => (
                    <option key={p.id_partido} value={p.id_partido}>
                      {p.club_local} vs {p.club_visitante} ({p.estadio_sede})
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div className="campo-grupo" style={{ marginBottom: '16px' }}>
              <label>PUNTO DE ENCUENTRO (DESCRIPCIÓN)</label>
              <input
                type="text"
                name="descripcion_punto"
                placeholder="Ej: Esquina Avenida Brandsen y Warnes - Bar La 12"
                value={form.descripcion_punto}
                onChange={manejarCambio}
                required
              />
            </div>

            <div className="form-grid">
              <div className="campo-grupo">
                <label>LATITUD</label>
                <input
                  type="number"
                  step="any"
                  name="punto_encuentro_lat"
                  placeholder="-34.6357"
                  value={form.punto_encuentro_lat}
                  onChange={manejarCambio}
                  required
                />
              </div>

              <div className="campo-grupo">
                <label>LONGITUD</label>
                <input
                  type="number"
                  step="any"
                  name="punto_encuentro_lng"
                  placeholder="-58.3649"
                  value={form.punto_encuentro_lng}
                  onChange={manejarCambio}
                  required
                />
              </div>
            </div>

            <div className="campo-grupo" style={{ marginBottom: '16px' }}>
              <label>CUPO MÁXIMO DE PERSONAS</label>
              <input
                type="number"
                name="cupo_maximo"
                placeholder="Ej: 20"
                value={form.cupo_maximo}
                onChange={manejarCambio}
                required
              />
            </div>

            <button type="submit" className="btn-submit" disabled={cargando}>
              {cargando ? 'PUBLICANDO...' : 'PUBLICAR JUNTADA'}
            </button>
          </form>
        )}

        <div className="juntadas-grid">
          {juntadas.length === 0 ? (
            <div className="vacio-mensaje">
              <span>⚽</span>
              <p>No hay juntadas activas disponibles.</p>
            </div>
          ) : (
            juntadas.map((j) => {
              const porcentajeCupo = Math.min(100, Math.round((j.total_miembros / j.cupo_maximo) * 100));

              return (
                <div
                  key={j.id_juntada}
                  className="juntada-card"
                >
                  <div className="juntada-card-header">
                    <span className="juntada-fecha">
                      {j.fecha_partido ? new Date(j.fecha_partido).toLocaleDateString('es-AR') : 'Próximamente'}
                    </span>
                  </div>

                  <div className="juntada-partido">
                    {j.nombre || `${j.club_local} vs ${j.club_visitante}`}
                  </div>

                  <div className="juntada-detalles">
                    <div className="detalle">
                      <span className="detalle-icono">📍</span>
                      <span>{j.descripcion_punto}</span>
                    </div>
                    <div className="detalle">
                      <span className="detalle-icono">🏟️</span>
                      <span>{j.club_local} vs {j.club_visitante} ({j.estadio_sede})</span>
                    </div>
                    <div className="detalle">
                      <span className="detalle-icono">👤</span>
                      <span>Organiza: {j.nombre_organizador}</span>
                    </div>
                  </div>

                  <div className="juntada-footer">
                    <div className="cupo-barra">
                      <div className="cupo-texto">
                        Cupo: {j.total_miembros} / {j.cupo_maximo} miembros
                      </div>
                      <div className="cupo-progreso">
                        <div className="cupo-relleno" style={{ width: `${porcentajeCupo}%` }}></div>
                      </div>
                    </div>

                    <div className="juntada-botones">
                      {j.id_organizador === usuarioLogueado.id_usuario ? (
                        // El organizador ya esta "adentro" de su propia
                        // juntada: no tiene sentido mostrarle UNIRSE ni
                        // SALIR (esto ultimo esta bloqueado por el
                        // trigger trg_proteger_organizador de todas formas).
                        <span className="juntada-rol-badge">SOS EL ORGANIZADOR</span>
                      ) : misJuntadasIds.has(j.id_juntada) ? (
                        <button className="btn-salir" onClick={(e) => salirDeJuntada(e, j.id_juntada)}>
                          SALIR
                        </button>
                      ) : (
                        <button className="btn-unirse" onClick={(e) => unirseAJuntada(e, j.id_juntada)}>
                          UNIRSE
                        </button>
                      )}
                      <button className="btn-chat-juntada" onClick={(e) => irAChat(e, j.id_juntada)}>
                        CHAT
                      </button>
                      {puedeEliminarJuntada(j) && (
                        <button className="btn-eliminar" onClick={(e) => eliminarJuntada(e, j)}>
                          ELIMINAR
                        </button>
                      )}
                    </div>
                  </div>
                </div>
              );
            })
          )}
        </div>
      </div>
    </div>
  );
}