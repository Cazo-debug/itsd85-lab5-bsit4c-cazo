# Convert the paper and cover sheet to PDF with Microsoft Word (fonts are embedded by Word).
param([string]$Folder = "$PSScriptRoot\..\docs\paper")
$word = New-Object -ComObject Word.Application
$word.Visible = $false
try {
  foreach ($name in "paper", "cover_sheet") {
    $in = (Resolve-Path "$Folder\$name.docx").Path
    $out = [System.IO.Path]::ChangeExtension($in, ".pdf")
    $doc = $word.Documents.Open($in)
    $doc.ExportAsFixedFormat($out, 17, $false, 0, 0, 0, 0, 0, $true, $true, 0, $true, $true, $true)  # 17 = PDF, bitmap fonts off, embed fonts
    $pages = $doc.ComputeStatistics(2)
    $doc.Close(0)
    Write-Output "$name.pdf : $pages pages"
  }
} finally { $word.Quit() }
