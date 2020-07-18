param($Buckets = 4, [switch] $UseWindowsContainer)

$saPassword = "h4rdc0dedThr0wAw4yPwd!"

if ($UseWindowsContainer) {
    $image = "microsoft/mssql-server-windows-developer"
    $sqlcmd = "sqlcmd"
} else {
    $image = "mcr.microsoft.com/mssql/server"
    $sqlcmd = "/opt/mssql-tools/bin/sqlcmd"
}

& docker pull $image
& docker run --name tcdemo-sql-001 -e "ACCEPT_EULA=Y" -e "sa_password=$saPassword" -p 1444:1433 -d $image

for ($i = 0; $i -lt 20; $i++) {
    & docker exec tcdemo-sql-001 $sqlcmd `
        -S localhost -U sa -P "$saPassword" `
        -Q "CREATE LOGIN [testuser] WITH PASSWORD=N'testpassword', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF"

    if ($LASTEXITCODE -eq 0) {
        Write-Host "testuser created"
        break
    } else {
        Write-Host "Failed to create testuser, probably SQL Server hasn't started yet. Will retry in 15 seconds. Attempt $i/20"
        Start-Sleep -Seconds 15
    }
}

& docker exec tcdemo-sql-001 $sqlcmd `
    -S localhost -U sa -P "$saPassword" `
    -Q "ALTER SERVER ROLE [sysadmin] ADD MEMBER [testuser]"

if (-not (Test-Path .\output))
{
    mkdir .\output
}
    
& msbuild .\FrameworkApp.sln /t:Build /p:FixtureCount=10 /p:TestsPerFixtureCount=10

# Single process
# & .\packages\NUnit.ConsoleRunner.3.11.1\tools\nunit3-console.exe `
#     .\FrameworkApp.Tests\bin\Debug\FrameworkApp.Tests.dll --work=.\output

# Multi-process
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