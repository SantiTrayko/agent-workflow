# Guía del flujo de tickets con agentes

Guía completa de `agent-workflow`. El [README](../README.md) es la referencia corta; esta guía explica cómo se usa el flujo de punta a punta. También hay una versión en PDF, con diagrama: [guia.pdf](guia.pdf).

## 1. Qué es

Un flujo por fases para trabajar tickets con agentes: **refine → plan → implement → review → ship**. Cada fase deja un archivo en la carpeta del ticket y la siguiente lo lee, así que no hay copy-paste entre chats y se puede retomar en una sesión nueva sin perder contexto.

Tiene dos piezas:

- **`ticket`** (terminal): crea la carpeta del ticket, un git worktree por repo y la branch.
- **Plugin `flow`** (Claude Code): las fases como comandos (`/flow:refine`, `/flow:plan`, `/flow:implement`, `/flow:review`, `/flow:ship`, `/flow:status`, `/flow:help`) y los subagentes que las ayudan.

Funciona con cualquier proyecto: lo específico de cada repo (formato de commits, tests, datos sensibles, plataforma de tareas) vive en un `.agent-workflow.md` local por repo.

## 2. Instalación

Requisitos: Claude Code, `git` y `gh` (con `gh auth login`). Opcionales: `opencode` con OpenCode Go (delegación, challenger y reviewer) y Obsidian.

```bash
git clone https://github.com/<usuario>/agent-workflow ~/projects/agent-workflow
cd ~/projects/agent-workflow
bash install.sh
```

Conviene clonarlo fuera de `Desktop` y `Documents`: macOS bloquea esas carpetas a algunas apps. `install.sh` se puede correr de nuevo sin problema. Hace esto:

1. Quita los enlaces viejos (`ticket-*`) si existían.
2. Enlaza el comando `ticket` en `~/.local/bin` (si no está en tu `PATH`, te dice qué agregar a `~/.zshrc`).
3. Registra la carpeta como marketplace local e instala el plugin `flow`.
4. Enlaza los agentes de OpenCode (`flow-coder`, `flow-reviewer`, `flow-challenger`) en `~/.config/opencode/agents/`.
5. Crea el vault de Obsidian en la carpeta de tickets.

Después, en Claude Code corré `/reload-plugins`. Variables opcionales para `~/.zshrc`:

```bash
export TICKETS_ROOT="$HOME/tickets"    # dónde viven los tickets (default)
export REPOS_ROOT="$HOME/projects"     # dónde están tus clones (default)
export TICKET_BRANCH_PREFIX="feat"     # fuerza el prefijo de branch
```

Para actualizar el kit: `git pull` y `/reload-plugins`. Si cambió `install.sh` o los agentes de OpenCode, volvé a correr `bash install.sh`.

## 3. Configurar cada proyecto

```bash
ticket init mi-repo     # crea mi-repo/.agent-workflow.md
```

Ahí definís, por repo:

- plataforma de tareas y cómo leerlas (GitHub, Jira, Linear, Seeble… vía su MCP),
- prefijo de branch, formato de commit y si `/flow:implement` deja en staging o commitea por tarea,
- título, idioma y secciones de los PRs,
- comandos de test, lint y dev server,
- delegación a OpenCode (agente, modelos, modelos permitidos),
- challenge del plan (motor, modelo, mínimo de tareas),
- reviewer de OpenCode y verificación de UI con Playwright,
- carpeta de ADRs,
- datos sensibles.

Es una config **personal**: nunca se commitea. `ticket init` la agrega a `.git/info/exclude` y `ticket add` la enlaza por symlink en cada worktree, así hay una sola copia. Si la creás después de agregar el repo a un ticket, corré `ticket add <repo>` de nuevo. Sin ese archivo las skills usan defaults razonables y no delegan.

## 4. Uso paso a paso

```bash
ticket new mi-repo#12                              # desde un issue de GitHub
ticket new CAN-123 export-pdf --link <url-tarea>   # tarea de cualquier plataforma (o sin --link)
cd "$(ticket path 12)"
claude
```

| Paso | Dónde | Qué hace | Checkpoint |
|---|---|---|---|
| `/flow:refine` | agente | Investiga y escribe `spec.md` con criterios de aceptación y preguntas para producto | Aprobás el spec |
| `ticket add repo [otro]` | terminal | Suma repos: un worktree por repo, misma branch | |
| `/flow:plan` | agente | Escribe `plan.md`: decisiones, contratos, tareas. Corre el challenge | Aprobás el plan |
| `/flow:implement [repo]` | agente | Ejecuta las tareas, las deja en staging, registra desvíos en `decisions.md` | Tareas tildadas, tests ok |
| `/flow:review` | agente | Resumen de decisiones, PR reviewer opcional y UI con Playwright → `review.md` | Aprobás el review |
| `/flow:ship` | agente | Propone ADRs, redacta los PRs y el commit; el `shipper` pushea y abre los PRs | Aprobás PRs y commit |
| `/flow:status` | agente | Dónde quedó el ticket y qué sigue | |
| `/flow:help [tema]` | agente | Machete del flujo | |
| `ticket ls` / `ticket done` | terminal | Ver tickets activos / cerrar y archivar después del merge | |

Entre fases conviene abrir una sesión nueva: todo el contexto está en los archivos.

## 5. Las fases en detalle

**Refine.** Lee el ticket (issue de GitHub o tarea de otra plataforma), explora los repos en solo lectura y las decisiones previas (ADRs). Escribe `spec.md`: problema, fuera de alcance, criterios de aceptación `AC-1…` en formato Dado/Cuando/Entonces, repos en alcance, supuestos, preguntas abiertas para producto con un default propuesto, y riesgos. No toca código. Al aprobarlo: `fase: plan`.

**Plan.** Diseña el plan técnico en `plan.md`: decisiones de arquitectura con alternativas, contratos entre repos, orden de ejecución, tareas `T1…` chicas (revisables en un commit) con el AC que cubren y cómo se verifican, plan de testing y riesgos. Marca como `[delegable]` las tareas que un modelo más barato puede hacer sin criterio de arquitectura. Todo AC tiene que estar cubierto por una tarea. Al final corre el challenge (sección 9).

**Implement.** Ejecuta `plan.md` tarea por tarea, solo dentro de los worktrees. Cada tarea termina con tests y lint, y queda en staging (o en un commit, con `por-tarea`). Nunca pushea. Un desvío chico se registra como `D-n` en `decisions.md`; un desvío grande (contrato, AC, alcance, modelo de datos, infra) **frena** y le pregunta al usuario. Al terminar: `fase: review`.

**Review.** Lanza revisores que no vieron cómo se escribió el código: el subagente `decisions-summarizer` (qué cambió y qué decisiones implícitas hay), el PR reviewer de OpenCode (opcional) y el `ui-verifier` con Playwright (si el ticket toca interfaz). Consolida todo en `review.md`: veredicto, bloqueantes, importantes, decisiones para validar y cobertura de ACs. No arregla nada sin que se lo pidan.

**Ship.** Propone qué decisiones promover a ADRs (vos elegís), redacta un PR por repo en `pr-<repo>.md`, propone el commit y espera tu aprobación. Después el subagente `shipper` (Haiku) pushea y abre los PRs; en tickets multi-repo los enlaza entre sí. Nada se commitea ni se pushea sin tu aprobación. Al terminar: `fase: qa`.

**Cerrar.** Cuando los PRs se mergean, `ticket done` saca los worktrees (exige todo commiteado y pusheado) y archiva el ticket en `_archive/`. Las branches se conservan.

## 6. La carpeta de un ticket

```
~/tickets/mi-repo-12-login-google/
├── .ticket           # metadatos: ID, branch, repos, origen de la tarea
├── status.md         # fase (frontmatter), checkpoints, pendientes y log
├── spec.md           # fase 1
├── plan.md           # fase 2 (incluye la sección Challenge)
├── challenge.md      # objeciones del challenger, tal cual
├── decisions.md      # desvíos y decisiones durante la implementación
├── review.md         # fase 4
├── pr-mi-repo.md     # fase 5: título y cuerpo del PR aprobado
├── ui-review.md      # resultado por AC de la verificación de UI
├── ui-evidence/      # screenshots
└── .wt/mi-repo/      # worktree en feat/12-login-google (oculto para Obsidian)
```

## 7. Agentes y subagentes

| Agente | Modelo | Qué hace |
|---|---|---|
| `decisions-summarizer` | Sonnet | Solo lectura. Compara el diff con spec, plan y decisiones |
| `ui-verifier` | Sonnet | Prueba la UI con Playwright en localhost/staging, con datos sintéticos |
| `challenger` | Opus | Alternativa de Claude a `flow-challenger` (motor `claude`) |
| `shipper` | Haiku | Push y PRs con `gh`. Nunca force push, merge ni commits |
| `flow-coder` (OpenCode) | configurable | Implementa tareas `[delegable]`. No commitea, no pushea, no lee `.env` |
| `flow-reviewer` (OpenCode) | configurable | Code review de solo lectura |
| `flow-challenger` (OpenCode) | configurable | Cuestiona el plan, solo lectura |

El modelo de cada agente de OpenCode se define por proyecto en `.agent-workflow.md` y se pasa con `-m`: se cambia sin tocar los agentes.

## 8. Delegación a OpenCode

Con "Delegar tareas: sí" en la config, `/flow:implement` le pasa las tareas `[delegable]` a `flow-coder` con un brief en `$T/.delegation/`. Claude **siempre** verifica el diff, corre los tests y recién ahí stagea; nunca confía en la salida del modelo. Si queda mal, la corrige o la rehace una vez. Cada delegación queda en el Log de `status.md` (ok / corregida / rehecha), que sirve para comparar modelos. `--no-delegate` hace todo con Claude.

Para código de una empresa o de clientes, usá solo modelos que lo permitan (retención cero) y solo si la empresa lo autoriza.

## 9. Challenge del plan

Al terminar `/flow:plan`, un challenger con contexto fresco revisa el plan antes de implementar: hasta 5 objeciones, cada una con evidencia (`archivo:línea`, un AC o una sección del plan) y una alternativa concreta. Claude responde cada una en la sección **Challenge** de `plan.md` (aceptada o rechazada, con motivo) y recién ahí te pide aprobar. Si una objeción cambia el alcance o un AC, queda "para decidir" y te la levanta a vos.

El motor se elige en la config: `opencode` (otro modelo, vía `flow-challenger`) o `claude` (subagente `challenger` con Opus). Se saltea en planes chicos (mínimo de tareas en la config) o con `--skip-challenge`.

## 10. Memoria del proyecto: ADRs

Las decisiones que sobreviven al ticket se promueven a ADRs en el repo: `docs/decisions/NNNN-titulo.md`, con un índice en `docs/decisions/README.md`. `/flow:ship` las propone y vos elegís; entran en el mismo PR. `/flow:refine` y `/flow:plan` las leen al arrancar y las tratan como restricciones; si un plan necesita ir contra una, lo dice explícitamente y el ADR viejo queda "reemplazado por NNNN". El review avisa si el código contradice un ADR sin declararlo.

## 11. Obsidian

Opcional. Abrí la carpeta de tickets (`~/tickets`) como vault: `Tickets.base` muestra un tablero de tickets por fase y la pestaña "Archivados" los cerrados. El estado vive en el frontmatter de `status.md`. Los worktrees están en `.wt/` (carpeta oculta) para que Obsidian no indexe código. Obsidian es solo una capa de lectura, no una base de datos. Para buscar en todos los tickets: `rg "texto" ~/tickets`.

## 12. Reglas de oro

- Sesión nueva entre fases: el contexto vive en los archivos.
- Desvío grande en la implementación → el agente frena y pregunta.
- Nada se commitea ni se pushea sin que apruebes en `/flow:ship`.
- Review de UI: dev server levantado y su URL en `status.md`.
- Nunca `.env`, credenciales ni datos reales de usuarios en el contexto de un agente.

## 13. Si algo falla

| Síntoma | Qué hacer |
|---|---|
| "no es un repo git" / "no tiene commits" | `git init` y un commit inicial |
| No puede leer el issue o abrir el PR | `gh auth login`, y que el repo tenga remoto en GitHub |
| Tarea de otra plataforma | Que su MCP esté conectado y que "Cómo leer una tarea" de la config diga qué tool usar; si no, pegá el texto |
| No corre la delegación, el challenger o el reviewer | Revisá `.agent-workflow.md`, `opencode agent list` y `opencode models` |
| No aparecen los `/flow:*` | `/reload-plugins` o `claude plugin list` |
| `ticket: command not found` | Agregá `~/.local/bin` al `PATH` y abrí otra terminal |
| `ticket done` se queja | Commiteá y `git push -u origin HEAD` en el repo indicado |
| Cambié una skill y no se refleja | `/reload-plugins`; si sigue igual, subí la versión en `plugin/.claude-plugin/plugin.json` y `claude plugin update flow` |

## 14. Cambiar el flujo

Cada fase es un `SKILL.md` en `plugin/skills/<fase>/`, en markdown. Las plantillas de los documentos están en `templates/`. Para ajustar el comportamiento de una fase, editá su `SKILL.md`.
