{ inputs, pkgs, ... }:
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

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    initContent = ''
      ${
        if pkgs.stdenv.isLinux then
          ''
            if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ];then
              exec start-hyprland
            fi
          ''
        else
          ""
      }
      ${
        if pkgs.stdenv.hostPlatform.system == "aarch64-darwin" then
          ''
            eval "$(/opt/homebrew/bin/brew shellenv)"
          ''
        else
          ""
      }

      # 自动启动 gpg-agent 并更新 TTY
      gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1

      # 导出 Nix-LD 动态库路径供 Java JNI / 外部二进制使用
      if [[ -n "$NIX_LD_LIBRARY_PATH" ]]; then
        export LD_LIBRARY_PATH="$NIX_LD_LIBRARY_PATH''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      fi

      # 如果在交互式终端内，要求 pinentry 脚本使用终端模式 (curses)
      if [[ -t 0 ]]; then
        export PINENTRY_USER_DATA="USE_CURSES=1"
      fi

      zstyle ':completion:*' use-cache on
      zstyle ':completion:*:descriptions' format '[%d]'
      zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
      zstyle ':fzf-tab:*' default-color $'\033[34m'
      zstyle ':fzf-tab:*' switch-group ',' '.'
      zstyle ':fzf-tab:*' fzf-pad 4
      zstyle ':fzf-tab:*' fzf-flags --no-separator \
      --color=bg+:#363A4F,bg:#24273A,spinner:#F4DBD6,hl:#ED8796 \
      --color=fg:#CAD3F5,header:#ED8796,info:#C6A0F6,pointer:#F4DBD6 \
      --color=marker:#B7BDF8,fg+:#CAD3F5,prompt:#C6A0F6,hl+:#ED8796 \
      --color=selected-bg:#494D64 \
      --color=border:#6E738D,label:#CAD3F5

      # 修正 vi 模式下的 backspace 行为
      bindkey '^?' backward-delete-char

      function pyvenv_cd {
        if [[ -n "$VIRTUAL_ENV" ]]; then
          if [[ $PWD != "$${VIRTUAL_ENV}"* ]]; then
            deactivate
          fi
        else
          if [[ -d .venv ]]; then
            source .venv/bin/activate
            #export PATH="$PATH:$VIRTUAL_ENV/.venv/bin"
          fi
        fi
      }

      # 获取windows剪切板路径
      wpath() {
        local win_path
        win_path=$(powershell.exe -NoProfile -Command "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; \$p = Get-Clipboard; if (\$p) { \$p.ToString().Trim('\"').Replace('\', '/') }" 2>/dev/null | tr -d '\r')
        if [ -n "$win_path" ]; then
          wslpath -u "$win_path"
        fi
      }

      autoload -U add-zsh-hook
      add-zsh-hook chpwd pyvenv_cd
      [[ $PWD != ~ ]] && pyvenv_cd
    '';

    completionInit = ''
      autoload -Uz compinit

      # 使用 Zsh 原生 Glob 检查文件时间（mh+24 代表修改时间超过 24 小时）
      # (N) 代表如果文件不存在不报错
      _comp_files=(~/.zcompdump(N.mh+24))

      if (( $#_comp_files )); then
        # 超过 24 小时了，或者是第一次启动，执行全量刷新并检查安全性 (-u)
        compinit -u
        # 在后台静默编译成二进制，绝不阻塞你打开新终端的速度
        zcompile ~/.zcompdump &!
      else
        # 24 小时以内，直接用 -C 极速读取缓存（去掉冲突的 -u）
        compinit -C
      fi

      unset _comp_files
    '';

    enable = true;
    # 显式开启 vi 模式
    defaultKeymap = "viins";
    # 支持..返回上一级目录
    autocd = true;

    # 启用自动补全
    enableCompletion = true;
    # 启用自动建议 (输入时灰色提示)
    autosuggestion.enable = true;
    # 关闭语法高亮
    syntaxHighlighting.enable = false;

    # 别名设置
    shellAliases = {
      update =
        if pkgs.stdenv.isDarwin then
          "sudo -H darwin-rebuild switch --flake ."
        else
          "sudo nixos-rebuild switch --flake .";
      vim = "nvim";
      ls = "eza";
      l = "eza -l";
      la = "eza -a";
      ll = "eza -l";
      lla = "eza -la";
      cp = "rsync -aP";
      cat = "bat --style=changes";
      cls = "clear";

      feh = "feh -F";
      bc = "bc -ql";

      fetch = "fastfetch";
      kssh = "kitty +kitten ssh";

      # git
      gl = "git pull";
      gp = "git push";
      gcmsg = "git commit -m";
      gss = "git status -s";
      gst = "git status";
      gsw = "git switch";
      gswc = "git switch --create";
      gswm = "git switch $(git_main_branch)";
      gswd = "git switch $(git_develop_branch)";
      gm = "git merge";
      gma = "git merge --abort";
      gbr = "git br";
      gcl = "git clone";
      grv = "git remote --verbose";

      datetime = "date '+%Y-%m-%d %H:%M:%S'";

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

    plugins = [
      {
        name = "omz-sudo";
        src = inputs.ohmyzsh;
        file = "plugins/sudo/sudo.plugin.zsh";
      }
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
      {
        name = "forgit";
        src = pkgs.zsh-forgit;
        file = "share/zsh/zsh-forgit/forgit.plugin.zsh";
      }
      {
        name = "fast-syntax-highlighting";
        src = pkgs.zsh-fast-syntax-highlighting;
        file = "share/zsh/site-functions/fast-syntax-highlighting.plugin.zsh";
      }
    ];
  };

}
