# This is a workaround because FUEL daemons dont inherit evnironment variables
require 'facter'
require 'json'

base_cmd = "bash -c 'source /etc/environment; echo $FACTER_%s'"
facters = ['tb_ips', 'mdm_ips', 'gateway_user', 'gateway_port', 'gateway_ips', 'gateway_password', 'mdm_password', 'storage_pools']
facters.each { |f|
  if ! Facter.value(f)
    Facter.add(f) do
      setcode base_cmd % f 
    end
  end
}

Facter.add('existing_cluster_mdm_ips') do
  setcode do
    user        = Facter.value('gateway_user')
    password    = Facter.value('gateway_password')
    host        = Facter.value('gateway_ips').split(',')[0]
    port        = Facter.value('gateway_port')
    base_url    = "https://%s:%s/api/%s"
    login_url   = base_url % [host, port, 'login']
    config_url  = base_url % [host, port, 'Configuration']
    login_req   = "curl -k --basic --user #{user}:#{password} #{login_url} 2>/dev/null | sed 's/\"//g'"
    token       = Facter::Util::Resolution.exec(login_req)
    req_url     = "curl -k --basic --user #{user}:#{token} #{config_url} 2>/dev/null"
    config_str  = Facter::Util::Resolution.exec(req_url)
    config      = JSON.parse(config_str)
    mdm_ips     = config['mdmAddresses'].join(',')
    mdm_ips
  end
end
