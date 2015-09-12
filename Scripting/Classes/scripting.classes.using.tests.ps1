# Import-Module $PSScriptRoot\..\LanguageTestSupport.psm1
$testDir = [io.path]::GetDirectoryName($myinvocation.mycommand.path)
$SupportModule = (resolve-path "$testDir\..\LanguageTestSupport.psm1").path
import-module $SupportModule -force

Describe 'using module' {
    

    function New-TestModule {
        param(
            [string]$Name, 
            [string]$Content, 
            [switch]$Manifest, 
            [version]$Version = '1.0' # ignored, if $Manifest -eq $false
        )
        
        if ($manifest) {
            new-item -type directory -Force "TestDrive:\$Name\$Version" > $null    
            Set-Content -Path TestDrive:\$Name\$Version\$Name.psm1 -Value $Content
            New-ModuleManifest -RootModule "$Name.psm1" -Path TestDrive:\$Name\$Version\$Name.psd1 -ModuleVersion $Version
        } else {
            new-item -type directory "TestDrive:\$Name" > $null
            Set-Content -Path TestDrive:\$Name\$Name.psm1 -Value $Content
        }

        $resolvedTestDrivePath = Split-Path ((ls TestDrive:\).FullName)
        if (-not ($env:PSModulePath -like "*$resolvedTestDrivePath*")) {
            $env:PSModulePath += ";$resolvedTestDrivePath"
        }
    }

    # we need to alter class names to bypass script caching 
    function Get-RandomClassName([string]$prefix = 'Bar')
    {
        $prefix + [guid]::NewGuid().Guid.Split('-')[0]
    }

    $originalPSModulePath = $env:PSModulePath

    try {
        
        
        # Create modules in TestDrive:\
        New-TestModule -Name Foo -Content 'class Foo { [string] GetModuleName() { return "Foo" } }'
        New-TestModule -Manifest -Name FooWithManifest -Content 'class Foo { [string] GetModuleName() { return "FooWithManifest" } }'

        It "can use class from another module as a base class with using module" {
            $className = Get-RandomClassName
            $barType = [scriptblock]::Create(@"
using module Foo
class $className : Foo {}
[$className]
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
            $className = Get-RandomClassName
            $fooObject = [scriptblock]::Create(@"
using module Foo
class $className : Foo.Foo {}
[Foo.Foo]::new()
"@).Invoke()
            $fooObject.GetModuleName() | Should Be 'Foo' 
        }

        It "can use modules with classes collision" {
            $className1 = Get-RandomClassName
            $className2 = Get-RandomClassName
            # we use 3 classes with name Foo at the same time
            # two of them come from 'using module' and one is defined in the scriptblock itself.
            # we should be able to use first two of them by the module-quilified name and the third one it's name.
            $fooModuleName = [scriptblock]::Create(@"
using module Foo
using module FooWithManifest

class Foo { [string] GetModuleName() { return "This" } }

class $className1 : Foo.Foo {}
class $className2 : FooWithManifest.Foo {}
class Bar : Foo {}

[$className1]::new().GetModuleName()
[$className2]::new().GetModuleName()
[Bar]::new().GetModuleName()
(New-Object Foo).GetModuleName()
"@).Invoke()

            $fooModuleName.Count | Should Be 4
            $fooModuleName[0] | Should Be 'Foo'
            $fooModuleName[1] | Should Be 'FooWithManifest'
            $fooModuleName[2] | Should Be 'This'
            $fooModuleName[3] | Should Be 'This'
        }

        It "can use class from another module as a base class with using module with manifest" {
            $className = Get-RandomClassName
            $barType = [scriptblock]::Create(@"
using module FooWithManifest
class $className : Foo {}
[$className]
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

        It "cannot use class from the different module by the short name in case of name collision" {
            $err = Get-RuntimeError @"
using module Foo
using module FooWithManifest
class Bar : Foo {}
"@
            $err.FullyQualifiedErrorId | Should Be AmbiguousTypeReference
        }

        It "cannot use class from another module in New-Object by short name" {
            $err = Get-RuntimeError @"
using module FooWithManifest
New-Object Foo
"@
            $err.FullyQualifiedErrorId | Should Be 'TypeNotFound,Microsoft.PowerShell.Commands.NewObjectCommand'
        }

        # Pending reason:
        # it's not yet implemented.
        It -Pending "accept module specification" {
            $err = Get-ParseErrors "using module @{ ModuleName = 'FooWithManifest'; ModuleVersion = '1.0' }"
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

        # Add side-by-side module
        New-TestModule -Manifest -Name FooWithManifest -Content 'class Foo { [string] GetModuleName() { return "FooWithManifestAndVersion" } }' -Version 3.4.5

        It "report an error about multiple found modules" {
            $err = Get-ParseResults "using module FooWithManifest"
            $err.Count | Should Be 1
            $err[0].ErrorId | Should Be 'MultipleModuleEntriesFoundDuringParse'
        }


    } finally {
        $env:PSModulePath = $originalPSModulePath
    }
}
