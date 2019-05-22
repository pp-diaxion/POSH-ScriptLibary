$cc = (get-host).ui.rawui.ForegroundColor

function  Get-LeadingZero {
    param (
        [int]$int
    )
    $leadingZero = ''
    1..$int.ToString().Length | ForEach-Object { $leadingZero += '0'}
    return $leadingZero
}


function Add-LeadingZero {
    param(
        [int]$i,
        [string]$leadingZero
    )
    return $i.ToString($leadingZero)
}



function Write-HostHelper {
    param (
        [ConsoleColor[]]$Color = (get-host).ui.rawui.ForegroundColor,
        [int]$numberOfItem = 1,
        [string] $writeWith = '',
        [switch] $newline,
        [switch] $tab,
        [switch] $space
    )
    begin {
        if ($writeWith.Length -eq 0) {
            if ($newline) {$writeWith = "`n"}
            if ($tab) {$writeWith = "`t"}
            if ($space) {$writeWith = ' '}
        }
    } # End Begin
    process {
        foreach ($item in 1..$numberOfItem) {
            Write-Screen $writeWith -NoNewline -Color $Color
        }
    } # End Process
    end {} # End End
}

function Get-TimeStamp {
    param (
        [string]$format = 'yyyy-MM-dd HH:mm:ss:ff',
        [switch]$out
    )
    begin {} # End begin
    process { $result = Get-Date -Format $format  } # End Process
    end {
        if ($out) {Write-Host "[$result]" -ForegroundColor Cyan -NoNewline}
        else {return $result}
    } # End end
}

function Write-Screen {
    param (
        [alias ('t')] [String[]]$Text,
        [alias ('c')] [ConsoleColor[]]$Color = (get-host).ui.rawui.ForegroundColor,
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
        if ($showTime) {Get-TimeStamp -out}
        if ($tab) {Write-Screen -Text " "  -noNewLine}
        if ($info) {Write-Screen -Text '[info]' -Color Cyan -noNewLine}
        if ($warning) {Write-Screen -Text '[warning]' -Color Yellow -noNewLine ; $color = [ConsoleColor]::Yellow}
        if ($err) {Write-Screen -Text '[err]' -Color DarkRed -noNewLine ; $color = [ConsoleColor]::Red}
        if ($task) {Write-Screen -Text '[task]' -Color Magenta -noNewLine}
        if ($pass) {Write-Screen -Text '[pass]' -Color Green -noNewLine; $color = [ConsoleColor]::Green }
        if ($fail) {Write-Screen -Text '[fail]' -Color Red -noNewLine; $color = [ConsoleColor]::Red}
        if ($progress) {Write-Screen -Text '[progress]' -Color White -noNewLine}
    }
    process {
        if ($Text.count -eq 0) {
            Write-Host
        }
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
        }
    } # End Process
    end {
        if ($pass) {Write-Screen -Text '... Done' -Color Green -noNewLine}
        if (!$noNewLine) {Write-Host}
    }
}

function Write-Line {
    param (
        [ConsoleColor]$Color = (get-host).ui.rawui.ForegroundColor,
        [string] $WriteWith = '-',
        [int] $numberOfitem = 0,
        [switch] $fullWidth,
        [switch] $quaterWidth
    )
    begin {
        if ( $numberOfItem -eq 0 ) {
            $uiWidth = $Host.UI.RawUI.WindowSize.Width

            $numberOfItem = $uiWidth * 0.5
            if ($fullWidth) {$numberOfItem = $uiWidth}
            if ($quaterWidth) {$numberOfItem = $uiWidth * 0.75}
        } # End  if ( $numberOfItem -eq 0 )
    } # End begin
    process {
        Write-Screen -Text "$($WriteWith*$numberOfItem)" -Color $Color
    }
    end {}
}

function Write-Header {
    param (
        [String[]]$Text,
        [ConsoleColor[]]$Color = (get-host).ui.rawui.ForegroundColor # Write-Line parameter
    )
    begin {
        Get-TimeStamp -out ; Write-Line -Color $Color
    }
    process {
        Get-TimeStamp -out ; Write-HostHelper -Color $Color -writeWith '----'
        Write-Screen -Text $Text -Color $Color
    }
    end {
        Get-TimeStamp -out ; Write-Line -Color $Color
    }
}


function Split-File {
    param(
        [ValidateScript( {
                if (-Not ($_ | Test-Path) ) {
                    throw "File or folder does not exist"
                }
                if (-Not ($_ | Test-Path -PathType Leaf) ) {
                    throw "The Path argument must be a file. Folder paths are not allowed."
                }
                #if($_ -notmatch "(\.msi|\.exe)"){
                #    throw "The file specified in the path argument must be either of type msi or exe"
                #}
                return $true
            })]
        [System.IO.FileInfo]$Path,
        [int] $lines = 100000
    )
    Begin {
        Write-Header "Starting Split file [ $($path.name) ]"

        # Create split folder
        $splitFolder = $path.Directory, $path.BaseName -join '\'
        if (Test-Path $splitFolder) {
            Write-Screen -showTime -warning "Split folder exists"
            $task = "Starting clean up and re-initiate"
            Write-Screen -showTime -task $task
            $NULL = Remove-Item $splitFolder -Recurse -Force
        }
        else {
            $task = "Starting create split folder"
            Write-Screen -showTime -task $task
        }
        $NULL = New-Item -Path $splitFolder -ItemType Directory -Force
        Write-Screen -showTime -pass $task

    } # End begin
    Process {
        Write-Screen -showTime -info "Reading into file content"
        $content = Get-Content -path $path -ReadCount $lines
        Write-Screen -showTime -info 'The file will be splited into', ($content.count), 'sub files' -Color $cc, cyan, $cc

        $task = 'Starting file split..'
        Write-Screen -showTime -task $task
        $leadingZero = Get-LeadingZero ($content.count)
        $totalJobs = 0
        $content | ForEach-Object {
            $splitFilePath = $splitFolder + '/' + $path.BaseName + '_' + (Add-LeadingZero $totalJobs $leadingZero) + '_.log'

            $NULL = Start-Job -Name $splitFolder -InitializationScript {& 'C:\Users\PP\Documents\WindowsPowerShell\PSWriteColor\Public\ScriptLibary.ps1'} -ScriptBlock {
                 $content = $args[0]
                 $splitFilePath = $args[1]
                 $splitFile = New-Item -Path $splitFilePath -ItemType File -Force
                 Write-Screen -showTime -info "Working on $($splitFile.BaseName)"
                 $content | Add-Content -Path $splitFilePath -Force
                 Write-Screen -showTime -info "[$($splitFile.BaseName)] is now ready"
             } -ArgumentList @($_,$splitFilePath)
            $totalJobs++
        }

        $finishJobsCount = 0

        While ($finishJobsCount -ne $totalJobs)
        {

            $finishJobs = Get-Job -Name $splitFolder* | Where-Object State -EQ 'Completed'
            if ($finishJobs) {
                $finishJobsCount += $finishJobs.count
                $finishJobs | Receive-Job
                $finishJobs | Remove-Job
                [int]$percent = $finishJobsCount/($totalJobs)*100
                Write-Progress -activity 'Working' -percentComplete ($percent)
                Write-Screen -showTime -progress "$finishJobsCount/$totalJobs  $percent%"
                Start-Sleep -Milliseconds 1000
            }
        }
        Write-Progress -activity 'Working' -percentComplete (100)
        Write-Screen -showTime -progress "$totalJobs/$totalJobs  100%"
        Write-Screen -showTime -pass $task
    } # End Process
    End { } # End End
}

function ConvertTo-IPv4MaskString {
  param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(0, 32)]
    [Int] $MaskBits
  )
  $mask = ([Math]::Pow(2, $MaskBits) - 1) * [Math]::Pow(2, (32 - $MaskBits))
  $bytes = [BitConverter]::GetBytes([UInt32] $mask)
  (($bytes.Count - 1)..0 | ForEach-Object { [String] $bytes[$_] }) -join "."
}


Function Compare-ObjectProperties {
    Param(
        [PSObject]$ReferenceObject,
        [string]$ReferenceObjectName,
        [PSObject]$DifferenceObject,
        [string]$DifferenceObjectName
    )

    if ($ReferenceObjectName)
    {
        $RefValue = $ReferenceObjectName
    }
    else
    {
        $RefValue = 'RefValue'
    }

    if ($DifferenceObjectName)
    {
        $DiffValue = $DifferenceObjectName
    }
    else
    {
        $DiffValue = 'DiffValue'
    }


    $objprops = @()
    $ReferenceObject, $DifferenceObject | ForEach-Object {
        $objprops += $_ | Get-Member -MemberType Property, NoteProperty | ForEach-Object Name
    }
    $objprops  = $objprops | Sort-Object | Select-Object -Unique

    $diffs     = @()
    foreach ($objprop in $objprops) {
        $tempRefOjb  = $ReferenceObject.$objprop
        $tempDiffOjb = $DifferenceObject.$objprop

        if (($NULL -ne $tempRefOjb) -and ($NULL -ne $tempDiffOjb)) ## Both Empty
        {
            $diff = Compare-Object $tempRefOjb $tempDiffOjb
            if ($diff) {
                $diffprops = [ordered]@{
                    PropertyName = $objprop
                    "$RefValue"     = $diff | Where-Object SideIndicator -eq '<='| Select-Object -ExpandProperty InputObject
                    "$DiffValue"    = $diff | Where-Object SideIndicator -eq '=>'| Select-Object -ExpandProperty InputObject
                }
                $diffs += New-Object PSObject -Property $diffprops
            }
        }
        else
        {
            $diffprops = [ordered]@{
                PropertyName = $objprop
                "$RefValue"     = $tempRefOjb
                "$DiffValue"    = $tempDiffOjb
            }
            $diffs += New-Object PSObject -Property $diffprops
        }
    }
    if ($diffs) { return $diffs }
}


Function Convert-OutputForCSV {
    <#
        .SYNOPSIS
            Provides a way to expand collections in an object property prior
            to being sent to Export-Csv.

        .DESCRIPTION
            Provides a way to expand collections in an object property prior
            to being sent to Export-Csv. This helps to avoid the object type
            from being shown such as system.object[] in a spreadsheet.

        .PARAMETER InputObject
            The object that will be sent to Export-Csv

        .PARAMETER OutPropertyType
            This determines whether the property that has the collection will be
            shown in the CSV as a comma delimmited string or as a stacked string.

            Possible values:
            Stack
            Comma

            Default value is: Stack

        .NOTES
            Name: Convert-OutputForCSV
            Author: Boe Prox
            Created: 24 Jan 2014
            Version History:
                1.1 - 02 Feb 2014
                    -Removed OutputOrder parameter as it is no longer needed; inputobject order is now respected
                    in the output object
                1.0 - 24 Jan 2014
                    -Initial Creation

        .EXAMPLE
            $Output = 'PSComputername','IPAddress','DNSServerSearchOrder'

            Get-WMIObject -Class Win32_NetworkAdapterConfiguration -Filter "IPEnabled='True'" |
            Select-Object $Output | Convert-OutputForCSV |
            Export-Csv -NoTypeInformation -Path NIC.csv

            Description
            -----------
            Using a predefined set of properties to display ($Output), data is collected from the
            Win32_NetworkAdapterConfiguration class and then passed to the Convert-OutputForCSV
            funtion which expands any property with a collection so it can be read properly prior
            to being sent to Export-Csv. Properties that had a collection will be viewed as a stack
            in the spreadsheet.

    #>
    #Requires -Version 3.0
    [cmdletbinding()]
    Param (
        [parameter(ValueFromPipeline)]
        [psobject]$InputObject,
        [parameter()]
        [ValidateSet('Stack','Comma')]
        [string]$OutputPropertyType = 'Stack'
    )
    Begin {
        $PSBoundParameters.GetEnumerator() | ForEach {
            Write-Verbose "$($_)"
        }
        $FirstRun = $True
    }
    Process {
        If ($FirstRun) {
            $OutputOrder = $InputObject.psobject.properties.name
            Write-Verbose "Output Order:`n $($OutputOrder -join ', ' )"
            $FirstRun = $False
            #Get properties to process
            $Properties = Get-Member -InputObject $InputObject -MemberType *Property
            #Get properties that hold a collection
            $Properties_Collection = @(($Properties | Where-Object {
                $_.Definition -match "Collection|\[\]"
            }).Name)
            #Get properties that do not hold a collection
            $Properties_NoCollection = @(($Properties | Where-Object {
                $_.Definition -notmatch "Collection|\[\]"
            }).Name)
            Write-Verbose "Properties Found that have collections:`n $(($Properties_Collection) -join ', ')"
            Write-Verbose "Properties Found that have no collections:`n $(($Properties_NoCollection) -join ', ')"
        }

        $InputObject | ForEach {
            $Line = $_
            $stringBuilder = New-Object Text.StringBuilder
            $Null = $stringBuilder.AppendLine("[pscustomobject] @{")

            $OutputOrder | ForEach {
                If ($OutputPropertyType -eq 'Stack') {
                    $Null = $stringBuilder.AppendLine("`"$($_)`" = `"$(($line.$($_) | Out-String).Trim())`"")
                } ElseIf ($OutputPropertyType -eq "Comma") {
                    $Null = $stringBuilder.AppendLine("`"$($_)`" = `"$($line.$($_) -join ', ')`"")
                }
            }
            $Null = $stringBuilder.AppendLine("}")

            Invoke-Expression $stringBuilder.ToString()
        }
    }
    End {}
}