<############################################################################################ 
 # File: HelperMethods.psm1
 # This file contains helper methods that will be used by Microsoft.PowerShell.Archive Test's.
 #
 ############################################################################################>

 Import-Module Microsoft.PowerShell.Archive -Force -Global
 Include Asserts.psm1
  . "$PSScriptRoot\uiproxy.ps1"

 <############################################################################################ 
 # 
 # Name:        GetTargetResourceExecutionHelper
 # Description: This is a helper method used to test Get functionality of RoleProvider.
 #
 ############################################################################################>
function CompressArchivePathParameterSetValidator {

    param 
    (
        [string[]] $path,
        [string] $destinationPath,
        [string]$compressionLevel = "Optimal"
    )

    try
    {
        Compress-Archive -Path $path -DestinationPath $destinationPath -CompressionLevel $compressionLevel
        Assert ($false) "Failed to detect ValidateNotNullOrEmpty attribute is missing on one or parameters belonging to Path parameterset."
    }
    catch
    {
        if($null -eq $_ -or $null -eq $_.FullyQualifiedErrorId -or $_.FullyQualifiedErrorId -ne "ParameterArgumentValidationError,Compress-Archive")
        {
           Assert ($false) "Failed to detect ValidateNotNullOrEmpty attribute is missing on one or parameters belonging to Path parameterset."
        }
    }
}

function CompressArchiveLiteralPathParameterSetValidator {

    param 
    (
        [string[]] $literalPath,
        [string] $destinationPath,
        [string]$compressionLevel = "Optimal"
    )

    try
    {
        Compress-Archive -LiteralPath $literalPath -DestinationPath $destinationPath -CompressionLevel $compressionLevel
        Assert ($false) "Failed to detect ValidateNotNullOrEmpty attribute is missing on one or parameters belonging to LiteralPath parameterset."
    }
    catch
    {
        if($null -eq $_ -or $null -eq $_.FullyQualifiedErrorId -or $_.FullyQualifiedErrorId -ne "ParameterArgumentValidationError,Compress-Archive")
        {
           Assert ($false) "Failed to detect ValidateNotNullOrEmpty attribute is missing on one or parameters belonging to LiteralPath parameterset."
        }
    }
}

function CompressArchiveInValidPathValidator {

    param 
    (
        [string[]] $path,
        [string] $destinationPath,
        [string] $invalidPath,
        [string] $expectedFullyQualifiedErrorId
    )

    try
    {   
        Compress-Archive -Path $path -DestinationPath $destinationPath           
        Assert ($false) "Failed to validate that an invalid Path $invalidPath was supplied as input to Compress-Archive cmdlet."
    }
    catch
    {
        
        if($null -eq $_ -or $null -eq $_.FullyQualifiedErrorId -or $_.FullyQualifiedErrorId -ne $expectedFullyQualifiedErrorId)
        {
           Assert ($false) "Failed to validate that an invalid Path $invalidPath was supplied as input to Compress-Archive cmdlet."
        }
    }
}

function CompressArchiveInValidArchiveFileExtensionValidator {

    param 
    (
        [string[]] $path,
        [string] $destinationPath,
        [string] $invalidArchiveFileExtension
    )

    try
    {
        Compress-Archive -Path $path -DestinationPath $destinationPath             
        Assert ($false) "Failed to validate that an invalid archive file format $invalidArchiveFileExtension was supplied as input to Compress-Archive cmdlet."
    }
    catch
    {
        if($null -eq $_ -or $null -eq $_.FullyQualifiedErrorId -or $_.FullyQualifiedErrorId -ne "NotSupportedArchiveFileExtension,Compress-Archive")
        {
        Assert ($false) "Failed to validate that an invalid archive file format $invalidArchiveFileExtension was supplied as input to Compress-Archive cmdlet."
        }
    }
}

function ArchiveFileEntriesValidator {

    param 
    (
        [string] $path,
        [int] $expectedEntryCount
    )

    Add-Type -AssemblyName System.IO.Compression

    try
    {
        $archiveFileStreamArgs = @($path, [System.IO.FileMode]::Open)
        $archiveFileStream = New-Object -TypeName System.IO.FileStream -ArgumentList $archiveFileStreamArgs

        $zipArchiveArgs = @($archiveFileStream, [System.IO.Compression.ZipArchiveMode]::Read, $false)
        $zipArchive = New-Object -TypeName System.IO.Compression.ZipArchive -ArgumentList $zipArchiveArgs

        $actualEntryCount = $zipArchive.Entries.Count
        Assert ($expectedEntryCount -eq $actualEntryCount) "Failed to Update archive file successfully. Expected number of files in the archive file $path is $expectedEntryCount but found $actualEntryCount after running update on the archive file."
    }
    catch
    {
        Assert ($false) "Failed to inspect the number of files in the archive file $path"
    }
    finally
    {
        If($null -ne $zipArchive)
        {
            $zipArchive.Dispose()
        }

        If($null -ne $archiveFileStream)
        {
            $archiveFileStream.Dispose()
        }
    }
}

function ArchiveFileEntryContentValidator {

    param 
    (
        [string] $path,
        [string] $entryFileName,
        [string] $expectedEntryFileContent
    )

    Add-Type -AssemblyName System.IO.Compression

    try
    {
        $destFile = "$pwd\ExpandedFile.txt"

        $archiveFileStreamArgs = @($path, [System.IO.FileMode]::Open)
        $archiveFileStream = New-Object -TypeName System.IO.FileStream -ArgumentList $archiveFileStreamArgs

        $zipArchiveArgs = @($archiveFileStream, [System.IO.Compression.ZipArchiveMode]::Read, $false)
        $zipArchive = New-Object -TypeName System.IO.Compression.ZipArchive -ArgumentList $zipArchiveArgs

        foreach($currentArchiveEntry in $zipArchive.Entries)
        {
            $comparisonResult = [string]::Compare($currentArchiveEntry.FullName, $entryFileName, [System.StringComparison]::OrdinalIgnoreCase)

            if($comparisonResult -eq 0)
            {
                $entryToBeUpdated = $currentArchiveEntry                           
                break
            }
        }

        if($entryToBeUpdated -ne $null)
        {
            $srcStream = $entryToBeUpdated.Open()
            $destStream = New-Object "System.IO.FileStream" -ArgumentList( $destFile, [System.IO.FileMode]::Create )
            $srcStream.CopyTo( $destStream )
            $destStream.Dispose()
            $srcStream.Dispose()

            $actualEntryFileContent = Get-Content $destFile
            $comparisonResult = [string]::Compare($expectedEntryFileContent, $actualEntryFileContent, [System.StringComparison]::OrdinalIgnoreCase)

            if($comparisonResult -ne 0)
            {
                Assert ($false) "The content of $entryFileName is expected to be $expectedEntryFileContent but the actual content is $actualEntryFileContent"
            }
        }
        else
        {
            Assert ($expectedEntryCount -eq $actualEntryCount) "Failed to find the file $entryFileName in the archive file $path"
        }
    }
    catch
    {
        Assert ($false) "Failed to inspect either the number of files in the archive file $path"
    }
    finally
    {
        If($null -ne $zipArchive)
        {
            $zipArchive.Dispose()
        }

        If($null -ne $archiveFileStream)
        {
            $archiveFileStream.Dispose()
        }

        del "$destFile" -Force -Recurse -ErrorAction SilentlyContinue
    }
}

function ExpandArchiveInvalidParameterValidator {

    param 
    (
        [boolean] $isLiteralPathParameterSet,
        [string[]] $path,
        [string] $destinationPath,
        [string] $expectedFullyQualifiedErrorId
    )

    try
    {
        if($isLiteralPathParameterSet)
        {
            Expand-Archive -LiteralPath $literalPath -DestinationPath $destinationPath
        }
        else
        { 
            Expand-Archive -Path $path -DestinationPath $destinationPath
        }

        Assert ($false) "Failed to detect ValidateNotNullOrEmpty attribute is missing on one or parameters belonging to Path parameterset."
    }
    catch
    {
        if($null -eq $_ -or $null -eq $_.FullyQualifiedErrorId -or $_.FullyQualifiedErrorId -ne $expectedFullyQualifiedErrorId)
        {
            Assert ($false) "Failed to detect ValidateNotNullOrEmpty attribute is missing on one or parameters belonging to Path parameterset."
        }
    }
}

function ExpandArchiveHelper {

    param 
    (
        [string[]] $sourcePath,
        [string[]] $emptyDirs,
        [string]   $sourceDir
    )

    try
    {
        $content = "Some Data"
        $sourceDirPath = Join-Path $pwd -ChildPath $sourceDir

        foreach($currentItem in $sourcePath)
        {
            $currentItemPath = Join-Path $sourceDirPath -ChildPath $currentItem
            $content | Out-File -FilePath $currentItemPath
        }

        Add-Type -AssemblyName System.IO.Compression.FileSystem

        $archiveFilePath = "$pwd\Sample.zip"
        [System.IO.Compression.ZipFile]::CreateFromDirectory("$pwd\$sourceDir", $archiveFilePath)

        $destinationPath = "$pwd\DestinationDir"
        New-Item $destinationPath -Type Directory | Out-Null

        Expand-Archive -Path $archiveFilePath -DestinationPath $destinationPath

        foreach($currentFile in $sourcePath)
        {
            $expandedFile = Join-Path $destinationPath -ChildPath $currentFile
            $result = Test-Path $expandedFile
            if($result -eq $true) { Log -Message "Found Expanded File: $($expandedFile)."}
            Assert ($result -eq $true) "Failed to Expand archive file $archiveFilePath ."
            $destSourceFileContent = Get-Content $expandedFile
            Assert ($content -eq $destSourceFileContent) "Failed to Expand archive file $archiveFilePath successfully. Expected File $expandedFile content is $content but actual file contennt is $destSourceFileContent"
        }

        foreach($currentEmptyDir in $emptyDirs)
        {
            $currentEmptyDirinDestPath = Join-Path $destinationPath -ChildPath $currentEmptyDir
            $result = Test-Path $currentEmptyDirinDestPath
            if($result -eq $true) { Log -Message "Found Empty Directory: $($currentEmptyDirinDestPath)."}
            Assert ($result -eq $true) "Failed to Expand archive file $archiveFilePath containing empty directory $currentEmptyDir successfully. Expected directory at $currentEmptyDirinDestPath but did not find it."
        }
    }
    catch
    {
        $currentError = $_.FullyQualifiedErrorId
        Assert ($false) "Failed to Expand archive file $archiveFilePath The FullyQualifiedErrorId is $currentError."
    }

    finally
    {
        del "$pwd\$sourceDir" -Force -Recurse -ErrorAction SilentlyContinue
        del "$destinationPath" -Force -Recurse -ErrorAction SilentlyContinue
        del "$archiveFilePath" -Force -Recurse -ErrorAction SilentlyContinue
    }
}

<############################################################################################ 
# Name: ExpandArchivePipelineTestValidationHelper
# Description: This is a helper method used to validate the expanded files/directories 
# created by executing Expand-Archive cmdlet.
############################################################################################>
function ExpandArchivePipelineTestValidationHelper {

    param 
    (
        [string[]] $expectedExpandedItems,
        [string]   $expectedEmptyDir,
        [boolean] $useEmptyDir
    )

    foreach($currentItem in $expectedExpandedItems)
    {
        $result = Test-Path $currentItem
        if($result -eq $true) { Log -Message "Found File: $($currentItem)."}
        Assert ($result -eq $true) "Failed to Expand archive file $archiveFilePath completly. $currentItem is not found at the expanded location"

        $expectedContent = "Some Data"
        $actualContent = Get-Content $currentItem
        Assert ($expectedContent -eq $actualContent) "The content of $currentItem in the expanded location does not match the expected content. The expected content is $expectedContent but the actual content is $actualContent"
    }

    if($useEmptyDir)
    {
        $currentItem = $expectedEmptyDir
        $result = Test-Path $currentItem
        if($result -eq $true) { Log -Message "Found Empty Dir: $($currentItem)."}
        Assert ($result -eq $true) "Failed to Expand archive file $archiveFilePath completly. $currentItem is not found at the expanded location"
    }
}

function ValidationHelperWhenDestinationPathIsNotSupplied {

    param 
    (
        [string]   $destinationPath
    )

    $archiveFilePath = "$pwd\SamplePreCreatedArchive.zip"
    $content = "Some Data"

    $files = @()
    $files += "Sample-1.txt"
    $files += "Sample-2.txt"

    try
    {
        Expand-Archive -Path $archiveFilePath -Verbose

        $result = Test-Path $destinationPath
        if($result -eq $true) { Log -Message "Expanded archive file contents to directory: $($destinationPath)."}
        Assert ($result -eq $true) "Failed to Expand archive file $archiveFilePath contents to $destinationPath when -DestinationPath parameter is not used."

        foreach($currentFile in $files)
        {
            $expandedFile = Join-Path $destinationPath -ChildPath $currentFile
            $result = Test-Path $expandedFile
            if($result -eq $true) { Log -Message "Found Expanded File: $($expandedFile)."}
            Assert ($result -eq $true) "Failed to Expand archive file $archiveFilePath ."
            $destSourceFileContent = Get-Content $expandedFile
            Assert ($content -eq $destSourceFileContent) "Failed to Expand archive file $archiveFilePath successfully. Expected File $expandedFile content is $content but actual file content is $destSourceFileContent"
        }
    }
    finally
    {
        Remove-Item "$destinationPath" -Force -Recurse -ErrorAction SilentlyContinue
    }
}

function CreateArchiveDataStore {

    param 
    (
    )

    New-Item $pwd\SourceDir -Type Directory | Out-Null
    New-Item $pwd\SourceDir\ChildDir-1 -Type Directory | Out-Null
    New-Item $pwd\SourceDir\ChildDir-2 -Type Directory | Out-Null
    New-Item $pwd\SourceDir\ChildEmptyDir -Type Directory | Out-Null

    $content = "Some Data"
    $content | Out-File -FilePath $pwd\SourceDir\Sample-1.txt
    $content | Out-File -FilePath $pwd\SourceDir\Sample-2.txt
    $content | Out-File -FilePath $pwd\SourceDir\ChildDir-1\Sample-3.txt
    $content | Out-File -FilePath $pwd\SourceDir\ChildDir-1\Sample-4.txt
    $content | Out-File -FilePath $pwd\SourceDir\ChildDir-2\Sample-5.txt    
    $content | Out-File -FilePath $pwd\SourceDir\ChildDir-2\Sample-6.txt
 
    "Some Text" > $pwd\Sample.unzip
    "Some Text" > $pwd\Sample.cab

    Rename-Item SamplePreCreatedArchive.archive SamplePreCreatedArchive.zip -ErrorAction SilentlyContinue
}

function DeleteArchiveDataStore {

    param 
    (
    )

    del "$pwd\SourceDir" -Force -Recurse -ErrorAction SilentlyContinue
    del "$pwd\Sample.unzip" -Force -Recurse -ErrorAction SilentlyContinue
    del "$pwd\Sample.cab" -Force -Recurse -ErrorAction SilentlyContinue
}

<############################################################################################ 
# Name: IsPlatformSupported
# Description: This is a helper method used to validate if archive cmdlets is supported on the
# target platform.
############################################################################################>
function IsPlatformSupported {

    param 
    (
    )

    # Check if the platform is arm. 
    # If so return $false, else return $true.
    $architecture = $env:PROCESSOR_ARCHITECTURE
    if($architecture -eq "arm" -or $architecture -eq "arm64")
    {
        return $false
    }
    return $true
}



