# Claude Code: Mejores Prácticas para Creación de Prompts

**Fecha**: 2025-11-14
**Fuentes**: Documentación oficial de Anthropic, comunidad Claude Code, prompt engineering research

---

## 1. Principios Fundamentales de Accuracy y Reliability

### 1.1 Especificidad sobre Generalidad
- **Principio**: "Claude Code's success rate improves significantly with more specific instructions, especially on first attempts"
- **Anti-patrón**: "add tests for foo.py" ❌
- **Patrón correcto**: "Add unit tests for foo.py covering: edge cases (null inputs, max values), error handling (ValueError, TypeError), and integration with bar module" ✅
- **Impacto**: Reduce iteraciones y course corrections

### 1.2 Prevención de Scope Creep
- **Problema**: El agente tiende a hacer más de lo pedido si no hay límites claros
- **Técnicas**:
  - Instrucciones explícitas de lo que NO hacer: "IMPORTANT: Only modify the contact form component, don't change routing logic"
  - Secciones `<critical>` y `<requirements>` con restricciones claras
  - Delimitación de archivos, líneas, o componentes específicos
- **Ejemplo**: "Refactor authentication BUT do not modify tests, do not add new dependencies, do not change API contracts"

### 1.3 Contexto Visual y Concreto
- Incluir screenshots, mockups, file paths específicos
- Referencias a `file:line` para evidencia concreta
- Evitar descripciones vagas sin ubicación precisa
- **Impacto**: Mejora dramática en alignment con expectativas

---

## 2. Estructuras Efectivas de Prompts

### 2.1 XML Tags para Organización
- `<task>`: Delimita tareas discretas
- `<requirements>`: Especifica restricciones y estándares
- `<critical>`: Marca secciones absolutamente obligatorias
- `<template>`: Define formato exacto de output
- `<context>`: Información de background
- **Beneficio**: Minimiza confusión, mejora parsing del modelo

### 2.2 Chain of Thought (Razonamiento Paso a Paso)
- Útil para tareas complejas de análisis y problem-solving
- Permite al modelo descomponer problemas step-by-step
- Reduce errores en lógica y cómputos
- **Implementación**: Incluir fases discretas con validación entre pasos

### 2.3 Progressive Refinement
- Dividir tareas grandes en chunks pequeños y discretos
- Cada chunk con scope y requirements específicos
- Validación humana en puntos críticos (human-in-the-loop)
- **Patrón**: Research → Plan → Implement → Review → Commit

---

## 3. Optimización de Tokens y Eficiencia

### 3.1 Concisión sin Pérdida de Claridad
- Target: ~150-250 líneas para comandos complejos, <100 para simples
- Evitar repetición de contexto ya disponible en CLAUDE.md
- Referencias con `@file/path.md` en lugar de duplicar contenido
- Eliminar frases redundantes, mantener solo lo esencial

### 3.2 Parámetros Dinámicos
- Usar `$ARGUMENTS` / `$1, $2, $3` para parametrización
- Permitir que el usuario ajuste comportamiento sin modificar prompt
- **Ejemplo**: `$1` = session_id, `$2` = focus area, `$3` = constraints

### 3.3 Conditional Logic
- Adaptar comportamiento según contexto detectado
- Evitar ejecutar operaciones innecesarias
- **Ejemplo**: Detectar si necesita code analysis, web research, o ambos
- Ahorro token: Skip research innecesaria (código del /plan refactorizado)

---

## 4. Patterns Específicos para Comandos

### 4.1 Session-Based Commands (ej: /code, /plan)
**Estructura recomendada**:
1. **Session Validation**: Verificar existencia, cargar contexto
2. **Task Execution**: Operación principal con subtareas delimitadas
3. **Output Generation**: Documentar resultados en formato estandarizado
4. **User Approval**: Critical operations require explicit approval
5. **Next Steps**: Guiar al usuario hacia siguientes acciones

### 4.2 Agente Selection Intelligence
- Analizar query intent ANTES de lanzar agentes
- Clasificar: CODE-ONLY | WEB-ONLY | BOTH | UNCLEAR
- Si UNCLEAR → preguntar al usuario en lugar de adivinar
- **Impacto**: 25-40% reducción de tokens en casos CODE/WEB-only

### 4.3 Evidence-Based Instructions
- Cada claim debe tener evidencia: `file:line` o URL
- Evitar descripciones vagas como "improve code quality"
- Preferir "Refactor utils/auth.py:45-67 to reduce cyclomatic complexity from 12 to <8"
- Priorización visual: 🔴 High | 🟡 Medium | 🟢 Low

---

## 5. Reliability Patterns

### 5.1 Validation en Cada Paso
- Incluir comandos de verificación: tests, linters, builds
- Criterios de éxito medibles y verificables
- **Template**:
  ```bash
  [command]  # Expected outcome
  [test]     # Success criteria
  ```

### 5.2 Error Handling Explícito
- Anticipar failure modes comunes
- Proveer instrucciones para cada error esperado
- **Ejemplo**:
  ```bash
  [ -z "$SESSION_DIR" ] && echo "❌ Session not found" && exit 1
  ```

### 5.3 Rollback y Safety
- NEVER destructive operations without explicit user approval
- Incluir `<critical>Wait for user approval before...</critical>`
- Documentar cambios ANTES de ejecutar para review

---

## 6. Flexibilidad y Versatilidad

### 6.1 Adaptive Behavior
- Ajustar output según research strategy (CODE/WEB/BOTH)
- Usar conditional sections: `[IF STRATEGY = BOTH, include:...]`
- No forzar estructura rígida cuando el contexto varía

### 6.2 Multi-Tool Coordination
- Especificar allowed-tools en frontmatter
- Usar herramientas especializadas (Read/Write/Edit) en lugar de bash cuando posible
- Coordinar Task agents con modelo principal

### 6.3 Argument Flexibility
- Soportar variaciones de input con argument-hint
- Proveer defaults sensibles
- Validar inputs pero no ser excesivamente restrictivo

---

## 7. Anti-Patterns a Evitar

### ❌ Evitar:
1. **Prompts vagos**: "improve the code" sin especificar qué ni cómo
2. **Scope ilimitado**: Sin delimitación de archivos, líneas, o componentes
3. **Ausencia de validación**: No checks de success/failure
4. **Duplicación de contexto**: Repetir lo que ya está en CLAUDE.md
5. **Proactividad excesiva**: Hacer más de lo pedido "por si acaso"
6. **Instrucciones ambiguas**: Múltiples interpretaciones posibles
7. **Prompts extensos**: >500 líneas con contenido redundante
8. **Falta de priorización**: Todo parece igual de importante

### ✅ Preferir:
1. **Prompts concretos**: "Refactor auth.py:45-67 to extract validation logic into utils/validators.py"
2. **Scope delimitado**: Archivos específicos, líneas exactas, componentes nombrados
3. **Validación integrada**: Tests + linters + success criteria
4. **Referencias ligeras**: `@path/to/file.md` para detalles
5. **Scope estricto**: "Only do X, do not do Y, do not do Z"
6. **Instrucciones inequívocas**: Un solo camino claro de ejecución
7. **Prompts concisos**: 100-250 líneas enfocadas
8. **Priorización visual**: 🔴🟡🟢 con impacto y effort claros

---

## 8. Testing y Validación de Prompts

### 8.1 Iterative Refinement
- **Principio**: "Test effectiveness through iteration rather than assuming initial versions work optimally"
- Primera versión → test con casos reales → ajustar según resultados
- Medir: token usage, success rate, iterations needed, scope creep

### 8.2 Métricas de Calidad
- **Accuracy**: ¿Hace exactamente lo pedido? ¿Sin extras?
- **Reliability**: ¿Resultados consistentes en múltiples runs?
- **Flexibility**: ¿Adapta a diferentes contextos y queries?
- **Efficiency**: ¿Token usage optimizado? ¿Minimal tool calls?

### 8.3 User Feedback Loop
- Incluir puntos de aprobación humana en operaciones críticas
- Presentar summary antes de ejecutar cambios destructivos
- Permitir ajustes mid-execution con Escape key

---

## 9. Extended Thinking

### 9.1 Cuando Usar
- Tareas complejas que requieren análisis profundo
- Synthesis de múltiples fuentes de información
- Architectural decisions con trade-offs
- Planning de implementaciones multi-fase

### 9.2 Como Activar
- Keywords: "think", "think hard", "think harder", "ultrathink"
- Asigna progresivamente más compute según complejidad
- **Impacto**: Mejor calidad en decisions complejas, más lento

---

## 10. Resumen Ejecutivo: Code Command Best Practices

Para el comando /code específicamente:

### ✅ Mantener:
- Session validation y context loading automático
- Template structure con secciones claras
- User approval antes de finalizar
- Output documentation en code.md

### ⚙️ Mejorar:
1. **Scope Control**: Añadir `<critical>` sections delimitando exactamente qué modificar
2. **Validation**: Tests + linters integrados en el flow, no solo mencionados
3. **Evidence**: Referencias file:line para cada cambio documentado
4. **Flexibility**: Soportar diferentes modos (full implementation vs incremental vs review-only)
5. **Error Handling**: Anticipar failures comunes (tests failing, plan missing, etc.)

### 🎯 Target Metrics:
- **Líneas**: <150 (actualmente 110, puede crecer moderadamente para mejorar clarity)
- **Accuracy**: 95%+ first-time success rate
- **Scope adherence**: 100% (zero unauthorized modifications)
- **Token efficiency**: Minimal tool calls, referencias en lugar de duplicación

---

## Referencias

- [Official Anthropic Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Prompt Engineering for Claude](https://docs.claude.com/en/docs/build-with-claude/prompt-engineering/claude-4-best-practices)
- [Claude Code Community Resources](https://claudelog.com/)

**Autor**: Claude (Sonnet 4.5)
**Review**: Pendiente
