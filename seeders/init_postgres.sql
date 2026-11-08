-- =============================================================================
-- RH SOLUTIONS V2 — ESQUEMA Y SEEDER MAESTRO PARA POSTGRESQL 17+
-- =============================================================================
-- Base de datos normalizada en 3NF:
--   * 27 Tablas Catálogo (pobladas con data oficial de Colombia y paramétricas)
--   * 17 Tablas Operativas (limpias, incluyendo únicamente el Usuario #1 Admin)
--   * Secuencias (SERIAL/IDENTITY) sincronizadas automáticamente al final
-- =============================================================================

BEGIN;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET TIME ZONE 'America/Bogota';

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- 1. TABLAS CATÁLOGO (27 TABLAS PARAMÉTRICAS)
-- =============================================================================

-- 1.1. Roles del Sistema
CREATE TABLE IF NOT EXISTS roles (
    id_rol SERIAL PRIMARY KEY,
    nom_rol VARCHAR(45) NOT NULL UNIQUE,
    descripcion VARCHAR(255) DEFAULT NULL
);

-- 1.2. Tipo de Identificación (Documento de identidad de la persona)
CREATE TABLE IF NOT EXISTS tipo_identificacion (
    id_tipo_identificacion SERIAL PRIMARY KEY,
    sigla VARCHAR(10) NOT NULL UNIQUE,
    nom_tipo_identificacion VARCHAR(80) NOT NULL UNIQUE
);

-- 1.3. Tipo de Sangre (Grupo RH)
CREATE TABLE IF NOT EXISTS tipo_sangre (
    id_tipo_sangre SERIAL PRIMARY KEY,
    grupo_rh VARCHAR(5) NOT NULL UNIQUE
);

-- 1.4. Sexo
CREATE TABLE IF NOT EXISTS sexo (
    id_sexo SERIAL PRIMARY KEY,
    nom_sexo VARCHAR(30) NOT NULL UNIQUE
);

-- 1.5. Estado Civil
CREATE TABLE IF NOT EXISTS estado_civil (
    id_estado_civil SERIAL PRIMARY KEY,
    nom_estado_civil VARCHAR(45) NOT NULL UNIQUE
);

-- 1.6. Estado del Usuario
CREATE TABLE IF NOT EXISTS estado_usuario (
    id_estado SERIAL PRIMARY KEY,
    nom_estado VARCHAR(155) NOT NULL UNIQUE
);

-- 1.7. Departamentos
CREATE TABLE IF NOT EXISTS departamentos (
    id_departamento SERIAL PRIMARY KEY,
    nom_departamento VARCHAR(80) NOT NULL UNIQUE
);

-- 1.8. Municipios
CREATE TABLE IF NOT EXISTS municipio (
    id_municipio SERIAL PRIMARY KEY,
    nom_municipio VARCHAR(80) NOT NULL,
    id_departamento INTEGER NOT NULL REFERENCES departamentos(id_departamento) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE INDEX IF NOT EXISTS idx_municipio_departamento ON municipio(id_departamento);
CREATE INDEX IF NOT EXISTS idx_municipio_nombre ON municipio(nom_municipio);

-- 1.9. Dependencias (Áreas de la empresa)
CREATE TABLE IF NOT EXISTS dependencias (
    id_dependencia SERIAL PRIMARY KEY,
    dependencia VARCHAR(80) NOT NULL UNIQUE
);

-- 1.10. Cargos Organizacionales
CREATE TABLE IF NOT EXISTS cargos (
    id_cargo SERIAL PRIMARY KEY,
    cargo VARCHAR(155) NOT NULL UNIQUE,
    id_dependencia INTEGER NOT NULL REFERENCES dependencias(id_dependencia) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE INDEX IF NOT EXISTS idx_cargos_dependencia ON cargos(id_dependencia);

-- 1.11. Profesiones
CREATE TABLE IF NOT EXISTS profesion (
    id_profesion SERIAL PRIMARY KEY,
    nom_profesion VARCHAR(100) NOT NULL UNIQUE
);

-- 1.12. EPS (Entidades Promotoras de Salud)
CREATE TABLE IF NOT EXISTS eps (
    id_eps SERIAL PRIMARY KEY,
    nom_eps VARCHAR(100) NOT NULL UNIQUE
);

-- 1.13. Fondos de Pensiones
CREATE TABLE IF NOT EXISTS pensiones (
    id_pension SERIAL PRIMARY KEY,
    nom_pension VARCHAR(60) NOT NULL UNIQUE
);

-- 1.14. ARL (Administradoras de Riesgos Laborales)
CREATE TABLE IF NOT EXISTS arl (
    id_arl SERIAL PRIMARY KEY,
    nom_arl VARCHAR(60) NOT NULL UNIQUE
);

-- 1.15. Cajas de Compensación Familiar
CREATE TABLE IF NOT EXISTS caja_compensacion (
    id_caj_compen SERIAL PRIMARY KEY,
    nom_caj_compen VARCHAR(80) NOT NULL UNIQUE
);

-- 1.16. Bancos
CREATE TABLE IF NOT EXISTS bancos (
    id_banco SERIAL PRIMARY KEY,
    nom_banco VARCHAR(100) NOT NULL UNIQUE
);

-- 1.17. Categoría de Licencia de Conducción
CREATE TABLE IF NOT EXISTS categoria_licencia (
    id_categoria_licencia SERIAL PRIMARY KEY,
    nom_categoria VARCHAR(35) NOT NULL UNIQUE
);

-- 1.18. Estado de Licencia de Conducción
CREATE TABLE IF NOT EXISTS estado_licencia (
    id_estado_licencia SERIAL PRIMARY KEY,
    nom_estado_licencia VARCHAR(45) NOT NULL UNIQUE
);

-- 1.19. Tipo de Contrato Laboral
CREATE TABLE IF NOT EXISTS tipo_contrato (
    id_tip_contrato SERIAL PRIMARY KEY,
    nom_contrato VARCHAR(60) NOT NULL UNIQUE
);

-- 1.20. Tiempo / Duración de Contrato
CREATE TABLE IF NOT EXISTS tiempo_contrato (
    id_tiemp_contrato SERIAL PRIMARY KEY,
    nom_tiemp_contrato VARCHAR(55) NOT NULL UNIQUE
);

-- 1.21. Estado de Contrato
CREATE TABLE IF NOT EXISTS estado_contrato (
    id_est_contrato SERIAL PRIMARY KEY,
    nom_est_contrato VARCHAR(60) NOT NULL UNIQUE
);

-- 1.22. Tipo de Documento (Formato de archivo permitido)
CREATE TABLE IF NOT EXISTS tipo_documento (
    id_tip_document SERIAL PRIMARY KEY,
    nom_tip_document VARCHAR(155) NOT NULL UNIQUE
);

-- 1.23. Estado de Documento (Semáforo de vigencia y carga)
CREATE TABLE IF NOT EXISTS estado_documento (
    id_estado_documento SERIAL PRIMARY KEY,
    nom_estado_documento VARCHAR(45) NOT NULL UNIQUE
);

-- 1.24. Tipo de Permisos y Licencias
CREATE TABLE IF NOT EXISTS tipo_permisos (
    id_tipo_permiso SERIAL PRIMARY KEY,
    nom_permiso VARCHAR(60) NOT NULL UNIQUE
);

-- 1.25. Estado de Permiso
CREATE TABLE IF NOT EXISTS estado_permiso (
    id_estado_permiso SERIAL PRIMARY KEY,
    nom_estado_permiso VARCHAR(45) NOT NULL UNIQUE
);

-- 1.26. Estado de Solicitud de Certificado Laboral
CREATE TABLE IF NOT EXISTS estado_certificado (
    id_estado_certificado SERIAL PRIMARY KEY,
    nom_estado_certificado VARCHAR(45) NOT NULL UNIQUE
);

-- 1.27. Estado de Solicitud de Renuncia
CREATE TABLE IF NOT EXISTS estado_renuncia (
    id_estado_renuncia SERIAL PRIMARY KEY,
    nom_estado_renuncia VARCHAR(45) NOT NULL UNIQUE
);


-- =============================================================================
-- 2. TABLAS OPERATIVAS (17 TABLAS TRANSACCIONALES)
-- =============================================================================

-- 2.1. Usuarios / Colaboradores
CREATE TABLE IF NOT EXISTS usuarios (
    id_usuario SERIAL PRIMARY KEY,
    uuid UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    doc_usuario VARCHAR(45) NOT NULL UNIQUE,
    id_tipo_identificacion INTEGER NOT NULL REFERENCES tipo_identificacion(id_tipo_identificacion) ON UPDATE CASCADE ON DELETE RESTRICT,
    pri_nombre VARCHAR(45) NOT NULL,
    seg_nombre VARCHAR(45) DEFAULT NULL,
    pri_apellido VARCHAR(45) NOT NULL,
    seg_apellido VARCHAR(55) DEFAULT NULL,
    fec_nacimiento DATE NOT NULL,
    id_tipo_sangre INTEGER NOT NULL REFERENCES tipo_sangre(id_tipo_sangre) ON UPDATE CASCADE ON DELETE RESTRICT,
    id_sexo INTEGER NOT NULL REFERENCES sexo(id_sexo) ON UPDATE CASCADE ON DELETE RESTRICT,
    id_estado_civil INTEGER DEFAULT NULL REFERENCES estado_civil(id_estado_civil) ON UPDATE CASCADE ON DELETE RESTRICT,
    dir_usuario VARCHAR(255) DEFAULT NULL,
    cel_usuario VARCHAR(45) NOT NULL UNIQUE,
    cel_emer_usuario VARCHAR(45) NOT NULL,
    correo_usuario VARCHAR(120) NOT NULL UNIQUE,
    registro_profesional VARCHAR(45) DEFAULT NULL,
    password VARCHAR(255) NOT NULL,
    id_rol INTEGER NOT NULL DEFAULT 2 REFERENCES roles(id_rol) ON UPDATE CASCADE ON DELETE RESTRICT,
    id_departamento INTEGER NOT NULL REFERENCES departamentos(id_departamento) ON UPDATE CASCADE ON DELETE RESTRICT,
    id_municipio INTEGER NOT NULL REFERENCES municipio(id_municipio) ON UPDATE CASCADE ON DELETE RESTRICT,
    id_estado INTEGER NOT NULL DEFAULT 1 REFERENCES estado_usuario(id_estado) ON UPDATE CASCADE ON DELETE RESTRICT,
    id_cargo INTEGER NOT NULL REFERENCES cargos(id_cargo) ON UPDATE CASCADE ON DELETE RESTRICT,
    id_eps INTEGER NOT NULL REFERENCES eps(id_eps) ON UPDATE CASCADE ON DELETE RESTRICT,
    id_pension INTEGER NOT NULL REFERENCES pensiones(id_pension) ON UPDATE CASCADE ON DELETE RESTRICT,
    id_arl INTEGER NOT NULL REFERENCES arl(id_arl) ON UPDATE CASCADE ON DELETE RESTRICT,
    id_caj_compen INTEGER NOT NULL REFERENCES caja_compensacion(id_caj_compen) ON UPDATE CASCADE ON DELETE RESTRICT,
    id_profesion INTEGER NOT NULL REFERENCES profesion(id_profesion) ON UPDATE CASCADE ON DELETE RESTRICT,
    img_perfil VARCHAR(255) DEFAULT 'imgs/default.jpg',
    ruta_firma VARCHAR(500) DEFAULT NULL,
    last_login TIMESTAMPTZ DEFAULT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_usuarios_rol ON usuarios(id_rol);
CREATE INDEX IF NOT EXISTS idx_usuarios_estado ON usuarios(id_estado);
CREATE INDEX IF NOT EXISTS idx_usuarios_cargo ON usuarios(id_cargo);

-- 2.2. Licencia de Conducción
CREATE TABLE IF NOT EXISTS licencia_conduccion (
    id_licencia SERIAL PRIMARY KEY,
    numero_licencia VARCHAR(20) NOT NULL UNIQUE,
    fecha_expedicion DATE NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    id_estado_licencia INTEGER NOT NULL REFERENCES estado_licencia(id_estado_licencia) ON UPDATE CASCADE ON DELETE RESTRICT,
    id_categoria_licencia INTEGER NOT NULL REFERENCES categoria_licencia(id_categoria_licencia) ON UPDATE CASCADE ON DELETE RESTRICT,
    id_usuario INTEGER NOT NULL REFERENCES usuarios(id_usuario) ON UPDATE CASCADE ON DELETE CASCADE
);

-- 2.3. Consentimientos de Firma Digital (Ley 527 de 1999)
CREATE TABLE IF NOT EXISTS consentimientos_firma_digital (
    id SERIAL PRIMARY KEY,
    id_usuario INTEGER NOT NULL REFERENCES usuarios(id_usuario) ON UPDATE CASCADE ON DELETE CASCADE,
    ruta_firma VARCHAR(500) NOT NULL,
    acepto_terminos BOOLEAN NOT NULL DEFAULT TRUE,
    ip_address VARCHAR(45) DEFAULT NULL,
    user_agent TEXT DEFAULT NULL,
    fecha_consentimiento TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2.4. Contratos Laborales
CREATE TABLE IF NOT EXISTS contrato (
    id_contrato SERIAL PRIMARY KEY,
    uuid UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    fec_ingreso DATE NOT NULL,
    fec_finalizacion DATE DEFAULT NULL,
    funciones TEXT DEFAULT NULL,
    salario NUMERIC(12, 2) NOT NULL,
    clausulas TEXT DEFAULT NULL,
    id_tip_contrato INTEGER NOT NULL REFERENCES tipo_contrato(id_tip_contrato) ON UPDATE CASCADE ON DELETE RESTRICT,
    id_usuario INTEGER NOT NULL REFERENCES usuarios(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT,
    id_tiemp_contrato INTEGER NOT NULL REFERENCES tiempo_contrato(id_tiemp_contrato) ON UPDATE CASCADE ON DELETE RESTRICT,
    id_est_contrato INTEGER NOT NULL REFERENCES estado_contrato(id_est_contrato) ON UPDATE CASCADE ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_contrato_usuario ON contrato(id_usuario);
CREATE INDEX IF NOT EXISTS idx_contrato_estado ON contrato(id_est_contrato);

-- 2.5. Documentos Requeridos (Asignados por Cargo o por Persona)
CREATE TABLE IF NOT EXISTS documentos_requeridos (
    id_doc_requerido SERIAL PRIMARY KEY,
    nom_documento VARCHAR(155) NOT NULL,
    obligatorio BOOLEAN NOT NULL DEFAULT TRUE,
    requiere_fecha BOOLEAN NOT NULL DEFAULT FALSE,
    id_cargo INTEGER DEFAULT NULL REFERENCES cargos(id_cargo) ON UPDATE CASCADE ON DELETE CASCADE,
    id_usuario INTEGER DEFAULT NULL REFERENCES usuarios(id_usuario) ON UPDATE CASCADE ON DELETE CASCADE,
    id_tip_document INTEGER NOT NULL REFERENCES tipo_documento(id_tip_document) ON UPDATE CASCADE ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_doc_req_target CHECK (id_cargo IS NOT NULL OR id_usuario IS NOT NULL)
);
CREATE INDEX IF NOT EXISTS idx_doc_req_cargo ON documentos_requeridos(id_cargo);
CREATE INDEX IF NOT EXISTS idx_doc_req_usuario ON documentos_requeridos(id_usuario);

-- 2.6. Documentos Cargados por Empleados
CREATE TABLE IF NOT EXISTS documentos (
    id_documentos SERIAL PRIMARY KEY,
    uuid UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    nom_documento VARCHAR(155) NOT NULL,
    ruta_archivo VARCHAR(1000) NOT NULL,
    fecha_vencimiento TIMESTAMPTZ DEFAULT NULL,
    serial_unico VARCHAR(155) NOT NULL UNIQUE,
    id_estado_documento INTEGER NOT NULL DEFAULT 1 REFERENCES estado_documento(id_estado_documento) ON UPDATE CASCADE ON DELETE RESTRICT,
    id_usuario INTEGER NOT NULL REFERENCES usuarios(id_usuario) ON UPDATE CASCADE ON DELETE CASCADE,
    id_tip_document INTEGER NOT NULL REFERENCES tipo_documento(id_tip_document) ON UPDATE CASCADE ON DELETE RESTRICT,
    id_doc_requerido INTEGER DEFAULT NULL REFERENCES documentos_requeridos(id_doc_requerido) ON UPDATE RESTRICT ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT NULL
);
CREATE INDEX IF NOT EXISTS idx_documentos_usuario ON documentos(id_usuario);
CREATE INDEX IF NOT EXISTS idx_documentos_estado ON documentos(id_estado_documento);
CREATE INDEX IF NOT EXISTS idx_documentos_vencimiento ON documentos(fecha_vencimiento);

-- 2.7. Historial de Emails de Vencimiento de Documentos (Control de Idempotencia)
CREATE TABLE IF NOT EXISTS historial_emails_documentos (
    id SERIAL PRIMARY KEY,
    id_usuario INTEGER NOT NULL REFERENCES usuarios(id_usuario) ON UPDATE CASCADE ON DELETE CASCADE,
    id_documento INTEGER NOT NULL REFERENCES documentos(id_documentos) ON UPDATE CASCADE ON DELETE CASCADE,
    tipo_email VARCHAR(50) NOT NULL,
    email_destinatario VARCHAR(120) NOT NULL,
    fecha_vencimiento_documento DATE DEFAULT NULL,
    dias_diferencia INTEGER DEFAULT NULL,
    estado_envio VARCHAR(30) NOT NULL DEFAULT 'enviado',
    error_mensaje TEXT DEFAULT NULL,
    fecha_envio TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_hist_email_doc_lookup ON historial_emails_documentos(id_usuario, id_documento, tipo_email);

-- 2.8. Solicitudes de Permisos, Licencias y Vacaciones
CREATE TABLE IF NOT EXISTS permisos (
    id_permiso SERIAL PRIMARY KEY,
    uuid UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    id_usuario INTEGER NOT NULL REFERENCES usuarios(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT,
    radicado INTEGER NOT NULL UNIQUE,
    id_estado_permiso INTEGER NOT NULL DEFAULT 1 REFERENCES estado_permiso(id_estado_permiso) ON UPDATE CASCADE ON DELETE RESTRICT,
    id_tipo_permiso INTEGER NOT NULL REFERENCES tipo_permisos(id_tipo_permiso) ON UPDATE CASCADE ON DELETE RESTRICT,
    motivo TEXT DEFAULT NULL,
    num_dias INTEGER DEFAULT NULL,
    id_dependencia INTEGER NOT NULL REFERENCES dependencias(id_dependencia) ON UPDATE CASCADE ON DELETE RESTRICT,
    hora_inicio TIME DEFAULT NULL,
    hora_fin TIME DEFAULT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_finalizacion DATE NOT NULL,
    fecha_reincorporacion DATE NOT NULL,
    soportes VARCHAR(500) DEFAULT NULL,
    pdf VARCHAR(500) NOT NULL,
    pdf_aprobacion VARCHAR(500) DEFAULT NULL,
    hash_pdf_firmado VARCHAR(64) DEFAULT NULL,
    motivo_rechazo TEXT DEFAULT NULL,
    autoriza_datos BOOLEAN NOT NULL DEFAULT TRUE,
    autoriza_firma BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_solicitud TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    tiempo_espera TIMESTAMPTZ DEFAULT NULL
);
CREATE INDEX IF NOT EXISTS idx_permisos_usuario ON permisos(id_usuario);
CREATE INDEX IF NOT EXISTS idx_permisos_estado ON permisos(id_estado_permiso);

-- 2.9. Historial de Permisos
CREATE TABLE IF NOT EXISTS historial_permisos (
    id_historial_permiso SERIAL PRIMARY KEY,
    id_usuario INTEGER NOT NULL REFERENCES usuarios(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT,
    fecha_emision DATE NOT NULL DEFAULT CURRENT_DATE,
    radicado INTEGER NOT NULL,
    id_estado_permiso INTEGER NOT NULL DEFAULT 1 REFERENCES estado_permiso(id_estado_permiso) ON UPDATE CASCADE ON DELETE RESTRICT,
    id_tipo_permiso INTEGER NOT NULL REFERENCES tipo_permisos(id_tipo_permiso) ON UPDATE CASCADE ON DELETE RESTRICT,
    motivo TEXT DEFAULT NULL,
    num_dias INTEGER DEFAULT NULL,
    id_dependencia INTEGER NOT NULL REFERENCES dependencias(id_dependencia) ON UPDATE CASCADE ON DELETE RESTRICT,
    hora_inicio TIME DEFAULT NULL,
    hora_fin TIME DEFAULT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_finalizacion DATE NOT NULL,
    fecha_reincorporacion DATE NOT NULL,
    soportes VARCHAR(500) DEFAULT NULL,
    pdf VARCHAR(500) NOT NULL,
    pdf_aprobacion VARCHAR(500) DEFAULT NULL,
    motivo_rechazo TEXT DEFAULT NULL,
    autoriza_datos BOOLEAN NOT NULL DEFAULT TRUE,
    autoriza_firma BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_hist_permisos_usuario ON historial_permisos(id_usuario);

-- 2.10. Solicitudes de Certificados Laborales
CREATE TABLE IF NOT EXISTS solicitud_certificado (
    id_solicitud SERIAL PRIMARY KEY,
    uuid UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    id_contrato INTEGER NOT NULL REFERENCES contrato(id_contrato) ON UPDATE CASCADE ON DELETE CASCADE,
    motivo TEXT NOT NULL,
    incluir_funciones BOOLEAN NOT NULL DEFAULT FALSE,
    incluir_salario BOOLEAN NOT NULL DEFAULT FALSE,
    incluir_cargo BOOLEAN NOT NULL DEFAULT FALSE,
    dirigido_banco BOOLEAN NOT NULL DEFAULT FALSE,
    id_banco INTEGER DEFAULT NULL REFERENCES bancos(id_banco) ON UPDATE CASCADE ON DELETE SET NULL,
    id_estado_certificado INTEGER NOT NULL DEFAULT 2 REFERENCES estado_certificado(id_estado_certificado) ON UPDATE CASCADE ON DELETE RESTRICT,
    fecha_solicitud TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    motivo_seg_vez VARCHAR(255) DEFAULT NULL,
    motivo_rechazo TEXT DEFAULT NULL,
    tiempo_espera TIMESTAMPTZ DEFAULT NULL,
    radicado_cert VARCHAR(100) NOT NULL UNIQUE,
    ruta_cert VARCHAR(500) DEFAULT NULL,
    soportes VARCHAR(500) DEFAULT NULL
);
CREATE INDEX IF NOT EXISTS idx_sol_cert_contrato ON solicitud_certificado(id_contrato);
CREATE INDEX IF NOT EXISTS idx_sol_cert_estado ON solicitud_certificado(id_estado_certificado);

-- 2.11. Historial de Certificados Laborales
CREATE TABLE IF NOT EXISTS historial_certificados (
    id_certificado SERIAL PRIMARY KEY,
    id_contrato INTEGER NOT NULL REFERENCES contrato(id_contrato) ON UPDATE CASCADE ON DELETE CASCADE,
    motivo TEXT NOT NULL,
    motivo_seg_vez VARCHAR(255) DEFAULT NULL,
    incluir_funciones BOOLEAN NOT NULL DEFAULT FALSE,
    incluir_salario BOOLEAN NOT NULL DEFAULT FALSE,
    incluir_cargo BOOLEAN NOT NULL DEFAULT FALSE,
    dirigido_banco BOOLEAN NOT NULL DEFAULT FALSE,
    id_banco INTEGER DEFAULT NULL REFERENCES bancos(id_banco) ON UPDATE CASCADE ON DELETE SET NULL,
    id_estado_certificado INTEGER NOT NULL REFERENCES estado_certificado(id_estado_certificado) ON UPDATE CASCADE ON DELETE RESTRICT,
    fecha_emision TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    motivo_rechazo TEXT DEFAULT NULL,
    radicado_cert VARCHAR(100) DEFAULT NULL,
    ruta_cert VARCHAR(500) DEFAULT NULL,
    soportes VARCHAR(500) DEFAULT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_hist_cert_contrato ON historial_certificados(id_contrato);

-- 2.12. Control de Tiempo de Espera (Cooldown) de Certificados
CREATE TABLE IF NOT EXISTS valida_tiempo_certificado (
    id SERIAL PRIMARY KEY,
    id_contrato INTEGER NOT NULL REFERENCES contrato(id_contrato) ON UPDATE CASCADE ON DELETE CASCADE,
    fecha_solicitud TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    tiempo_espera TIMESTAMPTZ DEFAULT NULL,
    id_banco INTEGER DEFAULT NULL REFERENCES bancos(id_banco) ON UPDATE CASCADE ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2.13. Solicitudes de Renuncia
CREATE TABLE IF NOT EXISTS renuncia_solicitud (
    id_renuncia SERIAL PRIMARY KEY,
    uuid UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    id_usuario INTEGER NOT NULL REFERENCES usuarios(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT,
    id_estado_renuncia INTEGER NOT NULL DEFAULT 2 REFERENCES estado_renuncia(id_estado_renuncia) ON UPDATE CASCADE ON DELETE RESTRICT,
    radicado_renun VARCHAR(100) NOT NULL UNIQUE,
    fech_emision DATE NOT NULL DEFAULT CURRENT_DATE,
    fech_renun DATE NOT NULL,
    motivo_renun VARCHAR(255) NOT NULL,
    motivo_ampliado TEXT DEFAULT NULL,
    ruta_carta VARCHAR(500) DEFAULT NULL,
    ruta_aprobacion VARCHAR(500) DEFAULT NULL,
    hash_carta_firmada VARCHAR(64) DEFAULT NULL,
    autoriza_datos BOOLEAN NOT NULL DEFAULT TRUE,
    autoriza_firma BOOLEAN NOT NULL DEFAULT TRUE,
    motivo_rechazo TEXT DEFAULT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_renuncia_usuario ON renuncia_solicitud(id_usuario);
CREATE INDEX IF NOT EXISTS idx_renuncia_estado ON renuncia_solicitud(id_estado_renuncia);

-- 2.14. Historial de Renuncias
CREATE TABLE IF NOT EXISTS historial_renuncias (
    id_historial_renun SERIAL PRIMARY KEY,
    id_usuario INTEGER NOT NULL REFERENCES usuarios(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT,
    id_estado_renuncia INTEGER NOT NULL REFERENCES estado_renuncia(id_estado_renuncia) ON UPDATE CASCADE ON DELETE RESTRICT,
    radicado_renun VARCHAR(100) NOT NULL UNIQUE,
    fech_emision DATE NOT NULL,
    fech_renun DATE NOT NULL,
    motivo_renun VARCHAR(255) NOT NULL,
    motivo_ampliado TEXT DEFAULT NULL,
    ruta_carta VARCHAR(500) DEFAULT NULL,
    ruta_aprobacion VARCHAR(500) DEFAULT NULL,
    motivo_rechazo TEXT DEFAULT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_hist_renun_usuario ON historial_renuncias(id_usuario);

-- 2.15. Notificaciones Internas (Tiempo Real + Persistencia)
CREATE TABLE IF NOT EXISTS notificaciones (
    id SERIAL PRIMARY KEY,
    usuario_id INTEGER NOT NULL REFERENCES usuarios(id_usuario) ON UPDATE CASCADE ON DELETE CASCADE,
    documento_id INTEGER DEFAULT NULL REFERENCES documentos(id_documentos) ON UPDATE CASCADE ON DELETE SET NULL,
    tipo VARCHAR(100) NOT NULL,
    mensaje TEXT NOT NULL,
    usuario_nombre VARCHAR(155) DEFAULT NULL,
    cedula_usuario VARCHAR(45) DEFAULT NULL,
    img_perfil VARCHAR(255) DEFAULT NULL,
    url VARCHAR(500) DEFAULT NULL,
    leida BOOLEAN NOT NULL DEFAULT FALSE,
    estado BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_notificaciones_usuario_leida ON notificaciones(usuario_id, estado, leida);

-- 2.16. Registro de Códigos OTP de Firma Electrónica
CREATE TABLE IF NOT EXISTS user_otp_codes (
    id SERIAL PRIMARY KEY,
    id_usuario INTEGER NOT NULL REFERENCES usuarios(id_usuario) ON UPDATE CASCADE ON DELETE CASCADE,
    otp_code_hash VARCHAR(128) NOT NULL,
    radicado VARCHAR(100) DEFAULT NULL,
    intentos SMALLINT NOT NULL DEFAULT 0,
    expires_at TIMESTAMPTZ NOT NULL,
    used_at TIMESTAMPTZ DEFAULT NULL,
    ip_address VARCHAR(45) DEFAULT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_user_otp_usuario ON user_otp_codes(id_usuario, used_at);

-- 2.17. Bitácora Inmutable de Auditoría y Seguridad (Audit Logs)
CREATE TABLE IF NOT EXISTS audit_logs (
    id BIGSERIAL PRIMARY KEY,
    actor_id INTEGER DEFAULT NULL REFERENCES usuarios(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL,
    accion VARCHAR(100) NOT NULL,
    entidad VARCHAR(100) NOT NULL,
    entidad_id VARCHAR(100) DEFAULT NULL,
    datos_anteriores JSONB DEFAULT NULL,
    datos_nuevos JSONB DEFAULT NULL,
    hash_documento VARCHAR(64) DEFAULT NULL,
    ip_address VARCHAR(45) DEFAULT NULL,
    user_agent TEXT DEFAULT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_audit_logs_actor ON audit_logs(actor_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_entidad ON audit_logs(entidad, entidad_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created ON audit_logs(created_at);


-- =============================================================================
-- 3. POBLADO DE DATOS SEMILLA (CATÁLOGOS MAESTROS + USUARIO #1 ADMIN)
-- =============================================================================

-- 3.1. Roles
INSERT INTO roles (id_rol, nom_rol, descripcion) VALUES
(1, 'Administrador', 'Gestión integral de Talento Humano, aprobaciones, reportes y configuración'),
(2, 'Empleado', 'Portal de autogestión de certificados, permisos, documentos y renuncia')
ON CONFLICT (id_rol) DO NOTHING;

-- 3.2. Tipo de Identificación
INSERT INTO tipo_identificacion (id_tipo_identificacion, sigla, nom_tipo_identificacion) VALUES
(1, 'CC', 'Cédula de Ciudadanía'),
(2, 'CE', 'Cédula de Extranjería'),
(3, 'TI', 'Tarjeta de Identidad'),
(4, 'PA', 'Pasaporte'),
(5, 'DNI', 'Documento Nacional de Identidad'),
(6, 'PEP', 'Permiso Especial de Permanencia'),
(7, 'PPT', 'Permiso por Protección Temporal')
ON CONFLICT (id_tipo_identificacion) DO NOTHING;

-- 3.3. Tipo de Sangre
INSERT INTO tipo_sangre (id_tipo_sangre, grupo_rh) VALUES
(1, 'A+'),
(2, 'A-'),
(3, 'B+'),
(4, 'B-'),
(5, 'AB+'),
(6, 'AB-'),
(7, 'O+'),
(8, 'O-')
ON CONFLICT (id_tipo_sangre) DO NOTHING;

-- 3.4. Sexo
INSERT INTO sexo (id_sexo, nom_sexo) VALUES
(1, 'Masculino'),
(2, 'Femenino')
ON CONFLICT (id_sexo) DO NOTHING;

-- 3.5. Estado Civil
INSERT INTO estado_civil (id_estado_civil, nom_estado_civil) VALUES
(1, 'Soltero(a)'),
(2, 'Casado(a)'),
(3, 'Divorciado(a)'),
(4, 'Viudo(a)'),
(5, 'Unión libre'),
(6, 'Separado(a)')
ON CONFLICT (id_estado_civil) DO NOTHING;

-- 3.6. Estado del Usuario
INSERT INTO estado_usuario (id_estado, nom_estado) VALUES
(1, 'Activo'),
(2, 'Desvinculado'),
(3, 'Incapacitado'),
(4, 'En Licencia'),
(5, 'Suspendido'),
(6, 'En Vacaciones'),
(7, 'En Periodo de Prueba'),
(8, 'Teletrabajo'),
(9, 'Trabajo en Casa'),
(10, 'Trabajo Remoto')
ON CONFLICT (id_estado) DO NOTHING;

-- 3.7. Departamentos de Colombia
INSERT INTO departamentos (id_departamento, nom_departamento) VALUES
(1, 'Antioquia'),
(2, 'Atlántico'),
(3, 'Bogotá, d.c.'),
(4, 'Bolívar'),
(5, 'Boyacá'),
(6, 'Caldas'),
(7, 'Caquetá'),
(8, 'Cauca'),
(9, 'Cesar'),
(10, 'Córdoba'),
(11, 'Cundinamarca'),
(12, 'Chocó'),
(13, 'Huila'),
(14, 'La guajira'),
(15, 'Magdalena'),
(16, 'Meta'),
(17, 'Nariño'),
(18, 'Norte de santander'),
(19, 'Quindio'),
(20, 'Risaralda'),
(21, 'Santander'),
(22, 'Sucre'),
(23, 'Tolima'),
(24, 'Valle del cauca'),
(25, 'Arauca'),
(26, 'Casanare'),
(27, 'Putumayo'),
(28, 'Islas san andres y providencia'),
(29, 'Amazonas'),
(30, 'Guanía'),
(31, 'Guaviare'),
(32, 'Vaupes'),
(33, 'Vichada')
ON CONFLICT (id_departamento) DO NOTHING;

-- 3.8. Municipios de Colombia (1.122 municipios)
INSERT INTO municipio (id_municipio, nom_municipio, id_departamento) VALUES
(1, 'Medellín', 1),
(2, 'Abejorral', 1),
(3, 'Abriaquí', 1),
(4, 'Alejandría', 1),
(5, 'Amagá', 1),
(6, 'Amalfi', 1),
(7, 'Andes', 1),
(8, 'Angelópolis', 1),
(9, 'Angostura', 1),
(10, 'Anorí', 1),
(11, 'Santafé de Antioquia', 1),
(12, 'Anza', 1),
(13, 'Apartadó', 1),
(14, 'Arboletes', 1),
(15, 'Argelia', 1),
(16, 'Armenia', 1),
(17, 'Barbosa', 1),
(18, 'Bello', 1),
(19, 'Betania', 1),
(20, 'Betulia', 1),
(21, 'Briceño', 1),
(22, 'Buriticá', 1),
(23, 'Cáceres', 1),
(24, 'Caicedo', 1),
(25, 'Caldas', 1),
(26, 'Campamento', 1),
(27, 'Cañasgordas', 1),
(28, 'Caracolí', 1),
(29, 'Caramanta', 1),
(30, 'Carepa', 1),
(31, 'El Carmen de Viboral', 1),
(32, 'Carolina', 1),
(33, 'Caucasia', 1),
(34, 'Chigorodó', 1),
(35, 'Cisneros', 1),
(36, 'Cocorná', 1),
(37, 'Concepción', 1),
(38, 'Concordia', 1),
(39, 'Copacabana', 1),
(40, 'Dabeiba', 1),
(41, 'Donmatías', 1),
(42, 'Ebéjico', 1),
(43, 'El Bagre', 1),
(44, 'Entrerríos', 1),
(45, 'Envigado', 1),
(46, 'Fredonia', 1),
(47, 'Frontino', 1),
(48, 'Giraldo', 1),
(49, 'Girardota', 1),
(50, 'Gómez Plata', 1),
(51, 'Granada', 1),
(52, 'Guadalupe', 1),
(53, 'Guarne', 1),
(54, 'Guatapé', 1),
(55, 'Heliconia', 1),
(56, 'Hispania', 1),
(57, 'Itagüí', 1),
(58, 'Ituango', 1),
(59, 'Jardín', 1),
(60, 'Jericó', 1),
(61, 'La Ceja', 1),
(62, 'La Estrella', 1),
(63, 'La Pintada', 1),
(64, 'La Unión', 1),
(65, 'Liborina', 1),
(66, 'Maceo', 1),
(67, 'Marinilla', 1),
(68, 'Montebello', 1),
(69, 'Murindó', 1),
(70, 'Mutatá', 1),
(71, 'Nariño', 1),
(72, 'Nechí', 1),
(73, 'Olaya', 1),
(74, 'Peñol', 1),
(75, 'Peque', 1),
(76, 'Pueblorrico', 1),
(77, 'Puerto Berrío', 1),
(78, 'Puerto Nare', 1),
(79, 'Puerto Triunfo', 1),
(80, 'Remedios', 1),
(81, 'Retiro', 1),
(82, 'Rionegro', 1),
(83, 'Sabanalarga', 1),
(84, 'Sabaneta', 1),
(85, 'Salgar', 1),
(86, 'San Andrés de Cuerquia', 1),
(87, 'San Carlos', 1),
(88, 'San Francisco', 1),
(89, 'San Jerónimo', 1),
(90, 'San José de la Montaña', 1),
(91, 'San Juan de Urabá', 1),
(92, 'San Luis', 1),
(93, 'San Pedro', 1),
(94, 'San Pedro de Urabá', 1),
(95, 'San Rafael', 1),
(96, 'San Roque', 1),
(97, 'San Vicente', 1),
(98, 'Santa Bárbara', 1),
(99, 'Santa Rosa de Osos', 1),
(100, 'Santo Domingo', 1),
(101, 'El Santuario', 1),
(102, 'Segovia', 1),
(103, 'Sonsón', 1),
(104, 'Sopetrán', 1),
(105, 'Támesis', 1),
(106, 'Tarazá', 1),
(107, 'Tarso', 1),
(108, 'Titiribí', 1),
(109, 'Toledo', 1),
(110, 'Turbo', 1),
(111, 'Uramita', 1),
(112, 'Urrao', 1),
(113, 'Valdivia', 1),
(114, 'Valparaíso', 1),
(115, 'Vegachí', 1),
(116, 'Venecia', 1),
(117, 'Vigía del Fuerte', 1),
(118, 'Yalí', 1),
(119, 'Yarumal', 1),
(120, 'Yolombó', 1),
(121, 'Yondó', 1),
(122, 'Zaragoza', 1),
(125, 'Barranquilla', 2),
(126, 'Baranoa', 2),
(127, 'Campo de la Cruz', 2),
(128, 'Candelaria', 2),
(129, 'Galapa', 2),
(130, 'Juan de Acosta', 2),
(131, 'Luruaco', 2),
(132, 'Malambo', 2),
(133, 'Manatí', 2),
(134, 'Palmar de Varela', 2),
(135, 'Piojó', 2),
(136, 'Polonuevo', 2),
(137, 'Ponedera', 2),
(138, 'Puerto Colombia', 2),
(139, 'Repelón', 2),
(140, 'Sabanagrande', 2),
(141, 'Sabanalarga', 2),
(142, 'Santa Lucía', 2),
(143, 'Santo Tomás', 2),
(144, 'Soledad', 2),
(145, 'Suán', 2),
(146, 'Tubará', 2),
(147, 'Usiacurí', 2),
(164, 'Sabanalarga', 2),
(165, 'Santa Lucía', 2),
(166, 'Santo Tomás', 2),
(167, 'Soledad', 2),
(168, 'Suán', 2),
(171, 'Bogotá, D.C.', 3),
(172, 'Cartagena', 4),
(173, 'Achí', 4),
(174, 'Altos del Rosario', 4),
(175, 'Arenal', 4),
(176, 'Arjona', 4),
(177, 'Arroyohondo', 4),
(178, 'Barranco de Loba', 4),
(179, 'Calamar', 4),
(180, 'Cantagallo', 4),
(181, 'Cicuco', 4),
(182, 'Clemencia', 4),
(183, 'Córdoba', 4),
(184, 'El Carmen de Bolívar', 4),
(185, 'El Guamo', 4),
(186, 'El Peñón', 4),
(187, 'Hatillo de Loba', 4),
(188, 'Magangué', 4),
(189, 'Mahates', 4),
(190, 'Margarita', 4),
(191, 'María la Baja', 4),
(192, 'Mompós', 4),
(193, 'Montecristo', 4),
(194, 'Morales', 4),
(195, 'Norosí', 4),
(196, 'Pinillos', 4),
(197, 'Regidor', 4),
(198, 'Río Viejo', 4),
(199, 'San Cristóbal', 4),
(200, 'San Estanislao', 4),
(201, 'San Fernando', 4),
(202, 'San Jacinto', 4),
(203, 'San Jacinto del Cauca', 4),
(204, 'San Juan Nepomuceno', 4),
(205, 'San Martín de Loba', 4),
(206, 'San Pablo', 4),
(207, 'Santa Catalina', 4),
(208, 'Santa Rosa', 4),
(209, 'Santa Rosa del Sur', 4),
(210, 'Simití', 4),
(211, 'Soplaviento', 4),
(212, 'Talaigua Nuevo', 4),
(213, 'Tiquisio', 4),
(214, 'Turbaco', 4),
(215, 'Turbaná', 4),
(216, 'Villanueva', 4),
(217, 'Zambrano', 4),
(218, 'Tunja', 5),
(219, 'Almeida', 5),
(220, 'Aquitania', 5),
(221, 'Arcabuco', 5),
(222, 'Belén', 5),
(223, 'Berbeo', 5),
(224, 'Betéitiva', 5),
(225, 'Boavita', 5),
(226, 'Boyacá', 5),
(227, 'Briceño', 5),
(228, 'Buenavista', 5),
(229, 'Busbanzá', 5),
(230, 'Caldas', 5),
(231, 'Campohermoso', 5),
(232, 'Cerinza', 5),
(233, 'Chinavita', 5),
(234, 'Chiquinquirá', 5),
(235, 'Chíquiza', 5),
(236, 'Chiscas', 5),
(237, 'Chita', 5),
(238, 'Chitaraque', 5),
(239, 'Chivatá', 5),
(240, 'Ciénega', 5),
(241, 'Cómbita', 5),
(242, 'Coper', 5),
(243, 'Corrales', 5),
(244, 'Covarachía', 5),
(245, 'Cubará', 5),
(246, 'Cucaita', 5),
(247, 'Cuitiva', 5),
(248, 'El Cocuy', 5),
(249, 'El Espino', 5),
(250, 'Firavitoba', 5),
(251, 'Floresta', 5),
(252, 'Gachantivá', 5),
(253, 'Gámeza', 5),
(254, 'Garagoa', 5),
(255, 'Guacamayas', 5),
(256, 'Guateque', 5),
(257, 'Guayatá', 5),
(258, 'Güicán', 5),
(259, 'Iza', 5),
(260, 'Jenesano', 5),
(261, 'Jericó', 5),
(262, 'La Capilla', 5),
(263, 'La Uvita', 5),
(264, 'La Victoria', 5),
(265, 'Labranzagrande', 5),
(266, 'Macanal', 5),
(267, 'Maripí', 5),
(268, 'Miraflores', 5),
(269, 'Mongua', 5),
(270, 'Monguí', 5),
(271, 'Moniquirá', 5),
(272, 'Motavita', 5),
(273, 'Muzo', 5),
(274, 'Nobsa', 5),
(275, 'Nuevo Colón', 5),
(276, 'Oicatá', 5),
(277, 'Otanche', 5),
(278, 'Pachavita', 5),
(279, 'Páez', 5),
(280, 'Paipa', 5),
(281, 'Pajarito', 5),
(282, 'Panqueba', 5),
(283, 'Pauna', 5),
(284, 'Paya', 5),
(285, 'Paz de Río', 5),
(286, 'Pesca', 5),
(287, 'Pisba', 5),
(288, 'Puerto Boyacá', 5),
(289, 'Quípama', 5),
(290, 'Ramiriquí', 5),
(291, 'Ráquira', 5),
(292, 'Rondón', 5),
(293, 'Saboyá', 5),
(294, 'Sáchica', 5),
(295, 'Samacá', 5),
(296, 'San Eduardo', 5),
(297, 'San José de Pare', 5),
(298, 'San Luis de Gaceno', 5),
(299, 'San Mateo', 5),
(300, 'San Miguel de Sema', 5),
(301, 'San Pablo de Borbur', 5),
(302, 'Santa María', 5),
(303, 'Santa Rosa de Viterbo', 5),
(304, 'Santa Sofía', 5),
(305, 'Santana', 5),
(306, 'Sativanorte', 5),
(307, 'Sativasur', 5),
(308, 'Siachoque', 5),
(309, 'Soatá', 5),
(310, 'Socha', 5),
(311, 'Socotá', 5),
(312, 'Sogamoso', 5),
(313, 'Somondoco', 5),
(314, 'Sora', 5),
(315, 'Sotaquirá', 5),
(316, 'Soracá', 5),
(317, 'Susacón', 5),
(318, 'Sutamarchán', 5),
(319, 'Sutatenza', 5),
(320, 'Tasco', 5),
(321, 'Tenza', 5),
(322, 'Tibaná', 5),
(323, 'Tibasosa', 5),
(324, 'Tinjacá', 5),
(325, 'Tipacoque', 5),
(326, 'Toca', 5),
(327, 'Togüí', 5),
(328, 'Tópaga', 5),
(329, 'Tota', 5),
(330, 'Tunungua', 5),
(331, 'Turmequé', 5),
(332, 'Tuta', 5),
(333, 'Tutazá', 5),
(334, 'Úmbita', 5),
(335, 'Ventaquemada', 5),
(336, 'Villa de Leyva', 5),
(337, 'Viracachá', 5),
(338, 'Zetaquira', 5),
(339, 'Manizales', 6),
(340, 'Aguadas', 6),
(341, 'Anserma', 6),
(342, 'Aranzazu', 6),
(343, 'Belalcázar', 6),
(344, 'Chinchiná', 6),
(345, 'Filadelfia', 6),
(346, 'La Dorada', 6),
(347, 'La Merced', 6),
(348, 'Manzanares', 6),
(349, 'Marmato', 6),
(350, 'Marquetalia', 6),
(351, 'Marulanda', 6),
(352, 'Neira', 6),
(353, 'Norcasia', 6),
(354, 'Pácora', 6),
(355, 'Palestina', 6),
(356, 'Pensilvania', 6),
(357, 'Riosucio', 6),
(358, 'Risaralda', 6),
(359, 'Salamina', 6),
(360, 'Samaná', 6),
(361, 'San José', 6),
(362, 'Supía', 6),
(363, 'Victoria', 6),
(364, 'Villamaría', 6),
(365, 'Viterbo', 6),
(366, 'Florencia', 7),
(367, 'Albania', 7),
(368, 'Belén de los Andaquíes', 7),
(369, 'Cartagena del Chairá', 7),
(370, 'Curillo', 7),
(371, 'El Doncello', 7),
(372, 'El Paujil', 7),
(373, 'La Montañita', 7),
(374, 'Milán', 7),
(375, 'Morelia', 7),
(376, 'Puerto Rico', 7),
(377, 'San José del Fragua', 7),
(378, 'San Vicente del Caguán', 7),
(379, 'Solano', 7),
(380, 'Solita', 7),
(381, 'Valparaíso', 7),
(382, 'Popayán', 8),
(383, 'Almaguer', 8),
(384, 'Argelia', 8),
(385, 'Balboa', 8),
(386, 'Bolívar', 8),
(387, 'Buenos Aires', 8),
(388, 'Cajibío', 8),
(389, 'Caldono', 8),
(390, 'Caloto', 8),
(391, 'Corinto', 8),
(392, 'El Tambo', 8),
(393, 'Florencia', 8),
(394, 'Guachené', 8),
(395, 'Guapí', 8),
(396, 'Inzá', 8),
(397, 'Jambaló', 8),
(398, 'La Sierra', 8),
(399, 'La Vega', 8),
(400, 'López', 8),
(401, 'Mercaderes', 8),
(402, 'Miranda', 8),
(403, 'Morales', 8),
(404, 'Padilla', 8),
(405, 'Páez', 8),
(406, 'Patía', 8),
(407, 'Piamonte', 8),
(408, 'Piendamó', 8),
(409, 'Puerto Tejada', 8),
(410, 'Puracé', 8),
(411, 'Rosas', 8),
(412, 'San Sebastián', 8),
(413, 'Santa Rosa', 8),
(414, 'Santander de Quilichao', 8),
(415, 'Silvia', 8),
(416, 'Sotará', 8),
(417, 'Suárez', 8),
(418, 'Sucre', 8),
(419, 'Timbío', 8),
(420, 'Timbiquí', 8),
(421, 'Toribío', 8),
(422, 'Totoró', 8),
(423, 'Villa Rica', 8),
(424, 'Valledupar', 9),
(425, 'Aguachica', 9),
(426, 'Agustín Codazzi', 9),
(427, 'Astrea', 9),
(428, 'Becerril', 9),
(429, 'Bosconia', 9),
(430, 'Chimichagua', 9),
(431, 'Chiriguaná', 9),
(432, 'Curumaní', 9),
(433, 'El Copey', 9),
(434, 'El Paso', 9),
(435, 'Gamarra', 9),
(436, 'González', 9),
(437, 'La Gloria', 9),
(438, 'La Jagua de Ibirico', 9),
(439, 'La Paz', 9),
(440, 'Manaure Balcón del Cesar', 9),
(441, 'Pailitas', 9),
(442, 'Pelaya', 9),
(443, 'Pueblo Bello', 9),
(444, 'Río de Oro', 9),
(445, 'San Alberto', 9),
(446, 'San Diego', 9),
(447, 'San Martín', 9),
(448, 'Tamalameque', 9),
(449, 'Montería', 10),
(450, 'Ayapel', 10),
(451, 'Buenavista', 10),
(452, 'Canalete', 10),
(453, 'Cereté', 10),
(454, 'Chimá', 10),
(455, 'Chinú', 10),
(456, 'Ciénaga de Oro', 10),
(457, 'Cotorra', 10),
(458, 'La Apartada', 10),
(459, 'Lorica', 10),
(460, 'Los Córdobas', 10),
(461, 'Momil', 10),
(462, 'Montelíbano', 10),
(463, 'Moñitos', 10),
(464, 'Planeta Rica', 10),
(465, 'Pueblo Nuevo', 10),
(466, 'Puerto Escondido', 10),
(467, 'Puerto Libertador', 10),
(468, 'Purísima', 10),
(469, 'Sahagún', 10),
(470, 'San Andrés Sotavento', 10),
(471, 'San Antero', 10),
(472, 'San Bernardo del Viento', 10),
(473, 'San Carlos', 10),
(474, 'San José de Uré', 10),
(475, 'San Pelayo', 10),
(476, 'Tierralta', 10),
(477, 'Tuchín', 10),
(478, 'Valencia', 10),
(479, 'Agua de Dios', 11),
(480, 'Albán', 11),
(481, 'Anapoima', 11),
(482, 'Anolaima', 11),
(483, 'Arbeláez', 11),
(484, 'Beltrán', 11),
(485, 'Bituima', 11),
(486, 'Bojacá', 11),
(487, 'Cabrera', 11),
(488, 'Cachipay', 11),
(489, 'Cajicá', 11),
(490, 'Caparrapí', 11),
(491, 'Caqueza', 11),
(492, 'Carmen de Carupa', 11),
(493, 'Chaguaní', 11),
(494, 'Chía', 11),
(495, 'Chipaque', 11),
(496, 'Choachí', 11),
(497, 'Chocontá', 11),
(498, 'Cogua', 11),
(499, 'Cota', 11),
(500, 'Cucunubá', 11),
(501, 'El Colegio', 11),
(502, 'El Peñón', 11),
(503, 'El Rosal', 11),
(504, 'Facatativá', 11),
(505, 'Fómeque', 11),
(506, 'Fosca', 11),
(507, 'Funza', 11),
(508, 'Fúquene', 11),
(509, 'Fusagasugá', 11),
(510, 'Gachala', 11),
(511, 'Gachancipá', 11),
(512, 'Gachetá', 11),
(513, 'Gama', 11),
(514, 'Girardot', 11),
(515, 'Granada', 11),
(516, 'Guachetá', 11),
(517, 'Guaduas', 11),
(518, 'Guasca', 11),
(519, 'Guataquí', 11),
(520, 'Guatavita', 11),
(521, 'Guayabal de Siquima', 11),
(522, 'Guayabetal', 11),
(523, 'Gutiérrez', 11),
(524, 'Jerusalén', 11),
(525, 'Junín', 11),
(526, 'La Calera', 11),
(527, 'La Mesa', 11),
(528, 'La Palma', 11),
(529, 'La Peña', 11),
(530, 'La Vega', 11),
(531, 'Lenguazaque', 11),
(532, 'Machetá', 11),
(533, 'Madrid', 11),
(534, 'Manta', 11),
(535, 'Medina', 11),
(536, 'Mosquera', 11),
(537, 'Nariño', 11),
(538, 'Nemocón', 11),
(539, 'Nilo', 11),
(540, 'Nimaima', 11),
(541, 'Nocaima', 11),
(542, 'Pacho', 11),
(543, 'Paime', 11),
(544, 'Pandi', 11),
(545, 'Paratebueno', 11),
(546, 'Pasca', 11),
(547, 'Puerto Salgar', 11),
(548, 'Pulí', 11),
(549, 'Quebradanegra', 11),
(550, 'Quetame', 11),
(551, 'Quipile', 11),
(552, 'Apulo', 11),
(553, 'Ricaurte', 11),
(554, 'San Antonio del Tequendama', 11),
(555, 'San Bernardo', 11),
(556, 'San Cayetano', 11),
(557, 'San Francisco', 11),
(558, 'San Juan de Rioseco', 11),
(559, 'Sasaima', 11),
(560, 'Sesquilé', 11),
(561, 'Sibaté', 11),
(562, 'Silvania', 11),
(563, 'Simijaca', 11),
(564, 'Soacha', 11),
(565, 'Sopó', 11),
(566, 'Subachoque', 11),
(567, 'Suesca', 11),
(568, 'Supatá', 11),
(569, 'Susa', 11),
(570, 'Sutatausa', 11),
(571, 'Tabio', 11),
(572, 'Tausa', 11),
(573, 'Tena', 11),
(574, 'Tenjo', 11),
(575, 'Tibacuy', 11),
(576, 'Tibirita', 11),
(577, 'Tocaima', 11),
(578, 'Tocancipá', 11),
(579, 'Topaipí', 11),
(580, 'Ubalá', 11),
(581, 'Ubaque', 11),
(582, 'Ubaté', 11),
(583, 'Une', 11),
(584, 'Útica', 11),
(585, 'Venecia', 11),
(586, 'Vergara', 11),
(587, 'Vianí', 11),
(588, 'Villagómez', 11),
(589, 'Villapinzón', 11),
(590, 'Villeta', 11),
(591, 'Viotá', 11),
(592, 'Yacopí', 11),
(593, 'Zipacón', 11),
(594, 'Zipaquirá', 11),
(595, 'Nóvita', 12),
(596, 'Nuquí', 12),
(597, 'Río Iró', 12),
(598, 'Río Quito', 12),
(599, 'Riosucio', 12),
(600, 'San José del Palmar', 12),
(601, 'Sipí', 12),
(602, 'Tadó', 12),
(603, 'Ungía', 12),
(604, 'Unión Panamericana', 12),
(605, 'Neiva', 13),
(606, 'Acevedo', 13),
(607, 'Agrado', 13),
(608, 'Aipe', 13),
(609, 'Algeciras', 13),
(610, 'Altamira', 13),
(611, 'Baraya', 13),
(612, 'Campoalegre', 13),
(613, 'Colombia', 13),
(614, 'Elías', 13),
(615, 'Garzón', 13),
(616, 'Gigante', 13),
(617, 'Guadalupe', 13),
(618, 'Hobo', 13),
(619, 'Iquira', 13),
(620, 'Isnos', 13),
(621, 'La Argentina', 13),
(622, 'La Plata', 13),
(623, 'Nátaga', 13),
(624, 'Oporapa', 13),
(625, 'Paicol', 13),
(626, 'Palermo', 13),
(627, 'Palestina', 13),
(628, 'Pital', 13),
(629, 'Pitalito', 13),
(630, 'Rivera', 13),
(631, 'Saladoblanco', 13),
(632, 'San Agustín', 13),
(633, 'Santa María', 13),
(634, 'Suaza', 13),
(635, 'Tarqui', 13),
(636, 'Tello', 13),
(637, 'Teruel', 13),
(638, 'Tesalia', 13),
(639, 'Timaná', 13),
(640, 'Villavieja', 13),
(641, 'Yaguará', 13),
(642, 'Riohacha', 14),
(643, 'Albania', 14),
(644, 'Barrancas', 14),
(645, 'Dibulla', 14),
(646, 'Distracción', 14),
(647, 'El Molino', 14),
(648, 'Fonseca', 14),
(649, 'Hatonuevo', 14),
(650, 'La Jagua del Pilar', 14),
(651, 'Maicao', 14),
(652, 'Manaure', 14),
(653, 'San Juan del Cesar', 14),
(654, 'Uribia', 14),
(655, 'Urumita', 14),
(656, 'Villanueva', 14),
(657, 'Santa Marta', 15),
(658, 'Algarrobo', 15),
(659, 'Aracataca', 15),
(660, 'Ariguaní', 15),
(661, 'Cerro San Antonio', 15),
(662, 'Chibolo', 15),
(663, 'Ciénaga', 15),
(664, 'Concordia', 15),
(665, 'El Banco', 15),
(666, 'El Piñón', 15),
(667, 'El Retén', 15),
(668, 'Fundación', 15),
(669, 'Guamal', 15),
(670, 'Nueva Granada', 15),
(671, 'Pedraza', 15),
(672, 'Pijiño del Carmen', 15),
(673, 'Pivijay', 15),
(674, 'Plato', 15),
(675, 'Puebloviejo', 15),
(676, 'Remolino', 15),
(677, 'Sabanas de San Ángel', 15),
(678, 'Salamina', 15),
(679, 'San Sebastián de Buenavista', 15),
(680, 'San Zenón', 15),
(681, 'Santa Ana', 15),
(682, 'Santa Bárbara de Pinto', 15),
(683, 'Sitionuevo', 15),
(684, 'Tenerife', 15),
(685, 'Zapayán', 15),
(686, 'Zona Bananera', 15),
(687, 'Villavicencio', 16),
(688, 'Acacías', 16),
(689, 'Barranca de Upía', 16),
(690, 'Cabuyaro', 16),
(691, 'Castilla La Nueva', 16),
(692, 'Cubarral', 16),
(693, 'Cumaral', 16),
(694, 'El Calvario', 16),
(695, 'El Castillo', 16),
(696, 'El Dorado', 16),
(697, 'Fuente de Oro', 16),
(698, 'Granada', 16),
(699, 'Guamal', 16),
(700, 'La Macarena', 16),
(701, 'Lejanías', 16),
(702, 'Mapiripán', 16),
(703, 'Mesetas', 16),
(704, 'Puerto Concordia', 16),
(705, 'Puerto Gaitán', 16),
(706, 'Puerto Lleras', 16),
(707, 'Puerto López', 16),
(708, 'Puerto Rico', 16),
(709, 'Restrepo', 16),
(710, 'San Carlos de Guaroa', 16),
(711, 'San Juan de Arama', 16),
(712, 'San Juanito', 16),
(713, 'San Martín', 16),
(714, 'Uribe', 16),
(715, 'Vistahermosa', 16),
(716, 'Pasto', 17),
(717, 'Albán', 17),
(718, 'Aldana', 17),
(719, 'Ancuyá', 17),
(720, 'Arboleda', 17),
(721, 'Barbacoas', 17),
(722, 'Belén', 17),
(723, 'Buesaco', 17),
(724, 'Chachagüí', 17),
(725, 'Colón', 17),
(726, 'Consacá', 17),
(727, 'Contadero', 17),
(728, 'Córdoba', 17),
(729, 'Cuaspud', 17),
(730, 'Cumbal', 17),
(731, 'Cumbitara', 17),
(732, 'El Charco', 17),
(733, 'El Peñol', 17),
(734, 'El Rosario', 17),
(735, 'El Tablón de Gómez', 17),
(736, 'El Tambo', 17),
(737, 'Francisco Pizarro', 17),
(738, 'Funes', 17),
(739, 'Guachucal', 17),
(740, 'Guaitarilla', 17),
(741, 'Gualmatán', 17),
(742, 'Iles', 17),
(743, 'Imués', 17),
(744, 'Ipiales', 17),
(745, 'La Cruz', 17),
(746, 'La Florida', 17),
(747, 'La Llanada', 17),
(748, 'La Tola', 17),
(749, 'La Unión', 17),
(750, 'Leiva', 17),
(751, 'Linares', 17),
(752, 'Los Andes', 17),
(753, 'Magüí', 17),
(754, 'Mallama', 17),
(755, 'Mosquera', 17),
(756, 'Nariño', 17),
(757, 'Olaya Herrera', 17),
(758, 'Ospina', 17),
(759, 'Policarpa', 17),
(760, 'Potosí', 17),
(761, 'Providencia', 17),
(762, 'Puerres', 17),
(763, 'Pupiales', 17),
(764, 'Ricaurte', 17),
(765, 'Roberto Payán', 17),
(766, 'Samaniego', 17),
(767, 'San Bernardo', 17),
(768, 'San Lorenzo', 17),
(769, 'San Pablo', 17),
(770, 'San Pedro de Cartago', 17),
(771, 'Sandoná', 17),
(772, 'Santa Bárbara', 17),
(773, 'Santacruz', 17),
(774, 'Sapuyes', 17),
(775, 'Taminango', 17),
(776, 'Tangua', 17),
(777, 'Tumaco', 17),
(778, 'Túquerres', 17),
(779, 'Yacuanquer', 17),
(780, 'Cúcuta', 18),
(781, 'Abrego', 18),
(782, 'Arboledas', 18),
(783, 'Bochalema', 18),
(784, 'Bucarasica', 18),
(785, 'Cácota', 18),
(786, 'Cachirá', 18),
(787, 'Chinácota', 18),
(788, 'Chitagá', 18),
(789, 'Convención', 18),
(790, 'Cucutilla', 18),
(791, 'Duranía', 18),
(792, 'El Carmen', 18),
(793, 'El Tarra', 18),
(794, 'El Zulia', 18),
(795, 'Gramalote', 18),
(796, 'Hacarí', 18),
(797, 'Herrán', 18),
(798, 'La Esperanza', 18),
(799, 'La Playa', 18),
(800, 'Labateca', 18),
(801, 'Los Patios', 18),
(802, 'Lourdes', 18),
(803, 'Mutiscua', 18),
(804, 'Ocaña', 18),
(805, 'Pamplona', 18),
(806, 'Pamplonita', 18),
(807, 'Puerto Santander', 18),
(808, 'Ragonvalia', 18),
(809, 'Salazar de Las Palmas', 18),
(810, 'San Calixto', 18),
(811, 'San Cayetano', 18),
(812, 'Santiago', 18),
(813, 'Sardinata', 18),
(814, 'Silos', 18),
(815, 'Teorama', 18),
(816, 'Tibú', 18),
(817, 'Toledo', 18),
(818, 'Villa Caro', 18),
(819, 'Villa del Rosario', 18),
(820, 'Armenia', 19),
(821, 'Buenavista', 19),
(822, 'Calarcá', 19),
(823, 'Circasia', 19),
(824, 'Córdoba', 19),
(825, 'Filandia', 19),
(826, 'Génova', 19),
(827, 'La Tebaida', 19),
(828, 'Montenegro', 19),
(829, 'Pijao', 19),
(830, 'Quimbaya', 19),
(831, 'Salento', 19),
(832, 'Pereira', 20),
(833, 'Apía', 20),
(834, 'Balboa', 20),
(835, 'Belén de Umbría', 20),
(836, 'Dosquebradas', 20),
(837, 'Guática', 20),
(838, 'La Celia', 20),
(839, 'La Virginia', 20),
(840, 'Marsella', 20),
(841, 'Mistrató', 20),
(842, 'Pueblo Rico', 20),
(843, 'Quinchía', 20),
(844, 'Santa Rosa de Cabal', 20),
(845, 'Santuario', 20),
(846, 'Bucaramanga', 21),
(847, 'Aguada', 21),
(848, 'Albania', 21),
(849, 'Aratoca', 21),
(850, 'Barbosa', 21),
(851, 'Barichara', 21),
(852, 'Barrancabermeja', 21),
(853, 'Betulia', 21),
(854, 'Bolívar', 21),
(855, 'Cabrera', 21),
(856, 'California', 21),
(857, 'Capitanejo', 21),
(858, 'Carcasí', 21),
(859, 'Cepitá', 21),
(860, 'Cerrito', 21),
(861, 'Charalá', 21),
(862, 'Charta', 21),
(863, 'Chima', 21),
(864, 'Chipatá', 21),
(865, 'Cimitarra', 21),
(866, 'Concepción', 21),
(867, 'Confines', 21),
(868, 'Contratación', 21),
(869, 'Coromoro', 21),
(870, 'Curití', 21),
(871, 'El Carmen de Chucurí', 21),
(872, 'El Guacamayo', 21),
(873, 'El Peñón', 21),
(874, 'El Playón', 21),
(875, 'Encino', 21),
(876, 'Enciso', 21),
(877, 'Florián', 21),
(878, 'Floridablanca', 21),
(879, 'Galán', 21),
(880, 'Gámbita', 21),
(881, 'Girón', 21),
(882, 'Guaca', 21),
(883, 'Guadalupe', 21),
(884, 'Guapotá', 21),
(885, 'Guavatá', 21),
(886, 'Güepsa', 21),
(887, 'Hato', 21),
(888, 'Jesús María', 21),
(889, 'Jordán', 21),
(890, 'La Belleza', 21),
(891, 'La Paz', 21),
(892, 'Landázuri', 21),
(893, 'Lebrija', 21),
(894, 'Los Santos', 21),
(895, 'Macaravita', 21),
(896, 'Málaga', 21),
(897, 'Matanza', 21),
(898, 'Mogotes', 21),
(899, 'Molagavita', 21),
(900, 'Ocamonte', 21),
(901, 'Oiba', 21),
(902, 'Onzaga', 21),
(903, 'Palmar', 21),
(904, 'Palmas del Socorro', 21),
(905, 'Páramo', 21),
(906, 'Piedecuesta', 21),
(907, 'Pinchote', 21),
(908, 'Puente Nacional', 21),
(909, 'Puerto Parra', 21),
(910, 'Puerto Wilches', 21),
(911, 'Rionegro', 21),
(912, 'Sabana de Torres', 21),
(913, 'San Andrés', 21),
(914, 'San Benito', 21),
(915, 'San Gil', 21),
(916, 'San Joaquín', 21),
(917, 'San José de Miranda', 21),
(918, 'San Miguel', 21),
(919, 'San Vicente de Chucurí', 21),
(920, 'Santa Bárbara', 21),
(921, 'Santa Helena del Opón', 21),
(922, 'Simacota', 21),
(923, 'Socorro', 21),
(924, 'Suaita', 21),
(925, 'Sucre', 21),
(926, 'Suratá', 21),
(927, 'Tona', 21),
(928, 'Valle de San José', 21),
(929, 'Vélez', 21),
(930, 'Vetas', 21),
(931, 'Villanueva', 21),
(932, 'Zapatoca', 21),
(933, 'Sincelejo', 22),
(934, 'Buenavista', 22),
(935, 'Caimito', 22),
(936, 'Chalán', 22),
(937, 'Colosó', 22),
(938, 'Corozal', 22),
(939, 'Coveñas', 22),
(940, 'El Roble', 22),
(941, 'Galeras', 22),
(942, 'Guaranda', 22),
(943, 'La Unión', 22),
(944, 'Los Palmitos', 22),
(945, 'Majagual', 22),
(946, 'Morroa', 22),
(947, 'Ovejas', 22),
(948, 'Palmito', 22),
(949, 'Sampués', 22),
(950, 'San Benito Abad', 22),
(951, 'San Juan de Betulia', 22),
(952, 'San Marcos', 22),
(953, 'San Onofre', 22),
(954, 'San Pedro', 22),
(955, 'Santiago de Tolú', 22),
(956, 'Since', 22),
(957, 'Sucre', 22),
(958, 'Tolú Viejo', 22),
(959, 'Ibagué', 23),
(960, 'Alpujarra', 23),
(961, 'Alvarado', 23),
(962, 'Ambalema', 23),
(963, 'Anzoátegui', 23),
(964, 'Armero', 23),
(965, 'Ataco', 23),
(966, 'Cajamarca', 23),
(967, 'Carmen de Apicalá', 23),
(968, 'Casabianca', 23),
(969, 'Chaparral', 23),
(970, 'Coello', 23),
(971, 'Coyaima', 23),
(972, 'Cunday', 23),
(973, 'Dolores', 23),
(974, 'Espinal', 23),
(975, 'Falan', 23),
(976, 'Flandes', 23),
(977, 'Fresno', 23),
(978, 'Guamo', 23),
(979, 'Herveo', 23),
(980, 'Honda', 23),
(981, 'Icononzo', 23),
(982, 'Lérida', 23),
(983, 'Líbano', 23),
(984, 'Mariquita', 23),
(985, 'Melgar', 23),
(986, 'Murillo', 23),
(987, 'Natagaima', 23),
(988, 'Ortega', 23),
(989, 'Palocabildo', 23),
(990, 'Piedras', 23),
(991, 'Planadas', 23),
(992, 'Prado', 23),
(993, 'Purificación', 23),
(994, 'Rioblanco', 23),
(995, 'Roncesvalles', 23),
(996, 'Rovira', 23),
(997, 'Saldaña', 23),
(998, 'San Antonio', 23),
(999, 'San Luis', 23),
(1000, 'Santa Isabel', 23),
(1001, 'Suárez', 23),
(1002, 'Valle de San Juan', 23),
(1003, 'Venadillo', 23),
(1004, 'Villahermosa', 23),
(1005, 'Villarrica', 23),
(1006, 'Cali', 24),
(1007, 'Alcalá', 24),
(1008, 'Andalucía', 24),
(1009, 'Ansermanuevo', 24),
(1010, 'Argelia', 24),
(1011, 'Bolívar', 24),
(1012, 'Buenaventura', 24),
(1013, 'Bugalagrande', 24),
(1014, 'Caicedonia', 24),
(1015, 'Calima', 24),
(1016, 'Candelaria', 24),
(1017, 'Cartago', 24),
(1018, 'Dagua', 24),
(1019, 'El Águila', 24),
(1020, 'El Cairo', 24),
(1021, 'El Cerrito', 24),
(1022, 'El Dovio', 24),
(1023, 'Florida', 24),
(1024, 'Ginebra', 24),
(1025, 'Guacarí', 24),
(1026, 'Jamundí', 24),
(1027, 'La Cumbre', 24),
(1028, 'La Unión', 24),
(1029, 'La Victoria', 24),
(1030, 'Obando', 24),
(1031, 'Palmira', 24),
(1032, 'Pradera', 24),
(1033, 'Restrepo', 24),
(1034, 'Riofrío', 24),
(1035, 'Roldanillo', 24),
(1036, 'San Pedro', 24),
(1037, 'Sevilla', 24),
(1038, 'Toro', 24),
(1039, 'Trujillo', 24),
(1040, 'Tuluá', 24),
(1041, 'Ulloa', 24),
(1042, 'Versalles', 24),
(1043, 'Vijes', 24),
(1044, 'Yotoco', 24),
(1045, 'Yumbo', 24),
(1046, 'Zarzal', 24),
(1047, 'Arauca', 25),
(1048, 'Arauquita', 25),
(1049, 'Cravo Norte', 25),
(1050, 'Fortul', 25),
(1051, 'Puerto Rondón', 25),
(1052, 'Saravena', 25),
(1053, 'Tame', 25),
(1054, 'Yopal', 26),
(1055, 'Aguazul', 26),
(1056, 'Chámeza', 26),
(1057, 'Hato Corozal', 26),
(1058, 'La Salina', 26),
(1059, 'Maní', 26),
(1060, 'Monterrey', 26),
(1061, 'Nunchía', 26),
(1062, 'Orocué', 26),
(1063, 'Paz de Ariporo', 26),
(1064, 'Pore', 26),
(1065, 'Recetor', 26),
(1066, 'Sabanalarga', 26),
(1067, 'Sácama', 26),
(1068, 'San Luis de Palenque', 26),
(1069, 'Támara', 26),
(1070, 'Tauramena', 26),
(1071, 'Trinidad', 26),
(1072, 'Villanueva', 26),
(1073, 'Mocoa', 27),
(1074, 'Colón', 27),
(1075, 'Orito', 27),
(1076, 'Puerto Asís', 27),
(1077, 'Puerto Caicedo', 27),
(1078, 'Puerto Guzmán', 27),
(1079, 'Leguízamo', 27),
(1080, 'San Francisco', 27),
(1081, 'San Miguel', 27),
(1082, 'Santiago', 27),
(1083, 'Sibundoy', 27),
(1084, 'Valle del Guamuez', 27),
(1085, 'Villagarzón', 27),
(1086, 'San Andrés', 28),
(1087, 'Providencia', 28),
(1088, 'Santa Catalina', 28),
(1089, 'Leticia', 29),
(1090, 'El Encanto', 29),
(1091, 'La Chorrera', 29),
(1092, 'La Pedrera', 29),
(1093, 'La Victoria', 29),
(1094, 'Miriti - Paraná', 29),
(1095, 'Puerto Alegría', 29),
(1096, 'Puerto Arica', 29),
(1097, 'Puerto Nariño', 29),
(1098, 'Puerto Santander', 29),
(1099, 'Tarapacá', 29),
(1100, 'Inírida', 30),
(1101, 'Barranco Minas', 30),
(1102, 'Cacahual', 30),
(1103, 'La Guadalupe', 30),
(1104, 'Mapiripana', 30),
(1105, 'Morichal', 30),
(1106, 'Pana Pana', 30),
(1107, 'Puerto Colombia', 30),
(1108, 'San Felipe', 30),
(1109, 'San José del Guaviare', 31),
(1110, 'Calamar', 31),
(1111, 'El Retorno', 31),
(1112, 'Miraflores', 31),
(1113, 'Mitú', 32),
(1114, 'Carurú', 32),
(1115, 'Pacoa', 32),
(1116, 'Taraira', 32),
(1117, 'Papunaua', 32),
(1118, 'Yavaraté', 32),
(1119, 'Puerto Carreño', 33),
(1120, 'La Primavera', 33),
(1121, 'Santa Rosalía', 33),
(1122, 'Cumaribo', 33)
ON CONFLICT (id_municipio) DO NOTHING;

-- 3.9. Dependencias
INSERT INTO dependencias (id_dependencia, dependencia) VALUES
(1, 'Administracion'),
(2, 'Ambulancias'),
(3, 'Terapias'),
(4, 'Domiciliaria'),
(5, 'Recursos Humanos'),
(6, 'Área Médica'),
(7, 'Enfermería'),
(8, 'Odontología'),
(9, 'Psicología y Trabajo Social'),
(10, 'Rehabilitación y Terapias'),
(11, 'Nutrición'),
(12, 'Laboratorio Clínico'),
(13, 'Farmacia'),
(14, 'Admisiones y Recepción'),
(15, 'Contabilidad y Facturación'),
(16, 'Servicios Generales'),
(17, 'Calidad y Seguridad del Paciente')
ON CONFLICT (id_dependencia) DO NOTHING;

-- 3.10. Cargos (Corregido typo en cargo #1)
INSERT INTO cargos (id_cargo, cargo, id_dependencia) VALUES
(1, 'Coordinador de talento humano', 5),
(2, 'Director (a) de talento humano', 5),
(3, 'Coordinador(a) de ambulancias', 2),
(4, 'Coordinador(a) de terapias', 10),
(5, 'Director (a) administrativa', 1),
(6, 'Director (a) comercial', 1),
(7, 'Director(a) IPS', 6),
(8, 'Aprendiz sena', 1),
(9, 'Asesor comercial', 1),
(10, 'Auxiliar contable', 15),
(11, 'Auxiliar de ambulancias', 2),
(12, 'Auxiliar de enfermería', 7),
(13, 'Auxiliar de laboratorio', 12),
(14, 'Auxiliar de servicios generales', 16),
(15, 'Auxiliar domiciliario(a)', 4),
(16, 'Bacteriólogo(a)', 12),
(17, 'Call Center', 14),
(18, 'Conductor', 2),
(19, 'Contador', 15),
(20, 'Enfermero(a) jefe', 7),
(21, 'Fisioterapeuta', 10),
(22, 'Ginecólogo(a)', 6),
(23, 'Higienista', 8),
(24, 'Ingeniero de sistemas', 1),
(25, 'Ingeniero mecánico', 16),
(26, 'Médico general', 6),
(27, 'Médico ocupacional', 6),
(28, 'Nutricionista', 11),
(29, 'Odontólogo(a)', 8),
(30, 'Optómetra', 6),
(31, 'Pediatra', 6),
(32, 'Practicante universitario', 1),
(33, 'Psicólogo(a) clínico(a)', 9),
(34, 'Radioperador', 2),
(35, 'Radiólogo(a)', 6),
(36, 'Recepcionista', 14),
(37, 'Regente de farmacia', 13),
(38, 'Registrador', 14),
(39, 'Subgerente', 1),
(40, 'Terapeuta ocupacional', 10),
(41, 'Terapeuta respiratorio', 10),
(42, 'Trabajador(a) social', 9),
(43, 'Vacunador', 7)
ON CONFLICT (id_cargo) DO NOTHING;

-- 3.11. Profesiones
INSERT INTO profesion (id_profesion, nom_profesion) VALUES
(1, 'Psicologo'),
(2, 'Administrador en salud'),
(3, 'Contador'),
(4, 'Revisor fiscal'),
(5, 'Auxiliar contable'),
(6, 'Ingeniero de sistemas'),
(7, 'Ingeniero mecánico'),
(8, 'Administrador de empresas'),
(9, 'Trabajador(a) social'),
(10, 'Comunicador(a) social'),
(11, 'Técnico en recursos humanos'),
(12, 'Gestor(a) comercial y de servicios'),
(13, 'Médico general'),
(14, 'Médico ocupacional'),
(15, 'Médico especialista en ginecología'),
(16, 'Médico pediatra'),
(17, 'Fisioterapeuta'),
(18, 'Terapeuta ocupacional'),
(19, 'Terapeuta respiratorio'),
(20, 'Enfermero(a) profesional'),
(21, 'Auxiliar de enfermería'),
(22, 'Bacteriólogo(a)'),
(23, 'Regente de farmacia'),
(24, 'Químico farmacéutico'),
(25, 'Odontólogo(a)'),
(26, 'Higienista oral'),
(27, 'Optómetra'),
(28, 'Nutricionista dietista'),
(29, 'Tecnólogo en laboratorio clínico'),
(30, 'Radiólogo(a)'),
(31, 'Técnico en rayos X'),
(32, 'Conductor'),
(33, 'Técnico en atención prehospitalaria (APH)'),
(34, 'Auxiliar de servicios generales'),
(35, 'Recepcionista'),
(36, 'Asistente administrativo'),
(37, 'Aprendiz SENA'),
(38, 'Call center'),
(39, 'Administrador hospitalario'),
(40, 'Director(a) de IPS'),
(41, 'Gerente de servicios de salud'),
(42, 'Vacunador(a)'),
(43, 'Secretari(a) asistencial'),
(44, 'Abogado')
ON CONFLICT (id_profesion) DO NOTHING;

-- 3.12. EPS
INSERT INTO eps (id_eps, nom_eps) VALUES
(1, 'Nueva EPS'),
(2, 'SURA EPS'),
(3, 'Sanitas'),
(4, 'Salud Total EPS'),
(5, 'Compensar'),
(6, 'Famisanar'),
(7, 'Coosalud'),
(8, 'SOS'),
(9, 'Emssanar'),
(10, 'Aliansalud'),
(11, 'Mutual Ser'),
(12, 'Savia Salud')
ON CONFLICT (id_eps) DO NOTHING;

-- 3.13. Fondos de Pensiones
INSERT INTO pensiones (id_pension, nom_pension) VALUES
(1, 'Colpensiones'),
(2, 'Porvenir'),
(3, 'Protección'),
(4, 'Colfondos'),
(5, 'Skandia')
ON CONFLICT (id_pension) DO NOTHING;

-- 3.14. ARL
INSERT INTO arl (id_arl, nom_arl) VALUES
(1, 'ARL Sura'),
(2, 'ARL Colmena'),
(3, 'ARL Bolívar'),
(4, 'ARL Positiva'),
(5, 'ARL Seguros Alfa'),
(6, 'ARL Equidad Seguros'),
(7, 'ARL AXA Colpatria'),
(8, 'ARL Liberty Seguros'),
(9, 'ARL Mapfre'),
(10, 'ARL Aurora')
ON CONFLICT (id_arl) DO NOTHING;

-- 3.15. Cajas de Compensación
INSERT INTO caja_compensacion (id_caj_compen, nom_caj_compen) VALUES
(1, 'Comfenalco tolima'),
(2, 'Confatolima'),
(3, 'Colsubsidio'),
(4, 'Compensar'),
(5, 'Comfama'),
(6, 'Cafam'),
(7, 'Comfandi'),
(8, 'Comfenalco Antioquia'),
(9, 'Comfenalco Valle'),
(10, 'Comfamiliar Risaralda'),
(11, 'Comfamiliar Huila'),
(12, 'Confacaldas'),
(13, 'Comfenalco Cartagena'),
(14, 'Cajasan'),
(15, 'Comfamiliar Atlantico'),
(16, 'Comfamiliares Caldas'),
(17, 'Comfaboy'),
(18, 'Cofrem'),
(19, 'Comfacor'),
(20, 'Comfamiliar Nariño'),
(21, 'Combarranquilla'),
(22, 'Comfacauca'),
(23, 'Cajamag'),
(24, 'Comfacesar'),
(25, 'Comfanorte'),
(26, 'Comfaoriente'),
(27, 'Comfamiliar Cartagena'),
(28, 'Comfasucre'),
(29, 'Comfacasanare'),
(30, 'Cajacopi'),
(31, 'Comfachoco'),
(32, 'Comfiar Arauca'),
(33, 'Comfacundi'),
(34, 'Cafaba'),
(35, 'Comfaca'),
(36, 'Comfaguajira'),
(37, 'Comfamiliar Putumayo'),
(38, 'Camacol'),
(39, 'Cajasai'),
(40, 'Cafamaz'),
(41, 'Comcaja'),
(42, 'Comfenalco Santander'),
(43, 'Fenalco Quindio'),
(44, 'Cafasur')
ON CONFLICT (id_caj_compen) DO NOTHING;

-- 3.16. Bancos
INSERT INTO bancos (id_banco, nom_banco) VALUES
(1, 'Bancolombia'),
(2, 'Banco de Bogotá'),
(3, 'Davivienda'),
(4, 'Banco Popular'),
(5, 'BBVA'),
(6, 'Banco Caja Social')
ON CONFLICT (id_banco) DO NOTHING;

-- 3.17. Categoría de Licencia de Conducción
INSERT INTO categoria_licencia (id_categoria_licencia, nom_categoria) VALUES
(1, 'A1'),
(2, 'A2'),
(3, 'B1'),
(4, 'B2'),
(5, 'B3'),
(6, 'C1'),
(7, 'C2'),
(8, 'C3')
ON CONFLICT (id_categoria_licencia) DO NOTHING;

-- 3.18. Estado de Licencia de Conducción
INSERT INTO estado_licencia (id_estado_licencia, nom_estado_licencia) VALUES
(1, 'Vigente'),
(2, 'Por vencer'),
(3, 'Vencida'),
(4, 'Suspendida')
ON CONFLICT (id_estado_licencia) DO NOTHING;

-- 3.19. Tipo de Contrato
INSERT INTO tipo_contrato (id_tip_contrato, nom_contrato) VALUES
(1, 'Termino fijo'),
(2, 'Termino indefinido'),
(3, 'Obra o labor'),
(4, 'Prestacion de servicios'),
(5, 'Aprendizaje'),
(6, 'Ocasional de trabajo'),
(7, 'Periodo de prueba'),
(8, 'De confianza')
ON CONFLICT (id_tip_contrato) DO NOTHING;

-- 3.20. Tiempo de Contrato
INSERT INTO tiempo_contrato (id_tiemp_contrato, nom_tiemp_contrato) VALUES
(1, '1 mes'),
(2, '2 meses'),
(3, '3 meses'),
(4, '6 meses'),
(5, '9 meses'),
(6, '12 meses'),
(7, '24 meses'),
(8, '36 meses'),
(9, 'Indefinido'),
(10, 'Hasta finalizar obra')
ON CONFLICT (id_tiemp_contrato) DO NOTHING;

-- 3.21. Estado de Contrato
INSERT INTO estado_contrato (id_est_contrato, nom_est_contrato) VALUES
(1, 'Vigente'),
(2, 'Finalizado'),
(3, 'Suspendido'),
(4, 'Renovado'),
(5, 'Vencido'),
(6, 'Rescindido'),
(7, 'En prueba'),
(8, 'Inactivo'),
(9, 'En negociacion'),
(10, 'Cancelado'),
(11, 'Terminado por justa causa'),
(12, 'Terminado sin justa causa')
ON CONFLICT (id_est_contrato) DO NOTHING;

-- 3.22. Tipo de Documento (Formato de archivo)
INSERT INTO tipo_documento (id_tip_document, nom_tip_document) VALUES
(1, 'PDF'),
(2, 'Word'),
(3, 'Excel')
ON CONFLICT (id_tip_document) DO NOTHING;

-- 3.23. Estado de Documento
INSERT INTO estado_documento (id_estado_documento, nom_estado_documento) VALUES
(1, 'Pendiente'),
(2, 'Cargado'),
(3, 'Vigente'),
(4, 'Por vencer'),
(5, 'Vencido')
ON CONFLICT (id_estado_documento) DO NOTHING;

-- 3.24. Tipo de Permisos
INSERT INTO tipo_permisos (id_tipo_permiso, nom_permiso) VALUES
(1, 'Vacaciones'),
(2, 'Licencia de luto'),
(3, 'Cita médica'),
(4, 'Calamidad doméstica'),
(5, 'Permiso no remunerado'),
(6, 'Licencia de maternidad')
ON CONFLICT (id_tipo_permiso) DO NOTHING;

-- 3.25. Estado de Permiso
INSERT INTO estado_permiso (id_estado_permiso, nom_estado_permiso) VALUES
(1, 'Sin solicitud'),
(2, 'Pendiente'),
(3, 'Autorizado'),
(4, 'Rechazado'),
(5, 'Cancelado')
ON CONFLICT (id_estado_permiso) DO NOTHING;

-- 3.26. Estado de Certificado Laboral
INSERT INTO estado_certificado (id_estado_certificado, nom_estado_certificado) VALUES
(1, 'Sin solicitud'),
(2, 'Pendiente'),
(3, 'Aprobada'),
(4, 'Rechazada'),
(5, 'Cancelada')
ON CONFLICT (id_estado_certificado) DO NOTHING;

-- 3.27. Estado de Solicitud de Renuncia
INSERT INTO estado_renuncia (id_estado_renuncia, nom_estado_renuncia) VALUES
(1, 'Sin solicitud'),
(2, 'Pendiente'),
(3, 'Aprobada'),
(4, 'Rechazada'),
(5, 'Cancelada')
ON CONFLICT (id_estado_renuncia) DO NOTHING;


-- =============================================================================
-- 4. USUARIO SEMILLA #1 (ADMINISTRADOR PRINCIPAL)
-- =============================================================================
-- Mapeo de FKs normalizadas:
--   id_tipo_identificacion = 1 (CC)
--   id_tipo_sangre         = 7 (O+)
--   id_sexo                = 2 (Femenino)
--   id_estado_civil        = 1 (Soltero(a))
--   id_rol                 = 1 (Administrador)
--   id_departamento        = 23 (Tolima)
--   id_municipio           = 959 (Ibagué)
--   id_estado              = 1 (Activo)
--   id_cargo               = 1 (Coordinador de talento humano)
-- =============================================================================

INSERT INTO usuarios (
    id_usuario,
    doc_usuario,
    id_tipo_identificacion,
    pri_nombre,
    seg_nombre,
    pri_apellido,
    seg_apellido,
    fec_nacimiento,
    id_tipo_sangre,
    id_sexo,
    id_estado_civil,
    dir_usuario,
    cel_usuario,
    cel_emer_usuario,
    correo_usuario,
    registro_profesional,
    password,
    id_rol,
    id_departamento,
    id_municipio,
    id_estado,
    id_cargo,
    id_eps,
    id_pension,
    id_arl,
    id_caj_compen,
    id_profesion,
    img_perfil,
    ruta_firma
) VALUES (
    1,
    '123456789',
    1,
    'Sara',
    'Sofía',
    'Rodríguez',
    'Hernández',
    '2000-09-19',
    7,
    2,
    1,
    'Cr 47sur N 119-49',
    '3143191393',
    '3206634567',
    'sarisofia011@gmail.com',
    'RP-00123',
    '$2y$12$aGL4JljDthI/GRuhoJtO5OdVuReieAubrSNM1zBf4dMc5yk1HC2fq',
    1,
    23,
    959,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    'imgs/default.jpg',
    NULL
) ON CONFLICT (id_usuario) DO NOTHING;


-- =============================================================================
-- 5. SINCRONIZACIÓN AUTOMÁTICA DE SECUENCIAS (SERIAL) EN POSTGRESQL
-- =============================================================================

SELECT setval(pg_get_serial_sequence('roles', 'id_rol'), COALESCE((SELECT MAX(id_rol) FROM roles), 1), true);
SELECT setval(pg_get_serial_sequence('tipo_identificacion', 'id_tipo_identificacion'), COALESCE((SELECT MAX(id_tipo_identificacion) FROM tipo_identificacion), 1), true);
SELECT setval(pg_get_serial_sequence('tipo_sangre', 'id_tipo_sangre'), COALESCE((SELECT MAX(id_tipo_sangre) FROM tipo_sangre), 1), true);
SELECT setval(pg_get_serial_sequence('sexo', 'id_sexo'), COALESCE((SELECT MAX(id_sexo) FROM sexo), 1), true);
SELECT setval(pg_get_serial_sequence('estado_civil', 'id_estado_civil'), COALESCE((SELECT MAX(id_estado_civil) FROM estado_civil), 1), true);
SELECT setval(pg_get_serial_sequence('estado_usuario', 'id_estado'), COALESCE((SELECT MAX(id_estado) FROM estado_usuario), 1), true);
SELECT setval(pg_get_serial_sequence('departamentos', 'id_departamento'), COALESCE((SELECT MAX(id_departamento) FROM departamentos), 1), true);
SELECT setval(pg_get_serial_sequence('municipio', 'id_municipio'), COALESCE((SELECT MAX(id_municipio) FROM municipio), 1), true);
SELECT setval(pg_get_serial_sequence('dependencias', 'id_dependencia'), COALESCE((SELECT MAX(id_dependencia) FROM dependencias), 1), true);
SELECT setval(pg_get_serial_sequence('cargos', 'id_cargo'), COALESCE((SELECT MAX(id_cargo) FROM cargos), 1), true);
SELECT setval(pg_get_serial_sequence('profesion', 'id_profesion'), COALESCE((SELECT MAX(id_profesion) FROM profesion), 1), true);
SELECT setval(pg_get_serial_sequence('eps', 'id_eps'), COALESCE((SELECT MAX(id_eps) FROM eps), 1), true);
SELECT setval(pg_get_serial_sequence('pensiones', 'id_pension'), COALESCE((SELECT MAX(id_pension) FROM pensiones), 1), true);
SELECT setval(pg_get_serial_sequence('arl', 'id_arl'), COALESCE((SELECT MAX(id_arl) FROM arl), 1), true);
SELECT setval(pg_get_serial_sequence('caja_compensacion', 'id_caj_compen'), COALESCE((SELECT MAX(id_caj_compen) FROM caja_compensacion), 1), true);
SELECT setval(pg_get_serial_sequence('bancos', 'id_banco'), COALESCE((SELECT MAX(id_banco) FROM bancos), 1), true);
SELECT setval(pg_get_serial_sequence('categoria_licencia', 'id_categoria_licencia'), COALESCE((SELECT MAX(id_categoria_licencia) FROM categoria_licencia), 1), true);
SELECT setval(pg_get_serial_sequence('estado_licencia', 'id_estado_licencia'), COALESCE((SELECT MAX(id_estado_licencia) FROM estado_licencia), 1), true);
SELECT setval(pg_get_serial_sequence('tipo_contrato', 'id_tip_contrato'), COALESCE((SELECT MAX(id_tip_contrato) FROM tipo_contrato), 1), true);
SELECT setval(pg_get_serial_sequence('tiempo_contrato', 'id_tiemp_contrato'), COALESCE((SELECT MAX(id_tiemp_contrato) FROM tiempo_contrato), 1), true);
SELECT setval(pg_get_serial_sequence('estado_contrato', 'id_est_contrato'), COALESCE((SELECT MAX(id_est_contrato) FROM estado_contrato), 1), true);
SELECT setval(pg_get_serial_sequence('tipo_documento', 'id_tip_document'), COALESCE((SELECT MAX(id_tip_document) FROM tipo_documento), 1), true);
SELECT setval(pg_get_serial_sequence('estado_documento', 'id_estado_documento'), COALESCE((SELECT MAX(id_estado_documento) FROM estado_documento), 1), true);
SELECT setval(pg_get_serial_sequence('tipo_permisos', 'id_tipo_permiso'), COALESCE((SELECT MAX(id_tipo_permiso) FROM tipo_permisos), 1), true);
SELECT setval(pg_get_serial_sequence('estado_permiso', 'id_estado_permiso'), COALESCE((SELECT MAX(id_estado_permiso) FROM estado_permiso), 1), true);
SELECT setval(pg_get_serial_sequence('estado_certificado', 'id_estado_certificado'), COALESCE((SELECT MAX(id_estado_certificado) FROM estado_certificado), 1), true);
SELECT setval(pg_get_serial_sequence('estado_renuncia', 'id_estado_renuncia'), COALESCE((SELECT MAX(id_estado_renuncia) FROM estado_renuncia), 1), true);
SELECT setval(pg_get_serial_sequence('usuarios', 'id_usuario'), COALESCE((SELECT MAX(id_usuario) FROM usuarios), 1), true);

COMMIT;
