# Configuración del flujo de agentes

<!--
Este archivo va en la raíz de cada repo (`ticket init <repo>` lo crea). Es local: queda en
.git/info/exclude, nunca se commitea, y cada worktree de un ticket lo ve por symlink.
Todas las skills /flow:* lo leen antes de trabajar y sus reglas mandan sobre los defaults.
Si un ticket abarca varios repos, se aplican las reglas de cada repo a su parte.
Borrá o completá lo que no aplique.
-->

## Tickets
<!--
Plataforma donde viven las tareas. El link de cada ticket se guarda con
`ticket new <ID> <slug> --link <url>` o `ticket link <url>`; los issues de GitHub con `ticket new <repo>#<N>`.
-->
- **Origen:** github   <!-- github | seeble | jira | linear | … | manual -->
- **Cómo leer una tarea:** `gh issue view <N> --comments`
  <!-- Otra plataforma: las tools MCP a usar y de dónde sale el id. Ej. Seeble: mcp__seeble__get_task + mcp__seeble__list_comments con el task_id del final de la URL. Sin tool: "pedir que la peguen". -->
- **Referencia en el PR:** `Closes #<id>`   <!-- Ej. otra plataforma: "Ticket: <link>" -->
- **Comentar en la tarea al cerrar fases:** ofrecer, siempre preguntando antes   <!-- ofrecer | no -->
- **Formato de ID:** #<número de issue>
- **Idioma del spec y de las preguntas para producto:** español

## Git
- **Branch:** feat/<id>-<slug>          <!-- `ticket` toma el prefijo (lo de antes de la "/"); fix/... para bugs -->
- **Commit:** `<tipo>(<scope>): <descripción> (#<id>)`   <!-- conventional commits -->
- **Commits en implement:** stage   <!-- stage: cada tarea queda en staging y /flow:ship commitea con tu aprobación | por-tarea: un commit por tarea -->
- **Rama base:** main

## Pull requests
- **Título:** `<tipo>: <resumen> (#<id>)`
- **Idioma:** español
- **Draft por defecto:** sí
- **Secciones del cuerpo:** Qué cambia · Por qué · Decisiones · Cómo probar · Checklist

## Calidad
- **Tests:** `npm test`
- **Lint / types:** `npm run lint && npm run typecheck`
- **Dev server para revisar la UI:** `npm run dev` → http://localhost:3000

## Delegación (OpenCode)
<!--
Tareas marcadas [delegable] en plan.md las implementa OpenCode; Claude verifica, testea y commitea.
Modelos: ver `opencode models opencode-go`. Cambialos acá cuando compares resultados en el log de status.md.
-->
- **Delegar tareas:** sí
- **Agente:** flow-coder
- **Modelo por defecto:** opencode-go/kimi-k2.7-code
- **Modelo para tareas mecánicas (tests, boilerplate, renombres):** opencode-go/deepseek-v4.1-flash
- **Modelos permitidos:** cualquiera de OpenCode Go menos Muse Spark (entrena con tus datos)
  <!-- Para código de una empresa o de clientes: solo modelos con retención 0 días (sin Grok, GPT ni Haiku vía Go), y solo si la empresa lo permite. -->

## Challenge del plan
- **Challenger:** sí
- **Motor:** opencode   <!-- opencode: otro modelo vía OpenCode | claude: subagente challenger de Claude Code (Opus, contexto fresco) -->
- **Agente:** flow-challenger   <!-- solo motor opencode -->
- **Modelo:** opencode-go/kimi-k3   <!-- solo motor opencode -->   <!-- corre una vez por ticket: puede ser el modelo más capaz aunque tenga poca cuota -->
- **Mínimo de tareas para correrlo:** 4   <!-- planes más chicos lo saltean -->

## Revisión
- **PR reviewer de OpenCode:** sí
- **Agente del reviewer:** flow-reviewer
- **Modelo del reviewer:** opencode-go/glm-5.3-flash
- **Verificación de UI con Playwright:** sí, cuando el ticket toca interfaz

## Decisiones (ADR)
- **Carpeta:** docs/decisions   <!-- índice en docs/decisions/README.md -->
- **Proponer ADRs al hacer ship:** sí

## Datos sensibles
<!-- Qué no puede entrar nunca al contexto de un agente ni a fixtures. -->
- Archivos `.env`, credenciales y claves de APIs.
- Datos reales de usuarios o clientes: solo datos sintéticos en tests y en el navegador.

## Contexto del proyecto
<!-- 3-5 líneas: qué es, stack, dónde está la documentación de arquitectura. -->
