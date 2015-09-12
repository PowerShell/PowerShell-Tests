$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$data = Join-Path $here "StringManipulationData\ConvertString"

Describe "Convert-String test cases" {
	
	It "Changes first and last name with one Example" {
        
        $result = "Gustavo Soares" | Convert-String -Example "camilla araujo=araujo, c."
        $result | Should be "Soares, G."
    }   

	It "Changes first and last name with one Example, and three inputs" {
        
        $result = "Lee Holmes", "Gustavo Soares", "Sumit Gulwani", "Vu Le" |
            Convert-String -Example "camilla araujo=araujo, c."
        
        $result[0] | Should be "Holmes, L."
        $result[1] | Should be "Soares, G."
		$result[2] | Should be "Gulwani, S."
		$result[3] | Should be "Le, V."
    }	
			
    It "Changes first and last name with two Examples" {
        
        $examples = [PSCustomObject] @{ Before = 'camilla araujo'; After = 'araujo, c.' },
            [PSCustomObject] @{ Before = 'lee holmes'; After = 'holmes, l.' }
        $result = "Gustavo Soares" | Convert-String -Example $examples
        
        $result | Should be "Soares, G."
    }
	
	It "Changes first and last name with one dictionary example" {
		$result = "Gustavo Soares" | Convert-String -Example @{ Before = "camilla araujo"; After = "araujo, c." }
	}
	
	It "Changes first and last name with two dictionary example" {
		$result = "Gustavo Soares" | Convert-String -Example @(@{ Before = "camilla araujo"; After = "araujo, c." },@{ Before = "vu le"; After = "le, v." })
	}

	It "Check invalid text example" {    
		{ "Gustavo Soares" | Convert-String -Example "camilla araujo" } | Should Throw
    }

	It "Check invalid psobject examples" {
        $examples = Import-Csv $data\incorrect-examples.csv
        { "Gustavo Soares" | Convert-String -Example $examples } | Should Throw        
    }	

	It "Replace by empty" {
        $examples = Import-Csv $data\replace-name-by-empty.csv
		$result = "Gustavo Soares" | Convert-String -Example $examples
        $result.length -eq 0 | Should be true        
    }	
}