# Tests related to Bug 2817913 Start-Process -Wait sometimes doesn't wait
# It seems when passing SafeHandle of the process to AssignProcessToJobObject, the handle gets corrupted sometimes.
# The fix is to revert back to use raw handle (IntPtr) of the process for both FullCLR and CoreCLR.

Describe "Tests for Start-Process -Wait -PassThru" -Tags "Innerloop", "BVT" {
    
    It "Process object returned from Start-Process -Wait -PassThru should have ExitCode to be 0" {
         $iterations = 5
         $errorCount = 0
         while ($iterations -gt 0)
         {
            $p = Start-Process cmd.exe -WindowStyle Hidden -ArgumentList "/C echo 1" -PassThru -Wait
            If ($p.ExitCode -eq $null -or $p.ExitCode -ne 0) {
                $errorCount ++
            }
            $iterations --
         }
         $errorCount | Should Be 0
    }
}