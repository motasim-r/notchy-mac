using System.ComponentModel;
using System.Runtime.CompilerServices;
using Microsoft.UI.Xaml;
using NotchyTeleprompterWin.Models;

namespace NotchyTeleprompterWin.Services;

public sealed class AppStateController : INotifyPropertyChanged
{
    private readonly StateStore _stateStore = new();
    private readonly DispatcherTimer _tickTimer;
    private TeleprompterState _state;
    private double _maxOffsetPx;
    private int _offsetPersistCounter;
    private CancellationTokenSource? _saveCts;

    private DispatcherTimer? _stepResumeTimer;
    private bool _shouldResumeAfterStep;
    private const double StepPauseSeconds = 0.35;

    public AppStateController()
    {
        _state = (_stateStore.Load() ?? TeleprompterState.Default).Clamp();
        _tickTimer = new DispatcherTimer
        {
            Interval = TimeSpan.FromMilliseconds(16)
        };
        _tickTimer.Tick += (_, _) => HandleTick(0.016);
        SyncTicker();
    }

    public event PropertyChangedEventHandler? PropertyChanged;

    public string ScriptText
    {
        get => _state.ScriptText;
        set
        {
            if (_state.ScriptText == value) return;
            _state.ScriptText = value;
            OnPropertyChanged();
            SaveSoon();
        }
    }

    public bool IsPlaying
    {
        get => _state.Playback.IsPlaying;
        set
        {
            if (_state.Playback.IsPlaying == value) return;
            CancelStepResume();
            _state.Playback.IsPlaying = value;
            OnPropertyChanged();
            OnPropertyChanged(nameof(PlayPauseLabel));
            SyncTicker();
            SaveSoon();
        }
    }

    public string PlayPauseLabel => IsPlaying ? "Pause" : "Play";

    public double SpeedPxPerSec
    {
        get => _state.Playback.SpeedPxPerSec;
        set
        {
            if (Math.Abs(_state.Playback.SpeedPxPerSec - value) < 0.01) return;
            _state.Playback.SpeedPxPerSec = value;
            OnPropertyChanged();
            SaveSoon();
        }
    }

    public double OffsetPx
    {
        get => _state.Playback.OffsetPx;
        private set
        {
            if (Math.Abs(_state.Playback.OffsetPx - value) < 0.01) return;
            _state.Playback.OffsetPx = value;
            OnPropertyChanged();
            OnPropertyChanged(nameof(OverlayOffsetY));
        }
    }

    public double OverlayOffsetY => -OffsetPx;

    public double OverlayWidth
    {
        get => _state.Overlay.Width;
        set
        {
            if (Math.Abs(_state.Overlay.Width - value) < 0.01) return;
            _state.Overlay.Width = value;
            OnPropertyChanged();
            SaveSoon();
        }
    }

    public double OverlayHeight
    {
        get => _state.Overlay.Height;
        set
        {
            if (Math.Abs(_state.Overlay.Height - value) < 0.01) return;
            _state.Overlay.Height = value;
            OnPropertyChanged();
            SaveSoon();
        }
    }

    public double OverlayVerticalOffsetPx
    {
        get => _state.Overlay.VerticalOffsetPx;
        set
        {
            if (Math.Abs(_state.Overlay.VerticalOffsetPx - value) < 0.01) return;
            _state.Overlay.VerticalOffsetPx = value;
            OnPropertyChanged();
            SaveSoon();
        }
    }

    public double FontSizePx
    {
        get => _state.Overlay.FontSizePx;
        set
        {
            if (Math.Abs(_state.Overlay.FontSizePx - value) < 0.01) return;
            _state.Overlay.FontSizePx = value;
            OnPropertyChanged();
            OnPropertyChanged(nameof(LineHeightPx));
            OnPropertyChanged(nameof(CharacterSpacing));
            SaveSoon();
        }
    }

    public double LineHeight
    {
        get => _state.Overlay.LineHeight;
        set
        {
            if (Math.Abs(_state.Overlay.LineHeight - value) < 0.001) return;
            _state.Overlay.LineHeight = value;
            OnPropertyChanged();
            OnPropertyChanged(nameof(LineHeightPx));
            SaveSoon();
        }
    }

    public double LetterSpacingPx
    {
        get => _state.Overlay.LetterSpacingPx;
        set
        {
            if (Math.Abs(_state.Overlay.LetterSpacingPx - value) < 0.01) return;
            _state.Overlay.LetterSpacingPx = value;
            OnPropertyChanged();
            OnPropertyChanged(nameof(CharacterSpacing));
            SaveSoon();
        }
    }

    public double LineHeightPx => FontSizePx * LineHeight;

    public int CharacterSpacing
    {
        get
        {
            if (FontSizePx <= 0.1) return 0;
            return (int)Math.Round((LetterSpacingPx / FontSizePx) * 1000);
        }
    }

    public bool OverlayVisible
    {
        get => _state.Overlay.Visible;
        set
        {
            if (_state.Overlay.Visible == value) return;
            _state.Overlay.Visible = value;
            OnPropertyChanged();
            OnPropertyChanged(nameof(OverlayOpacity));
            SaveSoon();
        }
    }

    public double OverlayOpacity => OverlayVisible ? 1 : 0;

    public bool ExcludeFromCapture
    {
        get => _state.Overlay.ExcludeFromCapture;
        set
        {
            if (_state.Overlay.ExcludeFromCapture == value) return;
            _state.Overlay.ExcludeFromCapture = value;
            OnPropertyChanged();
            SaveSoon();
        }
    }

    public void TogglePlayback()
    {
        CancelStepResume();
        if (!IsPlaying && _maxOffsetPx > 0 && OffsetPx >= _maxOffsetPx)
        {
            OffsetPx = 0;
        }
        IsPlaying = !IsPlaying;
    }

    public void ResetOffset()
    {
        CancelStepResume();
        OffsetPx = 0;
        IsPlaying = false;
        SaveSoon();
    }

    public void AdjustSpeed(double delta)
    {
        SpeedPxPerSec = _state.Playback.SpeedPxPerSec + delta;
    }

    public void StepScript(int direction)
    {
        var wasPlaying = IsPlaying;
        var stepPx = Math.Max(8, _state.Overlay.FontSizePx * _state.Overlay.LineHeight);
        var nextOffset = OffsetPx + (direction > 0 ? stepPx : -stepPx);
        OffsetPx = Math.Min(_maxOffsetPx, Math.Max(0, nextOffset));
        if (wasPlaying)
        {
            IsPlaying = false;
            ScheduleStepResume();
        }
        SaveSoon();
    }

    public void ScrollScript(double deltaPx)
    {
        if (Math.Abs(deltaPx) < 0.01) return;
        ResumeIfPausedForStep();
        OffsetPx = Math.Min(_maxOffsetPx, Math.Max(0, OffsetPx + deltaPx));
        SaveSoon();
    }

    public void UpdateScrollBounds(double contentHeight, double viewportHeight)
    {
        _maxOffsetPx = Math.Max(0, contentHeight - viewportHeight);
        if (OffsetPx > _maxOffsetPx)
        {
            OffsetPx = _maxOffsetPx;
            if (_maxOffsetPx == 0)
            {
                IsPlaying = false;
            }
        }
    }

    private void HandleTick(double deltaSeconds)
    {
        if (!IsPlaying) return;
        var nextOffset = OffsetPx + SpeedPxPerSec * deltaSeconds;
        var reachedEnd = _maxOffsetPx > 0 && nextOffset >= _maxOffsetPx;
        OffsetPx = Math.Min(_maxOffsetPx, nextOffset);
        if (reachedEnd)
        {
            IsPlaying = false;
        }

        _offsetPersistCounter++;
        if (reachedEnd || _offsetPersistCounter >= 18)
        {
            _offsetPersistCounter = 0;
            SaveNow();
        }
    }

    private void SyncTicker()
    {
        if (IsPlaying)
        {
            if (!_tickTimer.IsEnabled) _tickTimer.Start();
        }
        else
        {
            if (_tickTimer.IsEnabled) _tickTimer.Stop();
        }
    }

    private void SaveSoon()
    {
        _saveCts?.Cancel();
        var cts = new CancellationTokenSource();
        _saveCts = cts;
        _ = Task.Run(async () =>
        {
            try
            {
                await Task.Delay(200, cts.Token);
                if (!cts.IsCancellationRequested)
                {
                    SaveNow();
                }
            }
            catch (TaskCanceledException)
            {
            }
        });
    }

    private void SaveNow()
    {
        try
        {
            _stateStore.Save(_state);
        }
        catch
        {
            // Ignore persistence errors for now.
        }
    }

    private void ScheduleStepResume()
    {
        _stepResumeTimer?.Stop();
        _shouldResumeAfterStep = true;

        var timer = new DispatcherTimer { Interval = TimeSpan.FromSeconds(StepPauseSeconds) };
        timer.Tick += (_, _) =>
        {
            timer.Stop();
            if (!_shouldResumeAfterStep) return;
            _shouldResumeAfterStep = false;
            if (!IsPlaying)
            {
                IsPlaying = true;
            }
        };
        _stepResumeTimer = timer;
        timer.Start();
    }

    private void CancelStepResume()
    {
        _shouldResumeAfterStep = false;
        if (_stepResumeTimer != null)
        {
            _stepResumeTimer.Stop();
            _stepResumeTimer = null;
        }
    }

    private void ResumeIfPausedForStep()
    {
        if (!_shouldResumeAfterStep) return;
        CancelStepResume();
        if (!IsPlaying)
        {
            IsPlaying = true;
        }
    }

    private void OnPropertyChanged([CallerMemberName] string? name = null)
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
    }
}
