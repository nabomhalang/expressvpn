function prompt_hidden_input() {
    local prompt_message=$1
    local input_variable_name=$2
    
    echo -en "${prompt_message}"

    local input=""
    
    while IFS= read -r -s -n1 char; do
        if [[ $char == $'\0' || $char == $'\n' ]]; then
            break
        fi
        
        if [[ $char == $'\177' ]]; then
            if [[ -n $input ]]; then
                input=${input%?}
                printf '\b \b'
            fi
        else
            input+="$char"
            printf '*'
        fi
    done
    echo

    export $input_variable_name="$input"
}