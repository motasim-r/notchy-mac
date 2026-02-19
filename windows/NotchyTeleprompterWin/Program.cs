using Microsoft.UI.Xaml;
using WinRT;

namespace NotchyTeleprompterWin;

public static class Program
{
    [STAThread]
    public static void Main(string[] args)
    {
        ComWrappersSupport.InitializeComWrappers();
        Application.Start(_ =>
        {
            _ = new App();
        });
    }
}
