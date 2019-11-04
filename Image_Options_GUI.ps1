<#
#>

# Add GUI Assembly
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()
# Create and Configure Window
$ImageOptions                    = New-Object system.Windows.Forms.Form
$ImageOptions.ClientSize         = '600,400'
$ImageOptions.text               = "Image Options GUI V1.0"
$ImageOptions.TopMost            = $false

$TitleLabel                      = New-Object system.Windows.Forms.Label
$TitleLabel.text                 = "Image Options GUI V1.0"
$TitleLabel.AutoSize             = $true
$TitleLabel.width                = 25
$TitleLabel.height               = 10
$TitleLabel.location             = New-Object System.Drawing.Point(15,17)
$TitleLabel.Font                 = 'Microsoft Sans Serif,15'

$CodedByLabel                    = New-Object system.Windows.Forms.Label
$CodedByLabel.text               = "Coded by: Hunter Pittman"
$CodedByLabel.AutoSize           = $true
$CodedByLabel.width              = 25
$CodedByLabel.height             = 10
$CodedByLabel.location           = New-Object System.Drawing.Point(16,43)
$CodedByLabel.Font               = 'Microsoft Sans Serif,10'

$OptionsComboBox                 = New-Object system.Windows.Forms.ComboBox
$OptionsComboBox.text            = "Click for Options"
$OptionsComboBox.width           = 139
$OptionsComboBox.height          = 20
@('Banner Format','Normal Format','Link Block Format','Profile Format','Custom Format','File Stats') | ForEach-Object {[void] $OptionsComboBox.Items.Add($_)}
$OptionsComboBox.location        = New-Object System.Drawing.Point(157,94)
$OptionsComboBox.Font            = 'Microsoft Sans Serif,10'

$ComboBoxLabel                   = New-Object system.Windows.Forms.Label
$ComboBoxLabel.text              = "Select Image Option:"
$ComboBoxLabel.AutoSize          = $true
$ComboBoxLabel.width             = 25
$ComboBoxLabel.height            = 10
$ComboBoxLabel.location          = New-Object System.Drawing.Point(22,96)
$ComboBoxLabel.Font              = 'Microsoft Sans Serif,10'

$FileSizeCheckBox                = New-Object system.Windows.Forms.CheckBox
$FileSizeCheckBox.text           = "Reduce File Size"
$FileSizeCheckBox.AutoSize       = $false
$FileSizeCheckBox.width          = 111
$FileSizeCheckBox.height         = 20
$FileSizeCheckBox.location       = New-Object System.Drawing.Point(22,129)
$FileSizeCheckBox.Font           = 'Microsoft Sans Serif,10'

$BatchCheckBox                   = New-Object system.Windows.Forms.CheckBox
$BatchCheckBox.text              = "Batch Job"
$BatchCheckBox.AutoSize          = $false
$BatchCheckBox.width             = 95
$BatchCheckBox.height            = 20
$BatchCheckBox.location          = New-Object System.Drawing.Point(218,129)
$BatchCheckBox.Font              = 'Microsoft Sans Serif,10'

$PathBoxLabel                    = New-Object system.Windows.Forms.Label
$PathBoxLabel.text               = "Enter Path:"
$PathBoxLabel.AutoSize           = $true
$PathBoxLabel.width              = 25
$PathBoxLabel.height             = 10
$PathBoxLabel.location           = New-Object System.Drawing.Point(7,209)
$PathBoxLabel.Font               = 'Microsoft Sans Serif,10'

$HowToLabel                      = New-Object system.Windows.Forms.Label
$HowToLabel.text                 = "When entering path include the extension, if you have chosen custom do not end in a `"/`""
$HowToLabel.AutoSize             = $true
$HowToLabel.width                = 25
$HowToLabel.height               = 10
$HowToLabel.location             = New-Object System.Drawing.Point(7,172)
$HowToLabel.Font                 = 'Microsoft Sans Serif,10'

$EnterPathTextBox                = New-Object system.Windows.Forms.TextBox
$EnterPathTextBox.multiline      = $false
$EnterPathTextBox.width          = 375
$EnterPathTextBox.height         = 20
$EnterPathTextBox.location       = New-Object System.Drawing.Point(92,205)
$EnterPathTextBox.Font           = 'Microsoft Sans Serif,10'

$FormatButton                    = New-Object system.Windows.Forms.Button
$FormatButton.text               = "Format"
$FormatButton.width              = 60
$FormatButton.height             = 30
$FormatButton.location           = New-Object System.Drawing.Point(522,355)
$FormatButton.Font               = 'Microsoft Sans Serif,10'

$ImageOptions.controls.AddRange(@($TitleLabel,$CodedByLabel,$OptionsComboBox,$ComboBoxLabel,$FileSizeCheckBox,$BatchCheckBox,$PathBoxLabel,$HowToLabel,$EnterPathTextBox,$FormatButton))

# LOGIC STARTS HERE
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

function Hello-World {
    New-Item C:\Users\006828426\Pictures\ResizeFolder\test.txt
}
Function Resize-Image() {
    [CmdLetBinding(
        SupportsShouldProcess=$true, 
        PositionalBinding=$false,
        ConfirmImpact="Medium",
        DefaultParameterSetName="Absolute"
    )]
    Param (
        [Parameter(Mandatory=$True)]
        [ValidateScript({
            $_ | ForEach-Object {
                Test-Path $_
            }
        })][String[]]$ImagePath,
        [Parameter(Mandatory=$False)][Switch]$MaintainRatio,
        [Parameter(Mandatory=$False, ParameterSetName="Absolute")][Int]$Height,
        [Parameter(Mandatory=$False, ParameterSetName="Absolute")][Int]$Width,
        [Parameter(Mandatory=$False, ParameterSetName="Percent")][Double]$Percentage,
        [Parameter(Mandatory=$False)][System.Drawing.Drawing2D.SmoothingMode]$SmoothingMode = "HighQuality",
        [Parameter(Mandatory=$False)][System.Drawing.Drawing2D.InterpolationMode]$InterpolationMode = "HighQualityBicubic",
        [Parameter(Mandatory=$False)][System.Drawing.Drawing2D.PixelOffsetMode]$PixelOffsetMode = "HighQuality",
        [Parameter(Mandatory=$False)][String]$NameModifier = "resized"
    )
    Begin {
        If ($Width -and $Height -and $MaintainRatio) {
            Throw "Absolute Width and Height cannot be given with the MaintainRatio parameter."
        }
  
        If (($Width -xor $Height) -and (-not $MaintainRatio)) {
            Throw "MaintainRatio must be set with incomplete size parameters (Missing height or width without MaintainRatio)"
        }
  
        If ($Percentage -and $MaintainRatio) {
            Write-Warning "The MaintainRatio flag while using the Percentage parameter does nothing"
        }
    }
    Process {
        ForEach ($Image in $ImagePath) {
            $Path = (Resolve-Path $Image).Path
            $Dot = $Path.LastIndexOf(".")
 
            #Add name modifier (OriginalName_{$NameModifier}.jpg)
            $OutputPath = $Path.Substring(0,$Dot) + "_" + $NameModifier + $Path.Substring($Dot,$Path.Length - $Dot)
             
            $OldImage = New-Object -TypeName System.Drawing.Bitmap -ArgumentList $Path
            # Grab these for use in calculations below. 
            $OldHeight = $OldImage.Height
            $OldWidth = $OldImage.Width
  
            If ($MaintainRatio) {
                $OldHeight = $OldImage.Height
                $OldWidth = $OldImage.Width
                If ($Height) {
                    $Width = $OldWidth / $OldHeight * $Height
                }
                If ($Width) {
                    $Height = $OldHeight / $OldWidth * $Width
                }
            }
  
            If ($Percentage) {
                $Product = ($Percentage / 100)
                $Height = $OldHeight * $Product
                $Width = $OldWidth * $Product
            }
 
            $Bitmap = New-Object -TypeName System.Drawing.Bitmap -ArgumentList $Width, $Height
            $NewImage = [System.Drawing.Graphics]::FromImage($Bitmap)
              
            #Retrieving the best quality possible
            $NewImage.SmoothingMode = $SmoothingMode
            $NewImage.InterpolationMode = $InterpolationMode
            $NewImage.PixelOffsetMode = $PixelOffsetMode
            $NewImage.DrawImage($OldImage, $(New-Object -TypeName System.Drawing.Rectangle -ArgumentList 0, 0, $Width, $Height))
 
            If ($PSCmdlet.ShouldProcess("Resized image based on $Path", "save to $OutputPath")) {
                $Bitmap.Save($OutputPath)
            }
             
            $Bitmap.Dispose()
            $NewImage.Dispose()
        }
    }
}
function Banner-Change {
    cd $PSScriptRoot

    # Image path generation
    $BatchJobOption = Read-Host "Is this a batch format(y/n)"

    if ($BatchJobOption -eq 'y') {
        $GetDirectory = Read-Host "What directory are the images stored at(Do not end with a \) "
        $DirectoryWildcard = $GetDirectory + "\*"
        $Files = @(Get-ChildItem -Path $DirectoryWildcard)
        

        foreach($dir in $Files) {
            Resize-Image -Width 1920 -Height 620 -ImagePath $dir
        }
        
        Start-Sleep -s 5
        $ResizedFiles = @(Get-ChildItem -Path $DirectoryWildcard)

        foreach($ResizedDir in $ResizedFiles) {
            Rename-Item -Path $ResizedDir -NewName ([io.path]::ChangeExtension($ResizedDir, '.png'))
        }

    } else {
        $GetSingleDirectory = Read-Host "Enter path of the image to be formatted (include extension)"
        Resize-Image -Width 1920 -Height 620 -ImagePath $GetSingleDirectory
        $DirectoryWithoutExtension = $GetSingleDirectory.split('.')[0]
        $Dimensions = "1920x620"
        $ModifiedSingleName = $DirectoryWithoutExtension + "_resized_" + $Dimensions
        $OldDirectory = $ModifiedSingleName + "." + $GetSingleDirectory.split('.')[1]
        Rename-Item -Path $OldDirectory -NewName ([io.path]::ChangeExtension($OldDirectory, '.png'))
        $FullDirectory = $ModifiedSingleName + ".png"
        $FinishMessage = "The image has been succesfully formatted and is at $FullDirectory"
        Write-Host $FinishMessage
    }
 
}


function Normal-Change {
    $BatchJobOption = Read-Host "Is this a batch format(y/n)"
    
    if ($BatchJobOption -eq 'y') {
        $GetDirectory = Read-Host "What directory are the images stored at(Do not end with a \) "
        $DirectoryWildcard = $GetDirectory + "\*"
        $Files = @(Get-ChildItem -Path $DirectoryWildcard)
        

        foreach($dir in $Files) {
            Resize-Image -Width 1920 -Height 620 -ImagePath $dir
        }
        
        Start-Sleep -s 5
        $ResizedFiles = @(Get-ChildItem -Path $DirectoryWildcard)

        foreach($ResizedDir in $ResizedFiles) {
            Rename-Item -Path $ResizedDir -NewName ([io.path]::ChangeExtension($ResizedDir, '.png'))
        }

    } else {
        $GetSingleDirectory = Read-Host "Enter path of the image to be formatted"
        Resize-Image -Width 2550 -Height 1656 -ImagePath $GetSingleDirectory
        $DirectoryWithoutExtension = $GetSingleDirectory.split('.')[0]
        $Dimensions = "2550x1656"
        $ModifiedSingleName = $DirectoryWithoutExtension + "_resized_" + $Dimensions
        $OldDirectory = $ModifiedSingleName + "." + $GetSingleDirectory.split('.')[1]
        Rename-Item -Path $OldDirectory -NewName ([io.path]::ChangeExtension($OldDirectory, '.png'))
        $FullDirectory = $ModifiedSingleName + ".png"
        $FinishMessage = "The image has been succesfully formatted and is at $FullDirectory"
        Write-Host $FinishMessage
    }

}

function LinkBlock-Change {
    $BatchJobOption = Read-Host "Is this a batch format(y/n)"
    
    if ($BatchJobOption -eq 'y') {
        $GetDirectory = Read-Host "What directory are the images stored at(Do not end with a \) "
        $DirectoryWildcard = $GetDirectory + "\*"
        $Files = @(Get-ChildItem -Path $DirectoryWildcard)
        

        foreach($dir in $Files) {
            Resize-Image -Width 1920 -Height 620 -ImagePath $dir
        }
        
        Start-Sleep -s 5
        $ResizedFiles = @(Get-ChildItem -Path $DirectoryWildcard)

        foreach($ResizedDir in $ResizedFiles) {
            Rename-Item -Path $ResizedDir -NewName ([io.path]::ChangeExtension($ResizedDir, '.png'))
        }

    } else {
        $GetSingleDirectory = Read-Host "Enter path of the image to be formatted"
        Resize-Image -Width 250 -Height 175 -ImagePath $GetSingleDirectory
        $DirectoryWithoutExtension = $GetSingleDirectory.split('.')[0]
        $Dimensions = "250x175"
        $ModifiedSingleName = $DirectoryWithoutExtension + "_resized_" + $Dimensions
        $OldDirectory = $ModifiedSingleName + "." + $GetSingleDirectory.split('.')[1]
        Rename-Item -Path $OldDirectory -NewName ([io.path]::ChangeExtension($OldDirectory, '.png'))
        $FullDirectory = $ModifiedSingleName + ".png"
        $FinishMessage = "The image has been succesfully formatted and is at $FullDirectory"
        Write-Host $FinishMessage
    }

}

function Profile-Change {
    $BatchJobOption = Read-Host "Is this a batch format(y/n)"
    
    if ($BatchJobOption -eq 'y') {
        $GetDirectory = Read-Host "What directory are the images stored at(Do not end with a \) "
        $DirectoryWildcard = $GetDirectory + "\*"
        $Files = @(Get-ChildItem -Path $DirectoryWildcard)
        

        foreach($dir in $Files) {
            Resize-Image -Width 1920 -Height 620 -ImagePath $dir
        }
        
        Start-Sleep -s 5
        $ResizedFiles = @(Get-ChildItem -Path $DirectoryWildcard)

        foreach($ResizedDir in $ResizedFiles) {
            Rename-Item -Path $ResizedDir -NewName ([io.path]::ChangeExtension($ResizedDir, '.png'))
        }

    } else {
        $GetSingleDirectory = Read-Host "Enter path of the image to be formatted"
        Resize-Image -Width 243 -Height 346 -ImagePath $GetSingleDirectory
        $DirectoryWithoutExtension = $GetSingleDirectory.split('.')[0]
        $Dimensions = "243x346"
        $ModifiedSingleName = $DirectoryWithoutExtension + "_resized_" + $Dimensions
        $OldDirectory = $ModifiedSingleName + "." + $GetSingleDirectory.split('.')[1]
        Rename-Item -Path $OldDirectory -NewName ([io.path]::ChangeExtension($OldDirectory, '.png'))
        $FullDirectory = $ModifiedSingleName + ".png"
        $FinishMessage = "The image has been succesfully formatted and is at $FullDirectory"
        Write-Host $FinishMessage
    }

}

function Custom-Change {
    $WidthDimension = Read-Host "Please enter the width to format this image with"
    $HeightDimension = Read-Host "Please enter the height to format this image with"
    $BatchJobOption = Read-Host "Is this a batch format(y/n)"
    
    if ($BatchJobOption -eq 'y') {
        $GetDirectory = Read-Host "What directory are the images stored at(Do not end with a \) "
        $DirectoryWildcard = $GetDirectory + "\*"
        $Files = @(Get-ChildItem -Path $DirectoryWildcard)
        

        foreach($dir in $Files) {
            Resize-Image -Width $WidthDimension -Height $HeightDimension -ImagePath $dir
        }
        
        Start-Sleep -s 5
        $ResizedFiles = @(Get-ChildItem -Path $DirectoryWildcard)

        foreach($ResizedDir in $ResizedFiles) {
            Rename-Item -Path $ResizedDir -NewName ([io.path]::ChangeExtension($ResizedDir, '.png'))
        }

    } else {
        $GetSingleDirectory = Read-Host "Enter path of the image to be formatted"
        Resize-Image -Width $WidthDimension -Height $HeightDimension -ImagePath $GetSingleDirectory
        $DirectoryWithoutExtension = $GetSingleDirectory.split('.')[0]
        $Dimensions = $WidthDimension + $HeightDimension
        $ModifiedSingleName = $DirectoryWithoutExtension + "_resized_" + $Dimensions
        $OldDirectory = $ModifiedSingleName + "." + $GetSingleDirectory.split('.')[1]
        Rename-Item -Path $OldDirectory -NewName ([io.path]::ChangeExtension($OldDirectory, '.png'))
        $FullDirectory = $ModifiedSingleName + ".png"
        $FinishMessage = "The image has been succesfully formatted and is at $FullDirectory"
        Write-Host $FinishMessage
    }

}

function File-Info {
    $ImageLocation = Read-Host "Enter path to image"
    Get-ItemProperty $ImageLocation | Format-List
}

# GUI Variable Modifiers
$ReduceFileSize = $false
function CheckState-FileSize {
    $ReduceFileSize = $true
}

$BatchJob = $false
function CheckState-BatchJob {
    $Batch = $true
}

# GUI SHOWN
[void]$ImageOptions.ShowDialog()