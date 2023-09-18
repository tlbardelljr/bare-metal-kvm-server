#!/bin/bash

   #################################################################
   #                                                               #
   #             tlbardelljr network VM host installer             #
   #           Copyright (C) 2023 Terry Bardell Jr                 #
   #       Licensed under the GNU General Public License 3.0       #
   #                                                               #
   #                                                               #
   #                                                               #
   #################################################################
   
my_options=(   "Curl"  "Git"  "Cockpit" "Webmin" "KVM"  "Boot-headless" "CIFS"  "Network-Bridge" "ssh"   )
preselection=( "true"  "true" "true"    "true"   "true" "false"         "false" "true"           "false" )
installer_name="tlbardelljr network VM installer"
sdoutColor=252
progressBarColor=226
headerColorFG=226
headerColorBG=124

export terminal=$(tty)

command -v apt > /dev/null && package_manager="apt-get"
command -v yum > /dev/null && package_manager="yum"
command -v zypper > /dev/null && package_manager="zypper"
 
Update () {
	sudo "$package_manager" update -y 
}
 
Curl () {
	sudo "$package_manager" install -y curl
}

Git () {
	sudo "$package_manager" install -y git 
}

Cockpit () {
	sudo "$package_manager" install -y cockpit cockpit-machines 
	sudo systemctl enable --now cockpit.socket 
}

Webmin () {
	case "$package_manager" in

	apt-get) 
		curl -o setup-repos.sh https://raw.githubusercontent.com/webmin/webmin/master/setup-repos.sh 
		sudo sh setup-repos.sh --force 
		sudo apt-get install --install-recommends webmin -y 
	    	;;
	yum) 
		sudo dnf install -y 'perl(IO::Pty)' 
		curl -o setup-repos.sh https://raw.githubusercontent.com/webmin/webmin/master/setup-repos.sh 
		sudo sh setup-repos.sh --force 
		sudo dnf install webmin -y 
		echo Enter password for webmim root account to login webmin?
		echo " "
		read -s password < $terminal
		sudo /usr/libexec/webmin/changepass.pl /etc/webmin root "$password"
	    	;;
	zypper)  
		sudo zypper install -y 'perl(IO::Pty)' 
		sudo zypper -n install apache2 
		sudo zypper -n install openssl openssl-devel 
		sudo zypper -n install perl perl-Net-SSLeay perl-Crypt-SSLeay 
		sudo wget http://prdownloads.sourceforge.net/webadmin/webmin-1.770-1.noarch.rpm 
		sudo rpm -ivh webmin-1.770-1.noarch.rpm 
		;;
	*) 	echo "Package manager error"
	   	;;
	esac
}

KVM () {
	case "$package_manager" in

	apt-get) 
		sudo "$package_manager" install -y qemu-kvm bridge-utils virt-manager 
		sudo "$package_manager" install -y libvirt-daemon-system libvirt-clients virtinst libguestfs-tools libosinfo-bin 
		echo Enter login name to add to libvirt group?
		read username < $terminal
		sudo usermod -aG libvirt "$username"
	    	;;
	yum) 
		sudo "$package_manager" install -y qemu-kvm bridge-utils virt-manager
		sudo "$package_manager" install -y libvirt virt-install libvirt-devel virt-top libguestfs-tools guestfs-tools 
		echo Enter login name to add to libvirt group?
		read username < $terminal
		sudo usermod -aG libvirt "$username"
		sudo systemctl start libvirtd
		sudo systemctl enable libvirtd
	    	;;
	zypper)  
		sudo zypper install -y -t pattern kvm_server kvm_tools 
		sudo zypper install -y libvirt libvirt-daemon libvirt-daemon-config-nwfilter
		sudo zypper install -y bridge-utils virt-manager
		sudo systemctl enable --now libvirtd
		
	    	;;
	*) 	echo "Package manager error"
	   	;;
	esac
}

Boot-headless () {
	sudo systemctl set-default multi-user.target 
	echo -e ' '
	echo "After reboot enter to boot GUI: sudo systemctl isolate graphical.target"
}

CIFS () {
	sudo "$package_manager" install -y cifs-utils 
}

Network-Bridge () {
	sudo nmcli connection show
	echo Enter network interface name to link to bridge br0?
	read interface_name < $terminal
	echo " "
	echo Use prefix length for network mask.
	echo 'Example 192.168.0.5 255.255.0.0 would be entered 192.168.0.5/16.'
	echo Enter ipadress with prefix length?
	read ip_address < $terminal
	echo Enter ip address for gateway?
	read gateway < $terminal
	
	sudo nmcli connection add type bridge autoconnect yes con-name br0 ifname br0
	sudo nmcli connection modify br0 ipv4.addresses "$ip_address" gw4 "$gateway" ipv4.method manual 
	sudo nmcli connection modify br0 ipv4.dns "$gateway" 
	sudo nmcli connection add type bridge-slave autoconnect yes con-name "$interface_name" ifname "$interface_name" master br0 
	sudo nmcli connection up br0
}

ssh () {
	case "$package_manager" in

	apt-get) 
		sudo "$package_manager" install openssh-server -y 
		sudo systemctl start ssh
		sudo systemctl enable ssh 
	    	;;
	yum) 
		sudo "$package_manager" install openssh-server -y 
		sudo systemctl start sshd
		sudo systemctl enable sshd 
	    	;;
	zypper)  
		sudo "$package_manager" install -y openssh-server 
		sudo systemctl start sshd
		sudo systemctl enable sshd 
	    	;;
	*) 	echo "Package manager error"
	   	;;
	esac
}

install_app () {
	 while true; do
	 	echo -e "\nDo you wish to install $1? "
   		read -p "Please answer (y)es or (n)o." yn
    	case $yn in
        		[Yy]* ) 
        			
        			spinner $1 &                                       # calls the loading function
    				local whilePID=$!                                  # gets the pid for the loop
    				tput csr 7 $(($(tput lines) - 7))
			    	tput cup 7 0
			    	$1 &
			    	local backupPID=$!                                 # get's back up pid
			    	wait $backupPID                                    # waits for backup id
			    	kill $whilePID                                     # kills the while loop
			    	
        			break;;
        		[Nn]* ) break;;
        		* ) echo "Please answer (y)es or (n)o.";;
    	esac
	done
}

function spinner() { # just a function to hold the spinner loop, here you can put whatever
   while true; do
    	sleep 2
    	tput sc
    	Margin=5
    	Rows=$(tput lines)
    	Cols=$(tput cols)-$((Margin*2))-2
    	tput cup $(($Rows)) $Margin
    	tput el
    	tput el1
    	tput cup $(($Rows - 1)) $Margin
    	tput el
    	tput el1
    	tput cup $(($Rows - 2)) $Margin
    	tput el
    	tput el1
    	((progress=progress+1))
    	((remaining=${Cols}-${progress}))
    	tput bold
    	tput setaf $progressBarColor
    	
    	echo -ne "[$(printf "%${progress}s" | tr " " "#")$(printf "%${remaining}s" | tr " " "-")]"
    	tput sgr0
    	if (( $progress > ($((Cols-2))) )); then
   		((progress=1))
        fi
        tput rc
    done
}

function Header() { 
	tput bold
	tput setaf $headerColorFG
	tput setab $headerColorBG
	((ESpace=$(tput cols)-(${#installer_name})))
    	((LSide=((${ESpace}/2))-2))
    	((RSide=$(tput cols)-(${#installer_name})-${LSide}-4))
    	tput cup 0 0
    	echo -ne "[$(printf "%${LSide}s" | tr " " "#") $(printf "$installer_name") $(printf "%${RSide}s" | tr " " "-")]"
    	tput sgr0
    	echo -e ' '
}
function multiselect {
    # little helpers for terminal print control and key input
    ESC=$( printf "\033")
    cursor_blink_on()   { printf "$ESC[?25h"; }
    cursor_blink_off()  { printf "$ESC[?25l"; }
    cursor_to()         { printf "$ESC[$1;${2:-1}H"; }
    print_inactive()    { printf "$2   $1 "; }
    print_active()      { printf "$2  $ESC[7m $1 $ESC[27m"; }
    get_cursor_row()    { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }

    local return_value=$1
    local -n options=$2
    local -n defaults=$3

    local selected=()
    for ((i=0; i<${#options[@]}; i++)); do
        if [[ ${defaults[i]} = "true" ]]; then
            selected+=("true")
        else
            selected+=("false")
        fi
        printf "\n"
    done

    # determine current screen position for overwriting the options
    local lastrow=`get_cursor_row`
    local startrow=$(($lastrow - ${#options[@]}))

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    key_input() {
        local key
        IFS= read -rsn1 key 2>/dev/null >&2
        if [[ $key = ""      ]]; then echo enter; fi;
        if [[ $key = $'\x20' ]]; then echo space; fi;
        if [[ $key = "k" ]]; then echo up; fi;
        if [[ $key = "j" ]]; then echo down; fi;
        if [[ $key = $'\x1b' ]]; then
            read -rsn2 key
            if [[ $key = [A || $key = k ]]; then echo up;    fi;
            if [[ $key = [B || $key = j ]]; then echo down;  fi;
        fi 
    }

    toggle_option() {
        local option=$1
        if [[ ${selected[option]} == true ]]; then
            selected[option]=false
        else
            selected[option]=true
        fi
    }

    print_options() {
        # print options by overwriting the last lines
        
        local idx=0
        for option in "${options[@]}"; do
            local prefix="[ ]"
            if [[ ${selected[idx]} == true ]]; then
              prefix="[\e[38;5;46m✔\e[0m]"
            fi

            cursor_to $(($startrow + $idx))
            if [ $idx -eq $1 ]; then
                print_active "$option" "$prefix"
            else
                print_inactive "$option" "$prefix"
            fi
            ((idx++))
        done
       
    	echo -e '\n'
	echo -e '\nPress enter when done with selections'
    }

    local active=0
    while true; do
        print_options $active

        # user key control
        case `key_input` in
            space)  toggle_option $active;;
            enter)  print_options -1; break;;
            up)     ((active--));
                    if [ $active -lt 0 ]; then active=$((${#options[@]} - 1)); fi;;
            down)   ((active++));
                    if [ $active -ge ${#options[@]} ]; then active=0; fi;;
        esac
    done
    
    # cursor position back to normal
    cursor_to $lastrow
    printf "\n"
    printf "\n"
    printf "\n"
    cursor_blink_on

    eval $return_value='("${selected[@]}")'
}

clear
TRows=$(tput lines)
TCols=$(tput cols)
if (( "90" > ${TCols} )); then
   	clear
   	Header
	echo -e ' '
      	echo "Terminal not wide enough ($TCols - columns)"
      	echo "Need 90 columns. Make terminal wider."
      	exit
fi
if (( "25" > ${TRows} )); then
   	clear
   	Header
	echo -e ' '
      	echo "Terminal not tall enough ($TRows - rows)"
      	echo "Need 25 rows. Make terminal taller."
      	exit
fi

Header
echo "Updating Packages...."
tput setaf $sdoutColor
install_app Update
tput sgr0
clear
Header
echo -e '\nArrow up/down space bar to select'
echo -e ' '
multiselect result my_options preselection

idx=0
for option in "${my_options[@]}"; do
   if [ "true" = "${result[idx]}" ]; then
   	clear
   	Header
	echo -e ' '
	echo "Installing.. $option"
      	tput setaf $sdoutColor
      	install_app $option
      	echo -e ' '
      	tput sgr0
      	echo "Finished option.. $option"
      	read -p "Press enter to continue"
      	
   fi
    ((idx++))
done
clear
echo "Thank you for using $installer_name"
