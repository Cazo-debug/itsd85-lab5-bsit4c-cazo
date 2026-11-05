param(
	[string]$AndroidSdk = "$env:LOCALAPPDATA\Android\Sdk",
	[string]$JavaHome = 'C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot'
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$output = Join-Path $repo '.bin\gate2-touch'
$buildTools = Join-Path $AndroidSdk 'build-tools\36.0.0'
$androidJar = Join-Path $AndroidSdk 'platforms\android-35\android.jar'
New-Item -ItemType Directory -Force $output, "$output\classes", "$output\dex" | Out-Null
$manifest = @'
<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="com.itsd85.toottubes.qa" android:versionCode="1" android:versionName="1">
<uses-sdk android:minSdkVersion="24" android:targetSdkVersion="35"/>
<application android:label="Toot Tubes QA" android:debuggable="true" android:allowBackup="false"/>
<instrumentation android:name="com.itsd85.toottubes.qa.Gate2Touch" android:targetPackage="com.itsd85.toottubes.qa" android:functionalTest="true"/>
</manifest>
'@
[IO.File]::WriteAllText("$output\AndroidManifest.xml", $manifest)
& "$JavaHome\bin\javac.exe" -encoding UTF-8 -source 8 -target 8 -bootclasspath $androidJar -d "$output\classes" "$PSScriptRoot\android\Gate2Touch.java"
if ($LASTEXITCODE -ne 0) { throw 'Touch helper Java compilation failed' }
$classes = @(Get-ChildItem "$output\classes" -Recurse -Filter '*.class' | Select-Object -ExpandProperty FullName)
$previousJavaHome = $env:JAVA_HOME
$signingPath = $null
$env:JAVA_HOME = $JavaHome
try {
	& "$buildTools\d8.bat" --lib $androidJar --output "$output\dex" @classes
	if ($LASTEXITCODE -ne 0) { throw 'Touch helper dex compilation failed' }
	& "$buildTools\aapt2.exe" link -o "$output\unsigned.apk" --manifest "$output\AndroidManifest.xml" -I $androidJar
	if ($LASTEXITCODE -ne 0) { throw 'Touch helper package linking failed' }
	Add-Type -AssemblyName System.IO.Compression
	Add-Type -AssemblyName System.IO.Compression.FileSystem
	$archive = [IO.Compression.ZipFile]::Open("$output\unsigned.apk", [IO.Compression.ZipArchiveMode]::Update)
	try { [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, "$output\dex\classes.dex", 'classes.dex') | Out-Null } finally { $archive.Dispose() }
	& "$buildTools\zipalign.exe" -f 4 "$output\unsigned.apk" "$output\gate2-touch.apk"
	if ($LASTEXITCODE -ne 0) { throw 'Touch helper alignment failed' }
	# Disposable signing identity: no user/export key or password is read.
	$env:GATE2_QA_PASSWORD = [Guid]::NewGuid().ToString('N')
	$signingPath = Join-Path $output ('qa-' + [Guid]::NewGuid().ToString('N') + '.p12')
	# Windows PowerShell treats keytool's successful stderr progress as an error.
	$previousErrorAction = $ErrorActionPreference
	try {
		$ErrorActionPreference = 'Continue'
		& "$JavaHome\bin\keytool.exe" -genkeypair -keystore $signingPath -storetype PKCS12 -alias gate2 -keyalg RSA -keysize 2048 -validity 2 -dname 'CN=Toot Tubes QA' -storepass:env GATE2_QA_PASSWORD -keypass:env GATE2_QA_PASSWORD -noprompt 2>$null
		$keyExit = $LASTEXITCODE
	} finally { $ErrorActionPreference = $previousErrorAction }
	if ($keyExit -ne 0) { throw 'Disposable signing identity creation failed' }
	& "$buildTools\apksigner.bat" sign --ks $signingPath --ks-key-alias gate2 --ks-pass env:GATE2_QA_PASSWORD "$output\gate2-touch.apk"
	if ($LASTEXITCODE -ne 0) { throw 'Touch helper signing failed' }
	Write-Output "Built ignored test-only helper: $output\gate2-touch.apk"
} finally {
	$env:JAVA_HOME = $previousJavaHome
	Remove-Item Env:GATE2_QA_PASSWORD -ErrorAction SilentlyContinue
	if ($signingPath -and (Test-Path -LiteralPath $signingPath)) {
		Remove-Item -LiteralPath $signingPath
	}
}
