import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { MessageCircle, MessagesSquare, Building2 } from 'lucide-react';
import Navbar from './Navbar';
import api from '../api';
import '../styles/Debates.css';

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

const CATEGORIAS_GENERALES = [
  'Seleccion Argentina',
  'Futbol Internacional',
  'Debates Generales',
  'Mercado de Pases'
];

function Debates({ usuario }) {
  const navigate = useNavigate();
  const [foros, setForos] = useState([]);
  const [mostrarForm, setMostrarForm] = useState(false);
  const [error, setError] = useState('');
  const [exito, setExito] = useState('');
  const [cargando, setCargando] = useState(false);

  // Se saca el fallback fijo a { id_usuario: 1 } por la misma razon
  // que en Juntadas.js: no queremos que, ante la ausencia de sesion,
  // el componente actue como si fuera un usuario real cualquiera.
  const usuarioLogueado = usuario || JSON.parse(localStorage.getItem('hincha_usuario') || 'null');

  useEffect(() => {
    if (!usuarioLogueado) {
      navigate('/login');
    }
  }, [usuarioLogueado, navigate]);

  const [form, setForm] = useState({
    tipo: 'Club',
    id_equipo: '',
    categoria_general: '',
    nombre_foro: '',
    descripcion: ''
  });

  const cargarForos = async () => {
    try {
      const res = await api.get('debates/listar.php');
      if (res.foros) setForos(res.foros);
    } catch (e) {
      setError('No se pudieron cargar los foros.');
    }
  };

  useEffect(() => {
    cargarForos();
  }, []);

  const manejarCambio = (e) => {
    setForm({ ...form, [e.target.name]: e.target.value });
  };

  const crearForo = async (e) => {
    e.preventDefault();
    setError('');
    setExito('');
    setCargando(true);

    const datos = {
      tipo: form.tipo,
      id_equipo: form.tipo === 'Club' ? parseInt(form.id_equipo) : null,
      categoria_general: form.tipo === 'General' ? form.categoria_general : null,
      nombre_foro: form.nombre_foro,
      descripcion: form.descripcion,
      id_usuario_creador: usuarioLogueado.id_usuario
    };

    try {
      const res = await api.post('debates/crear.php', datos);
      if (res.error) {
        setError(res.error);
      } else {
        setExito('¡Foro creado exitosamente!');
        setMostrarForm(false);
        setForm({ tipo: 'Club', id_equipo: '', categoria_general: '', nombre_foro: '', descripcion: '' });
        await cargarForos();
        setTimeout(() => setExito(''), 3000);
      }
    } catch (e) {
      setError('No se pudo conectar con el servidor. Intenta de nuevo.');
    } finally {
      setCargando(false);
    }
  };

  // Antes esto navegaba a /chat/:idForo, que es la ruta pensada
  // para JUNTADAS (tipo="juntada" por defecto). Eso hacia que el
  // chat tratara el id del foro como si fuera un id de juntada:
  // pedia juntadas/obtener.php con ese id (que no existe como
  // juntada) y el chat quedaba "colgado" sin cargar nada real.
  const irAlChat = (idForo) => {
    navigate(`/chat/debate/${idForo}`);
  };

  // Moderacion: solo admin puede borrar un foro entero. El backend
  // vuelve a validar esto mismo por su cuenta (esAdmin() contra la
  // base), este chequeo es unicamente para decidir que mostrar en
  // la UI.
  const eliminarForo = async (e, foro) => {
    e.stopPropagation();
    setError('');
    setExito('');
    const confirmacion = window.confirm(
      `¿Seguro que queres eliminar el foro "${foro.nombre_foro}"? Se van a borrar todos sus mensajes. Esta acción no se puede deshacer.`
    );
    if (!confirmacion) return;

    try {
      const res = await api.post('debates/eliminar.php', {
        id_foro: foro.id_foro,
        id_usuario: usuarioLogueado.id_usuario,
      });
      if (res.error) {
        setError(res.error);
        return;
      }
      setExito('Foro eliminado.');
      await cargarForos();
    } catch (e) {
      setError(e.message || 'No se pudo eliminar el foro.');
    }
  };

  if (!usuarioLogueado) {
    return null;
  }

  return (
    <div className="debates-pagina">
      <Navbar usuario={usuarioLogueado} onLogout={() => {
        localStorage.removeItem('hincha_usuario');
        window.location.href = '/login';
      }} />

      <main className="debates-contenido">
        <div className="debates-header">
          <div>
            <h1><MessageCircle size={26} /> Foros de Debate</h1>
            <p>Debate sobre tu club, los jugadores y las ultimas noticias</p>
          </div>
          <button className="btn-crear" onClick={() => setMostrarForm(!mostrarForm)}>
            {mostrarForm ? 'Cancelar' : '+ Nuevo Foro'}
          </button>
        </div>

        {error && <div className="alerta alerta-error">{error}</div>}
        {exito && <div className="alerta alerta-exito">{exito}</div>}

        {mostrarForm && (
          <form className="form-crear" onSubmit={crearForo}>
            <h3>Abrir Nuevo Foro de Debate</h3>

            <div className="campo-grupo">
              <label>TIPO DE FORO</label>
              <select name="tipo" value={form.tipo} onChange={manejarCambio} required>
                <option value="Club">De un club</option>
                <option value="General">General (sin club)</option>
              </select>
            </div>

            {form.tipo === 'Club' ? (
              <div className="campo-grupo">
                <label>EQUIPO / CLUB</label>
                <select
                  name="id_equipo"
                  value={form.id_equipo}
                  onChange={manejarCambio}
                  required
                >
                  <option value="">Selecciona el club</option>
                  {EQUIPOS_FIJOS.map((eq) => (
                    <option key={eq.id} value={eq.id}>{eq.nombre}</option>
                  ))}
                </select>
              </div>
            ) : (
              <div className="campo-grupo">
                <label>CATEGORIA</label>
                <select
                  name="categoria_general"
                  value={form.categoria_general}
                  onChange={manejarCambio}
                  required
                >
                  <option value="">Selecciona una categoria</option>
                  {CATEGORIAS_GENERALES.map((cat) => (
                    <option key={cat} value={cat}>{cat}</option>
                  ))}
                </select>
              </div>
            )}

            <div className="campo-grupo">
              <label>NOMBRE DEL FORO</label>
              <input
                type="text"
                name="nombre_foro"
                placeholder="Ej: Debate sobre el nuevo DT"
                value={form.nombre_foro}
                onChange={manejarCambio}
                required
              />
            </div>
            <div className="campo-grupo">
              <label>DESCRIPCION</label>
              <input
                type="text"
                name="descripcion"
                placeholder="Breve descripcion del tema a debatir"
                value={form.descripcion}
                onChange={manejarCambio}
              />
            </div>
            <button type="submit" className="btn-submit" disabled={cargando}>
              {cargando ? 'Creando...' : 'Crear Foro'}
            </button>
          </form>
        )}

        <div className="debates-grid">
          {foros.length === 0 ? (
            <div className="vacio-mensaje">
              <span><MessageCircle size={28} /></span>
              <p>No hay foros de debate creados aun. Abre el primero!</p>
            </div>
          ) : (
            foros.map((f) => (
              <div key={f.id_foro} className="debate-card">
                <div className="debate-card-top">
                  <div className="debate-equipo-badge">
                    {f.tipo === 'Club' ? f.nombre_club : f.categoria_general}
                  </div>
                  <span className="debate-mensajes">
                    {f.total_mensajes} mensajes
                  </span>
                </div>

                <h3 className="debate-titulo">{f.nombre_foro}</h3>
                <p className="debate-descripcion">
                  {f.descripcion || 'Sin descripcion'}
                </p>

                <div className="debate-card-footer">
                  <div className="debate-estadio">
                    {f.tipo === 'Club' ? (
                      <><Building2 size={13} /> {f.estadio}</>
                    ) : (
                      'Foro general'
                    )}
                  </div>
                  <div className="debate-card-acciones">
                    {usuarioLogueado.rol === 'admin' && (
                      <button
                        className="btn-eliminar-foro"
                        onClick={(e) => eliminarForo(e, f)}
                        title="Eliminar foro (solo administradores)"
                      >
                        Eliminar
                      </button>
                    )}
                    <button
                      className="btn-entrar-chat"
                      onClick={() => irAlChat(f.id_foro)}
                    >
                      <MessagesSquare size={14} /> Entrar al debate
                    </button>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      </main>
    </div>
  );
}

export default Debates;