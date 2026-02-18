### Requires Task string variable in component in DRMM

function Write-DRMMAlert ($message) {
    write-host '<-Start Result->'
    write-host "Alert=$message"
    write-host '<-End Result->'
}

function Write-DRMMStatus ($message) {
    write-host '<-Start Result->'
    write-host "STATUS=$message"
    write-host '<-End Result->'
}

#String variable required in DRMM called Task to allow for invidual or filtered scheduled task lookup
$RequiredTask = $ENV:Task

#Task Info list
[array]$Error_List=@("0:The operation completed successfully."
"1: Incorrect function called or unknown function called."
"2: File not found."
"10: The environment is incorrect."
"267008:Task is ready to run at its next scheduled time."
"267009:Task is currently running."
"267010:Task is disabled."
"267011:Task has not yet run."
"267012:There are no more runs scheduled for this task."
"267014:Task is terminated."
"-2147216609: An instance of this task is already running."
"-2147023651: The service is not available (is 'Run only when a user is logged on' checked?)."
"-1073741510:The application terminated as a result of a CTRL+C."
"-1066598274:Unknown software exception."
"267008: The task is ready to run at its next * Scheduled time."
"267009: The task is currently running."
"267010: The task will not run at the * Scheduled times because it has been disabled."
"267011: The task has not yet run."
"267012: There are no more runs * Scheduled for this task."
"267013: One or more of the properties that are needed to run this task on a * Schedule have not been set."
"267014: The last run of the task was terminated by the user."
"267015: Either the task has no triggers or the existing triggers are disabled or not set."
"267016: Event triggers do not have set run times."
"-2147216631: A tasks trigger is not found."
"-2147216630: One or more of the properties required to run this task have not been set."
"-2147216629: There is no running instance of the task."
"-2147216628: The Task * Scheduler service is not installed on this computer."
"-2147216627: The task object could not be opened."
"-2147216626: The object is either an invalid task object or is not a task object."
"-2147216625: No account information could be found in the Task * Scheduler security database for the task indicated."
"-2147216624:Unable to establish existence of the account specified."
"-2147216623: Corruption was detected in the Task * Scheduler security database."
"-2147216622: Task * Scheduler security services are available only on Windows NT."
"-2147216621: The task object version is either unsupported or invalid."
"-2147216620: The task has been configured with an unsupported combination of account settings and run time options."
"-2147216619: The Task * Scheduler Service is not running."
"-2147216618: The task XML contains an unexpected node."
"-2147216617: The task XML contains an element or attribute from an unexpected namespace."
"-2147216616: The task XML contains a value which is incorrectly formatted or out of range."
"-2147216615: The task XML is missing a required element or attribute."
"-2147216614: The task XML is malformed."
"267035: The task is registered, but not all specified triggers will start the task."
"267036: The task is registered, but may fail to start.' Batch logon privilege needs to be enabled for the task principal."
"-2147216611: The task XML contains too many nodes of the same type."
"-2147216610: The task cannot be started after the trigger end boundary."
"-2147216609: An instance of this task is already running."
"-2147216608: The task will not run because the user is not logged on."
"-2147216607: The task image is corrupt or has been tampered with."
"-2147216606: The Task * Scheduler service is not available."
"-2147216605: The Task * Scheduler service is too busy to handle your request.' Please try again later."
"-2147216604: The Task * Scheduler service attempted to run the task, but the task did not run due to one of the constraints in the task definition."
"267045: The Task * Scheduler service has asked the task to run."
"-2147216602: The task is disabled."
"-2147216601: The task has properties that are not compatible with earlier versions of Windows."
"-2147216600: The task settings do not allow the task to start on demand."
)

function Get-TaskStatus ([string]$Status) {
    $Return="Return Code is $Status"
    Foreach($E in $Error_List){
        if($E.ToString().Contains($Status)) {
            $Return=($E.split(":")[1])
            return $Return;break
        }
    }
    return $Return
}

if ($RequiredTask) {
    $query = 'SELECT * FROM MSFT_ScheduledTask WHERE TaskName LIKE "%'+$RequiredTask+'%"'
} else {
    $query = 'SELECT * FROM MSFT_ScheduledTask'
}
$Tasks = Get-WmiObject -Query $query -Namespace Root/Microsoft/Windows/TaskScheduler

ForEach($Task in $Tasks) {
    If($Task.TaskPath.Length -eq 1){
        $TaskName = $Task.TaskName
        $TaskOutput = Invoke-WmiMethod -Class PS_ScheduledTask -Namespace ROOT\Microsoft\Windows\TaskScheduler -Name GetInfoByName -ArgumentList $TaskName | Select-Object -expand cmdletOutput | Select-Object TaskName,LastTaskResult
        If($TaskOutput){
            $TaskName = $TaskOutput.TaskName
            $TaskResult = Get-TaskStatus($TaskOutput.LastTaskResult)
            if ($TaskOutput.LastTaskResult -ne 0) {
                Write-Host "Failure found"
                $Failure = $true
            }
            $Results += "$TaskName - $TaskResult`r`n"
        }
    }
}

If($Failure) {
    Write-DRMMAlert $Results
    Exit 1
}

Write-DRMMStatus $Results