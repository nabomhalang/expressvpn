function prompt_hidden_input() {
    echo -en $1

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

    printf -v "$2" '%s' "$input"
}

# function prompt_input() {
# }