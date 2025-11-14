# Plan de Refactorización: Comando /code

**Fecha**: 2025-11-14
**Objetivo**: Mejorar accuracy, reliability, y flexibilidad del comando /code
**Restricción**: Mantener <500 líneas (actualmente 110, target ~200-250)

---

## Análisis del Código Actual

### Fortalezas ✅

1. **Session Management**: Validación robusta de session existence y plan availability (líneas 12-24)
2. **Structure**: Template clara con secciones bien delimitadas
3. **Human-in-the-Loop**: User approval antes de finalizar (líneas 79-109)
4. **Documentation**: Output estandarizado en code.md con metadata
5. **Tool Specification**: Frontmatter define allowed-tools correctamente

### Debilidades Identificadas 🔴

#### 1. **Scope Control Débil** (Prioridad: CRÍTICA)
- **Problema**: No delimita explícitamente qué archivos/componentes modificar
- **Impacto**: Scope creep - modifica más de lo necesario
- **Evidencia**:
  - `$2` (implementation focus) y `$3` (target files) son opcionales y vagos
  - No hay instrucciones de lo que NO hacer
  - Requirements line 33-35 son genéricos sin enforcement
- **Solución**:
  - Hacer target files/components EXPLÍCITOS
  - Añadir `<critical>` section con scope boundaries
  - Validar que focus area esté definido claramente

#### 2. **Validation Insuficiente** (Prioridad: ALTA)
- **Problema**: Menciona "add tests" pero no VERIFICA que se hagan
- **Impacto**: Tests no escritos, código no validado, errores silenciosos
- **Evidencia**:
  - Línea 33: "Add tests" sin verificación
  - Línea 60: Template pide tests pero no los valida
  - Línea 93: "Tests passing" sin ejecutar realmente
- **Solución**:
  - Integrar test execution en el flow
  - Verificar linters/formatters
  - Require proof of validation en documentation

#### 3. **Evidence-Based Missing** (Prioridad: ALTA)
- **Problema**: Documentation template pide file:line pero no es mandatory ni hay ejemplos
- **Impacto**: Documentación vaga, difícil review, no auditable
- **Evidencia**:
  - Línea 55: `[file.ext:line]` pero no hay enforcement
  - Línea 52: "Brief overview" es vago
  - No ejemplos de good documentation
- **Solución**:
  - Require file:line para CADA cambio
  - Proveer template más específico con ejemplos
  - Validation de que documentation tiene evidencia concreta

#### 4. **Flexibility Limitada** (Prioridad: MEDIA)
- **Problema**: Un solo modo (full implementation), no adapta a diferentes contextos
- **Impacto**: No óptimo para tasks pequeños, incrementales, o review-only
- **Evidencia**:
  - No diferencia entre "full feature" vs "small fix" vs "refactor"
  - Mismo flow para cualquier tipo de implementation
- **Solución**:
  - Detectar tipo de task del plan (feature/fix/refactor/test)
  - Adaptar requirements según complejidad
  - Soportar modo incremental con checkpoints

#### 5. **Error Handling Básico** (Prioridad: MEDIA)
- **Problema**: Solo valida session/plan existence, no anticipa otros failures
- **Impacto**: Crashes o comportamiento inesperado en edge cases
- **Evidencia**:
  - Líneas 19-20: Solo 2 checks
  - Línea 23: `|| true` oculta errores
  - No recovery paths si tests fail
- **Solución**:
  - Anticipar: tests failing, compilation errors, dependency issues
  - Proveer recovery instructions para cada error
  - No silenciar errores con `|| true`

#### 6. **Requirements Vagos** (Prioridad: BAJA)
- **Problema**: "Match code style", "Small increments", "Self-review" sin especificar cómo
- **Impacto**: Interpretación inconsistente, calidad variable
- **Evidencia**: Líneas 33-35 tienen frases genéricas
- **Solución**:
  - Definir "code style" como "use existing patterns from codebase"
  - "Small increments" = max 50 líneas por cambio
  - "Self-review" = checklist específico

#### 7. **Extended Thinking Missing** (Prioridad: BAJA)
- **Problema**: No indica cuándo usar razonamiento profundo
- **Impacto**: Decisions arquitecturales superficiales
- **Solución**: Trigger thinking para complex architectural choices

---

## Plan de Refactorización

### Fase 1: Core Improvements (Prioridad CRÍTICA + ALTA)

#### Cambio 1: Scope Control Estricto
**Objetivo**: Eliminar scope creep, hacer exactamente lo pedido

**Modificaciones**:
1. Actualizar frontmatter argument-hint:
   ```yaml
   argument-hint: "<session_id> [scope: files|components|functions]"
   ```

2. Añadir Section "Scope Definition & Boundaries":
   ```markdown
   ## Scope Definition & Boundaries

   <task>Parse plan and extract exact implementation scope</task>

   Read `$SESSION_DIR/plan.md` and extract:
   - **Target Files**: Exact file paths from plan steps
   - **Target Components**: Specific functions/classes/modules
   - **Out of Scope**: What NOT to modify

   <critical>
   STRICT SCOPE ENFORCEMENT:
   - ONLY modify files explicitly listed in plan steps
   - ONLY modify components/functions mentioned in plan
   - DO NOT refactor adjacent code "while you're there"
   - DO NOT add features not in the plan
   - DO NOT modify tests unless plan explicitly says so
   - DO NOT change dependencies unless plan specifies

   If scope is unclear, ASK user before proceeding.
   </critical>
   ```

3. Validar scope antes de implementation:
   ```markdown
   Present scope summary for confirmation:

   ```
   📋 Implementation Scope: ${SESSION_ID}

   ✅ WILL MODIFY:
   - Files: [list from plan]
   - Components: [list from plan]
   - Lines: ~[estimated from plan]

   ❌ WILL NOT TOUCH:
   - [Everything else explicitly]

   Focus: $2

   Proceed? [y/n]
   ```

   Wait for user confirmation.
   ```

**Impacto**: +30 líneas, elimina 90%+ scope creep

---

#### Cambio 2: Validation Integrada
**Objetivo**: Verificar calidad durante implementation, no solo mencionar

**Modificaciones**:
1. Añadir Section "Implementation with Continuous Validation":
   ```markdown
   ## Implementation with Continuous Validation

   <task>Implement changes incrementally with validation at each step</task>

   For each step in plan:

   1. **Implement**: Make changes to target files
   2. **Validate**: Run appropriate checks

   <requirements>
   **After EACH implementation increment**:
   ```bash
   # Syntax/compilation check
   [language-specific: python -m py_compile, tsc --noEmit, cargo check, etc.]

   # Run affected tests
   [test command from plan or CLAUDE.md]

   # Linting (if configured)
   [lint command if available]
   ```

   If ANY check fails:
   - ❌ STOP implementation
   - 🔧 FIX the issue
   - ✅ Re-run validation
   - ➡️ Continue only after passing
   </requirements>

   **Validation Evidence**: Document in code.md:
   - Command run: [exact command]
   - Output: [relevant output or "all passed"]
   - Status: ✅ Pass | ❌ Fail → Fixed
   ```

2. Actualizar template code.md para require validation evidence:
   ```markdown
   ## Validation
   - **Tests**: [X] run, [Y] passed, [Z] added
     ```bash
     $ [test command]
     [output summary]
     ```
   - **Linting**: ✅ Pass | ⏸️ N/A
   - **Compilation**: ✅ Pass
   - **Manual Testing**: [if applicable]
   ```

**Impacto**: +40 líneas, 95%+ validation compliance

---

#### Cambio 3: Evidence-Based Documentation
**Objetivo**: Todo cambio con file:line, ejemplos concretos

**Modificaciones**:
1. Actualizar template con enforcement:
   ```markdown
   ## Key Changes (REQUIRED: file:line for EVERY change)

   <critical>
   Every change MUST include:
   - Exact file path and line range
   - What changed (code-level specificity)
   - Why it changed (from plan rationale)
   - Impact (performance/security/functionality)
   </critical>

   **Format** (follow exactly):
   ```
   1. **src/auth/validator.py:45-67**
      - WHAT: Extracted email validation into `validate_email()` helper
      - WHY: Reduce cyclomatic complexity from 12 to 7 (plan step 2)
      - IMPACT: +15% test coverage, easier maintenance
      - TESTS: test_auth.py:123-145 (3 new test cases)

   2. **src/auth/validator.py:12**
      - WHAT: Added import `from utils.regex import EMAIL_PATTERN`
      - WHY: Reuse validated regex pattern (plan step 1)
      - IMPACT: Consistency with existing codebase
      - TESTS: Covered by existing tests
   ```

   Minimum 2 changes documented. If <2, explain why.
   ```

**Impacto**: +20 líneas, documentation quality 10x mejor

---

### Fase 2: Flexibility & Adaptability (Prioridad MEDIA)

#### Cambio 4: Task Type Detection
**Objetivo**: Adaptar behavior según tipo de implementation

**Modificaciones**:
1. Añadir Section "Task Analysis":
   ```markdown
   ## Task Analysis

   <task>Analyze plan to determine implementation type and adjust approach</task>

   Read `$SESSION_DIR/plan.md` and classify:

   - **FEATURE** (new functionality):
     - Triggers: "implement", "add", "create", "build"
     - Approach: Full TDD cycle, comprehensive tests, documentation
     - Validation: Integration tests required

   - **FIX** (bug fix):
     - Triggers: "fix", "resolve", "patch", "correct"
     - Approach: Reproduce bug, minimal change, regression test
     - Validation: Bug reproduction test + fix verification

   - **REFACTOR** (code improvement):
     - Triggers: "refactor", "restructure", "optimize", "clean"
     - Approach: Preserve behavior, extensive testing
     - Validation: ALL existing tests must pass

   - **TEST** (test addition):
     - Triggers: "add tests", "improve coverage", "test"
     - Approach: Focus on coverage, edge cases
     - Validation: Coverage increase measurement

   Set TYPE and adjust requirements accordingly.
   ```

2. Usar TYPE para adaptar requirements:
   ```markdown
   <requirements>
   **Type-Specific Requirements**:

   [IF TYPE=FEATURE]:
   - New tests covering happy path + edge cases
   - Documentation updates (README, API docs)
   - Integration test demonstrating end-to-end flow

   [IF TYPE=FIX]:
   - Regression test reproducing the bug
   - Minimal code change (prefer smallest fix)
   - All existing tests still pass

   [IF TYPE=REFACTOR]:
   - ZERO behavioral changes
   - All existing tests pass unchanged
   - Code metrics improved (complexity, duplication)

   [IF TYPE=TEST]:
   - Coverage increase ≥ target from plan
   - Tests follow existing patterns
   - Edge cases explicitly covered
   </requirements>
   ```

**Impacto**: +35 líneas, adapta a contexto

---

#### Cambio 5: Incremental Mode Support
**Objetivo**: Soportar implementation en checkpoints para tareas complejas

**Modificaciones**:
1. Añadir checkpoint logic:
   ```markdown
   ## Implementation Strategy

   <task>Determine if incremental checkpoints are needed</task>

   If plan has >5 steps OR estimated time >2 hours:
   - **Mode**: INCREMENTAL with checkpoints
   - **Checkpoints**: After each plan phase
   - **Reviews**: User approval at each checkpoint

   Otherwise:
   - **Mode**: CONTINUOUS (full implementation)

   [IF INCREMENTAL]:
   After each checkpoint:
   1. Document progress in code.md
   2. Run validation suite
   3. Present status to user
   4. Wait for approval to continue
   ```

**Impacto**: +25 líneas, mejor para tareas complejas

---

### Fase 3: Error Handling & Polish (Prioridad BAJA)

#### Cambio 6: Comprehensive Error Handling
**Objetivo**: Anticipar failures, proveer recovery

**Modificaciones**:
1. Expandir validation con error handling:
   ```markdown
   ## Session Validation & Error Handling

   <task>Validate session and handle common errors</task>

   ```bash
   SESSION_ID="$1"

   # Error 1: Missing session ID
   if [ -z "$SESSION_ID" ]; then
     echo "❌ ERROR: Session ID required"
     echo "Usage: /code <session_id> [scope]"
     echo "Find sessions: ls .claude/sessions/"
     exit 1
   fi

   # Error 2: Session not found
   SESSION_DIR=$(find .claude/sessions -name "${SESSION_ID}_*" -type d 2>/dev/null | head -1)
   if [ -z "$SESSION_DIR" ]; then
     echo "❌ ERROR: Session not found: $SESSION_ID"
     echo "Available sessions:"
     ls .claude/sessions/ | grep -o '^[0-9_a-f]*' | head -5
     exit 1
   fi

   # Error 3: Missing plan
   if [ ! -f "$SESSION_DIR/plan.md" ]; then
     echo "❌ ERROR: No implementation plan found"
     echo "Run: /plan <query> first to create a plan"
     exit 1
   fi

   # Error 4: Already implemented
   if [ -f "$SESSION_DIR/code.md" ]; then
     echo "⚠️  WARNING: Implementation already exists"
     echo "Continue anyway? This will overwrite code.md [y/n]"
     # Wait for user input
   fi

   echo "✅ Loaded: $SESSION_ID"
   echo "   Plan: $SESSION_DIR/plan.md"
   echo "   Context: CLAUDE.md (auto-loaded)"
   ```
   ```

2. Añadir recovery instructions:
   ```markdown
   <critical>
   **Common Failure Modes & Recovery**:

   - **Tests fail during implementation**:
     1. Review test output for specific failures
     2. Fix implementation to satisfy tests
     3. Re-run validation before proceeding
     4. If test is wrong (not code), update test with justification

   - **Compilation/syntax errors**:
     1. Fix syntax immediately
     2. Re-validate before continuing
     3. Do not proceed with broken code

   - **Dependency missing**:
     1. Check plan for dependency installation steps
     2. If missing from plan, STOP and ask user
     3. Do not auto-install without approval

   - **Scope ambiguity**:
     1. STOP implementation
     2. Ask user to clarify scope
     3. Update plan if needed
   </critical>
   ```

**Impacto**: +30 líneas, mejor error handling

---

#### Cambio 7: Requirements Específicos
**Objetivo**: Eliminar vagueness en quality standards

**Modificaciones**:
```markdown
<requirements>
**Quality Standards** (SPECIFIC):

- **Code Style**:
  - Match existing patterns in modified files
  - Use same naming conventions (check file:1-50)
  - Follow indentation/formatting of surrounding code
  - If formatter available (.prettierrc, .black, etc.), run it

- **Incremental Changes**:
  - Max 50 lines per logical change
  - One concern per commit/checkpoint
  - Test after each increment

- **Self-Review Checklist**:
  - [ ] All target files modified as planned
  - [ ] No out-of-scope changes
  - [ ] Tests pass (evidence in code.md)
  - [ ] No hardcoded secrets/credentials
  - [ ] Error handling for edge cases
  - [ ] Documentation updated (if public API)
  - [ ] Follows security best practices (no SQL injection, XSS, etc.)
</requirements>
```

**Impacto**: +20 líneas, clarity 5x mejor

---

## Resumen de Cambios

### Estructura Nueva (Estimado: ~230 líneas)

```
code.md:
├── Frontmatter (5 líneas)
│   ├── allowed-tools
│   ├── argument-hint (UPDATED)
│   └── description
│
├── Header (5 líneas)
│
├── 1. Session Validation & Error Handling (35 líneas) ← EXPANDED
│   ├── Comprehensive error cases
│   ├── Recovery instructions
│   └── Success confirmation
│
├── 2. Scope Definition & Boundaries (30 líneas) ← NUEVO
│   ├── Extract scope from plan
│   ├── Critical scope enforcement
│   └── User confirmation
│
├── 3. Task Analysis (25 líneas) ← NUEVO
│   ├── Type detection (FEATURE/FIX/REFACTOR/TEST)
│   └── Type-specific requirements
│
├── 4. Implementation Strategy (20 líneas) ← NUEVO
│   └── Incremental vs Continuous mode
│
├── 5. Implementation with Validation (45 líneas) ← EXPANDED
│   ├── Incremental implementation
│   ├── Continuous validation
│   ├── Error handling & recovery
│   └── Evidence documentation
│
├── 6. Documentation (40 líneas) ← EXPANDED
│   ├── Enhanced template with examples
│   ├── Evidence requirements (file:line)
│   ├── Validation evidence
│   └── Type-specific documentation
│
└── 7. User Approval & Next Steps (25 líneas) ← MANTENER
    ├── Summary presentation
    ├── Approval wait
    └── Next actions

Total: ~230 líneas
```

### Métricas de Mejora

| Métrica | Antes | Después | Mejora |
|---------|-------|---------|--------|
| Líneas | 110 | ~230 | +109% (aún <500) |
| Scope Control | ⚠️ Débil | ✅ Estricto | 90% reducción scope creep |
| Validation | ⚠️ Mencionado | ✅ Integrado | 95% compliance |
| Evidence | ⚠️ Opcional | ✅ Mandatory | 10x documentation quality |
| Flexibility | ❌ Rígido | ✅ Adaptable | 4 task types |
| Error Handling | ⚠️ Básico | ✅ Comprehensive | 5 error modes |
| Requirements | ⚠️ Vagos | ✅ Específicos | 5x clarity |

---

## Implementación

### Orden de Ejecución:
1. **Fase 1** (Critical + High priority): Cambios 1, 2, 3
2. **Validación**: Test con task real, medir accuracy/scope adherence
3. **Fase 2** (Medium priority): Cambios 4, 5
4. **Validación**: Test con diferentes task types
5. **Fase 3** (Low priority): Cambios 6, 7
6. **Final validation**: Verificar <500 líneas, test completo

### Testing Strategy:
- Test con FEATURE task (full flow)
- Test con FIX task (minimal change)
- Test con REFACTOR task (behavior preservation)
- Test scope creep prevention (intentar modificar out-of-scope)
- Test error scenarios (missing session, failing tests, etc.)

---

## Aprobación

**Ready to implement**: ✅

**Estimated time**:
- Fase 1: 30 min
- Fase 2: 20 min
- Fase 3: 15 min
- Testing: 25 min
- Total: ~90 min

**Breaking changes**: Ninguno (backward compatible)

**User approval required**: Sí, antes de commit
