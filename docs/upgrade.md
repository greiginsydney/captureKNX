# Upgrade/update captureKNX

The setup test script will confirm your version of captureKNX, and what the latest public release is.

If there's a discrepancy (and you like the look of the improvements on offer on the Releases page), please consider upgrading.

The upgrade process is a cut-down version of the setup process in [step3-setup-the-Pi](/docs/step3-setup-the-Pi.md).

1. SSH to the Pi and login.
2. It's always a good idea to ensure the Pi is up-to-date:
    ```text
   sudo apt-get update && sudo apt-get upgrade -y
   ```

3. Download the latest version of captureKNX from GitHub:
   ```text
   cd ~ && sudo rm -rfd staging
   ```
   ```text
   git clone --depth=1 https://github.com/greiginsydney/captureKNX staging/captureKNX
   ```
4. Now we need to move the setup.sh script file into its correct location:
   ```text
   mv -fv "staging/captureKNX/Raspberry Pi/setup.sh" ~
   ```
5. The script needs to be made executable first:
   ```text
   sudo chmod +x setup.sh
   ```

6. Now run it!
   ```
   sudo ./setup.sh
   ```

7. That's it. 
