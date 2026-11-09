---
name: plan
description: Fase 2 del flujo. A partir del spec aprobado, diseña el plan técnico (arquitectura, contratos entre repos, tareas, testing) y lo guarda en plan.md. Usar con /flow:plan.
---

# Planificar → plan.md

Sos el arquitecto del ticket. Tu salida es un plan que otro agente pueda ejecutar tarea por tarea sin adivinar. **En esta fase no escribís código de producción.**

## 0. Ubicarte y cargar la config
1. Buscá `.ticket` en el directorio actual o sus padres → carpeta del ticket `$T`.
2. Leé `.ticket`, `status.md`, `spec.md` y `plan.md`.
3. **Config del proyecto:** leé `.agent-workflow.md` en la raíz de cada worktree (`$T/.wt/<repo>/`). Sus reglas mandan (comandos de test, convenciones, datos sensibles). Si falta, usá defaults.
4. Si el spec no dice `Estado: aprobado`, avisale al usuario y preguntá si quiere seguir igual.
5. Si `plan.md` ya tiene contenido, estás retomando: resumí dónde quedó.

## 1. Investigar el código
- Trabajá sobre los worktrees en `$T/.wt/` (uno por repo de `REPOS`). Si el spec lista repos sin worktree, pedile al usuario que corra `ticket add <repo>`.
- Leé las convenciones de cada repo: `CLAUDE.md`/`AGENTS.md`, estructura, cómo se testea, cómo se hacen migraciones.
- Leé el índice de ADRs (`docs/decisions/README.md` o la carpeta de la config) y los ADRs vigentes relacionados. El plan los respeta. Si hay una buena razón para ir contra uno, decilo explícitamente en Decisiones de arquitectura ("reemplaza ADR NNNN porque…") para que en `/flow:ship` salga el ADR nuevo.

## 2. Discutir antes de escribir
Si hay decisiones con más de una opción razonable (modelo de datos, dónde vive la lógica, sync vs async, librería nueva, infra), presentalas con pros y contras **antes** de cerrarlas. Máximo las 3 más importantes por ronda.

## 3. Escribir plan.md
- **Decisiones de arquitectura:** cada una con alternativas y el porqué.
- **Contratos entre repos:** schemas, endpoints, eventos o tipos compartidos, con la forma concreta. Van primero en el orden de ejecución.
- **Orden de ejecución:** qué repo va primero y por qué.
- **Tareas por repo:** checklist con IDs `T1`, `T2`… Cada tarea chica (revisable en un commit), con el repo, los archivos principales, qué AC cubre y cómo se verifica (test, comando o chequeo manual).
- **Marca `[delegable]`** (solo si la config tiene "Delegar tareas: sí"): ponela al final de la línea de las tareas que puede hacer un modelo más barato sin criterio de arquitectura. Agregá `[delegable:mecánica]` si es repetitiva (tests de algo ya hecho, boilerplate, renombres, tipos).
  - **Sí delegable:** CRUD o endpoint siguiendo un patrón que ya existe en el repo, componente de UI con props definidas, tests de código existente, migración simple ya diseñada, mapeos de datos, scripts.
  - **No delegable:** contratos entre repos, modelo de datos nuevo, lógica de negocio central, seguridad o permisos, integraciones externas nuevas, cualquier cosa que toque datos sensibles, o tareas donde la definición todavía es ambigua.
  - Una tarea delegable tiene que poder describirse sin ambigüedad: archivos, comportamiento esperado y cómo verificarla. Si no, no es delegable.
- **Datos y migraciones / Infra:** solo si aplica, con rollback.
- **Plan de testing:** unitarios, integración y qué ACs se verifican en la UI. Usá los comandos de la config.
- **Riesgos y rollback.**

Todo AC del spec tiene que estar cubierto por al menos una tarea. Si alguno no lo está, decilo.

## 4. Challenge (antes de pedir aprobación)
Correlo cuando el plan esté completo, salvo que: la config diga "Challenger: no", el plan tenga menos tareas que el mínimo de la config (default 4), `$ARGUMENTS` incluya `--skip-challenge`, o el motor sea `opencode` y no esté instalado (en ese caso avisá).

1. Lanzá el challenger según el "Motor" de la config (default `opencode`):
   - **`claude`:** subagente `challenger` (Opus, contexto fresco) con la ruta de `$T` y los repos del ticket. Guardá su respuesta tal cual en `$T/challenge.md`.
   - **`opencode`:** desde el worktree principal (el spec y el plan van adjuntos porque están fuera del repo):
   ```bash
   cd "$T/.wt/<repo principal>" && opencode run --agent <agente, default flow-challenger> -m <modelo de la config> \
     -f "$T/spec.md" -f "$T/plan.md" \
     "Cuestioná este plan según tus instrucciones. Los repos del ticket son: <REPOS>." \
     > "$T/challenge.md" 2>&1
   ```
2. Leé `challenge.md` y respondé **cada** objeción en la sección **Challenge** de `plan.md`:
   - **Aceptada** → ajustá el plan y anotá en una línea qué cambió.
   - **Rechazada** → una línea con el motivo concreto (evidencia, no opinión).
   No aceptes todo por defecto ni rechaces todo por defecto: evaluá cada una con el código y el spec.
3. Si una objeción cambia el alcance o un AC, no la resuelvas vos: marcala "para decidir" y levántasela al usuario.
4. Mostrale al usuario el veredicto, qué aceptaste, qué rechazaste y lo que queda para decidir. Ahí recién pedí la aprobación del plan.

## 5. Cerrar la fase (solo con aprobación explícita del usuario)
- `plan.md`: `Estado: aprobado`.
- `status.md`: tildá "Plan aprobado", `fase: implementación` en el frontmatter y línea en el Log.
- Recordale: `/flow:implement` (opcionalmente con el repo, ej. `/flow:implement backend`).
