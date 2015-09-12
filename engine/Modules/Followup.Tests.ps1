# This is a Pester test suite to validate the Test Followups for Powershell Module Versioning
#
# Copyright (c) Microsoft Corporation, 2015
#
#

Describe "TestFollowupForBugs" {

    <#
    Purpose:
        Verify TFS bug: 2173155 Get-Module -ListAvailable report the subfolder 
        as a module when there is psd1 file in the version\subfolder where subfolder 
        name is same as the module name and the root module folder is empty.
                
    Action:
        Create a module under $pshome\Modules with version folder. Place valid psd1 file under both version folder and nested folder.
        In old behavior, get-module -ListAvailable will show both modules.
        The fix should avoid that and ignore the nested module.
               
    Expected Result: 
        Only the psd1 file under version folder will be discovered.
    #>
    It "Bug 2173155" {
        $moduleName="TestModVer_$(Get-Random)"
        $modulePath = "$pshome\Modules\$modulename"
        md $modulePath

        $version = "1.0.3.1"
        $version2 = "1.0"
        md $modulePath\$version

        $manifestPath = "$modulePath\$version\$moduleName.psd1"

        # create the root psd1 file supposd to be discovered
        New-ModuleManifest $manifestPath -ModuleVersion $version

        $nestedModule = "$modulePath\$version\$moduleName"

        md $nestedModule

        $nestedManifestPath = "$nestedModule\$moduleName.psd1"

        # create the nested psd1 file not supposd to be discovered
        New-ModuleManifest $nestedManifestPath -ModuleVersion $version2

        try
        {
            $module = get-module -ListAvailable $moduleName
            $module.Count | should be 1
            $module.Version.ToString() | should be $version
        }
        catch
        {
            throw $_.FullyQualifiedErrorId
        }
        finally
        {
            Remove-Item $modulePath -Recurse -Force
        }
    }

    <#
    Purpose:
        Verify TFS bug: 1169495 Exceptions raised in a script loaded via a module's ScriptsToProcess 
        manifest entry don't prevent a module from loading
                
    Action:
        Create a module under $pshome\Modules with a script throwing exception. Load the script in ScriptsToProcess in a module Manifest file.
        Import the module manifest
               
    Expected Result: 
        The module should not be loaded.
    #>
    It "Bug 1169495" {
        $moduleName="ModuleA"
        $modulePath = "$pshome\Modules\$modulename"
        if (test-path $modulePath)
        {
            Remove-Item $modulePath -Recurse -Force
        }
        md $modulePath

        # Create ModuleA manifest
        New-ModuleManifest -path $modulesPath\ModuleA.psd1 -RootModule ModuleA.psm1 -ModuleVersion 1.0.0.1 -ScriptsToProcess ScriptA.ps1 -FileList @('ModuleA.psm1','ModuleA.psd1','ScriptA.ps1')
        
        # Create ModuleA script module
@'
Write-Host 'Look at me, I''m loading, even though an exception was raised!'
'@ | Out-File -LiteralPath $modulesPath\ModuleA.psm1
        # Create ScriptA file
@"
throw 'Something bad happened, so the module shouldn''t load.'
"@ | Out-File -LiteralPath $modulesPath\ScriptA.ps1


        Get-Module ModuleA | Remove-Module -ErrorAction SilentlyContinue

        try
        {
            # Load ModuleA
            Import-Module ModuleA -Force -ErrorAction SilentlyContinue
            throw "Throw exception in scriptToProcess should be caught as it is."
        }
        catch
        {
            $module = Get-Module ModuleA
            $module.Count | should be 0
        }
        finally
        {
            Remove-Item $modulePath -Recurse -Force
        }
    }

    <#
    Purpose:
        Verify TFS bug: 1169509 Exceptions raised in a module manifest cause an 
        incorrect error to be generated after the exception is displayed
                
    Action:
        Create a module under $pshome\Modules with psm1 file throwing exception. 
        Import the module. 
               
    Expected Result: 
        When you import the module, you should only see the one, true exception that the module raised, allowing you to take appropriate action to then load the module again.  
        No error pointing the finger at the module author should be displayed in this use case.

    #>
    It "Bug 1169509" {
        $moduleName="ModuleB"
        $modulePath = "$pshome\Modules\$modulename"
        if (test-path $modulePath)
        {
            Remove-Item $modulePath -Recurse -Force
        }
        md $modulePath

        # Create ModuleB manifest
        New-ModuleManifest -path $modulesPath\ModuleB.psd1 -RootModule ModuleB.psm1 -ModuleVersion 1.0.0.1 -FileList @('ModuleB.psm1','ModuleB.psd1')
        
        # Create ModuleB script module
@'
function Test-ForPrerequisite {
[CmdletBinding()]
param()
$false
}
if (-not (Test-ForPrerequisite)) {
throw 'Prequisite requirements are not met. Correct them and then try loading the module again.'
}
'@ | Out-File -LiteralPath $modulesPath\ModuleB.psm1

        Get-Module ModuleB | Remove-Module -ErrorAction SilentlyContinue

        try
        {
            # Load ModuleB
            Import-Module ModuleB -Force -ErrorAction SilentlyContinue
            throw "Throw exception in scriptToProcess should be caught as it is."
        }
        catch
        {
        }
        finally
        {
            Remove-Item $modulePath -Recurse -Force
        }
    }

    <#
    Purpose:
        Verify TFS bug: 2320366 "Get-Module -Name $null -ListAvailable", -Name param value is not validated 
                
    Action:
        Get-Module -Name $null -ListAvailable
        Get-Module -Name "" -ListAvailable
               
    Expected Result: 
        Grace exception should be thrown
    #>
        It "Bug 2320366" {
            try
            {
                Get-Module -Name $null -ListAvailable
                throw "No exception is caught, ParameterArgumentValidationError is expected."
            }
            catch
            {
                $_.FullyQualifiedErrorId | should be "ParameterArgumentValidationError,Microsoft.PowerShell.Commands.GetModuleCommand"
            }

            try
            {
                Get-Module -Name "" -ListAvailable
                throw "No exception is caught, ParameterArgumentValidationError is expected."
            }
            catch
            {
                $_.FullyQualifiedErrorId | should be "ParameterArgumentValidationError,Microsoft.PowerShell.Commands.GetModuleCommand"
            }
        }

    <#
    Purpose:
        Verify TFS bug: 1987318 Import-Module incorrectly detects a cycle in the module dependency graph
                
    Action:
        Create a bunch modules which don't contain cycle logically
               
    Expected Result: 
        root module should be imported without exception.

    #>
    It "Bug 1987318" {
        $ModulePath = Join-Path $env:USERPROFILE "Documents\WindowsPowerShell\Modules"
        "m1","m2","m3","m4","m5","m6" | %{ new-item -type directory (Join-Path $ModulePath $_ ) -ea 0 } | out-null
 
        New-ModuleManifest -Path (Join-Path $ModulePath "m1\m1.psd1") -RequiredModules "m5","m2"
        New-ModuleManifest -Path (Join-Path $ModulePath "m2\m2.psd1") -RequiredModules "m3","m4"
        New-ModuleManifest -Path (Join-Path $ModulePath "m3\m3.psd1") -RequiredModules "m4"
        New-ModuleManifest -Path (Join-Path $ModulePath "m4\m4.psd1") -RequiredModules "m5"
        New-ModuleManifest -Path (Join-Path $ModulePath "m5\m5.psd1")
 
        # m1 ------------------------> m5
        # |----> m2 ---------> m4 -----^
        #        |----> m3 ----^
 
        #No cycles, this can be loaded m5, m4, m3, m2, m1


        try
        {
            import-module m1 -force
        }
        catch
        {
            throw $_.FullyQualifiedErrorId
        }
        finally
        {
            "m1","m2","m3","m4","m5" | %{ rm -Recurse (Join-Path $ModulePath $_ ) }
        }
    }

    <#
    Purpose:
        Verify TFS bug: 2737519 Import-Module -Assembly does not return object to pipeline when -PassThru is used
                
    Action:
        import a binary module with -passthru
               
    Expected Result: 
        module object should be returned

    #>
    It "Bug 2737519" {
        $nsName = "MyUnitTest"
        $className = "MyClass_" + (Get-Random)
        $source = @"
using System.Management.Automation;
namespace $nsName {
[Cmdlet("Invoke", "$className")]
public sealed class $className : PSCmdlet {
   protected override void ProcessRecord() {
     this.WriteObject(this.MyInvocation.MyCommand.Name); 
   }
  }
}
"@
        $type = Add-Type -TypeDefinition $source -Language CSharp -PassThru 
        # ** BUG ** Import-Module is not returning an object when -PassThru is used
        $module = Import-Module -Assembly $type[0].Assembly -PassThru -Force
        $module.gettype().name | should be "PSModuleInfo"
    }

    <#
    Purpose:
        Verify TFS bug: 2737859 Import-Module -Assembly with dynamic code incorrectly stores entries in the ModuleTable
                
    Action:
        import several assemblies that doesn't have physical location
               
    Expected Result: 
        the module should be imported and the cmdlets from the module should be valid

    #>
    It "Bug 2737859" {
    function GenerateCmdlet {
        $nsName = "MyUnitTest"
        $className = "MyClass_" + (Get-Random)
        $source = @"
using System.Management.Automation;
namespace $nsName {
    [Cmdlet("Invoke", "$className")]
    public sealed class $className : PSCmdlet {
        protected override void ProcessRecord() { 
            this.WriteVerbose(string.Format("hi {0}", this.MyInvocation.MyCommand.Name));
        }
    }
}
"@
        $type = Add-Type -TypeDefinition $source -Language CSharp -PassThru
        Import-Module -Assembly $type[0].Assembly -Force
        return "Invoke-$className"
    }
    $Error.Clear()
       Set-Location cert:
    # Generate memory assemblies several times, make sure the unique module name is added to the module table.
    Set-Location C:\
    $cmdlet = GenerateCmdlet ; . $cmdlet
    $cmdlet = GenerateCmdlet ; . $cmdlet
    Set-Location cert:
    $cmdlet = GenerateCmdlet ; . $cmdlet
    $cmdlet = GenerateCmdlet ; . $cmdlet
    Set-Location C:\
    $cmdlet = GenerateCmdlet ; . $cmdlet
}


    <#
    Purpose:
        Verify TFS bug: 1571197 Import-Module fails when PSModulePath contains a provider-qualified UNC path and the $PWD is not a FileSystem path
                
    Action:
        cd to a registry location, import a module from unc path
               
    Expected Result: 
        the module should be imported and the cmdlets from the module should be valid

    #>
    It "Bug 1571197" {

    pushd $HOME

    $driverLetter = $env:SystemDrive.Remove($env:SystemDrive.Length - 1) + "$"

    $uncModuleBasePath = "filesystem::\\$env:computername\$driverLetter\temp"
    $uncModulePath = "filesystem::\\$env:computername\$driverLetter\temp\mod1"

    if (!(Test-Path $uncModulePath))
    {
        new-item -type directory $uncModulePath | out-null
    }
    else
    {
        Remove-Item $uncModulePath -Recurse -Force -ErrorAction SilentlyContinue
        new-item -type directory $uncModulePath | out-null
    }

    echo "function mod1_foo() { write-host 'mod1!' }" > "$uncModulePath\mod1.psm1"

    $reseveredModulePath = $env:PSModulePath
    if( !($env:PSModulePath.Split( ';' ) -contains $uncModuleBasePath) )
    {
        $env:PSModulePath = "$($env:PSModulePath);$uncModuleBasePath"
    }

    cd HKCU:\

    try
    {
        Import-Module mod1 -ErrorAction Stop

        $m1 = Get-Module mod1 -ErrorAction Stop

    }
    catch
    {
        throw $_
    }
    finally
    {
        remove-item $uncModuleBasePath -Recurse -Force -ErrorAction SilentlyContinue
        $env:PSModulePath = $reseveredModulePath
        popd
    }
}
}


Describe "Win8TestFollowupForBugs" {

    It "bug284599-GetModuleFormat" {
        # Do a Get-Module after Get-Module -List
        Get-Module -ListAvailable | Out-Null
        $modules = Get-Module

        foreach ($m in $modules)
        {
            $m.PSTypeNames.Contains("ModuleInfoGrouping") | should be $false
        }
    }
}
