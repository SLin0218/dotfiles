/**
 * zellij-copy.c: 跨平台 Zellij 原地无感复制模式启动器
 *
 * 支持平台：
 *   - Windows (MSVC / MinGW GCC / Clang)
 *   - Linux (GCC / Clang)
 *   - macOS (Clang / GCC)
 *   - FreeBSD / BSD
 *
 * 核心功能：
 *   1. 跨平台自动探测自身可执行文件路径，自适应拼装同级目录下的 copy-mode.lua；
 *   2. 直通底层控制台 TTY 句柄，消除中间脚本封装引起的 ANSI 配色与转义序列失真；
 *   3. Windows 平台通过 CreateProcess 绕过 CMD.EXE，消除 WSL UNC 路径警告；
 *   4. Unix 平台通过 execvp 零开销替换进程，性能极致。
 *
 * 编译命令：
 *   - Windows:  gcc -O2 -s -o zellij-copy.exe zellij-copy.c
 *   - Linux:    gcc -O2 -s -o zellij-copy zellij-copy.c
 *   - macOS:    clang -O2 -o zellij-copy zellij-copy.c
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if defined(_WIN32)
    #include <windows.h>
    #define PATH_SEP '\\'
    #define PATH_SEP_STR "\\"
#else
    #include <unistd.h>
    #include <limits.h>
    #include <sys/wait.h>
    #define PATH_SEP '/'
    #define PATH_SEP_STR "/"
    #if defined(__APPLE__)
        #include <mach-o/dyld.h>
    #endif
#endif

#ifndef PATH_MAX
    #define PATH_MAX 4096
#endif

// 获取当前可执行程序所在目录（包含末尾路径分隔符）
static void get_executable_dir(char *dir_buf, size_t buf_size, const char *fallback_argv0) {
    dir_buf[0] = '\0';

#if defined(_WIN32)
    char path[MAX_PATH];
    DWORD len = GetModuleFileNameA(NULL, path, sizeof(path));
    if (len > 0 && len < sizeof(path)) {
        char *slash1 = strrchr(path, '\\');
        char *slash2 = strrchr(path, '/');
        char *slash = (slash1 > slash2) ? slash1 : slash2;
        if (slash) {
            *(slash + 1) = '\0';
            snprintf(dir_buf, buf_size, "%s", path);
            return;
        }
    }

#elif defined(__APPLE__)
    char path[PATH_MAX];
    uint32_t size = sizeof(path);
    if (_NSGetExecutablePath(path, &size) == 0) {
        char resolved[PATH_MAX];
        if (realpath(path, resolved)) {
            char *slash = strrchr(resolved, '/');
            if (slash) {
                *(slash + 1) = '\0';
                snprintf(dir_buf, buf_size, "%s", resolved);
                return;
            }
        }
    }

#elif defined(__linux__)
    char path[PATH_MAX];
    ssize_t len = readlink("/proc/self/exe", path, sizeof(path) - 1);
    if (len != -1) {
        path[len] = '\0';
        char *slash = strrchr(path, '/');
        if (slash) {
            *(slash + 1) = '\0';
            snprintf(dir_buf, buf_size, "%s", path);
            return;
        }
    }
#endif

    // 通用降级方案（通过 argv[0] 获取）
    if (fallback_argv0 && strlen(fallback_argv0) > 0) {
#if !defined(_WIN32)
        char resolved[PATH_MAX];
        if (realpath(fallback_argv0, resolved)) {
            char *slash = strrchr(resolved, '/');
            if (slash) {
                *(slash + 1) = '\0';
                snprintf(dir_buf, buf_size, "%s", resolved);
                return;
            }
        }
#endif
        const char *slash1 = strrchr(fallback_argv0, '\\');
        const char *slash2 = strrchr(fallback_argv0, '/');
        const char *slash = (slash1 > slash2) ? slash1 : slash2;
        if (slash) {
            size_t prefix_len = (size_t)(slash - fallback_argv0 + 1);
            if (prefix_len < buf_size) {
                memcpy(dir_buf, fallback_argv0, prefix_len);
                dir_buf[prefix_len] = '\0';
                return;
            }
        }
    }

    // 默认当前目录
    snprintf(dir_buf, buf_size, ".%s", PATH_SEP_STR);
}

int main(int argc, char *argv[]) {
    char dir[PATH_MAX];
    get_executable_dir(dir, sizeof(dir), (argc > 0) ? argv[0] : NULL);

    char lua_path[PATH_MAX];
    snprintf(lua_path, sizeof(lua_path), "%scopy-mode.lua", dir);

#if defined(_WIN32)
    // Windows: 构建 CreateProcess 命令行并直通控制台句柄
    char cmd[8192];
    char target[4096] = "";
    if (argc > 1 && argv[1]) {
        snprintf(target, sizeof(target), "\"%s\"", argv[1]);
    }
    snprintf(cmd, sizeof(cmd), "nvim.exe --clean -u \"%s\" %s", lua_path, target);

    STARTUPINFO si;
    PROCESS_INFORMATION pi;
    ZeroMemory(&si, sizeof(si));
    si.cb = sizeof(si);
    si.hStdInput  = GetStdHandle(STD_INPUT_HANDLE);
    si.hStdOutput = GetStdHandle(STD_OUTPUT_HANDLE);
    si.hStdError  = GetStdHandle(STD_ERROR_HANDLE);
    si.dwFlags   |= STARTF_USESTDHANDLES;
    ZeroMemory(&pi, sizeof(pi));

    if (CreateProcessA(NULL, cmd, NULL, NULL, TRUE, 0, NULL, NULL, &si, &pi)) {
        WaitForSingleObject(pi.hProcess, INFINITE);
        DWORD exitCode = 0;
        GetExitCodeProcess(pi.hProcess, &exitCode);
        CloseHandle(pi.hProcess);
        CloseHandle(pi.hThread);
        // 保证在退出复制模式后，Zellij 状态栏恢复为 normal 模式
        system("zellij.exe action switch-mode normal");
        return (int)exitCode;
    }

    return 1;

#else
    // Linux / macOS / POSIX: fork + waitpid，退出后恢复 Zellij normal 模式
    pid_t pid = fork();
    if (pid < 0) {
        perror("fork failed");
        return 1;
    }

    if (pid == 0) {
        int total_args = 4 + (argc > 1 ? (argc - 1) : 0) + 1;
        char **nargs = (char **)malloc(sizeof(char *) * total_args);
        if (!nargs) exit(1);

        int idx = 0;
        nargs[idx++] = "nvim";
        nargs[idx++] = "--clean";
        nargs[idx++] = "-u";
        nargs[idx++] = lua_path;

        for (int i = 1; i < argc; i++) {
            nargs[idx++] = argv[i];
        }
        nargs[idx] = NULL;

        execvp("nvim", nargs);
        perror("execvp nvim failed");
        free(nargs);
        exit(1);
    } else {
        int status = 0;
        waitpid(pid, &status, 0);
        system("zellij action switch-mode normal");
        return WEXITSTATUS(status);
    }
#endif
}
