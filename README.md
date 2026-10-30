# agent-workflow

Flujo por fases para trabajar tickets con agentes: **refine → plan → implement → review → ship**.
Cada fase deja un archivo en la carpeta del ticket y la siguiente lo lee. Sin copy-paste entre chats.

Tiene dos partes:
- **`ticket`** (terminal): crea la carpeta del ticket, los worktrees y la branch.
- **Plugin `flow`** (Claude Code): `/flow:refine`, `/flow:plan`, `/flow:implement`, `/flow:review`, `/flow:ship`, `/flow:status`, `/flow:help`, más los subagentes `decisions-summarizer`, `ui-verifier` y `shipper` (Haiku).

## Instalar

```bash
cd ~/Desktop/projects/agent-workflow
bash install.sh
```

Registra esta carpeta como marketplace local e instala el plugin: si editás un SKILL.md, el cambio se aplica en la próxima sesión o con `/reload-plugins`.

Opcional, en `~/.zshrc`:

```bash
export TICKETS_ROOT="$HOME/Desktop/tickets"   # dónde viven los tickets
export REPOS_ROOT="$HOME/Desktop/projects"    # dónde están tus clones
```

Requisitos: `gh` (GitHub CLI) con `gh auth login` para issues y PRs. `opencode` con OpenCode Go para delegar tareas y para el reviewer.

`install.sh` también enlaza tres agentes de OpenCode en `~/.config/opencode/agents/`:
- **flow-coder:** implementa tareas `[delegable]`. Puede editar archivos y correr tests y lint; no puede commitear, pushear, instalar dependencias ni leer `.env` o claves.
- **flow-reviewer:** code review de solo lectura (git diff/log/show, cat, grep).
- **flow-challenger:** cuestiona el plan antes de implementar (solo lectura, máx. 5 objeciones con evidencia).

El modelo de cada uno se define por proyecto en `.agent-workflow.md` y se pasa con `-m`, así lo cambiás sin tocar los agentes.

## Configurar cada proyecto

```bash
ticket init growcore     # crea growcore/.agent-workflow.md
```

Ahí definís, por repo: origen de tickets, formato de branch y commits, título y cuerpo de los PRs, idioma, comandos de test, si se usa el reviewer de OpenCode y la UI con Playwright, y qué datos son sensibles. Commitealo en el repo. Sin ese archivo, las skills usan defaults razonables.

## Uso

```bash
ticket new growcore#12            # desde un issue de GitHub (o: ticket new CAN-123 slug)
cd "$(ticket path 12)"
claude
```

| Paso | Dónde | Qué hace |
|---|---|---|
| `/flow:refine` | agente | Investiga y escribe `spec.md` con ACs y preguntas para producto |
| `ticket add repo [otro]` | terminal | Suma repos: un worktree por repo, misma branch |
| `/flow:plan` | agente | Escribe `plan.md`: decisiones, contratos, tareas |
| `/flow:implement [repo]` | agente | Ejecuta tareas, commitea, registra desvíos en `decisions.md` |
| `/flow:review` | agente | Resumen de decisiones + PR reviewer (opcional) + UI con Playwright → `review.md` |
| `/flow:ship` | agente | Propone ADRs (vos elegís), redacta los PRs, vos aprobás, el subagente `shipper` pushea y los abre |
| `/flow:status` | agente | Dónde quedó y qué sigue (para retomar en sesión nueva) |
| `/flow:help [tema]` | agente | Machete del flujo |
| `ticket ls` / `ticket done` | terminal | Ver tickets activos / cerrar y archivar después del merge |

Entre fases conviene abrir una sesión nueva: todo el contexto está en los archivos.

## Memoria del proyecto

- **Del ticket:** spec, plan, decisiones y review en la carpeta del ticket; al cerrar quedan en `tickets/_archive/` (buscable con `rg`, o abrí `~/Desktop/tickets` como vault de Obsidian).
- **Del proyecto:** las decisiones que sobreviven al ticket se promueven a ADRs en el repo (`docs/decisions/`) durante `/flow:ship`. Las leen `/flow:refine` y `/flow:plan` en los tickets siguientes, y cualquier otro agente que trabaje en el repo.

## Estructura

```
agent-workflow/
├── .claude-plugin/marketplace.json   # marketplace local
├── plugin/                           # plugin "flow"
│   ├── skills/{refine,plan,implement,review,ship,status,help}/SKILL.md
│   └── agents/{decisions-summarizer,ui-verifier,shipper}.md
├── opencode/agents/{flow-coder,flow-reviewer,flow-challenger}.md
├── bin/ticket
├── templates/                        # spec, plan, decisions, status, agent-workflow
└── install.sh

~/Desktop/tickets/growcore-12-login-google/
├── .ticket  status.md  spec.md  plan.md  decisions.md
├── review.md  pr-growcore.md  ui-review.md  ui-evidence/
└── .wt/growcore/                     # worktree en feat/12-login-google (oculto para Obsidian)
```

`_to_delete/` tiene la versión anterior (skills `ticket-*`); se puede borrar.
