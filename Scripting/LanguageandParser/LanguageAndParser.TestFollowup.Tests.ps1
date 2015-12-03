
Describe "Clone array" {
    It "Cast in target expr" {
        (([int[]](42)).clone()) | Should Be 42
        (([int[]](1..5)).clone()).Length | Should Be 5
        (([int[]](1..5)).clone()).GetType() | Should Be ([int[]])

    }
    It "Cast not in target expr" {
        $e = [int[]](42)
        $e.Clone() | Should Be 42
        $e = [int[]](1..5)
        $e.Clone().Length | Should Be 5
        $e.Clone().GetType() | Should Be ([int[]])
    }
}

Describe "Set fields through PSMemberInfo" {
    Add-Type @"
    public struct AStruct { public string s; }
"@

    It "via cast" {
        ([AStruct]@{s = "abc" }).s | Should Be "abc"
    }
    It "via new-object" {
        (new-object AStruct -prop @{s="abc"}).s | Should Be "abc"
    }
    It "via PSObject" {
        $x = [AStruct]::new()
        $x.psobject.properties['s'].Value = 'abc'
        $x.s | Should Be "abc"
    }
}

Describe "MSFT:3309783" {
    # For a reliable test, we must run this in a new process because an earlier binding in this process
    # could mask the bug/fix.
    powershell -noprofile -command "[psobject] | % FullName" | Should Be System.Management.Automation.PSObject

    # For good measure, do the same thing in this process
    [psobject] | % FullName | Should Be System.Management.Automation.PSObject

    # Related - make sure we can still pipe objects derived from PSObject
    class MyPsObj : PSObject
    {
        MyPsObj($obj) : base($obj) { }
        [string] ToString() {
            # Don't change access via .psobject, that was also a bug.
            return "MyObj: " + $this.psobject.BaseObject
        }
    }

    [MyPsObj]::new("abc").psobject.ToString() | Should Be "MyObj: abc"
    [MyPsObj]::new("def") | Out-String | % Trim | Should Be "MyObj: def"
}
