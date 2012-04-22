#!/bin/sh

bin="$0"
src="$1" 
base="$2"
target="$3"


print_disclaimer () {
	echo "All Copyrights are acknowledged."
	echo "The information here is provided under the terms of the"
	echo "GNU Public License version 2 unless noted otherwise."
}

# insert a text in the middle at the position of a keyword
# using two methods:
#
# doinsert1() - split out the first part of the file
# doinsert2() - split out the second part of the file
#
# params:
#   from	- where to read the orig file from
#   to		- where to write the new file to
#   key		- keyword
#
doinsert1 () {
	from="$1"
	tox="$2"
	key="$3"
		cat $from \
			| awk -v m="$key" '
				BEGIN { pp=1; } 
				{ if (index($0, m) > 0) { pp=0; } } 
				{ if ( pp>0 ) print $0; } 
			'\
		> $tox
	diff -q $from $tox > /dev/null
	rv=$?
	return $rv
}	
doinsert2 () {
	from="$1"
	tox="$2"
	key="$3"
		cat $from \
			| awk -v m="$key" '
				BEGIN { pp=0; } 
				{ if ( pp>0 ) print $0; } 
				{ if (index($0, m) > 0) { pp=1; } } 
			'\
		>> $tox
}


#echo "Run: " $0 $root $up $upn $parent

	#echo "d="`pwd`", i=" $i
	t1=${target}_1;
	t2=${target}_2;
	to=$target
	if [ -f $src ]; then
		#echo "from " $i " to " $t2

		cp $src $t1

		# insert menu
		doinsert1 $t1 $t2 "@MENU@"
		v=$?
		if [ $v -eq 1 ]; then
			echo "<div id=\"mtree\">" >> $t2
			cat src/$base-menu.src \
				>> $t2
			echo "</div>" >> $t2
			doinsert2 $i $t2 "@MENU@"
		fi
		mv $t2 $t1

		# insert disclaimer
		doinsert1 $t1 $t2 "@DISCLAIMER@"
		v=$?
		if [ $v -eq 1 ]; then
			print_disclaimer >> $t2
			doinsert2 $t1 $t2 "@DISCLAIMER@" 
		fi
		mv $t2 $t1

		#echo "from " $t4 " to " $t5
		cat $t1 \
			| sed -e "s/@EMAIL@/afachat@gmx.de/g" \
			| sed -e "s%@XA@%http://www.floodgap.com/retrotech/xa/%g" \
			| sed -e "s%@CBMARC@%http://www.zimmers.net/anonftp/pub/cbm%g" \
			| sed -e "s/@[a-zA-Z0-9]*@//g" \
			> $t2
#			| awk '/@FOOTER@/ { print "<p>Return to <a href=\"%up%index.html\">Homepage</a></p>"; }
#				{ print $0; }' \
		mv $t2 $t1

		#echo "from " $t5 " to " $to
		if [ ! -f $to ]; then
			cp $t1 $to;
		else
			diff -q $to $t1
			if [ $? -eq 1 ]; then
				cp $t1 $to;
			fi
		fi;
		rm $i $t1
	fi;



