rsnapshot_backup '/' do
  exclude '/dev/*'
  exclude '/media/*'
  exclude '/mnt/*'
  exclude '/proc/*'
  exclude '/sys/*'
  exclude '/tmp/*'
  exclude '/var/cache/apt/archives/*'
  exclude '/var/lock/*'
  exclude '/var/run/*'
  exclude '/var/tmp/*'
end
