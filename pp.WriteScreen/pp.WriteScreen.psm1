function Write-TimeStamp {
    param (
        [string]$format = 'yyyy-MM-dd HH:mm:ss:ff',
        [switch]$out
    )
    begin { } # End begin
    process { $result = Get-Date -Format $format } # End Process
    end {
        if ($out) { Write-Host "[$result]" -ForegroundColor Cyan -NoNewline }
        else { return $result }
    } # End end
}
function Write-Screen {
    param (
        [alias ('t')] [String[]]$Text,
        [alias ('c')] [ConsoleColor[]]$Color = [ConsoleColor]'Gray',
        [switch] $showTime,
        [switch] $noNewLine,
        [switch] $info,
        [switch] $warning,
        [switch] $err,
        [switch] $task,
        [switch] $pass,
        [switch] $fail,
        [switch] $progress,
        [switch] $tab
    )
    begin {
        if ($showTime) { Get-TimeStamp -out }
        if ($tab) { Write-Screen -Text " "          -noNewLine }
        if ($info) { Write-Screen -Text '[info]'     -noNewLine -Color Cyan }
        if ($warning) { Write-Screen -Text '[warning]'  -noNewLine -Color Yellow ; $color = [ConsoleColor]::Yellow }
        if ($err) { Write-Screen -Text '[err]'      -noNewLine -Color DarkRed; $color = [ConsoleColor]::Red }
        if ($task) { Write-Screen -Text '[task] Processing: '     -noNewLine -Color Blue }
        if ($pass) { Write-Screen -Text '[pass] '     -noNewLine -Color Green  ; $color = [ConsoleColor]::Green }
        if ($fail) { Write-Screen -Text '[fail] '     -noNewLine -Color Red    ; $color = [ConsoleColor]::Red }
        if ($progress) { Write-Screen -Text '[progress]' -noNewLine -Color White }
    }
    process {
        if ($Text.count -eq 0) {
            Write-Host
        } # End if
        else {
            foreach ($i in 0..($Text.count - 1)) {
                if ($NULL -eq $Color[$i]) {
                    $ForegroundColor = (get-host).ui.rawui.ForegroundColor
                } # End if
                else {
                    $ForegroundColor = $Color[$i]
                }

                Write-Host -Object $($Text[$i] + ' ') -ForegroundColor $ForegroundColor -NoNewLine
            } # End foreach ($i in 0..($Text.count - 1))
        } # End if else
    } # End Process
    end {
        if ($pass) { Write-Screen -Text '... Completed' -Color Green -noNewLine }
        if ($fail) { Write-Screen -Text '... Failed' -Color Red -noNewLine }
        if (!$noNewLine) { Write-Host }
    }
}

function Write-HostHelper {
    param (
        [ConsoleColor[]]$Color = [ConsoleColor]'Gray',
        [int]$numberOfItem = 1,
        [string] $writeWith = '',
        [switch] $newline,
        [switch] $tab,
        [switch] $space
    )
    begin {
        if ($writeWith.Length -eq 0) {
            if ($newline) { $writeWith = "`n" }
            if ($tab) { $writeWith = "`t" }
            if ($space) { $writeWith = ' ' }
        }
    } # End Begin
    process {
        foreach ($item in 1..$numberOfItem) {
            Write-Screen $writeWith -NoNewline -Color $Color
        }
    } # End Process
    end { } # End End
}


function Write-Line {
    param (
        [string] $WriteWith = '-',
        [ConsoleColor]$Color = [ConsoleColor]'Gray',
        [int] $numberOfitem = 0,
        [switch] $fullWidth,
        [switch] $quaterWidth
    )
    begin {
        if ( $numberOfItem -eq 0 ) {
            $uiWidth = $Host.UI.RawUI.WindowSize.Width

            $numberOfItem = $uiWidth * 0.5
            if ($fullWidth) { $numberOfItem = $uiWidth }
            if ($quaterWidth) { $numberOfItem = $uiWidth * 0.75 }
        } # End  if ( $numberOfItem -eq 0 )
    } # End begin
    process {
        Write-Screen -Text "$($WriteWith*$numberOfItem)" -Color $Color
    }
    end { }
}

function Write-Header {
    param (
        [String[]]$Text = '',
        [ConsoleColor[]]$Color = [ConsoleColor]'Gray'# Write-Line parameter
    )
    begin {
        Write-TimeStamp -out ; Write-Line -Color $Color
    }
    process {
        Write-TimeStamp -out ; Write-HostHelper -Color $Color -writeWith '----'
        Write-Screen -Text $Text -Color $Color
    }
    end {
        Write-TimeStamp -out ; Write-Line -Color $Color
    }
}

Export-ModuleMember -Function 'Write-*'