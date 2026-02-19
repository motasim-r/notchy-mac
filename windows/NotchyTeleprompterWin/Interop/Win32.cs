using System.Runtime.InteropServices;

namespace NotchyTeleprompterWin.Interop;

internal static class Win32
{
    internal const uint WDA_NONE = 0x0;
    internal const uint WDA_EXCLUDEFROMCAPTURE = 0x11;
    internal const int GWL_WNDPROC = -4;
    internal const int WM_HOTKEY = 0x0312;
    internal const uint MOD_ALT = 0x0001;
    internal const uint MOD_CONTROL = 0x0002;
    internal const uint MOD_SHIFT = 0x0004;
    internal const uint MOD_NOREPEAT = 0x4000;
    internal const uint VK_SPACE = 0x20;
    internal const uint VK_LEFT = 0x25;
    internal const uint VK_UP = 0x26;
    internal const uint VK_RIGHT = 0x27;
    internal const uint VK_DOWN = 0x28;

    internal delegate nint WndProc(nint hWnd, uint msg, nint wParam, nint lParam);

    [DllImport("user32.dll")]
    internal static extern bool SetWindowDisplayAffinity(nint hWnd, uint dwAffinity);

    [DllImport("user32.dll", SetLastError = true)]
    internal static extern bool RegisterHotKey(nint hWnd, int id, uint fsModifiers, uint vk);

    [DllImport("user32.dll", SetLastError = true)]
    internal static extern bool UnregisterHotKey(nint hWnd, int id);

    [DllImport("user32.dll", EntryPoint = "SetWindowLongPtrW")]
    private static extern nint SetWindowLongPtr64(nint hWnd, int nIndex, nint dwNewLong);

    [DllImport("user32.dll", EntryPoint = "SetWindowLongW")]
    private static extern int SetWindowLong32(nint hWnd, int nIndex, int dwNewLong);

    [DllImport("user32.dll", EntryPoint = "CallWindowProcW")]
    internal static extern nint CallWindowProc(nint lpPrevWndFunc, nint hWnd, uint msg, nint wParam, nint lParam);

    internal static nint SetWindowLongPtr(nint hWnd, int nIndex, nint dwNewLong)
    {
        if (IntPtr.Size == 8)
        {
            return SetWindowLongPtr64(hWnd, nIndex, dwNewLong);
        }

        return new nint(SetWindowLong32(hWnd, nIndex, dwNewLong.ToInt32()));
    }
}
