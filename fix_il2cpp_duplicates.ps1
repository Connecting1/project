$il2cppDir = "C:\_toriCapsule\client\android\unityLibrary\src\main\Il2CppOutputProject\Source\il2cppOutput"

Write-Host "스캔 중..." -ForegroundColor Cyan

$allFiles = Get-ChildItem -Path $il2cppDir -Filter "*.cpp" | Where-Object { $_.Name -match "^.+__\d+\.cpp$" } | Sort-Object Name
$groups = $allFiles | Group-Object { $_.Name -replace "__\d+\.cpp$", "" }
$totalFixed = 0

foreach ($group in ($groups | Sort-Object Name)) {
    $files = $group.Group | Sort-Object { [int]($_.Name -replace "^.+__(\d+)\.cpp$", '$1') }
    if ($files.Count -lt 2) { continue }

    $fileFuncs = @{}
    foreach ($file in $files) {
        $lines = Get-Content $file.FullName
        $defs = [System.Collections.Generic.List[object]]::new()
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match "^IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR\s+\S+\s+(\w+)\s*\(" -and -not $lines[$i].TrimEnd().EndsWith(";")) {
                $defs.Add([PSCustomObject]@{ Name = $Matches[1]; Idx = $i })
            }
        }
        $fileFuncs[$file.Name] = $defs
    }

    for ($i = 0; $i -lt ($files.Count - 1); $i++) {
        $fileN = $files[$i]
        $laterFuncs = [System.Collections.Generic.HashSet[string]]::new()
        for ($j = $i + 1; $j -lt $files.Count; $j++) {
            foreach ($d in $fileFuncs[$files[$j].Name]) { [void]$laterFuncs.Add($d.Name) }
        }

        $cutIdx = -1
        foreach ($def in $fileFuncs[$fileN.Name]) {
            if ($laterFuncs.Contains($def.Name)) {
                $cutIdx = $def.Idx - 1
                Write-Host "[$($fileN.Name)] 라인 $($def.Idx + 1) 중복 발견 -> 라인 $($cutIdx + 1)까지 유지" -ForegroundColor Yellow
                break
            }
        }

        if ($cutIdx -ge 0) {
            $lines = Get-Content $fileN.FullName
            $lines[0..$cutIdx] | Set-Content $fileN.FullName
            Write-Host "  -> 수정 완료" -ForegroundColor Green
            $totalFixed++
        }
    }
}

Write-Host "`n총 $totalFixed 개 파일 수정 완료" -ForegroundColor Cyan
