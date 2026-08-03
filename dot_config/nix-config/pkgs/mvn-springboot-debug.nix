{ pkgs }:

# 高版本 JDK 默认开启了严格的模块封装（Strong Encapsulation），不再允许外部库（如 HotswapAgent）通过反射随意读取 java.base 模块下的 JVM 内部私有属性，因此抛出了 InaccessibleObjectException。
# 告诉 JVM 放开对 sun.nio.ch 的反射限制。 --add-opens=java.base/sun.nio.ch=ALL-UNNAMED

pkgs.writeShellScriptBin "mvn-springboot-debug" ''
  USE_HOTSWAP=true
  if [ "$ENABLE_HOTSWAP" = "false" ] || [ "$DISABLE_HOTSWAP" = "1" ] || [ "$NO_HOTSWAP" = "1" ]; then
    USE_HOTSWAP=false
  fi

  POSITIONAL_ARGS=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-hotswap|--disable-hotswap|--without-hotswap|--no-agent|-nh)
        USE_HOTSWAP=false
        shift
        ;;
      --hotswap|--enable-hotswap)
        USE_HOTSWAP=true
        shift
        ;;
      *)
        POSITIONAL_ARGS+=("$1")
        shift
        ;;
    esac
  done

  EXTRA_ARGS=()
  if [ ''${#POSITIONAL_ARGS[@]} -gt 0 ]; then
    if [[ "''${POSITIONAL_ARGS[0]}" != -* ]]; then
      EXTRA_ARGS+=("-pl" "''${POSITIONAL_ARGS[0]}")
      EXTRA_ARGS+=("''${POSITIONAL_ARGS[@]:1}")
    else
      EXTRA_ARGS+=("''${POSITIONAL_ARGS[@]}")
    fi
  fi

  JVM_OPTS=()
  if [ "$USE_HOTSWAP" = true ]; then
    HOTSWAP_DIR="$HOME/.config/emacs/.cache"
    HOTSWAP_JAR="$HOTSWAP_DIR/hotswap-agent.jar"

    if [ ! -f "$HOTSWAP_JAR" ]; then
      echo "HotswapAgent JAR not found at $HOTSWAP_JAR. Downloading..."
      mkdir -p "$HOTSWAP_DIR"
      ${pkgs.curl}/bin/curl -L -o "$HOTSWAP_JAR" "https://github.com/HotswapProjects/HotswapAgent/releases/download/RELEASE-2.0.3/hotswap-agent-2.0.3.jar"
      if [ $? -ne 0 ]; then
        echo "Error: Failed to download HotswapAgent JAR." >&2
        exit 1
      fi
      echo "HotswapAgent JAR downloaded successfully."
    fi

    JVM_OPTS+=("-XX:+AllowEnhancedClassRedefinition" "-javaagent:$HOTSWAP_JAR")
  else
    echo "HotswapAgent is disabled."
  fi

  JVM_OPTS+=(
    "-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005"
    "-Xms512m -Xmx2g -XX:MetaspaceSize=256m -XX:MaxMetaspaceSize=1024m"
    "-XX:ReservedCodeCacheSize=512m -XX:+UseCodeCacheFlushing"
    "-XX:+UseG1GC"
    "--add-opens=java.base/sun.nio.ch=ALL-UNNAMED"
    "--add-opens java.base/java.lang=ALL-UNNAMED"
    "--add-opens java.desktop/java.beans=ALL-UNNAMED"
    "--add-opens java.base/java.lang.invoke=ALL-UNNAMED"
    "--add-opens java.base/java.io=ALL-UNNAMED"
    "--add-opens java.base/java.util=ALL-UNNAMED"
    "--add-opens java.base/java.util.concurrent=ALL-UNNAMED"
    "--add-opens java.base/java.math=ALL-UNNAMED"
    "--add-opens java.base/java.net=ALL-UNNAMED"
    "--add-opens java.base/java.text=ALL-UNNAMED"
  )

  MVN_CMD="mvn"
  if [ -f "./mvnw" ]; then
    MVN_CMD="./mvnw"
  fi

  exec $MVN_CMD spring-boot:run "''${EXTRA_ARGS[@]}" -Dspring-boot.run.jvmArguments="''${JVM_OPTS[*]}"
''
