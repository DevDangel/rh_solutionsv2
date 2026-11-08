"use client";

import React, { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Eye, EyeOff } from "lucide-react";
import { api, type ApiResponse } from "@/services/api";
import { useAuthStore } from "@/stores/authStore";
import type { LoginResponseData, VerifyOtpResponseData } from "@/types/auth";
import OtpLoginModal from "./OtpLoginModal";

export default function LoginForm() {
  const router = useRouter();
  const { usuario, setUsuario, rehidratarSesion } = useAuthStore();

  const [docUsuario, setDocUsuario] = useState("");
  const [password, setPassword] = useState("");
  const [mostrarPassword, setMostrarPassword] = useState(false);
  const [mostrarIconoOjo, setMostrarIconoOjo] = useState(false);
  const [cargando, setCargando] = useState(false);
  const [mensajeError, setMensajeError] = useState<string | null>(null);

  const [modalOtpAbierto, setModalOtpAbierto] = useState(false);
  const [correoEnmascarado, setCorreoEnmascarado] = useState("");

  useEffect(() => {
    let activo = true;
    const verificarSesionActiva = async () => {
      const sesion = usuario ?? (await rehidratarSesion());
      if (!activo || !sesion) return;
      router.replace(sesion.id_rol === 1 ? "/admin/dashboard" : "/empleado/dashboard");
    };
    void verificarSesionActiva();
    return () => {
      activo = false;
    };
  }, [rehidratarSesion, router, usuario]);

  const manejarCambioDocumento = (e: React.ChangeEvent<HTMLInputElement>) => {
    const soloNumeros = e.target.value.replace(/\D/g, "").slice(0, 10);
    setDocUsuario(soloNumeros);
  };

  const manejarCambioPassword = (e: React.ChangeEvent<HTMLInputElement>) => {
    const valor = e.target.value;
    setPassword(valor);
    setMostrarIconoOjo(valor.length > 0);
  };

  const manejarSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setMensajeError(null);

    if (docUsuario.length < 7 || docUsuario.length > 10) {
      setMensajeError("El número de documento debe contener entre 7 y 10 dígitos.");
      return;
    }

    setCargando(true);
    try {
      const respuesta = await api.post<LoginResponseData>("/api/v1/auth/login/", {
        doc_usuario: docUsuario,
        password,
      });

      const datos = respuesta.data;
      if (!datos) {
        setMensajeError("Respuesta inesperada del servidor.");
        return;
      }

      if (datos.requires_otp) {
        setCorreoEnmascarado(datos.email_masked || "correo...");
        setModalOtpAbierto(true);
        return;
      }

      if (datos.user) {
        setUsuario(datos.user);
      }
      router.replace(datos.redirect_to || "/empleado/dashboard");
    } catch (err) {
      const errorApi = err as ApiResponse;
      setMensajeError(errorApi?.message || "Usuario o contraseña incorrecta");
    } finally {
      setCargando(false);
    }
  };

  const manejarCancelarOtp = async () => {
    setModalOtpAbierto(false);
    try {
      await api.post("/api/v1/auth/otp/cancelar/");
    } catch {
      // Limpieza silenciosa de sesión pre-login
    }
  };

  const manejarOtpVerificado = (datos: VerifyOtpResponseData) => {
    setUsuario(datos.user);
    setTimeout(() => {
      setModalOtpAbierto(false);
      router.replace(datos.redirect_to || "/admin/dashboard");
    }, 800);
  };

  return (
    <div className="flex min-h-screen relative overflow-x-hidden">
      {/* Mitad izquierda: Formulario (#f4f6fc) */}
      <div className="w-full lg:w-1/2 flex justify-center items-center bg-[#f4f6fc] p-[20px] relative z-10">
        <div className="bg-[#f4f6fc] p-[20px] sm:p-[30px] lg:p-[40px] rounded-[8px] w-full max-w-[450px]">
          <img
            src="/imgs/rh19.png"
            alt="RH Solutions"
            className="w-[120px] sm:w-[150px] mb-[5px] h-auto"
          />
          <h3 className="text-left mb-[50px] text-[16px] font-medium text-[#333333]">
            TU SOFTWARE DE RECURSOS HUMANOS
          </h3>

          <form onSubmit={manejarSubmit}>
            <div>
              <label htmlFor="exampleInputCedula" className="text-[16px] text-black mb-[5px] block">
                Usuario
              </label>
              <input
                id="exampleInputCedula"
                name="doc_usuario"
                type="text"
                inputMode="numeric"
                required
                pattern="^[0-9]{7,10}$"
                title="El número debe contener entre 7 y 10 dígitos."
                placeholder="Ingrese el usuario"
                value={docUsuario}
                onChange={manejarCambioDocumento}
                className="h-[40px] border border-[#cccccc] rounded-[8px] bg-[#02024D] hover:bg-[#06042e] focus:bg-[#06042e] focus:border-[#06042e] text-white placeholder:text-white/70 w-full mb-[15px] px-[15px] py-[8px] outline-none transition-colors"
              />
            </div>

            <div className="relative">
              <label htmlFor="exampleInputPassword1" className="text-[16px] text-black mb-[5px] block">
                Contraseña
              </label>
              <input
                id="exampleInputPassword1"
                name="password"
                type={mostrarPassword ? "text" : "password"}
                required
                aria-label="Contraseña"
                title="Ingresa la contraseña."
                value={password}
                onFocus={() => setMostrarIconoOjo(true)}
                onChange={manejarCambioPassword}
                className="h-[40px] border border-[#cccccc] rounded-[8px] bg-[#02024D] hover:bg-[#06042e] focus:bg-[#06042e] focus:border-[#06042e] text-white placeholder:text-white/70 w-full mb-[15px] pl-[15px] pr-[42px] py-[8px] outline-none transition-colors"
              />
              {mostrarIconoOjo && (
                <button
                  type="button"
                  onClick={() => setMostrarPassword((prev) => !prev)}
                  className="absolute right-[15px] top-[49px] -translate-y-1/2 text-[#f6f8fd] cursor-pointer"
                  aria-label="Mostrar u ocultar contraseña"
                >
                  {mostrarPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              )}
            </div>

            <span className="block w-[170px] text-left mt-[5px] text-[14px] text-[#6c757d] hover:text-[#02024D] hover:underline cursor-pointer">
              ¿Olvidaste tu contraseña?
            </span>

            {mensajeError && (
              <div className="relative top-[10px] text-[#ff0000] bg-[#f8dbdb] p-[8px] rounded-[8px] mb-[20px] text-[14px] text-center">
                {mensajeError}
              </div>
            )}

            <button
              type="submit"
              disabled={cargando}
              className="bg-white hover:bg-[#02024D] active:bg-[#06042e] active:scale-[0.98] text-black hover:text-white active:text-white border-none py-[12px] px-[24px] text-[16px] rounded-[8px] transition-all duration-300 cursor-pointer shadow-[0_0_20px_rgba(0,0,0,0.2)] h-[38px] flex items-center justify-center w-full font-bold mt-[20px] disabled:opacity-60"
            >
              {cargando ? "VERIFICANDO..." : "INICIAR SESION"}
            </button>
          </form>
        </div>
      </div>

      {/* Mitad derecha: Imagen corporativa y barras decorativas (#183160) */}
      <div className="hidden lg:block w-1/2 relative bg-[#183160]">
        <div className="absolute w-[50px] h-full bg-[#2a4576] left-0 z-[1] opacity-50 shadow-[0_0_40px_rgba(0,0,0,0.99)]" />
        <div className="absolute w-full h-[50px] bg-[#2a4576] left-0 top-0 z-[2] opacity-50 shadow-[0_0_40px_rgba(0,0,0,0.99)]" />
        <img
          src="/imgs/rh14.jpg"
          alt="RH Solutions Corporativo"
          className="w-full h-[80%] object-cover absolute top-[54.4%] left-[48%] -translate-x-1/2 -translate-y-1/2 shadow-[0_0_40px_rgba(0,0,0,0.99)] rounded-[7px] z-10"
        />
      </div>

      <OtpLoginModal
        abierto={modalOtpAbierto}
        correoEnmascaradoInicial={correoEnmascarado}
        onCancelar={() => void manejarCancelarOtp()}
        onVerificado={manejarOtpVerificado}
      />
    </div>
  );
}
