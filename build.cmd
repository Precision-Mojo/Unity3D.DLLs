@echo off
setlocal

set MSBUILD="%WINDIR%\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe"
%MSBUILD% Unity3D.DLLs.proj
