"use client";

import React from "react";
import Link from "next/link";
import { Home, LogOut, X } from "lucide-react";

interface SidebarProps {
  rutaInicio: string;
  abiertoMovil: boolean;
  onCerrarMovil: () => void;
  onSolicitarLogout: () => void;
}

export default function Sidebar({
  rutaInicio,
  abiertoMovil,
  onCerrarMovil,
  onSolicitarLogout,
}: SidebarProps) {
  return (
    <>
      {abiertoMovil && (
        <div
          className="fixed inset-0 z-40 bg-black/50 lg:hidden"
          onClick={onCerrarMovil}
          aria-hidden="true"
        />
      )}

      <aside
        className={`fixed top-0 left-0 z-50 h-screen w-[280px] sm:w-[300px] bg-[#000050] text-white pt-[20px] flex flex-col justify-between overflow-y-auto transition-transform duration-300 ease-in-out ${
          abiertoMovil ? "translate-x-0" : "-translate-x-full lg:translate-x-0"
        }`}
      >
        <div>
          <div className="relative text-center mb-[20px] px-4">
            <img
              src="/imgs/rh18.png"
              alt="RH Solutions"
              className="mx-auto max-w-[90%] h-[75px] rounded-[12px] object-contain"
            />
            <button
              type="button"
              onClick={onCerrarMovil}
              className="absolute right-4 top-2 text-white/80 hover:text-white lg:hidden cursor-pointer"
              aria-label="Cerrar menú lateral"
            >
              <X className="h-6 w-6" />
            </button>
          </div>

          <nav className="flex flex-col">
            <Link
              href={rutaInicio}
              onClick={onCerrarMovil}
              className="flex items-center gap-[10px] px-[20px] py-[12px] text-[16px] text-white bg-[#02024D] hover:bg-[#02024D] border-l-4 border-white/80 transition-colors"
            >
              <Home className="h-5 w-5 shrink-0" />
              <span>Inicio</span>
            </Link>

            <button
              type="button"
              onClick={() => {
                onCerrarMovil();
                onSolicitarLogout();
              }}
              className="flex items-center gap-[10px] px-[20px] py-[12px] text-[16px] text-white hover:bg-[#02024D] text-left transition-colors cursor-pointer w-full"
            >
              <LogOut className="h-5 w-5 shrink-0" />
              <span>Cerrar sesión</span>
            </button>
          </nav>
        </div>

        <div className="px-[20px] py-[15px] text-[12px] text-white/50">
          RH Solutions
        </div>
      </aside>
    </>
  );
}
