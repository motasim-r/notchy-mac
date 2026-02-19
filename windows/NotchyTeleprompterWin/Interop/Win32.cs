using System.Runtime.InteropServices;

namespace NotchyTeleprompterWin.Interop;

internal static class Win32
{
    internal const uint WDA_NONE = 0x0;
    internal const uint WDA_EXCLUDEFROMCAPTURE = 0x11;

    [DllImport("user32.dll")]
    internal static extern bool SetWindowDisplayAffinity(nint hWnd, uint dwAffinity);
}
