param(
	[int[]]$Levels = @(1, 2, 3, 4, 5),
	[int[]]$CrewSizes = @(1, 2, 3, 4),
	[int[]]$Seeds = @(1, 3),
	[switch]$IncludeAssistants,
	[string]$Godot = '',
	[ValidatePattern('^[A-Za-z0-9_-]+$')][string]$RunLabel = ('run-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
if (-not $Godot) { $Godot = Join-Path $repo '.bin\Godot_v4.7.2-stable_win64.exe' }
$Godot = (Resolve-Path -LiteralPath $Godot).Path
$output = Join-Path $repo ('.bin\phase3-validation\' + $RunLabel)
New-Item -ItemType Directory -Path $output -Force | Out-Null
$results = [Collections.Generic.List[object]]::new()

function Invoke-CourseCheck([int]$Number, [int]$Crew, [int]$Seed, [bool]$Assistants) {
	if ($Number -lt 1 -or $Number -gt 5 -or $Crew -lt 1 -or $Crew -gt 4) { throw 'Invalid course or crew size' }
	$suffix = if ($Assistants) { '_assist' } else { '' }
	$label = 'level{0}-crew{1}-seed{2}{3}' -f $Number, $Crew, $Seed, $suffix
	$arguments = @('--headless', '--path', ('"' + $repo + '"'), '--fixed-fps', '60', '--script', 'tools/verify_sky_garden.gd', '--', "--level=$Number", "--crew=$Crew", "--seed=$Seed")
	if ($Assistants) { $arguments += '--assistants' }
	$process = Start-Process -FilePath $Godot -ArgumentList $arguments -WorkingDirectory $repo -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $output ($label + '.log')) -RedirectStandardError (Join-Path $output ($label + '-errors.log'))
	# Cache the process handle before exit (Windows PowerShell otherwise loses ExitCode).
	$null = $process.Handle
	$deadline = [DateTime]::UtcNow.AddMinutes(3)
	while (-not $process.WaitForExit(1000)) {
		if ([DateTime]::UtcNow -ge $deadline) { $process.Kill(); throw "Check timed out: $label" }
	}
	$process.WaitForExit()
	if ($null -eq $process.ExitCode -or $process.ExitCode -ne 0) { throw "Course check failed: $label (exit $($process.ExitCode)). See $output" }
	$reportName = if ($Number -eq 1) { "sky_result_${Crew}_${Seed}${suffix}.json" } else { "course_result_${Number}_${Crew}_${Seed}${suffix}.json" }
	$report = Get-Content -LiteralPath (Join-Path $repo ('.bin\' + $reportName)) -Raw | ConvertFrom-Json
	if (-not $report.passed) { throw "Course report failed: $label" }
	$results.Add($report)
	Write-Output ("PASS {0}: {1:N2}s, {2} contacts, {3} recoveries" -f $label, $report.seconds, $report.contacts, $report.recoveries)
	[IO.File]::WriteAllText((Join-Path $output 'results.json'), (ConvertTo-Json -InputObject @($results.ToArray()) -Depth 8), [Text.UTF8Encoding]::new($false))
}

foreach ($number in $Levels) {
	foreach ($crew in $CrewSizes) {
		foreach ($seed in $Seeds) { Invoke-CourseCheck $number $crew $seed $false }
	}
	if ($IncludeAssistants) { Invoke-CourseCheck $number 4 7 $true }
}
Write-Output "All $($results.Count) course checks passed. Reports: $output"
