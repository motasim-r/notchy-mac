using Microsoft.UI.Xaml;
using NotchyTeleprompterWin.Services;
using WinRT.Interop;

namespace NotchyTeleprompterWin.Views;

public sealed partial class MainWindow : Window
{
    public AppStateController Controller { get; }
    private GlobalHotkeyManager? _hotkeys;

    public MainWindow(AppStateController controller)
    {
        Controller = controller;
        InitializeComponent();

        Loaded += (_, _) =>
        {
            var hwnd = WindowNative.GetWindowHandle(this);
            _hotkeys = new GlobalHotkeyManager(hwnd, Controller);
        };

        Closed += (_, _) =>
        {
            _hotkeys?.Dispose();
            _hotkeys = null;
        };
    }

    private void OnTogglePlayback(object sender, RoutedEventArgs e)
    {
        Controller.TogglePlayback();
    }

    private void OnReset(object sender, RoutedEventArgs e)
    {
        Controller.ResetOffset();
    }

    private void OnResetSettings(object sender, RoutedEventArgs e)
    {
        Controller.ResetSettingsKeepingScript();
    }
}
