#!/bin/bash

echo "

██╗██████╗ ███████╗███████╗ ██████╗    ██╗   ██╗██████╗ ███╗   ██╗                                                    
██║██╔══██╗██╔════╝██╔════╝██╔════╝    ██║   ██║██╔══██╗████╗  ██║                                                    
██║██████╔╝███████╗█████╗  ██║         ██║   ██║██████╔╝██╔██╗ ██║                                                    
██║██╔═══╝ ╚════██║██╔══╝  ██║         ╚██╗ ██╔╝██╔═══╝ ██║╚██╗██║                                                    
██║██║     ███████║███████╗╚██████╗     ╚████╔╝ ██║     ██║ ╚████║                                                    
╚═╝╚═╝     ╚══════╝╚══════╝ ╚═════╝      ╚═══╝  ╚═╝     ╚═╝  ╚═══╝                                                    
                                                                                                                      
███╗   ███╗██╗ ██████╗ ██████╗  █████╗ ████████╗██╗ ██████╗ ███╗   ██╗    ███████╗ ██████╗██████╗ ██╗██████╗ ████████╗
████╗ ████║██║██╔════╝ ██╔══██╗██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║    ██╔════╝██╔════╝██╔══██╗██║██╔══██╗╚══██╔══╝
██╔████╔██║██║██║  ███╗██████╔╝███████║   ██║   ██║██║   ██║██╔██╗ ██║    ███████╗██║     ██████╔╝██║██████╔╝   ██║   
██║╚██╔╝██║██║██║   ██║██╔══██╗██╔══██║   ██║   ██║██║   ██║██║╚██╗██║    ╚════██║██║     ██╔══██╗██║██╔═══╝    ██║   
██║ ╚═╝ ██║██║╚██████╔╝██║  ██║██║  ██║   ██║   ██║╚██████╔╝██║ ╚████║    ███████║╚██████╗██║  ██║██║██║        ██║   
╚═╝     ╚═╝╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝    ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝        ╚═╝   
                                                                                                                      

Input file format:
neutron router1,advanced router1
neutron router2,advanced router2
...
"

echo "{====================STAGE 1: Collecting information====================}"
echo ""
echo ""

#!/bin/bash

# STEP 1: Reading the config file and building map

if [ -z "$1" ]; then
    echo "Error: No input file provided."
    exit 1
fi

start_time=$(date +%s)

echo "Executing STEP 1: Reading config file $1"

# Required map
declare -A neutron_to_adv_router

# Building map with required values
while IFS=, read -r vpn_neutron_router vpn_advanced_router || [ -n "$vpn_neutron_router" ]; do
    neutron_to_adv_router["$vpn_neutron_router"]="$vpn_advanced_router"
done < "$1"

echo "Reading values from config:"
echo ""
echo "___________________________________________________________________________"
echo "|Neutron router                      |Advanced Router                     |"
echo " ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ "

for key in "${!neutron_to_adv_router[@]}"; do
    echo "|$key|${neutron_to_adv_router[$key]}|"
done
echo " ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ "
echo ""

echo "STEP 1 complete (config read)"
echo "**********************************************************************************"

# STEP 2: Checking if Neutron routers exist in OpenStack tenant

echo "Executing STEP 2: Checking Neutron routers"

neutron_router_list=$(openstack router list -f json)

for neutron_router_id in "${!neutron_to_adv_router[@]}"; do
    if ! echo "$neutron_router_list" | jq -e --arg id "$neutron_router_id" '.[] | select(.ID == $id)' > /dev/null; then
        echo "Error: Neutron router ID $neutron_router_id not found in OpenStack tenant."
        exit 1
    else
        echo "Neutron router ID $neutron_router_id exists in OpenStack tenant."
    fi
done

echo "STEP 2 complete (Neutron routers checked)"
echo "**********************************************************************************"

# STEP 3: Checking if Advanced routers exist in external SDN

echo "Executing STEP 3: Checking Advanced routers"


token=$(openstack token issue -c id -f value)

curl_output=$(curl -s https://infra.mail.ru:9696/v2.0/direct_connect/dc_routers \
    -H "Content-Type: application/json" \
    -H "X-Auth-Token: $token" \
    -H "X-SDN:SPRUT")

for advanced_router_id in "${neutron_to_adv_router[@]}"; do
    if ! echo "$curl_output" | jq -e --arg id "$advanced_router_id" '.dc_routers[] | select(.id == $id)' > /dev/null; then
        echo "Error: Advanced router ID $advanced_router_id not found in SDN."
        exit 1
    else
        echo "Advanced router ID $advanced_router_id exists in SDN."
    fi
done

echo "STEP 3 complete (Advanced routers checked)"
echo "**********************************************************************************"



# STEP 4: Collecting info about IPsec policies

echo "Executing STEP 4: Collecting info about IPsec policies"

# Declare a dictionary to store IPsec policy details
declare -A neutron_ipsec_policy_ID_to_json_details

# List all IPsec policies
ike_policy_list_cmd="openstack vpn ike policy list -f json"
neutron_ike_policy_list=$($ike_policy_list_cmd)

# Run show for each IPsec policy from list
policy_ids=$(echo "$neutron_ike_policy_list" | jq -r '.[].ID')
for policy_id in $policy_ids; do
    ike_policy_show_cmd="openstack vpn ike policy show $policy_id -f json"
    echo "Running command: $ike_policy_show_cmd"

    ike_policy_json_details=$($ike_policy_show_cmd)

    # Store the JSON details in the dictionary with the ID as the key
    neutron_ipsec_policy_ID_to_json_details["$policy_id"]="$ike_policy_json_details"
done

# Output IPsec policy details
echo "Stored IPsec policies:"
for policy_id in "${!neutron_ipsec_policy_ID_to_json_details[@]}"; do
    echo "Policy ID: $policy_id"
    echo "Details: ${neutron_ipsec_policy_ID_to_json_details[$policy_id]}"
    echo ""
done

echo "STEP 4 complete: Info about IPsec policies stored"
echo "**********************************************************************************"

# STEP 5: Collecting info about IKE policies

echo "Executing STEP 5: Collecting info about IKE policies"

# Declare a dictionary to store IKE policy details
declare -A neutron_ike_policy_ID_to_json_details

# List all IKE policies
ike_policy_list_cmd="openstack vpn ike policy list -f json"
neutron_ike_policy_list=$($ike_policy_list_cmd)

# Run show for each IKE policy from list
ike_policy_ids=$(echo "$neutron_ike_policy_list" | jq -r '.[].ID')
for ike_policy_id in $ike_policy_ids; do
    ike_policy_show_cmd="openstack vpn ike policy show $ike_policy_id -f json"
    echo "Running command: $ike_policy_show_cmd"

    ike_policy_json_details=$($ike_policy_show_cmd)

    # Store the JSON details in the dictionary with the ID as the key
    neutron_ike_policy_ID_to_json_details["$ike_policy_id"]="$ike_policy_json_details"
done

# Output IKE policy details
echo "Stored IKE policies:"
for ike_policy_id in "${!neutron_ike_policy_ID_to_json_details[@]}"; do
    echo "Policy ID: $ike_policy_id"
    echo "Details: ${neutron_ike_policy_ID_to_json_details[$ike_policy_id]}"
    echo ""
done

echo "STEP 5 complete: Info about IKE policies stored"
echo "**********************************************************************************"

# STEP 6: Collecting info about Endpoint Groups

echo "Executing STEP 6: Collecting info about Endpoint Groups"

# Declare a dictionary to store Endpoint Group details
declare -A neutron_endpoint_group_ID_to_json_details

# List all Endpoint Groups
endpoint_group_list_cmd="openstack vpn endpoint group list -f json"
neutron_endpoint_group_list=$($endpoint_group_list_cmd)

# Run show for each Endpoint Group from list
endpoint_group_ids=$(echo "$neutron_endpoint_group_list" | jq -r '.[].ID')
for endpoint_group_id in $endpoint_group_ids; do
    endpoint_group_show_cmd="openstack vpn endpoint group show $endpoint_group_id -f json"
    echo "Running command: $endpoint_group_show_cmd"

    endpoint_group_json_details=$($endpoint_group_show_cmd)

    # Store the JSON details in the dictionary with the ID as the key
    neutron_endpoint_group_ID_to_json_details["$endpoint_group_id"]="$endpoint_group_json_details"

    # Check if "sdn" is "sprut" and echo network addresses
    sdn_value=$(echo "$endpoint_group_json_details" | jq -r '."sdn"')
    if [[ "$sdn_value" == "sprut" ]]; then
        network_addresses=$(echo "$endpoint_group_json_details" | jq -r '."Endpoints"[]')
        echo "Endpoint Group $endpoint_group_id has sdn 'sprut' with the following network addresses:"
        echo "$network_addresses"
    fi
done

# Output Endpoint Group details
echo "Stored Endpoint Groups:"
for endpoint_group_id in "${!neutron_endpoint_group_ID_to_json_details[@]}"; do
    echo "Endpoint Group ID: $endpoint_group_id"
    echo "Details: ${neutron_endpoint_group_ID_to_json_details[$endpoint_group_id]}"
    echo ""
done

echo "STEP 6 complete: Info about Endpoint Groups stored"
echo "**********************************************************************************"

# STEP 7: Creating a map of Subnet ID to Subnet Address

echo "Executing STEP 7: Creating a map of Subnet ID to Subnet Address"

# Declare a dictionary to store Subnet ID to Subnet Address
declare -A subnet_id_to_subnet_address

# Get the list of subnets
subnet_list_cmd="openstack subnet list -f json"
subnet_list=$($subnet_list_cmd)

# Loop through each subnet and build the map
subnet_ids=$(echo "$subnet_list" | jq -r '.[] | select(.Name | startswith("ext-subnet") | not) | .ID')
for subnet_id in $subnet_ids; do
    subnet_address=$(echo "$subnet_list" | jq -r --arg id "$subnet_id" '.[] | select(.ID == $id) | .Subnet')
    
    # Add to map only if the subnet name does not start with "ext-subnet"
    subnet_name=$(echo "$subnet_list" | jq -r --arg id "$subnet_id" '.[] | select(.ID == $id) | .Name')
    if [[ ! "$subnet_name" =~ ^ext-subnet ]]; then
        subnet_id_to_subnet_address["$subnet_id"]="$subnet_address"
    fi
done

# Output the Subnet ID to Subnet Address map in a table format
echo "Stored Subnet ID to Subnet Address mapping:"
echo "_____________________________________________________________"
printf "| %-36s | %-18s |\n" "Subnet ID" "Subnet Address"
echo " ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅"
for subnet_id in "${!subnet_id_to_subnet_address[@]}"; do
    printf "| %-36s | %-18s |\n" "$subnet_id" "${subnet_id_to_subnet_address[$subnet_id]}"
done
echo " ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅"
echo ""

echo "STEP 7 complete: Subnet ID to Subnet Address map created"
echo "**********************************************************************************"


echo "Executing STEP 8: Collecting info about vpn services"

vpn_service_list_cmd="openstack vpn service list -f json"
echo "Running command: $vpn_service_list_cmd"
neutron_vpn_services_list=$($vpn_service_list_cmd)

declare -A router_id_to_vpn_service_id

while IFS= read -r line; do
    router_id=$(echo "$line" | cut -d ' ' -f 1)
    vpn_id=$(echo "$line" | cut -d ' ' -f 2)
    
    # If the router_id key doesn't already exist, add it to the map
    if [[ -z "${router_id_to_vpn_service_id["$router_id"]}" ]]; then
        router_id_to_vpn_service_id["$router_id"]="$vpn_id"
    fi
done < <(echo "$neutron_vpn_services_list" | jq -r '.[] | "\(.Router) \(.ID)"')


echo "Remove router_ids that are not in config"
for router_id in "${!router_id_to_vpn_service_id[@]}"; do
    if [[ -z "${neutron_to_adv_router["$router_id"]}" ]]; then
        unset "router_id_to_vpn_service_id[$router_id]"
    fi
done

echo "__________________________________________________________________________"
echo "|Router ID                           |VPN service ID                      |"
echo " ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅"
for router_id in "${!router_id_to_vpn_service_id[@]}"; do
    echo "|$router_id|${router_id_to_vpn_service_id[$router_id]}|"
done
echo " ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅"

# Declare backwards dictionary

echo "build backwards dictionary"

declare -A vpn_service_id_to_router_id
while IFS= read -r line; do
    router_id=$(echo "$line" | cut -d ' ' -f 1)
    vpn_id=$(echo "$line" | cut -d ' ' -f 2)
    
    vpn_service_id_to_router_id[$vpn_id]=$router_id
    
done < <(echo "$neutron_vpn_services_list" | jq -r '.[] | "\(.Router) \(.ID)"')

echo "__________________________________________________________________________"
echo "|VPN service ID                      |Router ID                          |"
echo " ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅"
for vpn_service_id in "${!vpn_service_id_to_router_id[@]}"; do
    echo "|$vpn_service_id|${vpn_service_id_to_router_id[$vpn_service_id]}|"
done
echo " ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅"


echo "STEP 8 complete (Router ID to VPN Service ID map built)"
echo "**********************************************************************************"

echo "Executing STEP 9: Collecting info about ipsec"

# Map for storing openstack ipsec show command for each ipsec tunnel
declare -A neutron_vpn_ipsec_site_connection_ID_to_json_details

# Map for storing neutron router id to ipsec tunnel
declare -A neutron_router_to_ipsec_ids

# List all ipsec tunnels
vpn_site_connection_list_cmd="openstack vpn ipsec site connection list -f json"
neutron_vpn_ipsec_site_connection_list=$($vpn_site_connection_list_cmd)

# Run show for each ipsec from list
ids=$(echo "$neutron_vpn_ipsec_site_connection_list" | jq -r '.[].ID')
for id in $ids; do
    ipsec_site_connection_show_cmd="openstack vpn ipsec site connection show $id -f json"
    echo "Running command: $ipsec_site_connection_show_cmd"

    ipsec_site_connection_json_details=$($ipsec_site_connection_show_cmd)

    vpn_service_id=$(echo "$ipsec_site_connection_json_details" | jq -r '."VPN Service"') 

    router_id=$(echo "${vpn_service_id_to_router_id[$vpn_service_id]}")

    

    # Append the IPsec ID to the list associated with the router

    if [[ -z "${neutron_router_to_ipsec_ids[$router_id]}" ]]; then
        neutron_router_to_ipsec_ids[$router_id]="$id"
    else
        neutron_router_to_ipsec_ids[$router_id]+=", $id"
    fi

    neutron_vpn_ipsec_site_connection_ID_to_json_details["$id"]="$ipsec_site_connection_json_details"

done

# Output IPsec connections
echo "Stored IPsec connections:"
for id in "${!neutron_vpn_ipsec_site_connection_ID_to_json_details[@]}"; do
    echo "ID: $id"
    echo "Details: ${neutron_vpn_ipsec_site_connection_ID_to_json_details[$id]}"
    echo ""
done

# Output Neutron Router to IPsec IDs map
echo "==================================================================================-"
echo "Neutron Router to IPsec IDs mapping:"
for router_id in "${!neutron_router_to_ipsec_ids[@]}"; do
    echo "Router ID: $router_id"
    echo "IPsec IDs: ${neutron_router_to_ipsec_ids[$router_id]}"
    echo "--------------------------------------------------------------------------------"
done
echo "==================================================================================="
echo ""

echo "STEP 9 complete: Info about ipsec stored"
echo "**********************************************************************************"

echo "{====================STAGE 1: COMPLETE====================}"
echo ""
echo "{====================STAGE 2: CREATING NEW TUNNELS ====================}"

end_time=$(date +%s)
elapsed_time=$(($end_time - $start_time))
echo "Elapsed time: $elapsed_time seconds"