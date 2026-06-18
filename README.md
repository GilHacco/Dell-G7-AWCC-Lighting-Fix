# Alienware Lighting Recovery

A small PowerShell utility that recovers the **Dell G7** keyboard backlight / LED
lighting when the **Alienware Command Center (AWCC)** "FX" tab stops working —
the lights won't turn on, the keyboard light toggle does nothing, and the FX
color/behavior controls are missing — **without needing to reboot**.

## The problem it fixes

On some Dell G7 laptops the RGB lighting controller (`USB\VID_1532&PID_0039`)
accumulates **phantom / ghost duplicate device entries** in Windows. AWCC then
latches onto a dead instance, which leaves the FX tab with no color/behavior
controls and the backlight unresponsive. Clearing those duplicates and
restarting the AWCC app + service restores it.

## Usage

1. Double-click **`Fix-Lighting.bat`**.
2. Click **Yes** on the UAC prompt (admin rights are needed for the device steps).
3. Watch the four steps run in the console. AWCC reopens at the end.
4. Open **AWCC → FX** and confirm the controls are back and the lights respond.

## What it does

1. Removes the **phantom (non-present)** duplicate entries of the lighting
   controller that hide the FX controls.
2. Best-effort **re-initializes the live controller** over USB
   (`pnputil /restart-device`).
3. **Force-stops** the (often-wedged) AWCC app + service and re-scans hardware.
4. **Restarts the AWCC service** and relaunches the app so it re-detects the
   controller and re-renders the FX controls.

Device IDs are discovered dynamically (their suffixes change between boots), and
the AWCC Store package is located automatically — so the script keeps working
across reboots and AWCC updates.

## If it still doesn't work

Do a full **Restart** — *Start → Power → Restart* (**not** Shut Down). "Restart"
forces a true cold boot that re-initializes the controller at the firmware
level; "Shut Down" with **Fast Startup** enabled does not.

## Stop it from recurring

Disable **Fast Startup**:
*Control Panel → Power Options → "Choose what the power buttons do" → "Change
settings that are currently unavailable" → uncheck **Turn on fast startup** →
Save changes.*

## Compatibility

- Windows 10 (2004+) / Windows 11, PowerShell 5.1+
- Dell G7 with the `VID_1532&PID_0039` lighting controller and the Microsoft
  Store build of Alienware Command Center.
- If your laptop/keyboard uses a different controller, update `$VidPid` near the
  top of `Fix-AlienwareLighting.ps1`.

## ⚠️ Disclaimer

This software is provided **"as is", without warranty of any kind**, and is **not
affiliated with, endorsed by, or supported by Dell or Alienware**. It modifies
Windows device (PnP) state and stops/starts processes and services. **Use it at
your own risk.** The author accepts **no liability** for any damage, data loss,
or other issues that may arise from its use. Review the script before running it,
and make sure you understand what it does. See [LICENSE](LICENSE) for full terms.

## 💜 Donations

If this saved you a headache and you'd like to say thanks, donations are very
welcome (entirely optional):

| Coin | Address |
| ---- | ------- |
| **BTC** | `3L8KucpMJDuUEAnbyDmYwfExPjkC1bWhvt` |
| **ETH** | `0x7cFd91780Aea5ca7156492aE9D1222D8fA6210a0` |
| **XRP** | `rw2ciyaNshpHe7bCHo4bRWq6pqqynnWKQg` &nbsp;•&nbsp; Destination Tag: `3221561577` |
| **SOL** | `DWnNaiayQPhc3jvU1JJKUZKS5oHTAzbYGY3AX69CqQzA` |

> **XRP note:** when sending to an exchange-hosted address, the **Destination
> Tag** is usually required or your deposit may not be credited.

## License

[MIT](LICENSE) © 2026 GilHa
