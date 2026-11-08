# Guía de Instalación y Configuración de Python 3.12 desde Consola (Windows / PowerShell)

Esta guía documenta cómo instalar **Python 3.12 (64-bit)** y **`uv`** 100% desde PowerShell (sin abrir instaladores gráficos), reemplazar versiones antiguas en las variables de entorno (como el Python de Laragon) y verificar que todo quede apuntando a la ruta correcta.

> [!TIP]
> **Para ejecutar con un Agente de IA (Antigravity / Cursor / Claude Code):**
> Solo dile a tu asistente: *"Lee `guia_instalacion_python.md` y ejecuta los pasos del 1 al 4 en mi máquina para dejar instalado Python 3.12, `uv` y actualizado mi PATH de usuario"*.
> Como utiliza variables dinámicas de Windows (`$env:LOCALAPPDATA`, `$env:USERPROFILE`, `$env:TEMP`), funciona en cualquier PC con Windows sin importar cómo se llame el usuario.

---

## 1. Descargar e instalar Python 3.12 silenciosamente desde PowerShell

El instalador oficial de Python soporta banderas de instalación desatendida (`/quiet`). Ejecuta este bloque en **PowerShell**:

```powershell
# 1. Definir versión y ruta temporal del instalador
$PythonVersion = "3.12.9"
$InstallerUrl  = "https://www.python.org/ftp/python/$PythonVersion/python-$PythonVersion-amd64.exe"
$InstallerPath = "$env:TEMP\python-$PythonVersion-amd64.exe"
$TargetDir     = "$env:LOCALAPPDATA\Programs\Python\Python312"

# 2. Descargar el instalador oficial desde python.org
Invoke-WebRequest -Uri $InstallerUrl -OutFile $InstallerPath

# 3. Ejecutar instalación silenciosa en el perfil del usuario actual
Start-Process -FilePath $InstallerPath -ArgumentList "/quiet InstallAllUsers=0 TargetDir=`"$TargetDir`" Include_pip=1 Include_Launcher=1 Include_test=0" -Wait

# 4. Limpiar el instalador temporal
Remove-Item -Path $InstallerPath -Force
```

### ¿Qué hacen los parámetros del instalador?
- `/quiet`: Instala sin abrir ventanas ni pedir clics.
- `InstallAllUsers=0`: Instala en tu carpeta de usuario (`C:\Users\<TU_USUARIO>\AppData\Local\Programs\Python\Python312`), evitando problemas de permisos de Administrador al instalar paquetes globales.
- `Include_pip=1` y `Include_Launcher=1`: Instala `pip` y el comando `py`.
- `Include_test=0`: No instala la suite de pruebas internas de Python (ahorra espacio y miles de archivos innecesarios).

---

## 2. Instalar `uv` (Gestor ultrarrápido de entornos y paquetes Python)

`uv` es el estándar moderno para manejar `.venv` y dependencias en proyectos con Django + Pandas en milisegundos:

```powershell
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

*(Por defecto se instala en `$env:USERPROFILE\.local\bin`).*

---

## 3. Limpiar el `PATH` antiguo (Laragon) y apuntar a Python 3.12 + `uv`

Si tenías Laragon con `python-3.10` (u otra versión previa), este script en PowerShell lee tu variable de entorno `Path` de usuario, elimina las rutas de Python de Laragon y coloca **Python 3.12** y **`uv`** al inicio para que tengan prioridad absoluta:

```powershell
$PythonDir    = "$env:LOCALAPPDATA\Programs\Python\Python312"
$PythonScript = "$env:LOCALAPPDATA\Programs\Python\Python312\Scripts"
$UvDir        = "$env:USERPROFILE\.local\bin"

# 1. Obtener el PATH actual del Usuario
$CurrentUserPath = [Environment]::GetEnvironmentVariable("Path", "User")

# 2. Filtrar rutas viejas de Python en Laragon y evitar duplicados
$CleanPaths = $CurrentUserPath -split ';' | Where-Object {
    $_ -ne "" -and
    $_ -notmatch "laragon\\bin\\python" -and
    $_ -ne $PythonDir -and
    $_ -ne $PythonScript -and
    $_ -ne $UvDir
}

# 3. Poner Python 3.12, Scripts y uv al principio del PATH de Usuario
$NewUserPath = (@($PythonDir, $PythonScript, $UvDir) + $CleanPaths) -join ';'

# 4. Guardar permanentemente en las variables de entorno del Usuario
[Environment]::SetEnvironmentVariable("Path", $NewUserPath, "User")

# 5. Actualizar también la sesión actual de PowerShell sin tener que reiniciar la consola
$env:Path = "$PythonDir;$PythonScript;$UvDir;$env:Path"
```

---

## 4. Comandos de verificación

Una vez ejecutados los pasos anteriores, abre una nueva terminal y comprueba que Windows esté tomando los binarios correctos:

```powershell
# Ver versión activa de Python y pip
python --version
pip --version
uv --version

# Confirmar la ruta exacta desde donde se está ejecutando Python
where.exe python
```

La salida de `where.exe python` debe mostrar en primer lugar:
`C:\Users\<TU_USUARIO>\AppData\Local\Programs\Python\Python312\python.exe`

---

## 5. Cómo crear y activar el entorno virtual del proyecto

Cuando estemos dentro de la carpeta del backend (`C:\Project\rh_solutionsv2\backend`):

```powershell
# Con uv (recomendado, tarda ~1 segundo)
uv venv --python 3.12
.venv\Scripts\activate

# O con el módulo venv nativo de Python
python -m venv .venv
.venv\Scripts\activate
```
