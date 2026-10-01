#Requires -Version 5.1
<#
.SYNOPSIS
  THubX 构建脚本（Windows 版）
  多文件 src/ -> 单文件 dist/THubX.lua
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File build/build.ps1
#>
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$DistDir = Join-Path $Root "dist"
$Input = Join-Path $Root "src/Init.lua"
$TempOut = Join-Path $DistDir "temp.lua"
$Output = Join-Path $Root "dist/THubX.lua"
$DarkluaConfig = Join-Path $Root "build/darklua.json"

if (-not (Test-Path -LiteralPath $DistDir)) {
  New-Item -ItemType Directory -Path $DistDir | Out-Null
}

# 1. 检查 darklua，没有则提示安装
$darklua = Get-Command darklua -ErrorAction SilentlyContinue
if (-not $darklua) {
  Write-Host "[ x ] 未找到 darklua，请先安装：" -ForegroundColor Red
  Write-Host "  方式1(推荐): cargo install darklua"
  Write-Host "  方式2: 去 https://github.com/seaofvoices/darklua/releases 下载 darklua.exe 并加入 PATH"
  Write-Host "  方式3(winget): winget install darklua"
  exit 1
}

# 2. 读版本
$pkg = Get-Content (Join-Path $Root "package.json") -Raw | ConvertFrom-Json
$ver = $pkg.version
$date = Get-Date -Format "yyyy-MM-dd"

# 3. 打包
$sw = [System.Diagnostics.Stopwatch]::StartNew()
& darklua process $Input $TempOut --config $DarkluaConfig
if ($LASTEXITCODE -ne 0) { Write-Host "[ x ] DarkLua failed" -ForegroundColor Red; exit 1 }
$sw.Stop()

# 4. 加头
$header = "--[[" + "`r`n" + "  THubX v$ver | build $date" + "`r`n" + "  入口: loadstring(game:HttpGet(.../dist/THubX.lua))()" + "`r`n" + "  源码: src/ 多文件，产物: dist/ 单文件 (darklua bundle path mode)" + "`r`n" + "]]"
$body = Get-Content $TempOut -Raw
Set-Content -LiteralPath $Output -Value ($header + "`r`n" + $body) -NoNewline
Remove-Item -LiteralPath $TempOut -Force -ErrorAction SilentlyContinue

$kb = [math]::Round((Get-Item $Output).Length / 1KB, 1)
Write-Host ""
Write-Host "[ v ] THubX Build 完成" -ForegroundColor Green
Write-Host "[ > ] Version: $ver"
Write-Host "[ > ] Time: $($sw.ElapsedMilliseconds)ms"
Write-Host "[ > ] Size: ${kb}KB"
Write-Host "[ > ] Output: dist/THubX.lua"
Write-Host ""
