---
name: implement
description: Fase 3 del flujo. Ejecuta las tareas de plan.md en los worktrees del ticket (delegando las [delegable] a OpenCode y verificándolas), commitea por tarea, registra desvíos en decisions.md y frena ante cambios de alcance. Usar con /flow:implement [repo].
disable-model-invocation: true
---

# Implementar el plan

Ejecutás `plan.md` tarea por tarea. El plan es la fuente de verdad; cualquier desvío queda escrito. Sos responsable de la calidad de **cada** commit, lo hayas escrito vos o un modelo delegado.

## 0. Ubicarte y cargar la config
1. Buscá `.ticket` en el directorio actual o sus padres → `$T`. Leé `.ticket`, `status.md`, `spec.md`, `plan.md` y `decisions.md`.
2. **Config del proyecto:** leé `.agent-workflow.md` de cada worktree. De ahí salen el formato de commit, los comandos de test/lint, los datos sensibles y la sección "Delegación" (agente, modelos y modelos permitidos). Si falta, usá los defaults de abajo y no delegues.
3. Si te pasaron un repo en `$ARGUMENTS`, trabajá solo en `$T/.wt/<repo>`. Si no, seguí el orden de ejecución del plan. Si `$ARGUMENTS` incluye `--no-delegate`, hacé todo vos.
4. Identificá la próxima tarea sin tildar y arrancá por ahí (así se retoma sin perder nada).

## 1. Reglas de trabajo
- **Solo se tocan archivos dentro de los worktrees (`$T/.wt/<repo>`).** Nunca los repos base de `REPOS_ROOT`.
- Una tarea a la vez: implementar, correr tests y lint, verificar lo que dice la tarea y recién ahí tildarla en `plan.md`.
- Un commit por tarea, con el formato de la config. Default: `<ID> T<n>: descripción corta`. **No pushees**: eso es de `/flow:ship`.
- Respetá "Datos sensibles" de la config. Siempre: nada de `.env` ni credenciales; solo datos sintéticos en tests y fixtures.
- Si otro agente implementa otro repo del mismo ticket, releé `decisions.md` antes de cada tarea.

## 2. Tareas `[delegable]` → OpenCode
Solo si la config dice "Delegar tareas: sí", `opencode` está instalado y la tarea está marcada `[delegable]`. Si algo de eso falla, hacela vos.

1. **Elegí el modelo:** `[delegable:mecánica]` → modelo para tareas mecánicas; resto → modelo por defecto. Tiene que estar dentro de "Modelos permitidos".
2. **Escribí el brief** en `$T/.delegation/T<n>.md`: la línea de la tarea, los archivos a tocar, el comportamiento esperado, el AC que cubre, las convenciones relevantes (con un ejemplo de archivo vecino si hay patrón), los comandos de test y lint, y qué NO tocar.
3. **Lanzá** (el spec y el plan van adjuntos con `-f` porque están fuera del repo):
   ```bash
   cd "$T/.wt/<repo>" && opencode run --agent <agente> -m <modelo> \
     -f "$T/.delegation/T<n>.md" -f "$T/plan.md" -f "$T/spec.md" \
     "Implementá la tarea T<n> según el brief adjunto. No commitees." \
     > "$T/.delegation/T<n>.out.md" 2>&1
   ```
4. **Verificá vos, siempre:**
   - `git diff` completo: que toque solo lo que pide la tarea, que siga las convenciones y que no haya archivos sensibles ni dependencias nuevas.
   - Corré tests y lint vos mismo (no confíes en lo que reporta el modelo).
   - Chequeá el criterio de verificación de la tarea.
5. **Resultado:**
   - **OK** → commit y tildá la tarea.
   - **Fallas chicas** → corregilas vos y commiteá.
   - **Mal encaminada** → `git checkout -- . && git clean -fd` en ese worktree (solo cambios sin commitear de esta tarea), y reintentá una vez con el brief mejorado y el error concreto. Si vuelve a fallar, hacela vos.
6. **Registrá** en el Log de `status.md`: `T<n> delegada a <modelo>: ok | corregida (qué) | rehecha`. Ese registro es lo que sirve para comparar modelos.

## 3. Protocolo de desvíos
- **Desvío chico** (detalle de implementación, archivo distinto, helper extra, sin cambiar contratos ni ACs): hacelo y registralo en `decisions.md` como `D-n` (contexto, decisión, alternativas, impacto). Seguí.
- **Desvío grande** (cambia un contrato entre repos, un AC, el alcance, el modelo de datos o agrega infra): **frená**. Registralo en `decisions.md` como pendiente, explicale al usuario en pocas líneas qué encontraste y qué proponés, y esperá. Si lo aprueba, actualizá también `plan.md`.
- Mejoras que surgen pero no son del ticket: van a "Pendientes / bloqueos" en `status.md`. No las implementes.

## 4. Al terminar la sesión
- Agregá al Log de `status.md` qué tareas quedaron hechas y qué sigue. Si hubo delegaciones, un resumen: cuántas ok / corregidas / rehechas por modelo.
- Si todas las tareas de todos los repos están tildadas y los tests pasan: tildá "Implementación completa", `fase: review` en el frontmatter y recordale `/flow:review`.
