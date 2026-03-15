$ErrorActionPreference = "Stop"

function Show-Usage {
  @'
Usage:
  tinypng.ps1 --input <file> [--output <file>] [--width <n>] [--height <n>] [--convert <webp|avif|jpeg|png>] [--preserve <copyright,creation,location>]

Examples:
  tinypng.ps1 --input .\hero.png
  tinypng.ps1 --input .\hero.png --width 128
  tinypng.ps1 --input .\hero.png --width 128 --height 128
  tinypng.ps1 --input .\hero.png --convert webp
  tinypng.ps1 --input .\photo.jpg --preserve creation,location
'@ | Write-Output
}

function Fail([string]$Message) {
  [Console]::Error.WriteLine($Message)
  exit 1
}

function Get-DefaultOutputPath([string]$InputPath, [string]$ConvertFormat) {
  $directory = Split-Path -Parent $InputPath
  $fileName = [System.IO.Path]::GetFileName($InputPath)
  $baseName = [System.IO.Path]::GetFileNameWithoutExtension($InputPath)
  $currentExtension = [System.IO.Path]::GetExtension($InputPath)

  $targetExtension = switch ($ConvertFormat) {
    "webp" { ".webp" }
    "avif" { ".avif" }
    "jpeg" { ".jpg" }
    "png"  { ".png" }
    ""     { $currentExtension }
    default { throw "Unsupported convert format: $ConvertFormat" }
  }

  if ([string]::IsNullOrEmpty($directory)) {
    return "$baseName.tinypng$targetExtension"
  }

  return [System.IO.Path]::Combine($directory, "$baseName.tinypng$targetExtension")
}

function Get-HeaderValue([string]$Path, [string]$Name) {
  foreach ($line in [System.IO.File]::ReadAllLines($Path)) {
    if ($line -match "^(?i:$Name):\s*(.+)$") {
      return $Matches[1].Trim()
    }
  }
  return ""
}

function Write-Utf8NoBom([string]$Path, [string]$Content) {
  $encoding = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

function Show-ResponseBody([string]$Path) {
  if (Test-Path $Path -PathType Leaf) {
    $content = [System.IO.File]::ReadAllText($Path)
    if (-not [string]::IsNullOrWhiteSpace($content)) {
      [Console]::Error.WriteLine("Response body:")
      [Console]::Error.WriteLine($content)
    }
  }
}

function Validate-PositiveInteger([string]$Value, [string]$Name) {
  if (-not ($Value -match '^[1-9][0-9]*$')) {
    Fail "$Name must be a positive integer."
  }
}

$inputPath = ""
$outputPath = ""
$width = ""
$height = ""
$convert = ""
$preserve = ""

for ($i = 0; $i -lt $args.Count; $i++) {
  switch ($args[$i]) {
    "--input" {
      if ($i + 1 -ge $args.Count) { Fail "Missing value for --input." }
      $inputPath = $args[++$i]
    }
    "--output" {
      if ($i + 1 -ge $args.Count) { Fail "Missing value for --output." }
      $outputPath = $args[++$i]
    }
    "--width" {
      if ($i + 1 -ge $args.Count) { Fail "Missing value for --width." }
      $width = $args[++$i]
    }
    "--height" {
      if ($i + 1 -ge $args.Count) { Fail "Missing value for --height." }
      $height = $args[++$i]
    }
    "--convert" {
      if ($i + 1 -ge $args.Count) { Fail "Missing value for --convert." }
      $convert = $args[++$i]
    }
    "--preserve" {
      if ($i + 1 -ge $args.Count) { Fail "Missing value for --preserve." }
      $preserve = $args[++$i]
    }
    "--help" { Show-Usage; exit 0 }
    "-h" { Show-Usage; exit 0 }
    default { Fail "Unknown argument: $($args[$i])" }
  }
}

if (-not (Get-Command curl.exe -ErrorAction SilentlyContinue)) {
  Fail "curl.exe is required."
}

if ([string]::IsNullOrWhiteSpace($env:TINYPNG_API_KEY)) {
  Fail "TINYPNG_API_KEY is not set."
}

if ([string]::IsNullOrWhiteSpace($inputPath)) {
  Fail "The --input argument is required."
}

if (-not (Test-Path $inputPath -PathType Leaf)) {
  Fail "Input file does not exist: $inputPath"
}

if (-not [string]::IsNullOrWhiteSpace($width)) {
  Validate-PositiveInteger $width "--width"
}

if (-not [string]::IsNullOrWhiteSpace($height)) {
  Validate-PositiveInteger $height "--height"
}

switch ($convert) {
  "" { }
  "webp" { }
  "avif" { }
  "jpeg" { }
  "png" { }
  default { Fail "Unsupported convert format: $convert" }
}

$preserveList = @()
if (-not [string]::IsNullOrWhiteSpace($preserve)) {
  foreach ($item in $preserve.Split(",")) {
    $trimmed = $item.Trim()
    switch ($trimmed) {
      "copyright" { $preserveList += $trimmed }
      "creation"  { $preserveList += $trimmed }
      "location"  { $preserveList += $trimmed }
      "" { }
      default { Fail "Unsupported preserve value: $trimmed" }
    }
  }
  if ($preserveList.Count -eq 0) {
    Fail "The --preserve value must not be empty."
  }
}

if ([string]::IsNullOrWhiteSpace($outputPath)) {
  $outputPath = Get-DefaultOutputPath $inputPath $convert
}

if ($outputPath -eq $inputPath) {
  Fail "Refusing to overwrite the input file. Provide a different --output path."
}

$outputDirectory = Split-Path -Parent $outputPath
if (-not [string]::IsNullOrWhiteSpace($outputDirectory) -and -not (Test-Path $outputDirectory -PathType Container)) {
  Fail "Output directory does not exist: $outputDirectory"
}

$requestParts = New-Object System.Collections.Generic.List[string]

if (-not [string]::IsNullOrWhiteSpace($width) -and -not [string]::IsNullOrWhiteSpace($height)) {
  $requestParts.Add('"resize":{"method":"fit","width":' + $width + ',"height":' + $height + '}')
} elseif (-not [string]::IsNullOrWhiteSpace($width)) {
  $requestParts.Add('"resize":{"method":"scale","width":' + $width + '}')
} elseif (-not [string]::IsNullOrWhiteSpace($height)) {
  $requestParts.Add('"resize":{"method":"scale","height":' + $height + '}')
}

if (-not [string]::IsNullOrWhiteSpace($convert)) {
  $convertMime = switch ($convert) {
    "webp" { "image/webp" }
    "avif" { "image/avif" }
    "jpeg" { "image/jpeg" }
    "png"  { "image/png" }
  }
  $requestParts.Add('"convert":{"type":"' + $convertMime + '"}')
}

if ($preserveList.Count -gt 0) {
  $quoted = $preserveList | ForEach-Object { '"' + $_ + '"' }
  $requestParts.Add('"preserve":[' + ($quoted -join ",") + ']')
}

$requestJson = ""
if ($requestParts.Count -gt 0) {
  $requestJson = "{" + ($requestParts -join ",") + "}"
}

$tempDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ("tinypng-" + [System.Guid]::NewGuid().ToString("N"))
[void](New-Item -ItemType Directory -Path $tempDirectory)

try {
  $uploadHeaders = Join-Path $tempDirectory "upload.headers"
  $uploadBody = Join-Path $tempDirectory "upload.body"
  $resultBody = Join-Path $tempDirectory "result.body"
  $payloadFile = Join-Path $tempDirectory "payload.json"

  $uploadArgs = @(
    "--silent",
    "--show-error",
    "--dump-header", $uploadHeaders,
    "--output", $uploadBody,
    "--write-out", "%{http_code}",
    "--user", "api:$env:TINYPNG_API_KEY",
    "--data-binary", "@$inputPath",
    "https://api.tinify.com/shrink"
  )

  $uploadStatus = (& curl.exe @uploadArgs | Out-String).Trim()
  if ($LASTEXITCODE -ne 0) {
    Fail "curl upload failed with exit code $LASTEXITCODE."
  }
  if ($uploadStatus -notmatch '^2\d\d$') {
    [Console]::Error.WriteLine("Upload failed with HTTP status $uploadStatus.")
    Show-ResponseBody $uploadBody
    exit 1
  }

  $location = Get-HeaderValue $uploadHeaders "Location"
  if ([string]::IsNullOrWhiteSpace($location)) {
    Fail "TinyPNG response did not include a Location header."
  }

  if ([string]::IsNullOrWhiteSpace($requestJson)) {
    $resultArgs = @(
      "--silent",
      "--show-error",
      "--output", $resultBody,
      "--write-out", "%{http_code}",
      "--user", "api:$env:TINYPNG_API_KEY",
      $location
    )
  } else {
    Write-Utf8NoBom $payloadFile $requestJson
    $resultArgs = @(
      "--silent",
      "--show-error",
      "--output", $resultBody,
      "--write-out", "%{http_code}",
      "--user", "api:$env:TINYPNG_API_KEY",
      "--header", "Content-Type: application/json",
      "--data-binary", "@$payloadFile",
      $location
    )
  }

  $resultStatus = (& curl.exe @resultArgs | Out-String).Trim()
  if ($LASTEXITCODE -ne 0) {
    Fail "curl result request failed with exit code $LASTEXITCODE."
  }
  if ($resultStatus -notmatch '^2\d\d$') {
    [Console]::Error.WriteLine("Result request failed with HTTP status $resultStatus.")
    Show-ResponseBody $resultBody
    exit 1
  }

  Move-Item -Force $resultBody $outputPath

  $inputSize = (Get-Item $inputPath).Length
  $outputSize = (Get-Item $outputPath).Length

  Write-Output "Input: $inputPath"
  Write-Output "Output: $outputPath"
  Write-Output "Original bytes: $inputSize"
  Write-Output "Result bytes: $outputSize"
}
finally {
  if (Test-Path $tempDirectory) {
    Remove-Item -Recurse -Force $tempDirectory
  }
}
