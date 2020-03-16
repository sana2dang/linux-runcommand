#!/bin/bash

SCRIPT_PATH=$(dirname $(realpath $0))
source "$SCRIPT_PATH/runcommand.cfg"
###############################################################################

# ARG
EMULATOR=$1
ROM=$2
ROM_TINY="${ROM##*/}"
################################################################################

# joy2key 프로세스 죽이기
function func_KillJoy2Key()
{
	JOY2KEY_PID=$(pgrep -f joy2key.py)
	#sudo kill -INT "$JOY2KEY_PID"
	sudo killall joy2key.py > /dev/null 2>&1
}

# 에뮬레이터별 코어 값 cfg 불러오기
function func_LoadEmulatorCfg()
{
	## EMULATOR CORE CFG LOAD ###################################################
	if [ -f "$RUNCOMMAND_PATH/cfg/$EMULATOR.cfg" ] ; then
		source "$RUNCOMMAND_PATH/cfg/$EMULATOR.cfg"
		echo "CFG LOAD : $RUNCOMMAND_PATH/cfg/$EMULATOR.cfg" >> $LOG_FILE
	else
		echo "CFG LOAD ERROR : $RUNCOMMAND_PATH/cfg/$EMULATOR.cfg" >> $LOG_FILE
		exit 0
	fi
	
	if [ ! -d "$RUNCOMMAND_PATH/$EMULATOR" ] ; then
		mkdir $RUNCOMMAND_PATH/$EMULATOR
	fi
	
	echo "DEFAULT CORE : $DEFAULT" >> $LOG_FILE
	#############################################################################

}

# 게임에 설정된 코어 읽어오기
function func_LoadGameCore()
{
	## EMULATOR CORE CFG LOAD ###################################################
	if [ -f "$RUNCOMMAND_PATH/$EMULATOR/$ROM_TINY.cfg" ] ; then
		GAME_DEFAULT=`cat "$RUNCOMMAND_PATH/$EMULATOR/$ROM_TINY.cfg"`
	else
		GAME_DEFAULT=""
	fi
	############################################################################
	
	echo "GAME_CORE : $GAME_DEFAULT" >> $LOG_FILE
	
}


# 에뮬레이터 디폴트 코어 변경
function func_DefaultCoreSelect()
{
	echo "" >> $LOG_FILE
	echo "=== func_DefaultCoreSelect" >> $LOG_FILE
	
	OPTIONS=()
	for (( i = 0 ; i < ${#CORES[@]} ; i++ )) ; do
 		OPTIONS+=("$i"  "${CORES[$i]}")
	done
	OPTIONS+=("EXIT" "EXIT")
	#echo ${ZZZ[@]}

	dialog --clear --no-cancel   \
	--title "[ DEFAULT C O R E - S E L E C T ]" \
	--menu "UP/DOWN ENTER! \n\
	EMULATOR : $EMULATOR \n\
	ROM : $ROM_TINY \n\
	DEFAULT CORE : $DEFAULT" 15 60 10 \
	"${OPTIONS[@]}" 2>$RUNCOMMAND_PATH/defaultitem 

	############################################ select menu #######################################################
	defaultitem=`cat $RUNCOMMAND_PATH/defaultitem` 

	SEL_DEFAULT=${CORES[$defaultitem]}

	# cfg 파일에 저장
	if [ "$SEL_DEFAULT" != "" ]; then
		sed -i "1s/.*/DEFAULT=\"$SEL_DEFAULT\"/g" $RUNCOMMAND_PATH/$EMULATOR.cfg
	fi 
}

# 게임별 코어를 선택 변경
function func_GameCoreSelect()
{

	echo "" >> $LOG_FILE
	echo "=== func_GameCoreSelect" >> $LOG_FILE
	
	OPTIONS=()
	for (( i = 0 ; i < ${#CORES[@]} ; i++ )) ; do
 		OPTIONS+=("$i"  "${CORES[$i]}")
	done
	OPTIONS+=("EXIT" "EXIT")
	#echo ${ZZZ[@]}

	dialog --clear --no-cancel   \
	--title "[ G A M E - C O R E - S E L E C T ]" \
	--menu "UP/DOWN ENTER! \n\
	EMULATOR : $EMULATOR \n\
	ROM : $ROM_TINY \n\
	GAME CORE : $DEFAULT" 15 60 10 \
	"${OPTIONS[@]}" 2>$RUNCOMMAND_PATH/gameitem 

	############################################ select menu #######################################################
	gameitem=`cat $RUNCOMMAND_PATH/gameitem` 

	# make decsion 
	GAME_DEFAULT=${CORES[$gameitem]}

	if [ "$GAME_DEFAULT" != "" ]; then
		# 게임별 선택 코어 cfg 만들기
		echo "$GAME_DEFAULT" > "$RUNCOMMAND_PATH/$EMULATOR/$ROM_TINY.cfg"
		echo "CREATE FILE : $RUNCOMMAND_PATH/$EMULATOR/$ROM_TINY.cfg" >> $LOG_FILE
		echo "SELECT GAME CORE : $GAME_DEFAULT" >> $LOG_FILE
	fi
}


function func_GameCoreRemove()
{
	echo "" >> $LOG_FILE
	echo "=== func_GameCoreRemove" >> $LOG_FILE
	
	rm "$RUNCOMMAND_PATH/$EMULATOR/$ROM_TINY.cfg"
	GAME_DEFAULT=""
}

# 런커맨드를 거치지 않고 바로 실행
function func_LaunchImmediately()
{
	echo "" >> $LOG_FILE
	echo "=== func_LaunchImmediately" >> $LOG_FILE
	
	func_LoadEmulatorCfg
	func_LoadGameCore
	func_LaunchGame
}

# 게임 실행
function func_LaunchGame()
{
	echo "" >> $LOG_FILE
	echo "=== func_LaunchGame" >> $LOG_FILE
	
	func_KillJoy2Key

	############################################### retroarch exec ###############################################################
	if [ "$GAME_DEFAULT" == "" ]; then
		CORE=$DEFAULT
	else
		CORE=$GAME_DEFAULT
	fi
	
	##### KILL joy2key.py ####################
	func_KillJoy2Key
	########################################

	
	## 32bit / 64bit 구분 ( 앞에 "32-" 가 붙으면 32비트 구동
	if [[ "$CORE" == *".so"* ]]; then
		if [[ "$CORE" == *"32-"* ]]; then
			CORE=${CORE:3}
			echo "RUNCOMMAND : $RETROARCH32_EXEC -L \"$CORE32_PATH/$CORE\" \"$ROM\"" >> $LOG_FILE

			if [ "$EMULATOR" == "dreamcast" ] || [ "$EMULATOR" == "atomiswave" ] || [ "$EMULATOR" == "naomi" ]; then
				$RETROARCH32_EXEC -L "$CORE32_PATH/$CORE" < /dev/null "$ROM" > /dev/null 2>&1
			else
				$RETROARCH32_EXEC -L "$CORE32_PATH/$CORE" "$ROM" > /dev/null 2>&1
			fi
		else
			echo "RUNCOMMAND : $RETROARCH_EXEC -L \"$CORE_PATH/$CORE\" \"$ROM\"" >> $LOG_FILE
			if [ "$EMULATOR" == "dreamcast" ] || [ "$EMULATOR" == "atomiswave" ] || [ "$EMULATOR" == "naomi" ]; then
				$RETROARCH_EXEC -L "$CORE_PATH/$CORE" < /dev/null "$ROM" > /dev/null 2>&1
			else
				$RETROARCH_EXEC -L "$CORE_PATH/$CORE" "$ROM" > /dev/null 2>&1
			fi
		fi
	else
		echo "RUNCOMMAND(no core) : $CORE \"$ROM\"" >> $LOG_FILE
		$CORE "$ROM" > /dev/null 2>&1
	fi
	
	
	exit 0
}


# 런커맨드 코어선택 메인 함수
function func_CoreSelectMenu()
{
	echo "" >> $LOG_FILE
	echo "=== func_CoreSelectMenu==" >> $LOG_FILE	
	############################################### default core select ###############################################################

	## EMULATOR CORE CFG LOAD ###################################################
	func_LoadEmulatorCfg
	
	# 게임코어 읽어오기 - 없으면 디폴트
	func_LoadGameCore

	######################################## dialog menu ###########################################################
	dialog --clear --no-cancel --timeout 10  \
	--title "[ C O R E - S E L E C T ]" \
	--menu "UP/DOWN ENTER! \n\
	EMULATOR : $EMULATOR \n\
	ROM : $ROM_TINY \n\
	NO CONTROL : GAME CORE starts after 10 seconds" 15 60 10 \
	0 "-DEFAULT CORE( $DEFAULT )" \
	1 "-GAME CORE( $GAME_DEFAULT )" \
	2 "-GAME CORE REMOVE" \
	3 "Launch GAME" \
	EXIT "EXIT" 2>$RUNCOMMAND_PATH/menuitem 

	############################################ select menu #######################################################
	menuitem=`cat $RUNCOMMAND_PATH/menuitem` 

	# make decsion 
	case $menuitem in
		0) func_DefaultCoreSelect;;
		1) func_GameCoreSelect;;
		2) func_GameCoreRemove;;
		3) func_LaunchGame;;
		EXIT) func_KillJoy2Key;exit 0;;
		*) func_LaunchGame;;
	esac	
}




##### Main Function ##################################################################

#clear
# joy2key enable - up down A-button
"$RUNCOMMAND_PATH/joy2key.py" "/dev/input/js0" kcub1 kcuf1 kcuu1 kcud1 0x0a 0x09 & 

echo "EMULATOR : $EMULATOR" > $LOG_FILE
echo "ROM_FULL_PATH : $ROM" >> $LOG_FILE 
echo "ROM : $ROM_TINY" >> $LOG_FILE
	
perfmax
if read -s -t $TIME -N 1 key; then
	while [ 1 ]; do
		func_CoreSelectMenu
	done
else
	func_LaunchImmediately
fi
perfnorm
#clear
#######################################################################################
