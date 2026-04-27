$VaultRoot = $PSScriptRoot
$ImageDest = Join-Path $VaultRoot "assets\images"

if (-not (Test-Path $ImageDest)) {
    New-Item -ItemType Directory -Path $ImageDest | Out-Null
    Write-Host "[+] Created: assets/images/"
}

# 1. Root Pasted image files
$RootImages = Get-ChildItem -Path $VaultRoot -Filter "Pasted image*.png" -File
foreach ($img in $RootImages) {
    $dest = Join-Path $ImageDest $img.Name
    if (-not (Test-Path $dest)) {
        Move-Item -Path $img.FullName -Destination $dest
        Write-Host "[mv] $($img.Name)"
    }
}

# 2. _posts Pasted image files
$PostsPath = Join-Path $VaultRoot "_posts"
if (Test-Path $PostsPath) {
    $PostsImages = Get-ChildItem -Path $PostsPath -Filter "Pasted image*.png" -Recurse -File
    foreach ($img in $PostsImages) {
        $dest = Join-Path $ImageDest $img.Name
        if (-not (Test-Path $dest)) {
            Move-Item -Path $img.FullName -Destination $dest
            Write-Host "[mv] $($img.Name)"
        }
    }
}

# 3. Update md links
$MdFiles = Get-ChildItem -Path $VaultRoot -Filter "*.md" -Recurse -File |
    Where-Object { $_.FullName -notlike "*\.git*" }

$count = 0
foreach ($md in $MdFiles) {
    $content = Get-Content -Path $md.FullName -Raw -Encoding UTF8
    $original = $content

    $content = $content -replace '!\[\[Pasted image ([^\]]+\.png)\]\]', '![](/assets/images/Pasted image $1)'

    $content = [regex]::Replace($content,
        '!\[([^\]]*)\]\(Pasted%20image%20([^)]+\.png)\)',
        { param($m) "![$($m.Groups[1].Value)](/assets/images/Pasted image $($m.Groups[2].Value -replace '%20',' '))" }
    )

    if ($content -ne $original) {
        Set-Content -Path $md.FullName -Value $content -Encoding UTF8 -NoNewline
        Write-Host "[fix] $($md.Name)"
        $count++
    }
}

Write-Host ""
Write-Host "[done] md files updated: $count"
