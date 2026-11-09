---
name: help
description: Machete rápido del flujo de tickets (comandos, fases, archivos, config por proyecto, qué hacer si algo falla). Usar con /flow:help [tema] o cuando el usuario pregunta cómo era algún paso del flujo.
---

# Ayuda del flujo

Respondé **corto**, sin leer nada salvo lo indicado.

- **Sin `$ARGUMENTS`:** mostrá el machete de abajo. Si hay un `.ticket` en el directorio actual o sus padres, leé el campo `fase` del frontmatter de `status.md` y agregá al final: "Estás en **<ID>**, fase **<fase>** → próximo paso: `<comando>`".
- **Con una fase o comando** (refine, plan, implement, review, ship, status, new, add, init, done, config…): explicá solo eso en 5-8 líneas: qué hace, qué lee, qué escribe, cuándo termina y el error más común.
- **Con una pregunta libre:** respondela con este machete.

---

## Machete

**Terminal**
| Comando | Qué hace |
|---|---|
| `ticket new growcore#12` | Ticket desde un issue de GitHub: trae el issue al spec y crea el worktree del repo |
| `ticket new CAN-123 slug [--link <url>]` | Ticket manual, opcionalmente vinculado a una tarea de cualquier plataforma (la plataforma sale del dominio o de `--source`) |
| `ticket link <url>` | Vincular el ticket actual a una tarea |
| `cd "$(ticket path 12)"` | Ir al ticket (por número de issue o ID) |
| `ticket add repo1 [repo2]` | Sumar repos: worktree por repo, misma branch, con la config enlazada (repetirlo enlaza una config creada después) |
| `ticket init repo` | Crear `.agent-workflow.md` (config local del flujo, nunca se commitea) en ese repo |
| `ticket ls` | Tickets activos, fase y repos |
| `ticket done` | Sacar worktrees y archivar (exige todo commiteado y pusheado) |

**Dentro de Claude** (abierto en la carpeta del ticket)
| Fase | Comando | Escribe | Checkpoint |
|---|---|---|---|
| 1 | `/flow:refine` | `spec.md` | Aprobás el spec |
| 2 | `/flow:plan [--skip-challenge]` | `plan.md` + `challenge.md` | Aprobás el plan (ya con el challenge respondido) |
| 3 | `/flow:implement [repo]` | código en staging (o commits por tarea) + `decisions.md` | Tareas tildadas, tests ok |
| 4 | `/flow:review` | `review.md` | Aprobás el review |
| 5 | `/flow:ship` | ADRs + `pr-<repo>.md` + commit + PRs | Elegís qué decisiones van a ADR y aprobás los PRs y el commit antes del push |
| * | `/flow:status` | — | Dónde quedé y qué sigue |

**Config por proyecto:** `.agent-workflow.md` en la raíz de cada repo (plataforma de tareas, prefijo de branch, commits, PRs, tests, delegación, revisores, datos sensibles). Es local: está en `.git/info/exclude` y los worktrees la ven por symlink. Si no está, se usan defaults y no se delega.

**Prefijo de branch:** `TICKET_BRANCH_PREFIX` si está definida; si no, el de la línea "Branch:" de la config del primer repo que se agrega al ticket; si no, `feat`.

**Commits:** con "Commits en implement: stage" (default), cada tarea queda en staging y `/flow:ship` propone el commit y lo hace cuando lo aprobás. Con `por-tarea`, un commit por tarea.

**Delegación a OpenCode**
- `/flow:plan` marca tareas `[delegable]` o `[delegable:mecánica]`.
- `/flow:implement` se las pasa a `flow-coder` con el modelo de la config, revisa el diff, corre los tests y recién ahí lo stagea (o commitea, según la config). `/flow:implement --no-delegate` hace todo con Claude.
- Cada delegación queda en el Log de `status.md` (ok / corregida / rehecha): usá eso para elegir modelos.
- Cambiar de modelo: editá la sección "Delegación" de `.agent-workflow.md`. Ver modelos: `opencode models opencode-go`.
- Permisos: `flow-coder` edita y corre tests, pero no commitea, no pushea, no instala nada ni lee `.env`. `flow-reviewer` y `flow-challenger` son solo lectura.

**Challenge del plan:** al terminar `/flow:plan`, un challenger con contexto fresco (`flow-challenger` en OpenCode con otro modelo, o el subagente `challenger` de Claude con Opus si la config dice "Motor: claude") tira hasta 5 objeciones con evidencia. Claude responde cada una en la sección Challenge de `plan.md` (aceptada / rechazada / para decidir) y recién ahí te pide aprobar. Se saltea en planes chicos (mínimo de tareas en la config) o con `--skip-challenge`.

**Memoria del proyecto (ADRs):** las decisiones que sobreviven al ticket van al repo en `docs/decisions/NNNN-titulo.md` (índice en `docs/decisions/README.md`). `/flow:ship` las propone y vos elegís; `/flow:refine` y `/flow:plan` las leen al arrancar; el review avisa si el código contradice una.

**Obsidian:** abrí `TICKETS_ROOT` (default `~/tickets`) como vault. `Tickets.base` muestra el tablero de tickets por fase; los worktrees viven en `.wt/` (oculta) para que Obsidian no indexe código.

**Reglas de oro**
- Sesión nueva entre fases: el contexto vive en los archivos.
- Desvío grande en la implementación → el agente frena y pregunta.
- Nada se pushea sin que apruebes los PRs en `/flow:ship`.
- Review de UI: dev server levantado y URL en `status.md`.

**Si algo falla**
- "no es un repo git" / "no tiene commits" → `git init` y un commit inicial.
- No puede leer el issue → `gh auth login` y que el repo tenga remoto en GitHub. Tarea de otra plataforma → que su MCP esté conectado y que "Cómo leer una tarea" de la config diga qué tool usar; si no, pegá el texto.
- No corre el PR reviewer o la delegación → chequeá `.agent-workflow.md`, `opencode agent list` (tienen que aparecer `flow-coder` y `flow-reviewer`) y que el modelo exista en `opencode models`.
- No aparecen los `/flow:*` → `/reload-plugins` o `claude plugin list`.
- `ticket done` se queja → commiteá y `git push -u origin HEAD` en el repo indicado.
