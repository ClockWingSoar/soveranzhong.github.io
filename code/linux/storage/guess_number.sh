#!/bin/bash

# Function to generate a random number between 1 and 100
generate_target() {
    echo $((RANDOM % 100 + 1))
}

# Main game logic
play_game() {
    local target=$(generate_target)
    local guess=0
    local attempts=0

    echo "Welcome to the Number Guessing Game!"
    echo "I have selected a number between 1 and 100."
    echo "Can you guess what it is?"

    while [[ $guess -ne $target ]]; do
        read -p "Enter your guess: " guess

        # Validate input is a number
        if ! [[ "$guess" =~ ^[0-9]+$ ]]; then
            echo "Please enter a valid integer."
            continue
        fi

        ((attempts++))

        if [[ $guess -lt $target ]]; then
            echo "Too small! Try again."
        elif [[ $guess -gt $target ]]; then
            echo "Too big! Try again."
        else
            echo "Congratulations! You guessed the number $target in $attempts attempts."
        fi
    done
}

# Start the game
play_game
