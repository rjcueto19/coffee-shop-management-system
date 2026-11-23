param(
 [Parameter(ValueFromRemainingArguments=$true)]
 [string[]]$ArtisanArgs = @('serve')
)
$previousScanDirectory = $env:PHP_INI_SCAN_DIR
try {
 $env:PHP_INI_SCAN_DIR = Join-Path $PSScriptRoot 'tools/php'
 & php (Join-Path $PSScriptRoot 'artisan') @ArtisanArgs
 $commandExitCode = $LASTEXITCODE
} finally {
 $env:PHP_INI_SCAN_DIR = $previousScanDirectory
}
exit $commandExitCode