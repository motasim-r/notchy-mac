using Microsoft.UI.Xaml;
using NotchyTeleprompterWin.Services;
using NotchyTeleprompterWin.Views;

namespace NotchyTeleprompterWin;

public partial class App : Application
{
    private Window? _editorWindow;
    private OverlayWindow? _overlayWindow;
    private readonly AppStateController _controller = new();

    public App()
    {
        InitializeComponent();
    }

    protected override void OnLaunched(Microsoft.UI.Xaml.LaunchActivatedEventArgs args)
    {
        _editorWindow = new MainWindow(_controller);
        _editorWindow.Activate();

        _overlayWindow = new OverlayWindow(_controller);
        _overlayWindow.Activate();
    }
}
