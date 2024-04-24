#! bin/bash

check_network() {
	re='^[0-9]+$'
	message=$(Netsh wlan show profile key=clear)
	if [[ -z "$1" ]]; then
		# Proccess mensage so the user can select the Profile name easily
		processed=$(echo "$message" | awk '/User profiles/{flag=1; print; next} flag{if (/^[[:space:]]*$/ || /^-------------$/) {print $0} else {print "[" ++i "]" $0}} END{print "[0] To Cancel"}')

		# Saves the last value of i so that we can verify for incorrect user input later on
		last_value_of_i=$(echo "$message" | awk '/User profiles/{flag=1; print; next} flag{if (/^[[:space:]]*$/ || /^-------------$/) {} else{++i}} END{print i}')

		# Backup original IFS
		OIFS=$IFS
		# Change IFS for read
		IFS=$'\n'
		# execute read
		read -d '' -a last_value_of_i <<< "$last_value_of_i"
		last_value_of_i=${last_value_of_i[1]}

		# Send the processed list to the user
		clear
		echo "$processed"

		### Save the list of te profile names, without the "[i]    All User Profile     :"
		profile_names=$(echo "$processed" | awk '/^\[[0-9]+\]/ { sub(/^\[[0-9]+\]\s+All User Profile\s+:\s+/, ""); print }')
		
		# Save the profile names as an array
		read -d '' -a profile_names <<< "$profile_names"
		# Removes static "[0] To Cancel"
		profile_names=("${profile_names[@]:0:$((${#profile_names[@]}-1))}")

		# Ask the user to select a valid option
		echo "Select the Profile: 1 - $last_value_of_i, or 0 to cancel."
		read user_input
		# TODO: Fix choosing 0 not canceling action
		while ! [[ $user_input =~ $re && $user_input -ge 0 && $user_input -le $last_value_of_i ]]; do
			# TODO: Add message depending on what the user did wrong
			echo "try again"
			read user_input
		done

		# Since the user input is 1 base, we need to offset to -1
		user_input=$(($user_input-1))

		# Call function to give the details of the network using the Profile name
		clear
		# TODO: BUGFIX, when the profile name has a special charater it breaks. Might be a problem on the program used itself.
		Netsh wlan show profile name=${profile_names[$user_input]} key=clear

		# Change IFS back to original
		IFS=$OIFS
	else
		Netsh wlan show profile name=$1 key=clear
	fi
}

check_network $1
