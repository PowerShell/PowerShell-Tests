# This is a Pester test suite to validate Copy-Item remotely using a remote session.
#
# Copyright (c) Microsoft Corporation, 2015
#
#

# If PS Remoting is not available, do not run the suite.
$script:ShouldRunResult = $null
Function ShouldRun
{
    if ( $script:ShouldRunResult -eq $null )
    {
        $result = Invoke-Command -ComputerName . -ScriptBlock {1} -ErrorAction SilentlyContinue
        if ( $result -eq 1 )
        {
            $script:ShouldRunResult = $true
        }
        else
        {
            $script:ShouldRunResult = $false
        }
    }
    $PSDefaultParameterValues["It:Skip"] = ! $ShouldRunResult
    return $script:ShouldRunResult
}

Describe "Validate Copy-Item Remotely" -Tags "Innerloop" {
    BeforeAll {
        if ( ! (ShouldRun) ) { return }
        $s = New-PSSession -ComputerName . -ea SilentlyContinue
        if (-not $s)
        {
            throw "Failed to create PSSession for remote copy operations."
        }

        $destinationFolderName = "DestinationDirectory"
        $sourceFolderName = "SourceDirectory"
        $testDirectory = Join-Path "TestDrive:" "copyItemRemotely"
        $destinationDirectory = Join-Path $testDirectory $destinationFolderName
        $sourceDirectory = Join-Path $testDirectory $sourceFolderName

        # Creates one txt file
        #
        function CreateTestFile
        {
            param ([switch]$setReadOnlyAttribute = $false, [switch]$emptyFile = $false)

            # Create the test directory.
            New-Item -Path $sourceDirectory -Force -ItemType Directory | Out-Null

            # Create the file.
            $filePath = Join-Path $sourceDirectory "testfileone.txt"
            if (-not $emptyFile)
            {
                "File test content" | Out-File $filePath -Force
            }
            else
            {
                "" | Out-File $filePath -Force
            }

            if (-not (Test-Path $filePath))
            {
                throw "Failed to create test file $filePath."
            }

            if ($setReadOnlyAttribute)
            {
                Set-ItemProperty $filePath -Name IsReadOnly -value $true -Force
            }

            return (Get-Item $filePath).FullName
        }

        # Create a set of directories and files with the following structure:
        # .\copyItemRemotely\SourceDirectory\A\a.txt
        # .\copyItemRemotely\SourceDirectory\A\a2.txt
        # .\copyItemRemotely\SourceDirectory\rootFile.txt
        # .\copyItemRemotely\SourceDirectory\B\b.txt
        # .\copyItemRemotely\SourceDirectory\C\D\d.txt
        #
        function CreateTestDirectory
        {
            param ([switch]$setReadOnlyAttribute = $false)

            $directoriesToCreate = @()
            $directoriesToCreate += "A"
            $directoriesToCreate += "B"
            $directoriesToCreate += "C\D"

            $filesToCreate = @()
            $filesToCreate += "rootFile.txt"
            $filesToCreate += "A\a.txt"
            $filesToCreate += "A\a2.txt"
            $filesToCreate += "B\b.txt"
            $filesToCreate += "C\D\d.txt"

            # Create the directories.
            foreach ($directory in $directoriesToCreate)
            {
                $directoryPath = Join-Path $sourceDirectory $directory
                New-Item -Path $directoryPath -Force -ItemType Directory | Out-Null
            }

            $result = @{
                SourceDirectory = (Get-Item $sourceDirectory).FullName
                Files = @()
            }

            # Create the files.
            foreach ($file in $filesToCreate)
            {
                $filePath = Join-Path $sourceDirectory $file
                $file + "`r`n File test content" | Out-File $filePath -Force

                if (-not (Test-Path $filePath))
                {
                    throw "Failed to create test file $filePath."
                }

                if ($setReadOnlyAttribute)
                {
                    Set-ItemProperty $filePath -Name IsReadOnly -value $true -Force
                }

                $result.Files += (Get-Item $filePath).FullName
            }

            return $result
        }
        
        function GenerateTestAssembly
        {
            $assemblyPath = Join-Path $env:TEMP TestModule
            $outputPath = Join-Path $assemblyPath TestModule.dll
            
            if (-not (Test-Path $assemblyPath))
            {
                New-Item $assemblyPath -Force -ItemType Directory | Out-Null
            }            

            if (-not (Test-Path $outputPath))
            {
                $code = @"
                namespace TestModule
                {
                    using System;
                    using System.Management.Automation;
  
                    [Cmdlet(VerbsCommon.Get, "TestModule")]
                    public class TestSameCmdlets : PSCmdlet
                    {
                        protected override void ProcessRecord()
                        {
                            WriteObject("TestModule");
                        }
                    }
                }
"@
                Add-Type -TypeDefinition $code -OutputAssembly $outputPath
            }

            $result = @{
                ModuleName = "TestModule"
                Path = (Get-Item $outputPath).FullName
            }

            return $result
        }

        function GetDestinationFolderPath
        {
            return (Get-Item $destinationDirectory).FullName
        }
    }

    AfterAll {
        if ( ! (ShouldRun) ) { return }
        Remove-PSSession -Name $s.Name -ea SilentlyContinue
    }

    BeforeEach {
        if ( ! (ShouldRun) ) { return }
        <# Ensure we start with an empty test directory. Here is the file structure 

        #$destinationFolderName = "DestinationDirectory"
        #$sourceFolderName = "SourceDirectory"
        #$testDirectory = Join-Path "TestDrive:" "copyItemRemotely"
        ##$destinationDirectory = Join-Path $testDirectory $destinationFolderName
        #$sourceDirectory = Join-Path $testDirectory $sourceFolderName
        #>

        if (test-path $testDirectory)
        {
            Remove-Item $testDirectory -Force -ea SilentlyContinue -Recurse
        }

        # Create testDirectory, and destinationDirectory
        New-Item $testDirectory -ItemType Directory -Force | Out-Null
        New-Item $destinationDirectory -ItemType Directory -Force | Out-Null
    }

    Context "Validate Copy-Item Locally." {
        It "Copy-Item -Path $filePath -Destination $destinationFolderPath" {
       
            $filePath = CreateTestFile
            $destinationFolderPath = GetDestinationFolderPath
            Copy-Item -Path $filePath -Destination $destinationFolderPath
            $copiedFilePath = ([string]$filePath).Replace("SourceDirectory", "DestinationDirectory")
            $copiedFilePath | should Exist
        }

        It "Copy-Item -Path $($testObject.SourceDirectory)  -Destination $destinationFolderPath -Recurse" {

            $testObject = CreateTestDirectory
            $destinationFolderPath = GetDestinationFolderPath
            Copy-Item -Path $testObject.SourceDirectory -Destination $destinationFolderPath -Recurse
            foreach ($file in $testObject.Files)
            {
                $copiedFilePath = ([string]$file).Replace("SourceDirectory", "DestinationDirectory\SourceDirectory")
                $copiedFilePath | should Exist
            }
        }
    }

    Context "Validate Copy-Item to remote session." {

        It "Copy one file to remote session." {
            $filePath = CreateTestFile
            $destinationFolderPath = GetDestinationFolderPath   
            Copy-Item -Path $filePath -ToSession $s -Destination $destinationFolderPath
            $copiedFilePath = ([string]$filePath).Replace("SourceDirectory", "DestinationDirectory")
            $copiedFilePath | should Exist 
            (Get-Item $copiedFilePath).Length | should be (Get-Item $filePath).Length
        
        }

        It "Copy one read only file to remote session." {

            $filePath = CreateTestFile -setReadOnlyAttribute
            $destinationFolderPath = GetDestinationFolderPath
            Copy-Item -Path $filePath -ToSession $s -Destination $destinationFolderPath -Force
            $copiedFilePath = ([string]$filePath).Replace("SourceDirectory", "DestinationDirectory")
            $copiedFilePath | should Exist
            (Get-Item $copiedFilePath).Length | should be (Get-Item $filePath).Length
        }

        It "Copy-Item throws CopyFileInfoItemUnauthorizedAccessError for a read only files when '-Force' is not used." {

            $filePath = CreateTestFile -setReadOnlyAttribute
            $destinationFolderPath = GetDestinationFolderPath
            try
            {
                Copy-Item -Path $filePath -ToSession $s -Destination $destinationFolderPath -ErrorAction Stop
                throw "CodeExecuted"
            }
            catch
            {
                $_.FullyQualifiedErrorId | should be "CopyFileInfoItemUnauthorizedAccessError,Microsoft.PowerShell.Commands.CopyItemCommand"
            }
        }

        It "Copy one folder to session Recursively" {

            $testObject = CreateTestDirectory
            $destinationFolderPath = GetDestinationFolderPath
            Copy-Item -Path $testObject.SourceDirectory -ToSession $s -Destination $destinationFolderPath -Recurse

            foreach ($file in $testObject.Files)
            {
                $copiedFilePath = ([string]$file).Replace("SourceDirectory", "DestinationDirectory\SourceDirectory")
                $copiedFilePath | should Exist 
                (Get-Item $copiedFilePath).Length | should be (Get-Item $file).Length
            }
        }

        It "Copy read only file to remote session recursively." {
            $testObject = CreateTestDirectory -setReadOnlyAttribute
            $destinationFolderPath = GetDestinationFolderPath
            Copy-Item -Path $testObject.SourceDirectory -ToSession $s -Destination $destinationFolderPath -Recurse -Force

            foreach ($file in $testObject.Files)
            {
                $copiedFilePath = ([string]$file).Replace("SourceDirectory", "DestinationDirectory\SourceDirectory")
                $copiedFilePath | should Exist
                (Get-Item $copiedFilePath).Length | should be (Get-Item $file).Length
            }
        }

        It "Copy one empty file to remote session." {

            $filePath = CreateTestFile -emptyFile
            $destinationFolderPath = GetDestinationFolderPath
            $copiedFilePath = ([string]$filePath).Replace("SourceDirectory", "DestinationDirectory")
            $copiedFilePath | should Not Exist
            Copy-Item -Path $filePath  -ToSession $s -Destination $destinationFolderPath
            $copiedFilePath | should Exist
            (Get-Item $copiedFilePath).Length | should be (Get-Item $filePath).Length
        }
    }

    Context "Validate Copy-Item from remote session." {

        It "Copy one file from remote session." {

            $filePath = CreateTestFile
            $destinationFolderPath = GetDestinationFolderPath
            $copiedFilePath = ([string]$filePath).Replace("SourceDirectory", "DestinationDirectory")
            $copiedFilePath | should Not Exist
            Copy-Item -Path $filePath  -FromSession $s -Destination $destinationFolderPath
            $copiedFilePath | should Exist
            (Get-Item $copiedFilePath).Length | should be (Get-Item $filePath).Length
        }

        It "Copy one empty file from remote session." {

            $filePath = CreateTestFile -emptyFile
            $destinationFolderPath = GetDestinationFolderPath
            $copiedFilePath = ([string]$filePath).Replace("SourceDirectory", "DestinationDirectory") 
            $copiedFilePath | should Not Exist     
            Copy-Item -Path $filePath  -FromSession $s -Destination $destinationFolderPath
            $copiedFilePath | should Exist
            (Get-Item $copiedFilePath).Length | should be (Get-Item $filePath).Length
        }

        It "Copy folder from remote session recursively." {

            $testObject = CreateTestDirectory
            $destinationFolderPath = GetDestinationFolderPath
            $files = @(Get-ChildItem $destinationFolderPath -Recurse -Force)
            Copy-Item -Path $testObject.SourceDirectory -FromSession $s -Destination $destinationFolderPath -Recurse

            foreach ($file in $testObject.Files)
            {
                $copiedFilePath = ([string]$file).Replace("SourceDirectory", "DestinationDirectory\SourceDirectory")
                $copiedFilePath | should Exist 
                (Get-Item $copiedFilePath).Length | should be (Get-Item $file).Length
            }
        }

        It "Copy a read only file from a remote session." {

            $filePath = CreateTestFile -setReadOnlyAttribute
            $destinationFolderPath = GetDestinationFolderPath
            $copiedFilePath = ([string]$filePath).Replace("SourceDirectory", "DestinationDirectory")
            Copy-Item -Path $filePath  -FromSession $s -Destination $destinationFolderPath -Force
            $copiedFilePath | should Exist
            (Get-Item $copiedFilePath).Length | should be (Get-Item $filePath).Length
        }

        It "Copy-Item for a read only file with no -force parameter throws System.UnauthorizedAccessException" {

            $filePath = CreateTestFile -setReadOnlyAttribute
            $destinationFolderPath = GetDestinationFolderPath
            try
            {
                Copy-Item -Path $filePath -FromSession $s -Destination $destinationFolderPath -ErrorAction Stop
                throw "CodeExecuted"
            }
            catch
            {
                $_.FullyQualifiedErrorId | should be "System.UnauthorizedAccessException,WriteException"
            }
        }

        It "Copy-Item -FromSession throws System.IO.IOException,WriteException when trying to copy an assembly that is currently being used by another process." {

            $testAssembly = GenerateTestAssembly
            $destinationFolderPath = GetDestinationFolderPath
            Import-Module $testAssembly.Path -Force
            try
            {
                try
                {
                    Copy-Item -Path $testAssembly.Path -FromSession $s -Destination $destinationFolderPath -ErrorAction Stop
                    throw "CodeExecuted"
                }
                catch
                {
                    $_.FullyQualifiedErrorId | should be "System.IO.IOException,WriteException"
                }
            }
            finally
            {
                Remove-Module $testAssembly.ModuleName -Force -ea SilentlyContinue
            }         
        }
    }

    Context "Validate Copy-Item Remotely using wildcards" {

        It "Copy-Item from session using wildcards." {

            $testObject = CreateTestDirectory
            $destinationFolderPath = GetDestinationFolderPath
            $sourcePathWithWildcards = "$($testObject.SourceDirectory)\A\*.txt"
            Copy-Item -Path $sourcePathWithWildcards -FromSession $s -Destination $destinationFolderPath -Force

            $sourceFiles = @(Get-Item $sourcePathWithWildcards)
            foreach ($file in $sourceFiles)
            {
                $copiedFilePath = Join-Path $destinationFolderPath (Split-Path $file -Leaf)
                $copiedFilePath | Should Exist
                (Get-Item $copiedFilePath).Length | Should Be (Get-Item $file).Length
            }
        }

        It "Copy-Item to session using wildcards." {

            $testObject = CreateTestDirectory
            $destinationFolderPath = GetDestinationFolderPath
            $sourcePathWithWildcards = "$($testObject.SourceDirectory)\A\*.txt"
            Copy-Item -Path $sourcePathWithWildcards -ToSession $s -Destination $destinationFolderPath -Force

            $sourceFiles = @(Get-Item $sourcePathWithWildcards)
            foreach ($file in $sourceFiles)
            {
                $copiedFilePath = Join-Path $destinationFolderPath (Split-Path $file -Leaf)
                $copiedFilePath | Should Exist
                (Get-Item $copiedFilePath).Length | Should Be (Get-Item $file).Length
            }
        }
    }

    Context "Validate FullyQualifiedErrorIds for remote source and destination paths." {
    
        BeforeAll {
            if ( ! (ShouldRun) ) { return }
            
            # Create test file.
            $testFilePath = Join-Path "TestDrive:" "testfile.txt"
            if (test-path $testFilePath)
            {
                Remove-Item $testFilePath -Force -ea SilentlyContinue
            }
            "File test content" | Out-File $testFilePath -Force
        }

        function Test-CopyItemError
        {
            param ($path, $destination, $expectedFullyQualifiedErrorId, $fromSession = $false)

            if ($fromSession)
            {
                It "Copy-Item FromSession -Path '$path' throws $expectedFullyQualifiedErrorId" {
                    try
                    {
                        Copy-Item -Path $path -FromSession $s -Destination $destination -ErrorAction Stop
                        throw "CodeExecuted"
                    }
                    catch
                    {
                        $_.FullyQualifiedErrorId | should be $expectedFullyQualifiedErrorId
                    }
                }
            }
            else
            {
                It "Copy-Item ToSession -Destination '$path' throws $expectedFullyQualifiedErrorId" {
                    try
                    {
                        Copy-Item -Path $path -ToSession $s -Destination $destination -ErrorAction Stop
                        throw "CodeExecuted"
                    }
                    catch
                    {
                        $_.FullyQualifiedErrorId | should be $expectedFullyQualifiedErrorId
                    }
                }
            }
        }

        $invalidSourcePathtestCases = @(
            @{
                Path = "HKLM:\SOFTWARE"
                Destination = $env:SystemDrive
                ExpectedFullyQualifiedErrorId = "NamedParameterNotFound,Microsoft.PowerShell.Commands.CopyItemCommand"
                FromSession = $true
            }
            @{
                Path = ".\Source"
                Destination = $env:SystemDrive 
                ExpectedFullyQualifiedErrorId = "RemotePathIsNotAbsolute,Microsoft.PowerShell.Commands.CopyItemCommand"
                FromSession = $true
            }
            @{
                Path = "c:\FolderThatDoesNotExist\Foo\Bar"
                Destination = $env:SystemDrive
                ExpectedFullyQualifiedErrorId = "RemotePathNotFound,Microsoft.PowerShell.Commands.CopyItemCommand"
                FromSession = $true
            }
            @{
                Path = $null
                Destination = $env:SystemDrive
                ExpectedFullyQualifiedErrorId = "ParameterArgumentValidationErrorNullNotAllowed,Microsoft.PowerShell.Commands.CopyItemCommand"
                FromSession = $true
            }
            @{
                Path = ''
                Destination = $env:SystemDrive
                ExpectedFullyQualifiedErrorId = "ParameterArgumentValidationErrorEmptyStringNotAllowed,Microsoft.PowerShell.Commands.CopyItemCommand"
                FromSession = $true
            }
        )

        foreach ($testCase in $invalidSourcePathtestCases) {
           Test-CopyItemError @testCase
        }

        $invalidDestinationPathtestCases = @(
            @{
                Path = $testFilePath
                Destination = ".\Source"            
                ExpectedFullyQualifiedErrorId = "RemotePathIsNotAbsolute,Microsoft.PowerShell.Commands.CopyItemCommand"
            }
            @{
                Path = $testFilePath
                Destination = "c:\FolderThatDoesNotExist\Foo\Bar"
                ExpectedFullyQualifiedErrorId = "RemotePathNotFound,Microsoft.PowerShell.Commands.CopyItemCommand"
            }
            @{
                Path = $testFilePath
                Destination = $null
                ExpectedFullyQualifiedErrorId = "CopyItemRemoteDestinationIsNullOrEmpty,Microsoft.PowerShell.Commands.CopyItemCommand"
            }
            @{
                Path = $testFilePath
                Destination = ""
                ExpectedFullyQualifiedErrorId = "CopyItemRemoteDestinationIsNullOrEmpty,Microsoft.PowerShell.Commands.CopyItemCommand"
            }
        )

        foreach ($testCase in $invalidDestinationPathtestCases) {
           Test-CopyItemError @testCase
        }
    }
}

Describe "Validate Copy-Item error for target sessions not in FullLanguageMode." -Tags "Innerloop", "RI", "P1" {

    BeforeAll {
        # Keep track of the sessions.
        $testSessions = @{}
        # Keep track of the session names to be unregistered.
        $sessionToUnregister = @()

        $testDirectory = "TestDrive:\"

        # Create the test file and directories.
        $source = "$testDirectory\Source"
        $destination = "$testDirectory\Destination"

        # return before doing anything
        if ( ! (ShouldRun) ) { return }

        New-Item $source -ItemType Directory -Force | Out-Null
        New-Item $destination -ItemType Directory -Force | Out-Null

        $testFilePath = Join-Path $source "testfile.txt"
        "File test content" | Out-File $testFilePath -Force

        $languageModes = @("ConstrainedLanguage", "NoLanguage", "RestrictedLanguage")
        $id = (Get-Random).ToString()
        
        foreach ($languageMode in $languageModes)
        {
            $sessionName = $languageMode + "_" + $id
            $sessionToUnregister += $sessionName
            $configFilePath = Join-Path $testDirectory "test.pssc"

            # Create the session.
            # Write-Host "Creating pssession with '$languageMode' ..."
            New-PSSessionConfigurationFile -Path $configFilePath -SessionType Default -LanguageMode $languageMode
            Register-PSSessionConfiguration -Name $sessionName -Path $configFilePath -Force | Out-Null
            $testSession = New-PSSession -ConfigurationName $sessionName

            # Validate that the session is opened.
            # $testSession.State | Should Be "Opened"

            # Add the new session to the list.
            $testSessions[$languageMode] = $testSession

            # Remove the pssc file.
            Remove-Item $configFilePath -Force -ea SilentlyContinue
        }
    }

    AfterAll {
        if ( ! (ShouldRun) ) { return }
        $testSessions.Values | Remove-PSSession -ea SilentlyContinue
        $sessionToUnregister | foreach { Unregister-PSSessionConfiguration -Name $_ -Force -ea SilentlyContinue }
    }

    foreach ($languageMode in $testSessions.Keys)
    {
        It "Copy-Item throws 'SessionIsNotInFullLanguageMode' error for a session in '$languageMode'" {
            $session = $testSessions[$languageMode]

            # FromSession
            try
            {
                Copy-Item -Path $testFilePath -FromSession $session -Destination $destination -Force -Verbose -ea Stop
                throw "CodeExecuted"
            }
            catch
            {
                $_.FullyQualifiedErrorId | should be "SessionIsNotInFullLanguageMode,Microsoft.PowerShell.Commands.CopyItemCommand"
            }

            # ToSession
            try
            {
                Copy-Item -Path $testFilePath -ToSession $session -Destination $destination -Force -Verbose -ea Stop
                throw "CodeExecuted"
            }
            catch
            {
                $_.FullyQualifiedErrorId | should be "SessionIsNotInFullLanguageMode,Microsoft.PowerShell.Commands.CopyItemCommand"
            }
        }
    }
}
