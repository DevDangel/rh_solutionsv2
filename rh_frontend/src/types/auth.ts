export type RolCodigo = "admin" | "empleado" | "jefe_inmediato";

export interface UsuarioSesion {
  id_usuario: number;
  uuid_usuario: string;
  documento: string;
  primer_nombre: string;
  segundo_nombre?: string | null;
  primer_apellido: string;
  segundo_apellido?: string | null;
  correo: string;
  id_rol: number;
  rol_codigo: RolCodigo;
  nombre_cargo?: string | null;
  img_perfil?: string | null;
}

export interface LoginResponseData {
  requires_otp: boolean;
  email_masked?: string;
  redirect_to?: string;
  user?: UsuarioSesion;
}

export interface VerifyOtpResponseData {
  redirect_to: string;
  user: UsuarioSesion;
}
