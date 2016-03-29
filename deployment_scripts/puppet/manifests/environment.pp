# Helper for array processing
define env_fact($role, $fact, $value) {
  file_line { "Append a FACTER_${role}_${fact} line to /etc/environment":
    ensure  => present,
    path    => '/etc/environment',
    match   => "^FACTER_${role}_${fact}=",
    line    => "FACTER_${role}_${fact}=${value}",
  }  
}

define environment() {
  $fuel_version = hiera('fuel_version')
  $all_nodes = hiera('nodes')
  $role = $name
  $nodes = $fuel_version ? {
    /(6\.1|7\.0)/   => concat(filter_nodes($all_nodes, 'role', 'primary-controller'), filter_nodes($all_nodes, 'role', 'controller')),
    default         => filter_nodes($all_nodes, 'role', "scaleio-${role}"),
  }
  $hashes         = nodes_to_hash($nodes, 'name', 'storage_address')
  $ips_array_      = ipsort(values($hashes))
  if $fuel_version == '6.1' or $fuel_version == '7.0' {
    $count = count(keys($hashes))
    case $role {
      'tb': {
        $ips_array = $count ? {
          1 => [],
          3 => values_at($ips_array_, 2),
          5 => values_at($ips_array_, ['3-4']),
          default => fail("Only configuration cluster_3 and cluster_5 are supported, actualy ${count}")
        }
      }
      'mdm': {
        $ips_array = $count ? {
          1 => $ips_array_,
          3 => values_at($ips_array_, ['0-1']),
          5 => values_at($ips_array_, ['0-2']),
          default => fail("Only configuration cluster_3 and cluster_5 are supported, actualy ${count}")
        }
      }
      'gateway': {
        $ips_array = $ips_array_
      }
      default: {
        fail("Unsupported role ${role}")
      }
    }
  } else {
    $ips_array = $ips_array_
  }
  $ips = join($ips_array, ',')
  env_fact {"Environment fact: ${role}, nodes: ${nodes}, ips: ${ips}":
    role  => $role,
    fact  => 'ips',
    value => $ips,
  }
}

$scaleio = hiera('scaleio')
if $scaleio['metadata']['enabled'] {
  notify{'ScaleIO plugin enabled': }
  case $::osfamily {
    'RedHat': {
      fail('This is temporary limitation. ScaleIO supports only Ubuntu for now.')
    }
    'Debian': {
      # nothing to do
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} only support osfamily RedHat and Debian")
    }
  }
  $all_nodes = hiera('nodes')
  if count(filter_nodes($all_nodes, 'role', 'cinder')) == 0 {
    fail('At least one Node with Cinder role is required')
  }
  if $scaleio['existing_cluster'] {
    notify{'Use existing ScaleIO cluster': }
    $existing_mdm_ips = $::existing_cluster_mdm_ips
    env_fact{"Environment fact: role gateway, ips: ${scaleio['gateway_ip']}":
      role => 'gateway',
      fact => 'ips',
      value => $scaleio['gateway_ip']
    } ->
    env_fact{"Environment fact: role mdm, ips: ${existing_mdm_ips}":
      role => 'mdm',
      fact => 'ips',
      value => $existing_mdm_ips
    } ->
    env_fact{"Environment fact: role gateway, user: ${scaleio['gateway_user']}":
      role => 'gateway',
      fact => 'user',
      value => $scaleio['gateway_user']
    } ->
    env_fact{"Environment fact: role gateway, password: ${scaleio['gateway_password']}":
      role => 'gateway',
      fact => 'password',
      value => $scaleio['gateway_password']
    } ->
    env_fact{"Environment fact: role gateway, port: ${scaleio['gateway_port']}":
      role => 'gateway',
      fact => 'port',
      value => $scaleio['gateway_port']
    } ->
    env_fact{"Environment fact: role storage, pools: ${scaleio['existing_storage_pools']}":
      role => 'storage',
      fact => 'pools',
      value => $scaleio['existing_storage_pools']
    }
  } else {
    #TODO: check number of possible SDS-es 
    $nodes = filter_nodes($all_nodes, 'name', $::hostname)
    if ! empty(filter_nodes($nodes, 'role', 'cinder')) {
      notify {"Ensure devices size are greater than 100GB for Cinder Node ${::hostname}": }
      #TODO: add check devices sizes
    }
    notify{'Deploy new ScaleIO cluster': }
    environment{['mdm', 'tb', 'gateway']: } ->
    env_fact{'Environment fact: role gateway, user: admin':
      role => 'gateway',
      fact => 'user',
      value => 'admin'
    } ->
    env_fact{'Environment fact: role gateway, port: 4443':
      role => 'gateway',
      fact => 'port',
      value => 4443
    } ->
    env_fact{"Environment fact: role storage, pools: ${scaleio['storage_pools']}":
      role => 'storage',
      fact => 'pools',
      value => $scaleio['storage_pools']
    }
  }
} else {
    notify{'ScaleIO plugin disabled': }
}
