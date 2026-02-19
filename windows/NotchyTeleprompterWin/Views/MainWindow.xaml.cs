using Microsoft.UI.Xaml;
using NotchyTeleprompterWin.Services;

namespace NotchyTeleprompterWin.Views;

public sealed partial class MainWindow : Window
{
    public AppStateController Controller { get; }

    public MainWindow(AppStateController controller)
    {
        Controller = controller;
        InitializeComponent();
    }

    private void OnTogglePlayback(object sender, RoutedEventArgs e)
    {
        Controller.TogglePlayback();
    }

    private void OnReset(object sender, RoutedEventArgs e)
    {
        Controller.ResetOffset();
    }
}
