"use client";

import React, { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { useAuthStore } from "@/stores/authStore";
import Sidebar from "./Sidebar";
import Topbar from "./Topbar";
import LogoutModal from "./LogoutModal";

interface DashboardShellProps {
  rolEsperado: "admin" | "empleado";
  children?: React.ReactNode;
}

export default function DashboardShell({ rolEsperado, children }: DashboardShellProps) {
  const router = useRouter();
  const { usuario, cargandoSesion, rehidratarSesion, cerrarSesion } = useAuthStore();

  const [verificado, setVerificado] = useState(false);
  const [sidebarMovilAbierto, setSidebarMovilAbierto] = useState(false);
  const [modalLogoutAbierto, setModalLogoutAbierto] = useState(false);
  const [cerrandoSesion, setCerrandoSesion] = useState(false);

  useEffect(() => {
    let activo = true;

    const verificarAcceso = async () => {
      const sesionActual = usuario ?? (await rehidratarSesion());
      if (!activo) return;

      if (!sesionActual) {
        router.replace("/login");
        return;
      }

      const esAdmin = sesionActual.id_rol === 1;
      if (rolEsperado === "admin" && !esAdmin) {
        router.replace("/empleado/dashboard");
        return;
      }

      if (rolEsperado === "empleado" && esAdmin) {
        router.replace("/admin/dashboard");
        return;
      }

      setVerificado(true);
    };

    void verificarAcceso();
    return () => {
      activo = false;
    };
  }, [rolEsperado, router, rehidratarSesion, usuario]);

  const manejarConfirmarLogout = async () => {
    setCerrandoSesion(true);
    try {
      await cerrarSesion();
      router.replace("/login");
    } finally {
      setCerrandoSesion(false);
      setModalLogoutAbierto(false);
    }
  };

  if (cargandoSesion || !verificado || !usuario) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[#f8f9fa]">
        <div className="flex flex-col items-center gap-3">
          <div className="h-10 w-10 animate-spin rounded-full border-4 border-[#000050] border-t-transparent" />
          <p className="text-[14px] font-medium text-[#02024D]">Verificando sesión...</p>
        </div>
      </div>
    );
  }

  const rutaInicio = rolEsperado === "admin" ? "/admin/dashboard" : "/empleado/dashboard";

  return (
    <div className="min-h-screen bg-[#f8f9fa]">
      <Sidebar
        rutaInicio={rutaInicio}
        abiertoMovil={sidebarMovilAbierto}
        onCerrarMovil={() => setSidebarMovilAbierto(false)}
        onSolicitarLogout={() => setModalLogoutAbierto(true)}
      />

      <Topbar
        usuario={usuario}
        onAbrirSidebarMovil={() => setSidebarMovilAbierto(true)}
        onSolicitarLogout={() => setModalLogoutAbierto(true)}
      />

      <main className="lg:ml-[300px] mt-[70px] p-[20px] sm:p-[30px] min-h-[calc(100vh-70px)] bg-[#f8f9fa]">
        {children ?? (
          <div className="w-full flex items-center justify-center">
            <img
              src="/imgs/rh19.png"
              alt="RH Solutions"
              className="w-full p-[10%] object-contain"
            />
          </div>
        )}
      </main>

      <LogoutModal
        abierto={modalLogoutAbierto}
        cerrando={cerrandoSesion}
        onCancelar={() => setModalLogoutAbierto(false)}
        onConfirmar={() => void manejarConfirmarLogout()}
      />
    </div>
  );
}
