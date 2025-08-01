cmake_minimum_required(VERSION 3.10)
project(adhoc-azure-vm NONE)

# command line settings
if(NOT VM_PROJECT)
	set(VM_PROJECT "$ENV{USER}")
endif()
if(NOT VM_USER)
	set(VM_USER "$ENV{USER}")
endif()
if(NOT VM_OS)
	set(VM_OS "linux")
endif()
if(NOT VM_VARIANT)
	set(VM_VARIANT "dev")
endif()
if(NOT VM_LOCATION)
	set(VM_LOCATION "northeurope")
endif()

set(VM_PROJECT "${VM_PROJECT}" CACHE STRING "Project name")
set(VM_USER "${VM_USER}" CACHE STRING "Username")
set(VM_OS "${VM_OS}" CACHE STRING "Operating system (linux/windows)")
set(VM_VARIANT "${VM_VARIANT}" CACHE STRING "Variant (dev/core)")
set(VM_LOCATION "${VM_LOCATION}" CACHE STRING "Azure location")

# derived settings
set(VM_RESOURCE "${VM_PROJECT}-${VM_OS}-${VM_VARIANT}" CACHE STRING "Resource name")

# login IP (IPv4)
if(NOT DEFINED VM_LOGIN_IP)
	execute_process(
		COMMAND curl --ipv4 --silent ifconfig.me
		OUTPUT_VARIABLE VM_LOGIN_IP_RAW
		OUTPUT_STRIP_TRAILING_WHITESPACE
	)
	set(VM_LOGIN_IP "${VM_LOGIN_IP_RAW}" CACHE STRING "Login IP address")
endif()

# ssh keys
set(SSH_PRIVATE_KEY "${CMAKE_CURRENT_BINARY_DIR}/ssh_key" CACHE STRING "SSH private key path")
set(SSH_PUBLIC_KEY "${CMAKE_CURRENT_BINARY_DIR}/ssh_key.pub" CACHE STRING "SSH public key path")
if(NOT EXISTS "${SSH_PRIVATE_KEY}")
	message(STATUS "Generating SSH key pair...")
	execute_process(
		COMMAND ssh-keygen -t rsa -b 4096 -f "${SSH_PRIVATE_KEY}" -N ""
		RESULT_VARIABLE SSH_KEYGEN_RESULT
	)
	if(NOT SSH_KEYGEN_RESULT EQUAL 0)
		message(FATAL_ERROR "Failed to generate SSH keys")
	endif()
endif()
file(READ "${SSH_PUBLIC_KEY}" VM_SSH_KEY)
string(STRIP "${VM_SSH_KEY}" VM_SSH_KEY)

file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/template")

# generate bicep and cloud-init files
configure_file(
	"${CMAKE_SOURCE_DIR}/template/cloud-init.yaml.in"
	"${CMAKE_CURRENT_BINARY_DIR}/template/cloud-init.yaml"
	@ONLY
)
configure_file(
	"${CMAKE_SOURCE_DIR}/template/main.bicep.in"
	"${CMAKE_CURRENT_BINARY_DIR}/template/main.bicep"
	@ONLY
)
configure_file(
	"${CMAKE_SOURCE_DIR}/template/net.bicep.in"
	"${CMAKE_CURRENT_BINARY_DIR}/template/net.bicep"
	@ONLY
)
configure_file(
	"${CMAKE_SOURCE_DIR}/template/vm.bicep.in"
	"${CMAKE_CURRENT_BINARY_DIR}/template/vm.bicep"
	@ONLY
)

# deploy VM (during configure step)
if(NOT DEFINED VM_IP)
	message(STATUS "Deploying VM...")

	string(RANDOM LENGTH 20 ALPHABET "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*" DEPLOY_PASSWORD)
	execute_process(
		COMMAND az deployment sub create
			--name "${VM_LOCATION}-vm-deployment"
			--template-file "${CMAKE_CURRENT_BINARY_DIR}/template/main.bicep"
			--location "${VM_LOCATION}"
			--parameters password=${DEPLOY_PASSWORD}
		RESULT_VARIABLE DEPLOY_RESULT
		OUTPUT_QUIET
	)

	if(DEPLOY_RESULT EQUAL 0)
		execute_process(
			COMMAND az vm list-ip-addresses
				--resource-group "${VM_RESOURCE}"
				--query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress"
				--output tsv
			OUTPUT_VARIABLE VM_IP_RAW
			OUTPUT_STRIP_TRAILING_WHITESPACE
		)
		set(VM_IP "${VM_IP_RAW}" CACHE STRING "VM IP address")

		execute_process(
			COMMAND az vm list
				--resource-group "${VM_RESOURCE}"
				--query "[].id"
				--output tsv
			OUTPUT_VARIABLE VM_IDS_RAW
			OUTPUT_STRIP_TRAILING_WHITESPACE
		)
		set(VM_IDS "${VM_IDS_RAW}" CACHE STRING "VM resource IDs")

		# Generate vm.conf with all variables
		file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/vm.conf"
			"VM_PROJECT=${VM_PROJECT}\n"
			"VM_OS=${VM_OS}\n"
			"VM_VARIANT=${VM_VARIANT}\n"
			"VM_RESOURCE=${VM_RESOURCE}\n"
			"VM_LOCATION=${VM_LOCATION}\n"
			"VM_USER=${VM_USER}\n"
			"VM_LOGIN_IP=${VM_LOGIN_IP}\n"
			"VM_IP=${VM_IP}\n"
			"VM_IDS=${VM_IDS}\n"
			"SSH_PRIVATE_KEY=${SSH_PRIVATE_KEY}\n"
			"SSH_PUBLIC_KEY=${SSH_PUBLIC_KEY}\n"
		)

		# Generate SSH/RDP configs
		configure_file(
			"${CMAKE_SOURCE_DIR}/connection/ssh_config.in"
			"${CMAKE_CURRENT_BINARY_DIR}/ssh_config"
			@ONLY
		)
		if(VM_OS STREQUAL "windows")
			configure_file(
				"${CMAKE_SOURCE_DIR}/connection/rdp.in"
				"${CMAKE_CURRENT_BINARY_DIR}/${VM_PROJECT}.rdp"
				@ONLY
			)
		endif()

		message(STATUS "VM[${VM_IDS}] deployed with IP: ${VM_IP}")
	else()
		message(WARNING "VM deployment failed")
	endif()
endif()


add_custom_target(rm
	COMMAND az group delete --resource-group ${VM_RESOURCE} --yes --no-wait
	COMMENT "Remove all Azure resources"
	USES_TERMINAL
)

add_custom_target(passwd
	COMMAND ${CMAKE_COMMAND}
		-DVM_USER=${VM_USER}
		-DVM_IDS=${VM_IDS}
		-P "${CMAKE_SOURCE_DIR}/scripts/update_password.cmake"
	COMMENT "Generate and set new random VM password"
	USES_TERMINAL
)

add_custom_target(start
	COMMAND az vm start --ids ${VM_IDS}
	COMMENT "Start VM"
)

add_custom_target(stop
	COMMAND az vm stop --ids ${VM_IDS}
	COMMENT "Stop VM"
)

add_custom_target(show
	COMMAND ${CMAKE_COMMAND} -E cat vm.conf
	COMMENT "Show VM variables"
)
