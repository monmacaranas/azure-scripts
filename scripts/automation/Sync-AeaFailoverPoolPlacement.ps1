#Requires -Modules Az.Accounts, Az.Sql
[CmdletBinding(SupportsShouldProcess)]
param(
  [string]$PrimaryResourceGroup='ASE-RSG-PRD-APP',
  [string]$PrimaryServer='sql-paas-ase-safetrac-prd',
  [string]$SecondaryResourceGroup='aea-rsg-prd-app',
  [string]$SecondaryServer='sql-paas-aea-safetrac-prd',
  [string]$TimeZoneId='AUS Eastern Standard Time',
  [datetime]$ChangeWindowStart,
  [datetime]$ChangeWindowEnd,
  [switch]$ApplyChanges,
  [string]$DatabaseName
)

# ITP-233 safety boundary: ASE is read-only; failover-group membership is read-only.
$PoolMap=@{
  'sql-paas-ase-safetrac-prd-pool'='sql-paas-ase-safetrac-prd-pool'
  'sql-paas-ase-safetrac-prd-pool2'='sql-paas-ase-safetrac-prd-pool2'
  'sql-paas-ase-boardtrac-prd-pool'='sql-paas-ase-boardtrac-prd-pool'
}
$ErrorActionPreference='Stop'
function Assert-Window {
  if(-not $ApplyChanges){return}
  $now=[TimeZoneInfo]::ConvertTimeBySystemTimeZoneId((Get-Date),$TimeZoneId)
  if($now.DayOfWeek -in @('Friday','Saturday','Sunday')){throw 'ITP-233 production changes are blocked on Friday and weekends.'}
  if(-not $ChangeWindowStart -or -not $ChangeWindowEnd){throw 'ApplyChanges requires ChangeWindowStart and ChangeWindowEnd.'}
  if($ChangeWindowEnd -le $ChangeWindowStart){throw 'ChangeWindowEnd must be later than ChangeWindowStart.'}
  if($now -lt $ChangeWindowStart -or $now -gt $ChangeWindowEnd){throw "Outside approved change window: $ChangeWindowStart to $ChangeWindowEnd"}
}
function Get-FogMap {
  param([string]$rg,[string]$server)
  $m=@{}
  $groups=@(Get-AzSqlDatabaseFailoverGroup -ResourceGroupName $rg -ServerName $server)
  foreach($g in $groups){foreach($db in @($g.DatabaseNames)){$m[$db]=[string]$g.FailoverGroupName}}
  return $m
}
Connect-AzAccount -Identity | Out-Null
if($SecondaryServer -eq $PrimaryServer){throw 'Safety stop: AEA target cannot equal ASE primary.'}
Assert-Window

# READ ONLY: inventory ASE primary.
$primary=@(Get-AzSqlDatabase -ResourceGroupName $PrimaryResourceGroup -ServerName $PrimaryServer | Where-Object {$_.DatabaseName -ne 'master'})
if($DatabaseName){$primary=@($primary | Where-Object {$_.DatabaseName -eq $DatabaseName})}
$fogBefore=Get-FogMap $PrimaryResourceGroup $PrimaryServer
$results=New-Object System.Collections.Generic.List[object]

foreach($p in $primary){
  $name=[string]$p.DatabaseName
  $primaryPool=[string]$p.ElasticPoolName
  if([string]::IsNullOrWhiteSpace($primaryPool)){continue}
  if(-not $PoolMap.ContainsKey($primaryPool)){continue}
  $targetPool=[string]$PoolMap[$primaryPool]
  if(-not $fogBefore.ContainsKey($name)){
    $results.Add([pscustomobject]@{Database=$name;Status='SKIP';Reason='Not in failover group';PrimaryPool=$primaryPool;SecondaryPool='';TargetPool=$targetPool})|Out-Null
    continue
  }
  try{$s=Get-AzSqlDatabase -ResourceGroupName $SecondaryResourceGroup -ServerName $SecondaryServer -DatabaseName $name}catch{
    $results.Add([pscustomobject]@{Database=$name;Status='SKIP';Reason='AEA secondary not found';PrimaryPool=$primaryPool;SecondaryPool='';TargetPool=$targetPool})|Out-Null
    continue
  }
  $secondaryPool=[string]$s.ElasticPoolName
  if($secondaryPool -eq $targetPool){
    $results.Add([pscustomobject]@{Database=$name;Status='OK';Reason='Already correctly placed';PrimaryPool=$primaryPool;SecondaryPool=$secondaryPool;TargetPool=$targetPool})|Out-Null
    continue
  }
  $linkArgs=@{ResourceGroupName=$SecondaryResourceGroup;ServerName=$SecondaryServer;DatabaseName=$name;PartnerResourceGroupName=$PrimaryResourceGroup;PartnerServerName=$PrimaryServer}
  $links=@(Get-AzSqlDatabaseReplicationLink @linkArgs)
  if($links.Count -eq 0){
    $results.Add([pscustomobject]@{Database=$name;Status='SKIP';Reason='No ASE replication link detected';PrimaryPool=$primaryPool;SecondaryPool=$secondaryPool;TargetPool=$targetPool})|Out-Null
    continue
  }
  if(-not $ApplyChanges){
    $results.Add([pscustomobject]@{Database=$name;Status='PLAN';Reason='Would move AEA only';PrimaryPool=$primaryPool;SecondaryPool=$secondaryPool;TargetPool=$targetPool})|Out-Null
    continue
  }
  $oldPool=$secondaryPool
  try{
    if(-not $PSCmdlet.ShouldProcess("$SecondaryServer/$name","Move AEA database from $oldPool to $targetPool")){continue}
    Set-AzSqlDatabase -ResourceGroupName $SecondaryResourceGroup -ServerName $SecondaryServer -DatabaseName $name -ElasticPoolName $targetPool -Confirm:$false | Out-Null
    $deadline=(Get-Date).AddMinutes(15)
    do{Start-Sleep -Seconds 15;$s2=Get-AzSqlDatabase -ResourceGroupName $SecondaryResourceGroup -ServerName $SecondaryServer -DatabaseName $name;$actual=[string]$s2.ElasticPoolName}while($actual -ne $targetPool -and (Get-Date)-lt $deadline)
    if($actual -ne $targetPool){throw "AEA placement did not converge to $targetPool"}
    $p2=Get-AzSqlDatabase -ResourceGroupName $PrimaryResourceGroup -ServerName $PrimaryServer -DatabaseName $name
    if([string]$p2.ElasticPoolName -ne $primaryPool){throw 'SAFETY STOP: ASE primary pool changed unexpectedly.'}
    $fogAfter=Get-FogMap $PrimaryResourceGroup $PrimaryServer
    if($fogBefore.Count -ne $fogAfter.Count){throw 'SAFETY STOP: failover-group membership count changed.'}
    foreach($k in $fogBefore.Keys){if(-not $fogAfter.ContainsKey($k) -or $fogBefore[$k] -ne $fogAfter[$k]){throw "SAFETY STOP: failover-group membership changed for $k"}}
    $results.Add([pscustomobject]@{Database=$name;Status='SUCCESS';Reason='AEA corrected; ASE placement and failover membership verified';PrimaryPool=$primaryPool;SecondaryPool=$oldPool;TargetPool=$targetPool})|Out-Null
  }catch{
    $err=$_.Exception.Message
    try{Set-AzSqlDatabase -ResourceGroupName $SecondaryResourceGroup -ServerName $SecondaryServer -DatabaseName $name -ElasticPoolName $oldPool -Confirm:$false|Out-Null;$results.Add([pscustomobject]@{Database=$name;Status='ROLLBACK_ISSUED';Reason=$err;PrimaryPool=$primaryPool;SecondaryPool=$targetPool;TargetPool=$oldPool})|Out-Null}
    catch{$results.Add([pscustomobject]@{Database=$name;Status='ROLLBACK_FAILED';Reason="$err | $($_.Exception.Message)";PrimaryPool=$primaryPool;SecondaryPool=$targetPool;TargetPool=$oldPool})|Out-Null}
  }
}
$results|Format-Table -AutoSize
$results|ConvertTo-Json -Depth 5