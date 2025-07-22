_make_password()
{
    echo ${RANDOM}x${RANDOM}+${RANDOM} | base64
}

_validate()
{
    az deployment sub validate \
        --template-file template/main.bicep \
        --location northeurope \
        --parameters \
            os_type=$1 \
            username=$USER \
            password=$(_make_password) \
            login_ip=$(curl --ipv4 --silent ifconfig.me)
}

_deploy()
{
    az deployment sub create \
        --template-file template/main.bicep \
        --location northeurope \
        --parameters \
            os_type=$1 \
            username=$USER \
            password=$(_make_password) \
            login_ip=$(curl --ipv4 --silent ifconfig.me)
}

_vm_list()
{
    os=$(echo $1 | cut -d'-' -f1)
    variant=$(echo $1 | cut -d'-' -f2)
    az vm list --resource-group ${USER}-${os}-${variant} --query "[].id" -o tsv
}

_show()
{
    az vm list-ip-addresses --output yamlc \
        --ids $(_vm_list $1) \
        --query "[].{Host:virtualMachine.name, HostName:virtualMachine.network.publicIpAddresses[0].ipAddress}"
}

_passwd()
{
    printf "Password: "
    read -r password
    az vm user update \
        --username $USER \
        --password $password \
        --ids $(_vm_list $1)
}

_start()
{
    az vm start --ids $(_vm_list $1)
}

_stop()
{
    az vm stop --ids $(_vm_list $1)
}

_deallocate()
{
    az vm deallocate --ids $(_vm_list $1)
}
