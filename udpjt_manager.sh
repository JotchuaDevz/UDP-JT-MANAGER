#!/bin/bash

CONFIG_DIR="/etc/hysteria"
CONFIG_FILE="$CONFIG_DIR/config.json"
USER_DB="$CONFIG_DIR/udpusers.db"
SYSTEMD_SERVICE="/etc/systemd/system/hysteria-server.service"

mkdir -p "$CONFIG_DIR"
touch "$USER_DB"

fetch_users() {
    if [[ -f "$USER_DB" ]]; then
        sqlite3 "$USER_DB" "SELECT username || ':' || password FROM users;" | paste -sd, -
    fi
}

update_userpass_config() {
    local users=$(fetch_users)
    local user_array=$(echo "$users" | awk -F, '{for(i=1;i<=NF;i++) printf "\"" $i "\"" ((i==NF) ? "" : ",")}')
    jq ".auth.config = [$user_array]" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
}

add_user() {
    echo -e "\n\e[1;34mIngresa El Usuario:\e[0m"
    read -r username
    echo -e "\e[1;34mIngresa La Contraseña:\e[0m"
    read -r password
    sqlite3 "$USER_DB" "INSERT INTO users (username, password) VALUES ('$username', '$password');"
    if [[ $? -eq 0 ]]; then
        echo -e "\e[1;32mUsuario $username Agregado Correctamente.\e[0m"
        update_userpass_config
        restart_server
    else
        echo -e "\e[1;31mError: Fallo Al Agregar El Usuario > $username.\e[0m"
    fi
}

edit_user() {
    echo -e "\n\e[1;34mIngresa El Usuario A Editar:\e[0m"
    read -r username
    echo -e "\e[1;34mIngresa La Nueva Contraseña:\e[0m"
    read -r password
    sqlite3 "$USER_DB" "UPDATE users SET password = '$password' WHERE username = '$username';"
    if [[ $? -eq 0 ]]; then
        echo -e "\e[1;32mUsuario $username Actualizado Correctamente.\e[0m"
        update_userpass_config
        restart_server
    else
        echo -e "\e[1;31mError: Fallo Al Actualizar El Usuario > $username.\e[0m"
    fi
}

delete_user() {
    echo -e "\n\e[1;34mIngrea El Usuario A Eliminar:\e[0m"
    read -r username
    sqlite3 "$USER_DB" "DELETE FROM users WHERE username = '$username';"
    if [[ $? -eq 0 ]]; then
        echo -e "\e[1;32mUsuario $username Eliminado Correctamente.\e[0m"
        update_userpass_config
        restart_server
    else
        echo -e "\e[1;31mError: Fallo Al Eliminar El Usuario > $username.\e[0m"
    fi
}

show_users() {
    echo -e "\n\e[1;34mCurrent users:\e[0m"
    sqlite3 "$USER_DB" "SELECT username FROM users;"
}

change_domain() {
    echo -e "\n\e[1;34mEnter new domain:\e[0m"
    read -r domain
    jq ".server = \"$domain\"" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    echo -e "\e[1;32mDominio Cambiado $domain Correctamente.\e[0m"
    restart_server
}

change_obfs() {
    echo -e "\n\e[1;34mIngresa El Nuevo Obfs:\e[0m"
    read -r obfs
    jq ".obfs.password = \"$obfs\"" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    echo -e "\e[1;32mObfs Cambiado A $obfs Correctamente.\e[0m"
    restart_server
}

change_up_speed() {
    echo -e "\n\e[1;34mEnter new upload speed (Mbps):\e[0m"
    read -r up_speed
    jq ".up_mbps = $up_speed" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    jq ".up = \"$up_speed Mbps\"" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    echo -e "\e[1;32mUpload speed changed to $up_speed Mbps successfully.\e[0m"
    restart_server
}

change_down_speed() {
    echo -e "\n\e[1;34mEnter new download speed (Mbps):\e[0m"
    read -r down_speed
    jq ".down_mbps = $down_speed" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    jq ".down = \"$down_speed Mbps\"" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    echo -e "\e[1;32mDownload speed changed to $down_speed Mbps successfully.\e[0m"
    restart_server
}

restart_server() {
    systemctl restart hysteria-server
    echo -e "\e[1;32mServidor Reiniciado Correctamente.\e[0m"
}

uninstall_server() {
    echo -e "\n\e[1;34mDesinstalando UDP-JT MOD...\e[0m"
    systemctl stop hysteria-server
    systemctl disable hysteria-server
    rm -f "$SYSTEMD_SERVICE"
    systemctl daemon-reload
    rm -rf "$CONFIG_DIR"
    rm -f /usr/local/bin/hysteria
    echo -e "\e[1;32mUDP-JT MOD Eliminado Correctamente.\e[0m"
}

show_banner() {
    echo -e "\e[1;36m---------------------------------------------"
    echo " UDP-JT MOD"
    echo " (c) 2025 JotchuaST"
    echo " Telegram: @Jotchua_DevzZ"
    echo "---------------------------------------------\e[0m"
}

show_menu() {
    echo -e "\e[1;36m----------------------------"
    echo    "       UDP-JT Manager            "
    echo -e "----------------------------\e[0m"
    echo -e "\e[1;32m1. Añadir Nuevo Usuario"
    echo "2. Editar Usuario Y Contraseña"
    echo "3. Eliminar Usuario"
    echo "4. Mostrar Usuarios"
    echo "5. Cambiar Dominio"
    echo "6. Cambiar Obfs"
    echo "7. Cambiar upload speed"
    echo "8. Cambiar download speed"
    echo "9. Reiniciar Servidor"
    echo "10. Desinstalar Script"
    echo -e "11. Salir\e[0m"
    echo -e "\e[1;36m----------------------------"
    echo -e "Ingresa Una Opcion : \e[0m"
}

show_banner
while true; do
    show_menu
    read -r choice
    case $choice in
        1) add_user ;;
        2) edit_user ;;
        3) delete_user ;;
        4) show_users ;;
        5) change_domain ;;
        6) change_obfs ;;
        7) change_up_speed ;;
        8) change_down_speed ;;
        9) restart_server ;;
        10) uninstall_server; exit 0 ;;
        11) exit 0 ;;
        *) echo -e "\e[1;31mOpcion Invalida, Por Favor Elegir Nuevamente.\e[0m" ;;
    esac
done
