Describe "Get-Counter" -Tags "innerloop" {    
    It "should run for 5 iterations in continuous mode" {        
        $result = [Powershell]::Create().AddScript('$a = 0; get-counter -Continuous | %{ $a++; if ($a -eq 5) {$a; break}}').Invoke()                
        $result | Should Be 5
    }

    It "returns expected max count" {
        (get-counter -MaxSamples 5).Count | Should Be 5
    }
}