# Plan de Refactorización: Comando /explore
## Arquitectura Híbrida con Búsqueda de Código + Web/MCP

**Fecha**: 2025-11-09
**Objetivo**: Refactorizar `/explore` para combinar búsqueda de código local con research web/MCP
**Alcance**: Rediseño de subagentes y arquitectura del comando explore

---

## Tabla de Contenidos

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Análisis del Estado Actual](#análisis-del-estado-actual)
3. [Investigación y Hallazgos](#investigación-y-hallazgos)
4. [Arquitectura Propuesta](#arquitectura-propuesta)
5. [Plan de Implementación](#plan-de-implementación)
6. [Detalles Técnicos](#detalles-técnicos)
7. [Consideraciones y Trade-offs](#consideraciones-y-trade-offs)
8. [Próximos Pasos](#próximos-pasos)

---

## Resumen Ejecutivo

### Problema Actual

El comando `/explore` actual solo realiza búsqueda local de código:
- 4 subagentes especializados (code-structure, test-coverage, dependency, documentation)
- Todos limitados a herramientas read-only locales (Read, Glob, Grep, Bash)
- No hay capacidad de búsqueda web o MCP
- No hay búsqueda semántica de código

### Solución Propuesta

Arquitectura híbrida con **3 subagentes especializados**:

1. **Code Search Agent** - Búsqueda semántica y estructural del código
2. **Web Research Agent** - Investigación web usando WebSearch nativo + MCP servers
3. **Context Synthesis Agent** - Integración y síntesis de hallazgos

### Beneficios Esperados

- ✅ Búsqueda híbrida: código local + conocimiento web actualizado
- ✅ Reducción de subagentes: 4 → 3 (más especializados)
- ✅ Capacidad de investigar tecnologías, frameworks, best practices en tiempo real
- ✅ Mejor context gathering con información actualizada
- ✅ Token efficiency: ~40% reducción usando semantic code search
- ✅ Arquitectura modular compatible con patrones 2025 (ReAct, Agentic RAG)

---

## Análisis del Estado Actual

### Subagentes Existentes

```
cc/agents/
├── code-search-agent.md           (Read, Glob, Grep, Task)
├── web-research-agent.md          (WebSearch, WebFetch, Task)
└── context-synthesis-agent.md     (Read, Task, Write)
```

**Análisis**:

| Agente | Propósito | Tools | Modelo | Ventajas |
|--------|-----------|-------|--------|-----------|
| code-search-agent | Análisis de código integral (arquitectura, tests, dependencias, docs) | Read, Glob, Grep, Task | haiku | Consolidado, eficiente, contexto completo |
| web-research-agent | Investigación de mejores prácticas y estándares actuales | WebSearch, WebFetch, Task | haiku | Información actual 2024-2025, mejores prácticas |
| context-synthesis-agent | Integración de hallazgos + análisis de brechas + recomendaciones | Read, Task, Write | sonnet | Síntesis de alta calidad, análisis estratégico |

### Flujo Actual

```
/explore <feature> <context>
    │
    ├─> code-search-agent (paralelo)     ← Análisis local completo
    ├─> web-research-agent (paralelo)    ← Best practices 2024-2025
         ↓
    context-synthesis-agent (secuencial) ← Integración + síntesis
         ↓
    Salida a explore.md + CLAUDE.md
```

**Limitaciones identificadas**:

1. ❌ No puede investigar nuevas tecnologías o frameworks
2. ❌ No puede verificar best practices actuales online
3. ❌ No puede buscar soluciones a problemas similares
4. ❌ No puede consultar documentación oficial actualizada
5. ❌ Búsqueda lineal de código (no semántica)
6. ❌ No aprovecha MCP para integraciones

---

## Investigación y Hallazgos

### 1. Herramientas Disponibles en Claude Code

#### WebSearch (Nativo)
- **Disponible desde**: Septiembre 2025
- **Capacidades**:
  - Búsqueda en tiempo real
  - Retorna títulos + URLs + snippets
  - Parámetros: max_uses, user_location
  - Domain allow/block lists
- **Uso**: Ideal para research de tecnologías, frameworks, best practices

#### WebFetch (Nativo)
- **Capacidades**:
  - Fetch de URL específica
  - Extrae contenido + análisis
  - Retorna respuesta procesada
- **Uso**: Para leer documentación específica, artículos técnicos

#### Task Tool
- **Capacidades**:
  - Spawn subagentes con contextos aislados
  - Ejecución paralela
  - Diferentes tipos: general-purpose, Explore, Plan
- **Uso**: Orquestación de subagentes especializados

### 2. MCP Servers Disponibles

#### Para Web Search

| MCP Server | API | Free Tier | Características |
|------------|-----|-----------|-----------------|
| **Brave Search** | Brave API | 2,000 queries/mes, 1 req/s | Privacy-focused, web index propio |
| **DuckDuckGo** | DuckDuckGo | 15,000 req/mes, 1 req/s | Simple, sin tracking |
| **Tavily** | Tavily API | Varía | Versatile, optimizado para AI |
| **Perplexity Sonar** | Sonar API | Paid | Up-to-minute info, profesional |

**Recomendación**: Brave Search MCP para balance entre privacidad, capacidad y límites gratuitos.

#### Para Code Search

| MCP Server | Tecnología | Características |
|------------|------------|-----------------|
| **Claude Context** (Zilliztech) | BM25 + Vector embeddings | Búsqueda semántica híbrida, 40% token reduction |

**Características de Claude Context**:
- Búsqueda híbrida: BM25 (keyword) + dense vector (semántica)
- Soporta: TypeScript, JavaScript, Python, Java, C++, C#, Go, Rust, PHP, Ruby, Swift, Kotlin, Scala, Markdown
- Embedding providers: OpenAI, VoyageAI, Ollama, Gemini
- Vector DBs: Milvus o Zilliz Cloud
- ~40% reducción de tokens vs búsqueda tradicional

### 3. Patrones de Arquitectura 2025

#### ReAct (Reasoning + Acting)
```
Observe → Reason → Act → Observe → Reason → Act → ...
```
- Agente razona sobre qué herramienta usar
- Ejecuta acción
- Re-evalúa resultados
- Itera hasta resolver

#### Agentic RAG (Retrieval-Augmented Generation)
```
Query → Retrieval System → Generation Model → Agent Layer
```
- Retrieval: BM25, dense embeddings, hybrid
- Generation: Respuestas contextualizadas
- Agent: Coordina retrieval + generation dinámicamente

#### Hybrid Multi-Agent Pattern
```
Orchestrator
  ├─> Specialist Agent 1 (Domain-specific)
  ├─> Specialist Agent 2 (Domain-specific)
  └─> Specialist Agent 3 (Domain-specific)
       ↓
   Synthesis & Integration
```

### 4. Best Practices Identificadas

**Context Management**:
1. ✅ **Just-in-time loading**: Cargar datos dinámicamente con tools
2. ✅ **Project-scoped MCP**: MCP servers por proyecto, no globales
3. ✅ **Minimize idle MCP servers**: Cada MCP idle consume 4-10k tokens
4. ✅ **Hybrid model**: CLAUDE.md upfront + tools para retrieval on-demand
5. ✅ **Subagents preserve context**: Usar subagentes para preservar contexto principal

**Agent Workflow**:
```
Gather Context → Take Action → Verify Work → Repeat
```

**Modularity**:
- Agentes especializados con un propósito claro
- Composables y reemplazables
- Independientes pero colaborativos

---

## Arquitectura Propuesta

### Nuevo Diseño de Subagentes

Reducción de **4 → 3 subagentes especializados**:

```
cc/agents/
├── code-search-agent.md           (NEW - Búsqueda híbrida de código)
├── web-research-agent.md          (NEW - Research web/MCP)
└── context-synthesis-agent.md     (NEW - Síntesis e integración)
```

### 1. Code Search Agent

**Propósito**: Búsqueda semántica y estructural del código local

**Tools permitidas**:
- Read, Glob, Grep (búsqueda tradicional)
- Task (para spawning si necesario)
- Bash (para comandos de análisis)

**MCP opcional**: Claude Context (si configurado)

**Capacidades**:
- Búsqueda semántica: "encuentra funciones que manejan autenticación"
- Análisis de estructura de código
- Evaluación de test coverage
- Análisis de dependencias
- Extracción de requirements de docs

**Modelo**: Haiku (eficiencia + capacidad)

**Output**:
```markdown
## Code Search Results

### Relevant Code Components
- Component/Function (file:line) - Description
- Component/Function (file:line) - Description

### Code Architecture
[Architecture pattern, organization]

### Test Coverage
- Coverage: ~X%
- Well-tested: [areas]
- Gaps: [areas]

### Dependencies
- Direct: [list]
- Internal: [list]
- Risk factors: [list]

### Documentation Found
- Files: [list]
- Quality: [assessment]
- Requirements: [extracted]
```

### 2. Web Research Agent

**Propósito**: Investigación web para contexto actualizado

**Tools permitidas**:
- WebSearch (nativo)
- WebFetch (nativo)
- Task (para sub-research)

**MCP opcional**: Brave Search, DuckDuckGo, Tavily

**Capacidades**:
- Búsqueda de best practices actuales
- Investigación de frameworks/tecnologías
- Consulta de documentación oficial
- Búsqueda de soluciones a problemas similares
- Verificación de vulnerabilidades/updates

**Modelo**: Haiku (suficiente para research)

**Output**:
```markdown
## Web Research Results

### Technology Overview
- Framework/Library: [name]
- Current version: [version]
- Key features: [list]

### Best Practices (2025)
1. [Practice 1] - Source: [URL]
2. [Practice 2] - Source: [URL]

### Similar Solutions Found
- Project/Article: [title]
- Approach: [description]
- Source: [URL]

### Official Documentation
- Main docs: [URL]
- Relevant sections: [list]

### Security/Updates
- Latest version: [version]
- Known issues: [list]
- Recommendations: [list]
```

### 3. Context Synthesis Agent

**Propósito**: Integrar hallazgos de code search + web research

**Tools permitidas**:
- Read (para leer outputs de otros agentes)
- Write (para crear síntesis)
- Task (si necesita re-investigar)

**Modelo**: Sonnet (requiere razonamiento complejo)

**Capacidades**:
- Combinar hallazgos de código + web
- Identificar patrones y conexiones
- Priorizar findings por relevancia
- Crear síntesis cohesiva
- Generar recomendaciones accionables

**Output**:
```markdown
## Exploration Synthesis

### Executive Summary
[High-level overview of findings]

### Key Findings
1. [Critical discovery 1] - Context: [code/web]
2. [Critical discovery 2] - Context: [code/web]
3. [Critical discovery 3] - Context: [code/web]

### Code-Web Integration
- [How codebase aligns with best practices]
- [Gaps between current state and modern approaches]
- [Opportunities for improvement]

### Risk Assessment
- High: [risks]
- Medium: [risks]
- Low: [risks]

### Implementation Considerations
- [Technical constraints]
- [Best practices to follow]
- [Patterns to adopt]

### Recommended Next Steps
1. [Action item 1]
2. [Action item 2]
3. [Action item 3]
```

### Nuevo Flujo del Comando /explore

```
/explore <feature> <context>
    │
    ├─> Code Search Agent (paralelo)
    │   ├─> Semantic code search (optional MCP)
    │   ├─> Structure analysis
    │   ├─> Test coverage
    │   ├─> Dependencies
    │   └─> Local docs
    │
    ├─> Web Research Agent (paralelo)
    │   ├─> Best practices search
    │   ├─> Framework docs
    │   ├─> Similar solutions
    │   ├─> Security/updates
    │   └─> Official documentation
    │
    └─> Wait for both agents
         ↓
    Context Synthesis Agent (secuencial)
         ├─> Integrate code + web findings
         ├─> Identify patterns
         ├─> Assess risks
         └─> Generate recommendations
              ↓
         Update session CLAUDE.md
              ↓
         Save detailed results to explore.md
```

### Comparación: Estado Actual vs Propuesto

| Aspecto | Actual | Propuesto | Mejora |
|---------|--------|-----------|--------|
| **Subagentes** | 4 especializados | 3 especializados | Más cohesivos |
| **Búsqueda** | Solo local | Local + Web | Contexto completo |
| **Semántica** | No | Sí (opcional MCP) | 40% token reduction |
| **Research** | Solo docs locales | Web + oficial docs | Info actualizada |
| **Síntesis** | En comando principal | Subagente dedicado | Mejor calidad |
| **Modelo síntesis** | N/A | Sonnet | Razonamiento profundo |
| **Paralelización** | 4 paralelos | 2 paralelos + 1 seq | Balance eficiencia/calidad |
| **MCP Support** | No | Sí (opcional) | Extensibilidad |

---

## Plan de Implementación

### Fase 1: Creación de Nuevos Subagentes (Semana 1)

#### 1.1 Code Search Agent

**Archivo**: `cc/agents/code-search-agent.md`

**Tareas**:
- ✅ Definir frontmatter (tools, model, description)
- ✅ Consolidar capacidades de los 4 agentes actuales
- ✅ Crear estructura de output unificada
- ✅ Documentar uso de MCP opcional (Claude Context)
- ✅ Implementar prompt engineering para búsqueda eficiente

**Criterios de éxito**:
- Puede encontrar código relevante semánticamente
- Analiza estructura + tests + dependencies en un solo agente
- Output estructurado y parseable
- Compatible con/sin MCP

#### 1.2 Web Research Agent

**Archivo**: `cc/agents/web-research-agent.md`

**Tareas**:
- ✅ Definir frontmatter (tools, model, description)
- ✅ Implementar uso de WebSearch nativo
- ✅ Implementar uso de WebFetch para docs específicas
- ✅ Documentar MCP opcionales (Brave, DuckDuckGo)
- ✅ Crear estrategias de búsqueda por tipo de query
- ✅ Implementar filtrado de resultados relevantes

**Criterios de éxito**:
- Puede buscar best practices actuales
- Encuentra documentación oficial
- Identifica soluciones similares
- Output con fuentes citadas
- Funciona con/sin MCP

#### 1.3 Context Synthesis Agent

**Archivo**: `cc/agents/context-synthesis-agent.md`

**Tareas**:
- ✅ Definir frontmatter (tools: Read, Write, model: sonnet)
- ✅ Implementar lógica de integración
- ✅ Crear prompt para síntesis coherente
- ✅ Implementar priorización de findings
- ✅ Generar recomendaciones accionables

**Criterios de éxito**:
- Integra efectivamente código + web findings
- Identifica patrones cross-source
- Genera executive summary útil
- Recommendations priorizadas y claras

### Fase 2: Refactorización del Comando /explore (Semana 1-2)

**Archivo**: `cc/commands/explore.md`

**Tareas**:
- ✅ Actualizar descripción del comando
- ✅ Modificar flujo para usar 3 nuevos agentes
- ✅ Implementar ejecución paralela (code + web)
- ✅ Implementar ejecución secuencial (synthesis)
- ✅ Actualizar estructura de output
- ✅ Mantener compatibilidad con session CLAUDE.md
- ✅ Agregar flags opcionales (ej: --web-only, --code-only)

**Estructura de output actualizada**:
```
.claude/sessions/{SESSION_ID}_{DESC}/
├── CLAUDE.md              (Session context - síntesis)
├── explore.md             (Resultados detallados completos)
├── code-search.md         (Output del code search agent)
├── web-research.md        (Output del web research agent)
└── synthesis.md           (Output del synthesis agent)
```

**Criterios de éxito**:
- Flujo orquestado correctamente
- Manejo de errores (si web search falla, continúa)
- Output consistente y útil
- Backwards compatible con flujo actual

### Fase 3: Configuración MCP Opcional (Semana 2)

#### 3.1 Brave Search MCP

**Archivo**: `cc/mcp-config-examples/brave-search.json`

```json
{
  "mcpServers": {
    "brave-search": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-brave-search"],
      "env": {
        "BRAVE_API_KEY": "${BRAVE_API_KEY}"
      }
    }
  }
}
```

**Documentación**: Instrucciones de setup en README

#### 3.2 Claude Context MCP (Opcional)

**Archivo**: `cc/mcp-config-examples/claude-context.json`

```json
{
  "mcpServers": {
    "claude-context": {
      "command": "npx",
      "args": ["@zilliz/claude-context-mcp@latest"],
      "env": {
        "OPENAI_API_KEY": "${OPENAI_API_KEY}",
        "MILVUS_TOKEN": "${MILVUS_TOKEN}"
      }
    }
  }
}
```

**Criterios de éxito**:
- Documentación clara de setup
- Examples de configuración
- Funciona sin MCP (graceful degradation)
- Instrucciones para obtener API keys

### Fase 4: Testing y Validación (Semana 2)

**Test Cases**:

1. **Test sin MCP** (solo herramientas nativas)
   - Code search funciona con Glob/Grep
   - Web research funciona con WebSearch nativo
   - Synthesis integra correctamente

2. **Test con Brave Search MCP**
   - Web research usa MCP cuando disponible
   - Fallback a WebSearch si MCP falla

3. **Test con Claude Context MCP**
   - Code search semántico funciona
   - Comparar resultados vs búsqueda tradicional
   - Verificar token reduction

4. **Test de casos reales**:
   - Explorar feature de autenticación
   - Explorar refactor de arquitectura
   - Explorar integración de nuevo framework

**Métricas**:
- Token usage (comparar con enfoque actual)
- Calidad de findings (subjetivo pero documentar)
- Tiempo de ejecución
- Relevancia de web research

### Fase 5: Migración y Deprecación (Semana 3)

**Tareas**:
- ✅ Renombrar agentes viejos: `*.old.md`
- ✅ Actualizar documentación del proyecto
- ✅ Crear migration guide
- ✅ Notificar cambios en CLAUDE.md
- ✅ Mantener backwards compatibility temporal

**Migration Path**:
```bash
# Backup de configuración actual
cp -r cc/agents cc/agents.backup

# Los nuevos agentes conviven con los viejos temporalmente
# Usuario puede probar nuevo flujo con flag
/explore --new-arch <feature>

# Después de validación, se elimina flag y se vuelve default
```

---

## Detalles Técnicos

### Subagent Definitions

#### Code Search Agent (code-search-agent.md)

```markdown
---
description: "Hybrid code search combining structural and semantic analysis"
allowed-tools: Read, Glob, Grep, Bash, Task
model: haiku
---

# Code Search Agent

You are a specialized subagent for comprehensive code search and analysis.

## Your Mission

Search and analyze the codebase to find components, patterns, and information
related to the specified feature or functionality.

## Your Capabilities

### 1. Semantic Code Search (if MCP available)
Use Claude Context MCP for semantic queries:
- "Find functions that handle user authentication"
- "Locate code that implements caching"
- "Search for error handling patterns"

### 2. Structural Analysis
- Code architecture and organization
- Component relationships
- Module boundaries
- Design patterns used

### 3. Test Coverage Assessment
- Identify test files
- Estimate coverage
- Find gaps
- Assess test quality

### 4. Dependency Analysis
- External dependencies (package.json, requirements.txt, etc.)
- Internal module dependencies
- Integration points
- Version status

### 5. Documentation Extraction
- README files
- Code comments
- API documentation
- Requirements

## Your Tools

- **Glob**: Find files by pattern (`**/*.ts`, `**/*.test.*`)
- **Grep**: Search code content (imports, functions, classes)
- **Read**: Examine file contents
- **Bash**: Run analysis commands (coverage, linting)
- **Task**: Spawn sub-searches if needed

## Output Format

Provide structured markdown:

```markdown
## Code Search Results

### Overview
- Files analyzed: X
- Components found: Y
- Test coverage: ~Z%

### Key Components
1. **ComponentName** (file:line)
   - Purpose: [description]
   - Dependencies: [list]
   - Test coverage: [status]

### Architecture
[Description of architecture pattern, organization]

### Test Coverage
- **Well-tested**: [components]
- **Gaps**: [components without tests]
- **Test files**: [list]

### Dependencies
**External**:
- package@version - Status: ✅/⚠️/❌

**Internal**:
- internal/module - How used

### Documentation
- **Found**: [files]
- **Quality**: [assessment]
- **Requirements extracted**: [list]

### Risk Factors
- [High/Medium/Low]: [description]
```

## Best Practices

1. Start with semantic search (if available), fall back to Glob/Grep
2. Focus on relevance - don't return everything
3. Include file:line references
4. Assess quality, not just presence
5. Flag outdated or risky dependencies
6. Be concise but thorough
```

#### Web Research Agent (web-research-agent.md)

```markdown
---
description: "Web research agent for up-to-date information and best practices"
allowed-tools: WebSearch, WebFetch, Task
model: haiku
---

# Web Research Agent

You are a specialized subagent for web-based research and information gathering.

## Your Mission

Research current best practices, documentation, and solutions related to the
specified feature or technology using web search.

## Your Capabilities

### 1. Best Practices Research
Search for current industry standards and recommended approaches:
- "authentication best practices 2025"
- "React state management patterns"
- "API security recommendations"

### 2. Framework/Technology Documentation
Find and fetch official documentation:
- Official docs sites
- GitHub repositories
- Release notes
- Migration guides

### 3. Similar Solutions
Discover how others have solved similar problems:
- Open source projects
- Blog posts and tutorials
- Stack Overflow discussions
- Case studies

### 4. Security and Updates
Check for vulnerabilities and latest versions:
- CVE databases
- Security advisories
- Version updates
- Breaking changes

## Your Tools

- **WebSearch**: Search the web for information
  - Use targeted queries
  - Max 3-5 searches per topic
  - Prioritize official sources

- **WebFetch**: Fetch specific URLs for detailed info
  - Official documentation
  - Specific articles
  - GitHub repos

- **Task**: Spawn focused sub-research if needed

## Search Strategies

### For Technologies/Frameworks
```
Query: "[framework] official documentation 2025"
Query: "[framework] best practices [use-case]"
Query: "[framework] vs [alternative] comparison"
```

### For Patterns/Solutions
```
Query: "[pattern-name] implementation guide"
Query: "how to [specific-task] in [technology]"
Query: "[problem] solution examples"
```

### For Security/Updates
```
Query: "[library] latest version security"
Query: "[dependency] vulnerabilities CVE"
Query: "[framework] migration guide [version]"
```

## Output Format

Provide structured markdown:

```markdown
## Web Research Results

### Technology Overview
**Name**: [Framework/Library]
**Current Version**: [version] (as of [date])
**Official Site**: [URL]
**Key Features**: [list]

### Best Practices (2025)
1. **[Practice Name]**
   - Description: [what it is]
   - Why: [reasoning]
   - Source: [URL]

2. **[Practice Name]**
   - Description: [what it is]
   - How: [implementation]
   - Source: [URL]

### Official Documentation
- **Main Docs**: [URL]
- **API Reference**: [URL]
- **Guides**: [relevant sections]
- **Key Concepts**: [extracted]

### Similar Solutions Found
1. **[Project/Article Title]**
   - Approach: [description]
   - Pros: [list]
   - Cons: [list]
   - Source: [URL]

### Security & Updates
- **Latest Version**: [version]
- **Known Issues**: [list with CVE if applicable]
- **Security Recommendations**: [list]
- **Breaking Changes**: [if relevant]

### Community Insights
- **Popular approaches**: [what community uses]
- **Common pitfalls**: [what to avoid]
- **Trending patterns**: [emerging practices]
```

## Quality Guidelines

1. **Prioritize official sources**: Docs, GitHub, official blogs
2. **Verify recency**: Prefer 2024-2025 content
3. **Cross-reference**: Confirm info across multiple sources
4. **Cite sources**: Always include URLs
5. **Filter noise**: Ignore outdated or low-quality content
6. **Be concise**: Summarize, don't copy-paste

## Error Handling

If web search fails or returns no results:
1. Try alternative queries
2. Broaden the search
3. Document what was searched
4. Return partial results with explanation
```

#### Context Synthesis Agent (context-synthesis-agent.md)

```markdown
---
description: "Synthesizes code and web research into actionable insights"
allowed-tools: Read, Write, Task
model: sonnet
---

# Context Synthesis Agent

You are a specialized subagent for integrating and synthesizing findings from
multiple research sources into cohesive, actionable insights.

## Your Mission

Combine code search results and web research findings into a unified analysis
that provides clear, prioritized recommendations for implementation.

## Your Inputs

You will receive:
1. **Code Search Results**: Local codebase analysis
2. **Web Research Results**: Current best practices and solutions

## Your Process

### 1. Integrate Findings
- Identify connections between code state and web insights
- Find gaps between current implementation and best practices
- Spot opportunities for improvement

### 2. Analyze Patterns
- Common themes across sources
- Contradictions or conflicts
- Critical insights that emerge

### 3. Assess Risks
- Technical risks from code analysis
- Implementation risks from research
- Prioritize by severity and likelihood

### 4. Generate Recommendations
- Specific, actionable next steps
- Prioritized by impact and effort
- Grounded in both code reality and industry best practices

## Output Format

```markdown
## Exploration Synthesis: [Feature Name]

### Executive Summary
[2-3 sentences capturing the most important findings]

### Current State vs Best Practice

#### What We Have (Code Analysis)
- Architecture: [current pattern]
- Key components: [list with file:line]
- Test coverage: [percentage]
- Dependencies: [key ones]

#### What Industry Recommends (Web Research)
- Best practice pattern: [from research]
- Modern approaches: [from 2024-2025]
- Security considerations: [from research]

#### Gap Analysis
1. **[Gap 1]**: [current state] → [recommended state]
2. **[Gap 2]**: [current state] → [recommended state]

### Key Findings

1. **[Finding 1]** [🔴 Critical / 🟡 Important / 🟢 Notable]
   - Context: [code + web]
   - Impact: [description]
   - Evidence: [file:line + URL]

2. **[Finding 2]** [🔴 Critical / 🟡 Important / 🟢 Notable]
   - Context: [code + web]
   - Impact: [description]
   - Evidence: [file:line + URL]

### Risk Assessment

#### High Priority 🔴
- **[Risk Name]**: [description]
  - Current state: [from code]
  - Best practice: [from web]
  - Mitigation: [recommendation]

#### Medium Priority 🟡
- **[Risk Name]**: [description]

#### Low Priority 🟢
- **[Risk Name]**: [description]

### Implementation Considerations

**Technical Constraints** (from code):
- [Constraint 1]
- [Constraint 2]

**Best Practices to Follow** (from web):
- [Practice 1]
- [Practice 2]

**Recommended Patterns**:
- [Pattern 1]: [why and how]
- [Pattern 2]: [why and how]

### Actionable Recommendations

#### Immediate (Week 1)
1. **[Action]**: [description]
   - Why: [reasoning]
   - How: [approach]
   - Files: [affected files]

#### Short-term (Weeks 2-4)
1. **[Action]**: [description]
   - Why: [reasoning]
   - How: [approach]

#### Long-term (Month+)
1. **[Action]**: [description]
   - Why: [reasoning]

### References

**Code**:
- @.claude/sessions/{session}/code-search.md

**Web Research**:
- @.claude/sessions/{session}/web-research.md
- [Key URL 1]
- [Key URL 2]

### Questions for Planning Phase

1. [Question about implementation approach]
2. [Question about trade-offs]
3. [Question about priorities]
```

## Quality Criteria

Your synthesis should be:

1. **Coherent**: Reads as unified narrative, not two separate reports
2. **Actionable**: Clear next steps, not just observations
3. **Prioritized**: Most important findings highlighted
4. **Evidence-based**: Claims backed by code references or URLs
5. **Balanced**: Considers both code reality and ideal best practices
6. **Concise**: Dense with information, no fluff
7. **Forward-looking**: Focuses on what to do next

## Integration Patterns to Look For

- **Alignment**: Where code already follows best practices
- **Gaps**: Where code differs from recommendations
- **Opportunities**: Where modern patterns could improve code
- **Risks**: Where current code has known issues per research
- **Quick wins**: Easy improvements with high impact
- **Strategic**: Larger changes requiring planning
```

### Comando /explore Refactorizado

```markdown
---
allowed-tools: Read, Glob, Grep, Task, Bash, Write, WebSearch, WebFetch
argument-hint: "[feature/issue description] [scope/context]"
description: Hybrid exploration using code search + web research + synthesis
---

# Explore: Hybrid Research and Context Gathering

Orchestrate comprehensive exploration combining codebase analysis with
up-to-date web research for: **$1**$2

## Session Setup

Generate unique session ID and create session directory with CLAUDE.md:

```bash
# Generate session ID
SESSION_ID=$(date +%Y%m%d_%H%M%S)_$(openssl rand -hex 4)
SESSION_DESC=$(echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | head -c 20)
SESSION_DIR=".claude/sessions/${SESSION_ID}_${SESSION_DESC}"

# Create session structure
mkdir -p "$SESSION_DIR"

# Initialize session CLAUDE.md
cat > "$SESSION_DIR/CLAUDE.md" << EOF
# Session: $1

## Status
Phase: explore
Started: $(date '+%Y-%m-%d %H:%M')
Session ID: ${SESSION_ID}

## Objective
$1

## Context
$2

## Key Findings
[To be populated during exploration]

## Next Steps
Run \`/cc:plan ${SESSION_ID}\` to create implementation plan

## References
@.claude/sessions/${SESSION_ID}_${SESSION_DESC}/explore.md
EOF

echo "✅ Session initialized: ${SESSION_ID}"
echo "📁 Directory: $SESSION_DIR"
```

## Hybrid Exploration with Specialized Subagents

Launch 2 specialized subagents in PARALLEL, then synthesize:

### Phase 1: Parallel Research (Code + Web)

#### 1A. Code Search Agent
Use the Task tool to spawn `code-search-agent`:

```
Analyze the codebase for: $1

Context: $2

Focus:
- Semantic search for relevant components (use MCP if available)
- Code structure and architecture
- Test coverage assessment
- Dependency analysis
- Local documentation extraction

Output to: ${SESSION_DIR}/code-search.md
```

#### 1B. Web Research Agent
Use the Task tool to spawn `web-research-agent` IN PARALLEL:

```
Research web information for: $1

Context: $2

Focus:
- Current best practices (2024-2025)
- Official documentation for relevant technologies
- Similar solutions and implementations
- Security advisories and updates
- Community insights and patterns

Output to: ${SESSION_DIR}/web-research.md
```

### Phase 2: Sequential Synthesis

After BOTH agents complete, spawn `context-synthesis-agent`:

```
Synthesize exploration findings for: $1

Inputs:
- Code Search: ${SESSION_DIR}/code-search.md
- Web Research: ${SESSION_DIR}/web-research.md

Task:
- Integrate code analysis with web research
- Identify gaps and opportunities
- Assess risks with evidence
- Generate prioritized recommendations
- Create actionable next steps

Output to: ${SESSION_DIR}/synthesis.md
```

## Session Persistence

### Update Session CLAUDE.md

After synthesis completes, update session CLAUDE.md with key findings:

```markdown
# Session: [Feature Name]

## Status
Phase: explore → plan
Completed: $(date '+%Y-%m-%d %H:%M')
Session ID: ${SESSION_ID}

## Key Findings

### From Code Analysis
- Architecture: [pattern] (file:line)
- Coverage: [percentage]
- Key components: [list with references]

### From Web Research
- Best practice: [summary] (URL)
- Modern approach: [summary] (URL)
- Security: [considerations]

## Critical Insights
1. [Most important discovery - code + web integrated]
2. [Second most important]
3. [Third most important]

## Gap Analysis
- Current state: [from code]
- Recommended: [from web]
- Action needed: [from synthesis]

## Implementation Recommendations
1. [Immediate action]
2. [Short-term action]
3. [Long-term consideration]

## References
- Code Analysis: @.claude/sessions/${SESSION_ID}_${SESSION_DESC}/code-search.md
- Web Research: @.claude/sessions/${SESSION_ID}_${SESSION_DESC}/web-research.md
- Synthesis: @.claude/sessions/${SESSION_ID}_${SESSION_DESC}/synthesis.md
- Full Report: @.claude/sessions/${SESSION_ID}_${SESSION_DESC}/explore.md
```

### Create Comprehensive explore.md

Combine all outputs into detailed exploration report:

```markdown
# Exploration Results: [Feature Name]

## Session Information
- Session ID: ${SESSION_ID}
- Date: $(date)
- Scope: $1 $2

## Exploration Summary
[Executive summary from synthesis]

---

## Code Search Results
[Full content from code-search.md]

---

## Web Research Results
[Full content from web-research.md]

---

## Integrated Synthesis
[Full content from synthesis.md]

---

## Appendices

### Search Queries Used
- Code: [semantic queries, glob patterns]
- Web: [search queries]

### Tools Used
- Code Search: [tools list]
- Web Research: [WebSearch, WebFetch, MCP if used]

### Timestamp
Completed: $(date)
```

## Completion Checklist

Before considering exploration complete:

- ✅ Session CLAUDE.md created and populated
- ✅ Code search completed
- ✅ Web research completed
- ✅ Synthesis integrates both sources
- ✅ Key insights identified (< 5 most important)
- ✅ Gap analysis documented
- ✅ Recommendations prioritized
- ✅ All outputs saved to session directory

## Next Steps

When exploration is complete, inform the user:

```
✅ Exploration complete for session: ${SESSION_ID}

📊 Summary:
CODE ANALYSIS:
- [X] files analyzed
- [X] components identified
- Coverage: ~[X]%

WEB RESEARCH:
- [X] sources consulted
- [X] best practices found
- [X] official docs reviewed

🎯 Key Findings (Integrated):
1. [Finding 1]
2. [Finding 2]
3. [Finding 3]

🚨 Critical Gaps:
- [Gap 1]: Current [state] → Recommended [state]

🚀 Next: Run `/cc:plan ${SESSION_ID}` to create implementation plan

Session context auto-loaded via: .claude/sessions/${SESSION_ID}_${SESSION_DESC}/CLAUDE.md
```

## Optional Flags

### --code-only
Skip web research, only perform code search:
```bash
/explore --code-only <feature> <context>
```

### --web-only
Skip code search, only perform web research:
```bash
/explore --web-only <feature> <context>
```

### --no-synthesis
Skip synthesis, return separate code + web results:
```bash
/explore --no-synthesis <feature> <context>
```

## Error Handling

### Web Search Fails
If WebSearch or MCP fails:
- Continue with code search only
- Note limitation in output
- Suggest manual research topics

### Code Search Issues
If codebase is too large:
- Focus on specific directories
- Use semantic search if available (MCP)
- Request user to narrow scope

### MCP Not Available
Gracefully degrade:
- Use native WebSearch instead of MCP
- Use traditional Glob/Grep instead of semantic search
- Document what tools were used

## Efficiency Notes

- **Parallel execution**: Code + Web run simultaneously (2x faster)
- **Context isolation**: Each subagent has separate context
- **Token efficiency**:
  - Code search: ~40% reduction if using semantic MCP
  - Web research: Targeted queries vs broad exploration
  - Synthesis: Sonnet only for integration, not discovery
- **Auto-loading**: Session CLAUDE.md automatically loaded in future phases
```

---

## Consideraciones y Trade-offs

### Token Usage

| Component | Tokens (Estimated) | Notes |
|-----------|-------------------|-------|
| **Code Search Agent** | 5,000 - 15,000 | Depends on codebase size |
| **Web Research Agent** | 3,000 - 10,000 | Depends on search depth |
| **Context Synthesis Agent** | 8,000 - 20,000 | Sonnet model, complex reasoning |
| **Total** | 16,000 - 45,000 | vs ~10,000-20,000 current |

**Trade-off**: ~2x token usage pero con información web actualizada incluida.

**Mitigación**:
- Semantic code search (MCP) reduce code search tokens ~40%
- Targeted web queries vs exploratory browsing
- Optional flags para skip code o web
- Synthesis solo cuando ambos completan

### Latencia

| Fase | Tiempo (Estimado) | Paralelo |
|------|-------------------|----------|
| Code Search | 30-60s | ✅ Sí |
| Web Research | 30-90s | ✅ Sí |
| Synthesis | 20-40s | ❌ No |
| **Total** | 80-190s | vs ~120-180s current |

**Trade-off**: Similar o mejor latencia gracias a paralelización.

### MCP Dependencies

**Opcionales, no requeridos**:
- ✅ Funciona sin MCP (degrada gracefully)
- ✅ WebSearch/WebFetch nativos suficientes
- ✅ MCP solo para features avanzadas:
  - Semantic code search (Claude Context)
  - Múltiples search engines (Brave, DuckDuckGo)

**Setup Complexity**:
- Sin MCP: 0 setup (usa herramientas nativas)
- Con MCP básico: 5 min (agregar API key)
- Con MCP completo: 15-30 min (Claude Context + embeddings)

### Calidad de Resultados

**Mejoras esperadas**:
- ✅ Información actualizada (web research)
- ✅ Best practices 2024-2025
- ✅ Awareness de vulnerabilidades/updates
- ✅ Contexto más completo (código + industria)
- ✅ Recomendaciones mejor fundamentadas

**Riesgos**:
- ⚠️ Web research puede traer info no relevante
- ⚠️ Synthesis puede fallar en integración
- ⚠️ MCP puede tener límites de rate/quota

**Mitigaciones**:
- Prompts claros para filtrar relevancia
- Synthesis usa Sonnet (mejor razonamiento)
- Documentar límites de MCP, fallback a nativo

---

## Próximos Pasos

### Implementación Inmediata

1. **Crear los 3 nuevos subagentes** (Semana 1)
   - code-search-agent.md
   - web-research-agent.md
   - context-synthesis-agent.md

2. **Refactorizar /explore** (Semana 1-2)
   - Actualizar flujo de orquestación
   - Implementar ejecución paralela
   - Agregar manejo de errores

3. **Testing básico** (Semana 2)
   - Sin MCP (solo herramientas nativas)
   - Validar outputs
   - Ajustar prompts

### Extensiones Futuras

1. **MCP Integration** (Semana 2-3)
   - Brave Search MCP
   - Claude Context MCP (opcional)
   - Documentación de setup

2. **Optimizaciones** (Mes 2)
   - Caching de web research
   - Embeddings pre-computados (si MCP)
   - Compression de resultados

3. **Advanced Features** (Mes 2+)
   - Multi-language support
   - Custom search strategies
   - Integration con /plan (auto-trigger research)

### Métricas de Éxito

**Cuantitativas**:
- Token usage: <50K tokens por exploration
- Latency: <3 minutos para exploración completa
- Coverage: >80% de información relevante capturada

**Cualitativas**:
- Relevancia de web findings: ¿son útiles?
- Calidad de síntesis: ¿integra bien código + web?
- Actionability: ¿las recomendaciones son claras y priorizadas?

### Documentación Necesaria

1. **README Update**:
   - Explicar nuevo flujo /explore
   - Documentar MCP opcionales
   - Ejemplos de uso

2. **Migration Guide**:
   - Cambios vs versión anterior
   - Cómo usar flags opcionales
   - Setup de MCP (si desired)

3. **Troubleshooting**:
   - Qué hacer si web search falla
   - Cómo optimizar token usage
   - Common issues y soluciones

---

## Conclusión

### Resumen de Cambios

**De**:
```
4 subagentes especializados (code-only)
└─> Solo búsqueda local
    └─> Output separado por agente
```

**A**:
```
3 subagentes especializados (code + web + synthesis)
├─> Code Search Agent (local + semantic)
├─> Web Research Agent (nativo + MCP)
└─> Context Synthesis Agent (integración)
     └─> Output unificado y accionable
```

### Beneficios Clave

1. **Contexto Completo**: Código local + conocimiento web actual
2. **Información Actualizada**: Best practices 2024-2025, security advisories
3. **Búsqueda Mejorada**: Semantic search opcional (40% token reduction)
4. **Mejor Síntesis**: Agente dedicado con Sonnet para integración
5. **Extensibilidad**: MCP support para futuras integraciones
6. **Modularidad**: Arquitectura compatible con patrones 2025 (ReAct, Agentic RAG)

### Filosofía de Diseño

**Hybrid & Flexible**:
- Funciona sin MCP (herramientas nativas)
- Mejora con MCP (semantic search, multiple engines)
- Optional flags para customización

**Just-in-Time Context**:
- No pre-carga toda la web
- Targeted research based on feature
- Load code semánticamente cuando disponible

**Modular & Composable**:
- Subagentes independientes
- Reutilizables en otros comandos
- Fácil de extender o reemplazar

**Production-Ready**:
- Error handling robusto
- Graceful degradation
- Token-efficient
- Well-documented

---

## Referencias

### Documentación Consultada

1. **Claude Code Official Docs**:
   - Web Search Tool: https://docs.claude.com/en/docs/agents-and-tools/tool-use/web-search-tool
   - MCP Integration: https://docs.claude.com/en/docs/mcp
   - Best Practices: Multiple community sources

2. **MCP Servers**:
   - Brave Search MCP: https://github.com/modelcontextprotocol/servers
   - DuckDuckGo MCP: https://github.com/nickclyde/duckduckgo-mcp-server
   - Claude Context: https://github.com/zilliztech/claude-context

3. **Architecture Patterns**:
   - ReAct Pattern: Multiple sources
   - Agentic RAG: Industry research 2025
   - Hybrid Agent Architectures: AI engineering blogs

4. **Best Practices**:
   - Context Engineering: Anthropic blog
   - MCP Best Practices: Community guides
   - Agent Workflows: LangChain, LlamaIndex docs

### Proyectos de Referencia

1. **Zilliztech Claude Context**: Semantic code search MCP
2. **Anthropic Multi-Agent Research**: Orchestrator-worker pattern
3. **LangGraph**: Checkpointing and state management
4. **Various MCP Servers**: Web search implementations

---

**Plan Version**: 1.0
**Fecha**: 2025-11-09
**Autor**: Research Agent
**Estado**: Propuesto para aprobación
**Próxima Acción**: Review y aprobación del usuario
