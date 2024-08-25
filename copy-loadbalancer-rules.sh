
echo "

 ██████╗ ██████╗ ██████╗ ██╗   ██╗    ██╗      ██████╗  █████╗ ██████╗ ██████╗  █████╗ ██╗      █████╗ ███╗   ██╗ ██████╗███████╗██████╗ 
██╔════╝██╔═══██╗██╔══██╗╚██╗ ██╔╝    ██║     ██╔═══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗██║     ██╔══██╗████╗  ██║██╔════╝██╔════╝██╔══██╗
██║     ██║   ██║██████╔╝ ╚████╔╝     ██║     ██║   ██║███████║██║  ██║██████╔╝███████║██║     ███████║██╔██╗ ██║██║     █████╗  ██████╔╝
██║     ██║   ██║██╔═══╝   ╚██╔╝      ██║     ██║   ██║██╔══██║██║  ██║██╔══██╗██╔══██║██║     ██╔══██║██║╚██╗██║██║     ██╔══╝  ██╔══██╗
╚██████╗╚██████╔╝██║        ██║       ███████╗╚██████╔╝██║  ██║██████╔╝██████╔╝██║  ██║███████╗██║  ██║██║ ╚████║╚██████╗███████╗██║  ██║
 ╚═════╝ ╚═════╝ ╚═╝        ╚═╝       ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝╚══════╝╚═╝  ╚═╝
                                                                                                                                         
██████╗ ██╗   ██╗██╗     ███████╗███████╗                                                                                                
██╔══██╗██║   ██║██║     ██╔════╝██╔════╝                                                                                                
██████╔╝██║   ██║██║     █████╗  ███████╗                                                                                                
██╔══██╗██║   ██║██║     ██╔══╝  ╚════██║                                                                                                
██║  ██║╚██████╔╝███████╗███████╗███████║                                                                                                
╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝╚══════╝                                                                                                
                                                                                                                                         

"
#!/bin/bash

# Config file from the previous script
CONFIG_FILE="copy-loadbalancer-script-output-config.csv"

# Initialize maps
declare -A neutron_to_sprut_lb_name
declare -A neutron_to_sprut_lb_id
declare -A neutron_to_sprut_listener_id
declare -A neutron_to_sprut_pool_id
declare -A neutron_to_sprut_member_id
declare -A neutron_to_sprut_healthmonitor_id

declare -A neutron_listener_info_map
declare -A neutron_pool_info_map
declare -A neutron_member_info_map
declare -A neutron_healthmonitor_info_map

declare -A neutron_to_sprut_network_id
declare -A neutron_to_sprut_subnetwork_id

# Function to print dictionary as table
print_map_as_table() {
    local -n map=$1
    local title=$2
    local column1=$3
    local column2=$4

    echo "====================================="
    echo "$title"
    echo "====================================="
    printf "%-40s | %-40s\n" "$column1" "$column2"
    echo "-------------------------------------|-------------------------------------"
    for key in "${!map[@]}"; do
        printf "%-40s | %-40s\n" "$key" "${map[$key]}"
    done
    echo "====================================="
    echo ""
}

# Read config file and populate dictionary
echo "Reading config file..."
while IFS=',' read -r sprut_lb_name; do
    if [[ "$sprut_lb_name" == "sprut_lb_name" ]]; then
        continue
    fi

    # Remove "-sprut" postfix to get the corresponding Neutron LB name
    neutron_lb_name="${sprut_lb_name%-sprut}"
    neutron_to_sprut_lb_name["$neutron_lb_name"]="$sprut_lb_name"
done < "$CONFIG_FILE"
echo "Config file read complete."

print_map_as_table neutron_to_sprut_lb_name "Neutron to Sprut Load Balancers" "Neutron LB Name" "Sprut LB Name"

# STAGE 1: Collect information about Neutron
echo "STAGE 1: Collect information about Neutron"

for neutron_lb_name in "${!neutron_to_sprut_lb_name[@]}"; do
    echo "Collecting information for Neutron load balancer: $neutron_lb_name"

    # Load balancer info
    neutron_lb_info=$(openstack loadbalancer show "$neutron_lb_name" -f json)
    neutron_lb_id=$(echo "$neutron_lb_info" | jq -r '.id')

    neutron_lb_vip_subnet_id=$(echo "$neutron_lb_info" | jq -r '.vip_subnet_id')

    echo "Neutron load balancer info for $neutron_lb_name:"
    echo "$neutron_lb_info" | jq .

    # Split listeners and pools strings into arrays
    neutron_listeners=$(echo "$neutron_lb_info" | jq -r '.listeners' | tr '\n' ' ' | tr ' ' '\n')
    neutron_pools=$(echo "$neutron_lb_info" | jq -r '.pools' | tr '\n' ' ' | tr ' ' '\n')

    # Store Listener Info in Separate Dictionary
    for neutron_listener_id in $neutron_listeners; do
        neutron_listener_info=$(openstack loadbalancer listener show "$neutron_listener_id" -f json)
        neutron_listener_info_map["$neutron_listener_id"]="$neutron_listener_info"
        neutron_to_sprut_listener_id["$neutron_listener_id"]=""

        echo "Neutron listener info for $neutron_listener_id:"
        echo "$neutron_listener_info" | jq .
    done

    # Store Pool Info in Separate Dictionary
    for neutron_pool_id in $neutron_pools; do
        neutron_pool_info=$(openstack loadbalancer pool show "$neutron_pool_id" -f json)
        neutron_pool_info_map["$neutron_pool_id"]="$neutron_pool_info"
        neutron_to_sprut_pool_id["$neutron_pool_id"]=""

        echo "Neutron pool info for $neutron_pool_id:"
        echo "$neutron_pool_info" | jq .

        # Split members string into array
        neutron_members=$(echo "$neutron_pool_info" | jq -r '.members' | tr '\n' ' ' | tr ' ' '\n')

        # Store Member Info in Separate Dictionary
        for neutron_member_id in $neutron_members; do
            neutron_member_info=$(openstack loadbalancer member show "$neutron_pool_id" "$neutron_member_id" -f json)
            neutron_member_info_map["$neutron_member_id"]="$neutron_member_info"
            neutron_to_sprut_member_id["$neutron_member_id"]=""

            echo "Neutron member info for $neutron_member_id in pool $neutron_pool_id:"
            echo "$neutron_member_info" | jq .
        done

        # Store Health Monitor Info in Separate Dictionary
        neutron_healthmonitor_id=$(echo "$neutron_pool_info" | jq -r '.healthmonitor_id')
        if [ -n "$neutron_healthmonitor_id" ]; then
            neutron_healthmonitor_info=$(openstack loadbalancer healthmonitor show "$neutron_healthmonitor_id" -f json)
            neutron_healthmonitor_info_map["$neutron_healthmonitor_id"]="$neutron_healthmonitor_info"
            neutron_to_sprut_healthmonitor_id["$neutron_healthmonitor_id"]=""

            echo "Neutron health monitor info for $neutron_healthmonitor_id:"
            echo "$neutron_healthmonitor_info" | jq .
        fi
    done
done

print_map_as_table neutron_listener_info_map "Neutron Listeners Info" "Neutron Listener ID" "Listener Info (JSON)"
print_map_as_table neutron_pool_info_map "Neutron Pools Info" "Neutron Pool ID" "Pool Info (JSON)"
print_map_as_table neutron_member_info_map "Neutron Members Info" "Neutron Member ID" "Member Info (JSON)"
print_map_as_table neutron_healthmonitor_info_map "Neutron Health Monitors Info" "Neutron Health Monitor ID" "Health Monitor Info (JSON)"

# STAGE 2: Collect information about Sprut entities
echo "STAGE 2: Collect information about Sprut entities"

for neutron_lb_name in "${!neutron_to_sprut_lb_name[@]}"; do
    sprut_lb_name="${neutron_to_sprut_lb_name[$neutron_lb_name]}"
    echo "Collecting information for Sprut load balancer: $sprut_lb_name"

    sprut_lb_details=$(openstack loadbalancer show "$sprut_lb_name" -f json)

    # Load balancer ID
    sprut_lb_id=$(echo $sprut_lb_details | jq -r .id)
    if [ -z "$sprut_lb_id" ]; then
        echo "ERROR: Could not find Sprut load balancer ID for $sprut_lb_name. Skipping..."
        continue
    fi

    neutron_lb_details=$(openstack loadbalancer show "$neutron_lb_name" -f json)

    neutron_lb_id=$(echo $neutron_lb_details | jq -r .id)
    if [ -z "$neutron_lb_id" ]; then
        echo "ERROR: Could not find Neutron load balancer ID for $neutron_lb_id. Skipping..."
        continue
    fi

    neutron_to_sprut_lb_id["$neutron_lb_id"]="$sprut_lb_id"
    echo "Neutron loadbalancer ID for $neutron_lb_name: $neutron_lb_id"
    echo "Sprut load balancer ID for $sprut_lb_name: $sprut_lb_id"
    
    # network map
    sprut_network_id=$(echo $sprut_lb_details | jq -r .vip_network_id)
    neutron_network_id=$(echo $neutron_lb_details | jq -r .vip_network_id)
    neutron_to_sprut_network_id["$neutron_network_id"]="$sprut_network_id"

    # subnet map
    sprut_subnetwork_id=$(echo $sprut_lb_details | jq -r .vip_subnet_id)
    neutron_subnetwork_id=$(echo $neutron_lb_details | jq -r .vip_subnet_id)
    neutron_to_sprut_subnetwork_id["$neutron_subnetwork_id"]="$sprut_subnetwork_id"

    # Listeners
    sprut_listeners=$(openstack loadbalancer listener list --loadbalancer "$sprut_lb_id" -f json)
    echo "Sprut listeners for $sprut_lb_name:"
    echo "$sprut_listeners" | jq .

    for listener in $(echo "$sprut_listeners" | jq -r '.[] | @base64'); do
        _jq() {
            echo "${listener}" | base64 --decode | jq -r "${1}"
        }

        sprut_listener_id=$(_jq '.id')
        neutron_listener_id=$(echo "$neutron_listener_info_map" | jq -r --arg sprut_listener_id "$sprut_listener_id" 'keys[] | select(. == $sprut_listener_id)')
        if [ -z "$neutron_listener_id" ]; then
            echo "WARNING: No matching Neutron listener found for Sprut listener ID $sprut_listener_id. Skipping..."
            continue
        fi
        neutron_to_sprut_listener_id["$neutron_listener_id"]="$sprut_listener_id"
    done

    # Pools
    sprut_pools=$(openstack loadbalancer pool list --loadbalancer "$sprut_lb_id" -f json)
    echo "Sprut pools for $sprut_lb_name:"
    echo "$sprut_pools" | jq .

    for pool in $(echo "$sprut_pools" | jq -r '.[] | @base64'); do
        _jq() {
            echo "${pool}" | base64 --decode | jq -r "${1}"
        }

        sprut_pool_id=$(_jq '.id')
        neutron_pool_id=$(echo "$neutron_pool_info_map" | jq -r --arg sprut_pool_id "$sprut_pool_id" 'keys[] | select(. == $sprut_pool_id)')
        if [ -z "$neutron_pool_id" ]; then
            echo "WARNING: No matching Neutron pool found for Sprut pool ID $sprut_pool_id. Skipping..."
            continue
        fi
        neutron_to_sprut_pool_id["$neutron_pool_id"]="$sprut_pool_id"

        # Members
        sprut_members=$(openstack loadbalancer member list "$sprut_pool_id" -f json)
        echo "Sprut members for pool $sprut_pool_id:"
        echo "$sprut_members" | jq .

        for member in $(echo "$sprut_members" | jq -r '.[] | @base64'); do
            _jq() {
                echo "${member}" | base64 --decode | jq -r "${1}"
            }

            sprut_member_id=$(_jq '.id')
            neutron_member_id=$(echo "$neutron_member_info_map" | jq -r --arg sprut_member_id "$sprut_member_id" 'keys[] | select(. == $sprut_member_id)')
            if [ -z "$neutron_member_id" ]; then
                echo "WARNING: No matching Neutron member found for Sprut member ID $sprut_member_id. Skipping..."
                continue
            fi
            neutron_to_sprut_member_id["$neutron_member_id"]="$sprut_member_id"
        done

        # Health Monitor
        sprut_healthmonitor_id=$(openstack loadbalancer healthmonitor list --pool "$sprut_pool_id" -f value -c id)
        if [ -n "$sprut_healthmonitor_id" ]; then
            neutron_healthmonitor_id=$(echo "$neutron_pool_info_map" | jq -r '.healthmonitor_id')
            if [ -n "$neutron_healthmonitor_id" ]; then
                neutron_to_sprut_healthmonitor_id["$neutron_healthmonitor_id"]="$sprut_healthmonitor_id"
                echo "Sprut health monitor for pool $sprut_pool_id: $sprut_healthmonitor_id"
            else
                echo "WARNING: No matching Neutron health monitor found for Sprut health monitor ID $sprut_healthmonitor_id. Skipping..."
            fi
        fi
    done
done

print_map_as_table neutron_to_sprut_lb_id "Neutron to Sprut loadbalancers after STAGE 2" "Neutron loadbalancer ID" "Sprut Loadbalancer ID"
print_map_as_table neutron_to_sprut_listener_id "Neutron to Sprut Listeners after STAGE 2" "Neutron Listener ID" "Sprut Listener ID"
print_map_as_table neutron_to_sprut_pool_id "Neutron to Sprut Pools after STAGE 2" "Neutron Pool ID" "Sprut Pool ID"
print_map_as_table neutron_to_sprut_member_id "Neutron to Sprut Members after STAGE 2" "Neutron Member ID" "Sprut Member ID"
print_map_as_table neutron_to_sprut_healthmonitor_id "Neutron to Sprut Health Monitors after STAGE 2" "Neutron Health Monitor ID" "Sprut Health Monitor ID"
print_map_as_table neutron_to_sprut_network_id "Neutron to sprut network ids" "Neutron network id" "Sprut network id"
print_map_as_table neutron_to_sprut_subnetwork_id "Neutron to sprut subnet ids" "Neutron subnet id" "Sprut subnet id"

# API base URL and token
api_base_url="https://public.infra.mail.ru:9876/v2"
token=$(openstack token issue -c id -f value)

# Retry parameters
max_retries=3
retry_interval=5

# Helper function to make API requests with retry logic
make_api_request() {
    method=$1
    url=$2
    data=$3

    for ((i=1; i<=max_retries; i++)); do
        if [ -n "$data" ]; then
            response=$(curl -s -X "$method" "$url" \
                -H "Content-Type: application/json" \
                -H "X-Auth-Token: $token" \
                -d "$data")
        else
            response=$(curl -s -X "$method" "$url" \
                -H "Content-Type: application/json" \
                -H "X-Auth-Token: $token")
        fi

        if [ -n "$response" ] && ! echo "$response" | grep -q "Error"; then
            echo "$response"
            return
        else
            echo "Attempt $i/$max_retries failed. Retrying in $retry_interval seconds..."
            sleep $retry_interval
        fi
    done

    echo "Request failed after $max_retries attempts."
}



# STAGE 3: Create missing entities in Sprut
echo "STAGE 3: Create missing entities in Sprut"

# Create missing listeners
for neutron_listener_id in "${!neutron_listener_info_map[@]}"; do
    sprut_listener_id="${neutron_to_sprut_listener_id[$neutron_listener_id]}"

    if [ -z "$sprut_listener_id" ]; then
        echo "Copying neutron listener $neutron_listener_id"
        neutron_listener_info="${neutron_listener_info_map[$neutron_listener_id]}"

        neutron_lb_id=$(echo "$neutron_listener_info" | jq -r '.loadbalancers')
        sprut_lb_id="${neutron_to_sprut_lb_id[$neutron_lb_id]}"

        if [ -z "$sprut_lb_id" ]; then
            echo "ERROR: No Sprut load balancer found for Neutron load balancer ID $neutron_lb_id. Skipping listener creation..."
            continue
        fi

        protocol=$(echo "$neutron_listener_info" | jq -r '.protocol')
        protocol_port=$(echo "$neutron_listener_info" | jq -r '.protocol_port')
        listener_description=$(echo "$neutron_listener_info" | jq -r '.description')

        listener_name="${sprut_lb_name}_listener_${protocol}_${protocol_port}"

        request_body=$(jq -n --arg name "$listener_name" \
                              --arg protocol "$protocol" \
                              --arg protocol_port "$protocol_port" \
                              --arg description "$listener_description" \
                              --arg loadbalancer_id "$sprut_lb_id" \
            '{
                listener: {
                    name: $name,
                    protocol: $protocol,
                    protocol_port: $protocol_port,
                    description: $description,
                    loadbalancer_id: $loadbalancer_id
                }
            }')

        echo "Creating listener for Sprut load balancer $sprut_lb_id"
        echo "Running API request: POST $api_base_url/lbaas/listeners"
        echo "Request body: $request_body"
        response=$(make_api_request "POST" "$api_base_url/lbaas/listeners" "$request_body")
        echo "Request response: $response"
        sprut_listener_id=$(echo "$response" | jq -r '.listener.id')
        echo "Sprut listener ID: $sprut_listener_id"
        neutron_to_sprut_listener_id["$neutron_listener_id"]="$sprut_listener_id"
    else
        echo "Listener $sprut_listener_id already exists in Sprut."
    fi
done

sleep 10

# Create missing pools and members
for neutron_pool_id in "${!neutron_pool_info_map[@]}"; do
    sprut_pool_id="${neutron_to_sprut_pool_id[$neutron_pool_id]}"

    if [ -z "$sprut_pool_id" ]; then
        neutron_pool_info="${neutron_pool_info_map[$neutron_pool_id]}"
        
        neutron_listener_id=$(echo "$neutron_pool_info" | jq -r '.listeners')
        sprut_listener_id="${neutron_to_sprut_listener_id[$neutron_listener_id]}"

        if [ -z "$sprut_listener_id" ]; then
            echo "ERROR: No Sprut listener found for Neutron listener ID $neutron_listener_id. Skipping pool creation..."
            continue
        fi

        lb_algorithm=$(echo "$neutron_pool_info" | jq -r '.lb_algorithm')
        protocol=$(echo "$neutron_pool_info" | jq -r '.protocol')
        pool_name="${sprut_listener_id}_pool_${protocol}_${lb_algorithm}"

        request_body=$(jq -n --arg name "$pool_name" \
                              --arg protocol "$protocol" \
                              --arg lb_algorithm "$lb_algorithm" \
                              --arg listener_id "$sprut_listener_id" \
            '{
                pool: {
                    name: $name,
                    protocol: $protocol,
                    lb_algorithm: $lb_algorithm,
                    listener_id: $listener_id
                }
            }')

        echo "Creating pool for Sprut listener $sprut_listener_id"
        echo "Running API request: POST $api_base_url/lbaas/pools"
        echo "Request body: $request_body"
        response=$(make_api_request "POST" "$api_base_url/lbaas/pools" "$request_body")
        echo "Request response: $response"
        sprut_pool_id=$(echo "$response" | jq -r '.pool.id')
        echo "Sprut pool ID: $sprut_pool_id"
        
    else
        echo "Pool $sprut_pool_id already exists in Sprut."
    fi

    neutron_to_sprut_pool_id["$neutron_pool_id"]="$sprut_pool_id"

    # Now, handle members associated with this pool
    neutron_members=$(echo "$neutron_pool_info" | jq -r '.members' | tr '\n' ' ')
    for neutron_member_id in $neutron_members; do
        sleep 4
        sprut_member_id="${neutron_to_sprut_member_id[$neutron_member_id]}"

        if [ -z "$sprut_member_id" ]; then
            neutron_member_info="${neutron_member_info_map[$neutron_member_id]}"
            address=$(echo "$neutron_member_info" | jq -r '.address')
            protocol_port=$(echo "$neutron_member_info" | jq -r '.protocol_port')
            neutron_subnet_id=$(echo "$neutron_member_info" | jq -r '.subnet_id')
            sprut_subnet_id="${neutron_to_sprut_subnetwork_id[$neutron_subnet_id]}"
            weight=$(echo "$neutron_member_info" | jq -r '.weight')

            member_name="${sprut_pool_id}_member_${address}_${protocol_port}"

            request_body=$(jq -n --arg address "$address" \
                                  --arg protocol_port "$protocol_port" \
                                  --arg subnet_id "$sprut_subnet_id" \
                                  --arg weight "$weight" \
                                  --arg name "$member_name" \
                '{
                    member: {
                        name: $name,
                        address: $address,
                        protocol_port: $protocol_port,
                        subnet_id: $subnet_id,
                        weight: $weight
                    }
                }')

            echo "Creating member for Sprut pool $sprut_pool_id"
            echo "Running API request: POST $api_base_url/lbaas/pools/$sprut_pool_id/members"
            echo "Request body: $request_body"
            response=$(make_api_request "POST" "$api_base_url/lbaas/pools/$sprut_pool_id/members" "$request_body")
            echo "Request response: $response"
            sprut_member_id=$(echo "$response" | jq -r '.member.id')
            echo "Sprut member ID: $sprut_member_id"
            neutron_to_sprut_member_id["$neutron_member_id"]="$sprut_member_id"
        else
            echo "Member $sprut_member_id already exists in Sprut."
        fi
    done
done

sleep 10

# Create missing health monitors
for neutron_healthmonitor_id in "${!neutron_healthmonitor_info_map[@]}"; do
    sprut_healthmonitor_id="${neutron_to_sprut_healthmonitor_id[$neutron_healthmonitor_id]}"

    if [ -z "$sprut_healthmonitor_id" ]; then
        neutron_healthmonitor_info="${neutron_healthmonitor_info_map[$neutron_healthmonitor_id]}"
        delay=$(echo "$neutron_healthmonitor_info" | jq -r '.delay')
        timeout=$(echo "$neutron_healthmonitor_info" | jq -r '.timeout')
        max_retries=$(echo "$neutron_healthmonitor_info" | jq -r '.max_retries')
        type=$(echo "$neutron_healthmonitor_info" | jq -r '.type')
        neutron_pool_id=$(echo "$neutron_healthmonitor_info" | jq -r '.pools')
        sprut_pool_id="${neutron_to_sprut_pool_id[$neutron_pool_id]}"

        if [ -z "$sprut_pool_id" ]; then
            echo "ERROR: No Sprut pool found for Neutron pool ID $neutron_pool_id. Skipping health monitor creation..."
            continue
        fi

        monitor_name="${sprut_pool_id}_monitor_${type}_${delay}"

        request_body=$(jq -n --arg delay "$delay" \
                              --arg timeout "$timeout" \
                              --arg max_retries "$max_retries" \
                              --arg type "$type" \
                              --arg name "$monitor_name" \
                              --arg pool_id "$sprut_pool_id" \
            '{
                healthmonitor: {
                    delay: $delay,
                    timeout: $timeout,
                    max_retries: $max_retries,
                    type: $type,
                    pool_id: $pool_id,
                    name: $name
                }
            }')

        echo "Creating health monitor for Sprut pool $sprut_pool_id"
        echo "Running API request: POST $api_base_url/lbaas/healthmonitors"
        echo "Request body: $request_body"
        response=$(make_api_request "POST" "$api_base_url/lbaas/healthmonitors" "$request_body")
        echo "Request response: $response"
        sprut_healthmonitor_id=$(echo "$response" | jq -r '.healthmonitor.id')
        echo "Sprut health monitor ID: $sprut_healthmonitor_id"
        neutron_to_sprut_healthmonitor_id["$neutron_healthmonitor_id"]="$sprut_healthmonitor_id"
    else
        echo "Health monitor $sprut_healthmonitor_id already exists in Sprut."
    fi
done

echo "Load balancer rules copy process completed."
