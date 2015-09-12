# This is a helper module for a Pester test suite to validate the Clear-RecycleBin cmdlet 
# in the Microsoft.PowerShell.Management module.
#
# Copyright (c) Microsoft Corporation, 2015
#

# Get the current directory, and create a folder to generate test files.
$currentDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path

# Returns the guid for the current system drive.
#
function GetDriveID
{
    $defaultDrive = $env:SystemDrive.Replace(":", "")
    $driveID = $null
    try
    {
        $defaultVolume = Get-Volume -DriveLetter $defaultDrive -ErrorAction Stop
        $defaultVolume = $defaultVolume.Path.Replace("\\?\Volume", "")
        $driveID = $defaultVolume.Replace("\", "") 
    }
    catch 
    {
        Write-Verbose "Failed to get system drive Id. Error: $_" -Verbose        
    }
    return $driveID   
}

# By default this function returns false.
#
function ShouldRun
{
    # If the Shell API is not available, skip the test suite.
    try 
    {
        $shell = new-object -comobject "Shell.Application"
    }
    catch
    {
        # ignore the error and return false.
        return $false
    }

    if ($shell -eq $null)
    {
        return $false
    }

    # Check the registry to see if the user has disable sending files to the recycle bin.
    $systemDriveID = GetDriveID
    if ($systemDriveID -ne $null)
    {
        $registrySettingsPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\BitBucket\Volume\'
        $allDrives = @(Get-ChildItem $registrySettingsPath)
        if ($allDrives.Count -gt 0)
        {
            foreach ($drive in $allDrives)
            {
                if ($drive.PSChildName -match $systemDriveID)
                {
                    # Save the original key value
                    $keySettingPath = $registrySettingsPath + $drive.PSChildName
                    $recybleBinKey = Get-ItemProperty -path $keySettingPath -Name NukeOnDelete
                    if ($recybleBinKey.NukeOnDelete -eq 0)
                    {
                        return $true
                    }
                }            
            }
        }
    }
    return $false        
}

function Setup
{
    # Get the current directory, and create a folder to generate test files.
    $script:testFolderPath = join-path $currentDirectory "ClearRecycleBinTests" 
    write-verbose  "Test folder path: $testFolderPath"
    if (test-path $script:testFolderPath)
    {
        Remove-Item $script:testFolderPath -Recurse -Force -ea SilentlyContinue
    }
    New-Item $script:testFolderPath -ItemType Directory -Force|out-null

    # Script level variables for recycleBin manipulations.
    $script:shell = new-object -comobject "Shell.Application"
    $script:recycleBin = $script:shell.NameSpace(0xa)
}

function CleanUp
{
    if (test-path $script:testFolderPath)
    {
        Remove-Item $script:testFolderPath -Recurse -Force -ea SilentlyContinue
    }
}

function TestCaseSetup
{
    param 
    (
        [int]$numberOfFiles = 10
    )

    # Script level variables for recycleBin manipulations.
    $script:shell = new-object -comobject "Shell.Application"
    $script:recycleBin = $script:shell.NameSpace(0xa)

    # Ensure that the recycle bin is empty. 
    $script:recycleBin.Items() | Remove-Item -Force -Recurse -ea SilentlyContinue

    # Generate $numberOfFiles and send them to the RecycleBin.
    1..$numberOfFiles | % {
        $filePath = Join-Path $script:testFolderPath ($_.ToString() + ".txt")
        Set-Content -Value $_ -Path $filePath
        $item = $script:shell.Namespace(0).ParseName("$filePath")
        $item.InvokeVerb("delete")
    }

    # Ensure that the RecycleBin is not empty.
    $results = @($script:recycleBin.Items())
    if (-not ($results.Count -gt 0))
    {
        throw "Failed to populate recycleBin with test files."
    }
}

function GetRecycleBinFileCount
{
    return @($script:recycleBin.Items()).Count
}
