# Windows App (WinUI 3)

This folder contains a WinUI 3 (C#) app scaffold for a native Windows version of Notchy.

## Prereqs (on Windows)
- Visual Studio 2022 (Desktop development with C# + Windows App SDK)
- .NET 8 SDK

## Open / Build
1. Open `windows/NotchyTeleprompterWin/NotchyTeleprompterWin.csproj` in Visual Studio.
2. Restore NuGet packages.
3. Build/Run.

## Notes
- The overlay window is always-on-top and uses `SetWindowDisplayAffinity` to exclude it from capture.
- The editor window is the main app window.
- Some implementation details are stubbed and should be expanded to match the macOS feature set.
