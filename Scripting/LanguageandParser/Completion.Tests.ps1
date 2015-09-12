$testDir = [io.path]::GetDirectoryName($myinvocation.mycommand.path)
$SupportModule = (resolve-path "$testDir\..\CompletionTestSupport.psm1").path
import-module $SupportModule -force

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
