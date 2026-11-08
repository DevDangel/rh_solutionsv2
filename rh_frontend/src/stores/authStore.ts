import { create } from "zustand";
import { api } from "@/services/api";
import type { UsuarioSesion } from "@/types/auth";

interface AuthState {
  usuario: UsuarioSesion | null;
  cargandoSesion: boolean;
  setUsuario: (usuario: UsuarioSesion | null) => void;
  rehidratarSesion: () => Promise<UsuarioSesion | null>;
  cerrarSesion: () => Promise<void>;
}

/**
 * Store de autenticación en memoria RAM (Zustand).
 * Invariante #1 de AGENTS.md: Jamás persiste en localStorage ni sessionStorage.
 * La verdad de la sesión vive en la cookie HttpOnly validada contra /api/v1/auth/me/.
 */
export const useAuthStore = create<AuthState>((set) => ({
  usuario: null,
  cargandoSesion: true,

  setUsuario: (usuario) => set({ usuario, cargandoSesion: false }),

  rehidratarSesion: async () => {
    set({ cargandoSesion: true });
    try {
      const respuesta = await api.get<UsuarioSesion>("/api/v1/auth/me/");
      const usuario = respuesta.data ?? null;
      set({ usuario, cargandoSesion: false });
      return usuario;
    } catch {
      set({ usuario: null, cargandoSesion: false });
      return null;
    }
  },

  cerrarSesion: async () => {
    try {
      await api.post("/api/v1/auth/logout/");
    } finally {
      set({ usuario: null, cargandoSesion: false });
    }
  },
}));
