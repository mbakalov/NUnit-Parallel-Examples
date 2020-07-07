$buckets = 4

if (-not (Test-Path .\output))
{
    mkdir .\output
}

& msbuild .\FrameworkApp.sln /t:Build /p:FixtureCount=4 /p:TestsPerFixtureCount=2

$singleProcess = Measure-Command {
    & .\packages\NUnit.ConsoleRunner.3.11.1\tools\nunit3-console.exe `
    .\FrameworkApp.Tests\bin\Debug\FrameworkApp.Tests.dll --work=.\output | Out-Host
}

& .\packages\NUnit.ConsoleRunner.3.11.1\tools\nunit3-console.exe `
    .\FrameworkApp.Tests\bin\Debug\FrameworkApp.Tests.dll --explore=.\output\allTests.xml

$testsXml = [xml] (gc .\output\allTests.xml)
$fullNames = $testsXml.SelectNodes('//test-case') | select -ExpandProperty fullname
$testCount = $fullNames.Count
$perBucket = [int] [Math]::Ceiling($testCount / $buckets)
$bucket = 0
for ($i = 0; $i -lt $testCount; $i += $perBucket) {
    $subset = $fullNames[$i..($i + $perBucket - 1)]
 
    $subset | Out-File ".\output\Tests_$bucket.txt" -Encoding ascii

    $bucket++
}

$block = {
    param($workDir, $testFile, $dbName)

    Set-Location $workDir

    & .\packages\NUnit.ConsoleRunner.3.11.1\tools\nunit3-console.exe `
    .\FrameworkApp.Tests\bin\Debug\FrameworkApp.Tests.dll `
    --testlist=$testFile --testparam:DbName=$dbName --work=.\output
}

$currentDir = Get-Location
for ($i = 0; $i -lt $buckets; $i++) {
    $bucketFile = ".\output\Tests_$i.txt"
    $dbName = "BlogContext$i"

    Start-Job $block -ArgumentList $currentDir, $bucketFile, $dbName | Out-Null
}

$multiProcess = Measure-Command {
    Get-Job | Wait-Job | Out-Null
}

Get-Job | Receive-Job

Remove-Job *

Write-Host "Single Process"
$singleProcess

Write-Host "Multi-Process"
$multiProcess