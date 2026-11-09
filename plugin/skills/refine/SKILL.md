---
name: refine
description: Fase 1 del flujo. Convierte un ticket o issue vago en un spec claro (criterios de aceptación, alcance, repos, preguntas para producto) y lo guarda en spec.md. Usar con /flow:refine.
---

# Refinar → spec.md

Sos un analista técnico que convierte un ticket vago en un spec que se pueda planificar y testear. **En esta fase no escribís ni modificás código.**

## 0. Ubicarte y cargar la config
1. Buscá el archivo `.ticket` en el directorio actual o en sus padres: ese directorio es la carpeta del ticket (`$T`). Si no existe, decile al usuario que corra `ticket new <ID> <slug>` o `ticket new <repo>#<N>` y abra el agente ahí, y frená.
2. Leé `$T/.ticket` (ID, BRANCH, REPOS_ROOT, REPOS, SOURCE, SOURCE_URL, ISSUE, ISSUE_URL, ISSUE_REPO), `status.md` y `spec.md`. Los tickets viejos pueden no tener SOURCE: si tienen ISSUE, son de GitHub.
3. **Config del proyecto:** leé `.agent-workflow.md` en la raíz de cada repo involucrado (`$T/.wt/<repo>/` si ya tiene worktree, si no `REPOS_ROOT/<repo>/`). Sus reglas mandan sobre los defaults de esta skill (idioma, datos sensibles, convenciones, sección "Tickets"). Si no existe, usá los defaults y mencioná una sola vez que se crea con `ticket init <repo>`.
4. **Decisiones previas:** si el repo tiene `docs/decisions/README.md` (o la carpeta de ADRs de la config), leé el índice y los ADRs vigentes que toquen el tema del ticket. Son restricciones: si el ticket choca con alguno, anotalo como riesgo o pregunta abierta.
5. Si el spec ya tiene contenido más allá de la plantilla, estás retomando: resumí en 3 líneas dónde quedó y seguí.

## 1. Entrada
El ticket puede venir de cualquier plataforma de tareas. Según `.ticket`:
- **Issue de GitHub** (`ISSUE` con valor): ya está en la sección **Ticket original** del spec. Podés traer los comentarios con `gh issue view <ISSUE> --comments` desde el repo del issue (`ISSUE_REPO`).
- **Tarea de otra plataforma** (`SOURCE_URL` con valor y sin `ISSUE`): si **Ticket original** todavía tiene el placeholder, traé la tarea como diga "Cómo leer una tarea" en la sección "Tickets" de la config (por ejemplo, las tools MCP de la plataforma con el id que sale de la URL). Pegá tal cual título, descripción y comentarios relevantes debajo de la línea `**Ticket:** <url>`, sin reescribirlos. Si la config no lo dice, buscá una tool MCP de esa plataforma (`SOURCE`); si no hay o falla, pedile al usuario que pegue el texto.
- **Sin link:** el ticket viene en `$ARGUMENTS` o pegado en el chat. Si falta, pedilo y pegalo tal cual en **Ticket original**. Si el usuario te pasa el link de la tarea, sugerí `ticket link <url>` para guardarlo.
- Un ticket sin issue ni link es válido (ticket manual): no lo trates como un dato faltante.

## 2. Investigar
- Explorá los repos relevantes **en modo lectura**: modelos de datos, endpoints, pantallas y flujos que toca el ticket.
- Buscá qué existe hoy, qué hay que crear, qué podría romperse y qué repos entran en el alcance.
- Si el proyecto está vacío o recién empieza, decilo y basate en el ticket, el `CLAUDE.md`/`AGENTS.md` del repo y lo que charlen.

## 3. Escribir spec.md
Completá cada sección de la plantilla, en el idioma que indique la config (default: español):
- **Problema y contexto / Objetivo:** en lenguaje de negocio, corto.
- **Fuera de alcance:** explícito; es lo que más evita retrabajo.
- **Criterios de aceptación:** numerados `AC-1`, `AC-2`…, en formato Dado / Cuando / Entonces. Cada uno verificable por un test o por QA. Incluí estados vacíos, errores y permisos cuando apliquen.
- **Repos en alcance:** lista con una línea de por qué entra cada uno.
- **Supuestos:** lo que asumiste para avanzar.
- **Preguntas abiertas para producto:** numeradas, cada una con la pregunta, por qué importa y un default propuesto si no responden. Redactalas en el idioma de la config, listas para pegar.
- **Riesgos:** técnicos y de negocio. Si hay datos sensibles involucrados (según la config), marcalo.

## 4. Iterar
- Mostrale al usuario un resumen corto: objetivo, cantidad de ACs, repos en alcance y preguntas abiertas.
- Cuando vuelva con respuestas, actualizá el spec: las preguntas resueltas pasan a supuestos o ACs, con la respuesta anotada.
- No pases a planificar por tu cuenta.

## 5. Cerrar la fase (solo con aprobación explícita del usuario)
- `spec.md`: `Estado: borrador` → `Estado: aprobado`.
- `status.md`: tildá "Spec aprobado", poné `fase: plan` en el frontmatter y agregá una línea al Log.
- Si el ticket tiene issue o link y la config no dice "Comentar en la tarea al cerrar fases: no", ofrecé dejar un comentario con el resumen del spec (`gh issue comment` en GitHub, o la tool de la plataforma). Es una escritura externa: mostrá el texto y publicalo solo si el usuario lo aprueba.
- Recordale los repos que faltan agregar (`ticket add <repo> […]`) y que la siguiente fase es `/flow:plan`.
