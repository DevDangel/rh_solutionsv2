/**
 * Cliente HTTP único centralizado de RH Solutions v2.
 * Cumple las invariantes de .agents/rules/security_rules.md:
 * - Autenticación por Cookie HttpOnly (credentials: 'include').
 * - Protección CSRF automática leyendo la cookie 'csrftoken' hacia 'X-CSRFToken'.
 * - Cero uso de localStorage o sessionStorage.
 */

const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";

function obtenerCsrfToken(): string | null {
  if (typeof document === "undefined") return null;
  const match = document.cookie.match(/(?:^|;\s*)csrftoken=([^;]*)/);
  return match ? decodeURIComponent(match[1]) : null;
}

export interface ApiResponse<T = unknown> {
  status: "success" | "error";
  message?: string;
  data?: T;
  errors?: Record<string, string[]>;
}

async function request<T>(
  endpoint: string,
  options: RequestInit = {}
): Promise<ApiResponse<T>> {
  const metodo = (options.method || "GET").toUpperCase();
  const headers = new Headers(options.headers || {});

  if (!(options.body instanceof FormData) && !headers.has("Content-Type")) {
    headers.set("Content-Type", "application/json");
  }

  if (["POST", "PUT", "PATCH", "DELETE"].includes(metodo)) {
    const csrfToken = obtenerCsrfToken();
    if (csrfToken) {
      headers.set("X-CSRFToken", csrfToken);
    }
  }

  const respuesta = await fetch(`${API_BASE_URL}${endpoint}`, {
    ...options,
    method: metodo,
    headers,
    credentials: "include",
  });

  const payload = (await respuesta.json().catch(() => ({
    status: "error",
    message: "Respuesta inválida del servidor.",
  }))) as ApiResponse<T>;

  if (!respuesta.ok) {
    throw payload;
  }

  return payload;
}

export const api = {
  get: <T>(endpoint: string, options?: RequestInit) =>
    request<T>(endpoint, { ...options, method: "GET" }),
  post: <T>(endpoint: string, body?: unknown, options?: RequestInit) =>
    request<T>(endpoint, {
      ...options,
      method: "POST",
      body: body instanceof FormData ? body : JSON.stringify(body ?? {}),
    }),
  put: <T>(endpoint: string, body?: unknown, options?: RequestInit) =>
    request<T>(endpoint, {
      ...options,
      method: "PUT",
      body: body instanceof FormData ? body : JSON.stringify(body ?? {}),
    }),
  patch: <T>(endpoint: string, body?: unknown, options?: RequestInit) =>
    request<T>(endpoint, {
      ...options,
      method: "PATCH",
      body: body instanceof FormData ? body : JSON.stringify(body ?? {}),
    }),
  delete: <T>(endpoint: string, options?: RequestInit) =>
    request<T>(endpoint, { ...options, method: "DELETE" }),
};
