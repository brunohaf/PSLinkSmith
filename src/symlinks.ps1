param (
    [Alias("s", "source")] [string]$SourceDir = $(Get-Location).ToString(), # Source directory
    [Alias("t", "target")] [string]$TargetDir, # Target directory for symlinks
    [Alias("f", "path", "file")] [string[]]$Files = @("*"),
    [Alias("e")] [string[]]$Exclude = @(""), # Optional: Exclude specific files
    [Alias("h")] [switch]$Help = $null, # Show usage help
    [Alias("c", "create", "CreateDir")] [switch]$CreateFolder = $null, # Switch to create missing folders
    [Alias("auto-clone")] [switch]$AutoClone = $null,
    [Alias("dry-run")] [switch]$DryRun = $null
)

$adminCheck = [System.Security.Principal.WindowsPrincipal] [System.Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $adminCheck.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Log "This script requires administrator privileges. Please run it as an administrator." -Type ERROR
    exit
}

# Function to display the help message
function Show-Help {
    Write-Log @"
Usage: .\symlinks.ps1 -TargetDir "C:\Path\To\Target" [-Files "file1", "file2"] [-Help]

Creates symbolic links in the target directory for files and folders from the current directory.

PARAMETERS:
  -TargetDir   [Required] Path where symlinks should be created.
  -Files       [Optional] List of specific files/folders to symlink. Supports wildcards (e.g., "*.txt").
  -Help        [Optional] Show this help message.

EXAMPLES:
  1. Symlink everything in the current directory:
     .\symlinks.ps1 -TargetDir "C:\Links"

  2. Symlink only specific files:
     .\symlinks.ps1 -TargetDir "C:\Links" -Files "example.txt", "folder1"

  3. Symlink all .txt files:
     .\symlinks.ps1 -TargetDir "C:\Links" -Files "*.txt"

  NOTE: This script requires administrator privileges or Developer Mode enabled.
"@ -ForegroundColor Cyan
    exit 0
}

# Ensure Output Encoding is UTF-8
$OutputEncoding = [System.Text.Encoding]::UTF8

function Set-TruncatePath {
    param (
        [string]$Path, # The path to be truncated
        [int]$MaxLength = 30      # Maximum length of the path, default is 50 characters
    )

    if ($Path.Length -gt $MaxLength) {
        $StartPart = $Path.Substring(0, $MaxLength)
        $EndPart = $Path.Substring($Path.Length - $MaxLength, $MaxLength)
        return "$StartPart...$EndPart"
    }
    return $Path
}


function Write-Log {
    param (
        [string]$Message,
        [string]$Type = "INFO"  # Default log type
    )

    $ColorMap = @{
        "INFO"    = "DarkMagenta"
        "WARN"    = "DarkYellow"
        "ERROR"   = "DarkRed"
        "SUCCESS" = "DarkGreen"
    }


    Write-Host "$Type`: $Message" -ForegroundColor $ColorMap[$Type]
}

# Function to create a folder if it does not exist
function Add-Folder {
    [CmdletBinding()]
    param (
        [string]$FolderPath # The directory path to create
    )
    Write-Debug -Message "Should Add-Folder?: $FolderPath"
    if (-not (Test-Path $FolderPath)) {
        Write-Debug -Message "Creating folder: $FolderPath"
        New-Item -Path $FolderPath -ItemType Directory -Force | Out-Null
        Write-Debug -Message "Created -> Folder: $(Set-TruncatePath -Path $FolderPath)"
    }
    else {
        Write-Debug -Message "Folder already exists:  $(Set-TruncatePath -Path $FolderPath)"
    }
}

function Add-Symlink {
    [CmdletBinding()]
    param (
        [string]$LinkPath,
        [string]$SourcePath,
        [bool]$AutoClone = $false,
        [bool]$DryRun = $false
    )
    # Ensure SourcePath is valid
    if (-not $SourcePath -or -not (Test-Path $SourcePath)) {
        Write-Log "[ERROR] Invalid SourcePath: $(Set-TruncatePath -Path $SourcePath)" -ForegroundColor Red
        return
    }

    # Avoid linking the script itself
    if (-not $AutoClone -and $MyInvocation.ScriptName -and $SourcePath -match [regex]::Escape($MyInvocation.ScriptName)) {
        Skip-Symlink -SourcePath $SourcePath
        return
    }

    # Check if SourcePath is a directory
    $isDirectory = Test-Path $SourcePath -PathType Container

    # Debugging output
    Write-Debug -Message "Linking: $LinkPath -> $SourcePath (Directory: $isDirectory)"

    # Construct the command with correct flag
    if ($isDirectory) {
        $cmd = "cmd /c mklink /D `"$LinkPath`" `"$SourcePath`""
    }
    else {
        $cmd = "cmd /c mklink `"$LinkPath`" `"$SourcePath`""
    }

    $Type = if ($isDirectory) { "Folder" } else { "File" }

    try {
        if (Test-Path -Path $LinkPath) {
            throw "Cannot create a symlink when it already exists.."
        }

        if (-not $DryRun) {
            Invoke-Expression $cmd
        }

        Write-Log "LINK -> $Type` -> CREATED: $(Set-TruncatePath -Path $LinkPath) -> $(Set-TruncatePath -Path $SourcePath)" -Type INFO
    }
    catch {
        Write-Log "LINK -> $Type` -> NOT CREATED: $(Set-TruncatePath -Path $LinkPath) -> $(Set-TruncatePath -Path $SourcePath)`n`t- $($_)" -Type WARN
    }
}



function Skip-Symlink {
    [CmdletBinding()]
    param (
        [string]$LinkPath,
        [string]$SourcePath
    )
    Write-Log "SKIP -> File: $SourcePath" -Type WARN
}

function Add-SymlinksCreateFolder {
    [CmdletBinding()]
    param (
        [string]$SourceDir,
        [string]$TargetDir,
        [string[]]$Files = @("*"),
        [string[]]$Exclude = @(""),
        [bool]$AutoClone = $false,
        [bool]$DryRun = $false
    )
    $ItemsToProcess = Get-ChildItem -Path $Files -Recurse -File -ErrorAction SilentlyContinue -Exclude $Exclude

    Write-Debug -Message "Starting to process items..."

    $ItemsToProcess | ForEach-Object {
        $SourcePath = $_.FullName
        $SourceDirLength = $SourceDir.Length

        Write-Debug -Message "SourceDirLength: $SourceDirLength"

        $TargetDirPath = $_.Directory.ToString().Substring($SourceDirLength)
        $RelativePath = $SourcePath.Substring($SourceDirLength)

        Write-Debug -Message "Directory: $_.Directory"
        Write-Debug -Message "TargetDirPath: $TargetDirPath"
        Write-Debug -Message "RelativePath: $RelativePath"

        $LinkPath = Join-Path -Path $TargetDir -ChildPath $RelativePath

        Add-Folder -FolderPath $(Join-Path -Path $TargetDir -ChildPath $TargetDirPath)
        Add-Symlink -LinkPath $LinkPath -SourcePath $SourcePath -AutoClone $AutoClone -DryRun $DryRun
    }
}

function Add-Symlinks {
    [CmdletBinding()]
    param (
        [string]$SourceDir,
        [string]$TargetDir,
        [string[]]$Files = @("*"),
        [string[]]$Exclude = @(""),
        [bool]$AutoClone = $false,
        [bool]$DryRun = $false
    )
    Write-Debug -Message "Files: $Files"
    if ($Files -like "*/*") {
        Write-Debug -Message "Pattern with subpath detected. Invoking Add-SymlinkCreateFolder..."
        Add-SymlinksCreateFolder -SourceDir $SourceDir -TargetDir $TargetDir -Files $Files -Exclude $Exclude -AutoClone $AutoClone -DryRun $DryRun
        return
    }
    else {
        $ItemsToProcess = Get-Item -Path $Files -ErrorAction SilentlyContinue  -Exclude $Exclude
    }

    Write-Debug -Message "Starting to process items..."
    $ItemsToProcess | ForEach-Object {
        Write-Debug -Message "Processing: $($_.Name)..."
        $SourcePath = $_.FullName
        $RelativePath = $SourcePath.Substring($SourceDir.Length)
        $LinkPath = Join-Path -Path $TargetDir -ChildPath $RelativePath

        Add-Symlink -LinkPath $LinkPath -SourcePath $SourcePath -AutoClone $AutoClone -DryRun $DryRun
    }
}

function Start-Symlinks() {
    [CmdletBinding()]
    param (
        [string]$SourceDir,
        [string]$TargetDir,
        [bool]$Help = $false,
        [bool]$CreateFolder = $false,
        [string[]]$Files = @("*"),
        [string[]]$Exclude = @(""),
        [bool]$AutoClone = $false,
        [bool]$DryRun = $false
    )

    # If no parameters are provided, show help
    if ($Help -or -not $TargetDir) {
        Show-Help
    }

    # Ensure the target directory exists
    if (-not (Test-Path $TargetDir)) {
        Write-Log "Target directory does not exist." -Type ERROR
        exit 1
    }

    if ($CreateFolder) {
        Write-Debug -Message "Starting with CreateFolder..."
        Add-SymlinksCreateFolder -SourceDir $SourceDir -TargetDir $TargetDir -Files $Files -Exclude $Exclude -AutoClone $AutoClone -DryRun $DryRun
    }
    else {
        Write-Debug -Message "Starting without CreateFolder..."
        Add-Symlinks -SourceDir $SourceDir -TargetDir $TargetDir -Files $Files -Exclude $Exclude -AutoClone $AutoClone -DryRun $DryRun
    }

    if ($?) {
        Write-Log "Symlink creation complete!" -Type SUCCESS
    }
    else {
        Write-Log "Symlink creation failed!" -Type ERROR
    }
}

Write-Host "Starting Symlinks..."
Write-Host "-SourceDir: $SourceDir"
Write-Host "-TargetDir: $TargetDir"
Write-Host "-Files: $Files"
Write-Host "-Exclude: $Exclude"
Write-Host "-CreateFolder: $CreateFolder"
Write-Host "-AutoClone: $AutoClone"
Write-Host "-DryRun: $DryRun"

Start-Symlinks -SourceDir $SourceDir -TargetDir $TargetDir -Files $Files -Exclude $Exclude -CreateFolder $CreateFolder -AutoClone $AutoClone -DryRun $DryRun