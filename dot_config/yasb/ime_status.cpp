#include <windows.h>
#include <cstdio> // 改用更轻量底层的 printf

int main() {
    HWND fgWindow = GetForegroundWindow();
    DWORD targetThread = GetWindowThreadProcessId(fgWindow, NULL);
    DWORD currentThread = GetCurrentThreadId();
    HKL hkl = NULL;

    if (targetThread != 0 && targetThread != currentThread) {
        if (AttachThreadInput(currentThread, targetThread, TRUE)) {
            hkl = GetKeyboardLayout(targetThread);
            AttachThreadInput(currentThread, targetThread, FALSE);
        }
    } else {
        hkl = GetKeyboardLayout(0);
    }

    // 提取低 16 位语言代码
    UINT_PTR langId = ((UINT_PTR)hkl) & 0xFFFF;
    const char* text = (langId == 0x0804) ? "\uE982" : "\uE983";

    printf("%s\n", text);
    return 0;
}
