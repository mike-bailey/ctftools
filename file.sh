FILE=$1
text=$(file $1| cut -d: -f2|sed 's/^ //g')



asciitext() {
	while IFS='' read -r line || [[ -n "$line" ]]; do
		for word in $line; do
			echo "Checking $word"
	        ruby textanalysis.rb  "$word" quiet > $resultsdir/textresults.txt
	    done
	done < "$FILE"
}

pics() {
 identify -verbose $FILE > $resultsdir/exifdata.txt
 mkdir -p $resultsdir/foremost
 foremost -o $resultsdir/foremost -c foremost.conf  $FILE
 echo "Identified"
}

RANDSESSION=$RANDOM$RANDOM$RANDOM
resultsdir="./results/$RANDSESSION"
mkdir -p $resultsdir
echo "RESULTS AT $resultsdir"

echo "$resultsdir"
if [ "$text" == "ASCII text" ]; then
	asciitext
elif [ "${text/image data}" != "$text" ]; then
	pics
else
	echo "Unsupported type $text"
fi