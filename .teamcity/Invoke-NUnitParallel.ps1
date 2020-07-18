$Buckets = 2

if (-not (Test-Path .\output))
{
    mkdir .\output
}

& .\packages\NUnit.ConsoleRunner.3.11.1\tools\nunit3-console.exe `
    .\FrameworkApp.Tests\bin\Debug\FrameworkApp.Tests.dll --explore=.\output\allTests.xml

$testsXml = [xml] (gc .\output\allTests.xml)
$fullNames = $testsXml.SelectNodes('//test-case') | select -ExpandProperty fullname
$testCount = $fullNames.Count
$perBucket = [int] [Math]::Ceiling($testCount / $Buckets)
$bucket = 0
for ($i = 0; $i -lt $testCount; $i += $perBucket) {
    $subset = $fullNames[$i..($i + $perBucket - 1)]
 
    $subset | Out-File ".\output\Tests_$bucket.txt" -Encoding ascii

    $bucket++
}

$block = {
    param($workDir, $bucketId)

    Set-Location $workDir

    $testFile = ".\output\Tests_$bucketId.txt"
    $dbName = "BlogContext$bucketId"
    $outputDir = ".\output\$bucketId"

    & .\packages\NUnit.ConsoleRunner.3.11.1\tools\nunit3-console.exe `
        .\FrameworkApp.Tests\bin\Debug\FrameworkApp.Tests.dll `
        --testlist=$testFile --testparam:DbName=$dbName --work=$outputDir `
        --teamcity
}

$jobs = @()
$currentDir = Get-Location
for ($i = 0; $i -lt $buckets; $i++) {
    $jobs += Start-Job $block -Name "NUnit_TestJob_$i" -ArgumentList $currentDir, $i 
}

# Display progress will jobs are running
while ($jobs.State -contains "Running") {
    $jobs | Receive-Job
    Start-Sleep -Seconds 10
}

# Display final output
$jobs | Receive-Job

# Cleanup jobs
$jobs | Remove-Job