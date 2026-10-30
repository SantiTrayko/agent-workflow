# Configuración del flujo de agentes

<!--
Este archivo va en la raíz de cada repo (`ticket init <repo>` lo copia).
Todas las skills /ticket-* lo leen antes de trabajar y sus reglas mandan sobre los defaults.
Si un ticket abarca varios repos, se aplican las reglas de cada repo a su parte.
Borrá o completá lo que no aplique.
-->

## Tickets
- **Origen:** github-issues   <!-- github-issues | manual -->
- **Formato de ID:** #<número de issue>
- **Idioma del spec y de las preguntas para producto:** español

## Git
- **Branch:** feat/<id>-<slug>          <!-- fix/... para bugs -->
- **Commit:** `<tipo>(<scope>): <descripción> (#<id>)`   <!-- conventional commits -->
- **Rama base:** main

## Pull requests
- **Título:** `<tipo>: <resumen> (#<id>)`
- **Idioma:** español
- **Draft por defecto:** sí
- **Cierra el issue:** sí (`Closes #<id>` en el cuerpo)
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
- **Agente:** flow-challenger
- **Modelo:** opencode-go/kimi-k3   <!-- corre una vez por ticket: puede ser el modelo más capaz aunque tenga poca cuota -->
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
