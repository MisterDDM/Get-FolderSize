Function Get-FolderSize
{
    [cmdletbinding()]
    param
    (
        [parameter( Mandatory = $false,
                    ParameterSetName = 'RemoteProfile',
                    Position = 0 )]        
        [switch]$RemoteProfile,

        [parameter( Mandatory = $false,
                    ParameterSetName = 'Path',
                    Position = 0,
                    ValueFromPipeline = $true,
                    ValueFromPipelineByPropertyName = $true )]
        [string[]]$Path,
        
        [parameter( Mandatory = $false,
                    Position = 1 )]
        [switch]$Export
    )

    Begin
    {
        if ( $PSBoundParameters['RemoteProfile'] )
        {
            $Desktop = 'Desktop',[System.Environment]::GetFolderPath('Desktop')
            $Documents = 'Documents', [System.Environment]::GetFolderPath('MyDocuments')
            $AppData = 'AppData', [System.Environment]::GetFolderPath('ApplicationData')
            $LocalData = 'LocalData', 'C:\LocalData'

            $FolderPath = $Desktop,$Documents,$AppData,$LocalData
        }
        if ( $PSBoundParameters['Path'] )
        {
            $FolderPath = $Path
        }

        $LogPath = "$((Get-IDLogPath -RemoteProfile).FullName)\$env:USERNAME.csv"
        [array]$Object = $null

    }

    Process
    {
        if ( $PSBoundParameters['RemoteProfile']  )
        {
            Write-IDEvent "Get-FolderSize - Collecting folder size information from the remote profile of $env:USERNAME"
            for ( $i = 0; $i -lt $FolderPath.Count; $i++ )
            {
                $Folder = $FolderPath[$i][0]
                $FullName = $FolderPath[$i][1]

                #$Size = "{0:N2}" -f ((Get-ChildItem $FullName -Recurse | Measure-Object -Property Length -Sum).Sum / 1mb) 
                $Size = [system.math]::Round((((robocopy.exe $FullName \LocalHostC$null /L /XJ /R:0 /W:1 /NP /E /BYTES /NFL /NDL /NJH /MT:64)[-4] -replace '\D+(\d+).*','$1') /1MB),2)

                $Object += [PSCustomObject]@{
                    Date = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
                    Folder = $Folder
                    'Size(MB)' = $Size
                    Path = $FullName
                }
            }

            if ( $PSBoundParameters['Export'] )
            {
                $Object | Export-Csv -Path "${LogPath}" -Encoding Default -Force -Delimiter ';' -NoTypeInformation
                Write-IDEvent "Get-FolderSize - Information exported"
            }
            else
            {
                return $Object
            }
        }
        if ( $PSBoundParameters['Path'] )
        {
            $FolderPath | ForEach-Object {  
        
                #"{0:N2}" -f ((Get-ChildItem $_ -Recurse | Measure-Object -Property Length -Sum).Sum / 1mb) 
                [system.math]::Round((((robocopy.exe $_ \LocalHostC$null /L /XJ /R:0 /W:1 /NP /E /BYTES /NFL /NDL /NJH /MT:64)[-4] -replace '\D+(\d+).*','$1') /1MB),2)
            }
        }
    }
    End
    {}
}
