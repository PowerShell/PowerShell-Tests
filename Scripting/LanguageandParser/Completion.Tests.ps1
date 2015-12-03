$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module $here\..\CompletionTestSupport.psm1 -force

# Convince the Pester Harness adapter that this is a pester test
if ($false) { Describe; It }

@{
    Description = "Completion doesn't cause stack overflow"
    ExpectedResults = @(
                @{CompletionText = "BaseObject"; ResultType = "Property"}
                @{CompletionText = "Members"; ResultType = "Property"}
                @{CompletionText = "GetMetaObject("; ResultType = "Method"}
                @{CompletionText = "Equals("; ResultType = "Method"}
                @{CompletionText = "ToString("; ResultType = "Method"})
    TestInput = @{inputScript = @'
$dums = @()
$dum = new-object PSObject
$dum | add-member noteproperty Blah "blah"
$dums += $dum
foreach($dum in $dums) {
    $dum.<#CURSOR#>
}
'@ }
} | Get-CompletionTestCaseData | Test-Completions
