{ pkgs, ... }:
{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;

    defaultCommand = "fd --exclude={.git,.idea,.vscode,.sass-cache,node_modules,build}";

    defaultOptions = [
      "--layout=reverse"
      "--height 100"
      "--border"
      "--no-separator"
      "--bind 'alt-y:execute(echo -n {} | ${
        if pkgs.stdenv.isDarwin then "pbcopy" else "xclip -selection clipboard"
      })'"
    ];
  };

  programs.zsh = {

    initContent = ''
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi

      # 导出 Nix-LD 动态库路径供 Java JNI / 外部二进制使用
      if [[ -n "$NIX_LD_LIBRARY_PATH" ]]; then
        export LD_LIBRARY_PATH="$NIX_LD_LIBRARY_PATH''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      fi

      # 修正 vi 模式下的 backspace 行为
      bindkey '^?' backward-delete-char

      [[ ! -f ~/.config/zsh/env.zsh ]] || source ~/.config/zsh/env.zsh
      [[ ! -f ~/.config/zsh/zinit.zsh ]] || source ~/.config/zsh/zinit.zsh
      [[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh
      [[ ! -f ~/.config/zsh/browser.zsh ]] || source ~/.config/zsh/browser.zsh
      [[ ! -f ~/.config/zsh/proxy.zsh ]] || source ~/.config/zsh/proxy.zsh
      [[ ! -f ~/.config/zsh/git.zsh ]] || source ~/.config/zsh/git.zsh
      [[ ! -f ~/.config/zsh/user.zsh ]] || source ~/.config/zsh/user.zsh
      [[ ! -f ~/.config/zsh/fzf.zsh ]] || source ~/.config/zsh/fzf.zsh
      [[ ! -f ~/.config/zsh/alias.zsh ]] || source ~/.config/zsh/alias.zsh
      [[ ! -f ~/.config/zsh/dev.zsh ]] || source ~/.config/zsh/dev.zsh
    '';

    enable = true;
    # 显式开启 vi 模式
    defaultKeymap = "viins";
    # 支持..返回上一级目录
    autocd = true;
    enableCompletion = false;
    autosuggestion.enable = false;
    syntaxHighlighting.enable = false;
    setOptions = [
      "MULTIOS"
      "PROMPT_SUBST"
    ];

    # 别名设置
    shellAliases = {
      update =
        if pkgs.stdenv.isDarwin then
          "sudo -H darwin-rebuild switch --flake ."
        else
          "sudo nixos-rebuild switch --flake .";
      nix-shell = "nix-shell --command zsh";
    };

    # 历史记录配置
    history = {
      size = 10000;
      path = "$HOME/.zsh_history";

      # 忽略连续重复的命令 (setopt HIST_IGNORE_DUPS)
      ignoreDups = true;

      # 忽略以空格开头的命令 (setopt HIST_IGNORE_SPACE)
      ignoreSpace = true;

      # 多个终端会话共享历史 (setopt SHARE_HISTORY)
      share = true;

      # 立即写入历史文件，而不是等退出时 (setopt INC_APPEND_HISTORY)
      append = true;

      # 记录命令执行的时间戳 (对应 omz 的 history 格式)
      expireDuplicatesFirst = true;
    };

  };

}
