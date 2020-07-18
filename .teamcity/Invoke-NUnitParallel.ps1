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

# Want to use PID of each individual nunit3-console.exe process to correctly assign
# "flowId" for TeamCity service messages, see https://github.com/nunit/teamcity-event-listener/issues/66
# The PID works only if the "TEAMCITY_PROCESS_FLOW_ID" env variable is not set.
# Not sure why it is getting set in my TeamCity instance, but removing it in the script
# explicitly to get the "PID" behavior
Remove-Item $env:TEAMCITY_PROCESS_FLOW_ID

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