# Could not execute successfully if there are package update

$msdeploy = "C:\Program Files\IIS\Microsoft Web Deploy V3\msdeploy.exe"
$user = "�z�u�Ǘ��҃��[�U�["
$Password = "�z�u�Ǘ��҃p�X���[�h"

foreach ($deploygroup in $deploygroups)
{
    # define arguments of msdeploy
    [string[]]$arguments = @(
        "-verb:sync",
        "-source:package=$zip",
        "-dest:auto,computerName=`"http://$deploygroup/MSDeployAgentService`",userName=$user,password=$Password,includeAcls=`"False`"",
        "-disableLink:AppPoolExtension",
        "-disableLink:ContentExtension",
        "-disableLink:CertificateExtension",
        "-setParam:`"IIS Web Application Name`"=`"W3C1hogehoge`"")
                
    # Start Process
    "running msdeploy to $deploygroup" | Out-LogHost -logfile $log -showdata
                                         
        # Deploy���e�����݂����ۂ� ���s����ɂႢ�� (�X�V���������ꍇ�ɂ̂ݑ���Ȃ��̂ŋp���ł�)
        $processinfo = New-Object System.Diagnostics.ProcessStartInfo
        $processinfo.FileName = $msdeploy
        $processinfo.RedirectStandardError = $true
        $processinfo.RedirectStandardOutput = $true
        $processinfo.UseShellExecute = $false
        $processinfo.Arguments = $arguments
                        
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $processinfo
        $process.Start() > $null
        $process.WaitForExit()

        $output = @()
        $output = $process.StandardError.ReadToEnd()
        $output += $process.StandardOutput.ReadToEnd()
        $output | Out-LogHost -logfile $log -hidedata
}
