---
name: review
description: Fase 4 del flujo. Lanza en paralelo el resumen de decisiones, el PR reviewer de OpenCode (si el proyecto lo usa) y la verificación de UI con Playwright, y consolida todo en review.md. Usar con /flow:review.
---

# Review del ticket → review.md

Coordinás revisores independientes que **no vieron cómo se escribió el código**. Vos no revisás: juntás, consolidás y priorizás.

## 0. Ubicarte y cargar la config
1. Buscá `.ticket` en el directorio actual o sus padres → `$T`. Leé `.ticket`, `status.md`, `spec.md`, `plan.md` y `decisions.md`.
2. **Config del proyecto:** leé `.agent-workflow.md` de cada worktree: sección "Revisión" (¿se usa el reviewer de OpenCode?, ¿verificación de UI?), "Calidad" (dev server) y "Datos sensibles".
3. Para cada repo de `REPOS`, calculá la base del diff: `git -C $T/.wt/<repo> merge-base HEAD origin/HEAD` (si falla, la rama base de la config, o `main`).
4. Si hay cambios sin commitear en algún worktree, avisale al usuario antes de seguir.

## 1. Lanzar revisores (en paralelo)
**a) Resumen de decisiones**: subagente `decisions-summarizer` con la ruta de `$T`. Siempre.

**b) PR reviewer de OpenCode**: solo si la config lo activa (sin config, solo si `OPENCODE_REVIEW_AGENT` está definida). Uno por repo, en segundo plano si se puede. El contexto va adjunto con `-f` porque está fuera del repo:
```bash
cd "$T/.wt/<repo>" && opencode run --agent <agente del reviewer, default flow-reviewer> -m <modelo del reviewer> \
  -f "$T/spec.md" -f "$T/plan.md" -f "$T/decisions.md" \
  "Revisá los cambios de esta branch contra <base> (git diff <base>...HEAD). El ticket está en los adjuntos." \
  > "$T/review-<repo>.md" 2>&1
```
Si `opencode` no está o el agente no existe (`opencode agent list`), avisá y seguí.

**c) Verificación de UI**: solo si el ticket toca interfaz y la config no la desactiva. Necesita la "URL para probar la UI" en `status.md` (o el dev server de la config) y el server levantado; si falta, pedíselo al usuario o salteá el paso dejándolo anotado. Subagente `ui-verifier` con la ruta de `$T`.

## 2. Consolidar en `$T/review.md`
- **Veredicto:** listo para PR / necesita cambios.
- **Bloqueantes:** lista única, sin duplicados entre revisores, con el origen de cada hallazgo.
- **Importantes y menores.**
- **Decisiones para validar:** las que el resumen marcó como implícitas o no documentadas.
- **Cobertura de ACs:** tabla AC → tarea → verificado por (test / UI / nada).
- Links a `review-<repo>.md` y a la evidencia de UI.

## 3. Cerrar
- Mostrale al usuario el veredicto y los bloqueantes. **No arregles nada sin que te lo pida**; si lo pide, volvé al protocolo de `/flow:implement`.
- Cuando lo apruebe: tildá "Review hecho" en `status.md`, `fase: ship` en el frontmatter, y recordale `/flow:ship`.
