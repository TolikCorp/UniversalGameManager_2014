#!/bin/bash
####################################################
    date_day_month_year=`date +%F`
    date_hours_minutes_seconds=`date +%T`
    ilf="[---------------------------------------------------]"
    ilh="[---------"
    echo "${ilf}"
    echo "${ilh} UniversalGameManager 2014 [CORE] [17.02.2014]"
    echo "${ilh} ${date_day_month_year} ${date_hours_minutes_seconds}"
    echo "${ilf}"
    
    default_iface="eth1"
    distrib_dir="/home/distrib"
    steamcmd="${distrib_dir}/steamcmd/steamcmd.sh"
    
    if [ "$(id -u)" -ne "0" ]; then
        echo "${ilh} Пользователь не root"
        exit 1
    fi
    
    error_msg ()
    {
        echo "#######################################################"
        echo "## bash $(basename $0) /{PATH_TO_CONF}/{SERVER_CONF}.sh <start|start autoupdate|restart|stop|install|update|backup>"
        echo "## ПАРАМЕТРЫ ЗАПУСКА:"
        echo "## start - запуск игрового сервера без предварительного обновления"
        echo "## start autoupdate - запуск игрового сервера с предварительным обновлением"
        echo "## stop - остановка игрового сервера"
        echo "## update - обновление игрового сервера"
        echo "## setup - установить необходимые библиотеки (необходим root)"
        echo "#######################################################"
        exit 1
    }
    
    aio_dir="$(cd "$(dirname "${0}")"; pwd)"
    aio_file="$(basename $0)"
    
    screen_wipe()
    {
        screen -wipe > /dev/null 2>&1
    }
    
    command_setup()
    {
        apps="lib32gcc1 zlib1g lib32z1 ia32-libs screen cron-apt"
        for i in ${apps}; do
            apt-get install --yes ${i}
        done
        if [ -f "${aio_dir}/steamcmd_linux.tar.gz" ]; then
            mkdir -p $(echo ${steamcmd} | sed 's%/steamcmd.sh%%g')
            cd $(echo ${steamcmd} | sed 's%/steamcmd.sh%%g')
            cp ${aio_dir}/steamcmd_linux.tar.gz ./
            tar xvfz steamcmd_linux.tar.gz
            ./steamcmd.sh
        fi
        exit 0
    }
        
    case "${1}" in
        setup)
            command_setup
        ;;
    esac
    
    if [ -z ${1} ]; then
        error_msg
    fi
    if [ -z ${2} ]; then
        error_msg
    fi
    if [[ ! -f ${steamcmd} ]]; then
        echo "${ilh} Файл STEAMCMD ${steamcmd} не найден!"
        exit 1
    fi
    
    server_conf="${1}"
    if [[ ! -f ${server_conf} ]]; then
        echo "${ilh} Файл конфигурации ${server_conf} не найден!"
        exit 1
    fi
    server_user="$(grep server_user= ${server_conf} | sed -e 's/.*"\(.*\)".*/\1/')"
    server_ip_address="$(grep server_ip_address= ${server_conf} | sed -e 's/.*"\(.*\)".*/\1/')"
    server_dir="$(grep server_dir= ${server_conf} | sed -e 's/.*"\(.*\)".*/\1/')"
    server_screen_title="$(grep server_screen_title= ${server_conf} | sed -e 's/.*"\(.*\)".*/\1/')"
    server_app_id="$(grep server_app_id= ${server_conf} | sed -e 's/.*"\(.*\)".*/\1/')"
    server_run_title="$(grep server_run_title= ${server_conf} | sed -e 's/.*"\(.*\)".*/\1/')"
    server_game_port="$(grep server_game_port= ${server_conf} | sed -e 's/.*"\(.*\)".*/\1/')"
    
    sudo_run="su --login ${server_user} --command"
        
    mkdir -p ${server_dir}
    if [ -d "${server_dir}" ]; then
        chmod -R 700 ${server_dir}
        chown -R ${server_user} ${server_dir}
        cd ${server_dir}
    else
        echo "${ilh} Каталог для сервера ${server_dir} не был создан. Попробуйте его создать вручную."
        exit 1
    fi
    
    kill_screen()
    {
        if [ -n "${1}" ]; then
            pids_list="$(ps ax | grep SCREEN | grep -v grep | grep ${1} | awk '{print $1}')"
            if [ -n "${pids_list}" ]; then
                kill -9 ${pids_list}
            fi
        fi
    }
    
    command_stop()
    {
        if screen -list | grep -q ${server_screen_title}_console; then
            screen -S ${server_screen_title}_console -X -p0 stuff 'exit'`echo -ne '\015'`
            sleep 5
            pids_list="$(ps ax | grep srcds_linux | grep -v grep | grep ${server_ip_address} | grep ${server_game_port} | awk '{print $1}')"
            if [ -n "${pids_list}" ]; then
                kill -9 ${pids_list}
            fi
        fi
        kill_screen ${server_screen_title}_console
        kill_screen ${server_screen_title}_monitoring
        kill_screen ${server_screen_title}_update
        kill_screen ${server_screen_title}_install
        kill_screen ${server_screen_title}_backup
        screen_wipe
    }
    
    command_start()
    {
        autoupdate_conf_create()
        {
            autoupdate_conf_dir="${aio_dir}/autoupdate_conf"
            mkdir -p ${autoupdate_conf_dir}
            chmod 777 ${autoupdate_conf_dir}
            autoupdate_conf_file="${server_screen_title}.update"
            if [ -d ${autoupdate_conf_dir} ]; then
                find ${autoupdate_conf_dir} -mtime  +7 -exec rm {} \;
                echo "${ilh} Скрипт для автообновления ${autoupdate_conf_dir}/${autoupdate_conf_file}"
                echo "//update ${server_screen_title}" > ${autoupdate_conf_dir}/${autoupdate_conf_file}
                echo "@ShutdownOnFailedCommand 0" >> ${autoupdate_conf_dir}/${autoupdate_conf_file}
                echo "@NoPromptForPassword 1" >> ${autoupdate_conf_dir}/${autoupdate_conf_file}
                echo "login anonymous" >> ${autoupdate_conf_dir}/${autoupdate_conf_file}
                echo "force_install_dir ${server_dir}" >> ${autoupdate_conf_dir}/${autoupdate_conf_file}
                echo "app_update ${server_app_id} validate" >> ${autoupdate_conf_dir}/${autoupdate_conf_file}
                echo "quit" >> ${autoupdate_conf_dir}/${autoupdate_conf_file}
                chown ${server_user} ${autoupdate_conf_dir}/${autoupdate_conf_file}
                chmod 700 ${autoupdate_conf_dir}/${autoupdate_conf_file}
            else
                echo "${ilh} Каталог для создания конфигураций автообновления ${autoupdate_conf_dir} не найден!"
            fi
        }
        command_stop
        chown ${server_user} ${server_conf}
        chmod 600 ${server_conf}
        case ${1} in
            autoupdate)
                autoupdate_conf_create
                screen -AmdS ${server_screen_title}_console ${sudo_run} sh ${server_conf} autoupdate $(echo ${steamcmd} | sed 's%/steamcmd.sh%%g') ${autoupdate_conf_dir}/${autoupdate_conf_file}
            ;;
            *)
                screen -AmdS ${server_screen_title}_console ${sudo_run} sh ${server_conf}
            ;;
        esac
        # Расположение скрипта мониторинга состояния. Требуются права доступа не менее 555
        monitoring_script_file="${aio_dir}/srcds_status_checker.py"
        if [ -f "${monitoring_script_file}" ]; then
            chmod 555 "${monitoring_script_file}"
            screen -AmdS ${server_screen_title}_monitoring python ${sudo_run} ${monitoring_script_file} ${server_ip_address} ${server_game_port} "${aio_dir}/${aio_file} ${server_conf} restart"
        else
            echo "${ilh} Файл ${monitoring_script_file} не найден!"
        fi
    }
    
    command_restart()
    {
        pids_list="$(ps ax | grep srcds_linux | grep -v grep | grep ${server_ip_address} | grep ${server_game_port} | awk '{print $1}')"
        if [ -n "${pids_list}" ]; then
            kill -9 ${pids_list}
        fi
        screen_wipe
    }
    
    command_update()
    {
        if screen -list | grep -q ${server_screen_title}_console; then
            i=0
            while [ "${i}" -lt "5" ]; do
                screen -S ${server_screen_title}_console -X -p0 stuff 'say Update server after a few seconds'`echo -ne '\015'`
                i="$(( $i + 1 ))"
                sleep 1
            done
        fi
        command_stop
        if [ -f "${server_dir}/screenlog.0" ]; then
            cp ./screenlog.0 screenlog.1 > /dev/null 2>&1
            rm ./screenlog.0 > /dev/null 2>&1
            chown ${server_user} ./screenlog.1
        fi
        screen -AmdLS ${server_screen_title}_update ${sudo_run} ${steamcmd} +login anonymous +force_install_dir ${server_dir} +app_update ${server_app_id} validate +quit
    }
    
    command_install()
    {
        command_stop
        if [ -f "${server_dir}/screenlog.0" ]; then
            cp ./screenlog.0 screenlog.1 > /dev/null 2>&1
            rm ./screenlog.0 > /dev/null 2>&1
            chown ${server_user} ./screenlog.1
        fi
        if [ -d "${distrib_dir}/${server_app_id}" ]; then
            cd ${server_dir}
            screen -AmdLS ${server_screen_title}_install cp -rv ${distrib_dir}/${server_app_id}/* ${server_dir} && chmod -R 744 ${server_dir}
        else
            echo "${ilh} Дистрибутива ${distrib_dir}/${server_app_id} нет. Попробуйте позже."
            exit 1
        fi
    }
    
    command_backup()
    {
        kill_screen ${server_screen_title}_backup
        backup_location_distrib="${distrib_dir}/${server_app_id}"
        if [[ ! -d "${distrib_dir}/${server_app_id}" ]]; then
            echo "${ilh} Дистрибутива ${distrib_dir}/${server_app_id} нет. Попробуйте позже."
            exit 1
        fi
        backup_location_gameserver="${server_dir}"
        backup_list_distrib="${backup_location_distrib}/${server_app_id}.list"
        backup_list_gameserver="${backup_location_gameserver}/backup.list"
        cd ${backup_location_distrib}
        find . -type f -print | sed -e 's/^.\{1\}//' > ${backup_list_distrib}
        find ${backup_location_gameserver} -type f -print > ${backup_list_gameserver}
        cp ${backup_list_gameserver} ${backup_list_gameserver}.backup.part1
        index="0"
        for i in $(grep -v ^# $backup_list_distrib); do
            if [ -f "${backup_location_gameserver}${i}" ]; then
                if [ "$(md5sum ${backup_location_gameserver}${i} | awk '{ print $1 }')" == "$(md5sum ${backup_location_distrib}${i} | awk '{ print $1 }')" ]; then
                    if [ "${index}" -eq "0" ]; then
                        grep -v ${i} ${backup_list_gameserver}.backup.part1 > ${backup_list_gameserver}.backup.part2
                        index="1"
                    else
                        grep -v ${i} ${backup_list_gameserver}.backup.part2 > ${backup_list_gameserver}.backup.part1
                        index="0"
                    fi
                    echo "${i} идентичен оригиналу"
                fi
            else
                echo "${i} не существует"
            fi
        done
        backup_temp_list=".backup.tar.gz .backup.part1 .backup.part2"
        for i in $(backup_temp_list); do
            if [ "${index}" -eq "0" ]; then
                grep -v ${i} ${backup_list_gameserver}.backup.part1 > ${backup_list_gameserver}.backup.part2
                index="1"
            else
                grep -v ${i} ${backup_list_gameserver}.backup.part2 > ${backup_list_gameserver}.backup.part1
                index="0"
            fi
        done
        if [ "${index}" -eq "0" ]; then
            backup_target_file="${backup_list_gameserver}.backup.part1"
        else
            backup_target_file="${backup_list_gameserver}.backup.part2"
        fi
        rm ${backup_list_gameserver}.backup.part1 > /dev/null 2>&1
        rm ${backup_list_gameserver}.backup.part2 > /dev/null 2>&1
        rm ${backup_list_gameserver} > /dev/null 2>&1
        cp ${backup_target_file} ${backup_list_gameserver}
        screen -AmdS ${server_screen_title}_backup tar -zcf ${backup_location_gameserver}/${date_day_month_year}.backup.tar.gz --files-from ${backup_list_gameserver}
    }
    
    command_screen()
    {
        screen_wipe
        if screen -list | grep -q ${server_screen_title}_console; then
            screen -x ${server_screen_title}_console
        elif screen -list | grep -q ${server_screen_title}_update; then
            screen -x ${server_screen_title}_update
        elif screen -list | grep -q ${server_screen_title}_install; then
            screen -x ${server_screen_title}_install
        elif screen -list | grep -q ${server_screen_title}_backup; then
            screen -x ${server_screen_title}_backup
        fi
    }

    # Действие с сервером
    case "${2}" in
        console|screen)
            command_screen
        ;;
        start)
            command_start ${3}
        ;;
        restart)
            command_restart
        ;;
        update)
            command_update
        ;;
        stop)
            command_stop
        ;;
        install)
            command_install
        ;;
        backup)
            command_backup
        ;;
        *)
            error_msg
        ;;
    esac
#####################################################################################################
#                                                                                                   #
#                    #######                         #####                                          #
#                       #     ####  #      # #    # #     #  ####  #####  #####                     #
#                       #    #    # #      # #   #  #       #    # #    # #    #                    #
#                       #    #    # #      # ####   #       #    # #    # #    #                    #
#                       #    #    # #      # #  #   #       #    # #####  #####                     #
#                       #    #    # #      # #   #  #     # #    # #   #  #                         #
#                       #     ####  ###### # #    #  #####   ####  #    # #                         #
#                                                                                                   #
#####################################################################################################
