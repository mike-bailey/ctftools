FILE=$1

text=$(file $1| cut -d: -f2|sed 's/^ //g')

asciitext() {
	while IFS='' read -r line || [[ -n "$line" ]]; do
		for word in $line; do
			echo "Checking $word"
	        ruby textanalysis.rb  "$word" quiet
	    done
	done < "$FILE"
}

echo "$text"
if [ "$text" == "ASCII text" ]; then
	asciitext
fi

