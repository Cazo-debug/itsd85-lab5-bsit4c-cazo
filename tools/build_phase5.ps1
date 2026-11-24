param(
	[string]$JavaHome = 'C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot',
	[string]$AndroidSdk = "$env:LOCALAPPDATA\Android\Sdk",
	[string]$SigningDirectory = "$env:LOCALAPPDATA\TootTubes\signing"
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$engine = Join-Path $repo '.bin\Godot_v4.7.2-stable_win64_console.exe'
$logs = Join-Path $repo '.bin'
$exports = Join-Path $repo 'export'
$signingRoot = [IO.Path]::GetFullPath($SigningDirectory)
$workspace = [IO.Path]::GetFullPath($repo).TrimEnd('\') + '\'
if ($signingRoot.StartsWith($workspace, [StringComparison]::OrdinalIgnoreCase)) { throw 'Signing material must stay outside the repository.' }
New-Item -ItemType Directory -Path $exports -Force | Out-Null
$names = @('JAVA_HOME', 'GODOT_ANDROID_KEYSTORE_RELEASE_PATH', 'GODOT_ANDROID_KEYSTORE_RELEASE_USER', 'GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD')
$priorEnvironment = @{}
foreach ($name in $names) { $priorEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
$privatePassword = $null
try {
	$env:JAVA_HOME = $JavaHome
	$hasCredentials = @($names[1..3] | Where-Object { [Environment]::GetEnvironmentVariable($_, 'Process') })
	if ($hasCredentials.Count -notin @(0, 3)) { throw 'Supply all three GODOT_ANDROID_KEYSTORE_RELEASE_* variables, or none.' }
	if ($hasCredentials.Count -eq 0) {
		New-Item -ItemType Directory -Path $signingRoot -Force | Out-Null
		$identity = [Security.Principal.WindowsIdentity]::GetCurrent().Name
		& icacls.exe $signingRoot /inheritance:r /grant:r ($identity + ':(OI)(CI)F') *> (Join-Path $logs 'phase5-key-acl.log')
		if ($LASTEXITCODE -ne 0) { throw 'Could not protect the private signing directory.' }
		$keyPath = Join-Path $signingRoot 'toot-tubes-release.keystore'
		$passwordPath = Join-Path $signingRoot 'release.password.dpapi'
		if ((Test-Path -LiteralPath $keyPath) -xor (Test-Path -LiteralPath $passwordPath)) { throw 'Incomplete signing identity. Recover the matching key/password; existing files will not be overwritten.' }
		if (-not (Test-Path -LiteralPath $keyPath)) {
			$bytes = New-Object byte[] 32
			$random = [Security.Cryptography.RandomNumberGenerator]::Create()
			try { $random.GetBytes($bytes) } finally { $random.Dispose() }
			$privatePassword = [Convert]::ToBase64String($bytes)
			$env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = $privatePassword
			$secure = ConvertTo-SecureString $privatePassword -AsPlainText -Force
			$encrypted = ConvertFrom-SecureString $secure
			$encrypted | Set-Content -LiteralPath $passwordPath -Encoding ASCII
			$secure.Dispose()
			$previousErrorAction = $ErrorActionPreference
			try {
				$ErrorActionPreference = 'Continue'
				& "$JavaHome\bin\keytool.exe" -genkeypair -keystore $keyPath -storetype JKS -alias toottubes -keyalg RSA -keysize 3072 -validity 10000 -dname 'CN=Toot Tubes Local Release, O=ITSD 85 Project' -storepass:env GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD -keypass:env GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD -noprompt *> (Join-Path $logs 'phase5-key-generation.log')
				$keyExit = $LASTEXITCODE
			} finally { $ErrorActionPreference = $previousErrorAction }
			if ($keyExit -ne 0) { throw 'Private release-key generation failed. Inspect the local key-generation log.' }
		} else {
			$secure = (Get-Content -LiteralPath $passwordPath -Raw).Trim() | ConvertTo-SecureString
			$pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
			try { $privatePassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer) }
			finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer); $secure.Dispose() }
			$env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = $privatePassword
		}
		$env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH = $keyPath
		$env:GODOT_ANDROID_KEYSTORE_RELEASE_USER = 'toottubes'
	}
	$resolvedKey = [IO.Path]::GetFullPath($env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH)
	if ($resolvedKey.StartsWith($workspace, [StringComparison]::OrdinalIgnoreCase)) { throw 'The supplied private key must be outside the repository.' }
	Push-Location $repo
	try {
		& $engine --headless --path . --editor --import *> (Join-Path $logs 'phase5-build-import.log')
		if ($LASTEXITCODE -ne 0) { throw 'Godot import failed.' }
		$builds = @(
			@('--export-debug', 'Android Debug', 'TootTubes-v1.0-debug.apk', 'debug'),
			@('--export-release', 'Android Release', 'TootTubes-v1.0.apk', 'android-release'),
			@('--export-release', 'Windows Portable', 'TootTubes-v1.0.exe', 'windows')
		)
		$manifest = [Collections.Generic.List[object]]::new()
		foreach ($build in $builds) {
			$destination = Join-Path $exports $build[2]
			& $engine --headless --path . $build[0] $build[1] $destination *> (Join-Path $logs ('phase5-export-' + $build[3] + '.log'))
			if ($LASTEXITCODE -ne 0) { throw "Export failed: $($build[1]). See .bin/phase5-export-$($build[3]).log" }
			if ($destination.EndsWith('.apk')) {
				& "$AndroidSdk\build-tools\36.0.0\apksigner.bat" verify --verbose --print-certs $destination *> (Join-Path $logs ('phase5-signature-' + $build[3] + '.log'))
				if ($LASTEXITCODE -ne 0) { throw "Signature verification failed: $($build[2])" }
				& "$AndroidSdk\build-tools\36.0.0\aapt.exe" dump badging $destination *> (Join-Path $logs ('phase5-package-' + $build[3] + '.log'))
				if ($LASTEXITCODE -ne 0) { throw "Package inspection failed: $($build[2])" }
			}
			$manifest.Add([ordered]@{file=$build[2]; bytes=(Get-Item -LiteralPath $destination).Length; sha256=(Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash})
			Write-Output ("Verified local build: " + $build[2])
		}
		[IO.File]::WriteAllText((Join-Path $exports 'phase5-builds.json'), (ConvertTo-Json -InputObject @($manifest.ToArray()) -Depth 4), [Text.UTF8Encoding]::new($false))
		Write-Output 'Local release candidates built. No publication was performed.'
	} finally { Pop-Location }
} finally {
	foreach ($name in $names) { [Environment]::SetEnvironmentVariable($name, $priorEnvironment[$name], 'Process') }
	$privatePassword = $null
}
