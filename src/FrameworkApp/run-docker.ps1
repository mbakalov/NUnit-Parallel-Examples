# Setup Linux SQL Server to run tests against
$saPassword = "h4rdc0dedThr0wAw4yPwd!"
& docker pull mcr.microsoft.com/mssql/server
& docker run --name tcdemo-sql-001 -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=$saPassword" -p 1434:1433 -d mcr.microsoft.com/mssql/server

Start-Sleep -Seconds 10 # Let the SQL Server start...

& docker exec -it tcdemo-sql-001 /opt/mssql-tools/bin/sqlcmd `
    -S localhost -U sa -P "$saPassword" `
    -Q "CREATE LOGIN [testuser] WITH PASSWORD=N'testpassword', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF"
& docker exec -it tcdemo-sql-001 /opt/mssql-tools/bin/sqlcmd `
    -S localhost -U sa -P "$saPassword" `
    -Q "ALTER SERVER ROLE [sysadmin] ADD MEMBER [testuser]"

if (-not (Test-Path .\output))
{
    mkdir .\output
}
    
& msbuild .\FrameworkApp.sln /t:Build /p:FixtureCount=4 /p:TestsPerFixtureCount=2

& .\packages\NUnit.ConsoleRunner.3.11.1\tools\nunit3-console.exe `
    .\FrameworkApp.Tests\bin\Debug\FrameworkApp.Tests.dll --work=.\output