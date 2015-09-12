# This is a Pester test suite to validate the Clipboard cmdlets in the Microsoft.PowerShell.Management module.
#
# Copyright (c) Microsoft Corporation, 2015
#
# These tests are not portable as they required functions from the ClipboardHelperFunctions.psm1 module.
#

$currentDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$helperModule = Join-Path $currentDirectory "ClipboardHelperFunctions.psm1"
$script:testFolderPath = join-path $env:TEMP "ClipboardTests"
$script:rdpProcessOn = $false;

if (-not $helperModule)
{
    throw "Helper module $helperModule is not available."
}
Import-Module $helperModule -Force

if (-not (ShouldRun))
{
    write-verbose "System.Windows.Clipborad namespace is not available, skipping tests..."  
    return   
}

# The number of test files to create for file copy.
$numberOfTestFiles = 10

# Setup
Setup -numberOfFiles $numberOfTestFiles

# If the test is running on the lab machine logged in from host,
# the rdpclip.exe will share the clipboard content between host and lab machine. It needs to be temporary disabled.

if ((Get-Process rdpclip -ErrorAction SilentlyContinue).count -ne 0)
    {
        Get-Process rdpclip | Stop-Process -force
        $rdpProcessOn = $true
    }

<#
    Purpose:
        Verify that Get/Set-Clipboard works with text format.
                
    Action:
        Run set/Get Clipboard cmdltes with text input
               
    Expected Result: 
        The Get-Clipboard should return what Set-Clipboard sets. 
#>

Describe "ClipboardWorksWithTextFormats" {

    It "Get text content from clipboard" {
        $text = "Content is set to Clipboard."
        Set-Clipboard -Value $text
        Get-Clipboard | should be $text
    }

    It "Set Clipboard With Append swtich" {
        $text1 = "text1 set to Clipboard."
        $text2 = "text2 set to Clipboard."
        Set-Clipboard -Value $text1
        Set-Clipboard -Value $text2 -Append
        $result = New-Object -TypeName "System.Text.StringBuilder"
        $result.AppendLine($text1)
        $result.Append($text2)
        Get-Clipboard -Raw | should be $result.ToString()
    }

    It "Set Clipboard works with pipe line as Text." {
        $filePath = Join-Path $script:testFolderPath "1.txt"
        $content = Get-Content $filePath
        Get-Content $filePath | Set-Clipboard
        Get-Clipboard -Raw | should be $content
    }

    It "Set Clipboard works with multiple pipe line." {
        $content = "string1", "string2"
        $content | Set-Clipboard
        $result = Get-Clipboard
        $result.Count | should be 2
        $result[0] | should be "string1"
        $result[1] | should be "string2"
    }
}


<#
    Purpose:
        Verify that Get/Set-Clipboard works with file format.
                
    Action:
        Run set/Get Clipboard cmdltes with file format
               
    Expected Result: 
        The Get-Clipboard should return what Set-Clipboard sets. 
#>

Describe "ClipboardWorksWithFileFormats" {

    It "Get text content from clipboard contains file format" {
        $filePath = Join-Path $script:testFolderPath "1.txt"
        Set-Clipboard -Path $filePath
        [Windows.Clipboard]::ContainsFileDropList() | should be $true
        (Get-Clipboard -Format FileDropList).fullname | should be $filePath
    }

    It "Set file format to Clipboard With Append swtich" {
        $filePath1 = Join-Path $script:testFolderPath "1.txt"
        $filePath2 = Join-Path $script:testFolderPath "2.txt"
        Set-Clipboard -Path $filePath1
        Set-Clipboard -Path $filePath2 -Append
        [Windows.Clipboard]::ContainsFileDropList() | should be $true
        $result = Get-Clipboard -Format FileDropList -Raw
        $result.Contains($filePath1) | should be $true
        $result.Contains($filePath2) | should be $true
    }

    It "Set Clipboard works with file format" {
        $filePath = Join-Path $script:testFolderPath "1.txt"
        Set-Clipboard -Value "Test Value"
        [Windows.Clipboard]::ContainsText() | should be $true
        Set-Clipboard -Path $filePath 
        [Windows.Clipboard]::ContainsFileDropList() | should be $true
    }

    It "Set Clipboard works with wild card file name" {
        $filePath = Join-Path $script:testFolderPath "*"
        Set-Clipboard -Path $filePath
        [Windows.Clipboard]::ContainsFileDropList() | should be $true
        $result = [Windows.Clipboard]::GetFileDropList()
        $result.Count | should be $numberOfTestFiles
    }

    It "Set Clipboard works pipeLine as file format" {
        Get-ChildItem $script:testFolderPath | Set-Clipboard
        [Windows.Clipboard]::ContainsFileDropList() | should be $true
        $result = [Windows.Clipboard]::GetFileDropList()
        $result.Count | should be $numberOfTestFiles
    }

    It "Set Clipboard won't add duplicated file names" {
        Get-ChildItem $script:testFolderPath | Set-Clipboard
        [Windows.Clipboard]::ContainsFileDropList() | should be $true
        $result = [Windows.Clipboard]::GetFileDropList()
        $result.Count | should be $numberOfTestFiles
        Get-ChildItem $script:testFolderPath | Set-Clipboard -Append
        $result = [Windows.Clipboard]::GetFileDropList()
        $result.Count | should be $numberOfTestFiles
    }

    It "Set Clipboard won't add non-existed file names" {
        $filePath = Join-Path $script:testFolderPath "invalidFile"
        $fullyQualifiedErrorId = "FailedToSetClipboard,Microsoft.PowerShell.Commands.SetClipboardCommand"       
        $Error.Clear()
        try
        {
            Set-Clipboard -Path $filePath -ErrorAction Stop
            throw "Set-Clipboard doesn't throw expected exception"
        }
        catch
        {
             $_.FullyQualifiedErrorId | should be $fullyQualifiedErrorId

        }
    }

    It "Set Clipboard works with literal path file format" {
        $filePath = Join-Path $script:testFolderPath "[1].txt"
        Set-Content -Value "[1].txt" -Path $filePath
        Set-Clipboard -LiteralPath $filePath
        [Windows.Clipboard]::ContainsFileDropList() | should be $true
        $result = Get-Clipboard -Format FileDropList -Raw
        $result.Contains($filePath) | should be $true
    }
}


# Clean up
CleanUp

if ($rdpProcessOn)
{
   Start-Process rdpclip -ErrorAction Ignore
}

