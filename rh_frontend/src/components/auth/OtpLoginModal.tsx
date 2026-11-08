"use client";

import React, { useCallback, useEffect, useRef, useState } from "react";
import { createPortal } from "react-dom";
import { Ban, Check, CheckCircle2, Clock, KeyRound, Loader2, LockOpen, Send, ShieldCheck, TriangleAlert, X, XCircle } from "lucide-react";
import { api, type ApiResponse } from "@/services/api";
import type { VerifyOtpResponseData } from "@/types/auth";

interface OtpLoginModalProps {
  abierto: boolean;
  correoEnmascaradoInicial: string;
  onCancelar: () => void;
  onVerificado: (data: VerifyOtpResponseData) => void;
}

type EstadoAlerta = { tipo: "success" | "danger" | "warning"; texto: string };

export default function OtpLoginModal({ abierto, correoEnmascaradoInicial, onCancelar, onVerificado }: OtpLoginModalProps) {
  const [montado, setMontado] = useState(false);
  const [codigo, setCodigo] = useState("");
  const [correoEnmascarado, setCorreoEnmascarado] = useState(correoEnmascaradoInicial);
  const [segundosRestantes, setSegundosRestantes] = useState(300);
  const [enviandoReenvio, setEnviandoReenvio] = useState(false);
  const [verificando, setVerificando] = useState(false);
  const [bloqueado, setBloqueado] = useState(false);
  const [estadoEnvio, setEstadoEnvio] = useState<EstadoAlerta>({
    tipo: "success",
    texto: `Código enviado a tu correo (${correoEnmascaradoInicial})`,
  });
  const [resultadoVerificacion, setResultadoVerificacion] = useState<EstadoAlerta | null>(null);
  const inputRef = useRef<HTMLInputElement | null>(null);

  useEffect(() => {
    setMontado(true);
  }, []);

  useEffect(() => {
    if (!abierto) return;
    setCodigo("");
    setCorreoEnmascarado(correoEnmascaradoInicial);
    setSegundosRestantes(300);
    setBloqueado(false);
    setResultadoVerificacion(null);
    setEstadoEnvio({ tipo: "success", texto: `Código enviado a tu correo (${correoEnmascaradoInicial})` });
    setTimeout(() => inputRef.current?.focus(), 100);
  }, [abierto, correoEnmascaradoInicial]);

  useEffect(() => {
    if (!abierto || segundosRestantes <= 0 || bloqueado) return;
    const timer = setInterval(() => {
      setSegundosRestantes((prev) => {
        if (prev <= 1) {
          setEstadoEnvio({ tipo: "warning", texto: "El código ha expirado. Solicita uno nuevo." });
          return 0;
        }
        return prev - 1;
      });
    }, 1000);
    return () => clearInterval(timer);
  }, [abierto, segundosRestantes, bloqueado]);

  const verificarCodigo = useCallback(
    async (valorCodigo: string) => {
      if (valorCodigo.length !== 6 || verificando || bloqueado) return;
      setVerificando(true);
      setResultadoVerificacion(null);
      try {
        const res = await api.post<VerifyOtpResponseData>("/api/v1/auth/otp/verificar/", { codigo: valorCodigo });
        if (res.data) {
          setResultadoVerificacion({ tipo: "success", texto: "Código verificado. Iniciando sesión..." });
          onVerificado(res.data);
        }
      } catch (err) {
        const msg = (err as ApiResponse)?.message || "Código incorrecto.";
        setCodigo("");
        inputRef.current?.focus();
        if (msg.toLowerCase().includes("máximo de intentos")) {
          setBloqueado(true);
          setResultadoVerificacion({ tipo: "danger", texto: "Has superado el número máximo de intentos permitidos." });
          setTimeout(() => onCancelar(), 2500);
        } else {
          setResultadoVerificacion({ tipo: "danger", texto: msg });
        }
      } finally {
        setVerificando(false);
      }
    },
    [verificando, bloqueado, onVerificado, onCancelar]
  );

  const manejarCambioInput = (e: React.ChangeEvent<HTMLInputElement>) => {
    const limpio = e.target.value.replace(/\D/g, "").slice(0, 6);
    setCodigo(limpio);
    if (limpio.length === 6) void verificarCodigo(limpio);
  };

  const manejarReenviar = async () => {
    if (enviandoReenvio || verificando || bloqueado) return;
    setEnviandoReenvio(true);
    setResultadoVerificacion(null);
    try {
      const res = await api.post<{ email_masked: string }>("/api/v1/auth/otp/reenviar/");
      const nuevoMask = res.data?.email_masked || correoEnmascarado;
      setCorreoEnmascarado(nuevoMask);
      setCodigo("");
      setSegundosRestantes(300);
      setEstadoEnvio({ tipo: "success", texto: `Código reenviado a: ${nuevoMask}` });
      inputRef.current?.focus();
    } catch (err) {
      setEstadoEnvio({ tipo: "danger", texto: (err as ApiResponse)?.message || "No se pudo reenviar el código." });
    } finally {
      setEnviandoReenvio(false);
    }
  };

  if (!montado || !abierto) return null;

  const min = Math.floor(segundosRestantes / 60);
  const seg = (segundosRestantes % 60).toString().padStart(2, "0");
  const claseAlerta = (tipo: EstadoAlerta["tipo"]) =>
    tipo === "success" ? "bg-[#d1e7dd] text-[#0f5132]" : tipo === "warning" ? "bg-[#fff3cd] text-[#664d03]" : "bg-[#f8d7da] text-[#842029]";

  return createPortal(
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/55 p-4">
      <div className="w-full max-w-[500px] rounded-[12px] bg-white shadow-2xl overflow-hidden">
        <div className="flex items-center justify-between px-6 pt-5 pb-2">
          <h5 className="flex items-center gap-2 text-[18px] font-semibold text-[#212529]">
            <ShieldCheck className="h-5 w-5 text-[#02024D]" /> Verificación de Identidad
          </h5>
          <button type="button" disabled={verificando || bloqueado} onClick={onCancelar} className="text-gray-500 hover:text-black disabled:opacity-40 cursor-pointer" aria-label="Cerrar">
            <X className="h-5 w-5" />
          </button>
        </div>

        <div className="px-[25px] py-[25px]">
          <div className="text-center mb-5">
            <LockOpen className="mx-auto h-12 w-12 text-[#02024D]" />
            <h6 className="mt-3 mb-2 text-[16px] font-semibold text-[#333333]">Código de Verificación</h6>
            <p className="text-[14px] text-[#666666]">Por seguridad, ingresa el código de 6 dígitos enviado a tu correo.</p>
          </div>

          <div className={`mb-4 flex items-center gap-2 rounded-[8px] px-[15px] py-[12px] text-[14px] ${claseAlerta(estadoEnvio.tipo)}`}>
            {estadoEnvio.tipo === "success" && <CheckCircle2 className="h-4 w-4 shrink-0" />}
            {estadoEnvio.tipo === "warning" && <TriangleAlert className="h-4 w-4 shrink-0" />}
            {estadoEnvio.tipo === "danger" && <XCircle className="h-4 w-4 shrink-0" />}
            <span>{estadoEnvio.texto}</span>
          </div>

          <div className="text-center mb-4">
            <button
              type="button"
              disabled={enviandoReenvio || verificando || bloqueado}
              onClick={manejarReenviar}
              className="inline-flex items-center gap-2 rounded-[8px] bg-[#02024D] hover:bg-[#000a1f] px-5 py-2.5 text-[14px] font-semibold text-white transition disabled:bg-[#cccccc] disabled:text-[#999999] cursor-pointer"
            >
              {enviandoReenvio ? <Loader2 className="h-4 w-4 animate-spin" /> : <Send className="h-4 w-4" />}
              {enviandoReenvio ? "Enviando..." : "Reenviar código"}
            </button>
          </div>

          <div>
            <label htmlFor="codigoOTP" className="mb-1.5 flex items-center gap-1.5 text-[14px] text-black">
              <KeyRound className="h-4 w-4 text-[#02024D]" /> Código de 6 dígitos:
            </label>
            <div className="flex items-stretch gap-2">
              <input
                ref={inputRef}
                id="codigoOTP"
                type="text"
                inputMode="numeric"
                maxLength={6}
                placeholder="000000"
                value={codigo}
                disabled={verificando || bloqueado || segundosRestantes === 0}
                onChange={manejarCambioInput}
                className="w-full rounded-[8px] border-2 border-[#e0e0e0] focus:border-[#02024D] px-3 py-2.5 text-center font-mono text-[18px] font-bold tracking-[4px] text-[#02024D] outline-none transition disabled:bg-gray-100"
              />
              <button
                type="button"
                disabled={codigo.length !== 6 || verificando || bloqueado || segundosRestantes === 0}
                onClick={() => void verificarCodigo(codigo)}
                className="inline-flex items-center gap-1.5 rounded-[8px] bg-[#28a745] hover:bg-[#218838] px-5 py-2.5 text-[14px] font-semibold text-white transition disabled:bg-[#cccccc] disabled:text-[#999999] cursor-pointer shrink-0"
              >
                {verificando ? <Loader2 className="h-4 w-4 animate-spin" /> : <Check className="h-4 w-4" />}
                {verificando ? "Verificando..." : "Verificar"}
              </button>
            </div>
            <small className="mt-1.5 flex items-center gap-1 text-[13px] text-[#666666]">
              <Clock className="h-3.5 w-3.5" /> Código expira en: <span className="font-bold text-[#d32f2f]">{`${min}:${seg}`}</span>
            </small>
          </div>

          {resultadoVerificacion && (
            <div className={`mt-4 flex items-center gap-2 rounded-[8px] px-[15px] py-[12px] text-[14px] ${claseAlerta(resultadoVerificacion.tipo)}`}>
              {resultadoVerificacion.tipo === "success" ? <CheckCircle2 className="h-4 w-4 shrink-0" /> : bloqueado ? <Ban className="h-4 w-4 shrink-0" /> : <XCircle className="h-4 w-4 shrink-0" />}
              <span>{resultadoVerificacion.texto}</span>
            </div>
          )}
        </div>

        <div className="flex justify-end px-6 py-4 border-t border-gray-100">
          <button type="button" disabled={verificando || bloqueado} onClick={onCancelar} className="rounded-[8px] bg-[#6c757d] hover:bg-[#5c636a] px-4 py-2 text-[14px] font-medium text-white transition disabled:opacity-50 cursor-pointer">
            Cancelar
          </button>
        </div>
      </div>
    </div>,
    document.body
  );
}
