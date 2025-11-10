# Plan de Integración: Session Management en ./cc Plugin

**Fecha**: 2025-11-10
**Objetivo**: Integrar el sistema de manejo de sesiones v2 de `./session` en `./cc` manteniendo los comandos existentes sin cambios funcionales.

---

## Resumen Ejecutivo

### Qué se integra
- ✅ Sistema de generación de IDs v2 (sin OpenSSL)
- ✅ Sistema de resolución de referencias (@latest, short IDs, slug search)
- ✅ Índice JSON de sesiones (.claude/sessions/index.json)
- ✅ Comandos de gestión de sesiones (/session-list, /session-migrate, /session-rebuild-index)
- ✅ Hooks de ciclo de vida (SessionStart, PreToolUse, Stop, SessionEnd)
- ✅ Skill de búsqueda inteligente (session-finder)

### Qué NO se cambia
- ❌ Funcionalidad de /cc:explore (solo actualiza la parte de session ID)
- ❌ Funcionalidad de /cc:plan (se mantiene igual)
- ❌ Funcionalidad de /cc:code (se mantiene igual)
- ❌ Funcionalidad de /cc:commit (se mantiene igual)
- ❌ Agentes existentes (code-search, web-research, context-synthesis)

---

## Análisis de Componentes

### Componentes a copiar de ./session

| Componente | Origen | Destino | Modificaciones |
|------------|--------|---------|----------------|
| **Scripts** |
| generate-session-id.sh | session/scripts/ | cc/scripts/ | Ninguna |
| resolve-session-id.sh | session/scripts/ | cc/scripts/ | Ninguna |
| session-index.sh | session/scripts/ | cc/scripts/ | Ninguna |
| test-scripts.sh | session/scripts/ | cc/scripts/ | Ninguna |
| **Comandos** |
| session-list.md | session/commands/ | cc/commands/ | Cambiar CLAUDE_PLUGIN_ROOT → CLAUDE_PLUGIN_DIR |
| session-migrate.md | session/commands/ | cc/commands/ | Cambiar CLAUDE_PLUGIN_ROOT → CLAUDE_PLUGIN_DIR |
| session-rebuild-index.md | session/commands/ | cc/commands/ | Cambiar CLAUDE_PLUGIN_ROOT → CLAUDE_PLUGIN_DIR |
| **Hooks** |
| hooks.json | session/hooks/ | cc/hooks/ | Nueva creación |
| session-start/ | session/hooks/ | cc/hooks/ | Cambiar CLAUDE_PLUGIN_ROOT → CLAUDE_PLUGIN_DIR |
| session-end/ | session/hooks/ | cc/hooks/ | Cambiar CLAUDE_PLUGIN_ROOT → CLAUDE_PLUGIN_DIR |
| pre-tool-use/ | session/hooks/ | cc/hooks/ | Actualizar para cc:* commands |
| stop/ | session/hooks/ | cc/hooks/ | Cambiar CLAUDE_PLUGIN_ROOT → CLAUDE_PLUGIN_DIR |
| user-prompt-submit/ | session/hooks/ | cc/hooks/ | Cambiar CLAUDE_PLUGIN_ROOT → CLAUDE_PLUGIN_DIR |
| **Skills** |
| session-finder/ | session/skills/ | cc/skills/ | Crear estructura nueva |

### Componentes a modificar en ./cc

| Archivo | Tipo | Modificación |
|---------|------|--------------|
| explore.md | Comando | Actualizar sección "Session Setup" (líneas 11-109) |
| plan.md | Comando | Agregar resolución de referencias al inicio |
| code.md | Comando | Agregar resolución de referencias al inicio |
| plugin.json | Config | Agregar hooks: "./hooks/hooks.json" |

---

## Plan de Implementación

### FASE 1: Preparación del Entorno (30 min)

#### 1.1 Crear estructura de directorios
```bash
# Crear directorios necesarios en ./cc
mkdir -p cc/scripts
mkdir -p cc/hooks/session-start
mkdir -p cc/hooks/session-end
mkdir -p cc/hooks/pre-tool-use
mkdir -p cc/hooks/stop
mkdir -p cc/hooks/user-prompt-submit
mkdir -p cc/skills/session-finder/resources
```

**Validación**: Verificar que todos los directorios existen
```bash
ls -la cc/scripts cc/hooks cc/skills
```

#### 1.2 Backup de archivos existentes
```bash
# Crear backup de comandos que se modificarán
cp cc/commands/explore.md cc/commands/explore.md.backup
cp cc/.claude-plugin/plugin.json cc/.claude-plugin/plugin.json.backup
```

**Validación**: Verificar backups creados
```bash
ls -la cc/commands/*.backup cc/.claude-plugin/*.backup
```

---

### FASE 2: Copiar Scripts Core (20 min)

#### 2.1 Copiar scripts de generación y resolución
```bash
cp session/scripts/generate-session-id.sh cc/scripts/
cp session/scripts/resolve-session-id.sh cc/scripts/
cp session/scripts/session-index.sh cc/scripts/
cp session/scripts/test-scripts.sh cc/scripts/
```

**Modificaciones**: NINGUNA (los scripts son independientes)

**Validación**:
```bash
# Verificar que los scripts son ejecutables
chmod +x cc/scripts/*.sh
ls -la cc/scripts/

# Probar generación de ID
bash cc/scripts/generate-session-id.sh "test session"

# Resultado esperado: v2-20251110TXXXXXX-xxxxxxxx-test-session
```

#### 2.2 Copiar README de scripts
```bash
cp session/scripts/README.md cc/scripts/
```

---

### FASE 3: Crear Comandos de Gestión de Sesiones (30 min)

#### 3.1 Copiar comando /session-list
```bash
cp session/commands/session-list.md cc/commands/
```

**Modificaciones necesarias**:
- Línea 21: Cambiar `CLAUDE_PLUGIN_ROOT` → `CLAUDE_PLUGIN_DIR`

**Archivo**: `cc/commands/session-list.md`
```bash
# ANTES (línea 21):
PLUGIN_DIR="${CLAUDE_PLUGIN_ROOT}"

# DESPUÉS:
PLUGIN_DIR="${CLAUDE_PLUGIN_DIR}"
```

**Validación**:
```bash
grep -n "CLAUDE_PLUGIN" cc/commands/session-list.md
# Debe mostrar solo CLAUDE_PLUGIN_DIR
```

#### 3.2 Copiar comando /session-migrate
```bash
cp session/commands/session-migrate.md cc/commands/
```

**Modificaciones necesarias**:
- Línea 25: Cambiar `CLAUDE_PLUGIN_ROOT` → `CLAUDE_PLUGIN_DIR`

**Archivo**: `cc/commands/session-migrate.md`
```bash
# ANTES (línea 25):
PLUGIN_DIR="${CLAUDE_PLUGIN_ROOT}"

# DESPUÉS:
PLUGIN_DIR="${CLAUDE_PLUGIN_DIR}"
```

**Validación**:
```bash
grep -n "CLAUDE_PLUGIN" cc/commands/session-migrate.md
# Debe mostrar solo CLAUDE_PLUGIN_DIR
```

#### 3.3 Copiar comando /session-rebuild-index
```bash
cp session/commands/session-rebuild-index.md cc/commands/
```

**Modificaciones necesarias**:
- Línea 29: Cambiar `CLAUDE_PLUGIN_ROOT` → `CLAUDE_PLUGIN_DIR`

**Archivo**: `cc/commands/session-rebuild-index.md`
```bash
# ANTES (línea 29):
PLUGIN_DIR="${CLAUDE_PLUGIN_ROOT}"

# DESPUÉS:
PLUGIN_DIR="${CLAUDE_PLUGIN_DIR}"
```

**Validación**:
```bash
grep -n "CLAUDE_PLUGIN" cc/commands/session-rebuild-index.md
# Debe mostrar solo CLAUDE_PLUGIN_DIR
```

---

### FASE 4: Implementar Hooks del Ciclo de Vida (45 min)

#### 4.1 Crear configuración de hooks

**Archivo**: `cc/hooks/hooks.json`
```json
{
  "SessionStart": [
    {
      "matcher": "*",
      "hooks": [
        {
          "type": "command",
          "command": "bash \"$CLAUDE_PLUGIN_DIR\"/hooks/session-start/load-active-session.sh"
        }
      ]
    }
  ],
  "SessionEnd": [
    {
      "matcher": "*",
      "hooks": [
        {
          "type": "command",
          "command": "bash \"$CLAUDE_PLUGIN_DIR\"/hooks/session-end/save-session-state.sh"
        }
      ]
    }
  ],
  "PreToolUse": [
    {
      "matcher": "SlashCommand",
      "hooks": [
        {
          "type": "command",
          "command": "bash \"$CLAUDE_PLUGIN_DIR\"/hooks/pre-tool-use/validate-session.sh"
        }
      ]
    }
  ],
  "Stop": [
    {
      "matcher": "*",
      "hooks": [
        {
          "type": "command",
          "command": "bash \"$CLAUDE_PLUGIN_DIR\"/hooks/stop/auto-save-session.sh"
        }
      ]
    }
  ],
  "UserPromptSubmit": [
    {
      "matcher": "",
      "hooks": [
        {
          "type": "command",
          "command": "bash \"$CLAUDE_PLUGIN_DIR\"/hooks/user-prompt-submit/load-context.sh"
        }
      ]
    }
  ]
}
```

**Validación**:
```bash
jq empty cc/hooks/hooks.json
# Sin errores = JSON válido
```

#### 4.2 Copiar hook SessionStart
```bash
cp session/hooks/session-start/load-active-session.sh cc/hooks/session-start/
chmod +x cc/hooks/session-start/load-active-session.sh
```

**Modificaciones necesarias**:
- Línea 9: Cambiar `CLAUDE_PLUGIN_ROOT` → `CLAUDE_PLUGIN_DIR`

**Archivo**: `cc/hooks/session-start/load-active-session.sh`
```bash
# ANTES (línea 9):
PLUGIN_DIR="${CLAUDE_PLUGIN_ROOT}"

# DESPUÉS:
PLUGIN_DIR="${CLAUDE_PLUGIN_DIR}"
```

**Validación**:
```bash
bash cc/hooks/session-start/load-active-session.sh
# Debe ejecutar sin errores
```

#### 4.3 Copiar hook SessionEnd
```bash
cp session/hooks/session-end/save-session-state.sh cc/hooks/session-end/
chmod +x cc/hooks/session-end/save-session-state.sh
```

**Modificaciones necesarias**:
- Verificar y cambiar cualquier `CLAUDE_PLUGIN_ROOT` → `CLAUDE_PLUGIN_DIR`

**Validación**:
```bash
grep -n "CLAUDE_PLUGIN" cc/hooks/session-end/save-session-state.sh
bash cc/hooks/session-end/save-session-state.sh
```

#### 4.4 Copiar hook PreToolUse
```bash
cp session/hooks/pre-tool-use/validate-session.sh cc/hooks/pre-tool-use/
chmod +x cc/hooks/pre-tool-use/validate-session.sh
```

**Modificaciones necesarias**:
- Línea 17: Cambiar `CLAUDE_PLUGIN_DIR` (ya está correcto en session)
- Línea 26: Actualizar regex para comandos cc
  ```bash
  # ANTES:
  if ! echo "$COMMAND" | grep -qE '/cc:(plan|code)'; then

  # DESPUÉS (mantener igual, ya valida cc:plan y cc:code)
  if ! echo "$COMMAND" | grep -qE '/cc:(plan|code)'; then
  ```

**Validación**:
```bash
# Test con JSON mock
echo '{"tool_name":"SlashCommand","tool_input":{"command":"/cc:plan @latest"}}' | bash cc/hooks/pre-tool-use/validate-session.sh
```

#### 4.5 Copiar hook Stop
```bash
cp session/hooks/stop/auto-save-session.sh cc/hooks/stop/
chmod +x cc/hooks/stop/auto-save-session.sh
```

**Modificaciones necesarias**:
- Cambiar `CLAUDE_PLUGIN_ROOT` → `CLAUDE_PLUGIN_DIR` si existe

**Validación**:
```bash
grep -n "CLAUDE_PLUGIN" cc/hooks/stop/auto-save-session.sh
bash cc/hooks/stop/auto-save-session.sh
```

#### 4.6 Copiar hook UserPromptSubmit
```bash
cp session/hooks/user-prompt-submit/load-context.sh cc/hooks/user-prompt-submit/
chmod +x cc/hooks/user-prompt-submit/load-context.sh
```

**Modificaciones necesarias**:
- Cambiar `CLAUDE_PLUGIN_ROOT` → `CLAUDE_PLUGIN_DIR` si existe

**Validación**:
```bash
grep -n "CLAUDE_PLUGIN" cc/hooks/user-prompt-submit/load-context.sh
bash cc/hooks/user-prompt-submit/load-context.sh
```

#### 4.7 Copiar documentación y tests de hooks
```bash
cp session/hooks/README.md cc/hooks/
cp session/hooks/test-hooks.sh cc/hooks/
chmod +x cc/hooks/test-hooks.sh
```

---

### FASE 5: Integrar Skill de Búsqueda de Sesiones (20 min)

#### 5.1 Copiar skill session-finder
```bash
cp -r session/skills/session-finder cc/skills/
```

**Modificaciones necesarias**:
- NINGUNA (el skill es independiente y usa paths relativos)

**Validación**:
```bash
ls -la cc/skills/session-finder/
cat cc/skills/session-finder/SKILL.md | head -20
```

---

### FASE 6: Actualizar Comandos Existentes (60 min)

#### 6.1 Actualizar /cc:explore

**Archivo**: `cc/commands/explore.md`

**Modificación**: Reemplazar sección "Session Setup" (líneas 11-42 aproximadamente)

**ANTES** (líneas 11-42):
```bash
SESSION_ID=$(date +%Y%m%d_%H%M%S)_$(openssl rand -hex 4)
SESSION_DESC=$(echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | head -c 20)
SESSION_DIR=".claude/sessions/${SESSION_ID}_${SESSION_DESC}"
mkdir -p "$SESSION_DIR"

cat > "$SESSION_DIR/CLAUDE.md" << EOF
# Session: $1

## Status
Phase: explore | Started: $(date '+%Y-%m-%d %H:%M') | ID: ${SESSION_ID}

## Objective
$1

## Context
$2

## Key Findings
[Populated after synthesis]

## Next Steps
Run \`/plan ${SESSION_ID}\`
EOF

echo "✅ Session: ${SESSION_ID}"
echo "📁 $SESSION_DIR"
```

**DESPUÉS** (reemplazar con):
```bash
# Generate v2 session ID (zero dependencies)
echo "🔨 Generating session ID..."
SESSION_ID=$(bash "$CLAUDE_PLUGIN_DIR/scripts/generate-session-id.sh" "$1")

if [ $? -ne 0 ] || [ -z "$SESSION_ID" ]; then
  echo "❌ Failed to generate session ID"
  exit 1
fi

echo "✅ Generated: $SESSION_ID"
echo ""

# Extract slug from v2 ID (format: v2-YYYYMMDDTHHmmss-base32-slug)
SLUG=$(echo "$SESSION_ID" | cut -d'-' -f4-)

# Get current git branch
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")

# Create session directory
SESSION_DIR=".claude/sessions/${SESSION_ID}"
mkdir -p "$SESSION_DIR"

# Initialize session CLAUDE.md
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")

cat > "$SESSION_DIR/CLAUDE.md" << EOF
# Session: $1

## Status
Phase: explore
Started: $(date '+%Y-%m-%d %H:%M')
Last Updated: $(date '+%Y-%m-%d %H:%M')
Session ID: ${SESSION_ID}

## Technical Details
- Session Format: v2
- Branch: $BRANCH
- Short ID: $(echo "$SESSION_ID" | cut -d'-' -f3)
- Slug: $SLUG

## Objective
$1

## Context
$2

## Key Findings
[To be populated during exploration]

## Next Steps
Run \`/cc:plan @latest\` to create implementation plan

## References
@.claude/sessions/${SESSION_ID}/explore.md
EOF

# Initialize activity log
cat > "$SESSION_DIR/activity.log" << EOF
[$TIMESTAMP] Session created
[$TIMESTAMP] Description: $1
[$TIMESTAMP] Branch: $BRANCH
EOF

# Add session to index
echo "📇 Adding to session index..."
if [ -x "$CLAUDE_PLUGIN_DIR/scripts/session-index.sh" ]; then
  bash "$CLAUDE_PLUGIN_DIR/scripts/session-index.sh" add \
    "$SESSION_ID" \
    "$SLUG" \
    "exploration" \
    "in_progress" \
    "$BRANCH" || echo "⚠️  Warning: Failed to add to index"

  # Set as @latest
  bash "$CLAUDE_PLUGIN_DIR/scripts/session-index.sh" set-ref "@latest" "$SESSION_ID" || true
fi

echo ""
echo "✅ Session created successfully!"
echo ""
echo "📋 Session Details:"
echo "  ID: $SESSION_ID"
echo "  Name: $SLUG"
echo "  Phase: Exploration"
echo "  Branch: $BRANCH"
echo ""
echo "💡 Quick references:"
echo "  @latest              - Always refers to this session (until next session)"
echo "  @                    - Shorthand for @latest"
echo "  $(echo "$SESSION_ID" | cut -d'-' -f3)             - Short ID (8 chars)"
echo "  @/$SLUG - Slug search"
echo ""
echo "📁 Directory: $SESSION_DIR"
```

**Validación**:
```bash
# Verificar que el comando no tiene errores de sintaxis
bash -n cc/commands/explore.md
grep -n "CLAUDE_PLUGIN_DIR" cc/commands/explore.md
```

#### 6.2 Actualizar /cc:plan

**Archivo**: `cc/commands/plan.md`

**Modificación**: Agregar resolución de referencias al inicio (después de línea 15 aprox)

**Ubicación**: Después de `# Plan: Strategic Planning`

**Agregar**:
```markdown

## Session Reference Resolution

Resolve session reference to full session ID:

```bash
#!/bin/bash
set -euo pipefail

# Get session reference (default to @latest)
SESSION_REF="${1:-@latest}"

# Resolve reference to full session ID
if [ -x "$CLAUDE_PLUGIN_DIR/scripts/resolve-session-id.sh" ]; then
  SESSION_ID=$(bash "$CLAUDE_PLUGIN_DIR/scripts/resolve-session-id.sh" "$SESSION_REF" 2>&1)
  EXIT_CODE=$?

  if [ $EXIT_CODE -ne 0 ]; then
    echo "❌ Failed to resolve session reference: $SESSION_REF"
    echo ""
    echo "$SESSION_ID"
    echo ""
    echo "💡 Available commands:"
    echo "   /session-list              - View all sessions"
    echo "   /cc:explore <description>  - Create new session"
    exit 1
  fi

  echo "✅ Resolved: $SESSION_REF → $SESSION_ID"
  echo ""
else
  # Fallback: assume SESSION_REF is full ID
  SESSION_ID="$SESSION_REF"
  echo "⚠️  Session resolver not available, using: $SESSION_ID"
  echo ""
fi

# Set SESSION_DIR for rest of command
SESSION_DIR=".claude/sessions/${SESSION_ID}"

# Verify session exists
if [ ! -d "$SESSION_DIR" ]; then
  echo "❌ Session not found: $SESSION_ID"
  echo ""
  echo "💡 Try:"
  echo "   /session-list              - View all sessions"
  echo "   /cc:explore <description>  - Create new session"
  exit 1
fi

echo "📁 Using session: $SESSION_DIR"
echo ""
```
```

**Luego actualizar todas las referencias de `$1` a `$SESSION_ID` y referencias a session dir**

**Validación**:
```bash
grep -n "SESSION_ID" cc/commands/plan.md
grep -n "SESSION_DIR" cc/commands/plan.md
```

#### 6.3 Actualizar /cc:code

**Archivo**: `cc/commands/code.md`

**Modificación**: Idéntica a /cc:plan - agregar resolución de referencias al inicio

**Copiar el mismo bloque de resolución agregado en plan.md**

**Validación**:
```bash
grep -n "SESSION_ID" cc/commands/code.md
grep -n "SESSION_DIR" cc/commands/code.md
```

---

### FASE 7: Actualizar Configuración del Plugin (10 min)

#### 7.1 Actualizar plugin.json

**Archivo**: `cc/.claude-plugin/plugin.json`

**ANTES**:
```json
{
  "name": "cc",
  "version": "2.0.0",
  "description": "Senior engineer workflow system with multi-phase development (explore → plan → code → commit), parallel subagent exploration, CLAUDE.md hierarchical memory, and automated lifecycle hooks. 4x faster exploration, 8x better context efficiency.",
  "author": {
    "name": "Yerson",
    "email": "yersonargotev@gmail.com"
  },
  "homepage": "https://github.com/yersonargotev/cc-mkp",
  "repository": "https://github.com/yersonargotev/cc-mkp",
  "license": "MIT",
  "mcpServers": "./.mcp.json"
}
```

**DESPUÉS**:
```json
{
  "name": "cc",
  "version": "3.0.0",
  "description": "Senior engineer workflow system with multi-phase development (explore → plan → code → commit), parallel subagent exploration, CLAUDE.md hierarchical memory, Session Manager v2 (Git-like references), and automated lifecycle hooks. 4x faster exploration, 8x better context efficiency.",
  "author": {
    "name": "Yerson",
    "email": "yersonargotev@gmail.com"
  },
  "homepage": "https://github.com/yersonargotev/cc-mkp",
  "repository": "https://github.com/yersonargotev/cc-mkp",
  "license": "MIT",
  "mcpServers": "./.mcp.json",
  "hooks": "./hooks/hooks.json"
}
```

**Cambios**:
- Version: `2.0.0` → `3.0.0`
- Description: Agregar "Session Manager v2 (Git-like references)"
- **Agregar**: `"hooks": "./hooks/hooks.json"`

**Validación**:
```bash
jq empty cc/.claude-plugin/plugin.json
jq . cc/.claude-plugin/plugin.json
```

---

### FASE 8: Actualizar Documentación (30 min)

#### 8.1 Actualizar README.md

**Archivo**: `cc/README.md`

**Agregar sección** después de "Quick Start":

```markdown
### Session Management (v3.0)

The CC plugin now includes Session Manager v2 with Git-like references:

```bash
# Use @latest reference (easiest!)
/cc:plan @latest
/cc:code @

# Use short ID (8 chars)
/cc:plan n7c3fa9k

# Use slug search
/cc:plan @/add-user-auth

# Manage sessions
/session-list                    # View all sessions
/session-list auth --limit 10    # Filter by keyword
/session-migrate --execute       # Migrate v1 → v2
/session-rebuild-index          # Rebuild index
```

#### Session ID Format (v2)

```
v2-YYYYMMDDTHHmmss-base32random-kebab-slug

Example:
v2-20251109T183846-n7c3fa9k-implement-user-authentication-with-oauth

Components:
  v2              - Version prefix
  20251109T183846 - ISO8601 timestamp (sortable)
  n7c3fa9k        - 8-char base32 random ID
  implement-...   - Kebab-case slug
```

#### Quick References

| Reference | Description | Example |
|-----------|-------------|---------|
| `@latest` | Most recent session | `/cc:plan @latest` |
| `@` | Shorthand for @latest | `/cc:code @` |
| `@{N}` | Nth previous session | `/cc:plan @{1}` |
| Short ID | 8-char prefix match | `/cc:code n7c3fa9k` |
| `@/slug` | Slug search | `/cc:plan @/auth` |
| Full ID | Complete session ID | `/cc:code v2-20251109T...` |
```

#### 8.2 Actualizar PLUGIN_STRUCTURE.md

**Archivo**: `cc/PLUGIN_STRUCTURE.md`

**Actualizar estructura de directorios** para incluir:

```markdown
cc/                                    # Plugin Root Directory
├── .claude-plugin/
│   └── plugin.json                   # ✅ Plugin manifest (with hooks)
│
├── hooks/                             # ✅ Lifecycle hooks (NEW v3.0)
│   ├── hooks.json                     # Hook configuration
│   ├── session-start/
│   │   └── load-active-session.sh
│   ├── session-end/
│   │   └── save-session-state.sh
│   ├── pre-tool-use/
│   │   └── validate-session.sh
│   ├── stop/
│   │   └── auto-save-session.sh
│   ├── user-prompt-submit/
│   │   └── load-context.sh
│   ├── README.md
│   └── test-hooks.sh
│
├── scripts/                           # ✅ Session management scripts (NEW v3.0)
│   ├── generate-session-id.sh         # v2 ID generation
│   ├── resolve-session-id.sh          # Reference resolution
│   ├── session-index.sh               # Index management
│   ├── test-scripts.sh                # Script tests
│   └── README.md
│
├── skills/                            # ✅ AI-invoked skills (NEW v3.0)
│   └── session-finder/                # Natural language session search
│       ├── SKILL.md
│       └── resources/
│           └── session-patterns.md
│
├── commands/                          # ✅ Custom slash commands
│   ├── explore.md                     # Updated with v2 sessions
│   ├── plan.md                        # Updated with reference resolution
│   ├── code.md                        # Updated with reference resolution
│   ├── commit.md
│   ├── session-list.md                # NEW v3.0
│   ├── session-migrate.md             # NEW v3.0
│   └── session-rebuild-index.md       # NEW v3.0
│
├── agents/                            # ✅ Custom subagents
│   ├── code-search-agent.md
│   ├── context-synthesis-agent.md
│   └── web-research-agent.md
│
├── CLAUDE.md                          # Plugin overview
├── README.md                          # User documentation (updated)
├── PLUGIN_STRUCTURE.md                # This file (updated)
└── SESSION_INTEGRATION_PLAN.md        # Integration plan (this document)
```

---

### FASE 9: Testing y Validación (45 min)

#### 9.1 Test de Scripts

```bash
# Test 1: Generación de ID
bash cc/scripts/generate-session-id.sh "test feature"
# Esperado: v2-YYYYMMDDTHHMMSS-xxxxxxxx-test-feature

# Test 2: Inicializar índice
bash cc/scripts/session-index.sh init
# Esperado: Initialized session index: .claude/sessions/index.json

# Test 3: Agregar sesión de prueba
bash cc/scripts/session-index.sh add \
  "v2-20251110T120000-test1234-test-session" \
  "test-session" \
  "exploration" \
  "in_progress" \
  "main"
# Esperado: Added session: v2-...

# Test 4: Resolver referencia @latest
bash cc/scripts/resolve-session-id.sh "@latest"
# Esperado: v2-20251110T120000-test1234-test-session

# Test 5: Resolver short ID
bash cc/scripts/resolve-session-id.sh "test1234"
# Esperado: v2-20251110T120000-test1234-test-session
```

#### 9.2 Test de Hooks

```bash
# Ejecutar test suite
cd cc
bash hooks/test-hooks.sh

# Esperado:
# ✓ Configuration file exists
# ✓ Configuration is valid JSON
# ✓ Hook exists and is executable: session-start
# ✓ Hook exists and is executable: session-end
# ✓ Hook exists and is executable: pre-tool-use
# ✓ Hook exists and is executable: stop
# ✓ Hook exists and is executable: user-prompt-submit
# ✓ All tests passed!
```

#### 9.3 Test de Comandos

**Test /session-list:**
```bash
# Simular comando (requiere Claude Code environment)
# Verificar sintaxis bash
bash -n cc/commands/session-list.md
```

**Test /cc:explore (actualizado):**
```bash
# Verificar sintaxis
bash -n cc/commands/explore.md

# Verificar que usa scripts correctos
grep "generate-session-id.sh" cc/commands/explore.md
grep "session-index.sh" cc/commands/explore.md
```

**Test /cc:plan (actualizado):**
```bash
# Verificar sintaxis
bash -n cc/commands/plan.md

# Verificar que usa resolución
grep "resolve-session-id.sh" cc/commands/plan.md
```

**Test /cc:code (actualizado):**
```bash
# Verificar sintaxis
bash -n cc/commands/code.md

# Verificar que usa resolución
grep "resolve-session-id.sh" cc/commands/code.md
```

#### 9.4 Test de Integración

**Escenario completo**:
1. Crear sesión con /cc:explore
2. Verificar aparece en /session-list
3. Usar @latest en /cc:plan
4. Usar short ID en /cc:code
5. Verificar índice se actualiza

---

### FASE 10: Limpieza y Finalización (15 min)

#### 10.1 Verificar permisos de ejecución
```bash
chmod +x cc/scripts/*.sh
chmod +x cc/hooks/*/*.sh
find cc -name "*.sh" -exec ls -la {} \;
```

#### 10.2 Verificar variables de entorno correctas
```bash
# Buscar cualquier CLAUDE_PLUGIN_ROOT que deba ser CLAUDE_PLUGIN_DIR
grep -r "CLAUDE_PLUGIN_ROOT" cc/
# Esperado: Sin resultados (todos deben ser CLAUDE_PLUGIN_DIR)
```

#### 10.3 Validar JSON files
```bash
jq empty cc/.claude-plugin/plugin.json
jq empty cc/hooks/hooks.json
jq empty .claude/sessions/index.json 2>/dev/null || echo "Index will be created on first use"
```

#### 10.4 Crear commit
```bash
git add cc/
git commit -m "feat: integrate Session Manager v2 into cc plugin

- Add v2 session ID generation (zero dependencies)
- Add Git-like reference system (@latest, short IDs, slug search)
- Add session index with fast lookups
- Add session management commands (list, migrate, rebuild-index)
- Add lifecycle hooks (SessionStart, SessionEnd, PreToolUse, Stop, UserPromptSubmit)
- Add session-finder skill for natural language search
- Update explore/plan/code commands to use v2 sessions
- Update plugin.json to v3.0.0 with hooks configuration
- Maintain backward compatibility with v1 sessions

Breaking changes:
- Session ID format: v1 (YYYYMMDD_HHMMSS_hex) → v2 (v2-YYYYMMDDTHHmmss-base32-slug)
- Use /session-migrate to migrate existing sessions

New commands:
- /session-list - Browse and filter sessions
- /session-migrate - Migrate v1 → v2
- /session-rebuild-index - Rebuild index

Session references now support:
- @latest or @ - Most recent session
- @{N} - Nth previous session
- Short ID - 8-char prefix (e.g., n7c3fa9k)
- @/slug - Slug search (e.g., @/auth)
- Full v2 ID - Complete session identifier"
```

---

## Checklist de Validación Final

### Estructura
- [ ] Todos los directorios creados (scripts/, hooks/, skills/)
- [ ] Todos los archivos copiados correctamente
- [ ] Todos los scripts tienen permisos de ejecución (+x)

### Configuración
- [ ] plugin.json actualizado con hooks y versión 3.0.0
- [ ] hooks/hooks.json creado y válido
- [ ] Todas las variables CLAUDE_PLUGIN_ROOT → CLAUDE_PLUGIN_DIR

### Scripts
- [ ] generate-session-id.sh funciona
- [ ] resolve-session-id.sh funciona
- [ ] session-index.sh funciona (init, add, set-ref, lookup)
- [ ] test-scripts.sh pasa todos los tests

### Comandos
- [ ] /session-list tiene sintaxis válida
- [ ] /session-migrate tiene sintaxis válida
- [ ] /session-rebuild-index tiene sintaxis válida
- [ ] /cc:explore actualizado con v2 sessions
- [ ] /cc:plan actualizado con resolución de referencias
- [ ] /cc:code actualizado con resolución de referencias
- [ ] /cc:commit sin cambios (OK)

### Hooks
- [ ] session-start/load-active-session.sh ejecutable y funcional
- [ ] session-end/save-session-state.sh ejecutable y funcional
- [ ] pre-tool-use/validate-session.sh ejecutable y funcional
- [ ] stop/auto-save-session.sh ejecutable y funcional
- [ ] user-prompt-submit/load-context.sh ejecutable y funcional
- [ ] test-hooks.sh pasa todos los tests

### Skills
- [ ] session-finder/SKILL.md copiado
- [ ] session-finder/resources/ copiado

### Documentación
- [ ] README.md actualizado con Session Management v2
- [ ] PLUGIN_STRUCTURE.md actualizado con nueva estructura
- [ ] CHANGELOG agregado en README (v3.0.0)

### Testing
- [ ] Scripts core funcionan correctamente
- [ ] Hooks pasan test suite
- [ ] Comandos tienen sintaxis bash válida
- [ ] Archivos JSON son válidos
- [ ] Integración completa probada

---

## Rollback Plan

Si algo falla durante la integración:

### Rollback Completo
```bash
# Restaurar backups
cp cc/commands/explore.md.backup cc/commands/explore.md
cp cc/.claude-plugin/plugin.json.backup cc/.claude-plugin/plugin.json

# Eliminar cambios
rm -rf cc/scripts
rm -rf cc/hooks
rm -rf cc/skills/session-finder
rm cc/commands/session-*.md

# Volver a versión anterior
git checkout cc/
```

### Rollback Parcial
Si solo una fase falla, revertir esa fase específica:
```bash
# Ejemplo: Revertir solo hooks
rm -rf cc/hooks
rm -f cc/.claude-plugin/plugin.json
cp cc/.claude-plugin/plugin.json.backup cc/.claude-plugin/plugin.json
```

---

## Estimación de Tiempo

| Fase | Tiempo | Dificultad |
|------|--------|------------|
| 1. Preparación | 30 min | Fácil |
| 2. Scripts Core | 20 min | Fácil |
| 3. Comandos Gestión | 30 min | Media |
| 4. Hooks | 45 min | Media-Alta |
| 5. Skills | 20 min | Fácil |
| 6. Actualizar Comandos | 60 min | Alta |
| 7. Configuración | 10 min | Fácil |
| 8. Documentación | 30 min | Media |
| 9. Testing | 45 min | Media |
| 10. Finalización | 15 min | Fácil |
| **TOTAL** | **~5 horas** | **Media-Alta** |

---

## Notas Importantes

### Compatibilidad
- ✅ Backward compatible: sesiones v1 siguen funcionando mediante fallback
- ✅ Zero dependencies: No requiere OpenSSL (usa bash + /dev/urandom)
- ✅ Cross-platform: Linux y macOS

### Dependencias
- **Requerido**: bash 3.2+, jq
- **Opcional**: git (para branch detection)

### Variables de Entorno
- `CLAUDE_PLUGIN_DIR`: Directorio del plugin (set por Claude Code)
- No usar `CLAUDE_PLUGIN_ROOT` (era de ./session, cambiar a DIR)

### Convenciones
- Session IDs v2: `v2-YYYYMMDDTHHmmss-base32-slug`
- Referencias: @latest, @, @{N}, short-id, @/slug
- Índice: `.claude/sessions/index.json`

---

## Siguientes Pasos Post-Integración

1. **Testing extensivo** con usuarios reales
2. **Migrar sesiones existentes** con /session-migrate
3. **Documentar casos edge** encontrados
4. **Optimizar performance** del índice si es necesario
5. **Agregar métricas** de uso de sesiones
6. **Considerar features adicionales**:
   - Tags para sesiones
   - Archivado automático
   - Estadísticas de sesiones
   - Export/import de sesiones

---

**Fin del Plan de Integración**

*Documento creado: 2025-11-10*
*Versión: 1.0*
*Estado: Listo para ejecución*
