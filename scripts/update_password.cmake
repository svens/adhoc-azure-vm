string(RANDOM LENGTH 20 ALPHABET "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*" NEW_PASSWORD)
execute_process(
	COMMAND az vm user update
		--username ${VM_USER}
		--password ${NEW_PASSWORD}
		--ids ${VM_IDS}
	RESULT_VARIABLE UPDATE_RESULT
	OUTPUT_QUIET
	ERROR_VARIABLE UPDATE_ERROR
)

if(UPDATE_RESULT EQUAL 0)
	message("New password: ${NEW_PASSWORD}")
	message("WARNING: This password is shown only once. Copy it now!")
else()
	message(FATAL_ERROR "Failed to update password: ${UPDATE_ERROR}")
endif()
