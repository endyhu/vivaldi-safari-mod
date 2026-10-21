# vivaldi-safari-mod

A CSS mod that restyles [Vivaldi](https://vivaldi.com)'s interface after Safari 27 on
macOS: a centered address bar, centered favorites, and a Safari-style tab bar below
them.

Built and tested on Vivaldi 8.2.4133.89 on Windows 11. The CSS should work on any
platform; the optional tab-drag patch is Windows-only.

## Features

- **Centered address bar**: the field is centered on the window (40% of its width,
  up to 800px), and its URL text is centered in the field.
- **Centered bookmark bar**, as Safari's favorites bar.
- **Separate-style tab bar**: below the bookmark bar, flush with the window edges.
- **Equal-width tabs** that fill the bar, with centered titles, joined with square
  corners and hairline separators, and rounded again on hover.
- **Tab details**: close button on the leading edge on hover, audio button after the
  title, alert badge on the favicon's corner. Pinned tabs keep Vivaldi's own size.
- **Tab bar hidden with a single tab**, as in Safari.
- **Square page corners.**

## Install

1. Open `vivaldi://experiments` and enable **Allow for using CSS modifications**.
2. Clone or download this repository.
3. In **Settings → Appearance → Custom UI Modifications**, select the repository
   folder (the one containing `safari.css`).
4. Change the settings below, then restart Vivaldi. Vivaldi reads the CSS only at
   startup.

### Required settings

| Setting | Value |
| --- | --- |
| Settings → Tabs → Tab Bar Position | **Bottom** (the CSS moves it below the bookmark bar) |
| Settings → Address Bar → Address Bar Position | **Top** |
| Settings → Bookmarks → Bookmark Bar Position | **Top** |

Leave these **off**, since the CSS handles them itself:

- Settings → Tabs → **Display Close Button → On Left Side** (it would replace the favicon)
- Settings → Tabs → **Remove Tab Spacing in Maximized Windows**

## Tab dragging patch (optional, Windows)

Vivaldi positions tabs in its own model of fixed 180px tabs, which CSS can't change.
With the equal-width tabs, dragging a tab drops it in the wrong slot. `safari-drag.js`
fixes this by translating the cursor into Vivaldi's model while a tab is held.

Vivaldi can't load JavaScript from the mods folder, so the script has to be added to
Vivaldi's own `window.html`. To install it, double-click **`install-drag.bat`**
(requires [PowerShell 7](https://aka.ms/powershell)), then restart Vivaldi.

A Vivaldi update installs a fresh copy without the patch. Run the script again after
updating, or have it re-apply itself automatically:

```powershell
.\tools\install-drag.ps1 -Register             # also re-apply at logon and every 15 minutes
.\tools\install-drag.ps1 -Remove -Unregister   # undo the patch and remove the task
```

The script patches the per-user install in `%LOCALAPPDATA%\Vivaldi\Application`.
For a system-wide install, pass `-ApplicationDir` and run it as administrator.

## Known limitations

- The address field overlaps the left toolbar buttons in windows narrower than about
  500px.
- The URL text is centered between the field's icons, so it can sit a few pixels
  off the field's exact center.
- The drag patch depends on Vivaldi internals and may break after a Vivaldi update.
  It supports horizontal tab bars only.
- With the patch, a drag starts after a slightly longer movement than usual, and the
  image shown while pulling a tab out into a new window is the full tab width.
- Vivaldi's compact tab styles (`tab-small`, `tab-mini`) don't kick in when the
  equal-width tabs get very narrow.
- Liquid Glass translucency and refraction aren't reproduced.

## Uninstall

Clear the folder under **Settings → Appearance → Custom UI Modifications**. If you
installed the drag patch, run `install-drag.bat -Remove`, adding `-Unregister` if you
registered the scheduled task. Then restart Vivaldi.

## License

[MIT](LICENSE)
