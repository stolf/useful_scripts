#/bin/bash

# Lightweight bash script that processes ping's output in realtime and
# suppresses normal ping responses and prints instead only on packets lost
# and errors. It handles SIGQUIT correctly so that it can be used to invoke
# pings summary lines mid run. It also allows for the ping summary
# footer to be printed at the end.

# This script focus's on being fork light. It only forks ping once to do the
# actuall ICMP work, and date per loss block. Everything else is bash internals.

# Note the time stamps reported when an ICMP reply is recieved, and the lost 
# block is calculated.





# Authors Chris Browning <chris.browning@lightwire.co.nz>

# Copyright 2013 Lightwire Limited

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

# http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


last=0
prev=0
printit=0


ping $@ | while read i
trap "" SIGQUIT
trap "" SIGINT
do
	# Deal with printing summary at the end
	if [ $printit -eq 1 ]; then

		# Add any additional loss based on summary data
		val=${i// packets transmitted*/}
		if [[ $val != *[!0-9]* ]]; then
			if [ -n "$val" ]; then
				if [ "$val" -ne "$last" ]; then
					echo "`date +'%F %T'`: Lost $((val-last)) additional packets at quit ($((last+1)) to $((val)))"
				fi
			fi
		fi

		# Header finished exit
		if [ -z "$i" ]; then
			exit 0
		fi

		# Print summary data
		echo $i
		continue
	fi

	# Pull the request id
	val=${i//* icmp_req=/}
	val=${val// */}

	# Detect and deal with the Ping Header
	if [ "$val" == "PING" ]; then
		continue
	fi

	# Detect and deal with start of Ping Summary
	if [ -z "$val" ]; then
		echo $i
		printit=1
		continue
	fi

	# Deal with ICMP error responses (print them to screen)
	if [[ $val != *[!0-9]* ]]; then
		# Normal response
		if [ "$((val-1))" -ne "$last" ]; then
			echo "`date +'%F %T'`: Lost $((val-1-last)) packets ($((last+1)) to $((val-1)))"
		fi
		last=$val
	else
		echo $i
	fi
done
