'use client';

import React from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { Bell, Search, Menu } from 'lucide-react';

export default function Header() {
  const { user } = useAuth();

  return (
    <header className="bg-white border-b border-gray-200 h-16 flex items-center justify-between px-8 shadow-sm">
      <div className="flex items-center gap-4 flex-1">
        <button className="md:hidden text-gray-600 hover:text-gray-900">
          <Menu size={20} />
        </button>
        <div className="relative max-w-md w-full hidden md:block">
          <span className="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none text-gray-400">
            <Search size={18} />
          </span>
          <input
            type="text"
            placeholder="Buscar servicios, citas..."
            className="w-full pl-10 pr-4 py-2 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-rose-500/20 focus:border-rose-500 text-sm transition-all duration-200"
          />
        </div>
      </div>

      <div className="flex items-center gap-4">
        <button className="relative p-2 text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded-xl transition-all duration-200">
          <Bell size={20} />
          <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-rose-500 rounded-full"></span>
        </button>
        
        <div className="h-8 w-px bg-gray-200"></div>

        {user && (
          <div className="flex items-center gap-3">
            <div className="text-right">
              <p className="text-sm font-semibold text-gray-900">{user.nombre}</p>
              <p className="text-xs text-rose-500 font-medium capitalize">{user.rol.toLowerCase()}</p>
            </div>
            <div className="w-9 h-9 rounded-full bg-rose-100 flex items-center justify-center font-bold text-rose-500 border border-rose-200 shadow-sm">
              {user.nombre[0].toUpperCase()}
            </div>
          </div>
        )}
      </div>
    </header>
  );
}
