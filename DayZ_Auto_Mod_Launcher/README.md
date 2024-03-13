**DayZ Auto-Mod Launcher for Linux**
##

Author of the original code: DAYZ Linux CLI LAUNCHER by Bastimeyer https://github.com/bastimeyer/dayz-linux-cli-launcher

Rewritten and modded by: ice_hotf

Tested with Debian 11 and 12.

Tested with the official steam package: https://wiki.debian.org/Steam
##

**Modded scripts to based on Bastimeyer's DAYZ Linux CLI LAUNCHER.**
##
This script will automatically identify missing mods, download them and launch DayZ with the mods.

Just follow the instructions in the terminal window.

This script can launch modded servers and vanilla servers.
##
##
  **How To**:
##
- Add both scripts to your 'home' folder.
- Run 'sh Start_DayZ_Auto_Mod.sh' in the terminal, type in IP:Port & Query Port and username. 
- Wait for mods to download and click enter.
- DayZ launches with mods.
- The script will provide a direct link to the server after you connect to the server.
- Example:
- steam -applaunch 221100 "-mod=@BLDvXA;@VMT7bA" -connect=71.27.252.186:2322 --port 2323 -name=ice -nolauncher -world=empty
- Use this command for direct connect to server by saving it to aliases, script, .desktop-file or by running it in the terminal.
##
##
##
**Video:**
https://www.youtube.com/watch?v=ARHKGg2aMXo
##
##
**Screenshots:**
##
##
**When Mods are Missing:**
##
##
![Screenshot from 2024-03-11 01-13-39](https://github.com/ice-HoTF/DayZ_Auto_Mod_Launcher/assets/162713879/63fe82ec-aeb0-4d25-b8a1-8c8f215c3634)
![Screenshot from 2024-03-11 01-14-26](https://github.com/ice-HoTF/DayZ_Auto_Mod_Launcher/assets/162713879/981d1859-208c-4b1f-a7ab-eaf528ddceec)
##
##
**When Mods are already installed:**
##
##
![Screenshot from 2024-03-11 01-15-51](https://github.com/ice-HoTF/DayZ_Auto_Mod_Launcher/assets/162713879/fe23aaf5-a1b8-4f74-a0f2-3a4ca93bd77a)
##
##
**When joining Vanilla server:**
##
##
![Screenshot from 2024-03-11 01-21-14](https://github.com/ice-HoTF/DayZ_Auto_Mod_Launcher/assets/162713879/bfe2a703-b0db-4ef7-a7e9-7404f27e5dd8)
##
##
##
**FAQ:**
##
If anything fails you should be able to solve it by one of these actions: 
##
- Usubscribe from the mods from steam workshop and run the script againg. 
- Delete the mods from /home/$USER/.steam/debian-installation/steamapps/common/DayZ. The mods looks like this example: A text file called "1828439124".
- Delete the mods from /home/$USER/.steam/debian-installation/steamapps/workshop/content/221100. The mods looks like this example: A folder called "1828439124".
- Run the script again after completing step 1, 2 and 3.
