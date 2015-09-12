# This is a Pester test suite to validate the Clear-RecycleBin cmdlet in the Microsoft.PowerShell.Management module.
#
# Copyright (c) Microsoft Corporation, 2015
#
# These tests are not portable as they required functions from the ClearRecycleBinHelperFunctions.psm1 module.
#

$currentDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$helperModule = Join-Path $currentDirectory "ClearRecycleBinHelperFunctions.psm1"
if (-not $helperModule)
{
    throw "Helper module $helperModule is not available."
}
Import-Module $helperModule -Force

if (-not (ShouldRun))
{
    write-verbose "Shell.Application namespace is not available, skipping tests..."  
    return   
}

# The number of test files to create and send to the recycle bin.
$numberOfTestFiles = 10

# Setup
Setup

<#
    Purpose:
        Verify that Clear-RecycleBin with no parameters clears the recycle bin.
                
    Action:
        Run Clear-RecycleBin with no parameters.
               
    Expected Result: 
        All contents of the recycle bin are deleted. 
#>

Describe "ClearRecycleBinWithNoParameters" {

    It "Clear-RecycleBin -Force" {
        TestCaseSetup -numberOfFiles $numberOfTestFiles
        $result = @{
                InitialFileCount = GetRecycleBinFileCount
                FinalFileCount = $null
        }        
        Clear-RecycleBin -Force
        $result.FinalFileCount = GetRecycleBinFileCount

        $result.InitialFileCount - $numberOfTestFiles | should be 0
        $result.FinalFileCount | should be 0
    }
}


<#
    Purpose:
        Verify that Clear-RecycleBin -DriveLetter parameter supports the following formats: C, C: and C:\.
                
    Action:
        Run Clear-RecycleBin -DriveLetter using various supported formats.
               
    Expected Result: 
        All contents of the recycle bin for the default drive are deleted. 
#>

$supportedFormats = @()
$supportedFormats += $env:SystemDrive.Replace(":","")
$supportedFormats += $env:SystemDrive
$supportedFormats += ($env:SystemDrive + "\")        
Describe "ClearRecycleBinSupportedDriveLetterFormats" {
    
    foreach ($inputParam in $supportedFormats)
    {
        It "Clear-RecycleBin -DriveLetter $inputParam -Force" {
            TestCaseSetup -numberOfFiles $numberOfTestFiles
            $result = @{
                InitialFileCount = GetRecycleBinFileCount
                FinalFileCount = $null
            }
            Clear-RecycleBin -Force -DriveLetter $inputParam
            $result.FinalFileCount = GetRecycleBinFileCount

            $result.InitialFileCount - $numberOfTestFiles | should be 0
            $result.FinalFileCount | should be 0
        }
    }
}


<#
    Purpose:
        Verify that Clear-RecycleBin -DriveLetter throws the correct exception for $null and empty.
                
    Action:
        Run Clear-RecycleBin -DriveLetter using $null and empty.
               
    Expected Result: 
        The correct exception is thrown and the FullyQualifiedErrorId is ParameterArgumentValidationError,Microsoft.PowerShell.Commands.ClearRecycleBinCommand. 
#> 

$invalidInputs = @($null, "")   
Describe "ClearRecycleBinHandlesNullAndEmptyInputs" {
    
    foreach ($inputParam in $invalidInputs)
    {
        It "Clear-RecycleBin -DriveLetter null or empty" {
            try
            {
                Clear-RecycleBin -Force -DriveLetter $inputParam -ErrorAction Stop
                throw "CodeExecuted"
            }
            catch
            {
                $_.FullyQualifiedErrorId | should be "ParameterArgumentValidationError,Microsoft.PowerShell.Commands.ClearRecycleBinCommand"                    
            }           
        }
    }
}


<#
    Purpose:
        Verify that Clear-RecycleBin -DriveLetter throws the correct exception for a drive that does not exist.
                
    Action:
        Run Clear-RecycleBin -DriveLetter using an unknown drive.
               
    Expected Result: 
        The correct exception is thrown and the FullyQualifiedErrorId is DriveNotFound,Microsoft.PowerShell.Commands.ClearRecycleBinCommand. 
#> 

# Get a drive letter between F and Y that is not being used for the drive name.
$driveLetter = [char[]](70..89) | Where-Object {$_ -notin (Get-PSDrive).Name} | Select-Object -Last 1

Describe "ClearRecycleBinThrowsDriveNotFoundForDrivesThatDoNotExist" {
    It "Clear-RecycleBin -Force -DriveLetter $driveLetter -ErrorAction Stop" {
        try
        {
            Clear-RecycleBin -Force -DriveLetter $driveLetter -ErrorAction Stop
            throw "CodeExecuted"
        }
        catch
        {
            $_.FullyQualifiedErrorId | should be "DriveNotFound,Microsoft.PowerShell.Commands.ClearRecycleBinCommand"                    
        }
    }
}


<#
    Purpose:
        Verify that Clear-RecycleBin -DriveLetter throws the correct exception for a drive name in the incorrect format.
                
    Action:
        Run Clear-RecycleBin -DriveLetter c:\\\.
               
    Expected Result: 
        The correct exception is thrown and the FullyQualifiedErrorId is InvalidDriveNameFormat,Microsoft.PowerShell.Commands.ClearRecycleBinCommand. 
#>  

$driveName = ($env:SystemDrive + "\\\")  
Describe "ClearRecycleBinThrowsInvalidDriveNameFormatForInvalidDriveNames" {    
    It "Clear-RecycleBin -Force -DriveLetter $driveName" {                
        try
        {
            Clear-RecycleBin -Force -DriveLetter $driveName -ErrorAction Stop
            throw "CodeExecuted"
        }
        catch
        {
            $_.FullyQualifiedErrorId | should be "InvalidDriveNameFormat,Microsoft.PowerShell.Commands.ClearRecycleBinCommand"                    
        }
    }
}

<#
    Purpose:
        Verify that Clear-RecycleBin works using piping.
                
    Action:
        Run Get-Volume for the default drive, and pipe the output to Clear-RecycleBin.
               
    Expected Result: 
         All contents of the recycle bin for the default drive are deleted.  
#> 
$driveName = $env:SystemDrive.Replace(":","")
Describe "ClearRecycleBinSupportsPiping" {
    
    It "Get-Volume -DriveLetter $driveName | Clear-RecycleBin -Force" {
    TestCaseSetup -numberOfFiles $numberOfTestFiles
        $result = @{
            InitialFileCount = GetRecycleBinFileCount
            FinalFileCount = $null
        }
        Get-Volume -DriveLetter $driveName | Clear-RecycleBin -Force
        $result.FinalFileCount = GetRecycleBinFileCount

        $result.InitialFileCount -  $numberOfTestFiles | should be 0
        $result.FinalFileCount | should be 0
    }
}

# Clean up
CleanUp

