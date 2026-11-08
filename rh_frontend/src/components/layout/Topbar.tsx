"use client";

import React, { useEffect, useRef, useState } from "react";
import { Bell, ChevronDown, LogOut, Menu } from "lucide-react";
import type { UsuarioSesion } from "@/types/auth";

interface TopbarProps {
  usuario: UsuarioSesion;
  onAbrirSidebarMovil: () => void;
  onSolicitarLogout: () => void;
}

export default function Topbar({
  usuario,
  onAbrirSidebarMovil,
  onSolicitarLogout,
}: TopbarProps) {
  const [menuNotificacionesAbierto, setMenuNotificacionesAbierto] = useState(false);
  const [menuUsuarioAbierto, setMenuUsuarioAbierto] = useState(false);
  const contenedorRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    const manejarClickFuera = (e: MouseEvent) => {
      if (contenedorRef.current && !contenedorRef.current.contains(e.target as Node)) {
        setMenuNotificacionesAbierto(false);
        setMenuUsuarioAbierto(false);
      }
    };
    document.addEventListener("mousedown", manejarClickFuera);
    return () => document.removeEventListener("mousedown", manejarClickFuera);
  }, []);

  const nombreCompleto = `${usuario.primer_nombre} ${usuario.primer_apellido}`.trim();

  return (
    <header className="fixed top-0 left-0 lg:left-[300px] right-0 h-[70px] bg-white border-b border-[#dee2e6] shadow-sm z-30 flex items-center justify-between lg:justify-end px-4 sm:px-6">
      <button
        type="button"
        onClick={onAbrirSidebarMovil}
        className="lg:hidden inline-flex items-center justify-center rounded-[5px] bg-[#02024D] p-2.5 text-white shadow-md cursor-pointer"
        aria-label="Abrir menú lateral"
      >
        <Menu className="h-5 w-5" />
      </button>

      <div ref={contenedorRef} className="flex items-center gap-5 ml-auto">
        {/* Campana de notificaciones */}
        <div className="relative">
          <button
            type="button"
            onClick={() => {
              setMenuNotificacionesAbierto((prev) => !prev);
              setMenuUsuarioAbierto(false);
            }}
            className="relative p-2 text-gray-600 hover:text-[#02024D] transition-colors cursor-pointer"
            aria-label="Notificaciones"
          >
            <Bell className="h-5 w-5" />
          </button>

          {menuNotificacionesAbierto && (
            <div className="absolute right-0 mt-2 w-[300px] max-h-[400px] overflow-y-auto rounded-[8px] bg-white shadow-lg border border-gray-200 z-50">
              <div className="px-4 py-2.5 text-[13px] font-semibold text-gray-500 border-b border-gray-100">
                Notificaciones
              </div>
              <div className="px-4 py-4 text-center text-[14px] text-gray-500">
                Sin notificaciones
              </div>
            </div>
          )}
        </div>

        {/* Menú de usuario */}
        <div className="relative">
          <button
            type="button"
            onClick={() => {
              setMenuUsuarioAbierto((prev) => !prev);
              setMenuNotificacionesAbierto(false);
            }}
            className="flex items-center gap-2.5 text-gray-700 hover:text-[#02024D] cursor-pointer"
          >
            <span className="hidden sm:inline text-[14px] text-[#6c757d]">
              {nombreCompleto}
            </span>
            <img
              src="/imgs/default.jpg"
              alt="Foto de perfil"
              className="h-[40px] w-[40px] rounded-full object-cover border border-gray-200"
            />
            <ChevronDown className="h-4 w-4 text-gray-500" />
          </button>

          {menuUsuarioAbierto && (
            <div className="absolute right-0 mt-2 w-[200px] rounded-[8px] bg-white shadow-lg border border-gray-200 py-1.5 z-50">
              <div className="px-4 py-2 text-[13px] font-medium text-gray-700 border-b border-gray-100 sm:hidden">
                {nombreCompleto}
              </div>
              <button
                type="button"
                onClick={() => {
                  setMenuUsuarioAbierto(false);
                  onSolicitarLogout();
                }}
                className="flex w-full items-center gap-2 px-4 py-2 text-[14px] text-gray-700 hover:bg-gray-100 cursor-pointer"
              >
                <LogOut className="h-4 w-4 text-gray-500" />
                <span>Cerrar sesión</span>
              </button>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
