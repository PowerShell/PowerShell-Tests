[System.Management.Automation.Internal.InternalTestHooks]::SetTestHook("IgnoreScriptBlockCache", $true)
try 
{
    . $PSScriptRoot\scripting.classes.using.tests.ps1
}
finally
{
    [System.Management.Automation.Internal.InternalTestHooks]::SetTestHook("IgnoreScriptBlockCache", $false)
}
