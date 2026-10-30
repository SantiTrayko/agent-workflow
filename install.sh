#!/usr/bin/env bash
# Instala el kit: el comando `ticket` y el plugin `flow` de Claude Code (marketplace local).
# Se puede correr de nuevo sin problema.
set -euo pipefail
KIT="$(cd "$(dirname "$0")" && pwd)"

# 1) Limpiar la instalación vieja (skills ticket-* y agentes sueltos con symlink al kit)
for l in "$HOME"/.claude/skills/ticket-* "$HOME"/.claude/agents/decisions-summarizer.md "$HOME"/.claude/agents/ui-verifier.md; do
  if [ -L "$l" ]; then rm "$l"; echo "· quitado enlace viejo $(basename "$l")"; fi
done

# 2) Comando ticket
mkdir -p "$HOME/.local/bin"
chmod +x "$KIT/bin/ticket"
ln -sfn "$KIT/bin/ticket" "$HOME/.local/bin/ticket"
echo "✓ comando ticket → ~/.local/bin/ticket"

# 3) Plugin flow (desde este directorio como marketplace local: los cambios se aplican solos)
if command -v claude >/dev/null 2>&1; then
  claude plugin marketplace add "$KIT" 2>/dev/null || claude plugin marketplace update agent-workflow 2>/dev/null || true
  claude plugin install flow@agent-workflow 2>/dev/null || echo "· flow ya estaba instalado"
  echo "✓ plugin flow → /flow:refine /flow:plan /flow:implement /flow:review /flow:ship /flow:status /flow:help"
else
  echo "! no encontré el CLI 'claude'. Dentro de Claude Code corré:"
  echo "    /plugin marketplace add $KIT"
  echo "    /plugin install flow@agent-workflow"
fi

# 4) Agentes de OpenCode (flow-coder, flow-reviewer) con permisos ya configurados
mkdir -p "$HOME/.config/opencode/agents"
for a in "$KIT"/opencode/agents/*.md; do
  dest="$HOME/.config/opencode/agents/$(basename "$a")"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    echo "! ya existe $dest y no es del kit: no lo piso"
  else
    ln -sfn "$a" "$dest"; echo "✓ agente OpenCode $(basename "$a" .md)"
  fi
done

# 5) Vault de Obsidian en la carpeta de tickets
"$KIT/bin/ticket" vault

# 6) Chequeos
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) echo; echo "! ~/.local/bin no está en tu PATH. Agregá a ~/.zshrc:"; echo '    export PATH="$HOME/.local/bin:$PATH"' ;;
esac
command -v gh >/dev/null 2>&1 && echo "✓ gh encontrado" || echo "! falta gh (GitHub CLI): brew install gh && gh auth login — lo usan 'ticket new repo#N' y /flow:ship"
command -v opencode >/dev/null 2>&1 && echo "✓ opencode encontrado" || echo "! falta opencode: lo usan la delegación, el challenger y el reviewer"
[ -d /Applications/Obsidian.app ] && echo "✓ Obsidian instalado" || echo "! falta Obsidian: brew install --cask obsidian"
echo
echo "Listo. En una sesión de Claude Code abierta, corré /reload-plugins. Ayuda: /flow:help o 'ticket help'."
