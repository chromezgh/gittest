#!/bin/bash -x

# Function：compile the file then output the
# Usage: $0 <input.file> <output.file>
gcc_compile() {
	#gcc -c $1
	gcc -o $2 $1 
}

main() {
	gcc_compile $1 $2
}

main "$@"

