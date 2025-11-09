

<div align="center">

# 🧠 GPT-OSS Neural Shell  
**Sistema de Automatización IA + Xcode + DevOps — v9.9**

Una capa neural modular desarrollada por **MoLinesGitHub** para integrar agentes inteligentes, compilación automática, control de seguridad y flujo CI local en macOS + NAS Synology + Tailscale + Ollama.

![Version](https://img.shields.io/badge/version-9.9-blue?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)
![Build](https://img.shields.io/badge/status-stable-success?style=flat-square)

```

</div>

---

## 🚀 Descripción General

GPT-OSS es un **entorno de orquestación IA local** con integración total en macOS.  
Su arquitectura modular permite ejecutar agentes especializados, auditar el sistema, compilar proyectos Xcode y mantener sincronización entre dispositivos (Mac, NAS, Raspberry Pi, Tailscale).

Incluye:
- Controlador principal `oss`
- Configuración modular (`gptoss.conf`)
- Mapa de seguridad jerárquico (`security.map`)
- Scripts inteligentes (`oss-doctor`, hooks automáticos, backups, auditoría, firewall)
- UI visual (modo Terminal o ventana interactiva)

---

## ⚙️ Estructura del Proyecto

```
gptoss/
├── core/                # Scripts principales (oss, oss-doctor, daemon, etc.)
├── config/              # Configuración base (gptoss.conf, security.map)
├── hooks/               # Scripts automáticos post-build, recovery, firewall
├── scheduler/           # Tareas programadas y agentes
├── security/            # Blocklist, whitelist, claves y auditorías
├── logs/                # Archivos de registro (excluidos del repo)
└── backups/             # Copias automáticas (excluidas del repo)
```

---

## 🧩 Componentes Clave

### `core/oss`
> Comando principal.  
> Gestiona configuración, compila proyectos Xcode, ejecuta agentes IA y verifica seguridad.

Ejemplo:
```bash
oss build
oss audit
oss run agent SwiftExpert
```

### `core/oss-doctor`
> Auditoría completa del sistema.  
> Verifica rutas, configuración, estado de Xcode, NAS, Ollama y calcula hash SHA256 de `security.map`.

```bash
oss-doctor
```

---

## 🧱 Configuración

Archivo: `config/gptoss.conf`

Incluye:
- Xcode Integration  
- Seguridad avanzada (checksum, firmas, rotación de claves)
- Visual UI (`VISUAL_MODE=on`)
- Agentes IA locales y remotos (Ollama + API)
- Backups, logs y sincronización con NAS / Raspberry Pi
- Domótica experimental (Home Assistant)

---

## 🔒 Seguridad

Archivo: `config/security.map`

Matriz jerárquica de permisos:
```
SwiftExpert    code_write    sandbox
BuilderAgent   build         yes
SecurityAgent  audit         yes
DeployAgent    rollback      yes
SchedulerAgent self_repair   smart
```

El sistema valida los permisos antes de ejecutar acciones sensibles.
La integridad del archivo se comprueba mediante SHA256 en cada auditoría.

---

## 🧰 Hooks Incluidos

| Hook | Propósito |
|------|------------|
| `post-build.sh` | Ejecuta tareas tras compilar (deploy, tests, notificaciones) |
| `firewall.sh` | Aplica reglas de red dinámicas y bloquea agentes no firmados |
| `audit.sh` | Genera reportes de seguridad periódicos |
| `recovery.sh` | Restaura configuración y snapshots en caso de fallo |

Todos los hooks registran su actividad en `logs/`.

---

## 🧠 Modo Visual

Si `VISUAL_MODE=on`, el sistema lanza una **ventana UI dedicada de Terminal**  
al ejecutar `oss`, mostrando el shell interactivo GPT-OSS:

```
🧠 GPT-OSS Neural Shell — v9 interactivo
────────────────────────────────────────────
Escribe 'help' para ver comandos disponibles.
oss>
```

---

## 🧩 Diagnóstico

El módulo `oss-doctor` realiza una verificación completa:
- Xcode / Build System  
- Ollama / Modelos locales  
- NAS Synology vía Tailscale  
- Backups / Logs  
- Integridad de `security.map`  
- Estado de Home Assistant  

Ejemplo:
```
✓ Ruta del proyecto Xcode OK
✓ SAFE_MODE activo
✓ Integridad del security.map verificada (SHA256 coincide)
⚠️  Modelos Ollama no encontrados
```

---

## 🔧 Instalación Rápida

```bash
cd ~/Documents/Scripts/gptoss
sudo ln -sf ~/Documents/Scripts/gptoss/core/oss /usr/local/bin/oss
sudo ln -sf ~/Documents/Scripts/gptoss/core/oss-doctor /usr/local/bin/oss-doctor
chmod +x core/*
```

Verificar:
```bash
oss status
oss-doctor
```

---

## 🧩 Próximas Extensiones
- Agente `DeployAgent` con control remoto de simuladores
- UI web basada en Electron
- Integración nativa con n8n y MCP Server
- Gestión de snapshots NAS + iCloud combinada

---

## 📜 Autor
**MoLinesGitHub**  
Diseño, desarrollo y arquitectura de sistema GPT-OSS Neural Shell.  
> “El código limpio es poesía que funciona.”

---

## 🪪 Licencia
MIT © 2025 — MoLinesGitHub  
Puedes modificar, redistribuir o extender el sistema siempre que se mantenga la atribución.
