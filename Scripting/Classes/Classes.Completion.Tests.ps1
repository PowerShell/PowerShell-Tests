$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module $here\..\CompletionTestSupport.psm1 -force

# Convince the Pester Harness adapter that this is a pester test
if ($false) { Describe; It }

    @{
        Description = "Completion With Errors In Script - 1"  
        ExpectedResults = @(
            @{CompletionText = "ABC"; ResultType = "Property"}
            @{CompletionText = "DEF"; ResultType = "Property"}
            @{CompletionText = "Equals("; ResultType = "Method"}
            @{CompletionText = "ToString("; ResultType = "Method"})
        TestInput = @{inputScript = 'class C01 { $ABC; $DEF } [C01]::new().'}
    },
    @{
        Description = "Completion With Errors In Script - 2"
        ExpectedResults = @(
            @{CompletionText = "ABC"; ResultType = "Property"}
            @{CompletionText = "DEF"; ResultType = "Property"}
            @{CompletionText = "new("; ResultType = "Method"}
            @{CompletionText = "Equals("; ResultType = "Method"}
            @{CompletionText = "ReferenceEquals("; ResultType = "Method"})
        TestInput = @{inputScript = 'class C02 { static $ABC; static $DEF } [C02]::'}
    },
    @{
        Description = "Completion With Errors In Script - 3"
        ExpectedResults = @(
            @{CompletionText = "ABC("; ResultType = "Method"}
            @{CompletionText = "DEF("; ResultType = "Method"} )
        TestInput = @{inputScript = 'class C03 { ABC() {} DEF() {} } [C03]::new().'}
    },
    @{
        Description = "Completion With Errors In Script - 4"
        ExpectedResults = @(
            @{CompletionText = "ABC("; ResultType = "Method"}
            @{CompletionText = "DEF("; ResultType = "Method"} )
        TestInput = @{inputScript = 'class C04 { static ABC() {} static DEF() {} } [C04]::'}
    } | Get-CompletionTestCaseData | Test-Completions


    @{
        Description = "Completion Within Class C01" 
        ExpectedResults = @(
            @{CompletionText = "C01"; ResultType = "Type"})
        NotExpectedResults = @("B01")
        TestInput = @{inputScript = 'class C01 { $ABC; $DEF [C0] Foo { return $null} class B01 {$path}}';cursorColumn=26}
    },
    @{
        Description = "Completion Within Class C02" 
        ExpectedResults = @(
            @{CompletionText = "C01"; ResultType = "Type"}
            @{CompletionText = "C02"; ResultType = "Type"})
        NotExpectedResults = @("B01")
        TestInput = @{inputScript = 'class C01 { $ABC; $DEF [C01] Foo { return $null} } class C02 { [C0] Bar { return $null } class B01 {$path} }';cursorColumn=66}
    }| Get-CompletionTestCaseData | Test-Completions


    @{
        Description = "Complete From This" 
        ExpectedResults = @(
            @{CompletionText = "ABC"; ResultType = "Property"}
            @{CompletionText = "DEF"; ResultType = "Property"}
            @{CompletionText = "F("; ResultType = "Method"}
            @{CompletionText = "Equals("; ResultType = "Method"}
            @{CompletionText = "ToString("; ResultType = "Method"})
        TestInput = @{inputScript = 'class C05 { $ABC; $DEF; F() { $this.'}
   },

   
    @{
        Description = "Complete Hidden -1" 
        ExpectedResults = @(
            @{CompletionText = "ABC"; ResultType = "Property"}
            @{CompletionText = "DEF"; ResultType = "Property"}
            @{CompletionText = "GHI"; ResultType = "Property"}
            @{CompletionText = "Equals("; ResultType = "Method"}
            @{CompletionText = "ToString("; ResultType = "Method"})
        TestInput = @{inputScript = 'class C06 { $ABC; $DEF; hidden $GHI; F() { $this.'}
    },
    @{
        Description = "Complete Hidden -2" 
        ExpectedResults = @(
            @{CompletionText = "ABC"; ResultType = "Property"}
            @{CompletionText = "DEF"; ResultType = "Property"}
            @{CompletionText = "Equals("; ResultType = "Method"}
            @{CompletionText = "ToString("; ResultType = "Method"})
        NotExpectedResults = @("GHI")
        TestInput = @{inputScript = 'class C07 { $ABC; $DEF; hidden $GHI } [C07]::new().'}
    },
    @{
        Description = "Complete Hidden -3" 
        ExpectedResults = @(
            @{CompletionText = "ABC("; ResultType = "Method"}
            @{CompletionText = "DEF("; ResultType = "Method"}
            @{CompletionText = "Equals("; ResultType = "Method"}
            @{CompletionText = "ToString("; ResultType = "Method"})
        NotExpectedResults = @("GHI(")
        TestInput = @{inputScript = 'class C08 { ABC() {} DEF() {} hidden GHI() {} } [C08]::new().'}
    },
    @{
        Description = "Complete Hidden -4" 
        ExpectedResults = @(
            @{CompletionText = "AAA("; ResultType = "Method"}
            @{CompletionText = "ABC("; ResultType = "Method"})
        TestInput = @{inputScript = 'class C09 { ABC() {} hidden ABC($o) {} AAA() {} } [C09]::new().'}
    },
    @{
        Description = "Complete Hidden -5" 
        ExpectedResults = @(
            @{CompletionText = "AAA("; ResultType = "Method"}
            @{CompletionText = "ABC("; ResultType = "Method"})
        TestInput = @{inputScript = 'class C10 { ABC() {} hidden ABC($o) {} AAA() {} } [C10]::new().A'}
    },
    @{
        Description = "Complete Hidden -6" 
        ExpectedResults = @()
        NotExpectedResults = @("new(")
        TestInput = @{inputScript = 'class C11 { hidden C11() {} } [C11]::'}
    } | Get-CompletionTestCaseData | Test-Completions
    
      
    @{
        Description = "CompleteInheritance" 
        ExpectedResults = @(
            @{CompletionText = "Path"; ResultType = "Property"}
            @{CompletionText = "NewPath"; ResultType = "Property"}
            @{CompletionText = "foo("; ResultType = "Method"}
            @{CompletionText = "Equals("; ResultType = "Method"}
            @{CompletionText = "ToString("; ResultType = "Method"})
        TestInput = @{inputScript = 'class BaseFile {    $Path; [void] foo() {} } class DerivedFile : BaseFile { $NewPath; [void] foo() {} } $file = [DerivedFile]::new(); $file.'}
    } | Get-CompletionTestCaseData | Test-Completions

      
    @{
        Description = "Complete Class Attribute -1" 
        ExpectedResults = @(
            @{CompletionText = "System"; ResultType = "Namespace"} )               
        TestInput = @{inputScript = '[syste]class File { $Path; [void] foo() {}}';cursorColumn=6}
    },
    @{
        Description = "Complete Class Attribute -2" 
        ExpectedResults = @(
            @{CompletionText = "DscResource"; ResultType = "Type"} )               
        TestInput = @{inputScript = '[DSCRes]class File { $Path; [void] foo() {}}';cursorColumn=7}
    },
    @{
        Description = "Complete Class Attribute -3" 
        ExpectedResults = @(
            @{CompletionText = "System"; ResultType = "Namespace"} )               
        TestInput = @{inputScript ='[syste][DSCResour]class File {    $Path; [void] foo() {}';cursorColumn = 6}
    },
    @{
        Description = "Complete Class Attribute -4" 
        ExpectedResults = @(
            @{CompletionText = "DscResource"; ResultType = "Type"} )               
        TestInput = @{inputScript ='[syste][DSCResour]class File {    $Path; [void] foo() {}';cursorColumn = 17}
    } | Get-CompletionTestCaseData | Test-Completions
    

    @{
        Description = "Complete EnumA ttribute" 
        ExpectedResults = @(
            @{CompletionText = "System"; ResultType = "Namespace"} )               
        TestInput = @{inputScript = '[syste]Enum Color { Absent; Present}';cursorColumn=6}
    } | Get-CompletionTestCaseData | Test-Completions


    @{
        Description = "Complete Super Class -1"
        ExpectedResults = @(
            @{CompletionText = "System"; ResultType = "Namespace"} )               
        TestInput = @{inputScript = 'class File : syste {}';cursorColumn=18}
    },
    @{
        Description = "Complete Super Class -2"
        ExpectedResults = @(
            @{CompletionText = "System"; ResultType = "Namespace"} )               
        TestInput = @{inputScript = 'class File : syste {';cursorColumn=18}
    },
    @{
        Description = "Complete Super Class -3"
        ExpectedResults = @(
            @{CompletionText = "System"; ResultType = "Namespace"} )               
        TestInput = @{inputScript = 'class File : syste'}
    } | Get-CompletionTestCaseData | Test-Completions


    @{
        Description = "Complete Property Attribute -1"
        ExpectedResults = @(
            @{CompletionText = "Key"; ResultType = "Property"}
            @{CompletionText = "Mandatory"; ResultType = "Property"}
            @{CompletionText = "NotConfigurable"; ResultType = "Property"} )            
        TestInput = @{inputScript = '[DSCResource()] class Foo { [DscProperty()] [String] $path }';cursorColumn=41}
    },
    @{
        Description = "Complete Property Attribute -2"
        ExpectedResults = @(
            @{CompletionText = "Key"; ResultType = "Property"}
            @{CompletionText = "Mandatory"; ResultType = "Property"}
            @{CompletionText = "NotConfigurable"; ResultType = "Property"} )            
        TestInput = @{inputScript = '[DSCResource()] class Foo { [DscProperty()] }';cursorColumn=41}
    },
    @{
        Description = "Complete Property Attribute -3"
        ExpectedResults = @(
            @{CompletionText = "Key"; ResultType = "Property"}
            @{CompletionText = "Mandatory"; ResultType = "Property"}
            @{CompletionText = "NotConfigurable"; ResultType = "Property"} )               
        TestInput = @{inputScript = '[DSCResource()] class Foo { [DscProperty( )] [String] $path }';cursorColumn=42}
    },
    @{
        Description = "Complete Property Attribute -4"
        ExpectedResults = @(
            @{CompletionText = "Key"; ResultType = "Property"}
            @{CompletionText = "Mandatory"; ResultType = "Property"}
            @{CompletionText = "NotConfigurable"; ResultType = "Property"} )               
        TestInput = @{inputScript = '[DSCResource()] class Foo { [DscProperty( )]';cursorColumn=42}
    },
    @{
        Description = "Complete Property Attribute -5"
        ExpectedResults = @(
            @{CompletionText = "Key"; ResultType = "Property"})               
        TestInput = @{inputScript = '[DSCResource()] class Foo { [DscProperty(K)] [String] $path }';cursorColumn=42}
    },
    @{
        Description = "Complete Property Attribute -6"
        ExpectedResults = @(
            @{CompletionText = "Key"; ResultType = "Property"})               
        TestInput = @{inputScript = '[DSCResource()] class Foo { [DscProperty(K)] }';cursorColumn=42}
    },
    @{
        Description = "Complete Property Attribute -7"
        ExpectedResults = @(
            @{CompletionText = "Key"; ResultType = "Property"})               
        TestInput = @{inputScript = '[DSCResource()] class Foo { [DscProperty(K] }';cursorColumn=42}
    },
    @{
        Description = "Complete Property Attribute -8"
        ExpectedResults = @(
            @{CompletionText = "Key"; ResultType = "Property"})               
        TestInput = @{inputScript = '[DSCResource()] class Foo { [DscProperty( K)] [String] $path }';cursorColumn=43}
    },
    @{
        Description = "Complete Property Attribute -9"
        ExpectedResults = @(
            @{CompletionText = "Key"; ResultType = "Property"})               
        TestInput = @{inputScript = '[DSCResource()] class Foo { [DscProperty( K)]}';cursorColumn=43}
    },
    @{
        Description = "Complete Property Attribute -10"
        ExpectedResults = @(
            @{CompletionText = "Key"; ResultType = "Property"})               
        TestInput = @{inputScript = '[DSCResource()] class Foo { [DscProperty( K]}';cursorColumn=43}
    },
    @{
        Description = "Complete Property Attribute -11"
        ExpectedResults = @(
            @{CompletionText = "Key"; ResultType = "Property"})               
        TestInput = @{inputScript = '[DSCResource()] class Foo { [DscProperty( K]} [String] $';cursorColumn=43}
    } | Get-CompletionTestCaseData | Test-Completions
