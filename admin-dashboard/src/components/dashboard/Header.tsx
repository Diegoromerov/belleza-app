'use client';

import React from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { Bell, Search, Menu } from 'lucide-react';

export default function Header() {
  const { user } = useAuth();

  return (
    <header className="bg-white/90 backdrop-blur-md border-b border-[#C5A052]/20 h-16 flex items-center justify-between px-8 shadow-sm shadow-[#2B2420]/5 sticky top-0 z-10">
      <div className="flex items-center gap-4 flex-1">
        <button className="md:hidden text-[#2B2420] hover:text-[#C5A052]">
          <Menu size={20} />
        </button>
        <div className="relative max-w-md w-full hidden md:block">
          <span className="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none text-[#8C6F65]">
            <Search size={18} />
          </span>
          <input
            type="text"
            placeholder="Buscar servicios, precios, auditoría..."
            className="w-full pl-10 pr-4 py-2 border border-[#C5A052]/30 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#C5A052]/20 focus:border-[#C5A052] text-sm transition-all duration-200 text-[#2B2420] bg-[#FAF8F5]"
          />
        </div>
      </div>

      <div className="flex items-center gap-4">
        <button className="relative p-2 text-[#2B2420] hover:text-[#C5A052] hover:bg-[#FAF8F5] rounded-xl transition-all duration-200">
          <Bell size={20} />
          <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-[#C5A052] rounded-full"></span>
        </button>
        
        <div className="h-8 w-px bg-[#C5A052]/20"></div>

        {user && (
          <div className="flex items-center gap-3">
            <div className="text-right">
              <p className="text-sm font-semibold text-[#2B2420] font-sans">{user.nombre}</p>
              <p className="text-xs text-[#C5A052] font-semibold uppercase tracking-wide font-mono">{user.rol}</p>
            </div>
            <div className="w-9 h-9 rounded-full bg-[#2B2420] text-[#C5A052] border border-[#C5A052]/40 flex items-center justify-center font-bold text-sm shadow-sm font-serif">
              {user.nombre[0].toUpperCase()}
            </div>
          </div>
        )}
      </div>
    </header>
  );
}
