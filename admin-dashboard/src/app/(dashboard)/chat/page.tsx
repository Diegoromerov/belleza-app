'use client';

import React, { useState } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { MessageSquare, Send, User, Sparkles, CheckCheck } from 'lucide-react';

export default function ChatPage() {
  const { user } = useAuth();
  const [messages, setMessages] = useState([
    { id: '1', sender: 'Aura IA', text: '¡Hola! Soy Aura, tu asistente de IA en GlowApp. ¿En qué te puedo ayudar hoy?', time: '10:00 AM', isMe: false },
    { id: '2', sender: 'Soporte Concierge', text: 'Bienvenido al Centro de Mensajes. Tu cuenta está verificada y activa.', time: '10:02 AM', isMe: false }
  ]);
  const [inputText, setInputText] = useState('');

  const handleSendMessage = (e: React.FormEvent) => {
    e.preventDefault();
    if (!inputText.trim()) return;

    const newMsg = {
      id: Date.now().toString(),
      sender: user?.nombre || 'Usuario',
      text: inputText,
      time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      isMe: true
    };

    setMessages((prev) => [...prev, newMsg]);
    setInputText('');

    // Simulated reply
    setTimeout(() => {
      setMessages((prev) => [
        ...prev,
        {
          id: (Date.now() + 1).toString(),
          sender: 'Aura IA',
          text: 'Gracias por escribir. Hemos recibido tu mensaje y nuestro equipo de Concierge se encuentra atendiendo tu solicitud en tiempo real.',
          time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
          isMe: false
        }
      ]);
    }, 1000);
  };

  return (
    <div className="space-y-6 max-w-5xl mx-auto h-[calc(100vh-140px)] flex flex-col">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-3xl font-extrabold text-gray-900 tracking-tight">Centro de Mensajes</h2>
          <p className="text-gray-500 mt-1">Canal directo de chat con Soporte Concierge y Asistente Aura IA</p>
        </div>
      </div>

      <div className="flex-1 bg-white rounded-2xl shadow-sm border border-gray-200/80 flex flex-col overflow-hidden">
        {/* Header Chat */}
        <div className="p-4 bg-gray-50 border-b border-gray-200/80 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-gradient-to-tr from-rose-500 to-pink-500 flex items-center justify-center text-white font-bold shadow-sm">
              <Sparkles size={20} />
            </div>
            <div>
              <h3 className="font-bold text-gray-900 text-sm">Soporte Concierge & Aura IA</h3>
              <p className="text-xs text-emerald-600 font-semibold flex items-center gap-1">
                <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span> En línea 24/7
              </p>
            </div>
          </div>
        </div>

        {/* Message Container */}
        <div className="flex-1 p-6 overflow-y-auto space-y-4 bg-gray-50/30">
          {messages.map((m) => (
            <div key={m.id} className={`flex flex-col ${m.isMe ? 'items-end' : 'items-start'}`}>
              <span className="text-[11px] font-semibold text-gray-400 mb-1 px-1">{m.sender} • {m.time}</span>
              <div className={`max-w-md p-4 rounded-2xl text-sm ${
                m.isMe
                  ? 'bg-rose-500 text-white rounded-tr-none shadow-sm'
                  : 'bg-white text-gray-800 border border-gray-200/80 rounded-tl-none shadow-sm'
              }`}>
                {m.text}
              </div>
            </div>
          ))}
        </div>

        {/* Input Form */}
        <form onSubmit={handleSendMessage} className="p-4 bg-white border-t border-gray-200/80 flex gap-3">
          <input
            type="text"
            placeholder="Escribe un mensaje para soporte o Aura..."
            value={inputText}
            onChange={(e) => setInputText(e.target.value)}
            className="flex-1 px-4 py-3 text-sm bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-rose-500/20 focus:border-rose-500"
          />
          <button
            type="submit"
            disabled={!inputText.trim()}
            className="px-5 py-3 bg-rose-500 hover:bg-rose-600 disabled:opacity-50 text-white font-bold rounded-xl transition-all flex items-center gap-2"
          >
            <Send size={18} />
          </button>
        </form>
      </div>
    </div>
  );
}
