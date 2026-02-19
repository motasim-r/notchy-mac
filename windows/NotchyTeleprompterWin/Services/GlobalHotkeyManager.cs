using System.Runtime.InteropServices;
using NotchyTeleprompterWin.Interop;

namespace NotchyTeleprompterWin.Services;

public sealed class GlobalHotkeyManager : IDisposable
{
    private const int HotkeyPlayPause = 1;
    private const int HotkeySpeedDown = 2;
    private const int HotkeySpeedUp = 3;
    private const int HotkeyStepUp = 4;
    private const int HotkeyStepDown = 5;

    private readonly nint _hwnd;
    private readonly AppStateController _controller;
    private readonly Win32.WndProc _wndProc;
    private nint _prevWndProc;
    private bool _registered;

    public GlobalHotkeyManager(nint hwnd, AppStateController controller)
    {
        _hwnd = hwnd;
        _controller = controller;
        _wndProc = WndProc;

        var procPtr = Marshal.GetFunctionPointerForDelegate(_wndProc);
        _prevWndProc = Win32.SetWindowLongPtr(hwnd, Win32.GWL_WNDPROC, procPtr);

        RegisterAll();
    }

    public void Dispose()
    {
        UnregisterAll();
        if (_prevWndProc != 0)
        {
            Win32.SetWindowLongPtr(_hwnd, Win32.GWL_WNDPROC, _prevWndProc);
            _prevWndProc = 0;
        }
        GC.SuppressFinalize(this);
    }

    private void RegisterAll()
    {
        var modifiers = Win32.MOD_CONTROL | Win32.MOD_SHIFT | Win32.MOD_NOREPEAT;
        _registered = true;

        _registered &= Win32.RegisterHotKey(_hwnd, HotkeyPlayPause, modifiers, Win32.VK_SPACE);
        _registered &= Win32.RegisterHotKey(_hwnd, HotkeySpeedDown, modifiers, Win32.VK_LEFT);
        _registered &= Win32.RegisterHotKey(_hwnd, HotkeySpeedUp, modifiers, Win32.VK_RIGHT);
        _registered &= Win32.RegisterHotKey(_hwnd, HotkeyStepUp, modifiers, Win32.VK_UP);
        _registered &= Win32.RegisterHotKey(_hwnd, HotkeyStepDown, modifiers, Win32.VK_DOWN);
    }

    private void UnregisterAll()
    {
        Win32.UnregisterHotKey(_hwnd, HotkeyPlayPause);
        Win32.UnregisterHotKey(_hwnd, HotkeySpeedDown);
        Win32.UnregisterHotKey(_hwnd, HotkeySpeedUp);
        Win32.UnregisterHotKey(_hwnd, HotkeyStepUp);
        Win32.UnregisterHotKey(_hwnd, HotkeyStepDown);
        _registered = false;
    }

    private nint WndProc(nint hWnd, uint msg, nint wParam, nint lParam)
    {
        if (msg == Win32.WM_HOTKEY)
        {
            HandleHotkey((int)wParam);
            return 0;
        }

        return Win32.CallWindowProc(_prevWndProc, hWnd, msg, wParam, lParam);
    }

    private void HandleHotkey(int id)
    {
        switch (id)
        {
            case HotkeyPlayPause:
                _controller.TogglePlayback();
                break;
            case HotkeySpeedDown:
                _controller.AdjustSpeed(-2);
                break;
            case HotkeySpeedUp:
                _controller.AdjustSpeed(2);
                break;
            case HotkeyStepUp:
                _controller.StepScript(-1);
                break;
            case HotkeyStepDown:
                _controller.StepScript(1);
                break;
        }
    }
}
