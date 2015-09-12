Describe "Object cmdlets" -Tags 'innerloop' {
    Context "Group-Object" {
        It "AsHashtable returns a hashtable" {
            $result = Get-Process | Group-Object -Property ProcessName -AsHashTable
            $result["powershell"].Count | Should BeGreaterThan 0
        }        

        It "AsString returns a string" {
           $processes = Get-Process | Group-Object -Property ProcessName -AsHashTable -AsString
           $result = $processes.Keys | ForEach-Object {$_.GetType()}
           $result[0].Name | Should Be "String" 
        } 
    }

    Context "Tee-Object" {
        It "with literal path" {
            $path = "TestDrive:\[TeeObjectLiteralPathShouldWorkForSpecialFilename].txt"
            Write-Output "Test" | Tee-Object -LiteralPath $path | Tee-Object -Variable TeeObjectLiteralPathShouldWorkForSpecialFilename
            $TeeObjectLiteralPathShouldWorkForSpecialFilename | Should Be (Get-Content -LiteralPath $path)
        }
    }
}