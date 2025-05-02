#!/bin/sh

set -e


# Get the file path from the input
INPUT_GITHUB_VARIABLES="$1"

# echo "The file path is $INPUT_GITHUB_VARIABLES"

# Check if the file exists
if [ ! -f "$INPUT_GITHUB_VARIABLES" ]; then
  echo "Error: file $INPUT_GITHUB_VARIABLES does not exist."
  exit 1
fi


# Validate the JSON file format
if ! jq empty "$INPUT_GITHUB_VARIABLES" >/dev/null 2>&1; then
  echo "Error: JSON file $INPUT_GITHUB_VARIABLES is not in valid format."
  exit 1
fi

# Check if JSON contains at least one key-value pair with required attributes
if [ "$(jq length "$INPUT_GITHUB_VARIABLES")" -eq 0 ]; then
  echo "Error: JSON file does not contain any key-value pairs."
  exit 1
fi

# Validate that each key-value pair contains the required attributes
if ! jq -e 'all(.[]; has("key") and has("value"))' "$INPUT_GITHUB_VARIABLES"; then
  echo "Error: JSON file does not contain all required attributes (key, value)."
  exit 1
fi

# Set up GitHub params
PAT_TOKEN="$INPUT_GITHUB_PAT"
REPOSITORY_OWNER="$INPUT_REPOSITORY_OWNER"
REPOSITORY_NAME="$INPUT_REPOSITORY_NAME"
REPOSITORY="$REPOSITORY_OWNER/$REPOSITORY_NAME"

# echo "Repository: $REPOSITORY"
# Read the key-value pairs from the JSON file
KEY_VALUE_PAIRS=$(cat "$INPUT_GITHUB_VARIABLES")

response=$(curl -X GET  "https://api.github.com/repos/$REPOSITORY/actions/variables" \
        -H "Authorization: token $PAT_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        -w "%{http_code}" -o repo_vars.json)

# echo "Response: $response"
if [ "$response" -eq 200 ]; then
	echo "Request successful. Response saved to repo_vars.json."

	echo "Processing key-value pairs..."
	echo "$KEY_VALUE_PAIRS" | jq -c '.[]' | while read -r pair; do
		key=$(echo "$pair" | jq -r '.key')
		key_value=$(echo "$pair" | jq -r '.value')
		# echo "Key: $key, Value: $key_value"

		echo "Check for existence of $key variable"
		# Check if $key variable exists
		exists=$(cat repo_vars.json | jq -r --arg var "$key" '.variables[] | select(.name == $var) | .name')
		if [ "$exists" = "$key" ]; then
			echo "Variable $key exists. Will update it."
			response=$(curl -s -o /dev/null -w "%{http_code}" \
				-X PATCH -H "Authorization: token $PAT_TOKEN" \
     			-H "Accept: application/vnd.github.v3+json" \
				-d "{\"value\":\"$key_value\"}" \
     			"https://api.github.com/repos/$REPOSITORY/actions/variables/$key")
			# echo "Response: $response"
			if [ "$response" -ne 204 ]; then
				echo "Error: Failed to update the variable. HTTP status code: $response"
				exit 1
			fi

		else
			echo "Variable $key does not exist."
			response=$(curl -s -o /dev/null -w "%{http_code}" \
				-X POST -H "Authorization: token $PAT_TOKEN" \
     			-H "Accept: application/vnd.github.v3+json" \
     			-d "{\"name\":\"$key\",\"value\":\"$key_value\"}" \
     			"https://api.github.com/repos/$REPOSITORY/actions/variables")

			# echo "Response: $response"
			if [ "$response" -ne 201 ]; then
				echo "Error: Failed to update the variable. HTTP status code: $response"
				exit 1
			fi

		fi
	done
else
	echo "Error: Failure to retrieve variables from the GitHub repository. Request failed with status code $response."
	exit 1
fi
