{ inputs, config, ... }:
{
  imports = [
    ../common.nix
    ./modules/karabiner.nix
  ];

  # 映射特定的 Rime 配置文件与 Hammerspoon 配置
  home.file = {
    ".hammerspoon".source = ../../config/hammerspoon;
    "Library/Rime" = {
      source = inputs.rime-config;
      recursive = true;
    };
  };

  home = {
    homeDirectory = "/Users/${config.home.username}";
  };

  home.sessionVariables = {
    __ETC_ZSHRC_SOURCED = 1;
    # HOMEBREW_BREW_GIT_REMOTE  = "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git";
    # HOMEBREW_CORE_GIT_REMOTE  = "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git";
    # HOMEBREW_API_DOMAIN       = "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api";
    # HOMEBREW_BOTTLE_DOMAIN    = "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles";
    # HOMEBREW_PIP_INDEX_URL    = "https://pypi.tuna.tsinghua.edu.cn/simple";
    HOMEBREW_INSTALL_CLEANUP = 1;
    HOMEBREW_INSTALL_FROM_API = 1;
  };

  home.packages = [ ];
}
