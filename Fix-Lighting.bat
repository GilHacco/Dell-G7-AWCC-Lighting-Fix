@echo off
REM Double-click this to run the Alienware lighting recovery.
REM It launches the PowerShell script, which then prompts for admin rights (UAC).
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Fix-AlienwareLighting.ps1"
