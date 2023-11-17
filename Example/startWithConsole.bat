@echo off
cls
start powershell -noExit -c "$ProgressPreference = 'SilentlyContinue'; Set-Location '%~dp0';  ./server.ps1"