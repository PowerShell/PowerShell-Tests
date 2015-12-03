function ShouldRun($testCaseName)
{
    # test-computersecurechannel only works if the test machine is on a domain 
    if($env:PROCESSOR_ARCHITECTURE -eq "ARM")
    {
        return $false
    }
	return $true
}

if(ShouldRun)
{
    Describe "Test-ComputerSecureChannel" -Tags "innerloop" {

        BeforeAll {
            $localHostNames = @(
                "localHost",
	            ".",
	            "::1",
	            "127.0.0.1",
	            $env:COMPUTERNAME,
	            ($env:COMPUTERNAME + '.' + [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().DomainName)
            )
        }

        It "works with localhost" {
            $localHostNames | % { Test-ComputerSecureChannel -Server $_ | Should Be $true }
        }

        It -pending "works with repair" {
            Test-ComputerSecureChannel -Repair | Should Be $true
        }

        It "throws error with invalid server name" {
            try
            {
                Test-ComputerSecureChannel -Server TestComputerSecureChannelFailsWithInvalidServerName 
            }
            catch
            {
                $secureChannelError = $_
            }

            $secureChannelError.FullyQualifiedErrorId | Should Be 'AddressResolutionException,Microsoft.PowerShell.Commands.TestComputerSecureChannelCommand'
        }

        It "throws error with null credential" {
            try
            {
                Test-ComputerSecureChannel -Credential
            }
            catch
            {
                $secureChannelError = $_
            }

            $secureChannelError.FullyQualifiedErrorId | Should Be 'MissingArgument,Microsoft.PowerShell.Commands.TestComputerSecureChannelCommand'
        }
    }
}