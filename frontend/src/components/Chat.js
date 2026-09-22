import React, { useState, useEffect, useCallback } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import Navbar from './Navbar';
import api from '../api';
import '../styles/Chat.css';

export default function Chat({ usuario, tipo: tipoProp }) {
  // Las 3 rutas posibles apuntan a este mismo componente, pero cada
  // una define el parametro de la URL con un nombre distinto
  // (idJuntada / idDebate). Por eso hay que leer los dos y quedarnos
  // con el que exista.
  const { idJuntada: idJuntadaParam, idDebate: idDebateParam } = useParams();
  const navigate = useNavigate();

  // Si entramos por /chat/debate/:idDebate el tipo es "debate".
  // Si entramos por /chat/juntada/:idJuntada, /chat/:idJuntada o
  // /chat (sin id) el tipo es "juntada" (comportamiento por defecto).
  const tipo = tipoProp || (idDebateParam ? 'debate' : 'juntada');
  const idActual = tipo === 'debate' ? idDebateParam : idJuntadaParam;

  const [misJuntadas, setMisJuntadas] = useState([]);
  const [juntadaActual, setJuntadaActual] = useState(null);
  const [foroActual, setForoActual] = useState(null);
  const [mensajes, setMensajes] = useState([]);
  const [nuevoMensaje, setNuevoMensaje] = useState('');
  const [esMiembro, setEsMiembro] = useState(false);
  const [cargando, setCargando] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!usuario) {
      navigate('/login');
    }
  }, [usuario, navigate]);

  // ---- Carga de mensajes (sirve para juntada y para debate) ----
  const cargarMensajes = useCallback(async (params) => {
    const query = params.id_juntada
      ? `id_juntada=${params.id_juntada}`
      : `id_foro=${params.id_foro}`;
    const res = await api.get(`chat/obtener.php?${query}`);
    setMensajes(res.mensajes || []);
  }, []);

  // ---- Carga del chat de una JUNTADA puntual ----
  const cargarChatJuntada = useCallback(async (id, juntadasUsuario) => {
    try {
      setError('');
      const pertenece = juntadasUsuario.some((j) => String(j.id_juntada) === String(id));
      setEsMiembro(pertenece);

      const resJuntada = await api.get(`juntadas/obtener.php?id=${id}`);
      setJuntadaActual(resJuntada.juntada || null);

      await cargarMensajes({ id_juntada: id });
    } catch (e) {
      setError('No se pudo cargar esta juntada. Puede que ya no exista.');
      setJuntadaActual(null);
      setMensajes([]);
    }
  }, [cargarMensajes]);

  // ---- Carga del chat de un DEBATE/FORO puntual ----
  // Los foros son de acceso libre: cualquier hincha logueado puede
  // leer y escribir, no hace falta "unirse" como en las juntadas.
  const cargarChatDebate = useCallback(async (id) => {
    try {
      setError('');
      const resForo = await api.get(`debates/obtener.php?id=${id}`);
      setForoActual(resForo.foro || null);

      await cargarMensajes({ id_foro: id });
    } catch (e) {
      setError('No se pudo cargar este foro. Puede que ya no exista.');
      setForoActual(null);
      setMensajes([]);
    }
  }, [cargarMensajes]);

  useEffect(() => {
    if (!usuario) return;

    const iniciar = async () => {
      setCargando(true);
      setJuntadaActual(null);
      setForoActual(null);

      try {
        const res = await api.get(`juntadas/mis_juntadas.php?id_usuario=${usuario.id_usuario}`);
        const juntadasUsuario = res.juntadas || [];
        setMisJuntadas(juntadasUsuario);

        if (tipo === 'debate') {
          if (idActual) {
            await cargarChatDebate(idActual);
          }
        } else {
          const idACargar = idActual || (juntadasUsuario.length > 0 ? juntadasUsuario[0].id_juntada : null);
          if (idACargar) {
            await cargarChatJuntada(idACargar, juntadasUsuario);
          }
        }
      } catch (e) {
        console.error('Error al iniciar el chat', e);
      } finally {
        setCargando(false);
      }
    };

    iniciar();
  }, [idActual, tipo, usuario, cargarChatDebate, cargarChatJuntada]);

  const enviarMensaje = async (e) => {
    e.preventDefault();
    const texto = nuevoMensaje.trim();
    if (!texto) return;
    if (tipo === 'juntada' && (!esMiembro || !juntadaActual)) return;
    if (tipo === 'debate' && !foroActual) return;

    try {
      const payload = {
        id_usuario: usuario.id_usuario,
        contenido_texto: texto,
      };
      if (tipo === 'debate') {
        payload.id_foro = foroActual.id_foro;
      } else {
        payload.id_juntada = juntadaActual.id_juntada;
      }

      const res = await api.post('chat/enviar.php', payload);

      if (res.exito && res.mensaje) {
        setMensajes((prev) => [...prev, res.mensaje]);
        setNuevoMensaje('');
      }
    } catch (e) {
      setError(e.message || 'No se pudo enviar el mensaje.');
    }
  };

  // Unirse a la juntada actual SOLO afecta al usuario logueado:
  // el backend guarda la fila en miembros_juntada con su
  // id_usuario puntual, asi que nadie mas queda unido de rebote.
  const unirseAJuntadaActual = async () => {
    if (!juntadaActual) return;
    try {
      const res = await api.post('juntadas/unirse.php', {
        id_juntada: juntadaActual.id_juntada,
        id_usuario: usuario.id_usuario,
      });

      if (!res.error) {
        setEsMiembro(true);
        setMisJuntadas((prev) => [...prev, juntadaActual]);
        await cargarMensajes({ id_juntada: juntadaActual.id_juntada });
      } else {
        setError(res.error);
      }
    } catch (e) {
      setError(e.message || 'No se pudo completar la union a la juntada.');
    }
  };

  // Abandonar la juntada actual desde el propio chat. El organizador
  // no puede salir (el backend + el trigger trg_proteger_organizador
  // lo bloquean); para el, en cambio, se ofrece ELIMINAR.
  const salirDeJuntadaActual = async () => {
    if (!juntadaActual) return;
    const confirmacion = window.confirm('¿Seguro que queres salir de esta juntada?');
    if (!confirmacion) return;
    try {
      const res = await api.post('juntadas/salir.php', {
        id_juntada: juntadaActual.id_juntada,
        id_usuario: usuario.id_usuario,
      });
      if (res.error) {
        setError(res.error);
        return;
      }
      navigate('/juntadas');
    } catch (e) {
      setError(e.message || 'No se pudo salir de la juntada.');
    }
  };

  // Eliminar la juntada actual: solo el organizador o un admin ven
  // este boton (chequeo de UI); el backend vuelve a validar el
  // permiso por su cuenta antes de borrar nada.
  const eliminarJuntadaActual = async () => {
    if (!juntadaActual) return;
    const confirmacion = window.confirm(
      `¿Seguro que queres eliminar la juntada "${juntadaActual.nombre}"? Esta acción no se puede deshacer.`
    );
    if (!confirmacion) return;
    try {
      const res = await api.post('juntadas/eliminar.php', {
        id_juntada: juntadaActual.id_juntada,
        id_usuario: usuario.id_usuario,
      });
      if (res.error) {
        setError(res.error);
        return;
      }
      navigate('/juntadas');
    } catch (e) {
      setError(e.message || 'No se pudo eliminar la juntada.');
    }
  };

  // Eliminar el foro actual: solo admin. Mismo patron que arriba.
  const eliminarForoActual = async () => {
    if (!foroActual) return;
    const confirmacion = window.confirm(
      `¿Seguro que queres eliminar el foro "${foroActual.nombre_foro}"? Se van a borrar todos sus mensajes.`
    );
    if (!confirmacion) return;
    try {
      const res = await api.post('debates/eliminar.php', {
        id_foro: foroActual.id_foro,
        id_usuario: usuario.id_usuario,
      });
      if (res.error) {
        setError(res.error);
        return;
      }
      navigate('/debates');
    } catch (e) {
      setError(e.message || 'No se pudo eliminar el foro.');
    }
  };

  const logout = () => {
    localStorage.removeItem('hincha_usuario');
    window.location.href = '/login';
  };

  if (!usuario) {
    return null;
  }

  if (cargando) {
    return (
      <div className="chat-pagina">
        <Navbar usuario={usuario} onLogout={logout} />
        <div className="chat-cargando">Cargando chats...</div>
      </div>
    );
  }

  const elementoActual = tipo === 'debate' ? foroActual : juntadaActual;
  const tituloActual = tipo === 'debate'
    ? foroActual?.nombre_foro
    : (juntadaActual?.nombre || (juntadaActual ? `${juntadaActual.club_local} vs ${juntadaActual.club_visitante}` : ''));
  const subtituloActual = tipo === 'debate'
    ? (foroActual?.descripcion || 'Foro de debate')
    : (juntadaActual?.descripcion_punto || 'Punto de encuentro');
  const puedeEscribir = tipo === 'debate' ? true : esMiembro;

  return (
    <div className="chat-pagina">
      <Navbar usuario={usuario} onLogout={logout} />

      {tipo === 'juntada' && misJuntadas.length === 0 && !idActual ? (
        <div className="chat-vacio-contenedor">
          <h2>⚠️ NO ESTÁS UNIDO A NINGUNA JUNTADA</h2>
          <p>Para participar en los chats de juntadas debés unirte a una juntada activa.</p>
          <button onClick={() => navigate('/juntadas')} className="btn-explorar">
            EXPLORAR JUNTADAS
          </button>
        </div>
      ) : (
        <div className="chat-layout">
          {/* PANEL LATERAL: siempre muestra las juntadas del usuario */}
          <div className="chat-sidebar">
            <div className="sidebar-seccion">
              <h3>MIS JUNTADAS</h3>
              {misJuntadas.length === 0 ? (
                <p className="sidebar-vacio">Todavía no te uniste a ninguna juntada.</p>
              ) : (
                misJuntadas.map((j) => {
                  const esActivo = tipo === 'juntada' && String(juntadaActual?.id_juntada) === String(j.id_juntada);
                  return (
                    <div
                      key={j.id_juntada}
                      className={`sidebar-item ${esActivo ? 'activo' : ''}`}
                      onClick={() => navigate(`/chat/juntada/${j.id_juntada}`)}
                    >
                      <div className="sidebar-item-icono">⚽</div>
                      <div className="sidebar-item-texto">
                        <strong>{j.nombre || `${j.club_local} vs ${j.club_visitante}`}</strong>
                        <span>✓ Miembro activo</span>
                      </div>
                    </div>
                  );
                })
              )}
            </div>
          </div>

          {/* ÁREA DE CHAT PRINCIPAL */}
          <div className="chat-principal">
            {error && <div className="alerta alerta-error">{error}</div>}

            {elementoActual ? (
              <>
                <div className="chat-header-bar">
                  <span className="chat-header-tipo">{tipo === 'debate' ? '🗣️' : '💬'}</span>
                  <div className="chat-header-info">
                    <h2>{tituloActual}</h2>
                    <span className="chat-header-sub">{subtituloActual}</span>
                  </div>

                  {tipo === 'juntada' && !esMiembro && (
                    <button onClick={unirseAJuntadaActual} className="btn-enviar">
                      UNIRSE
                    </button>
                  )}

                  {tipo === 'juntada' && esMiembro && juntadaActual?.id_organizador !== usuario.id_usuario && (
                    <button onClick={salirDeJuntadaActual} className="btn-salir-chat">
                      SALIR
                    </button>
                  )}

                  {tipo === 'juntada' && (usuario.rol === 'admin' || juntadaActual?.id_organizador === usuario.id_usuario) && (
                    <button onClick={eliminarJuntadaActual} className="btn-eliminar-chat">
                      ELIMINAR
                    </button>
                  )}

                  {tipo === 'debate' && usuario.rol === 'admin' && (
                    <button onClick={eliminarForoActual} className="btn-eliminar-chat">
                      ELIMINAR FORO
                    </button>
                  )}

                  {(tipo === 'debate' || esMiembro) && (
                    <button
                      className="btn-refrescar"
                      title="Actualizar mensajes"
                      onClick={() => (tipo === 'debate'
                        ? cargarChatDebate(foroActual.id_foro)
                        : cargarChatJuntada(juntadaActual.id_juntada, misJuntadas))}
                    >
                      ↻
                    </button>
                  )}
                </div>

                <div className="chat-mensajes">
                  {mensajes.length === 0 ? (
                    <div className="chat-vacio">
                      <span>💬</span>
                      <p>Sé el primero en escribir un mensaje acá.</p>
                    </div>
                  ) : (
                    mensajes.map((m, index) => {
                      const esMio = m.id_usuario === usuario.id_usuario;
                      const inicial = m.nombre_usuario ? m.nombre_usuario.charAt(0).toUpperCase() : '?';

                      return (
                        <div key={m.id_mensaje || index} className={`mensaje burbuja ${esMio ? 'propio' : 'ajeno'}`}>
                          <div className="mensaje-avatar">{inicial}</div>
                          <div className="mensaje-bloque">
                            <span className="mensaje-nombre">{m.nombre_usuario || 'Hincha'}</span>
                            <div className="mensaje-contenido">{m.contenido_texto}</div>
                            {m.enviado_at && (
                              <span className="mensaje-hora">
                                {new Date(m.enviado_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                              </span>
                            )}
                          </div>
                        </div>
                      );
                    })
                  )}
                </div>

                <form onSubmit={enviarMensaje} className="chat-input-area">
                  <input
                    type="text"
                    value={nuevoMensaje}
                    onChange={(e) => setNuevoMensaje(e.target.value)}
                    placeholder={
                      puedeEscribir
                        ? 'Escribe tu mensaje...'
                        : 'Debes unirte a la juntada para poder enviar mensajes.'
                    }
                    disabled={!puedeEscribir}
                  />
                  <button type="submit" className="btn-enviar" disabled={!puedeEscribir || !nuevoMensaje.trim()}>
                    ENVIAR
                  </button>
                </form>
              </>
            ) : (
              <div className="chat-vacio">
                <span>🏟️</span>
                <p>Selecciona una juntada del menú lateral para ver el chat.</p>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
