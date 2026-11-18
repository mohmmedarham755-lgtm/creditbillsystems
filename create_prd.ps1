$log = "C:\\Recovery folder\\New Volume\\credit bill system\\creditbillsytems\\agy_logs"
$crash = "C:\\Recovery folder\\New Volume\\credit bill system\\creditbillsytems\\agy_crashes"
$inst = "C:\\Recovery folder\\New Volume\\credit bill system\\creditbillsytems\\agy_inst_id"

mkdir $log -Force
mkdir $crash -Force
New-Item -Path $inst -ItemType File -Force | Out-Null

$env:AGY_LOG_DIR = $log
$env:AGY_CRASH_DIR = $crash
$env:AGY_INSTALLATION_ID = $inst

'Create','ARHAM','English' | agy -p bmad-prd
