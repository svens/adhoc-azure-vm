_check_args()
{
    if [ $# -eq 0 ] || [ -z "$1" ]; then
        echo "Usage: <prefix>-<os>-<variant>" >&2
        exit 1
    fi
}

_make_password()
{
    echo ${RANDOM}x${RANDOM}+${RANDOM} | base64
}

_validate()
{
    _check_args "$1"
    az deployment sub validate \
        --template-file template/main.bicep \
        --location northeurope \
        --parameters \
            resource="$1" \
            username="$USER" \
            password=$(_make_password) \
            login_ip=$(curl --ipv4 --silent ifconfig.me)
}

_deploy()
{
    _check_args "$1"
    az deployment sub create \
        --template-file template/main.bicep \
        --location northeurope \
        --parameters \
            resource="$1" \
            username="$USER" \
            password=$(_make_password) \
            login_ip=$(curl --ipv4 --silent ifconfig.me)
}

_vm_list()
{
    _check_args "$1"
    az vm list --resource-group "$1" --query "[].id" -o tsv
}

_show()
{
    _check_args "$1"
    az vm list-ip-addresses --output yamlc \
        --ids $(az vm list --resource-group "$1" --query "[].id" -o tsv) \
        --query "[].{Host:virtualMachine.name, HostName:virtualMachine.network.publicIpAddresses[0].ipAddress}"
}

_passwd()
{
    _check_args "$1"
    printf "Password: "
    read -r password
    az vm user update \
        --username $USER \
        --password $password \
        --ids $(az vm list --resource-group "$1" --query "[].id" -o tsv)
}

_start()
{
    _check_args "$1"
    az vm start --ids $(az vm list --resource-group "$1" --query "[].id" -o tsv)
}

_stop()
{
    _check_args "$1"
    az vm stop --ids $(az vm list --resource-group "$1" --query "[].id" -o tsv)
}

_deallocate()
{
    _check_args "$1"
    az vm deallocate --ids $(az vm list --resource-group "$1" --query "[].id" -o tsv)
}
