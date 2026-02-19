using Microsoft.UI;
using Microsoft.UI.Windowing;
using Microsoft.UI.Xaml;
using NotchyTeleprompterWin.Interop;
using NotchyTeleprompterWin.Services;
using Windows.Graphics;
using WinRT.Interop;

namespace NotchyTeleprompterWin.Views;

public sealed partial class OverlayWindow : Window
{
    public AppStateController Controller { get; }
    private AppWindow? _appWindow;

    public OverlayWindow(AppStateController controller)
    {
        Controller = controller;
        InitializeComponent();

        ExtendsContentIntoTitleBar = true;
        SetTitleBar(null);

        Loaded += (_, _) =>
        {
            InitializeWindow();
            ApplyOverlaySizeAndPosition();
            ApplyCaptureExclusion();
        };

        Controller.PropertyChanged += (_, e) =>
        {
            if (e.PropertyName is nameof(AppStateController.OverlayWidth)
                or nameof(AppStateController.OverlayHeight)
                or nameof(AppStateController.OverlayVerticalOffsetPx))
            {
                ApplyOverlaySizeAndPosition();
            }
            else if (e.PropertyName == nameof(AppStateController.ExcludeFromCapture))
            {
                ApplyCaptureExclusion();
            }
        };
    }

    private void InitializeWindow()
    {
        var hwnd = WindowNative.GetWindowHandle(this);
        var windowId = Win32Interop.GetWindowIdFromWindow(hwnd);
        _appWindow = AppWindow.GetFromWindowId(windowId);

        _appWindow.SetPresenter(AppWindowPresenterKind.Overlapped);
        if (_appWindow.Presenter is OverlappedPresenter presenter)
        {
            presenter.IsAlwaysOnTop = true;
            presenter.IsResizable = false;
            presenter.IsMinimizable = false;
            presenter.IsMaximizable = false;
            presenter.SetBorderAndTitleBar(false, false);
        }
    }

    private void ApplyOverlaySizeAndPosition()
    {
        if (_appWindow == null) return;

        var width = (int)Math.Round(Controller.OverlayWidth);
        var height = (int)Math.Round(Controller.OverlayHeight);
        _appWindow.Resize(new SizeInt32(Math.Max(200, width), Math.Max(90, height)));

        var display = DisplayArea.GetFromWindowId(_appWindow.Id, DisplayAreaFallback.Primary);
        var work = display.WorkArea;
        var x = work.X + (work.Width / 2) - (width / 2);
        var y = work.Y + 4 + (int)Math.Round(Controller.OverlayVerticalOffsetPx);
        _appWindow.Move(new PointInt32(x, y));
    }

    private void ApplyCaptureExclusion()
    {
        var hwnd = WindowNative.GetWindowHandle(this);
        var affinity = Controller.ExcludeFromCapture ? Win32.WDA_EXCLUDEFROMCAPTURE : Win32.WDA_NONE;
        Win32.SetWindowDisplayAffinity(hwnd, affinity);
    }

    private void OnViewportSizeChanged(object sender, SizeChangedEventArgs e)
    {
        UpdateScrollBounds();
    }

    private void OnScriptSizeChanged(object sender, SizeChangedEventArgs e)
    {
        UpdateScrollBounds();
    }

    private void UpdateScrollBounds()
    {
        var contentHeight = ScriptText.ActualHeight;
        var viewportHeight = Viewport.ActualHeight;
        Controller.UpdateScrollBounds(contentHeight, viewportHeight);
    }
}
