@echo off
cls
start powershell -WindowStyle Hidden -noProfile -c "$ProgressPreference = 'SilentlyContinue'; Set-Location '%~dp0';  ./server.ps1"