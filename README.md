# Welcome to the Nginx SSL Setup Script!

This script will help you generate a self-signed SSL certificate and configure Nginx with it.

You will be prompted to enter your domain name, the path to save the certificate files, the expiration period for the certificate, and whether you want 301 redirection or not.

**Note:** Self-signed certificates are useful for development and testing but are not trusted by browsers in production environments. For production use, consider using a certificate from a recognized certificate authority like Let's Encrypt.

**Note:** Ensure that port 443 is open on your firewall for HTTPS traffic.

Let's get started!

## Table of Contents

1. [Requirements](#requirements)
2. [Script Features](#script-features)
3. [Rollback and Cleanup](#rollback-and-cleanup)
4. [Usage](#usage)
5. [Disclaimer](#disclaimer)
6. [Troubleshooting](#troubleshooting)
7. [License](#license)
8. [Contributing](#contributing)
9. [Contact](#contact)

## Requirements

Before running the script, make sure you have the following tools installed on your system:

- **Nginx**: The web server for which you are configuring SSL.
- **OpenSSL**: A toolkit for SSL/TLS that is required for generating SSL certificates.
- **Curl**: A command-line tool for transferring data with URLs. Used for testing the forwarded port in this script.

You can install these tools using your package manager. For example, on Debian-based systems, you can use:

```bash
sudo apt-get update
sudo apt-get install nginx openssl curl
```

## Script Features

- **Check for Required Tools**: Ensures that Nginx, OpenSSL, and Curl are installed and exits if any are missing.
- **Path Validation**: Validates and creates the directory where the certificate files will be saved.
- **Domain Name Validation**: Ensures the domain name entered is in a valid format.
- **Certificate Generation**: Creates a self-signed SSL certificate and private key using OpenSSL.
- **Nginx Configuration**: Configures a Nginx server block and sets up the server block to:
   - Listen on ports 80 (HTTP) and 443 (HTTPS).
   - Proxy traffic to the specified IP address and port.
   - Optionally perform a 301 redirect from HTTP to HTTPS.
   - Restarts Nginx to apply the new configuration.

- **Port Forwarding Testing(Optional)**: Performs a basic test using curl to verify the connection to the configured IP and port.

## Rollback and Cleanup

The script includes a rollback functionality in case of errors during certificate generation or Nginx configuration. It will attempt to:
   - Restore a backup of the original Nginx configuration file (if one was created).
   - Remove the generated certificate files.

## Usage

1. **Clone the Repository**:
```bash
git clone https://github.com/CagatayKahramann/ssl-setup-script.git
cd ssl-setup-script
```
2. **Make the Script Executable**:
```bash
git clone https://github.com/CagatayKahramann/ssl-setup-script.git
cd ssl-setup-script
```
3. **Execute the Script**:
```bash
git clone https://github.com/CagatayKahramann/ssl-setup-script.git
./ssl-setup.sh
```
4. **Follow the On-screen Prompts**: 
The script will guide you through the following steps and will need you to enter the necessary information:
   - Domain name for the SSL certificate.
   - Path to save the certificate files (create the directory if it doesn't exist)
   - Number of days for the certificate expiration (between 1 and 365)
   - IP address to forward traffic to.
   - Port number to forward traffic to.
   - (Optional) Enable a 301 redirect from HTTP to HTTPS.
   - (Optional) Test the connection to the configured IP address and port.

## Disclaimer

This script is provided for educational purposes only. While it automates the process of setting up a self-signed SSL certificate and Nginx configuration, it's important to understand the security implications of using self-signed certificates. For production environments, consider using a trusted certificate authority like Let's Encrypt.

## Troubleshooting

1. **Nginx Not Installed**:
   - **Issue**: The script cannot proceed if Nginx is not installed or not accessible.
   - **Solution**: Ensure Nginx is properly installed and running. You can check its status with:
     ```bash
     sudo systemctl status nginx
     ```
     To install Nginx, use:
     ```bash
     sudo apt-get install nginx
     ```
     If you encounter issues, refer to the [Nginx documentation](https://nginx.org/en/docs/) for more information.

2. **Permission Issues**:
   - **Issue**: The script may fail if you do not have the necessary permissions to create directories or write files.
   - **Solution**: Check and adjust permissions as needed. Ensure you are running the script with appropriate privileges. Use `sudo` if required:
     ```bash
     sudo ./your-script.sh
     ```
     Make sure the directory where you are saving the certificate files is writable. You can change permissions with:
     ```bash
     sudo chmod -R 755 /path/to/directory
     ```
     For directories, ensure they exist and are correctly owned:
     ```bash
     sudo chown $USER:$USER /path/to/directory
     ```

3. **SSL Certificate Generation Issues**:
   - **Issue**: Errors during SSL certificate generation can occur due to incorrect parameters or permissions.
   - **Solution**: Verify that you have specified the correct certificate path and expiration days. Ensure that OpenSSL is installed and properly configured. Test OpenSSL with:
     ```bash
     openssl version
     ```
     For detailed debugging, refer to the [OpenSSL documentation](https://www.openssl.org/docs/).

4. **Nginx Configuration Errors**:
   - **Issue**: Problems with the Nginx configuration can cause the server to fail to start or reload.
   - **Solution**: Check the Nginx configuration syntax with:
     ```bash
     sudo nginx -t
     ```
     Review the Nginx logs for any errors:
     ```bash
     sudo tail -f /var/log/nginx/error.log
     ```
     Ensure that the configuration file created by the script follows the correct syntax and includes all required directives.

5. **Port Forwarding Issues**:
   - **Issue**: Traffic may not be forwarded correctly if there are errors in the IP address or port configuration.
   - **Solution**: Verify that the specified IP address and port are correct and reachable. Test connectivity with tools like `curl` or `telnet`:
     ```bash
     curl http://<IP_ADDRESS>:<PORT>
     ```
     Check for firewall rules or network issues that might block the traffic.

6. **301 Redirect Not Working**:
   - **Issue**: The HTTP to HTTPS redirect might not function as expected.
   - **Solution**: Ensure that the redirect rule in the Nginx configuration is correctly implemented. Verify that the configuration reloads properly:
     ```bash
     sudo systemctl reload nginx
     ```
     Review the browser's network traffic to confirm that the redirect is occurring.

## License

This script is provided under the GNU General Public License v3.0. See the [LICENSE](./LICENSE) file for more details.

## Contributing

Contributions to this script are greatly appreciated! If you have suggestions, improvements, or bug fixes, please feel free to fork the repository and submit a pull request.

Please ensure your pull request adheres to the following guidelines:
- **Code Quality:** Ensure your code is well-tested and adheres to the project's coding standards.
- **Documentation:** Update the documentation if your changes affect the usage or functionality of the script.
- **Clear Description:** Provide a clear description of what your pull request does and why it is needed.

Thank you for your contribution!

## Contact

For any questions or support, please contact cagatay.kahraman@hotmail.com.
