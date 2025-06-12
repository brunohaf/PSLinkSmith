using namespace System.Windows.Forms
using namespace System.Drawing
using namespace System.IO

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO

$Form = New-Object -TypeName System.Windows.Forms.Form
[Panel]$BackgroundPanel = $null
[TableLayoutPanel]$MainTablePanel = $null
[TableLayoutPanel]$RightTablePanel = $null
[TableLayoutPanel]$SubmitTablePanel = $null
[Button]$SubmitButton = $null
[FlowLayoutPanel]$TokenizedFiltersFlowPanel = $null
[TableLayoutPanel]$TokenFilterLabelPanel = $null
[TableLayoutPanel]$ExcludeTablePanel = $null
[Label]$ExcludeLabel = $null
[TextBox]$ExcludeTextBox = $null
[TableLayoutPanel]$TokenizedFiltersHeaderTablePanel = $null
[Label]$TokenizedFiltersHeaderLabel = $null
[TableLayoutPanel]$LeftTablePanel = $null
[TreeView]$AssetsTreeView = $null
[TableLayoutPanel]$FolderBrowserTable = $null
[TextBox]$FolderBrowserTextBox = $null
[Button]$FolderBrowserButton = $null
[hashtable]$Config = @{}
[String]$ConfigFilePath = ""
[String]$SourcePath = ""
[String]$TargetPath = ""

#
#TokenFilterElementPanel
#
class TokenFilterElementPanel : TableLayoutPanel {
    TokenFilterElementPanel([TreeNode]$Node) {
        $this.Init($Node)
    }

    [String]$Directory = [Path]::GetFullPath($Node.Tag)
    [String]$Filter = ""
    [Bool]$IsExclude = $false

    [String]GetFilter() {
        return "$($this.Directory)\$($this.Filter)"
    }

    [void]Init([TreeNode]$Node) {
        $this.Name = [System.String]$Node.Tag
        $this.Tag = [System.String]$Node.Tag
        $this.Text = [System.String]"$(Format-NodePathTag -Tag $Node.Tag)\"

        $this.RowCount = [System.Int32]1
        $this.ColumnCount = [System.Int32]2

        $this.BackColor = [System.Drawing.Color]::LightGray
        $this.ForeColor = [System.Drawing.Color]::Black

        # $this.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]104,[System.Int32]0))
        $this.Margin = [Padding]::new(3, 3, 3, 3)
        $this.Padding = [Padding]::new(0, 0, 0, 0)
        $this.BorderStyle = [BorderStyle]::FixedSingle
        $this.CellBorderStyle = [TableLayoutPanelCellBorderStyle]::None
        $this.ColumnStyles.Add((New-Object -TypeName System.Windows.Forms.ColumnStyle -ArgumentList @([SizeType]::AutoSize)))
        $this.ColumnStyles.Add((New-Object -TypeName System.Windows.Forms.ColumnStyle -ArgumentList @([SizeType]::Percent, [Single]5)))
        $this.MaximumSize = (New-Object -TypeName System.Drawing.Size -ArgumentList @([Int32]300, [Int32]40))
        $this.AutoSize = $true
        $this.AutoSizeMode = [AutoSizeMode]::GrowAndShrink
        $this.GrowStyle = [TableLayoutPanelGrowStyle]::FixedSize
        $this.SetControls()
    }

    [void]SetControls() {
        $_TextBox = $this.BuildLabel()
        $_Label = $this.BuildTextBox()

        $this.Controls.Add($_Label, 1, 0)
        $this.Controls.Add($_TextBox, 0, 0)
    }


    #
    #TokenFilterLabel
    #
    [Label]BuildLabel() {
        $_Label = (New-Object -TypeName Label)
        $_Label.Tag = $this.Text
        $_Label.Name = [System.String]"TokenFilterLabel_$($this.Text)"
        $_Label.Visible = $true
        $_Label.Enabled = $true
        $_Label.Text = [System.String]$this.Text
        $_Label.TextAlign = [ContentAlignment]::MiddleCenter
        $_Label.Font = (New-Object -TypeName Font -ArgumentList @([System.String]'Fira Code Retina', [System.Single]8.25, [System.Drawing.FontStyle]::Bold))
        $_Label.AutoSize = $true
        $_Label.Dock = [DockStyle]::Fill
        $_Label.Margin = [Padding]::new(0, 0, 0, 0)
        $_Label.BorderStyle = [BorderStyle]::None
        # $_Label.FlatStyle = [FlatStyle]::Flat
        $_Label.Cursor = [Cursors]::Hand
        $_Label.Padding = [Padding]::new(0, 0, 0, 0)
        $_Label.FlatStyle = [FlatStyle]::System
        $this.Set_MouseEvents($_Label)
        $_Label.add_Click($global:TokenFilterElementPanel_Click)
        return $_Label
    }

    #
    #TokenFilterTextBox
    #
    [TextBox]BuildTextBox() {
        $_TextBox = (New-Object -TypeName TextBox)
        $_TextBox.Visible = $false
        $_TextBox.ReadOnly = $false
        $_TextBox.Enabled = $false
        $_TextBox.WordWrap = $false
        $_TextBox.BackColor = $this.BackColor
        $_TextBox.ForeColor = $this.ForeColor
        $_TextBox.Anchor = ([AnchorStyles]::Left -bor [AnchorStyles]::Right -bor [AnchorStyles]::Top)
        $_TextBox.BorderStyle = [BorderStyle]::None
        $_TextBox.Font = (New-Object -TypeName Font -ArgumentList @([System.String]'Fira Code Retina', [System.Single]8.25, [System.Drawing.FontStyle]::Bold))
        $_TextBox.Name = [System.String]"TokenFilterTextBox_$($this.Text)"
        $_TextBox.Padding = [Padding]::new(3, 0, 0, 3)
        $_TextBox.AutoSize = $true
        $_TextBox.MaximumSize = (New-Object -TypeName System.Drawing.Size -ArgumentList @([Int32]50, [Int32]30))
        $_TextBox.Text = [System.String][Path]::GetFileName(($this.Text))
        $_TextBox.Tag = $_TextBox.Text
        $_TextBox.TextAlign = [HorizontalAlignment]::Left
        $_TextBox.add_KeyUp($global:TokenFilterElementTextBox_KeyUp)
        $this.Set_MouseEvents($_TextBox)
        $_TextBox.Add_LostFocus({
                param([Object]$sdr, [EventArgs]$e)
                $sdr.Visible = $false
                $sdr.Enabled = $false
            })
        return $_TextBox
    }

    [void]Set_MouseEvents([Control]$parentControl) {
        $parentControl.add_MouseEnter({
                param([Object]$sdr, [EventArgs]$e)

                if ($sdr.GetType() -ne [TokenFilterElementPanel]) {
                    $sdr = $sdr.Parent
                }
                $toolTip = [ToolTip]::new()
                $toolTip.SetToolTip($sdr, [String]$sdr.Text)

                $sdr.BackColor = [Color]::Black
                $sdr.ForeColor = [Color]::LightGray
                foreach ($control in $sdr.Controls) {
                    try {
                        $toolTip.SetToolTip($this, [String]$this.Text)
                        $control.BackColor = $sdr.BackColor
                        $control.ForeColor = $sdr.ForeColor
                    }
                    catch {
                        Write-Debug $_.Exception.Message
                    }
                }
            })
        $parentControl.add_MouseLeave( {
            param([Object]$sdr, [EventArgs]$e)

            if ($sdr.GetType() -ne [TokenFilterElementPanel]) {
                $sdr = $sdr.Parent
            }

            $sdr.BackColor = [Color]::LightGray
            $sdr.ForeColor = [Color]::Black
            foreach ($control in $sdr.Controls) {
                try {
                    $control.BackColor = $sdr.BackColor
                    $control.ForeColor = $sdr.ForeColor
                }
                catch {
                    Write-Debug $_.Exception.Message
                }
            }
        })
    }

    [Region]GetRoundedRectangleRegion([int]$radius = 30) {
        $bounds = New-Object Rectangle(0, 0, $this.Width, $this.Height)
        $path = New-Object Drawing2D.GraphicsPath
        $d = $radius * 2

        $path.AddArc($bounds.X, $bounds.Y, $d, $d, 180, 90)  # Top-left
        $path.AddArc($bounds.Right - $d, $bounds.Y, $d, $d, 270, 90)  # Top-right
        $path.AddArc($bounds.Right - $d, $bounds.Bottom - $d, $d, $d, 0, 90)  # Bottom-right
        $path.AddArc($bounds.X, $bounds.Bottom - $d, $d, $d, 90, 90)  # Bottom-left
        $path.CloseFigure()

        return New-Object Region($path)
    }
}

function Save-Config {
    param ([Alias("config")] [hashtable]$configDict)

    $content = $configDict.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }
    $content | Set-Content -Path $filePath -Encoding UTF8
}

function InitializeConfig {
    param([ref]$SourcePath, [ref]$TargetPath)
    function Get-Config {
        if (Test-Path $ConfigFilePath) {
            Get-Content $ConfigFilePath | ForEach-Object {
                if ($_ -match "^(.*?)=(.*)$") {
                    $Config[$matches[1].Trim()] = $matches[2].Trim()
                }
            }
        }
        return $Config
    }

    $Path = Split-Path -Parent $PSScriptRoot
    $ConfigFilePath = $(Get-ChildItem -Path "$Path" -Recurse -File | Where-Object { $_.Name -like "*.config" }).FullName

    if (-not $ConfigFilePath) {
        $ConfigFilePath = "$Path/Config/PSLinkSmith.config"
    }

    $configFileDir = Split-Path -Parent $ConfigFilePath
    if (-not (Test-Path $configFileDir)) {
        New-Item -ItemType Directory -Path $configFileDir -Force | Out-Null
    }

    $Config = . Get-Config
    $SourcePath = $Config.SourcePath
    $TargetPath = $Config.TargetPath
    if (-not [string]::IsNullOrEmpty($TargetPath)) {
        $FolderBrowserTextBox.Text = $Config.TargetPath
    }

    if ([string]::IsNullOrEmpty($SourcePath)) {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show("Select a Source Directory.", "Warning", "OK", "Warning") | Out-Null

        $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderDialog.Description = "Select a Source Directory"

        if ($folderDialog.ShowDialog() -eq [DialogResult]::OK) {
            $SourcePath = $folderDialog.SelectedPath
            $Config.SourcePath = $SourcePath
            . Save-Config -config $Config
            Write-Host "Selected Source Directory: $SourcePath"
        }
        else {
            Write-Host "No folder selected. Exiting..."
            exit
        }
    }
}

function InitializeComponents {
    $BackgroundPanel = (New-Object -TypeName System.Windows.Forms.Panel)
    $MainTablePanel = (New-Object -TypeName System.Windows.Forms.TableLayoutPanel)

    $RightTablePanel = (New-Object -TypeName System.Windows.Forms.TableLayoutPanel)
    $TokenizedFiltersHeaderTablePanel = (New-Object -TypeName System.Windows.Forms.TableLayoutPanel)
    $TokenizedFiltersHeaderLabel = (New-Object -TypeName System.Windows.Forms.Label)
    $TokenFilterLabelPanel = (New-Object -TypeName System.Windows.Forms.TableLayoutPanel)
    $TokenizedFiltersFlowPanel = (New-Object -TypeName System.Windows.Forms.FlowLayoutPanel)
    $ExcludeTablePanel = (New-Object -TypeName System.Windows.Forms.TableLayoutPanel)
    $ExcludeLabel = (New-Object -TypeName Label)
    $ExcludeTextBox = (New-Object -TypeName System.Windows.Forms.TextBox)
    $SubmitTablePanel = (New-Object -TypeName System.Windows.Forms.TableLayoutPanel)
    $SubmitButton = (New-Object -TypeName System.Windows.Forms.Button)

    $LeftTablePanel = (New-Object -TypeName System.Windows.Forms.TableLayoutPanel)
    $FolderBrowserTable = (New-Object -TypeName System.Windows.Forms.TableLayoutPanel)
    $FolderBrowserTextBox = (New-Object -TypeName System.Windows.Forms.TextBox)
    $FolderBrowserButton = (New-Object -TypeName System.Windows.Forms.Button)
    $AssetsTreeView = (New-Object -TypeName System.Windows.Forms.TreeView)

    $Form.SuspendLayout()

    $BackgroundPanel.SuspendLayout()
    $MainTablePanel.SuspendLayout()

    $RightTablePanel.SuspendLayout()
    $TokenizedFiltersFlowPanel.SuspendLayout()
    $TokenizedFiltersHeaderTablePanel.SuspendLayout()
    $SubmitTablePanel.SuspendLayout()

    $LeftTablePanel.SuspendLayout()
    $FolderBrowserTable.SuspendLayout()


    #
    #BackgroundPanel
    #
    $BackgroundPanel.AutoSize = $true
    $BackgroundPanel.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink
    $BackgroundPanel.BackColor = [System.Drawing.Color]::Snow
    $BackgroundPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $BackgroundPanel.Controls.Add($MainTablePanel)
    $BackgroundPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
    $BackgroundPanel.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]0, [System.Int32]0))
    $BackgroundPanel.Name = [System.String]'BackgroundPanel'
    $BackgroundPanel.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]784, [System.Int32]561))
    $BackgroundPanel.TabIndex = [System.Int32]0
    #
    #MainTablePanel
    #
    $MainTablePanel.AllowDrop = $true
    $MainTablePanel.AutoSize = $true
    $MainTablePanel.BackColor = [System.Drawing.Color]::Transparent
    $MainTablePanel.ColumnCount = [System.Int32]2
    $MainTablePanel.ColumnStyles.Add((New-Object -TypeName System.Windows.Forms.ColumnStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, [System.Single]30.76923)))
    $MainTablePanel.ColumnStyles.Add((New-Object -TypeName System.Windows.Forms.ColumnStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, [System.Single]69.23077)))
    $MainTablePanel.Controls.Add($RightTablePanel, [System.Int32]1, [System.Int32]0)
    $MainTablePanel.Controls.Add($LeftTablePanel, [System.Int32]0, [System.Int32]0)
    $MainTablePanel.Dock = [System.Windows.Forms.DockStyle]::Fill
    $MainTablePanel.GrowStyle = [System.Windows.Forms.TableLayoutPanelGrowStyle]::FixedSize
    $MainTablePanel.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]0, [System.Int32]0))
    $MainTablePanel.Name = [System.String]'MainTablePanel'
    $MainTablePanel.RowCount = [System.Int32]1
    $MainTablePanel.RowStyles.Add((New-Object -TypeName System.Windows.Forms.RowStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, [System.Single]50)))
    $MainTablePanel.RowStyles.Add((New-Object -TypeName System.Windows.Forms.RowStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, [System.Single]50)))
    $MainTablePanel.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]780, [System.Int32]557))
    $MainTablePanel.TabIndex = [System.Int32]0
    #
    #RightTablePanel
    #
    $RightTablePanel.Anchor = ([System.Windows.Forms.AnchorStyles][System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right)
    $RightTablePanel.AutoSize = $true
    $RightTablePanel.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink
    $RightTablePanel.BackColor = [System.Drawing.Color]::GhostWhite
    $RightTablePanel.ColumnCount = [System.Int32]1
    $RightTablePanel.ColumnStyles.Add((New-Object -TypeName System.Windows.Forms.ColumnStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, [System.Single]100)))
    $RightTablePanel.Controls.Add($SubmitTablePanel, [System.Int32]0, [System.Int32]3)
    $RightTablePanel.Controls.Add($ExcludeTablePanel, [System.Int32]0, [System.Int32]2)
    $RightTablePanel.Controls.Add($TokenizedFiltersFlowPanel, [System.Int32]0, [System.Int32]1)
    $RightTablePanel.Controls.Add($TokenizedFiltersHeaderTablePanel, [System.Int32]0, [System.Int32]0)
    $RightTablePanel.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]242, [System.Int32]3))
    $RightTablePanel.MinimumSize = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]100, [System.Int32]100))
    $RightTablePanel.Name = [System.String]'RightTablePanel'
    $RightTablePanel.RowCount = [System.Int32]4
    $RightTablePanel.RowStyles.Add((New-Object -TypeName System.Windows.Forms.RowStyle -ArgumentList @([System.Windows.Forms.SizeType]::Absolute, [System.Single]35)))
    $RightTablePanel.RowStyles.Add((New-Object -TypeName System.Windows.Forms.RowStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, [System.Single]70)))
    $RightTablePanel.RowStyles.Add((New-Object -TypeName System.Windows.Forms.RowStyle -ArgumentList @([System.Windows.Forms.SizeType]::AutoSize)))
    $RightTablePanel.RowStyles.Add((New-Object -TypeName System.Windows.Forms.RowStyle -ArgumentList @([System.Windows.Forms.SizeType]::AutoSize)))
    $RightTablePanel.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]535, [System.Int32]551))
    $RightTablePanel.TabIndex = [System.Int32]0

    #
    #SubmitTablePanel
    #
    $SubmitTablePanel.Anchor = ([System.Windows.Forms.AnchorStyles][System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right)
    $SubmitTablePanel.AutoSize = $true
    $SubmitTablePanel.ColumnCount = [System.Int32]2
    $SubmitTablePanel.ColumnStyles.Add((New-Object -TypeName System.Windows.Forms.ColumnStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, [System.Single]100)))
    $SubmitTablePanel.ColumnStyles.Add((New-Object -TypeName System.Windows.Forms.ColumnStyle -ArgumentList @([System.Windows.Forms.SizeType]::Absolute, [System.Single]120)))
    $SubmitTablePanel.Controls.Add($SubmitButton, [System.Int32]1, [System.Int32]0)
    $SubmitTablePanel.GrowStyle = [System.Windows.Forms.TableLayoutPanelGrowStyle]::FixedSize
    $SubmitTablePanel.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]412, [System.Int32]503))
    $SubmitTablePanel.Name = [System.String]'SubmitTablePanel'
    $SubmitTablePanel.RowCount = [System.Int32]1
    $SubmitTablePanel.RowStyles.Add((New-Object -TypeName System.Windows.Forms.RowStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, [System.Single]100)))
    $SubmitTablePanel.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]227, [System.Int32]29))
    $SubmitTablePanel.TabIndex = [System.Int32]1
    # $SubmitTablePanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

    #
    #SubmitButton
    #
    $SubmitButton.Anchor = ([System.Windows.Forms.AnchorStyles][System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right)
    $SubmitButton.Font = (New-Object -TypeName System.Drawing.Font -ArgumentList @([String]'Fira Code Medium', [Single]9.75))
    $SubmitButton.AutoSize = $true
    $SubmitButton.Name = [System.String]'SubmitButton'
    $SubmitButton.TabIndex = [System.Int32]0
    $SubmitButton.Text = [System.String]'SUBMIT'
    $SubmitButton.UseVisualStyleBackColor = $true
    $SubmitButton.add_Click($SubmitButton_Click)
    $SubmitButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard

    #
    #TokenizedFiltersFlowPanel
    #
    $TokenizedFiltersFlowPanel.Anchor = ([System.Windows.Forms.AnchorStyles][System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right)
    $TokenizedFiltersFlowPanel.BackColor = [System.Drawing.Color]::WhiteSmoke
    $TokenizedFiltersFlowPanel.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]3, [System.Int32]38))
    $TokenizedFiltersFlowPanel.Name = [System.String]'TokenizedFiltersFlowPanel'
    $TokenizedFiltersFlowPanel.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]529, [System.Int32]303))
    $TokenizedFiltersFlowPanel.TabIndex = [System.Int32]0
    $TokenizedFiltersFlowPanel.WrapContents = $true
    $TokenizedFiltersFlowPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

    #
    #TokenFilterLabelPanel
    #
    $TokenFilterLabelPanel.AutoSize = $true
    $TokenFilterLabelPanel.BackColor = [System.Drawing.Color]::Lavender
    $TokenFilterLabelPanel.CellBorderStyle = [System.Windows.Forms.TableLayoutPanelCellBorderStyle]::Single
    $TokenFilterLabelPanel.ColumnCount = [System.Int32]1
    $TokenFilterLabelPanel.ColumnStyles.Add((New-Object -TypeName System.Windows.Forms.ColumnStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, [System.Single]50)))
    $TokenFilterLabelPanel.ColumnStyles.Add((New-Object -TypeName System.Windows.Forms.ColumnStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, [System.Single]50)))
    $TokenFilterLabelPanel.Font = (New-Object -TypeName System.Drawing.Font -ArgumentList @([System.String]'Fira Code Retina', [System.Single]8.25, [System.Drawing.FontStyle]::Bold))
    $TokenFilterLabelPanel.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]3, [System.Int32]3))
    $TokenFilterLabelPanel.Name = [System.String]'TokenFilterLabelPanel'
    $TokenFilterLabelPanel.RowCount = [System.Int32]1
    $TokenFilterLabelPanel.RowStyles.Add((New-Object -TypeName System.Windows.Forms.RowStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, [System.Single]50)))
    $TokenFilterLabelPanel.RowStyles.Add((New-Object -TypeName System.Windows.Forms.RowStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, [System.Single]50)))
    $TokenFilterLabelPanel.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]2, [System.Int32]2))
    $TokenFilterLabelPanel.TabIndex = [System.Int32]2

    #
    # ExcludeTablePanel
    #
    $ExcludeTablePanel.Anchor = ([System.Windows.Forms.AnchorStyles][System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Left)
    $ExcludeTablePanel.AutoSize = $true
    $ExcludeTablePanel.BackColor = [System.Drawing.Color]::GhostWhite
    $ExcludeTablePanel.CellBorderStyle = [System.Windows.Forms.TableLayoutPanelCellBorderStyle]::Single
    $ExcludeTablePanel.RowCount = [System.Int32]1
    $ExcludeTablePanel.ColumnCount = [System.Int32]2
    $ExcludeTablePanel.ColumnStyles.Add((New-Object -TypeName System.Windows.Forms.ColumnStyle -ArgumentList @([System.Windows.Forms.SizeType]::Absolute, [System.Single]90)))
    $ExcludeTablePanel.ColumnStyles.Add((New-Object -TypeName System.Windows.Forms.ColumnStyle -ArgumentList @([System.Windows.Forms.SizeType]::AutoSize)))
    $ExcludeTablePanel.RowStyles.Add((New-Object -TypeName System.Windows.Forms.RowStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, [System.Single]100)))
    $ExcludeTablePanel.Controls.Add($ExcludeLabel)
    $ExcludeTablePanel.Controls.Add($ExcludeTextBox)
    $ExcludeTablePanel.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]120, [System.Int32]60))
    $ExcludeTablePanel.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]412, [System.Int32]503))
    $ExcludeTablePanel.Name = [System.String]'ExcludeTablePanel'
    $ExcludeTablePanel.GrowStyle = [System.Windows.Forms.TableLayoutPanelGrowStyle]::FixedSize
    $ExcludeTablePanel.TabIndex = [System.Int32]1

    #
    #ExcludeLabel
    #
    $ExcludeLabel.Anchor = ([AnchorStyles]::Left -bor [AnchorStyles]::Top -bor [AnchorStyles]::Right)
    $ExcludeLabel.BackColor = [System.Drawing.Color]::GhostWhite
    $ExcludeLabel.BorderStyle = [BorderStyle]::None
    $ExcludeLabel.Font = (New-Object -TypeName System.Drawing.Font -ArgumentList @([System.String]'Fira Code Medium', [System.Single]9.75))
    $ExcludeLabel.Name = [System.String]'ExcludeLabel'
    $ExcludeLabel.TabIndex = [System.Int32]0
    $ExcludeLabel.Text = [System.String]"Exclude:"
    $ExcludeLabel.TextAlign = [ContentAlignment]::MiddleCenter

    #
    #ExcludeTextBox
    #
    $ExcludeTextBox.Visible = $true
    $ExcludeTextBox.Enabled = $true
    $ExcludeTextBox.Anchor = ([AnchorStyles]::Left -bor [AnchorStyles]::Right)
    $ExcludeTextBox.BackColor = [System.Drawing.Color]::WhiteSmoke
    # $ExcludeTextBox.BorderStyle = [BorderStyle]::FixedSingle
    $ExcludeTextBox.BorderStyle = [BorderStyle]::None
    $ExcludeTextBox.Name = [System.String]'ExcludeTextBox'
    $ExcludeTextBox.Font = (New-Object -TypeName Font -ArgumentList @([System.String]'Fira Code Retina', [System.Single]8.25, [System.Drawing.FontStyle]::Bold))
    $ExcludeTextBox.Location = (New-Object -TypeName Point -ArgumentList @([System.Int32]3, [System.Int32]8))
    $ExcludeTextBox.TabIndex = [System.Int32]0
    $ExcludeTextBox.Text = ""
    $ExcludeTextBox.TextAlign = [HorizontalAlignment]::Left

    #
    #TokenizedFiltersHeaderTablePanel
    #
    $TokenizedFiltersHeaderTablePanel.Anchor = ([System.Windows.Forms.AnchorStyles][System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right)
    $TokenizedFiltersHeaderTablePanel.AutoSize = $true
    $TokenizedFiltersHeaderTablePanel.ColumnCount = [System.Int32]2
    $TokenizedFiltersHeaderTablePanel.ColumnStyles.Add((New-Object -TypeName System.Windows.Forms.ColumnStyle -ArgumentList @([System.Windows.Forms.SizeType]::Absolute, [System.Single]100)))
    $TokenizedFiltersHeaderTablePanel.ColumnStyles.Add((New-Object -TypeName System.Windows.Forms.ColumnStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, [System.Single]100)))
    $TokenizedFiltersHeaderTablePanel.Controls.Add($TokenizedFiltersHeaderLabel, [System.Int32]0, [System.Int32]0)
    $TokenizedFiltersHeaderTablePanel.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]3, [System.Int32]3))
    $TokenizedFiltersHeaderTablePanel.Name = [System.String]'TokenizedFiltersHeaderTablePanel'
    $TokenizedFiltersHeaderTablePanel.RowCount = [System.Int32]1
    $TokenizedFiltersHeaderTablePanel.RowStyles.Add((New-Object -TypeName System.Windows.Forms.RowStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, [System.Single]100)))
    $TokenizedFiltersHeaderTablePanel.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]529, [System.Int32]29))
    $TokenizedFiltersHeaderTablePanel.TabIndex = [System.Int32]2
    $TokenizedFiltersHeaderTablePanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    #
    #TokenizedFiltersHeaderLabel
    #
    $TokenizedFiltersHeaderLabel.Anchor = ([System.Windows.Forms.AnchorStyles][System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right)
    $TokenizedFiltersHeaderLabel.AutoSize = $true
    $TokenizedFiltersHeaderLabel.Font = (New-Object -TypeName System.Drawing.Font -ArgumentList @([System.String]'Fira Code Medium', [System.Single]9.75))
    $TokenizedFiltersHeaderLabel.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]3, [System.Int32]0))
    $TokenizedFiltersHeaderLabel.Name = [System.String]'TokenizedFiltersHeaderLabel'
    $TokenizedFiltersHeaderLabel.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]94, [System.Int32]29))
    $TokenizedFiltersHeaderLabel.TabIndex = [System.Int32]0
    $TokenizedFiltersHeaderLabel.Text = [System.String]'Filters:'
    $TokenizedFiltersHeaderLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    #
    #LeftTablePanel
    #
    $LeftTablePanel.AutoSize = $true
    $LeftTablePanel.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink
    $LeftTablePanel.BackColor = [System.Drawing.Color]::GhostWhite
    $LeftTablePanel.ColumnCount = [System.Int32]1
    $LeftTablePanel.ColumnStyles.Add((New-Object -TypeName System.Windows.Forms.ColumnStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, [System.Single]100)))
    $LeftTablePanel.Controls.Add($AssetsTreeView, [System.Int32]0, [System.Int32]1)
    $LeftTablePanel.Controls.Add($FolderBrowserTable, [System.Int32]0, [System.Int32]0)
    $LeftTablePanel.Dock = [System.Windows.Forms.DockStyle]::Fill
    $LeftTablePanel.GrowStyle = [System.Windows.Forms.TableLayoutPanelGrowStyle]::FixedSize
    $LeftTablePanel.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]3, [System.Int32]3))
    $LeftTablePanel.Name = [System.String]'LeftTablePanel'
    $LeftTablePanel.RowCount = [System.Int32]2
    $LeftTablePanel.RowStyles.Add((New-Object -TypeName System.Windows.Forms.RowStyle -ArgumentList @([System.Windows.Forms.SizeType]::Absolute, [System.Single]35)))
    $LeftTablePanel.RowStyles.Add((New-Object -TypeName System.Windows.Forms.RowStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, [System.Single]100)))
    $LeftTablePanel.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]233, [System.Int32]551))
    $LeftTablePanel.TabIndex = [System.Int32]1
    #
    #AssetsTreeView
    #
    $AssetsTreeView.Anchor = ([System.Windows.Forms.AnchorStyles][System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right)
    $AssetsTreeView.BackColor = [System.Drawing.Color]::WhiteSmoke
    $AssetsTreeView.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $AssetsTreeView.CheckBoxes = $true
    $AssetsTreeView.Font = (New-Object -TypeName System.Drawing.Font -ArgumentList @([System.String]'Fira Code Retina', [System.Single]9.75))
    $AssetsTreeView.ForeColor = [System.Drawing.Color]::Black
    $AssetsTreeView.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]3, [System.Int32]38))
    $AssetsTreeView.Name = [System.String]'AssetsTreeView'
    $AssetsTreeView.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]227, [System.Int32]510))
    $AssetsTreeView.TabIndex = [System.Int32]0
    $AssetsTreeView.add_AfterCheck($AssetsTreeView_AfterCheck)
    #
    #FolderBrowserTable
    #
    $FolderBrowserTable.Anchor = ([System.Windows.Forms.AnchorStyles][System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right)
    $FolderBrowserTable.ColumnCount = [System.Int32]2
    $FolderBrowserTable.ColumnStyles.Add((New-Object -TypeName System.Windows.Forms.ColumnStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, [System.Single]100)))
    $FolderBrowserTable.ColumnStyles.Add((New-Object -TypeName System.Windows.Forms.ColumnStyle -ArgumentList @([System.Windows.Forms.SizeType]::Absolute, [System.Single]74)))
    $FolderBrowserTable.ColumnStyles.Add((New-Object -TypeName System.Windows.Forms.ColumnStyle -ArgumentList @([System.Windows.Forms.SizeType]::Absolute, [System.Single]20)))
    $FolderBrowserTable.Controls.Add($FolderBrowserTextBox, [System.Int32]0, [System.Int32]0)
    $FolderBrowserTable.Controls.Add($FolderBrowserButton, [System.Int32]1, [System.Int32]0)
    $FolderBrowserTable.GrowStyle = [System.Windows.Forms.TableLayoutPanelGrowStyle]::FixedSize
    $FolderBrowserTable.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]3, [System.Int32]3))
    $FolderBrowserTable.Name = [System.String]'FolderBrowserTable'
    $FolderBrowserTable.RowCount = [System.Int32]1
    $FolderBrowserTable.RowStyles.Add((New-Object -TypeName System.Windows.Forms.RowStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, [System.Single]100)))
    $FolderBrowserTable.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]227, [System.Int32]29))
    $FolderBrowserTable.TabIndex = [System.Int32]1
    #
    #FolderBrowserTextBox
    #
    $FolderBrowserTextBox.Anchor = ([System.Windows.Forms.AnchorStyles][System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right)
    $FolderBrowserTextBox.Font = (New-Object -TypeName System.Drawing.Font -ArgumentList @([System.String]'Fira Code Medium', [System.Single]9.75))
    $FolderBrowserTextBox.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]3, [System.Int32]3))
    $FolderBrowserTextBox.Name = [System.String]'FolderBrowserTextBox'
    $FolderBrowserTextBox.ReadOnly = $true
    $FolderBrowserTextBox.Enabled = $true
    $FolderBrowserTextBox.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]147, [System.Int32]23))
    $FolderBrowserTextBox.TabIndex = [System.Int32]2
    $FolderBrowserTextBox.WordWrap = $false
    $FolderBrowserTextBox.Text = $TargetPath
    $FolderBrowserTextBox.add_TextChanged($FolderBrowserTextBox_TextChanged)
    #
    #FolderBrowserButton
    #
    $FolderBrowserButton.Anchor = ([System.Windows.Forms.AnchorStyles][System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right)
    $FolderBrowserButton.AutoSize = $true
    $FolderBrowserButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard
    $FolderBrowserButton.Font = (New-Object -TypeName System.Drawing.Font -ArgumentList @([System.String]'Fira Code Medium', [System.Single]9.75))
    $FolderBrowserButton.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]156, [System.Int32]3))
    $FolderBrowserButton.Name = [System.String]'FolderBrowserButton'
    $FolderBrowserButton.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]68, [System.Int32]23))
    $FolderBrowserButton.TabIndex = [System.Int32]1
    $FolderBrowserButton.Text = [System.String]'Browse'
    $FolderBrowserButton.UseVisualStyleBackColor = $true
    $FolderBrowserButton.add_Click($FolderBrowserButton_Click)
    #
    #Form
    #
    $Form.Anchor = [System.Windows.Forms.AnchorStyles]::None
    $Form.AutoSize = $true
    $Form.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink
    $Form.ClientSize = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]784, [System.Int32]561))
    $Form.Controls.Add($BackgroundPanel)
    $Form.MaximumSize = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]800, [System.Int32]600))
    $Form.MinimumSize = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]800, [System.Int32]600))
    $Form.Text = [System.String]'Symlinks Spawner'
    $Form.add_Load($Form_Load)
    $BackgroundPanel.ResumeLayout($false)
    $BackgroundPanel.PerformLayout()
    $MainTablePanel.ResumeLayout($false)
    $MainTablePanel.PerformLayout()
    $RightTablePanel.ResumeLayout($false)
    $RightTablePanel.PerformLayout()
    $SubmitTablePanel.ResumeLayout($false)
    $TokenizedFiltersFlowPanel.ResumeLayout($false)
    $TokenizedFiltersFlowPanel.PerformLayout()
    $TokenizedFiltersHeaderTablePanel.ResumeLayout($false)
    $TokenizedFiltersHeaderTablePanel.PerformLayout()
    $ExcludeTablePanel.ResumeLayout($false)
    $ExcludeTablePanel.PerformLayout()
    $ExcludeLabel.ResumeLayout($false)
    $ExcludeLabel.PerformLayout()
    $ExcludeTextBox.ResumeLayout($false)
    $ExcludeTextBox.PerformLayout()
    $LeftTablePanel.ResumeLayout($false)
    $LeftTablePanel.PerformLayout()
    $FolderBrowserTable.ResumeLayout($false)
    $FolderBrowserTable.PerformLayout()
    $Form.ResumeLayout($false)
    $Form.PerformLayout()
    Add-Member -InputObject $Form -Name BackgroundPanel -Value $BackgroundPanel -MemberType NoteProperty
    Add-Member -InputObject $Form -Name MainTablePanel -Value $MainTablePanel -MemberType NoteProperty
    Add-Member -InputObject $Form -Name RightTablePanel -Value $RightTablePanel -MemberType NoteProperty
    Add-Member -InputObject $Form -Name SubmitTablePanel -Value $SubmitTablePanel -MemberType NoteProperty
    Add-Member -InputObject $Form -Name SubmitButton -Value $SubmitButton -MemberType NoteProperty
    Add-Member -InputObject $Form -Name TokenizedFiltersFlowPanel -Value $TokenizedFiltersFlowPanel -MemberType NoteProperty
    Add-Member -InputObject $Form -Name TokenizedFiltersHeaderTablePanel -Value $TokenizedFiltersHeaderTablePanel -MemberType NoteProperty
    Add-Member -InputObject $Form -Name TokenizedFiltersHeaderLabel -Value $TokenizedFiltersHeaderLabel -MemberType NoteProperty
    Add-Member -InputObject $Form -Name LeftTablePanel -Value $LeftTablePanel -MemberType NoteProperty
    Add-Member -InputObject $Form -Name AssetsTreeView -Value $AssetsTreeView -MemberType NoteProperty
    Add-Member -InputObject $Form -Name FolderBrowserTable -Value $FolderBrowserTable -MemberType NoteProperty
    Add-Member -InputObject $Form -Name FolderBrowserTextBox -Value $FolderBrowserTextBox -MemberType NoteProperty
    Add-Member -InputObject $Form -Name FolderBrowserButton -Value $FolderBrowserButton -MemberType NoteProperty
    Add-Member -InputObject $Form -Name ExcludeTablePanel -Value $ExcludeTablePanel -MemberType NoteProperty
    Add-Member -InputObject $Form -Name ExcludeTextBox -Value $ExcludeTextBox -MemberType NoteProperty
    Add-Member -InputObject $Form -Name ExcludeLabel -Value $ExcludeLabel -MemberType NoteProperty

    . InitializeConfig
}
. InitializeComponents

# class BetterTextBox : UserControl {
#     [TextBox]$TextB
#     [String]$Text
#     [Bool]$ReadOnly
#     [ContentAlignment]$TextAlign
#     [String]$Tag
#     [Color]$BackColor
#     [Color]$ForeColor
#     [Font]$Font
#     [BorderStyle]$BorderStyle
#     [bool]$WordWrap
#     [bool]$MultiLine
#     [Cursor]$Cursor


#     BetterTextBox() {
#         $this.Init()
#     }

#     [void]Init() {
#         $this.BorderStyle = [BorderStyle]::FixedSingle
#         $this.BackColor = [SystemColors]::Window
#         $this.TextB = New-Object TextBox
#         $this.TextB.BorderStyle = [BorderStyle]::None
#         $this.Controls.Add($this.TextB)
#         $this.AutoSize = $true
#         $this.TextB.AutoSize = $false
#         $this.TextB.TextAlign = [HorizontalAlignment]::Center
#         $this.Add_click({
#             param([Object]$sdr, [EventArgs]$e)
#             Write-Host "Clicked on BetterTextBox UserControl"
#         })
#         $this.Add_Resize({
#             param([Object]$sdr, [EventArgs]$e)
#             $sdr.TextB.Left = 0
#             $sdr.TextB.Top = ($sdr.Height - $sdr.TextB.Height) / 2
#         })
#         $this.Add_Click(
#             {
#                 param(
#                     [Object]$sdr,
#                     [EventArgs]$e
#                 )
#                 if ($sdr.ReadOnly) {
#                     $sdr.ReadOnly = $false
#                 }
#             })
#         $this.Add_MouseUp({
#                 param ($sdr, $e)
#                 if ($sdr.TextB.SelectionStart -lt $sdr.TextB.Tag.Length) {
#                     $sdr.TextB.SelectionStart = $sdr.TextB.Tag.Length
#                     $sdr.TextB.SelectionLength = 0
#                 }
#             })

#             $this.add_MouseEnter({
#                 param([Object]$sdr, [EventArgs]$e)
#                 $toolTip = [ToolTip]::new()
#                 $toolTip.SetToolTip($sdr, [String]$sdr.TextB.Text)
#                 $sdr.BackColor = [Color]::Black
#                 $sdr.ForeColor = [Color]::LightGray
#                 $sdr.TextB.BackColor = [Color]::Black
#                 $sdr.TextB.ForeColor = [Color]::LightGray
#             })

#             $this.add_MouseLeave({
#                 param([Object]$sdr, [EventArgs]$e)
#                 $sdr.BackColor = [Color]::LightGray
#                 $sdr.ForeColor = [Color]::Black
#                 $sdr.TextB.BackColor = [Color]::LightGray
#                 $sdr.TextB.ForeColor = [Color]::Black
#             })

#         }


#     [string]get_Text() {
#         return $this.TextB.Text
#     }
#     [void]set_Text([string]$value) {
#         $this.TextB.Text = $value
#     }

#     [ContentAlignment]get_TextAlign() {
#         return $this.TextB.TextAlign
#     }

#     [string]get_Tag() {
#         return $this.TextB.Tag
#     }
#     [void]set_Tag([string]$value) {
#         $this.TextB.Tag = $value
#     }

#     [bool]get_ReadOnly() {
#         return $this.TextB.ReadOnly
#     }
#     [void]set_ReadOnly([bool]$value) {
#         $this.TextB.ReadOnly = $value
#     }

#     [bool]get_WordWrap() {
#         return $this.TextB.WordWrap
#     }
#     [void]set_WordWrap([bool]$value) {
#         $this.TextB.WordWrap = $value
#     }

#     [bool]get_MultiLine() {
#         return $this.TextB.MultiLine
#     }
#     [void]set_MultiLine([bool]$value) {
#         $this.TextB.MultiLine = $value
#     }

#     [Cursor]get_Cursor() {
#         return $this.TextB.Cursor
#     }
#     [void]set_Cursor([Cursor]$value) {
#         $this.TextB.Cursor = $value
#     }

#     [Color]get_PropertyBackColor() {
#         return $this.TextB.BackColor
#     }
#     [void]set_PropertyBackColor([Color]$value) {
#         $this.TextB.BackColor = $value
#     }

#     [Color]get_ForeColor() {
#         return $this.TextB.ForeColor
#     }
#     [void]set_ForeColor([Color]$value) {
#         $this.TextB.ForeColor = $value
#     }

#     [Font]get_PropertyFont() {
#         return $this.TextB.Font
#     }
#     [void]set_PropertyFont([Font]$value) {
#         $this.TextB.Font = $value
#     }

#     [void]add_TextChanged([scriptblock]$value) {
#         $this.TextB.add_TextChanged($value)
#     }

#     [void]add_ReadOnlyChanged([scriptblock]$value) {
#         $this.TextB.add_ReadOnlyChanged($value)
#     }

#     [void]add_Click([scriptblock]$value) {
#         $this.TextB.add_Click($value)
#     }

#     [void]Add_KeyUp([scriptblock]$value) {
#         $this.TextB.Add_KeyUp($value)
#     }

#     [void]Add_KeyDown([scriptblock]$value) {
#         $this.TextB.Add_KeyDown($value)
#     }

#     [void]Add_MouseUp([scriptblock]$value) {
#         $this.TextB.Add_MouseUp($value)
#     }

#     [void]Add_GotFocus([scriptblock]$value) {
#         $this.TextB.Add_GotFocus($value)
#     }
# }

# class TokenFilterElement : Panel {

#     [String]$Directory = [Path]::GetFullPath($Node.Tag)
#     [String]$Filter = ""
#     [Bool]$IsExclude = $false

#     [String]GetFilter() {
#         return "$($this.Directory)\$($this.Filter)"
#     }

#     TokenFilterElement([TreeNode]$Node) {
#         $this.Init($Node)
#     }

#     [void]Init([TreeNode]$Node) {

#         $this.Name = [String]$Node.Tag
#         $this.AutoSize = $true
#         $this.Tag = [System.String]"$(Format-NodePathTag -Tag $Node.Tag)\"
#         $this.BackColor = [System.Drawing.Color]::LightGray
#         $this.ForeColor = [System.Drawing.Color]::Black
#         $this.Add_click({
#             param([Object]$sdr, [EventArgs]$e)
#             Write-Host "Clicked on panel $sdr.Tag"
#         })
#         $this.SetControls()
#     }

#     [void]SetControls() {
#         $textBox =  New-Object BetterTextBox
#         $textBox.Tag = $this.Tag
#         $textBox.Text = "$($this.Tag)\*"
#         $textBox.Cursor = [Cursors]::Hand
#         $textBox.ReadOnly = $true
#         $textBox.BackColor = $this.BackColor
#         $textBox.ForeColor =  $this.ForeColor
#         $this.Controls.Add($textBox)
#         $textBox.Add_ReadOnlyChanged({
#                 param ($sdr, $e)
#                 if ($sdr.ReadOnly) {
#                     $sdr.Cursor = [Cursors]::Default
#                     $sdr.Focus()
#                 }
#                 else {
#                     $sdr.Cursor = [Cursors]::Hand
#                 }
#             })
#         $textBox.Add_Click(
#             {
#                 param(
#                     [Object]$sdr,
#                     [EventArgs]$e
#                 )
#                 if ($sdr.ReadOnly) {
#                     $sdr.ReadOnly = $false
#                 }
#             })
#         # Handle input restrictions
#         $textBox.Add_KeyUp({
#                 param(
#                     [Object]$sdr,
#                     [KeyEventArgs]$e
#                 )
#                 if (($e.KeyCode -eq [Keys]::Enter -or $e.KeyCode -eq [Keys]::Return) -and $sdr.Focused) {
#                     if ($null -eq $sdr.Text -or $sdr.Text -eq $sdr.Tag) { $sdr.Text = $sdr.Tag }
#                     else {
#                         $filePattern = [Path]::GetFileName($sdr.Text).Replace("%", "*")
#                         $directory = [Path]::GetDirectoryName($sdr.Tag)
#                         $expectedPattern = "$($directory)\$filePattern"

#                         $isFilterInvalid = (
#                             -not ($filePattern -and ($filePattern -notmatch "[/\\]")) -or
#                             -not ($filePattern.IndexOfAny([Path]::GetInvalidPathChars()) -eq -1)
#                         )

#                         if ($isFilterInvalid) {
#                             $sdr.Text = $sdr.Tag
#                         }
#                         else {
#                             $sdr.Tag = $expectedPattern
#                             $sdr.Text = $sdr.Tag
#                             $sdr.Parent.Filter = $filePattern
#                         }
#                     }
#                     $sdr.ReadOnly = $True
#                 }
#             }
#         )
#         $textBox.Add_KeyDown({
#                 param ($sdr, $e)
#                 if ($sdr.SelectionStart -le $sdr.Tag.Length) {
#                     if ($e.KeyCode -eq "Delete" -and $sdr.SelectionStart -eq $sdr.Tag.Length) {
#                         return
#                     }
#                     if ($e.KeyCode -eq "Back") {
#                         $e.SuppressKeyPress = $true
#                         return
#                     }
#                     if ($e.KeyCode -eq "Left" -or $e.KeyCode -eq "Home") {
#                         $e.SuppressKeyPress = $true
#                         $sdr.SelectionStart = $sdr.Tag.Length
#                         return
#                     }
#                 }
#             })
#         $textBox.Add_MouseUp({
#                 param ($sdr, $e)
#                 if ($sdr.SelectionStart -lt $sdr.Tag.Length) {
#                     $sdr.SelectionStart = $sdr.Tag.Length
#                     $sdr.SelectionLength = 0
#                 }
#             })
#         $textBox.Add_GotFocus({
#                 param ($sdr, $e)
#                 $sdr.SelectionStart = $sdr.Tag.Length
#                 $sdr.SelectionLength = 0
#             })
#         }

#     [void]Set_MouseHoverEvents([Control]$ctrl) {
#         $ctrl.add_MouseEnter({
#                 param([Object]$sdr, [EventArgs]$e)

#                 if ($sdr.GetType() -ne [TokenFilterElement]) {
#                     $sdr = $sdr.Parent
#                 }
#                 $toolTip = [ToolTip]::new()
#                 $toolTip.SetToolTip($sdr, [String]$sdr.Text)

#                 $sdr.BackColor = [Color]::Black
#                 $sdr.ForeColor = [Color]::LightGray
#                 foreach ($control in $sdr.Controls) {
#                     try {
#                         $sdr._ToolTip.SetToolTip($this, [String]$this.Text)
#                         $control.BackColor = $backColor
#                         $control.ForeColor = $foreColor
#                     }
#                     catch {
#                         Write-Debug $_.Exception.Message
#                     }
#                 }
#             })

#         $ctrl.add_MouseLeave( {
#                 param([Object]$sdr, [EventArgs]$e)

#                 if ($sdr.GetType() -ne [TokenFilterElement]) {
#                     $sdr = $sdr.Parent
#                 }
#                 $sdr.BackColor = [Color]::LightGray
#                 $sdr.ForeColor = [Color]::Black
#                 foreach ($control in $sdr.Controls) {
#                     try {
#                         $control.BackColor = $backColor
#                         $control.ForeColor = $foreColor
#                     }
#                     catch {
#                         Write-Debug $_.Exception.Message
#                     }
#                 }
#             })
#     }
# }
