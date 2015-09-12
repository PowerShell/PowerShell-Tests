Describe "DelimitedText" {

    It "verifies automatic property generation" {
            
        $result = "Hello 9", "Hello 10", "Hello 90" | ConvertFrom-String
        
        ## Verify first properties got extracted
        $result[0].P1 | Should be 'Hello'
        $result[1].P1 | Should be 'Hello'
        $result[2].P1 | Should be 'Hello'
        
        ## Verify second properties got extracted
        $result[0].P2 | Should be 9
        $result[1].P2 | Should be 10
        $result[2].P2 | Should be 90
	}

    It "verifies property overflow generation" {
            
        $result = "Hello 9" | ConvertFrom-String -PropertyNames A
        
        $result.A | Should be 'Hello'
        $result.P2 | Should be 9
	}

    It "verifies property renaming" {
            
        $result = "Hello 9" | ConvertFrom-String -PN B,C
        
        $result.B | Should be 'Hello'
        $result.C | Should be '9'
	}

    It "verifies property typing of numbers" {
            
        $result = "Hello 9" | ConvertFrom-String -Property B,C
        $result.C.GetType().FullName | Should be 'System.Byte'
	}
    
    It "verifies property typing of TimeSpan" {
            
        $result = "Hello 1:00" | ConvertFrom-String -Property B,C
        $result.C.GetType().FullName | Should be 'System.TimeSpan'
	}

    It "verifies property typing of DateTime" {
            
        $result = "Hello 1/1/2012" | ConvertFrom-String -Property B,C
        $result.C.GetType().FullName | Should be 'System.DateTime'
	}

    It "verifies property typing of Char" {
            
        $result = "Hello A" | ConvertFrom-String -Property B,C
        $result.C.GetType().FullName | Should be 'System.Char'
	}
    
    It "verifies empty strings don't turn into INTs" {
            
        $result = "Hello" | ConvertFrom-String -Delimiter 'l'
        $result.P2.GetType().FullName | Should be 'System.String'
	}   

    It "verifies property typing of String" {
            
        $result = "Hello World" | ConvertFrom-String -Property B,C
        $result.C.GetType().FullName | Should be 'System.String'
	}
    
    It "verifies the ability to change the delimiter" {
            
        $result = "Hello-World" | ConvertFrom-String -Delimiter '-'
        $result.P1 | Should be 'Hello'
        $result.P2 | Should be 'World'
	}
    
    It "verifies that only matching text gets parsed" {
            
        $result = "Foo1","Hello1 World1","Hello-World" | ConvertFrom-String -Delimiter '-'
        $result.P1 | Should be 'Hello'
        $result.P2 | Should be 'World'
        @($result).Count | Should be 1
	}
    
    It "verifies that a good error message is returned from an invalid regular expression" {
            
        try
        {
            $result = "Hello World" | ConvertFrom-String -Delimiter '['
        }
        catch
        {
            $errorRecord = $_
        }
        
        $errorRecord.FullyQualifiedErrorId | Should be "InvalidRegularExpression,Microsoft.PowerShell.Commands.StringManipulation.ConvertFromStringCommand"
	}   
}