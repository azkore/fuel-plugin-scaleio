$scaleio = hiera('scaleio')
if $scaleio['metadata']['enabled'] {
  if $::mdm_ips {
    scaleio::login {'login':
      password => $scaleio['password']
    } ->
    class {'scaleio::sdc_server':
      ensure  => 'present',
      mdm_ip  => $::mdm_ips,
    } ->
    class {'scaleio_openstack::nova':
      ensure  => present,
    }
    $fuel_version = hiera('fuel_version')
    $all_nodes = hiera('nodes')
    $nodes  = filter_nodes($all_nodes, 'name', $::hostname)
    $hashes = nodes_to_hash($nodes, 'name', 'storage_address')
    $ips    = ipsort(values($hashes))
    $node_ips = split(regsubst($::ip_address_array, '[ "\[\]]', '', 'G'), ',')
    $sds_ips  = intersection($ips, $node_ips)    
    if $sds_ips {
      #use first ip as SDS name
      $sds_name = $sds_ips[0]
      $sds_ips_str = join($sds_ips, ',')
      # remove possible trailing comas
      # generate array of roles (all) with lenght of ips
      $ip_roles = join(values(hash(split(regsubst("${sds_ips_str},", ',', ',all,', 'G'), ','))), ',')
      $paths = $scaleio['device_paths'] ? {
        udnef   => undef,
        default => join(split($scaleio['device_paths'], ','), ',')
      }
      if $paths and count($paths) > 0 {
        #generate array of pools with lenght of device_paths
        $device_paths = $paths
        $storage_pools = join(values(hash(split(regsubst("${device_paths},", ',', ",${scaleio['storage_pool']},", 'G'), ','))), ',')
      } else {
        $device_paths = undef
        $storage_pools = undef
      }
      notify {"Devices ${device_paths}": } ->
      notify {"Storage pools ${storage_pools}": } ->
      notify {"IPs and roles ${sds_ips_str} /  ${ip_roles}": } ->
      scaleio::sds {"Configure SDS ${sds_name}":
        ensure             => 'present',
        ensure_properties  => undef,
        name               => $sds_name,
        protection_domain  => $scaleio['protection_domain'],
        fault_set          => undef,
        port               => undef,
        ips                => $sds_ips_str,
        ip_roles           => $ip_roles,
        storage_pools      => $storage_pools,
        device_paths       => $device_paths,
        require            => Scaleio::Login['login'],
      }
    } else {
      fail('Wrong SDS IPs configuration')
    }
  } else {
    fail('Empty MDM IPs configuration')
  }
}
