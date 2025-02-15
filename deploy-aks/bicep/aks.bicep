// This Bicep template is used to specify the desired configuration of the AKS service.
// Use deployment parameters to customize deployment.
//
//Project README: https://github.com/cool-tech-dad/minecraft-vending-machine 
//If you have questions or need help, reach out via Discord: https://discord.gg/aCnzN2QsQE
//If you want to contribute code, please see: https://github.com/cool-tech-dad/minecraft-vending-machine#contribute 

/*
Resource domains
1. AKS
*/


/*_  ___  __    __  .______    _______ .______      .__   __.  _______ .___________. _______      _______.
|  |/  / |  |  |  | |   _  \  |   ____||   _  \     |  \ |  | |   ____||           ||   ____|    /       |
|  '  /  |  |  |  | |  |_)  | |  |__   |  |_)  |    |   \|  | |  |__   `---|  |----`|  |__      |   (----`
|    <   |  |  |  | |   _  <  |   __|  |      /     |  . `  | |   __|      |  |     |   __|      \   \    
|  .  \  |  `--'  | |  |_)  | |  |____ |  |\  \----.|  |\   | |  |____     |  |     |  |____ .----)   |   
|__|\__\  \______/  |______/  |_______|| _| `._____||__| \__| |_______|    |__|     |_______||_______/ */

//**deployment parameters**
//global:
@description('Used to name all resources')
@minLength(3)
@maxLength(20)
param resource_name_prefix string
param location string

//governance:
param kubernetes_version string
param dev bool = true
param auto_scale bool = false
@description('Pool tier sizing presets')
@allowed([
  'cost-optimized'
  'standard'
  'premium'
])
param pool_tier string = 'cost-optimized'

//iam:
param enable_aad bool = true
param enable_azure_rbac bool = true

//agent pool 01 settings:
param user_pool01_name string = 'npmcbds001'
param user_pool01_labels object = {
  app: 'mc-bds-001'
}

//**variables**
var random_string = '${take(uniqueString(resourceGroup().id), 4)}'

var pool_presets_base = {
  osType: 'Linux'
}

var system_pool_presets = {
  name: 'npsystem'
  mode: 'System'
  count: 1
  maxPods: 30
  nodeTaints: [
    dev ? '' : 'CriticalAddonsOnly=true:NoSchedule'
  ]
}
var system_pool_sizing = {
  'cost-optimized' : {
    vmSize: 'Standard_B4ms'
    minCount: auto_scale ? 1 : json('null')
  }
  'standard' : {
    vmSize: 'Standard_D2_v5'
    minCount: auto_scale ? 1 : json('null')
  }
  'premium' : {
    vmSize: 'Standard_D4s_v5'
    minCount: auto_scale ? 2 : json('null')
  }
}
var system_pool_profile = union(pool_presets_base, system_pool_presets, system_pool_sizing[pool_tier])

var user_pool_presets = {
  mode: 'User'
  count: 1
}
var user_pool_sizing = {
  'cost-optimized' : {
    vmSize: 'Standard_B4ms'
    maxPods: 10
    minCount: auto_scale ? 1 : json('null')
  }
  'standard' : {
    vmSize: 'Standard_B4ms_v3'
    maxPods: 30
    minCount: auto_scale ? 1 : json('null')
  }
  'premium' : {
    vmSize: 'Standard_D4s_v5'
    maxPods: 30
    minCount: auto_scale ? 2 : json('null')
  }
}
var user_pool_01_name = dev ? {} : { 
  name: user_pool01_name
}
var user_pool_01_labels = dev ? {} : { 
  nodeLabels: user_pool01_labels
}
var user_pool_profile01= union( user_pool_01_name, user_pool_01_labels, pool_presets_base, user_pool_presets, user_pool_sizing[pool_tier])
var pool_profiles = dev ? array(system_pool_profile) : concat(array(system_pool_profile), array(user_pool_profile01))

var aks_properties_base = {
  kubernetesVersion: kubernetes_version
  dnsPrefix: '${resource_name_prefix}dns'
  aadProfile: enable_aad ? {
    managed: true
    enableAzureRbac: enable_azure_rbac
  } : null
  agentPoolProfiles: pool_profiles
  networkProfile: {
    loadBalancerSku: 'standard'
    networkPlugin: 'kubenet'
  }
}

//Deploy resource
resource aks 'Microsoft.ContainerService/managedClusters@2021-07-01' = {
  name: 'aks${resource_name_prefix}${random_string}'
  location: location
  properties: aks_properties_base
  identity: {
    type: 'SystemAssigned'
  }
}

//Genereate useful output
output std_out string = aks.name

//ACSCII Art link : https://textkool.com/en/ascii-art-generator?hl=default&vl=default&font=Star%20Wars&text=changeme
