const API_BASE = 'http://localhost/plus_hincha/backend';

/**
 * Convierte la respuesta del fetch en JSON.
 * Si la respuesta HTTP no es exitosa (código 4xx o 5xx),
 * extrae el mensaje de error de PHP o lanza una excepción.
 */
async function procesarRespuesta(res) {
  let cuerpo;
  try {
    cuerpo = await res.json();
  } catch (e) {
    throw new Error('El servidor devolvió un error interno o una respuesta no válida.');
  }

  // Si la respuesta HTTP no es exitosa (status != 200-299)
  if (!res.ok) {
    throw new Error(cuerpo.error || `Error del servidor (${res.status})`);
  }

  return cuerpo;
}

const api = {
  get: async (ruta) => {
    const res = await fetch(`${API_BASE}/${ruta}`);
    return procesarRespuesta(res);
  },

  post: async (ruta, datos) => {
    const res = await fetch(`${API_BASE}/${ruta}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(datos),
    });
    return procesarRespuesta(res);
  },
};

export default api;