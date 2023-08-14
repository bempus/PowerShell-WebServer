@echo off
cls
start powershell -c "$ProgressPreference = 'SilentlyContinue'; Set-Location '%~dp0';  ./server.ps1"