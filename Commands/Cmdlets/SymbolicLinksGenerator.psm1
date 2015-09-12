ParameterGenerator -name SymbolicLinkParameterValidationGenerator -definition {

    $returnObject = @() 

    $targetValues = @("", $null, "$global:targetfile", "C:\NonExistentFile.txt", "HKLM:\Software")
    $pathValues = @("", $null, $(Join-Path $global:testDestinationRoot "ValidDestination.txt"), "Env:\APPDATA")
    $itemTypes = @("SymbolicLink", "Junction", "HardLink")

    foreach($target in $targetValues)
    {
        foreach($path in $pathValues)
        {
            foreach($type in $itemTypes)
            {
                if($path -eq $null)
                {
                    $returnObject += New-Object PSObject -Property @{ Path = $path ; 
                                                                      Target = $target;
                                                                      ItemType = $type;
                                                                      ExpectedError = "ParameterArgumentValidationErrorNullNotAllowed,Microsoft.PowerShell.Commands.NewItemCommand" }
                }
                elseif(($path -eq ""))
                {
                    $returnObject += New-Object PSObject -Property @{ Path = $path ; 
                                                                      Target = $target;
                                                                      ItemType = $type;
                                                                      ExpectedError = "ParameterArgumentValidationErrorEmptyStringNotAllowed,Microsoft.PowerShell.Commands.NewItemCommand" }
                }
                elseif($target -eq $null)
                {
                    $returnObject += New-Object PSObject -Property @{ Path = $path ; 
                                                                      Target = $target;
                                                                      ItemType = $type;
                                                                      ExpectedError = "ArgumentNull,Microsoft.PowerShell.Commands.NewItemCommand" }
                }
                elseif(($target -eq ""))
                {
                    $returnObject += New-Object PSObject -Property @{ Path = $path ; 
                                                                      Target = $target;
                                                                      ItemType = $type;
                                                                      ExpectedError = "ArgumentNull,Microsoft.PowerShell.Commands.NewItemCommand" }
                }
                elseif(($path -eq "C:\NonExistentFile.txt") -and ($Target -eq $(Join-Path $global:testDestinationRoot "ValidDestination.txt")))
                {
                    $returnObject += New-Object PSObject -Property @{ Path = $path ; 
                                                                      Target = $target; 
                                                                      ItemType = $type;
                                                                      ExpectedError = "System.IO.FileNotFoundException,Microsoft.PowerShell.Commands.NewItemCommand" }
                }
                elseif($target -eq "HKLM:\Software")
                {
                    $returnObject += New-Object PSObject -Property @{ Path = $path ; 
                                                                      Target = $target; 
                                                                      ItemType = $type;
                                                                      ExpectedError = "NotSupported,Microsoft.PowerShell.Commands.NewItemCommand" }
                }
            }
        }
    }

    $returnObject
}

ParameterGenerator -name SymbolicLinkValidParametersGenerator -definition {
    
    $returnObject = @()
    
    $destinationDirectory = join-path $global:testDestinationRoot "SymbolicDirectory"
    $destinationFile = join-path $global:testDestinationRoot "SymbolicFile.txt"
        
    $otherDrive = Get-OtherFileSystemDrive -path $global:targetfile
    $otherDriveDestination = Join-path $otherDrive "symbolicLink.txt"
    $returnObject += New-Object PSObject -Property @{ Target = $global:targetfile ; Path = $otherDriveDestination }


    $shareRoot = Get-ShareRoot
    $shareDestination = Join-Path $shareRoot "shareSymbolicLink.txt"
    $shareSource = Join-Path $shareRoot "targetfile.txt"
    $returnObject += New-Object PSObject -Property @{ Target = $global:targetfile ; Path = $shareDestination }
    $returnObject += New-Object PSObject -Property @{ Target = $shareSource ; Path = $shareDestination }
    $returnObject += New-Object PSObject -Property @{ Target = $shareSource ; Path = $destinationFile }
    
    ##On non English machine this will contain non-english characters.
    #$nonEnglishDestination = Join-Path $env:APPDATA "TODO"
    #$returnObject += New-Object PSObject -Property @{ Path = $shareSource ; LinkDestination = $nonEnglishDestination }

    $returnObject
}

function Get-OtherFileSystemDrive($path)
{
    $currentDrive = [system.io.path]::GetPathRoot($path)
    $drives = Get-PSDrive -PSProvider FileSystem 

    $selectedOtherDrive = $null

    $drives | %{ if( ($_.Root -ne $currentDrive) -and ($_.Used -gt 0)) { $selectedOtherDrive = $_.Root ; return $selectedOtherDrive} }
}

function Get-ShareRoot
{
    $exists = Get-SmbShare -Name "LoopBackShare" -ErrorAction SilentlyContinue

    if(-not $exists)
    {
        "\\$env:COMPUTERNAME" + "\" + (New-SmbShare -Path $global:testDestinationRoot -Name "LoopBackShare" -FullAccess "$env:USERDNSDOMAIN\$env:USERNAME").Name
    }
    else
    {
        "\\$env:COMPUTERNAME\LoopBackShare"
    }
}
