param (
    [Alias("s", "source")] [string]$SourcePath = $(Get-Location).ToString(), # Source directory
    [Alias("t", "target")] [string]$TargetPath, # Target directory for symlinks
    [Alias("f", "path", "file")] [string[]]$Files = @("*"),
    [Alias("e")] [string[]]$Exclude = @(""), # Optional: Exclude specific files
    [Alias("h")] [switch]$Help = $null, # Show usage help
    [Alias("c", "create", "CreateDir")] [switch]$CreateFolder = $null, # Switch to create missing folders
    [Alias("auto-clone", "self-clone")] [switch]$SelfClone = $null,
    [Alias("dry-run")] [switch]$DryRun = $null
)


# Function to display the help message
function Show-Help {
    Write-Log @"
Usage: .\Invoke-PSSymlinkSpawner -TargetPath "C:\Path\To\Target" [-Files "file1", "file2"] [-Help]

Creates symbolic links in the target directory for files and folders from the current directory.

PARAMETERS:
  -TargetPath   [Required] Path where symlinks should be created.
  -Files       [Optional] List of specific files/folders to symlink. Supports wildcards (e.g., "*.txt").
  -Help        [Optional] Show this help message.

EXAMPLES:
  1. Symlink everything in the current directory:
     .\Invoke-PSSymlinkSpawner -TargetPath "C:\Links"

  2. Symlink only specific files:
     .\Invoke-PSSymlinkSpawner -TargetPath "C:\Links" -Files "example.txt", "folder1"

  3. Symlink all .txt files:
     .\Invoke-PSSymlinkSpawner -TargetPath "C:\Links" -Files "*.txt"

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
        [string]$ItemPath,
        [bool]$SelfClone = $false,
        [bool]$DryRun = $false
    )

    if (-not $ItemPath -or -not (Test-Path -LiteralPath "$($ItemPath)")) {
        Write-Log "[ERROR] Invalid ItemPath: $(Set-TruncatePath -Path $ItemPath)" -ForegroundColor Red
        return
    }

    if (-not $SelfClone -and $MyInvocation.ScriptName -and $ItemPath -match [regex]::Escape($MyInvocation.ScriptName)) {
        Skip-Symlink -ItemPath $ItemPath
        return
    }

    $isDirectory = Test-Path $ItemPath -PathType Container

    Write-Debug -Message "Linking: $LinkPath -> $ItemPath (Directory: $isDirectory)"

    $arguments = @(
        "/c", "mklink"
    )
    if ($isDirectory) {
        $arguments += "/D"
    }

    $arguments += @(
        "`"$LinkPath`"",
        "`"$ItemPath`""
    )
    Write-Host -Message "cmd $arguments"
    try {
        if (Test-Path -Path $LinkPath) {
            throw "Cannot create a symlink when it already exists.."
        }

        if (-not $DryRun) {
            & cmd @arguments
        }

        $Type = if ($isDirectory) { "Folder" } else { "File" }

        Write-Log "LINK -> $Type` -> CREATED: $(Set-TruncatePath -Path $LinkPath) -> $(Set-TruncatePath -Path $ItemPath)" -Type INFO
    }
    catch {
        Write-Log "LINK -> $Type` -> NOT CREATED: $(Set-TruncatePath -Path $LinkPath) -> $(Set-TruncatePath -Path $ItemPath)`n`t- $($_)" -Type WARN
    }
}

function Skip-Symlink {
    [CmdletBinding()]
    param (
        [string]$LinkPath,
        [string]$ItemPath
    )
    Write-Log "SKIP -> File: $ItemPath" -Type WARN
}

function Add-SymlinksCreateFolder {
    [CmdletBinding()]
    param (
        [string]$SourcePath,
        [string]$TargetPath,
        [string[]]$Files = @("*"),
        [string[]]$Exclude = @(""),
        [bool]$SelfClone = $false,
        [bool]$DryRun = $false
    )
    $ItemsToProcess = Get-ChildItem -Path $Files -Recurse -File -Exclude $Exclude -ErrorAction SilentlyContinue
    if(-not $ItemsToProcess){
        Write-Log -Message "No items to process. Exiting..." -Type WARN
        return
    }
    Write-Debug "ItemsToProcess: $ItemsToProcess"
    Write-Debug "Starting to process items..."
    try{
        $ItemsToProcess | ForEach-Object {
            $ItemPath = $_.FullName
            $SourcePathLength = $SourcePath.Length
            Write-Debug  "ItemPath: $ItemPath"

            Write-Debug  "SourcePathLength: $SourcePathLength"

            $TargetDir = $_.Directory.ToString().Substring($SourcePathLength)
            $RelativePath = $ItemPath.Substring($SourcePathLength)

            Write-Debug "Directory: $($_.Directory)"
            Write-Debug "TargetDir: $TargetDir"
            Write-Debug "RelativePath: $RelativePath"
            $LinkPath = Join-Path -Path $TargetPath -ChildPath $RelativePath
            Write-Debug "LinkPath: $LinkPath"
            Add-Folder -FolderPath $(Join-Path -Path $TargetPath -ChildPath $TargetDir)
            Add-Symlink -LinkPath $LinkPath -ItemPath $ItemPath -SelfClone $SelfClone -DryRun $DryRun
        }
    }
    catch{
        Write-Debug -Message "Error Processing Items to Symlink: $($_.Exception.Message)"
    }
}


function Add-Symlinks {
    [CmdletBinding()]
    param (
        [string]$SourcePath,
        [string]$TargetPath,
        [string[]]$Files = @("*"),
        [string[]]$Exclude = @(""),
        [bool]$SelfClone = $false,
        [bool]$DryRun = $false
    )
    Write-Debug -Message "Files: $Files"
    if ($Files -like "*/*") {
        Write-Debug -Message "Pattern with subpath detected. Invoking Add-SymlinkCreateFolder..."
        Add-SymlinksCreateFolder -SourcePath $SourcePath -TargetPath $TargetPath -Files $Files -Exclude $Exclude -SelfClone $SelfClone -DryRun $DryRun
        return
    }
    else {
        $ItemsToProcess = Get-Item -Path $Files -ErrorAction SilentlyContinue  -Exclude $Exclude
    }

    Write-Debug -Message "Starting to process items..."
    Write-Debug "ItemsToProcess: $ItemsToProcess"
    $ItemsToProcess | ForEach-Object {
        Write-Debug -Message "Processing: $($_.Name)..."
        $ItemPath = $_.FullName
        $RelativePath = $ItemPath.Substring($SourcePath.Length)
        $LinkPath = Join-Path -Path $TargetPath -ChildPath $RelativePath

        Add-Symlink -LinkPath $LinkPath ItemPath $ItemPath -SelfClone $SelfClone -DryRun $DryRun
    }
}

function Start-Symlinks() {
    [CmdletBinding()]
    param (
        [string]$SourcePath,
        [string]$TargetPath,
        [bool]$Help = $false,
        [bool]$CreateFolder = $false,
        [string[]]$Files = @("*"),
        [string[]]$Exclude = @(""),
        [bool]$SelfClone = $false,
        [bool]$DryRun = $false
    )

    # If no parameters are provided, show help
    if ($Help -or -not $TargetPath) {
        Show-Help
    }

    # Ensure the target directory exists
    if (-not (Test-Path $TargetPath)) {
        Write-Log "Target directory does not exist." -Type ERROR
        exit 1
    }
    try{
        if ($CreateFolder) {
            Write-Debug -Message "Starting with CreateFolder..."
            Add-SymlinksCreateFolder -SourcePath $SourcePath -TargetPath $TargetPath -Files $Files -Exclude $Exclude -SelfClone $SelfClone -DryRun $DryRun
        }
        else {
            Write-Debug -Message "Starting without CreateFolder..."
            Add-Symlinks -SourcePath $SourcePath -TargetPath $TargetPath -Files $Files -Exclude $Exclude -SelfClone $SelfClone -DryRun $DryRun
        }
        Write-Log "Symlink creation complete!" -Type SUCCESS
    }
    catch {
        Write-Log "Symlink creation failed!" -Type ERROR
    }
}

$adminCheck = [System.Security.Principal.WindowsPrincipal] [System.Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $adminCheck.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Log "This script requires administrator privileges. Please run it as an administrator." -Type ERROR
    exit
}

Start-Symlinks -SourcePath $SourcePath -TargetPath $TargetPath -Files $Files -Exclude $Exclude -CreateFolder $CreateFolder -SelfClone $SelfClone -DryRun $DryRun