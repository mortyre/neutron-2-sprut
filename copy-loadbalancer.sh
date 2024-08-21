#!/bin/bash



echo "


██╗      ██████╗  █████╗ ██████╗ ██████╗  █████╗ ██╗      █████╗ ███╗   ██╗ ██████╗███████╗██████╗                    
██║     ██╔═══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗██║     ██╔══██╗████╗  ██║██╔════╝██╔════╝██╔══██╗                   
██║     ██║   ██║███████║██║  ██║██████╔╝███████║██║     ███████║██╔██╗ ██║██║     █████╗  ██████╔╝                   
██║     ██║   ██║██╔══██║██║  ██║██╔══██╗██╔══██║██║     ██╔══██║██║╚██╗██║██║     ██╔══╝  ██╔══██╗                   
███████╗╚██████╔╝██║  ██║██████╔╝██████╔╝██║  ██║███████╗██║  ██║██║ ╚████║╚██████╗███████╗██║  ██║                   
╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝╚══════╝╚═╝  ╚═╝                   
                                                                                                                      
███╗   ███╗██╗ ██████╗ ██████╗  █████╗ ████████╗██╗ ██████╗ ███╗   ██╗    ███████╗ ██████╗██████╗ ██╗██████╗ ████████╗
████╗ ████║██║██╔════╝ ██╔══██╗██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║    ██╔════╝██╔════╝██╔══██╗██║██╔══██╗╚══██╔══╝
██╔████╔██║██║██║  ███╗██████╔╝███████║   ██║   ██║██║   ██║██╔██╗ ██║    ███████╗██║     ██████╔╝██║██████╔╝   ██║   
██║╚██╔╝██║██║██║   ██║██╔══██╗██╔══██║   ██║   ██║██║   ██║██║╚██╗██║    ╚════██║██║     ██╔══██╗██║██╔═══╝    ██║   
██║ ╚═╝ ██║██║╚██████╔╝██║  ██║██║  ██║   ██║   ██║╚██████╔╝██║ ╚████║    ███████║╚██████╗██║  ██║██║██║        ██║   
╚═╝     ╚═╝╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝    ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝        ╚═╝   
                                                                                                                                                                                                                                        

Input file format:
neutron loadbalancer name1,sprut network1, sprut subnetwork1
neutron loadbalancer name2,sprut network2, sprut subnetwork2
...
"

if [ -z "$1" ]; then
    echo "Error: No input file provided."
    exit 1
fi

OUTPUT_FILE="copy-loadbalancer-script-output-config.csv"

# Initialize maps
declare -A neutron_to_sprut_lb
declare -A sprut_networks
declare -A sprut_subnetworks
declare -A neutron_lbs

# Read config file and populate dictionary
echo "Reading config file $1"

while IFS=',' read -r neutron_lb_name sprut_network sprut_subnetwork floating_ip_uuid || [ -n "$neutron_lb_name" ]; do
    neutron_lbs["$neutron_lb_name"]="$sprut_network,$sprut_subnetwork,$floating_ip_uuid"
done < "$1"

echo "Config file read complete."

# STAGE 1: Collecting Information
echo "STAGE 1: Collecting information about neutron loadbalancers and sprut networks"

# Check that loadbalancers exist
echo "Checking that Neutron loadbalancers exist..."
for neutron_lb_name in "${!neutron_lbs[@]}"; do
    echo "Checking loadbalancer: $neutron_lb_name"
    neutron_lb_id=$(openstack loadbalancer show "$neutron_lb_name" -f value -c id)
    if [[ -z "$neutron_lb_id" ]]; then
        echo "Error: Neutron loadbalancer '$neutron_lb_name' does not exist."
        exit 1
    fi
    neutron_lb_ids["$neutron_lb_name"]="$neutron_lb_id"
done

echo "Neutron loadbalancer check complete."

# Check that networks and subnetworks exist in Sprut
echo "Checking that Sprut networks and subnetworks exist..."
for neutron_lb_name in "${!neutron_lbs[@]}"; do
    IFS=',' read -r sprut_network sprut_subnetwork floating_ip_uuid <<< "${neutron_lbs[$neutron_lb_name]}"
    
    sprut_network_id=$(openstack network show "$sprut_network" -f value -c id)
    sprut_subnetwork_id=$(openstack subnet show "$sprut_subnetwork" -f value -c id)
    
    if [[ -z "$sprut_network_id" ]] || [[ -z "$sprut_subnetwork_id" ]]; then
        echo "Error: Sprut network or subnet for '$neutron_lb_name' does not exist."
        exit 1
    fi

    sprut_networks["$sprut_network"]="$sprut_network_id"
    sprut_subnetworks["$sprut_subnetwork"]="$sprut_subnetwork_id"
    
    # Check if floating IP exists
    if [[ -n "$floating_ip_uuid" ]]; then
        floating_ip_exists=$(openstack floating ip show "$floating_ip_uuid" -f value -c id)
        if [[ -z "$floating_ip_exists" ]]; then
            echo "Warning: Floating IP '$floating_ip_uuid' for '$neutron_lb_name' does not exist. Ignoring."
            floating_ip_uuid=""
        fi
    fi
    
    neutron_lbs["$neutron_lb_name"]="$sprut_network,$sprut_subnetwork,$floating_ip_uuid"
done

echo "Sprut network and subnet check complete."

# STAGE 2: Collecting Information about Sprut Loadbalancers
echo "STAGE 2: Collecting information about sprut loadbalancers"

for neutron_lb_name in "${!neutron_lbs[@]}"; do
    IFS=',' read -r sprut_network sprut_subnetwork floating_ip_uuid <<< "${neutron_lbs[$neutron_lb_name]}"

    neutron_lb_info=$(openstack loadbalancer show "$neutron_lb_name" -f json)
    neutron_vip_subnet_id=$(echo "$neutron_lb_info" | jq -r '.vip_subnet_id')
    sprut_subnet_cidr=$(openstack subnet show "$sprut_subnetwork" -f value -c cidr)

    neutron_subnet_cidr=$(openstack subnet show "$neutron_vip_subnet_id" -f value -c cidr)
    
    if [[ "$neutron_subnet_cidr" != "$sprut_subnet_cidr" ]]; then
        echo "Error: CIDR mismatch for loadbalancer '$neutron_lb_name'. Neutron: $neutron_subnet_cidr, Sprut: $sprut_subnet_cidr"
        exit 1
    fi
    
    sprut_lb_name="${neutron_lb_name}-sprut"
    sprut_lb_id=$(openstack loadbalancer show "$sprut_lb_name" -f value -c id)

    if [[ -z "$sprut_lb_id" ]]; then
        echo "Sprut loadbalancer '$sprut_lb_name' does not exist. It will be created."
    else
        echo "Sprut loadbalancer '$sprut_lb_name' already exists."
    fi
    
    neutron_to_sprut_lb["$neutron_lb_name"]="$sprut_lb_id"
done


octavia_api_base="https://public.infra.mail.ru:9876/v2.0"

token=$(openstack token issue -c id -f value)

# STAGE 3: Creating Missing Loadbalancers
echo "STAGE 3: Creating missing loadbalancers in Sprut"
for neutron_lb_name in "${!neutron_lbs[@]}"; do
    IFS=',' read -r sprut_network sprut_subnetwork floating_ip_uuid <<< "${neutron_lbs[$neutron_lb_name]}"
    
    sprut_lb_name="${neutron_lb_name}-sprut"
    sprut_lb_id="${neutron_to_sprut_lb[$neutron_lb_name]}"

        if [[ -z "$sprut_lb_id" ]]; then
        neutron_lb_info=$(openstack loadbalancer show "$neutron_lb_name" -f json)
        neutron_vip_address=$(echo "$neutron_lb_info" | jq -r '.vip_address')
        
        echo "Creating loadbalancer '$sprut_lb_name' in Sprut network"
        request_body=$(jq -n --arg name "$sprut_lb_name" \
                          --arg vip_address "$neutron_vip_address" \
                          --arg vip_subnet_id "${sprut_subnetworks[$sprut_subnetwork]}" \
                          --arg vip_network_id "${sprut_networks[$sprut_network]}" \
                          '{
                            loadbalancer: {
                              name: $name,
                              vip_address: $vip_address,
                              vip_subnet_id: $vip_subnet_id,
                              vip_network_id: $vip_network_id
                            }
                          }')
        
        curl_response=$(curl -s -X POST "${octavia_api_base}/lbaas/loadbalancers" \
            -H "Content-Type: application/json" \
            -H "X-Auth-Token: $token" \
            -d "$request_body")

        echo "$curl_response" | jq .

        sprut_lb_id=$(echo "$curl_response" | jq -r '.loadbalancer.id')
        
        if [[ -n "$floating_ip_uuid" ]]; then
            echo "Assigning floating IP '$floating_ip_uuid' to loadbalancer '$sprut_lb_name'"
            openstack floating ip set --port "$sprut_lb_id" "$floating_ip_uuid"
        fi
    fi
    
    echo "$sprut_lb_name >> "$OUTPUT_FILE""
done

echo "Script execution completed. Check $OUTPUT_FILE for details."