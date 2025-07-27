# First, import the function
BeforeAll {
    . $PSScriptRoot\..\Functions\FileHelper.ps1
}

Write-Host $PSScriptRoot

# Then, write the Pester tests
Describe 'Split-TextFile' {
    BeforeAll {
        # Setup: Create a test file with 5000 lines
        1..5000 | ForEach-Object { Add-Content -Path .\testFile.txt -Value "This is line $_" }
    }

    BeforeEach {
        # Reset the mock counter
        $count = 0
    }

    It 'Splits file based on size' {
        # Mock Read-Host to simulate user input
        Mock Read-Host { Write-Host "Count is $count"; if($count -eq 0) { $count++; return "s" } else { return "10" } } -Verifiable

        Split-TextFile -FilePath .\testFile.txt

        # Test if the split files are created
        Test-Path .\testFile.1.txt | Should -Be $true
        Test-Path .\testFile.2.txt | Should -Be $true
        # ... continue for expected number of files based on mock input

        # Test if the files are approximately the right size (within 10%)
        (Get-Item .\testFile.1.txt).Length | Should -BeGreaterThan 9KB
        (Get-Item .\testFile.1.txt).Length | Should -BeLessThan 11KB

        # Verify the mock was called
        Assert-MockCalled Read-Host -Times 2 -Exactly
    }

    It 'Splits file based on number of lines' {
        # Mock Read-Host to simulate user input
        Mock Read-Host { Write-Host "Count is $count"; if($count -eq 0) { $count++; return "l" } else { return "1000" } } -Verifiable

        Split-TextFile -FilePath .\testFile.txt

        # Test if the split files are created
        Test-Path .\testFile.1.txt | Should -Be $true
        Test-Path .\testFile.2.txt | Should -Be $true
        # ... continue for expected number of files based on mock input

        # Test if the files have the right number of lines
        (Get-Content .\testFile.1.txt | Measure-Object).Count | Should -Be 1000

        # Verify the mock was called
        Assert-MockCalled Read-Host -Times 2 -Exactly
    }

    AfterAll {
        # Cleanup: Remove the test files
        Remove-Item .\testFile.txt -Force
        Remove-Item .\testFile.*.txt -Force
    }
}
