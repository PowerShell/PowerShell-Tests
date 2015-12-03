Describe "Process cmdlets" {
    
    Context "Start Process" {
        BeforeAll {
            $username = "StartProcessTest"
            $password = "pass@word1"
            $computerName = $env:COMPUTERNAME

            ## Setup test user
            Start-Process -FilePath net.exe -ArgumentList ("user $username $password /add") -NoNewWindow -Wait 

            ## Create credential for the user.
            $secureString = $password | ConvertTo-SecureString -AsPlainText -Force
            $credential = New-Object System.Management.Automation.PSCredential $username, $secureString
        }

        ## Test starts a command on powershell launched with a credential. Followup of bug Win8:545033

        It "can start process with credentials" {  

            $output = "$env:temp\output.txt"
            ## Start a process with credential 
            Start-Process powershell.exe -Credential $credential -ArgumentList ("-command whoami") -NoNewWindow -Wait -WorkingDirectory $env:SystemDrive -RedirectStandardOutput $output -LoadUserProfile
            
            ## Read the output of whoami 
            $result = Get-Content $output
            $result | Should Be "$computerName\$username"
        }

        AfterAll {            
            ## Remove test user
            Start-Process -FilePath net.exe -ArgumentList ("user $username /delete") -NoNewWindow -Wait
            Remove-Item $output -Force -ErrorAction SilentlyContinue

            $query = "select * from Win32_UserProfile where LocalPath LIKE '%$username%'"
            $userProfile = Get-CimInstance -Query $query

            if($userProfile)
            {
                ## Remove localpath
                Remove-Item -Recurse -Path ($userProfile.LocalPath) -ErrorAction SilentlyContinue -Force
            }
        }
    }
}
