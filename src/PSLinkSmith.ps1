using namespace System.Windows.Forms
using namespace System.Drawing
using namespace System.IO


Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO

$adminCheck = [System.Security.Principal.WindowsPrincipal] [System.Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $adminCheck.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script requires administrator privileges. Trying to run as an administrator." -ForegroundColor Blue
    . Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" @Arguments" -Verb RunAs  *>&1 | Write-Host -ForegroundColor Blue
    exit
}

# Helper function to get checked nodes' paths
function Get-Nodes {
    param (
        [bool]$checked = $true
    )

    $nodeList = @()

    function Get-CheckedRecursively {
        param (
            [System.Windows.Forms.TreeNodeCollection]$nodes,
            [ref]$nodeList,
            [bool]$checked
        )
        foreach ($node in $nodes) {
            if ($node.Checked -and $checked) {
                $nodeList.Value += $node
            }
            Get-CheckedRecursively -nodes $node.Nodes -checked $checked -nodeList $nodeList | Out-Null
        }
    }
    Get-CheckedRecursively -nodes $AssetsTreeView.Nodes -checked $checked -nodeList ([ref]$nodeList) | Out-Null
    return $nodeList
}


function Format-NodePathTag {
    param (
        [string]$Tag
    )
    return($Tag -replace [regex]::Escape($SourcePath), "").TrimStart("\")
}

function Get-NodePaths {
    param (
        [System.Windows.Forms.TreeNodeCollection]$nodes,
        [bool]$checked = $true
    )
    return $(Get-Nodes -nodes $treeView.Nodes -checked $true) | ForEach-Object { Format-NodePathTag -Tag $_.Tag }
}

function Watch-TokenFilter {
    param (
        [TreeNode]$Node,
        [bool]$Checked
    )

    if ($Checked) {
        Add-Token -node $e.Node | Out-Null
    }
    else {
        Remove-Token -Tag $e.Node.Tag | Out-Null
    }
}

function Set-CheckToParentNodes {
    param (
        [TreeNode]$node,
        [bool]$checked = $true,
        [Color]$color = [Color]::Black
    )

    while ($null -ne $node) {
        if (-not $node.Checked -eq $checked) {
            $node.Checked = $checked
            $node.ForeColor = $color
            Watch-TokenFilter -Node $node -Checked $checked
        }
        $node = $node.Parent
    }
}

function Set-CheckToChildNodes {
    param (
        [TreeNode]$node,
        [bool]$checked = $true,
        [Color]$color = [Color]::Black
    )
    foreach ($childNode in $node.Nodes) {
        $childNode.Checked = $checked
        $childNode.ForeColor = $color
        Watch-TokenFilter -Node $childNode -Checked $checked
        if ($childNode.Nodes.Count -gt 0) {
            Set-CheckToChildNodes($childNode, $checked)
        }
    }
}

function Add-Token {
    param([System.Windows.Forms.TreeNode]$Node)

    # If token already exists, don't add it again
    if ($TokenizedFiltersFlowPanel.Controls.ContainsKey($Node.Tag)) {
        return
    }

    try {
        [System.Windows.Forms.Control]$ParentControl = $TokenizedFiltersFlowPanel
        $tokenPanel = [TokenFilterElementPanel]::new($Node)
        $ParentControl.Controls.Add($tokenPanel)
    }
    catch {
        Write-Host "Error adding token: $($_.Exception.Message) | $($_.Exception.StackTrace) | $($_.ScriptStackTrace)"
        return
    }
}

function Remove-Token {
    param([string]$Tag)
    if ($TokenizedFiltersFlowPanel.Controls.ContainsKey($Node.Tag)) {
        $TokenizedFiltersFlowPanel.Controls.RemoveByKey($Node.Tag)
    }
}

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Target = "Form_Load")]
$Form_Load = {
    function Initialize-TreeView {
        param ($parentNode, $basePath)
        $folders = Get-ChildItem -Path $basePath -Directory -ErrorAction SilentlyContinue
        foreach ($folder in $folders) {
            $node = New-Object TreeNode
            $node.Text = $folder.Name
            $node.Tag = $folder.FullName
            if ($null -eq $parentNode) {
                $AssetsTreeView.Nodes.Add($node)
            }
            else {
                $parentNode.Nodes.Add($node)
            }
            Initialize-TreeView -basePath $folder.FullName -parentNode $node | Out-Null
        }
    }

    Initialize-TreeView -basePath $SourcePath | Out-Null
}

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Target = "AssetsTreeViewNode_CheckChanged")]
$AssetsTreeViewNode_CheckChanged = {
    param (
        [System.Windows.Forms.TreeView]$sdr,
        [System.Windows.Forms.TreeViewEventArgs]$e
    )
    if ($e.Node.Checked) {
        Add-Token -node $e.Node | Out-Null
    }
    else {
        Remove-Token -Tag $e.Node.Tag | Out-Null
    }
}

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Target = "AssetsTreeView_AfterCheck")]
$AssetsTreeView_AfterCheck = {
    param (
        [TreeView]$sdr,
        [TreeViewEventArgs]$e
    )

    Watch-TokenFilter -Node $e.Node -Checked $e.Node.Checked
}

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Target = "FolderBrowserButton_Click")]
$FolderBrowserButton_Click = {
    $FolderBrowserDialog = New-Object FolderBrowserDialog
    if ($FolderBrowserDialog.ShowDialog() -eq "OK") {
        $FolderBrowserTextBox.Text = $FolderBrowserDialog.SelectedPath
        $Config.TargetPath = $FolderBrowserDialog.SelectedPath
        . Save-Config -config $Config
    }
}

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Target = "TokenFilterElementPanel_Click")]
$TokenFilterElementPanel_Click = {
    param(
        [Object]$sdr,
        [EventArgs]$e
    )
    $_TextBox = $this.Parent.Controls | Where-Object { $_.GetType() -eq [TextBox] }
    if ($_TextBox.Enabled -eq $false) {
        $_TextBox.Enabled = $true
        $this.TextAlign = [ContentAlignment]::MiddleRight
        $this.Padding = [Padding]::new(3, 1, 0, 3)
        $this.Text = "$([Path]::GetDirectoryName($this.Tag))\"
        $_TextBox.Text = [Path]::GetFileName($this.Tag)
        $_TextBox.Visible = $true
        $_TextBox.Focus()
    }
}

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Target = "TokenFilterElementTextBox_KeyUp")]
$TokenFilterElementTextBox_KeyUp = {
    param(
        [Object]$sdr,
        [KeyEventArgs]$e
    )
    $_Label = $sdr.Parent.Controls | Where-Object { $_.GetType() -eq [Label] }
    if (($e.KeyCode -eq [Keys]::Enter -or $e.KeyCode -eq [Keys]::Return) -and $sdr.Focused -and $sdr.ReadOnly -eq $false) {
        if ($null -eq $sdr.Text -or $sdr.Text -eq $sdr.Tag) { $sdr.Text = $sdr.Tag }
        else {
            $filePattern = [Path]::GetFileName($sdr.Text).Replace("%", "*")
            $directory = [Path]::GetDirectoryName($_Label.Text)
            $expectedPattern = "$($directory)\$filePattern"

            $isFilterInvalid = (
                -not ($filePattern -and ($filePattern -notmatch "[/\\]")) -or
                -not ($filePattern.IndexOfAny([Path]::GetInvalidPathChars()) -eq -1)
            )

            if ($isFilterInvalid) {
                $_Label.Text = $_Label.Tag
            }
            else {
                $_Label.Tag = $expectedPattern
                $_Label.Text = $_Label.Tag
                $_Label.Parent.Filter = $filePattern
            }
        }
        $sdr.Text = ""
        $sdr.Visible = $false
        $_Label.Padding = [Padding]::new(3, 3, 3, 3)
        $_Label.TextAlign = [ContentAlignment]::MiddleCenter
        $sdr.Enabled = $false

    }
}

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Target = "ExcludeLabel_Click")]
$ExcludeLabel_Click = {
}

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Target = "SubmitButton_Click")]
$SubmitButton_Click = {
    if ($FolderBrowserTextBox.Text.Length -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Select a Target Directory.", "Error", "OK", "Error")
        $FolderBrowserButton.BackColor = [System.Drawing.Color]::Red
        Start-Sleep -Milliseconds 200
        $FolderBrowserButton.BackColor = [System.Drawing.SystemColors]::Control
        $FolderBrowserButton.Focus()
    }
    else {
        Invoke-Command($Filters)
    }
}

function Format-Filter([Object[]]$Filter) {
    if ($null -eq $Filter -or $Filter.Count -eq 0) { return $null }
    return ($Filter | ForEach-Object { $_ -replace '\\', '\\\\' }) -join ","
}

function Get-FilterCommandArgs {
    $Files = @()
    $Exclude = @()

    if ($ExcludeTextBox.Text.Length -gt 0) {
        $_exclude = $ExcludeTextBox.Text.Replace("`"", "").Replace("'", "").Split(",")
        foreach ($ex in $_exclude) {
            $Exclude += "`"$($ex.Replace(' ', ''))`""
        }
    }

    foreach ($control in $TokenizedFiltersFlowPanel.Controls) {
        $filter = "`"$($control.GetFilter())`""
        if ($filter.IsExclude) {
            $Exclude += $filter
        }
        else {
            $Files += $filter
        }
    }

    $FilesArgs = Format-Filter -Filter $Files
    $ExcludeArgs = Format-Filter -Filter $Exclude

    return @{
        Files   = $FilesArgs
        Exclude = $ExcludeArgs
    }
}

function Invoke-Command {
    param([Object[]]$Filters)

    $Script = $(Get-ChildItem -Path $PSScriptRoot -Recurse | Where-Object { $_.Name -eq "PSCreateSymlinks.ps1" }).FullName
    $_Args = Get-FilterCommandArgs

    $Arguments = @(
        "-SourcePath", "`"$SourcePath`"",
        "-TargetPath", "`"$($FolderBrowserTextBox.Text)`"",
        "-CreateFolder",
        "-Files", $_Args.Files
    )

    if (-not [string]::IsNullOrEmpty($_Args.Exclude)) {
        $Arguments += @("-Exclude", $_Args.Exclude)
    }

    $result = [System.Windows.Forms.MessageBox]::Show("Spawn Symlinks?", "Confirmation", "YesNo", "Question")
    if ($result -eq "Yes") {
        . PowerShell $Script @Arguments *>&1 | Write-Host -ForegroundColor White
    }
}

. (Join-Path $PSScriptRoot 'PSLinkSmiith.designer.ps1') | Out-Null

$Form.ShowDialog() | Out-Null
