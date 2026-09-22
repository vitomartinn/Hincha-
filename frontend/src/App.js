import React, { useState } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import Login from './components/Login';
import Register from './components/Register';
import Dashboard from './components/Dashboard';
import Juntadas from './components/Juntadas';
import Debates from './components/Debates';
import Chat from './components/Chat';

function App() {
  const [usuario, setUsuario] = useState(() => {
    // Unificamos la clave a 'hincha_usuario'
    const guardado = localStorage.getItem('hincha_usuario');
    return guardado ? JSON.parse(guardado) : null;
  });

  const login = (datos) => {
    localStorage.setItem('hincha_usuario', JSON.stringify(datos));
    setUsuario(datos);
  };

  const logout = () => {
    localStorage.removeItem('hincha_usuario');
    setUsuario(null);
  };

  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={
          usuario ? <Navigate to="/" /> : <Login onLogin={login} />
        } />
        <Route path="/register" element={
          usuario ? <Navigate to="/" /> : <Register onRegister={() => {}} />
        } />
        <Route path="/" element={
          usuario ? <Dashboard usuario={usuario} onLogout={logout} /> : <Navigate to="/login" />
        } />
        
        {/* Rutas de Juntadas */}
        <Route path="/juntadas" element={
          usuario ? <Juntadas usuario={usuario} /> : <Navigate to="/login" />
        } />
        <Route path="/juntadas/:idJuntada" element={
          usuario ? <Juntadas usuario={usuario} /> : <Navigate to="/login" />
        } />

        {/* Rutas de Debates */}
        <Route path="/debates" element={
          usuario ? <Debates usuario={usuario} /> : <Navigate to="/login" />
        } />
        <Route path="/debates/:idDebate" element={
          usuario ? <Debates usuario={usuario} /> : <Navigate to="/login" />
        } />

        {/* Rutas de Chat (General, Juntadas y Debates) */}
        <Route path="/chat" element={
          usuario ? <Chat usuario={usuario} /> : <Navigate to="/login" />
        } />
        
        {/* Chat específico para Juntadas */}
        <Route path="/chat/juntada/:idJuntada" element={
          usuario ? <Chat usuario={usuario} tipo="juntada" /> : <Navigate to="/login" />
        } />

        {/* Chat específico para Debates / Foros */}
        <Route path="/chat/debate/:idDebate" element={
          usuario ? <Chat usuario={usuario} tipo="debate" /> : <Navigate to="/login" />
        } />

        {/* Fallback de compatibilidad */}
        <Route path="/chat/:idJuntada" element={
          usuario ? <Chat usuario={usuario} tipo="juntada" /> : <Navigate to="/login" />
        } />

        <Route path="*" element={<Navigate to="/" />} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;