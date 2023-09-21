#!/bin/bash

   #################################################################
   #                                                               #
   #             tlbardelljr network VM host installer             #
   #           Copyright (C) 2023 Terry Bardell Jr                 #
   #       Licensed under the GNU General Public License 3.0       #
   #                                                               #
   #      https://github.com/tlbardelljr/bare-metal-kvm-server     #
   #                                                               #
   #################################################################
   
my_options=(   "Curl"  "Git"  "Cockpit" "Webmin" "KVM"  "Boot-headless" "CIFS"  "Network-Bridge" "ssh"   )
preselection=( "true"  "true" "true"    "true"   "true" "false"         "false" "true"           "false" )
installer_name="tlbardelljr network VM installer"
sdoutColor=250
progressBarColorFG=226
progressBarColorBG=242
headerColorFG=255
headerColorBG=242

export terminal=$(tty)

command -v apt > /dev/null && package_manager="apt-get"
command -v yum > /dev/null && package_manager="yum"
command -v zypper > /dev/null && package_manager="zypper"

Update () {
	"$package_manager" update -y & progress_bar $!;
}
 
Curl () {
	"$package_manager" install -y curl & progress_bar $!;
}

Git () {
	"$package_manager" install -y git & progress_bar $!;
}

Cockpit () {
	"$package_manager" install -y cockpit & progress_bar $!;
	"$package_manager" install -y cockpit-machines & progress_bar $!;
	systemctl enable --now cockpit.socket & progress_bar $!;
}

Webmin () {
	case "$package_manager" in

	apt-get) 
		curl -o setup-repos.sh https://raw.githubusercontent.com/webmin/webmin/master/setup-repos.sh & progress_bar $!;
		sh setup-repos.sh --force & progress_bar $!;
		apt-get install --install-recommends webmin -y & progress_bar $!;
	    	;;
	yum) 
		dnf install -y 'perl(IO::Pty)' & progress_bar $!;
		curl -o setup-repos.sh https://raw.githubusercontent.com/webmin/webmin/master/setup-repos.sh & progress_bar $!;
		sh setup-repos.sh --force & progress_bar $!;
		dnf install webmin -y & progress_bar $!;
		echo Enter password for webmim root account to login webmin?
		echo " "
		read -e password < $terminal
		/usr/libexec/webmin/changepass.pl /etc/webmin root "$password" & progress_bar $!;
	    	;;
	zypper)  
		zypper install -y 'perl(IO::Pty)' & progress_bar $!;  
		zypper -n install apache2 & progress_bar $!;  
		zypper -n install openssl & progress_bar $!; 
		zypper -n install openssl-devel & progress_bar $!;   
		zypper -n install perl & progress_bar $!; 
		zypper -n install perl-Net-SSLeay & progress_bar $!; 
		zypper -n install perl-Crypt-SSLeay & progress_bar $!;  
		wget http://prdownloads.sourceforge.net/webadmin/webmin-1.770-1.noarch.rpm & progress_bar $!;  
		rpm -ivh webmin-1.770-1.noarch.rpm & progress_bar $!;  
		;;
	*) 	echo "Package manager error"
	   	;;
	esac
}

KVM () {
	case "$package_manager" in

	apt-get) 
		"$package_manager" install -y qemu-kvm & progress_bar $!;
		"$package_manager" install -y bridge-utils & progress_bar $!;
		"$package_manager" install -y virt-manager & progress_bar $!; 
		"$package_manager" install -y libvirt-daemon-system & progress_bar $!;
		"$package_manager" install -y libvirt-clients & progress_bar $!;
		"$package_manager" install -y virtinst & progress_bar $!;
		"$package_manager" install -y libguestfs-tools & progress_bar $!;
		"$package_manager" install -y libosinfo-bin & progress_bar $!; 
		echo Enter login name to add to libvirt group?
		read -e username < $terminal
		usermod -aG libvirt "$username" & progress_bar $!;
	    	;;
	yum) 
		"$package_manager" install -y qemu-kvm & progress_bar $!;
		"$package_manager" install -y bridge-utils & progress_bar $!;
		"$package_manager" install -y virt-manager & progress_bar $!;
		"$package_manager" install -y libvirt & progress_bar $!;
		"$package_manager" install -y virt-install & progress_bar $!;
		"$package_manager" install -y libvirt-devel & progress_bar $!;
		"$package_manager" install -y virt-top & progress_bar $!;
		"$package_manager" install -y libguestfs-tools & progress_bar $!;
		"$package_manager" install -y guestfs-tools & progress_bar $!;
		echo Enter login name to add to libvirt group?
		read -e username < $terminal
		usermod -aG libvirt "$username" & progress_bar $!;
		systemctl start libvirtd & progress_bar $!;
		systemctl enable libvirtd & progress_bar $!;
	    	;;
	zypper)  
		zypper install -t pattern kvm_server & progress_bar $!;
		zypper install -t pattern kvm_tools & progress_bar $!;
		zypper install -y bridge-utils & progress_bar $!;
		zypper install -y virt-manager & progress_bar $!;
		systemctl enable --now libvirtd & progress_bar $!;
		
	    	;;
	*) 	echo "Package manager error"
	   	;;
	esac
}

Boot-headless () {
	systemctl set-default multi-user.target & progress_bar $!; 
	echo -e ' '
	echo "After reboot enter to boot GUI: systemctl isolate graphical.target"
}

CIFS () {
	"$package_manager" install -y cifs-utils & progress_bar $!; 
}

Network-Bridge () {
	nmcli connection show & progress_bar $!;
	echo Enter network interface device name to link to bridge br0?
	read -e interface_name < $terminal
	echo " "
	echo Use prefix length for network mask.
	echo 'Example 192.168.0.5 255.255.0.0 would be entered 192.168.0.5/16.'
	echo Enter ipadress with prefix length?
	read -e ip_address < $terminal
	echo Enter ip address for gateway?
	read -e gateway < $terminal
	
	nmcli connection add type bridge autoconnect yes con-name br0 ifname br0 & progress_bar $!;
	nmcli connection modify br0 ipv4.addresses "$ip_address" gw4 "$gateway" ipv4.method manual & progress_bar $!; 
	nmcli connection modify br0 ipv4.dns "$gateway" & progress_bar $!; 
	nmcli connection add type bridge-slave autoconnect yes con-name "$interface_name" ifname "$interface_name" master br0 & progress_bar $!; 
	nmcli connection up br0 & progress_bar $!;
}

ssh () {
	case "$package_manager" in

	apt-get) 
		"$package_manager" install openssh-server -y & progress_bar $!; 
		systemctl start ssh & progress_bar $!;
		systemctl enable ssh & progress_bar $!;
	    	;;
	yum) 
		"$package_manager" install openssh-server -y & progress_bar $!; 
		systemctl start sshd & progress_bar $!;
		systemctl enable sshd & progress_bar $!; 
	    	;;
	zypper)  
		"$package_manager" install -y openssh-server & progress_bar $!; 
		systemctl start sshd & progress_bar $!;
		systemctl enable sshd & progress_bar $!; 
	    	;;
	*) 	echo "Package manager error"
	   	;;
	esac
}

install_app () {
	 while true; do
	 	echo -e "\nDo you wish to install $1? "
   		read -p "Please answer (y)es or (n)o." yn
   	tput setaf $sdoutColor
      	case $yn in
        		[Yy]* ) 
        			
        			tput csr 8 $(($(tput lines) - 5))
			    	tput cup 8 0
			    	$1 
			    	
        			break;;
        		[Nn]* ) break;;
        		* ) echo "Please answer (y)es or (n)o.";;
    	esac
    	tput sgr0
	done
}

function progress_bar() { 
	pid=$1
 	((progress=1))
	while [ -e /proc/$pid ]; do
		kill -s STOP $pid > /dev/null 2>&1
		tput sc
	    	Rows=$(tput lines)
	    	Cols=$(tput cols)-2
	   	tput cup $(($Rows - 2)) 0
	    	((progress=progress+4))
	    	((remaining=${Cols}-${progress}))
	    	tput bold
	    	tput setaf $progressBarColorFG
	    	tput setab $progressBarColorBG
	    	echo -ne "[$(printf "%${progress}s" | tr " " "#")$(printf "%${remaining}s" | tr " " "-")]"
	    	tput cup $(($Rows - 1)) 0
      		tput sgr0
	    	tput ed
	    	if (( $progress > ($((Cols-4))) )); then
	   		((progress=1))
		fi
		tput rc
		sleep .5
		kill -s CONT $pid > /dev/null 2>&1
  		sleep 4
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
    	echo -ne "[$(printf "%${LSide}s" | tr " " " ") $(printf "$installer_name") $(printf "%${RSide}s" | tr " " " ")]"
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
if (( "80" > ${TCols} )); then
   	clear
   	Header
	echo -e ' '
      	echo "Terminal not wide enough ($TCols - columns)"
      	echo "Need 80 columns. Make terminal wider."
      	exit
fi
if (( "23" > ${TRows} )); then
   	clear
   	Header
	echo -e ' '
      	echo "Terminal not tall enough ($TRows - rows)"
      	echo "Need 23 rows. Make terminal taller."
      	exit
fi

systemctl stop packagekit
Header
echo "Updating Packages...."
install_app Update
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
