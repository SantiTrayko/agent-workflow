---
name: ship
description: Fase 5 del flujo. Redacta los PRs de cada repo del ticket a partir de spec, plan, decisions y review, los muestra para aprobar y delega el commit, push y creación de PRs al subagente shipper (Haiku). Usar con /flow:ship.
disable-model-invocation: true
---

# Ship: commit, push y PRs

Vos redactás (requiere criterio); el subagente `shipper` ejecuta (es mecánico y barato). Nada se pushea sin que el usuario apruebe los PRs.

## 0. Ubicarte y cargar la config
1. Buscá `.ticket` en el directorio actual o sus padres → `$T`. Leé `.ticket`, `status.md`, `spec.md`, `plan.md`, `decisions.md` y `review.md` si existe.
2. **Config del proyecto:** leé `.agent-workflow.md` de cada worktree, secciones "Git" y "Pull requests" (título, idioma, draft, cierre del issue, secciones del cuerpo, rama base). Defaults si falta: título `<ID>: <resumen>`, español, draft sí, rama base = default del remoto.
3. Chequeos previos (avisá y preguntá si alguno falla, no frenes en seco):
   - "Review hecho" tildado en `status.md`. Si no, recomendá `/flow:review` primero.
   - `gh auth status` OK y cada repo tiene remoto en GitHub.
   - Cambios sin commitear en algún worktree: mostrálos y preguntá si se incluyen (y con qué mensaje, en el formato de commit de la config) o se descartan del PR.

## 1. Promover decisiones a ADRs (antes de los PRs)
Las decisiones que sobreviven al ticket no se pueden quedar en la carpeta del ticket: van al repo como ADR. Saltealo si la config dice "Proponer ADRs al hacer ship: no".

1. Repasá `plan.md` (Decisiones de arquitectura, Challenge) y `decisions.md`. Proponé un ADR solo para decisiones que **un futuro ticket necesitaría conocer**: modelo de datos, contratos entre servicios, elección de tecnología o librería, patrones que se van a repetir, integraciones externas, restricciones de seguridad o de datos. **No** para detalles de implementación locales.
2. Mostrale al usuario la lista: título de una línea, repo donde iría y de dónde sale (D-n, sección del plan). Él elige cuáles van. También puede no ir ninguno.
3. Por cada ADR elegido, en el worktree del repo correspondiente (`$T/.wt/<repo>`):
   - Carpeta: la de la config (default `docs/decisions/`). Si no existe, creala con un `README.md` que tenga el título "Decisiones de arquitectura" y una tabla índice: Nº | Título | Estado | Fecha.
   - Número: el siguiente al mayor existente, con 4 dígitos (`0001`, `0002`…). Archivo `NNNN-titulo-en-kebab.md`, con esta estructura: título `# NNNN. Título`, y debajo Estado (aceptada / reemplazada por NNNN / deprecada), Fecha, Ticket (ID y link al issue), y las secciones Contexto, Decisión, Alternativas consideradas y Consecuencias. Corto: media página como máximo.
   - Si reemplaza a un ADR vigente, marcá el viejo como "reemplazada por NNNN" y actualizá el índice.
   - Agregá la fila al índice.
   - Si la decisión cambia algo general del proyecto (stack, principios, arquitectura), proponé también la línea a actualizar en `CLAUDE.md`.
4. Commiteá los ADRs en la branch del ticket (formato de commit de la config, tipo `docs`), así entran en el mismo PR. Mencionalos en la sección Decisiones del cuerpo del PR.

## 2. Redactar un PR por repo → `$T/pr-<repo>.md`
- **Título:** según la config.
- **Cuerpo:** las secciones de la config. Default:
  - **Qué cambia:** 3-6 bullets de este repo.
  - **Por qué:** 1-2 líneas desde el spec.
  - **Decisiones:** las relevantes de `plan.md` y `decisions.md`, con link a esta parte del ticket si hay más.
  - **Cómo probar:** pasos concretos, desde los ACs y el plan de testing.
  - **Checklist:** tests, lint, ACs cubiertos (según `review.md`).
- **Vínculo con el issue** (si `.ticket` tiene `ISSUE`): en el repo del issue (`ISSUE_REPO`), `Closes #<ISSUE>` si la config lo pide; en los demás repos, `Refs <owner>/<ISSUE_REPO>#<ISSUE>`.
- **Multi-repo:** dejá un placeholder `<!-- related-prs -->` al final; el shipper lo completa con los links de los otros PRs.
- Nunca incluyas secretos, datos sensibles ni rutas locales de la máquina.

Mostrale al usuario el título y cuerpo de cada PR y **esperá su aprobación** (puede pedir cambios).

## 3. Delegar al subagente `shipper`
Pasale en el prompt, por repo: ruta del worktree, branch, rama base, título, ruta de `pr-<repo>.md` y si es draft. Más la ruta de `$T`. El shipper pushea, crea los PRs, completa los PRs relacionados y te devuelve las URLs.

## 4. Cerrar
- En `status.md`: agregá una sección **PRs** con la URL de cada uno, tildá "PR abierto", `fase: qa` en el frontmatter y línea en el Log.
- Recordale que cuando los PRs se mergeen corra `ticket done` para sacar los worktrees y archivar el ticket.
