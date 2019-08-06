
function Invoke-Task {
    # Parameter help description
    [Parameter(AttributeValues)]
    [ParameterType]
    $ParameterName
}

$task = @{
    aa = [scriptblock]{Initialize-AWSDefaultConfiguration `
                -Region $AWS_REGION `
                -AccessKey $awsAccessKey `
                -SecretKey $awsSecretKey}
}

function FunctionName {
    param (
        [hash]$task
    )
    $local:thisTask = $task.key
    Write-Screen -task $local:thisTask -showTime
    try {

        Write-Screen -pass $local:thisTask -showTime
    }
    catch {
        Write-Screen -fail $local:thisTask -showTime ; Write-Screen -err $error[0] -showTime
    }
}


$task

. $task.Values