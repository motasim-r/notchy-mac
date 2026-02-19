# Windows App (WinUI 3)

This folder contains a WinUI 3 (C#) app scaffold for a native Windows version of Notchy.

## Prereqs (on Windows)
- Visual Studio 2022 (Desktop development with C# + Windows App SDK)
- .NET 8 SDK

## Open / Build
1. Open `/Users/nirob/Nirob/projects/notchy-mac/windows/NotchyTeleprompterWin/NotchyTeleprompterWin.csproj` in Visual Studio.
2. Restore NuGet packages.
3. Build/Run.

## Create an installable MSIX (recommended)
1. Open `/Users/nirob/Nirob/projects/notchy-mac/windows/NotchyTeleprompterWin.Package/NotchyTeleprompterWin.Package.wapproj` in Visual Studio.
2. Right-click the packaging project → `Publish` → `Create App Packages`.
3. Choose `Sideloading` for internal builds.
4. VS will prompt you to create/select a certificate. The certificate **Publisher** must match `Package.appxmanifest`.

### Update identity + publisher (required before distribution)
Update these files to match your real publisher identity:
- `/Users/nirob/Nirob/projects/notchy-mac/windows/NotchyTeleprompterWin.Package/Package.appxmanifest`
  - `Identity Name` and `Publisher` (CN must match your signing certificate)
- `/Users/nirob/Nirob/projects/notchy-mac/windows/NotchyTeleprompterWin.Package/NotchyTeleprompterWin.appinstaller`
  - `Publisher`, `Version`, and `Uri`
- `/Users/nirob/Nirob/projects/notchy-mac/windows/NotchyTeleprompterWin.Package/NotchyTeleprompterWin.Package.wapproj`
  - `AppInstallerUri`

## App Installer (.appinstaller)
A starter file is in:
`/Users/nirob/Nirob/projects/notchy-mac/windows/NotchyTeleprompterWin.Package/NotchyTeleprompterWin.appinstaller`

Host the `.appinstaller` and `.msix` on HTTPS and update the `Uri` values.

## Icons
Custom Notchy icons are included in:
`/Users/nirob/Nirob/projects/notchy-mac/windows/NotchyTeleprompterWin.Package/Assets`

## Portable EXE (no installer)
```powershell
dotnet publish -c Release -r win-x64 --self-contained true
```

## Notes
- The overlay window is always-on-top and uses `SetWindowDisplayAffinity` to exclude it from capture.
- Global hotkeys: Ctrl + Shift + Space (play/pause), Left/Right (speed -2/+2), Up/Down (move one line).
