USE plus_hincha;

-- ============================================================
-- AMPLIACIÓN DE MIEMBROS PARA LAS JUNTADAS
-- (Necesario para que los usuarios puedan chatear en las juntadas)
-- ============================================================

INSERT IGNORE INTO miembros_juntada (id_usuario, id_juntada, estado_logistico) VALUES
-- Juntada 1: Banderazo en La 12
(4, 1, 'Presente'),
(5, 1, 'Pendiente'),
(7, 1, 'Pendiente'),

-- Juntada 2: Previa en el subte
(3, 2, 'Presente'),
(6, 2, 'Pendiente'),
(11, 2, 'Presente'),

-- Juntada 3: Previa Racing
(1, 3, 'Pendiente'),
(2, 3, 'Presente'),

-- Juntada 4: Juntada Avellaneda
(1, 4, 'Pendiente'),
(3, 4, 'Presente'),
(5, 4, 'Presente'),

-- Juntada 5: MundoLeon previa
(1, 5, 'Presente'),
(2, 5, 'Pendiente'),

-- Juntada 6: Cerveceria El Pincha
(8, 6, 'Presente'),
(12, 6, 'Pendiente'),

-- Juntada 9: Bar Monumental
(2, 9, 'Presente'),
(11, 9, 'Presente'),
(3, 9, 'Pendiente');

-- ============================================================
-- MENSAJES PARA LOS CHATS DE JUNTADAS
-- ============================================================

INSERT INTO mensajes_chat (id_usuario, id_juntada, id_foro, contenido_texto, enviado_at) VALUES
-- Juntada 1: Banderazo en La 12
(1, 1, NULL, '¡Buenas a todos! Les aviso que ya guardé una mesa grande al fondo del local.', '2026-09-22 13:00:00'),
(2, 1, NULL, 'De diez Martín. Voy en camino, llego con un par de bombos más.', '2026-09-22 13:05:00'),
(3, 1, NULL, '¿Alguien sabe si dejan entrar con banderas al bar?', '2026-09-22 13:10:00'),
(1, 1, NULL, 'Sí Pablo, hablé con el dueño y no hay drama con las banderas ni camisetas.', '2026-09-22 13:12:00'),
(4, 1, NULL, 'Buenísimo, yo salgo del trabajo a las 16:30 y me sumo directo.', '2026-09-22 13:15:00'),
(5, 1, NULL, 'Lleven efectivo por las dudas para agilizar las rondas de bebidas.', '2026-09-22 13:20:00'),

-- Juntada 2: Previa en el subte
(2, 2, NULL, 'Nos encontramos todos en la salida de los molinetes a las 15:00 hs.', '2026-09-22 13:30:00'),
(1, 2, NULL, 'Avisen cuando vayan llegando así nos agrupamos antes de salir a la calle.', '2026-09-22 13:35:00'),
(3, 2, NULL, 'Hay bastante congestión en la línea, salgan con tiempo gente.', '2026-09-22 13:40:00'),
(11, 2, NULL, '¡Ya estoy por acá abajo! Nos vemos al lado de la boletería.', '2026-09-22 13:45:00'),

-- Juntada 3: Previa Racing
(3, 3, NULL, 'Muchachos, la parrilla ya está prendida en el bar. ¿Quiénes faltan confirmar?', '2026-09-22 14:00:00'),
(4, 3, NULL, 'En 15 minutos estoy ahí con Mateo y los pibes de la filial.', '2026-09-22 14:05:00'),
(5, 3, NULL, '¡Tremendo! Reserven un par de choripanes para nosotros.', '2026-09-22 14:10:00'),
(2, 3, NULL, '¿Alguien trae los parlantes para poner algo de música antes de ir a la cancha?', '2026-09-22 14:15:00'),

-- Juntada 4: Juntada Avellaneda
(4, 4, NULL, 'Estamos en el centro de la plaza San Martín, cerca de la estatua principal.', '2026-09-22 14:20:00'),
(3, 4, NULL, 'Perfecto, llevo los trapos para la caravana.', '2026-09-22 14:25:00'),
(5, 4, NULL, 'Avisen a qué hora arrancamos a caminar hacia la cancha así no nos dispersamos.', '2026-09-22 14:30:00'),

-- Juntada 6: Cerveceria El Pincha
(7, 6, NULL, 'Bienvenidos a la juntada. La promo de picada y pinta está activa hasta las 18:00.', '2026-09-22 14:35:00'),
(8, 6, NULL, 'Buenísima data Santiago. Ya estamos en la mesa del patio.', '2026-09-22 14:40:00'),
(12, 6, NULL, 'Me sumo en media hora apenas termine una reunión. ¡Guarden lugar!', '2026-09-22 14:45:00'),

-- Juntada 9: Bar Monumental
(9, 9, NULL, '¡Hola a todos! Espectacular convocatoria hoy. Somos más de 30 confirmados.', '2026-09-22 14:50:00'),
(1, 9, NULL, 'El clima está bárbaro para estar afuera sobre la calle.', '2026-09-22 14:55:00'),
(2, 9, NULL, 'Totalmente. Salimos en caravana para el estadio a las 19:30 hs puntual.', '2026-09-22 15:00:00');

-- ============================================================
-- MENSAJES PARA LOS FOROS DE DEBATE
-- ============================================================

INSERT INTO mensajes_chat (id_usuario, id_foro, id_juntada, contenido_texto, enviado_at) VALUES
-- Foro 1: Foro Boca Juniors
(1, 1, NULL, 'Con el nuevo esquema táctico el equipo se ve más ordenado en el medio campo.', '2026-09-22 10:00:00'),
(2, 1, NULL, 'Coincido, pero nos falta ser más determinantes en los últimos metros para definir los partidos.', '2026-09-22 10:15:00'),
(3, 1, NULL, 'Para mí el punto alto viene siendo la defensa, no nos generaron casi situaciones el fin de semana.', '2026-09-22 10:30:00'),
(5, 1, NULL, 'Hay que bancar el proceso, los juveniles están respondiendo muy bien cada vez que entran.', '2026-09-22 10:45:00'),

-- Foro 2: Refuerzos que necesita Boca
(1, 2, NULL, 'Necesitamos urgente incorporar un extremo por izquierda con buena pegada.', '2026-09-22 11:00:00'),
(6, 2, NULL, 'También haría falta un volante central que tenga buen manejo de pelota y recuperación.', '2026-09-22 11:20:00'),
(2, 2, NULL, '¿Qué opinan de promover más pibes de la reserva antes de salir a gastar afuera?', '2026-09-22 11:35:00'),

-- Foro 3: Foro River Plate
(2, 3, NULL, 'La presión alta que está ejerciendo el equipo en la salida rival es la clave del momento.', '2026-09-22 11:40:00'),
(11, 3, NULL, 'El rendimiento de local viene siendo perfecto, da gusto ir a la cancha.', '2026-09-22 11:55:00'),
(3, 3, NULL, 'Totalmente, solo resta ajustar un poco la puntería en las pelotas paradas.', '2026-09-22 12:05:00'),

-- Foro 4: Foro Racing Club
(3, 4, NULL, 'Si ganamos los próximos dos clásicos quedamos muy bien posicionados arriba.', '2026-09-22 12:15:00'),
(4, 4, NULL, 'El equipo viene jugando con mucha intensidad desde el primer minuto.', '2026-09-22 12:25:00'),
(5, 4, NULL, 'Hay que cuidar las amarillas para no perder jugadores clave en la recta final.', '2026-09-22 12:35:00'),

-- Foro 11: Selección Argentina: convocatoria
(9, 11, NULL, 'Muy buena la lista para las eliminatorias, me alegra ver caras nuevas citadas.', '2026-09-22 12:40:00'),
(1, 11, NULL, 'Es fundamental ir haciendo el recambio generacional de a poco sin perder la idea de juego.', '2026-09-22 12:45:00'),
(10, 11, NULL, 'Coincido, además los muchachos que juegan en Europa vienen con un ritmo bárbaro.', '2026-09-22 12:50:00'),

-- Foro 12: Mercado de pases: rumores
(10, 12, NULL, 'Se habla de varios regresos importantes desde el exterior para el año que viene.', '2026-09-22 12:52:00'),
(8, 12, NULL, 'Ojalá los clubes argentinos puedan retener a las joyas jóvenes al menos un año más.', '2026-09-22 12:55:00'),
(12, 12, NULL, 'Los préstamos entre equipos locales también le van a dar mucho rodaje a varios pibes.', '2026-09-22 13:00:00');