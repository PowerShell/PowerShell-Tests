# This is a helper module for a Pester test suite to validate the Clipboard cmdlet 
# in the Microsoft.PowerShell.Management module.
#
# Copyright (c) Microsoft Corporation, 2015
#

function ShouldRun
{
    # If the presentationCore is not available, skip the test suite.
    try 
    {
        Add-Type -Assembly PresentationCore
    }
    catch
    {
        # ignore the error and return false.
        return $false
    }

    return $true    
}

function Setup
{
    param 
    (
        [int]$numberOfFiles = 10
    )

    # Get the temp directory, and create a folder to generate test files.
    $script:testFolderPath = join-path $env:TEMP "ClipboardTests"
    write-verbose  "Test folder path: $testFolderPath"
    if (test-path $script:testFolderPath)
    {
        Remove-Item $script:testFolderPath -Recurse -Force -ea SilentlyContinue
    }
    New-Item $script:testFolderPath -ItemType Directory -Force | out-null

    # Generate $numberOfFiles.
    1..$numberOfFiles | % {
        $filePath = Join-Path $script:testFolderPath ($_.ToString() + ".txt")
        Set-Content -Value $_ -Path $filePath}

}

function CleanUp
{
    if (test-path $script:testFolderPath)
    {
        Remove-Item $script:testFolderPath -Recurse -Force -ea SilentlyContinue
    }
}
