$currentDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
# $classModulePath = Join-Path $currentDirectory "ClassHelpMod"

Describe "Class MAML help tests" {
    BeforeAll {
        ## Add the test resource to modulepath
	$origPsModulePath = $env:PSModulePath
	$env:PsModulePath += ";$currentDirectory"

        #$destinationPath = "$pshome\modules"
        #$moduleInstallPath = Join-Path $destinationPath $classModulePath 
        #Copy-Item -Recurse -Path $classModulePath $destinationPath -Force -ErrorAction SilentlyContinue

        $classHelp = Get-Help "ClassHelpClass"
        $classHelpWithWildCard = Get-Help "ClassHelpClas*"
        $classHelpWithCategory = Get-Help -category Class
    }

    AfterAll {
        ## Remove the test resource from modulepath
        # Remove-Item (Join-Path $destinationPath "FakeDscResource") -Force -Recurse -ErrorAction SilentlyContinue
	$env:PsModulePath = $origPsModulePath
    }
    
    It "is found" {
         $classHelp -ne $null | Should Be $true
    }

    It "is found with wildcard name" {
        $classHelpWithWildCard -ne $null | Should Be $true
    }

    It "is found with category Class" {
        $helpContent = $classHelpWithCategory | ? Name -eq 'ClassHelpClass' 
        $helpContent -ne $null | Should Be $true
    }
    
    It "has fields" {
        $classHelp.members.member | Should Not Be $null
    }

    It "has methods" {
        $foundMethod = $false
        $methodCount = 0

        foreach($member in $classHelp.members.member)
        {
            if($member.type -eq "method")
            {
                $foundMethod = $true
                $methodCount++
            } 
        }
        
        $foundMethod | Should Be $true
        $methodCount | Should Be 2
    }


    It "has a name" {
        $classHelp.name | Should Be "ClassHelpClass"        
    }

    It "has examples" {
        $classHelp.examples.example.code.length | Should Be 78
    }

    It "has related links" {
        $classHelp.relatedlinks.navigationLink.linkText | Should Be 'Online version:'
        $classHelp.relatedlinks.navigationLink.uri | Should Be 'http://go.microsoft.com/fwlink/?LinkID=138337'
    }
}

