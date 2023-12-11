## Part 1 :


$root_path = "C:\Users\ext_Maxen\"

$env:Path += ";C:\Users\ext_Maxen\Desktop\Data_Ingestion\AWSCLIV2"
$path = "C:\Program Files\PostgreSQL\"
$pg_version = (Get-ChildItem -Path $path | Where-Object { $_.PSIsContainer }).Name
$new_path = $path + $pg_version


try {
    $null = Get-Module -Name AWSPowerShell -ListAvailable -ErrorAction Stop
    Write-Host "AWSPowerShell module is already installed "
}
catch {
    Write-Host "AWSPowerShell module is not installed. Installing now..."
    Install-Module -Name AWSPowerShell -Force -AllowClobber -Scope CurrentUser
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
}

# aws cli :

function Test-AWSCLIInstalled {
    try {
        $null = aws --version
        return $true
    }
    catch {
        return $false
    }
}

if (-not (Test-AWSCLIInstalled)) {
    Write-Host "AWS CLI is not installed. Installing now..."
   
    $aws_cli_installer = "$env:TEMP\AWSCLIV2.msi"
    Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile $aws_cli_installer
    Start-Process -Wait -FilePath $aws_cli_installer
    Write-Host "AWS CLI has been installed. Restarting PowerShell..."


    exit
}

Write-Host "AWS CLI is installed. Continuing with the rest of the script..."

Import-Module AWSPowerShell


## Part 2 :


$path = "C:\Program Files\PostgreSQL\"
$pg_version = (Get-ChildItem -Path $path | Where-Object { $_.PSIsContainer }).Name
$new_path = $path + $pg_version

$aws_file_path = $root_path + "Desktop\Data_Ingestion\credentials.txt"

$aws_secret_key = Get-Content -Path $aws_file_path | Out-String

$aws_access_key_id = "AKIA2NKKH45E4VHGUFHG"
$outputFormat = "json"

$aws_region = "us-east-1"
Set-DefaultAWSRegion -Region $aws_region
Set-AWSCredential -AccessKey $aws_access_key_id -SecretKey $aws_secret_key

aws configure set aws_access_key_id $aws_access_key_id
aws configure set aws_secret_access_key $aws_secret_key
aws configure set default.region $aws_region
aws configure set default.output $outputFormat


$psql_path = $new_path+"\bin\psql.exe"

$host_name = "localhost"
$databaseName = "maxen_trend_export"
$superuser = "postgres"
$port = "5433"
$password = "626navada626"

$extract_date_file = $root_path + "Desktop\Data_Ingestion\date_extract.txt"

if (-not (Test-Path $extract_date_file)) {
    $defaultStartDate = '"1900-01-01 10:00:00"'
    $defaultStartDate | Set-Content -Path $extract_date_file
    Write-Host "Date file created with default start date: $defaultStartDate"
}

$last_extract_date = Get-Content -Path $extract_date_file
$last_extract_date_for_SQL = $last_extract_date -replace ' ', 'T'

$env:PGPASSWORD = $password
$sqlQuery = "SELECT * FROM trenddata WHERE date_stamp_ >  '$last_extract_date_for_SQL'"
$sqlQuery_date = "SELECT date_stamp_ FROM trenddata WHERE date_stamp_ > '$last_extract_date_for_SQL' order by date_stamp_ desc LIMIT 1"

$result = & $psql_path -h $host_name -p $port -U $superuser -d $databaseName -c "$sqlQuery"
$result_date = & $psql_path -h $host_name -p $port -U $superuser -d $databaseName -c "$sqlQuery_date" -t -A
$env:PGPASSWORD = $null

$datePart = ($result_date | ForEach-Object { ($_ -split ' ')[0] })

$desktop_path = [System.IO.Path]::Combine($env:USERPROFILE, "Desktop\Data_Ingestion")
$csv_file_path = [System.IO.Path]::Combine($desktop_path, "${datePart}_data.csv")

$result_date | Set-Content -Path $extract_date_file
$result | Out-File -FilePath $csv_file_path -Encoding UTF8

#$result | Export-Csv -Path $csv_file_path -NoTypeInformation
#$result | ConvertFrom-Csv -Delimiter '|' | Export-Csv -Path $csv_file_path -NoTypeInformation -Append

aws s3 cp $csv_file_path s3://maxen-glue-bucket-output/Navada/Input/

#schtasks /create /tn "ScriptTask" /tr "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe ~/Desktop/shell_script.ps1" /sc once /st 15:12