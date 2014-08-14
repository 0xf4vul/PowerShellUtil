﻿function Copy-ItemEX
{
    param
    (
        [parameter(
            Mandatory = 1,
            Position  = 0,
            ValueFromPipeline = 1,
            ValueFromPipelineByPropertyName =1)]
        [string]
        $Path,

        [parameter(
            Mandatory = 1,
            Position  = 1,
            ValueFromPipelineByPropertyName =1)]
        [string]
        $Destination,

        [parameter(
            Mandatory = 0,
            Position  = 2,
            ValueFromPipelineByPropertyName =1)]
        [string[]]
        $Targets,

        [parameter(
            Mandatory = 0,
            Position  = 3,
            ValueFromPipelineByPropertyName =1)]
        [string[]]
        $Excludes,

        [parameter(
            Mandatory = 0,
            Position  = 4,
            ValueFromPipelineByPropertyName =1)]
        [Switch]
        $Recurse,

        [parameter(
            Mandatory = 0,
            Position  = 5)]
        [switch]
        $Force
    )

    process
    {
        # Get Filtered Path (if none filter)
        $filterPath = GetTargetsFiles -Path $Path -Targets $Targets -Recurse:$isRecurse -Force:$Force
        $excludePath = GetExcludeFiles -Path $filterPath -Excludes $Excludes
        CopyItemEX  -Path $excludePath -RootPath $Path -Destination $Destination -Force:$isForce
    }

    begin
    {
        $isRecurse = $PSBoundParameters.ContainsKey('Recurse')
        $isForce = $PSBoundParameters.ContainsKey('Force')

        function GetTargetsFiles
        {
            [CmdletBinding()]
            param
            (
                [string]
                $Path,

                [string[]]
                $Targets,

                [bool]
                $Recurse,

                [bool]
                $Force
            )

            # fullName, DirectoryName, Name
            $list = New-Object 'System.Collections.Generic.List[Tuple[string,string,string]]'
            $base = Get-ChildItem $Path -Recurse:$Recurse -Force:$Force

            if (($Targets | measure).count -ne 0)
            {
                foreach($target in $Targets)
                {
                    $base `
                    | where Name -like $target `
                    | %{
                        if ($_ -is [System.IO.FileInfo])
                        {
                            $tuple = New-Object "System.Tuple[[string], [string], [string]]" ($_.FullName, $_.DirectoryName, $_.Name)
                        }
                        elseif ($_ -is [System.IO.DirectoryInfo])
                        {
                            $tuple = New-Object "System.Tuple[[string], [string], [string]]" ($_.FullName, $_.PSParentPath, $_.Name)
                        }
                        else
                        {
                            throw "Type '{0}' not imprement Exception!!" -f $_.GetType().FullName
                        }
                        $list.Add($tuple)
                    }
                }
            }
            else
            {
                $base `
                | %{
                    if ($_ -is [System.IO.FileInfo])
                    {
                        $tuple = New-Object "System.Tuple[[string], [string], [string]]" ($_.FullName, $_.DirectoryName, $_.Name)
                    }
                    elseif ($_ -is [System.IO.DirectoryInfo])
                    {
                        $tuple = New-Object "System.Tuple[[string], [string], [string]]" ($_.FullName, $_.PSParentPath, $_.Name)
                    }
                    else
                    {
                        throw "Type '{0}' not imprement Exception!!" -f $_.GetType().FullName
                    }
                    $list.Add($tuple)
                }
            }
            
            return $list
        }

        function GetExcludeFiles
        {
            param
            (
                [System.Collections.Generic.List[Tuple[string,string,string]]]
                $Path,

                [string[]]
                $Excludes
            )

            if (($Excludes | measure).count -ne 0)
            {
                Foreach ($exclude in $Excludes)
                {
                    # name not like $exclude
                    $Path | where Item3 -notlike $exclude
                }
            }
            else
            {
                $Path
            }

        }

        function CopyItemEX
        {
            [cmdletBinding(
                SupportsShouldProcess = $true,
                ConfirmImpact         = 'High')]
            param
            (
                [System.Collections.Generic.List[Tuple[string,string,string]]]
                $Path,

                [string]
                $RootPath,

                [string]
                $Destination,

                [bool]
                $Force
            )

            # remove default bound "Force"
            $PSBoundParameters.Remove('Force') > $null

            # convert to regex format
            $root = $RootPath.Replace("\", "\\")

            $Path `
            | %{
                # create destination DirectoryName
                $directoryName = Join-Path $Destination ($_.Item2 -split $root | select -Last 1)
                [PSCustomObject]@{
                    Path = $_.Item1
                    DirectoryName = $directoryName
                    Destination = Join-Path $directoryName $_.Item3
                }} `
            | where {$Force -or $PSCmdlet.ShouldProcess($_.Path, ("Copy Item to {0}" -f $_.Destination))} `
            | %{
                Write-Verbose ("Copying '{0}' to '{1}'." -f $_.Path, $_.Destination)
                New-Item -Path $_.DirectoryName -ItemType Directory -Force > $null
                Copy-Item -Path $_.Path -Destination $_.Destination -Force
            }
        }
    }
}

# Copy-ItemEX -Path D:\valentia -Destination D:\hoge -Targets * -Recurse -Excludes Read* -Verbose 