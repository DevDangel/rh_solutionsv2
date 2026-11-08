"use client";

import React, { useEffect, useState } from "react";
import { createPortal } from "react-dom";
import { X } from "lucide-react";

interface LogoutModalProps {
  abierto: boolean;
  cerrando: boolean;
  onCancelar: () => void;
  onConfirmar: () => void;
}

export default function LogoutModal({
  abierto,
  cerrando,
  onCancelar,
  onConfirmar,
}: LogoutModalProps) {
  const [montado, setMontado] = useState(false);

  useEffect(() => {
    setMontado(true);
  }, []);

  if (!montado || !abierto) return null;

  return createPortal(
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/55 p-4">
      <div className="w-full max-w-[500px] rounded-[8px] bg-white shadow-2xl overflow-hidden">
        <div className="flex items-center justify-between px-5 py-4 border-b border-gray-200">
          <h5 className="text-[18px] font-medium text-[#212529]">
            ¿Seguro que deseas salir?
          </h5>
          <button
            type="button"
            disabled={cerrando}
            onClick={onCancelar}
            className="text-gray-500 hover:text-black cursor-pointer"
            aria-label="Cerrar"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <div className="px-5 py-4 text-[16px] text-[#212529]">
          Selecciona &ldquo;Cerrar sesión&rdquo; si estás listo para finalizar tu sesión actual.
        </div>

        <div className="flex items-center justify-end gap-2 px-5 py-3 border-t border-gray-200">
          <button
            type="button"
            disabled={cerrando}
            onClick={onCancelar}
            className="rounded-[6px] bg-[#02024D] hover:bg-[#06042e] px-4 py-2 text-[15px] text-white transition cursor-pointer disabled:opacity-50"
          >
            Cancelar
          </button>
          <button
            type="button"
            disabled={cerrando}
            onClick={onConfirmar}
            className="rounded-[6px] bg-[#dc3545] hover:bg-[#bb2d3b] px-4 py-2 text-[15px] text-white transition cursor-pointer disabled:opacity-50"
          >
            {cerrando ? "Cerrando..." : "Cerrar sesión"}
          </button>
        </div>
      </div>
    </div>,
    document.body
  );
}
