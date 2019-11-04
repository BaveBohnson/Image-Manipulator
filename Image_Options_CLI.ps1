<#


#>

#$WorkingScript = $PSScriptRoot + "\ImgConvert.ps1"
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

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
        $GetDirectory = $GetDirectory -replace '["]', ''
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
        $GetSingleDirectory = $GetSingleDirectory -replace '["]', ''
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
        $GetDirectory = $GetDirectory -replace '["]', ''
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
        $GetSingleDirectory = $GetSingleDirectory -replace '["]', ''
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
        $GetDirectory = $GetDirectory -replace '["]', ''
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
        $GetSingleDirectory = $GetSingleDirectory -replace '["]', ''
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
        $GetDirectory = $GetDirectory -replace '["]', ''
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
        $GetSingleDirectory = $GetSingleDirectory -replace '["]', ''
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
        $GetDirectory = $GetDirectory -replace '["]', ''
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
        $GetSingleDirectory = $GetSingleDirectory -replace '["]', ''
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
    $ImageLocation = $ImageLocation -replace '["]', ''
    Get-ItemProperty $ImageLocation | Format-List
}

function Show-Menu
{
     param (
           [string]$Title = 'Image Options'
     )
     cls
     Write-Host "================ $Title ================"
    
     Write-Host "1: Press '1' for Banner Image Fomatting."
     Write-Host "2: Press '2' for Standard Image Format."
     Write-Host "3: Press '3' for Link Block Format."
     Write-Host "4: Press '4' for Profile Format."
     Write-Host "5: Press '5' for Custom Format."
     Write-Host "6: Press '6' for File Stats."
     Write-Host "Q: Press 'Q' to quit."
}

do
{
     Show-Menu
     $input = Read-Host "Please make a selection"
     switch ($input)
     {
           '1' {
                cls
                Banner-Change
           } '2' {
                cls
                Normal-Change
           } '3' {
                cls
                LinkBlock-Change
           } '4' {
                cls
                Profile-Change
           } '5' {
                cls
                Custom-Change
           } '6' {
                cls
                File-Info
           } 'q' {
                return
           }
     }
     pause
}
until ($input -eq 'q')