using System.Text.Json;
using NotchyTeleprompterWin.Models;

namespace NotchyTeleprompterWin.Services;

public sealed class StateStore
{
    private readonly string _path;
    private readonly JsonSerializerOptions _options = new()
    {
        WriteIndented = true
    };

    public StateStore()
    {
        var root = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
        var folder = Path.Combine(root, "NotchyTeleprompterWin");
        Directory.CreateDirectory(folder);
        _path = Path.Combine(folder, "state.json");
    }

    public TeleprompterState? Load()
    {
        if (!File.Exists(_path))
        {
            return null;
        }

        var json = File.ReadAllText(_path);
        var state = JsonSerializer.Deserialize<TeleprompterState>(json, _options);
        return state;
    }

    public void Save(TeleprompterState state)
    {
        var json = JsonSerializer.Serialize(state, _options);
        File.WriteAllText(_path, json);
    }
}
