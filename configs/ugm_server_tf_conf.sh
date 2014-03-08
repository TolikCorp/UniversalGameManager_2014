#!/bin/sh
####################################################
    date_day_month_year=`date +%F`
    date_hours_minutes_seconds=`date +%T`
    ilf="[---------------------------------------------------]"
    ilh="[---------"
    echo "${ilf}"
    echo "${ilh} UniversalGameManager 2014 [CONFIG] [17.02.2014]"
    echo "${ilh} ${date_day_month_year} ${date_hours_minutes_seconds}"
    echo "${ilf}"

# Физический IP-Адрес Выделенного сервера
####################################################
    server_ip_address="xxx.xxx.xxx.xxx"

# Пользователь сервера
####################################################
    server_user="game_server"

# AppID выделенного сервера
####################################################
#Counter-Strike: Global Offensive dedicated server  740
#Garry's Mod dedicated server                       4020
#Insurgency dedicated server                        17705
#Left 4 Dead 2 dedicated server                     222860
#Team Fortress 2 dedicated server                   232250
#Day of Defeat: Source dedicated server             232290
#Counter-Strike: Source dedicated server            232330
#Half-Life 2: Deathmatch dedicated server           232370

# Расположение дистрибутивов и хостинг-каталогов
####################################################

# Физическое расположение сервера
    server_dir="/home/usert/tf2_1"
# Название окна с сервером    
    server_screen_title="tf2_1"
# APP ID Dedicated Server
    server_app_id="232250"
# Название игры для srcds_run
    server_run_title="tf"
    
# Параметры запуска
####################################################
# Tickrate
    tickrate="66"
# Игровой порт
    server_game_port="27015"
# Стартовая карта
    default_map="ctf_2fort"
# Количество игроков
    maxplayers="25"
# Дополнительные параметры запуска
    params_ext="-nobots -nocrashdialog +tv_enable 0"
    
# Конфигурация автоматического обновления
####################################################
    case ${1} in
        autoupdate)
            autoupdate="-autoupdate -steam_dir ${2} -steamcmd_script ${3}"
        ;;
    esac
    if [ -z "${autoupdate}" ]; then
        autoupdate=""
    fi
    
# Заполнение дополнительных параметров
####################################################
    # client_port и tv_port заполняются автоматически
    client_port="$(( ${game_port} - 7000 ))"
    tv_port="$(( ${game_port} - 8000 ))"
    steam_port="$(( $game_port - 9000 ))"
    
# Запуск игрового сервера
####################################################
    while true; do
        cd $server_dir
        ./srcds_run -console -game ${game_name_run} -tickrate ${tickrate} -secure +ip ${ip_address} +map ${default_map} -port ${game_port} +clientport ${client_port} +tv_port ${tv_port} -steamport ${steam_port} +maxplayers ${maxplayers} ${params_ext} $autoupdate
        echo "${ilh} $(date +'%F-%R:%S') | Перезапуск сервера!" >> ./restarts.log
        echo "Ожидайте 10 секунд"
        sleep 10
    done 
####################################################