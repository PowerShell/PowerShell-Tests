# This is a Pester test suite to validate the Format-Hex cmdlet in the Microsoft.PowerShell.Utility module.
#
# Copyright (c) Microsoft Corporation, 2015
#

<#
    Purpose:
        Verify that Format-Hex display the Hexa decmial value for the input data.
                
    Action:
        Run Format-Fex.
               
    Expected Result: 
        Hexa decimal equivalent of the input data is displayed. 
#>

Describe "FormatHex" {
    
    New-Item TestDrive:\FormatHexDataDir -Type Directory  -Force | Out-Null
    $inputFile = "TestDrive:\FormatHexDataDir\SourceFile-1.txt"
    $inputText = 'Hello World'
    Set-Content -Value $inputText -Path $inputFile

    # This test is to validate to pipeline support in Format-Hex cmdlet.  
    It "ValidatePipelineSupport" {

        # InputObject Parameter set should get invoked and 
        # the input data should be treated as string.
        $result = $inputText | Format-Hex
        $result | Should Not Be $null
        $result.GetType().Name | Should Be 'ByteCollection'
        $actualResult = $result.ToString()
        ($actualResult -match $inputText) | Should Be $true
    }

    # This test is to validate to pipeline support in Format-Hex cmdlet.  
    It "ValidateByteArrayInputSupport" {

        # InputObject Parameter set should get invoked and 
        # the input data should be treated as byte[].
        $inputBytes = [System.Text.Encoding]::ASCII.GetBytes($inputText)

        $result =  Format-Hex -InputObject $inputBytes
        $result | Should Not Be $null
        $result.GetType().Name | Should Be 'ByteCollection'
        $actualResult = $result.ToString()
        ($actualResult -match $inputText) | Should Be $true   
    }

    # This test is to validate to input given through Path paramter set in Format-Hex cmdlet.
    It "ValidatePathParameterSet" {

        $result =  Format-Hex -Path $inputFile
        $result | Should Not Be $null
        $result.GetType().Name | Should Be 'ByteCollection'
        $actualResult = $result.ToString()
        ($actualResult -match $inputText) | Should Be $true  
    }

    # This test is to validate to Path paramter set is considered as default in Format-Hex cmdlet.
    It "ValidatePathAsDefaultParameterSet" {

        $result =  Format-Hex $inputFile
        $result | Should Not Be $null
        $result.GetType().Name | Should Be 'ByteCollection'
        $actualResult = $result.ToString()
        ($actualResult -match $inputText) | Should Be $true  
    }

    # This test is to validate to input given through LiteralPath paramter set in Format-Hex cmdlet.
    It "ValidateLiteralPathParameterSet" {
        
        $result =  Format-Hex -LiteralPath $inputFile
        $result | Should Not Be $null
        $result.GetType().Name | Should Be 'ByteCollection'
        $actualResult = $result.ToString()
        ($actualResult -match $inputText) | Should Be $true
    }

    # This test is to validate to input given through pipeline. The input being piped from results of Get-hildItem
    It "ValidateFileInfoPipelineInput" {
        
        $result = Get-ChildItem $inputFile | Format-Hex
        $result | Should Not Be $null
        $result.GetType().Name | Should Be 'ByteCollection'
        $actualResult = $result.ToString()
        ($actualResult -match $inputText) | Should Be $true
    }

    # This test is to validate Encoding formats functionality of Format-Hex cmdlet.
    It "ValidateEncodingFormats" {
        
        $result =  Format-Hex -InputObject $inputText -Encoding ASCII
        $result | Should Not Be $null
        $result.GetType().Name | Should Be 'ByteCollection'
        $actualResult = $result.ToString()
        ($actualResult -match $inputText) | Should Be $true
    }

    # This test is to validate the alias for Format-Hex cmdlet.
    It "ValidateCmdletAlias" {
        
        try
        {
            $result = Get-Command fhx -ErrorAction Stop
            $result | Should Not Be $null
            $result.CommandType | Should Not Be $null
            $result.CommandType.ToString() | Should Be "Alias"
        }
        catch
        {
            $_ | Should Be $null
        }
    }
}
