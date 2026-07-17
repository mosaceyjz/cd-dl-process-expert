# ─── CD DL Process Expert · 一键发布到 GitHub Pages ───────────────────────────
# 使用方法：在 PowerShell 中运行此脚本，或右键 → "使用 PowerShell 运行"
# ---------------------------------------------------------------------------

$repoName = "cd-dl-process-expert"

Write-Host ""
Write-Host "  🐼 CD DL Process Expert · GitHub Pages 发布工具" -ForegroundColor Cyan
Write-Host "  ─────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""

# 1. 获取 GitHub 用户名
$username = Read-Host "  请输入你的 GitHub 用户名"
if (-not $username) { Write-Host "  [取消]" -ForegroundColor Yellow; exit }

# 2. 获取 Personal Access Token
Write-Host ""
Write-Host "  需要 GitHub Personal Access Token (PAT)。" -ForegroundColor Yellow
Write-Host "  如还没有，请先到: https://github.com/settings/tokens/new" -ForegroundColor Gray
Write-Host "  勾选 repo 权限后生成，复制粘贴到下方：" -ForegroundColor Gray
Write-Host ""
$token = Read-Host "  粘贴 Personal Access Token (输入时不显示)" -AsSecureString
$tokenPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($token))
if (-not $tokenPlain) { Write-Host "  [取消]" -ForegroundColor Yellow; exit }

$remoteUrl = "https://${username}:${tokenPlain}@github.com/${username}/${repoName}.git"

Write-Host ""
Write-Host "  正在创建 GitHub 仓库 '$repoName'..." -ForegroundColor Cyan

# 3. 通过 GitHub API 创建仓库（private，避免 API key 公开）
$body = @{
    name        = $repoName
    description = "成都DL工厂工艺AI专家 · Powered by Dify RAG"
    private     = $false   # 改为 true 可设为私有仓库
    auto_init   = $false
} | ConvertTo-Json

$headers = @{
    Authorization = "token $tokenPlain"
    Accept        = "application/vnd.github.v3+json"
    "User-Agent"  = "CD-DL-Deploy"
}

try {
    $resp = Invoke-RestMethod -Uri "https://api.github.com/user/repos" `
        -Method Post -Body $body -Headers $headers -ContentType "application/json"
    Write-Host "  ✅ 仓库创建成功: $($resp.html_url)" -ForegroundColor Green
} catch {
    $errMsg = $_.ErrorDetails.Message | ConvertFrom-Json -ErrorAction SilentlyContinue
    if ($errMsg.errors -and $errMsg.errors[0].message -match "already exists") {
        Write-Host "  ℹ️  仓库已存在，直接推送..." -ForegroundColor Yellow
    } else {
        Write-Host "  ⚠️  创建仓库失败: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  将尝试直接推送到已有仓库..." -ForegroundColor Yellow
    }
}

# 4. 推送代码
Set-Location $PSScriptRoot
git remote remove origin 2>$null
git remote add origin $remoteUrl
git branch -M main
git push -u origin main --force 2>&1

Write-Host ""
Write-Host "  ✅ 推送完成！" -ForegroundColor Green
Write-Host ""
Write-Host "  正在开启 GitHub Pages..." -ForegroundColor Cyan

# 5. 启用 GitHub Pages
$pagesBody = @{
    source = @{ branch = "main"; path = "/" }
} | ConvertTo-Json

try {
    Invoke-RestMethod -Uri "https://api.github.com/repos/${username}/${repoName}/pages" `
        -Method Post -Body $pagesBody -Headers $headers -ContentType "application/json" | Out-Null
    Write-Host "  ✅ GitHub Pages 已启用！" -ForegroundColor Green
} catch {
    # 可能已经启用了
    Write-Host "  ℹ️  Pages 已启用或需要手动在仓库 Settings → Pages 中启用" -ForegroundColor Yellow
}

$pageUrl = "https://${username}.github.io/${repoName}/"
Write-Host ""
Write-Host "  🌐 访问地址（约1分钟后生效）：" -ForegroundColor Cyan
Write-Host "     $pageUrl" -ForegroundColor White
Write-Host ""
Write-Host "  ⚠️  注意：若出现 CORS 报错，说明 P&G 内网 API 不允许从" -ForegroundColor Yellow
Write-Host "     github.io 跨域请求，届时请改用本地 bat 脚本启动。" -ForegroundColor Yellow
Write-Host ""

Start-Process $pageUrl
pause
