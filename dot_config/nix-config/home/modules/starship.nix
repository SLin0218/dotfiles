{ ... }: {
  programs.starship = {
    enable = true;
    # 自动将初始化脚本注入 zsh/bash/fish
    enableZshIntegration = true;

    # 具体的样式配置
    settings = {
      add_newline = false;

      format = "$username$hostname$directory$git_branch$git_state$git_status$cmd_duration$java$nix_shell$line_break$python$character";

      directory = {
        style = "blue";
      };

      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
        vimcmd_symbol = "[❮](green)";
      };

      git_branch = {
        format = "[$branch]($style)";
        style = "bright-black";
      };

      git_status = {
        format = "[[(*$conflicted$untracked$modified$staged$renamed$deleted)](218) ($ahead_behind$stashed)]($style) ";
        style = "cyan";
        conflicted = "";
        untracked = "";
        modified = "";
        staged = "";
        renamed = "";
        deleted = "";
        stashed = "≡";
      };

      git_state = {
        format = "([$state( $progress_current/$progress_total)]($style)) ";
        style = "bright-black";
      };

      cmd_duration = {
        format = "[$duration]($style) ";
        style = "yellow";
      };

      python = {
        format = "[$virtualenv]($style) ";
        style = "bright-black";
        detect_extensions = [ ];
        detect_files = [ ];
      };

      java = {
        format = "[$symbol($version )]($style)";
      };

      nix_shell = {
        disabled = false;
        format = "[$symbol($name)]($style) ";
        symbol = "☃️ ";
      };
    };
  };
}
