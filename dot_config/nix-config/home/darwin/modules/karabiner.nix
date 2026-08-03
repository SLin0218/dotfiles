{ osConfig, ... }:

let
  # company pc
  mainChat = if osConfig.networking.hostName == "fcdeMac-mini" then "WeLink" else "WeChat";

  hyperModifiers = [
    "right_command"
    "right_control"
    "right_option"
    "right_shift"
  ];

  # 辅助函数：生成应用限制条件
  mkFrontmost = bundle_identifiers: [
    {
      type = "frontmost_application_if";
      inherit bundle_identifiers;
    }
  ];

  # 辅助函数：生成基于 Hyper 键的 basic manipulator
  mkHyperKey =
    {
      fromKey,
      toKey ? fromKey,
      toModifiers ? [ ],
      extraFromModifiers ? [ ],
      conditions ? [ ],
    }:
    {
      type = "basic";
      from = {
        key_code = fromKey;
        modifiers.mandatory = hyperModifiers ++ extraFromModifiers;
      };
      to = [
        {
          key_code = toKey;
          modifiers = toModifiers;
        }
      ];
    }
    // (if conditions != [ ] then { inherit conditions; } else { });

  # 2. 模块化：Caps Lock 映射
  capsLockRule = {
    description = "capsLock to hyper key (control+shift+option+command)";
    manipulators = [
      {
        type = "basic";
        from = {
          key_code = "caps_lock";
          modifiers.optional = [ "any" ];
        };
        to = [
          {
            key_code = "right_shift";
            modifiers = [
              "right_command"
              "right_control"
              "right_option"
            ];
          }
        ];
        to_if_alone = [ { key_code = "escape"; } ];
      }
      {
        type = "basic";
        from = {
          key_code = "escape";
          modifiers.optional = [ "any" ];
        };
        to = [
          {
            key_code = "caps_lock";
          }
        ];
      }
    ];
  };

  # 3. 模块化：HJKL 方向键
  navigationRules = {
    description = "capsLock + hjkl to arrow";
    manipulators =
      let
        navMap = [
          {
            key = "k";
            arrow = "up_arrow";
          }
          {
            key = "j";
            arrow = "down_arrow";
          }
          {
            key = "h";
            arrow = "left_arrow";
          }
          {
            key = "l";
            arrow = "right_arrow";
          }
        ];
        allNavs =
          (map (
            item:
            item
            // {
              extraFrom = [ ];
              extraTo = [ ];
            }
          ) navMap)
          ++ (map (
            item:
            item
            // {
              extraFrom = [ "left_command" ];
              extraTo = [ "left_command" ];
            }
          ) navMap);
      in
      map (
        item:
        mkHyperKey {
          fromKey = item.key;
          toKey = item.arrow;
          extraFromModifiers = item.extraFrom;
          toModifiers = item.extraTo;
        }
      ) allNavs;
  };

  # 4. 模块化：应用启动
  launchRules = {
    description = "launch application";
    manipulators =
      map
        (item: {
          type = "basic";
          from = {
            key_code = item.key;
            modifiers.mandatory = hyperModifiers;
          };
          to = [ { shell_command = "open -a '${item.app}'"; } ];
        })
        [
          {
            key = "e";
            app = "Finder";
          }
          {
            key = "g";
            app = "Brave Browser";
          }
          {
            key = "i";
            app = "wezterm";
          }
          {
            key = "y";
            app = "QQMusic";
          }
          {
            key = "s";
            app = "System Preferences";
          }
          {
            key = "u";
            app = mainChat;
          }
          {
            key = "o";
            app = "企业微信";
          }
          {
            key = "n";
            app = "IntelliJ IDEA";
          }
          {
            key = "m";
            app = "Emacs";
          }
          {
            key = "b";
            app = "wpsoffice";
          }
        ];
  };

  # 定义应用 ID 组，方便复用
  apps = {
    browsers = [
      "^com\\.apple\\.Safari$"
      "^com\\.brave\\.Browser$"
      "^org\\.mozilla\\.firefox$"
      "^org\\.mozilla\\.firefoxdeveloperedition$"
      "^com\\.kingsoft\\.wpsoffice\\.mac$"
    ];
    jetbrains = [
      "^com\\.jetbrains\\.intellij$"
      "^com\\.google\\.android\\.studio$"
    ];
    kitty = [ "^net\\.kovidgoyal\\.kitty$" ];
    wezterm = [ "^com\\.github\\.wez\\.wezterm$" ];
    emacs = [ "^org\\.gnu\\.Emacs$" ];
    raycast = [ "^com\\.raycast\\.macos$" ];
    welink = [ "^com\\.huawei\\.cloud\\.welink$" ];
  };

  # ---------------------------------------------------------
  # 新增：Only Specified Application 规则模块
  # ---------------------------------------------------------
  appSpecificRules = {
    description = "Only specified application settings";
    manipulators = builtins.concatLists [
      # 1. Kitty 专用
      (map
        (
          key:
          mkHyperKey {
            fromKey = key;
            toModifiers = [
              "left_control"
              "left_shift"
            ];
            conditions = mkFrontmost apps.kitty;
          }
        )
        [
          "open_bracket"
          "close_bracket"
        ]
      )

      [
        (mkHyperKey {
          fromKey = "open_bracket";
          toKey = "tab";
          toModifiers = [
            "left_control"
            "left_shift"
          ];
          conditions = mkFrontmost apps.wezterm;
        })
        (mkHyperKey {
          fromKey = "close_bracket";
          toKey = "tab";
          toModifiers = [ "left_control" ];
          conditions = mkFrontmost apps.wezterm;
        })
      ]

      # 2. JetBrains / Android Studio 专用
      (map
        (
          key:
          mkHyperKey {
            fromKey = key;
            toModifiers = [
              "left_command"
              "left_shift"
              "right_shift"
            ];
            conditions = mkFrontmost apps.jetbrains;
          }
        )
        [
          "open_bracket"
          "close_bracket"
        ]
      )

      # 3. 浏览器专用 (切换 Tab)
      [
        (mkHyperKey {
          fromKey = "open_bracket";
          toKey = "tab";
          toModifiers = [
            "left_control"
            "left_shift"
          ];
          conditions = mkFrontmost apps.browsers;
        })
        (mkHyperKey {
          fromKey = "close_bracket";
          toKey = "tab";
          toModifiers = [ "left_control" ];
          conditions = mkFrontmost apps.browsers;
        })
      ]

      # 4. Emacs 专用
      [
        (mkHyperKey {
          fromKey = "spacebar";
          toKey = "backslash";
          toModifiers = [ "left_control" ];
          conditions = mkFrontmost apps.emacs;
        })
      ]

      # 5. Raycast 专用
      (map
        (item: {
          type = "basic";
          from = {
            key_code = item.fromKey;
            modifiers.mandatory = [ "left_control" ];
          };
          to = [ { key_code = item.toKey; } ];
          conditions = mkFrontmost apps.raycast;
        })
        [
          {
            fromKey = "u";
            toKey = "page_up";
          }
          {
            fromKey = "d";
            toKey = "page_down";
          }
        ]
      )

      # 6. WeLink 专用
      (map
        (
          key:
          mkHyperKey {
            fromKey = key;
            toModifiers = [
              "left_control"
              "left_option"
              "left_command"
            ];
            conditions = mkFrontmost apps.welink;
          }
        )
        [
          "f"
          "k"
          "j"
        ]
      )
    ];
  };

  baseMapping = {
    description = "base mapping";
    manipulators = [
      # q 的长按映射
      {
        type = "basic";
        from = {
          key_code = "q";
          modifiers = {
            mandatory = [ "left_command" ];
            optional = [ "caps_lock" ];
          };
        };
        to = [ { key_code = "q"; } ];
        to_if_held_down = [
          {
            key_code = "q";
            modifiers = [ "left_command" ];
            repeat = false;
          }
        ];
      }
      {
        type = "basic";
        from = {
          key_code = "t";
          modifiers.mandatory = hyperModifiers;
        };
        to = [
          {
            key_code = "t";
            modifiers = [ "left_command" ];
          }
        ];
      }
    ];
  };

in
{
  home.file.".config/karabiner/assets/complex_modifications/custom.json".text = builtins.toJSON {
    title = "My Custom Config";
    maintainers = [ "DengShilin" ];
    rules = [
      capsLockRule
      baseMapping
      appSpecificRules
      navigationRules
      launchRules
    ];
  };
}
