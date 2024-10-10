# Upgrade/update the knxLogger

The setup test script will confirm your version of knxLogger, and what the latest public release is.

If there's a discrepancy (and you like the look of the improvements on offer on the Releases page), please consider upgrading.

The upgrade process is a cut-down version of the setup process in [step3-setup-the-pi](/docs/step3-setup-the-Pi.md).

1. SSH to the Pi and login.
2. It's always a good idea to ensure the Pi is up-to-date:
    ```text
   sudo apt-get update && sudo apt-get upgrade -y
   ```

3. Download the latest version of knxLogger from GitHub:
   ```text
   cd ~ && sudo rm -rfd staging
   ```
   ```text
   git clone --depth=1 https://github.com/greiginsydney/knxLogger staging/knxLogger
   ```
4. Now we need to move the setup.sh script file into its correct location:
   ```text
   mv -fv "staging/knxLogger/Raspberry Pi/setup.sh" ~
   ```
5. The script needs to be made executable first:
   ```text
   sudo chmod +x setup.sh
   ```

6. Now run it! (Be careful here: the switches are critical. "-E" ensures your user path is passed to the script. Without it the software will be moved to the wrong location, or not at all. "-H" passes the Pi user's home directory.)
   ```
   sudo -E -H ./setup.sh
   ```

7. That's it. 
