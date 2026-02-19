namespace NotchyTeleprompterWin.Models;

public sealed class TeleprompterState
{
    public string ScriptText { get; set; } = "";
    public PlaybackState Playback { get; set; } = new();
    public OverlayState Overlay { get; set; } = new();

    public static TeleprompterState Default => new()
    {
        ScriptText = "Notchy is a native teleprompter. Paste your script here...",
        Playback = new PlaybackState
        {
            IsPlaying = false,
            SpeedPxPerSec = 20,
            OffsetPx = 0
        },
        Overlay = new OverlayState
        {
            Width = 360,
            Height = 120,
            VerticalOffsetPx = 0,
            FontSizePx = 14,
            LineHeight = 1.06,
            LetterSpacingPx = 0,
            Visible = true,
            ExcludeFromCapture = true
        }
    };

    public TeleprompterState Clamp()
    {
        Playback.SpeedPxPerSec = Clamp(Playback.SpeedPxPerSec, 4, 260);
        Playback.OffsetPx = Math.Max(0, Playback.OffsetPx);

        Overlay.Width = Clamp(Overlay.Width, 220, 1400);
        Overlay.Height = Clamp(Overlay.Height, 90, 600);
        Overlay.VerticalOffsetPx = Clamp(Overlay.VerticalOffsetPx, -70, 220);
        Overlay.FontSizePx = Clamp(Overlay.FontSizePx, 10, 110);
        Overlay.LineHeight = Clamp(Overlay.LineHeight, 1.0, 2.2);
        Overlay.LetterSpacingPx = Clamp(Overlay.LetterSpacingPx, -0.5, 8.0);
        return this;
    }

    private static double Clamp(double value, double min, double max) => Math.Min(max, Math.Max(min, value));
}

public sealed class PlaybackState
{
    public bool IsPlaying { get; set; }
    public double SpeedPxPerSec { get; set; }
    public double OffsetPx { get; set; }
}

public sealed class OverlayState
{
    public double Width { get; set; }
    public double Height { get; set; }
    public double VerticalOffsetPx { get; set; }
    public double FontSizePx { get; set; }
    public double LineHeight { get; set; }
    public double LetterSpacingPx { get; set; }
    public bool Visible { get; set; }
    public bool ExcludeFromCapture { get; set; }
}
