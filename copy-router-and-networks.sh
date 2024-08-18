#!/bin/bash

echo "
██████╗  ██████╗ ██╗   ██╗████████╗███████╗██████╗                                                                    
██╔══██╗██╔═══██╗██║   ██║╚══██╔══╝██╔════╝██╔══██╗                                                                   
██████╔╝██║   ██║██║   ██║   ██║   █████╗  ██████╔╝                                                                   
██╔══██╗██║   ██║██║   ██║   ██║   ██╔══╝  ██╔══██╗                                                                   
██║  ██║╚██████╔╝╚██████╔╝   ██║   ███████╗██║  ██║                                                                   
╚═╝  ╚═╝ ╚═════╝  ╚═════╝    ╚═╝   ╚══════╝╚═╝  ╚═╝                                                                   
                                                                                                                      
███╗   ██╗███████╗████████╗██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗                                                        
████╗  ██║██╔════╝╚══██╔══╝██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝                                                        
██╔██╗ ██║█████╗     ██║   ██║ █╗ ██║██║   ██║██████╔╝█████╔╝                                                         
██║╚██╗██║██╔══╝     ██║   ██║███╗██║██║   ██║██╔══██╗██╔═██╗                                                         
██║ ╚████║███████╗   ██║   ╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗                                                        
╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝                                                        
                                                                                                                      
███████╗██╗   ██╗██████╗ ███╗   ██╗███████╗████████╗██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗                               
██╔════╝██║   ██║██╔══██╗████╗  ██║██╔════╝╚══██╔══╝██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝                               
███████╗██║   ██║██████╔╝██╔██╗ ██║█████╗     ██║   ██║ █╗ ██║██║   ██║██████╔╝█████╔╝                                
╚════██║██║   ██║██╔══██╗██║╚██╗██║██╔══╝     ██║   ██║███╗██║██║   ██║██╔══██╗██╔═██╗                                
███████║╚██████╔╝██████╔╝██║ ╚████║███████╗   ██║   ╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗                               
╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝                               
                                                                                                                      
███╗   ███╗██╗ ██████╗ ██████╗  █████╗ ████████╗██╗ ██████╗ ███╗   ██╗    ███████╗ ██████╗██████╗ ██╗██████╗ ████████╗
████╗ ████║██║██╔════╝ ██╔══██╗██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║    ██╔════╝██╔════╝██╔══██╗██║██╔══██╗╚══██╔══╝
██╔████╔██║██║██║  ███╗██████╔╝███████║   ██║   ██║██║   ██║██╔██╗ ██║    ███████╗██║     ██████╔╝██║██████╔╝   ██║   
██║╚██╔╝██║██║██║   ██║██╔══██╗██╔══██║   ██║   ██║██║   ██║██║╚██╗██║    ╚════██║██║     ██╔══██╗██║██╔═══╝    ██║   
██║ ╚═╝ ██║██║╚██████╔╝██║  ██║██║  ██║   ██║   ██║╚██████╔╝██║ ╚████║    ███████║╚██████╗██║  ██║██║██║        ██║   
╚═╝     ╚═╝╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝    ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝        ╚═╝   

Copies routers, networks, subnets from neutron to sprut.
All resources will be created with -sprut postfix.

Input file format:
neutron router1 UUID,<std|adv|transit>
neutron router2 UUID,<std|adv|transit>
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

declare -A neutron_router_to_transform_format

while IFS=, read -r neutron_router transform_format || [ -n "$neutron_router" ]
do
    if [[ "$transform_format" != "std"  &&  "$transform_format" != "adv" && "$transform_format" != "transit" ]]; then
        echo "Error: transform format $transform_format is not in <std|adv|transit>"
        exit 1
    fi

    neutron_router_to_transform_format["$neutron_router"]="$transform_format"
done < "$1"

echo "Reading values from config:"
echo ""
echo "_____________________________________________________"
echo "|Neutron router                      |Advanced Router|"
echo " ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅"

for key in "${!neutron_router_to_transform_format[@]}"; do
    echo "|$key|${neutron_router_to_transform_format[$key]}          |"
done
echo " ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ "
echo ""

echo "STEP 1 complete (config read)"
echo "**********************************************************************************"

# STEP 2: Checking if Neutron routers exist in OpenStack tenant
neutron_router_list=$(openstack router list -f json)

for neutron_router_id in "${!neutron_router_to_transform_format[@]}"; do
    if ! echo "$neutron_router_list" | jq -e --arg id "$neutron_router_id" '.[] | select(.ID == $id)' > /dev/null; then
        echo "Error: Neutron router ID $neutron_router_id not found in OpenStack tenant."
        exit 1
    else
        echo "Neutron router ID $neutron_router_id exists in OpenStack tenant."
    fi
done

echo "STEP 2 complete (Neutron routers checked)"
echo "**********************************************************************************"

# STEP 3: Collecting info about Openstack routers

echo "Executing STEP 3: Collecting info about Openstack routers"

declare -A neutron_router_ID_to_json_details

for neutron_router_id in "${!neutron_router_to_transform_format[@]}"; do
    neutron_router_show_cmd="openstack router show $neutron_router_id -f json"
    echo "Running command: $neutron_router_show_cmd"
    neutron_router_show_details=$($neutron_router_show_cmd)
    neutron_router_ID_to_json_details["$neutron_router_id"]=$neutron_router_show_details
done

echo "Stored neutron routers: "

for neutron_router_id in "${!neutron_router_ID_to_json_details[@]}"; do
    echo "Router ID: $neutron_router_id"
    echo "Details: ${neutron_router_ID_to_json_details[$neutron_router_id]}"
    echo ""
done

echo "STEP 3 complete: Info about neutron routers stored"
echo "**********************************************************************************"

# STEP 4: Collecting info about Openstack subnets per router

echo "Executing STEP 4: Collecting info about Openstack subnets per router"

declare -A neutron_router_id_to_subnet_ids
declare -A neutron_subnet_id_to_json_details
declare -A neutron_network_id_to_json_details

echo ""
echo "Listing subnets per router and showing details for each subnet:"

for neutron_router_id in "${!neutron_router_ID_to_json_details[@]}"; do
    subnet_ids=$(echo "${neutron_router_ID_to_json_details[$neutron_router_id]}" | jq -r '.interfaces_info[].subnet_id')
    
    neutron_router_id_to_subnet_ids["$neutron_router_id"]="$subnet_ids"

    echo "Router ID: $neutron_router_id"
    echo "Subnet IDs:"
    echo "${neutron_router_id_to_subnet_ids[$neutron_router_id]}"
    echo ""

    for subnet_id in ${neutron_router_id_to_subnet_ids[$neutron_router_id]}; do
        echo "Processing subnet ID: $subnet_id"
        
        neutron_subnet_show_cmd="openstack subnet show $subnet_id -f json"
        echo "Running command: $neutron_subnet_show_cmd"
        neutron_subnet_show_details=$($neutron_subnet_show_cmd)

        neutron_subnet_id_to_json_details["$subnet_id"]="$neutron_subnet_show_details"

        echo "$subnet_id Subnet details:"
        echo "${neutron_subnet_id_to_json_details["$subnet_id"]}"

        neutron_network_id=$(echo $neutron_subnet_show_details | jq -r '.network_id')

        neutron_network_id_to_json_details["$neutron_network_id"]=" "

    done

done

echo ""
echo "STEP 4 Complete: Info about Openstack subnets per router collected"

# STEP 5: Collecting info about Openstack networks

echo "Executing STEP 5: Collecting info about Openstack networks"
echo ""
for network_id in "${!neutron_network_id_to_json_details[@]}"; do
    echo "Processing network ID: $network_id"

    neutron_network_show_cmd="openstack network show $network_id -f json"
    echo "Running command: $neutron_network_show_cmd"
    neutron_network_show_details=$($neutron_network_show_cmd)

    neutron_network_id_to_json_details["$network_id"]=$neutron_network_show_details

    echo "Network details: "
    echo "${neutron_network_id_to_json_details["$network_id"]}"

done

echo "STEP 5 Complete: Info about Openstack networks collected"

echo "{====================STAGE 1: COMPLETE====================}"
echo ""

# Stage 2: Collecting Existing Sprut Objects
echo "{====================STAGE 2: Collecting Existing Sprut Objects====================}"

sprut_api_base="https://infra.mail.ru:9696/v2.0"

token=$(openstack token issue -c id -f value)

declare -A sprut_router_ports

# Function to collect Sprut objects and store them in dictionaries
collect_sprut_objects() {
    echo "Collecting Standard routers from Sprut..."
    sprut_standard_routers=$(curl -s -X GET "${sprut_api_base}/routers" \
        -H "Content-Type: application/json" \
        -H "X-Auth-Token: $token" \
        -H "X-SDN:SPRUT")
    echo "Standard routers collected:"
    echo "$sprut_standard_routers" | jq .
    echo ""

    echo "Collecting Advanced routers from Sprut..."
    sprut_advanced_routers=$(curl -s -X GET "${sprut_api_base}/direct_connect/dc_routers" \
        -H "Content-Type: application/json" \
        -H "X-Auth-Token: $token" \
        -H "X-SDN:SPRUT")
    echo "Advanced routers collected:"
    echo "$sprut_advanced_routers" | jq .
    echo ""

    echo "Collecting Networks from Sprut..."
    sprut_networks=$(curl -s -X GET "${sprut_api_base}/networks" \
        -H "Content-Type: application/json" \
        -H "X-Auth-Token: $token" \
        -H "X-SDN:SPRUT")
    echo "Networks collected:"
    echo "$sprut_networks" | jq .
    echo ""

    echo "Collecting Subnetworks from Sprut..."
    sprut_subnetworks=$(curl -s -X GET "${sprut_api_base}/subnets" \
        -H "Content-Type: application/json" \
        -H "X-Auth-Token: $token" \
        -H "X-SDN:SPRUT")
    echo "Subnetworks collected:"
    echo "$sprut_subnetworks" | jq .
    echo ""

    # Extract router IDs
    sprut_router_ids=$(echo "$sprut_standard_routers" | jq -r '.routers[].id')

    

    for router_id in $sprut_router_ids; do
        echo "Collecting ports for router ID: $router_id"
        
        # Fetch the ports associated with this router
        ports=$(curl -s -X GET "${sprut_api_base}/ports?device_id=${router_id}" \
            -H "Content-Type: application/json" \
            -H "X-Auth-Token: $token" \
            -H "X-SDN:SPRUT")
        
        # Store the result in the associative array
        sprut_router_ports["$router_id"]="$ports"
        
        echo "Ports for router ID $router_id:"
        echo "${sprut_router_ports["$router_id"]}" | jq .
        echo ""
    done
}

# Execute the function
collect_sprut_objects

echo "STAGE 2 complete: Sprut objects collected"
echo "**********************************************************************************"

# Stage 3: Comparing and Creating Missing Objects in Sprut
echo "{====================STAGE 3: Comparing and Creating Missing Objects in Sprut====================}"

print_map_as_table() {
    local -n map=$1
    local title=$2
    local column1=$3
    local column2=$4

    echo "=================================================================================="
    echo "$title"
    echo "=================================================================================="
    printf "| %-36s | %-36s |\n" "$column1" "$column2"
    echo " ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅ ̅"
    for key in "${!map[@]}"; do
        echo "$key"          "${map[$key]}"
    done
    echo "=================================================================================="
    echo ""
}

# Declare maps to store the correspondence between Neutron and Sprut IDs
declare -A neutron_to_sprut_router

compare_and_create_routers() {
    for neutron_router_id in "${!neutron_router_ID_to_json_details[@]}"; do
    neutron_router=$(echo "${neutron_router_ID_to_json_details[$neutron_router_id]}" | jq -r)
    neutron_router_name=$(echo "$neutron_router" | jq -r '.name')

    sprut_router_name=$neutron_router_name
    sprut_router_name+="-sprut"

    # basic case for std
    # TODO: add for tranzit and advanced
    # TODO: add check if router has external ip or no
    sprut_router_id=$(echo "$sprut_standard_routers" | jq -r --arg name "$sprut_router_name" '.routers[] | select(.name == $name) | .id')

    if [ -z "$sprut_router_id" ]; then
            echo "Creating Router '$sprut_router_name' in Sprut"

            request_body=$(jq -n --arg name "$sprut_router_name" '{
                router: {
                    name: $name
                }
            }')

            curl_response=$(curl -s -X POST "${sprut_api_base}/routers" \
                -H "Content-Type: application/json" \
                -H "X-Auth-Token: $token" \
                -H "X-SDN:SPRUT" \
                -d "$request_body")

            echo "$curl_response" | jq .

            sprut_router_id=$(echo "$curl_response" | jq -r '.router.id')
            neutron_to_sprut_router["$neutron_router_id"]="$sprut_router_id"
        else
            echo "Router '$sprut_router_name' already exists in Sprut"
            neutron_to_sprut_router["$neutron_router_id"]="$sprut_router_id"
        fi
    done
}

compare_and_create_routers
print_map_as_table neutron_to_sprut_router "Neutron to Sprut Routers" "Neutron Router ID" "Sprut Router ID"

declare -A neutron_to_sprut_network

compare_and_create_networks() {
    for neutron_network_id in "${!neutron_network_id_to_json_details[@]}"; do 
    neutron_network=$(echo "${neutron_network_id_to_json_details[$neutron_network_id]}" | jq -r)
    neutron_network_name=$(echo "$neutron_network" | jq -r '.name')

    sprut_network_name=$neutron_network_name
    sprut_network_name+="-sprut"


    sprut_network_id=$(echo "$sprut_networks" | jq -r --arg name "$sprut_network_name" '.networks[] | select(.name == $name) | .id')

    if [ -z "$sprut_network_id" ]; then
            echo "Creating Network '$sprut_network_name' in Sprut"

            request_body=$(jq -n --arg name "$sprut_network_name" '{
                network: {
                    name: $name
                }
            }')

            curl_response=$(curl -s -X POST "${sprut_api_base}/networks" \
                -H "Content-Type: application/json" \
                -H "X-Auth-Token: $token" \
                -H "X-SDN:SPRUT" \
                -d "$request_body")

            echo "$curl_response" | jq .

            sprut_network_id=$(echo "$curl_response" | jq -r '.network.id')
            neutron_to_sprut_network["$neutron_network_id"]="$sprut_network_id"
        else
            echo "Router '$sprut_router_name' already exists in Sprut"
            neutron_to_sprut_network["$neutron_network_id"]="$sprut_network_id"
        fi
    done

}

compare_and_create_networks
print_map_as_table neutron_to_sprut_network "Neutron to Sprut Networks" "Neutron Network ID" "Sprut Network ID"


# TODO: add transformation for static routes via SNAT interfaces

declare -A neutron_to_sprut_subnet

compare_and_create_subnetworks() {
    for neutron_subnetwork_id in "${!neutron_subnet_id_to_json_details[@]}"; do  
        neutron_subnetwork=$(echo "${neutron_subnet_id_to_json_details[$neutron_subnetwork_id]}" | jq -r)
        neutron_subnetwork_name=$(echo "$neutron_subnetwork" | jq -r '.name')

        sprut_subnetwork_name=$neutron_subnetwork_name
        sprut_subnetwork_name+="-sprut"

        sprut_subnetwork_id=$(echo "$sprut_subnetworks" | jq -r --arg name "$sprut_subnetwork_name" '.subnets[] | select(.name == $name) | .id')

        if [ -z "$sprut_subnetwork_id" ]; then
                echo "Creating Subnetwork '$sprut_subnetwork_name' in Sprut"

                neutron_network_id=$(echo "$neutron_subnetwork" | jq -r '.network_id')

                sprut_network_id="${neutron_to_sprut_network[$neutron_network_id]}"

                request_body=$(jq -n --arg name "$sprut_subnetwork_name" \
                        --arg cidr "$(echo "$neutron_subnetwork" | jq -r '.cidr')" \
                        --arg description "$(echo "$neutron_subnetwork" | jq -r '.description')" \
                        --argjson dns_nameservers "$(echo "$neutron_subnetwork" | jq '.dns_nameservers')" \
                        --argjson enable_dhcp "$(echo "$neutron_subnetwork" | jq '.enable_dhcp')" \
                        --arg gateway_ip "$(echo "$neutron_subnetwork" | jq -r '.gateway_ip')" \
                        --argjson host_routes "$(echo "$neutron_subnetwork" | jq '.host_routes')" \
                        --argjson allocation_pools "$(echo "$neutron_subnetwork" | jq '.allocation_pools')" \
                        --arg network_id "$sprut_network_id" \
                '{
                    subnet: {
                        name: $name,
                        cidr: $cidr,
                        description: $description,
                        dns_nameservers: $dns_nameservers,
                        enable_dhcp: $enable_dhcp,
                        gateway_ip: $gateway_ip,
                        host_routes: $host_routes,
                        allocation_pools: $allocation_pools,
                        network_id: $network_id,
                        ip_version: 4
                    }
                }')

                echo "Subnetwork creating request body: $request_body"

                curl_response=$(curl -s -X POST "${sprut_api_base}/subnets" \
                    -H "Content-Type: application/json" \
                    -H "X-Auth-Token: $token" \
                    -H "X-SDN:SPRUT" \
                    -d "$request_body")

                echo "$curl_response" | jq .

                sprut_subnetwork_id=$(echo "$curl_response" | jq -r '.subnet.id')
                neutron_to_sprut_subnet["$neutron_subnetwork_id"]="$sprut_subnetwork_id"
            else
                echo "Subnet '$sprut_subnetwork_name' already exists in Sprut"
                

                neutron_to_sprut_subnet["$neutron_subnetwork_id"]="$sprut_subnetwork_id"
            fi
    done
}

compare_and_create_subnetworks
print_map_as_table neutron_to_sprut_subnet "Neutron to Sprut Subnets" "Neutron Subnetwork ID" "Sprut Subnetwork ID"

collect_sprut_objects

declare -A neutron_to_sprut_router_ports

compare_and_create_router_to_network_interfaces() {
    neutron_and_sprut_ports_json=$(openstack port list -f json)

    for neutron_router_id in "${!neutron_router_ID_to_json_details[@]}"; do
        neutron_router=$(echo "${neutron_router_ID_to_json_details[$neutron_router_id]}" | jq -r)
        neutron_router_name=$(echo "$neutron_router" | jq -r '.name')

        for neutron_interface in $(echo "$neutron_router" | jq -c '.interfaces_info[]'); do
            neutron_ip=$(echo "$neutron_interface" | jq -r '.ip_address')

            neutron_interface_id=$(echo "$neutron_interface" | jq -r '.port_id')

            neutron_port_show_cmd="openstack port show $neutron_interface_id -f json"
            echo "Running command: $neutron_port_show_cmd"

            neutron_port_show_cmd_details=$($neutron_port_show_cmd)

            neutron_port_mac_address=$(echo "$neutron_port_show_cmd_details" | jq -r '.mac_address')

            neutron_subnet_id=$(echo "$neutron_interface" | jq -r '.subnet_id')
            
            sprut_subnet_id="${neutron_to_sprut_subnet[$neutron_subnet_id]}"
            # sprut_subnet=$(echo "$sprut_subnetworks" | jq -r --arg id "$sprut_subnet_id" '.subnets[] | select(.id == $id) | .name')
            sprut_subnet=$(echo "$sprut_subnetworks" | jq -r --arg id "$sprut_subnet_id" '.subnets[] | select(.id == $id)')

            sprut_subnet_name=$(echo "$sprut_subnet" | jq -r '.name')
            sprut_network_id=$(echo "$sprut_subnet" | jq -r '.network_id')
            
            # Assign the port name
            port_name="${neutron_router_name}-${sprut_subnet_name}"
            
            # Check if the port already exists in Sprut based on IP and MAC address

            echo "Check if port $port_name already exists"

            sprut_router_id=${neutron_to_sprut_router[$neutron_router_id]}
            
            # port can exist but not be attached
            sprut_port_id=$(echo "$neutron_and_sprut_ports_json" | jq -r --arg name $port_name --arg ip $neutron_ip '.[] | select(.Name == $name and ."Fixed IP Addresses"[].ip_address == $ip) | .ID')
            
            sprut_router_id="${neutron_to_sprut_router[$neutron_router_id]}"

            if [ -z "$sprut_port_id" ]; then
                echo "Creating Port '$port_name' in Sprut"

                request_body=$(jq -n --arg name "$port_name" \
                                    --arg ip_address "$neutron_ip" \
                                    --arg mac_address "$neutron_port_mac_address" \
                                    --arg network_id "$sprut_network_id" \
                                    --argjson fixed_ips "$(jq -n --arg subnet_id "$sprut_subnet_id" --arg ip_address "$neutron_ip" '[{subnet_id: $subnet_id, ip_address: $ip_address}]')" \
                '{
                    port: {
                        name: $name,
                        mac_address: $mac_address,
                        fixed_ips: $fixed_ips,
                        network_id: $network_id
                    }
                }')

                curl_response=$(curl -s -X POST "${sprut_api_base}/ports" \
                    -H "Content-Type: application/json" \
                    -H "X-Auth-Token: $token" \
                    -H "X-SDN:SPRUT" \
                    -d "$request_body")

                echo "$curl_response" | jq .

                sprut_port_id=$(echo "$curl_response" | jq -r '.port.id')

                # attaching ports to routers

                echo "Attaching created port $sprut_port_id to router $sprut_router_id"

                attach_port_cmd="openstack router add port $sprut_router_id $sprut_port_id"
                echo "Running command: $attach_port_cmd"
                result=$($attach_port_cmd)

            else
                echo "Port '$port_name' already exists in Sprut"
                # port exists, check that it is attached to a router
                sprut_routers_json_details="${sprut_router_ports["$sprut_router_id"]}"
                
                sprut_port_id_on_router=$(echo "$sprut_routers_json_details" | jq --arg name "$port_name" --arg mac "$neutron_port_mac_address" --arg ip "$neutron_ip" -c '
                    .ports[] | 
                    select(.NAME == $name and ."MAC Address" == $mac and ."Fixed IP Addresses"[].ip_address == $ip) | .ID
                ')

                if [[ -n "$sprut_port_id_on_router" ]]; then
                    echo "Port $sprut_port_id_on_router is attached to router $sprut_router_id"
                else
                    echo "Attaching existing port $sprut_port_id to router $sprut_router_id"
                    attach_port_cmd="openstack router add port $sprut_router_id $sprut_port_id"
                    echo "Running command: $attach_port_cmd"
                    $attach_port_cmd
                fi
                
            fi
            

            neutron_to_sprut_router_ports["$neutron_ip"]="$sprut_port_id"
        done
    done
}

compare_and_create_router_to_network_interfaces
print_map_as_table neutron_to_sprut_router_ports "Neutron to Sprut Router Ports" "Neutron Router Port ID" "Sprut Router Port ID"

echo "STAGE 3 complete: Missing Sprut objects created"
echo "**********************************************************************************"