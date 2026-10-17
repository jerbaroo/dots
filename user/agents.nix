let
  instructions = ./agents/AGENTS.md;
in
{
  home.file = {
    ".agents/AGENTS.md".source = instructions;
    ".codex/AGENTS.md".source = instructions;
    ".copilot/copilot-instructions.md".source = instructions;
  };
}
