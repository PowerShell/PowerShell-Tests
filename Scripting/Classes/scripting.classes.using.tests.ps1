Describe 'using module' -Tags "DRT" {
    
    Import-Module $PSScriptRoot\..\LanguageTestSupport.psm1

    function New-TestModule {
        param(
            [string]$Name, 
            [string]$Content, 
            [switch]$Manifest, 
            [version]$Version = '1.0' # ignored, if $Manifest -eq $false
        )
        
        if ($manifest) {
            mkdir -Force "TestDrive:\$Name\$Version" > $null    
            Set-Content -Path TestDrive:\$Name\$Version\$Name.psm1 -Value $Content
            New-ModuleManifest -RootModule "$Name.psm1" -Path TestDrive:\$Name\$Version\$Name.psd1 -ModuleVersion $Version
        } else {
            mkdir -Force "TestDrive:\$Name" > $null
            Set-Content -Path TestDrive:\$Name\$Name.psm1 -Value $Content
        }

        $resolvedTestDrivePath = Split-Path ((ls TestDrive:\)[0].FullName)
        if (-not ($env:PSModulePath -like "*$resolvedTestDrivePath*")) {
            $env:PSModulePath += ";$resolvedTestDrivePath"
        }
    }

    $originalPSModulePath = $env:PSModulePath

    try {
        
        # Create modules in TestDrive:\
        New-TestModule -Name Foo -Content 'class Foo { [string] GetModuleName() { return "Foo" } }'
        New-TestModule -Manifest -Name FooWithManifest -Content 'class Foo { [string] GetModuleName() { return "FooWithManifest" } }'
        
        It 'Import-Module has ImplementedAssembly, when classes are present in the module' {
            $module = Import-Module Foo  -PassThru
            try {
                $module.ImplementingAssembly | Should Not Be $null
            } finally {
                $module | Remove-Module
            }
        }

        It "can use class from another module as a base class with using module" {
            $barType = [scriptblock]::Create(@"
using module Foo
class Bar : Foo {}
[Bar]
"@).Invoke()
            
            $barType.BaseType.Name | Should Be 'Foo'
        }

        It "can use class from another module in New-Object" {
            $foo = [scriptblock]::Create(@"
using module FooWithManifest
using module Foo
New-Object FooWithManifest.Foo
New-Object Foo.Foo
"@).Invoke()

            $foo.Count | Should Be 2
            $foo[0].GetModuleName() | Should Be 'FooWithManifest'
            $foo[1].GetModuleName() | Should Be 'Foo'
        }

        It "can use class from another module by full name as base class and [type]" {
            $fooObject = [scriptblock]::Create(@"
using module Foo
class Bar : Foo.Foo {}
[Foo.Foo]::new()
"@).Invoke()
            $fooObject.GetModuleName() | Should Be 'Foo' 
        }

        It "can use modules with classes collision" {
            # we use 3 classes with name Foo at the same time
            # two of them come from 'using module' and one is defined in the scriptblock itself.
            # we should be able to use first two of them by the module-quilified name and the third one it's name.
            $fooModuleName = [scriptblock]::Create(@"
using module Foo
using module FooWithManifest

class Foo { [string] GetModuleName() { return "This" } }

class Bar1 : Foo.Foo {}
class Bar2 : FooWithManifest.Foo {}
class Bar : Foo {}

[Bar1]::new().GetModuleName() # Foo
[Bar2]::new().GetModuleName() # FooWithManifest
[Bar]::new().GetModuleName() # This
(New-Object Foo).GetModuleName() # This
"@).Invoke()

            $fooModuleName.Count | Should Be 4
            $fooModuleName[0] | Should Be 'Foo'
            $fooModuleName[1] | Should Be 'FooWithManifest'
            $fooModuleName[2] | Should Be 'This'
            $fooModuleName[3] | Should Be 'This'
        }

        It "doesn't mess up two consequitive scripts" {
            $sb1 = [scriptblock]::Create(@"
using module Foo
class Bar : Foo {}
[Bar]::new().GetModuleName() 
"@)

            $sb2 = [scriptblock]::Create(@"
using module Foo

class Foo { [string] GetModuleName() { return "This" } }
class Bar : Foo {}
[Bar]::new().GetModuleName() 

"@)
            $sb1.Invoke() | Should Be 'Foo'
            $sb2.Invoke() | Should Be 'This'
        }

        It "can use modules with classes collision simple" {
            $fooModuleName = [scriptblock]::Create(@"
using module Foo

class Foo { [string] GetModuleName() { return "This" } }

class Bar1 : Foo.Foo {}
class Bar : Foo {}

[Foo.Foo]::new().GetModuleName() # Foo
[Bar1]::new().GetModuleName() # Foo
[Bar]::new().GetModuleName() # This
[Foo]::new().GetModuleName() # This
(New-Object Foo).GetModuleName() # This
"@).Invoke()

            $fooModuleName.Count | Should Be 5
            $fooModuleName[0] | Should Be 'Foo'
            $fooModuleName[1] | Should Be 'Foo'
            $fooModuleName[2] | Should Be 'This'
            $fooModuleName[3] | Should Be 'This'
            $fooModuleName[4] | Should Be 'This'
        }

        It "can use class from another module as a base class with using module with manifest" {
            $barType = [scriptblock]::Create(@"
using module FooWithManifest
class Bar : Foo {}
[Bar]
"@).Invoke()

            $barType.BaseType.Name | Should Be 'Foo'
        }

        It "can instantiate class from another module" {
            $foo = [scriptblock]::Create(@"
using module Foo
[Foo]::new()
"@).Invoke()

            $foo.GetModuleName() | Should Be 'Foo'
        }

        It "cannot instantiate class from another module without using statement" {
            $err = Get-RuntimeError @"
#using module Foo
[Foo]::new()
"@
            $err.FullyQualifiedErrorId | Should Be TypeNotFound
        }

        It -pending "can use class from another module in New-Object by short name" {
            $foo = [scriptblock]::Create(@"
using module FooWithManifest
New-Object Foo
"@).Invoke()
            $foo.GetModuleName() | Should Be 'FooWithManifest'
        }

        It "can use class from this module in New-Object by short name" {
            $foo = [scriptblock]::Create(@"
class Foo {}
New-Object Foo
"@).Invoke()
            $foo | Should Not Be $null
        }

        # Pending reason:
        # it's not yet implemented.
        It -Pending "accept module specification" {
            $err = Get-ParseResults "using module @{ ModuleName = 'FooWithManifest'; ModuleVersion = '1.0' }"
            $err.Count | Should Be 0
        }

        It "report an error about not found module" {
            $err = Get-ParseResults "using module ThisModuleDoesntExist"
            $err.Count | Should Be 1
            $err[0].ErrorId | Should Be 'ModuleNotFoundDuringParse'
        }


        It "report an error about misformatted module specification" {
            $err = Get-ParseResults "using module @{ Foo = 'Foo' }"
            $err.Count | Should Be 1
            $err[0].ErrorId | Should Be 'InvalidValueForUsingItemName'
        }

        Context 'short name in case of name collision' {
            It "cannot use as base class" {
                $err = Get-RuntimeError @"
using module Foo
using module FooWithManifest
class Bar : Foo {}
"@
                $err.FullyQualifiedErrorId | Should Be AmbiguousTypeReference
            }

            It "cannot use as [...]" {
                $err = Get-RuntimeError @"
using module Foo
using module FooWithManifest
[Foo]
"@
                $err.FullyQualifiedErrorId | Should Be AmbiguousTypeReference
            }

            It -pending "cannot use in New-Object" {
                $err = Get-RuntimeError @"
using module Foo
using module FooWithManifest
New-Object Foo
"@
                $err.FullyQualifiedErrorId | Should Be 'AmbiguousTypeReference,Microsoft.PowerShell.Commands.NewObjectCommand'
            }

            It -pending "cannot use [type] cast from string" {
                $err = Get-RuntimeError @"
using module Foo
using module FooWithManifest
[type]"Foo"
"@
                $err.FullyQualifiedErrorId | Should Be AmbiguousTypeReference
            }
        }

        Context 'using use the latest version of module after Import-Module -Force' {
            New-TestModule -Name Foo -Content 'class Foo { [string] GetModuleName() { return "Foo2" } }'
            Import-Module Foo -Force
            It "can use class from another module as a base class with using module" {
                $moduleName = [scriptblock]::Create(@"
using module Foo
[Foo]::new().GetModuleName()
"@).Invoke()
            
                $moduleName | Should Be 'Foo2'
            }
        }

        Context 'Side by side' {
            # Add side-by-side module
            New-TestModule -Manifest -Name FooWithManifest -Content 'class Foo { [string] GetModuleName() { return "FooWithManifestAndVersion" } }' -Version 3.4.5

            It "report an error about multiple found modules" {
                $err = Get-ParseResults "using module FooWithManifest"
                $err.Count | Should Be 1
                $err[0].ErrorId | Should Be 'MultipleModuleEntriesFoundDuringParse'
            }
        }

        Context 'Use module with runtime error' {

            New-TestModule -Name ModuleWithRuntimeError -Content @'
class Foo { [string] GetModuleName() { return "ModuleWithRuntimeError" } }
throw 'error'
'@

            It "handles runtime errors in imported module" {
                $err = Get-RuntimeError @"
using module ModuleWithRuntimeError
[Foo]::new().GetModuleName()
"@

                $err | Should Be 'error'
            }
        }

        Context 'shared InitialSessionState' {
    
            It 'can pick the right module' {
                
                $scriptToProcessPath = 'TestDrive:\toProcess.ps1'
                Set-Content -Path $scriptToProcessPath -Value @'
using module Foo
function foo() 
{
    [Foo]::new()
}
'@
                # resolve name to absolute path
                $scriptToProcessPath = (ls $scriptToProcessPath).FullName
                $iss = [System.Management.Automation.Runspaces.initialsessionstate]::CreateDefault()
                $iss.StartupScripts.Add($scriptToProcessPath)

                $ps = [powershell]::Create($iss)
                $ps.AddCommand("foo").Invoke() | Should be Foo
                $ps.Streams.Error | Should Be $null

                $ps1 = [powershell]::Create($iss)
                $ps1.AddCommand("foo").Invoke() | Should be Foo
                $ps1.Streams.Error | Should Be $null

                $ps.Commands.Clear()
                $ps.Streams.Error.Clear()
                $ps.AddScript(". foo").Invoke() | Should be Foo
                $ps.Streams.Error | Should Be $null
            }
        }
       
        # this is a setup for Context "Module by path"
        New-TestModule -Name FooForPaths -Content 'class Foo { [string] GetModuleName() { return "FooForPaths" } }'


    } finally {
        $env:PSModulePath = $originalPSModulePath
    }

    # here we are back to normal $env:PSModulePath, but all modules are there
    Context "Module by path" {

        It 'use non-modified PSModulePath' {
            $env:PSModulePath | Should Be $originalPSModulePath
        }

        mkdir -Force TestDrive:\FooRelativeConsumer
        Set-Content -Path TestDrive:\FooRelativeConsumer\FooRelativeConsumer.ps1 -Value @'
using module ..\FooForPaths 
class Bar : Foo {}
[Bar]::new()
'@
        
        Set-Content -Path TestDrive:\FooRelativeConsumerErr.ps1 -Value @'
using module FooForPaths 
class Bar : Foo {}
[Bar]::new()
'@

        It "can be accessed by relative path" {
            $barObject = & TestDrive:\FooRelativeConsumer\FooRelativeConsumer.ps1          
            $barObject.GetModuleName() | Should Be 'FooForPaths' 
        }

        It "cannot be accessed by relative path without .\ from a script" {
            $err = Get-RuntimeError '& TestDrive:\FooRelativeConsumerErr.ps1'
            $err.FullyQualifiedErrorId | Should Be ModuleNotFoundDuringParse
        }

        It "can be accessed by absolute path" {
            $resolvedTestDrivePath = Split-Path ((ls TestDrive:\)[0].FullName)
            $s = @"
using module $resolvedTestDrivePath\FooForPaths
[Foo]::new()
"@
            $err = Get-ParseResults $s
            $err.Count | Should Be 0
            $barObject = [scriptblock]::Create($s).Invoke()            
            $barObject.GetModuleName() | Should Be 'FooForPaths' 
        }

        It "can be accessed by absolute path with file extension" {
            $resolvedTestDrivePath = Split-Path ((ls TestDrive:\)[0].FullName)
            $barObject = [scriptblock]::Create(@"
using module $resolvedTestDrivePath\FooForPaths\FooForPaths.psm1
[Foo]::new()
"@).Invoke()            
            $barObject.GetModuleName() | Should Be 'FooForPaths' 
        }

        It "can be accessed by relative path without file" {
            # we should not be able to access .\FooForPaths without cd
            $err = Get-RuntimeError @"
using module .\FooForPaths
[Foo]::new()
"@
            $err.FullyQualifiedErrorId | Should Be ModuleNotFoundDuringParse
            
            Push-Location TestDrive:\
            try {
                $barObject = [scriptblock]::Create(@"
using module .\FooForPaths
[Foo]::new()
"@).Invoke()            
                $barObject.GetModuleName() | Should Be 'FooForPaths' 
            } finally {
                Pop-Location
            }
        }

        It "cannot be accessed by relative path without .\" {
            Push-Location TestDrive:\
            try {
                $err = Get-RuntimeError @"
using module FooForPaths
[Foo]::new()
"@
                $err.FullyQualifiedErrorId | Should Be ModuleNotFoundDuringParse
            } finally {
                Pop-Location
            }
        }
    }
}

