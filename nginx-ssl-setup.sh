#!/bin/bash

# nginx-ssl-setup.sh - A script for generating self-signed SSL certificates and configuring Nginx
# Copyright (C) 2024  Çağatay Kahraman
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# Welcome message
echo "Welcome to the SSL Certificate Setup Script!"
echo "This script will help you generate a self-signed SSL certificate and configure Nginx with it."
echo "You will be prompted to enter your domain name, the path to save the certificate files, the expiration period for the certificate, and whether you want 301 redirection or not."
echo "Note: Self-signed certificates are not trusted by browsers and will display a warning. For production environments, consider using a Let's Encrypt certificate."
echo "Also, ensure that port 443 is open on your firewall for HTTPS traffic."
echo "Let's get started!"
echo ""
sleep 2

# Function to check if required tools are installed
check_tools() {
    # Check if Nginx is installed
    if ! command -v nginx &> /dev/null; then
        install_and_enable_tool "Nginx" "apt-get install nginx" "systemctl enable nginx"
    fi

    # Check if OpenSSL is installed
    if ! command -v openssl &> /dev/null; then
        install_and_enable_tool "OpenSSL" "apt-get install openssl"
        exit 1
    fi

    # Check if Curl is installed
    if ! command -v curl &> /dev/null; then
        install_and_enable_tool "Curl" "apt-get install curl"
        exit 1
    fi
}

# Function to prompt user for installation and optionally enable a service
install_and_enable_tool() {
    local tool_name=$1
    local install_command=$2
    local enable_command=$3
    
    echo "$tool_name is not installed on your system."
    echo "Warning: This script requires $tool_name to be installed to function correctly and will exit unless you install it."
    echo "You will be asked for sudo permissions to install the package if you choose to proceed."
    echo "Would you like to install $tool_name now? (y/n):"
    read -e -r install_response
    echo ""

    install_response_lower=$(echo "$install_response" | tr '[:upper:]' '[:lower:]')

    if [[ "$install_response_lower" == "y" ]]; then
        sudo apt-get update
        sudo $install_command
        if [ $? -ne 0 ]; then
            echo "Error while installing $tool_name. Exiting."
            exit 1
        fi

        if [[ "$tool_name" == "Nginx" ]] && [ -n "$enable_command" ]; then
            echo "Do you want $tool_name to run when the system starts? (y/n):"
            read -e -r enable_response
            echo ""

            enable_response_lower=$(echo "$enable_response" | tr '[:upper:]' '[:lower:]')

            if [[ "$enable_response_lower" == "y" ]]; then
                sudo $enable_command
                if [ $? -ne 0 ]; then
                    echo "Error while enabling $tool_name to run on startup."
                fi
            elif [[ "$enable_response_lower" == "n" ]]; then
                echo "$tool_name will not be enabled to run on startup."
                echo ""
            else
                echo "Invalid input: Please respond with 'y' to enable $tool_name on startup or 'n' to skip."
                echo "Continuing without enabling $tool_name to run on startup."
            fi
        fi
    elif [[ "$install_response_lower" == "n" ]]; then
        echo "$tool_name is required for this script to work. Exiting."
        exit 1
    else
        echo "Invalid input: Please respond with 'y' to install $tool_name or 'n' to exit."
        exit 1
    fi
}

# Function to validate and create user path
validate_cert_path() {
    local path=$1
    local parent_dir=$(dirname "$path")

    # Check for invalid characters (allow alphanumeric, slashes, and hyphens)
    if [[ "$path" =~ [^a-zA-Z0-9/_-] ]]; then
        echo "Invalid path: The specified path contains unsupported characters."
        echo "Please ensure your path only includes alphanumeric characters, slashes (/), and hyphens (-)."
        exit 1
    fi

    # Check if the path's parent directory exists
    if [ ! -d "$parent_dir" ]; then
        echo "Invalid directory: The parent directory $parent_dir does not exist."
        echo "Please create the directory manually or choose a different path, then rerun the script."
        exit 1
    fi

    # Check if the target directory exists; if not, create it
    if [ ! -d "$path" ]; then
        echo "Invalid directory: The target directory $path does not exist. Would you like to create it now? (y/n):"
        read -e -r create_dir_answer
        echo ""

        create_dir_answer_lower=$(echo "$create_dir_answer" | tr '[:upper:]' '[:lower:]')

        if [[ "$create_dir_answer_lower" == "y" ]]; then
            mkdir -p "$path"
            if [ $? -eq 0 ]; then
                echo "Directory $path created successfully."
                echo ""
            else
                echo "Error while creating directory $path."
                exit 1
            fi
        elif [[ "$create_dir_answer_lower" == "n" ]]; then
            echo "Directory creation aborted. Please create the directory manually and re-run the script."
            exit 1
        else
            echo "Invalid input: Please respond with 'y' to create the directory or 'n' to cancel."
            exit 1
        fi
    fi

    # Check write privileges for the specified path
    if [ ! -w "$path" ]; then
        echo "Insufficient permissions: You do not have write access to $path. Please adjust the permissions or choose a different directory"
        exit 1
    fi
    sleep 0.5
}

# Function to validate domain name
validate_domain_name() {
    local domain=$1
    if [[ ! "$domain" =~ ^([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$ ]]; then
        echo "Invalid domain name: The entered domain name is not in a valid format. Please use the format 'example.com'."
        exit 1
    fi
    sleep 0.5
}

# Function to handle rollback with user interactions
rollback() {
    local cert_path=$1

    echo "Rolling back changes..."
    echo ""
    sleep 0.5

    # Check if any backup of config exists
    local backup_file=$(ls /etc/nginx/sites-available/*.conf.bak-* 2>/dev/null | sort -r | head -n 1)

    if [ -n "$backup_file" ]; then
        echo "Backup file found at $backup_file."
        echo "Do you want to restore the backup? (y/n):"
        read -e -r restore_answer

        restore_answer_lower=$(echo "$restore_answer" | tr '[:upper:]' '[:lower:]')

        if [[ "$restore_answer_lower" == "y" ]]; then
            local conf_file="${backup_file%.bak-*}"
            sudo cp "$backup_file" "$conf_file"
            if [ $? -eq 0 ]; then
                echo "Configuration file restored from backup."
            else
                echo "Error restoring configuration file from backup."
            fi
        elif [[ "$restore_answer_lower" == "n" ]]; then
            echo "Backup not restored. Manual intervention might be required."
        else
            echo "Invalid input: Please enter 'y' for yes or 'n' for no."
            exit 1
        fi
    else
        echo "No backup file found. No rollback performed."
    fi
    sleep 0.5

    # Remove the generated certificates if they exist
    if [ -d "$cert_path" ]; then
        echo "Removing generated certificate files from $cert_path..."
        rm -rf "$cert_path"
        if [ $? -eq 0 ]; then
            echo "Certificate files removed successfully."
            echo ""
        else
            echo "Failed to remove certificate files from $cert_path. Please check your permissions and try again."
            echo ""
        fi
    fi
    sleep 0.5
}

# Function to handle script interruptions quickly
cleanup() {
    local cert_path=$1

    echo "Script interrupted. Performing cleanup..."
    echo ""
    sleep 0.5

    # Check if any backup of config exists
    local backup_file=$(ls /etc/nginx/sites-available/*.conf.bak-* 2>/dev/null | sort -r | head -n 1)

    if [ -n "$backup_file" ]; then
        echo "Backup file found at $backup_file."
        echo "Restoring the backup..."
        local conf_file="${backup_file%.bak-*}"
        sudo cp "$backup_file" "$conf_file"
        if [ $? -eq 0 ]; then
            echo "Configuration file restored from backup."
        else
            echo "Error: Couldn't restore configuration file from backup."
        fi
    else
        echo "No backup file found. Proceeding with cleanup..."
    fi

    # Remove the generated certificates if they exist
    if [ -d "$cert_path" ]; then
        echo "Removing generated certificate files from $cert_path..."
        rm -rf "$cert_path"
        if [ $? -eq 0 ]; then
            echo "Certificate files removed successfully."
        else
            echo "Error: Couldn't remove certificate files."
        fi
    fi

    echo "Cleanup completed."
    echo ""
    exit 1
}

# Set up a trap to catch interruptions and call the wrapper
cleanup_wrapper() {
    cleanup "$cert_path"
}
trap cleanup_wrapper SIGINT SIGTERM

# Function to generate a self-signed SSL certificate
generate_certificate() {
    local domain_name=$1
    local cert_path=$2
    local days=$3

    echo "Checking for existing SSL certificate files at $cert_path..."
    echo ""
    sleep 0.5
    
    if [ -f "$cert_path/$domain_name.crt" ] || [ -f "$cert_path/$domain_name.key" ]; then
        echo "Existing SSL certificate files found:"
        echo "- $cert_path/$domain_name.crt"
        echo "- $cert_path/$domain_name.key"
        echo ""
        
        echo "Do you want to overwrite these files? (y/n):"
        read -e -r overwrite_answer
        echo ""

        overwrite_answer_lower=$(echo "$overwrite_answer" | tr '[:upper:]' '[:lower:]')

        if [[ "$overwrite_answer_lower" == "y" ]]; then
            echo "Overwriting existing certificate files..."
            echo ""
            sleep 0.5
        elif [[ "$overwrite_answer_lower" == "n" ]]; then
            echo "Aborting certificate generation. Please manually handle the existing files or choose a different path."
            exit 1
        else
            echo "Invalid input: Please enter 'y' for yes or 'n' for no."
            exit 1
        fi
    fi

    echo "Generating private key for $domain_name..."
    openssl genrsa -out "$cert_path/$domain_name.key" 2048
    if [ $? -ne 0 ]; then
        echo "Error while generating private key. Exiting."
        rollback "$cert_path"
        exit 1
    fi
    sleep 0.5

    echo "Generating self-signed SSL certificate for $domain_name with $days days validity..."
    openssl req -new -x509 -nodes -days $days -key "$cert_path/$domain_name.key" -out "$cert_path/$domain_name.crt" -subj "/CN=$domain_name"
    if [ $? -ne 0 ]; then
        echo "Error while generating certificate. Exiting."
        rollback "$cert_path"
        exit 1
    fi
    sleep 0.5

    echo "SSL certificate generated and saved to $cert_path."
    echo ""
    sleep 0.5
}

# Function to create a domain-specific Nginx configuration file
create_nginx_conf() {
    local domain_name=$1
    local cert_path=$2
    local ssl_redirect=$3
    local forward_ip=$4
    local forward_port=$5

    local conf_file="/etc/nginx/sites-available/${domain_name}.conf"
    local symlink="/etc/nginx/sites-enabled/${domain_name}.conf"

    # Check if the configuration file already exists
    if [ -f "$conf_file" ]; then
        echo "A configuration file for $domain_name already exists."
        echo "Warning: If you choose not to create a backup, the existing file will be overwritten."
        echo "Would you like to create a backup before overwriting it? (y/n):"
        read -e -r overwrite_answer
        echo ""

        overwrite_answer_lower=$(echo "$overwrite_answer" | tr '[:upper:]' '[:lower:]')

        if [[ "$overwrite_answer_lower" == "y" ]]; then
            local backup_file="${conf_file}-backup-$(date +%F_%T)"
            sudo cp "$conf_file" "$backup_file"
            if [ $? -eq 0 ]; then
                echo "Backup created at $backup_file."
                echo ""
            else
                echo "Failed to create backup. Please check your permissions."
                rollback "$cert_path"
                exit 1
            fi
        elif [[ "$overwrite_answer_lower" == "n" ]]; then
            echo "Proceeding without backup. The existing file will be overwritten."
            echo ""
        else
            echo "Invalid input: Please enter 'y' for yes or 'n' for no."
            exit 1
        fi
    fi
    sleep 0.5

    echo "Creating Nginx configuration file for $domain_name..."
    echo ""
    sleep 0.5

    # Construct the configuration file content
    local config_content="server {
    listen 80;
    listen [::]:80;
    server_name $domain_name;"

    if [ "$ssl_redirect" = true ]; then
        config_content+="

    location / {
        return 301 https://\$host\$request_uri;
    }"
    else
        config_content+="

    location / {
    proxy_pass http://$forward_ip:$forward_port;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    }"
    fi

    config_content+="
}

server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name $domain_name;

    ssl_certificate $cert_path/$domain_name.crt;
    ssl_certificate_key $cert_path/$domain_name.key;

    location / {
        proxy_pass http://$forward_ip:$forward_port;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
"

    # Create the Nginx configuration file in /etc/nginx/sites-available/
    echo "$config_content" | sudo tee "$conf_file" > /dev/null

    if [ $? -ne 0 ]; then
        echo "Failed to create Nginx configuration file at $conf_file. Please ensure you have the necessary permissions and try again."
        rollback "$cert_path"
        exit 1
    fi

    echo "Nginx configuration file created at $conf_file"
    echo ""
    sleep 0.5

    # Check if symbolic link already exists and remove it if necessary
    if [ -L "$symlink" ]; then
        echo "Symbolic link $symlink already exists. Removing old link..."
        sudo rm "$symlink"
        if [ $? -ne 0 ]; then
            echo "Unable to remove the existing symbolic link at $symlink. Please check permissions and ensure no other processes are using the file."
            rollback "$cert_path"
            exit 1
        fi
    fi
    sleep 0.5

    # Create a symbolic link in /etc/nginx/sites-enabled/
    echo "Creating symbolic link for the Nginx configuration..."
    sudo ln -sfn "$conf_file" "$symlink"
    if [ $? -ne 0 ]; then
        echo "Failed to create symbolic link in /etc/nginx/sites-enabled/. Verify that you have the necessary permissions and that the directory is writable."
        rollback "$cert_path"
        exit 1
    fi

    echo "Configuration linked to /etc/nginx/sites-enabled/"
    echo ""
    sleep 0.5

    echo "Nginx configuration file content:"
    echo ""
    cat "$conf_file"
    sleep 0.5

    echo "Restarting Nginx to apply the new configuration..."
    sudo systemctl restart nginx
    if [ $? -eq 0 ]; then
        echo "Nginx restarted successfully."
        echo ""
    else
        echo "Unable to restart Nginx. Please check the configuration and restart Nginx manually using sudo systemctl restart nginx to apply the changes."
        exit 1
    fi
    sleep 0.5
}

# Function to test the forwarded port
test_port_forward() {
    local ip_address=$1
    local port=$2
    local timeout_duration=5

    echo "Testing the connection to $ip_address:$port..."
    sleep 0.5

    # Perform the HTTP request with a timeout
    response=$(curl --write-out "%{http_code}" --silent --output /dev/null --connect-timeout $timeout_duration http://$ip_address:$port)

    # Handle different HTTP response codes
    case $response in
        200)
            echo "Success: The service at $ip_address:$port is reachable and functioning."
            ;;
        404)
            echo "Error: The service at $ip_address:$port could not be found (404 Not Found)."
            ;;
        500)
            echo "Error: The service at $ip_address:$port encountered an internal error (500 Internal Server Error)."
            ;;
        000)
            echo "Error: The request to $ip_address:$port timed out or the service is unreachable."
            ;;
        *)
            echo "Notice: Received HTTP status code $response from the service at $ip_address:$port."
            ;;
    esac

    sleep 0.5
}


# Main script

check_tools

echo "Enter the domain name for the SSL certificate:"
read -e -r domain_name
echo ""
validate_domain_name "$domain_name"
sleep 0.2

echo "Enter the absolute path to save the certificate files:"
read -e -r cert_path
echo ""
validate_cert_path "$cert_path"
sleep 0.2

echo "Enter the number of days until the certificate expires (between 1 and 365):"
read -e -r expiration_days
echo ""
if [[ ! "$expiration_days" =~ ^[0-9]+$ ]]; then
    echo "Invalid input: Expiration days must be a number."
    exit 1
elif [[ "$expiration_days" -lt 1 || "$expiration_days" -gt 365 ]]; then
    echo "Invalid input: Expiration days must be between 1 and 365."
    exit 1
fi
sleep 0.2

# Generate certificate.
generate_certificate "$domain_name" "$cert_path" "$expiration_days"
sleep 0.2

echo "Enter the IP address to forward traffic to:"
read -e -r forward_ip
echo ""
if [[ ! "$forward_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid IP address format. Please enter a valid IP address."
    exit 1
fi
sleep 0.2

echo "Enter the port to forward traffic to:"
read -e -r forward_port
echo ""
if [[ ! "$forward_port" =~ ^[0-9]+$ ]] || [[ "$forward_port" -lt 1 || "$forward_port" -gt 65535 ]]; then
    echo "Invalid port number. Please enter a number between 1 and 65535."
    exit 1
fi
sleep 0.2

echo "Do you want to enable a 301 redirect from HTTP to HTTPS? (y/n):"
read -e -r ssl_redirect_answer
echo ""

ssl_redirect_answer_lower=$(echo "$ssl_redirect_answer" | tr '[:upper:]' '[:lower:]')

if [[ "$ssl_redirect_answer_lower" == "y" ]]; then
  ssl_redirect=true
elif [[ "$ssl_redirect_answer_lower" == "n" ]]; then
  ssl_redirect=false
else
  echo "Invalid input: Please enter 'y' for yes or 'n' for no."
  exit 1
fi
sleep 0.2

# Create Nginx config
create_nginx_conf "$domain_name" "$cert_path" "$ssl_redirect" "$forward_ip" "$forward_port"
sleep 0.2

echo "Would you like to test the connection to the IP address and port you configured? (y/n):"
read -e -r test_ip_port_answer
echo ""

test_ip_port_answer_lower=$(echo "$test_ip_port_answer" | tr '[:upper:]' '[:lower:]')

if [[ "$test_ip_port_answer_lower" == "y" ]]; then
    # Test the forwarded ip and port
    test_port_forward "$forward_ip" "$forward_port"
elif [[ "$test_ip_port_answer_lower" == "n" ]]; then
    echo "IP and port testing skipped. The configuration has been applied."
else
    echo "Invalid input: Please enter 'y' for yes or 'n' for no."
    exit 1
fi
sleep 0.2

echo ""
echo "Script completed. The SSL certificate and Nginx configuration have been set up."
sleep 2