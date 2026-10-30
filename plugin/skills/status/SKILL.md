---
name: status
description: Muestra en qué fase está el ticket actual, el estado de cada worktree y cuál es el próximo paso. Sirve para retomar un ticket en una sesión nueva. Usar con /flow:status o cuando el usuario pregunta dónde quedó un ticket.
---

# Estado del ticket

1. Buscá `.ticket` en el directorio actual o sus padres → `$T`. Si no hay, corré `ticket ls` y mostrá los tickets activos.
2. Leé `.ticket`, `status.md`, y por encima `spec.md`, `plan.md` y `decisions.md`.
3. Por cada repo de `REPOS`: `git -C $T/.wt/<repo> status --short` y `git -C $T/.wt/<repo> log --oneline -5`. Si hay PRs en `status.md`, `gh pr view <url> --json state,reviewDecision -q '.state + " " + .reviewDecision'`.
4. Respondé corto, en este orden:
   - Ticket (ID y link al issue si hay), fase actual (campo `fase` del frontmatter de `status.md`) y checkpoints tildados.
   - Por repo: commits, cambios sin commitear, si está pusheado y estado del PR.
   - Tareas del plan: hechas / total y cuál es la próxima.
   - Decisiones pendientes de aprobar en `decisions.md`.
   - **Próximo paso:** el comando concreto (`/flow:refine`, `ticket add …`, `/flow:plan`, `/flow:implement <repo>`, `/flow:review`, `/flow:ship`, `ticket done`).
