# dqxdump

Dumps game files from memory for use with the [dqxclarity](https://github.com/jmctune/dqxclarity) project.

# Requirements

- Latest version of Autohotkey 1.x installed

# How to use

- Open the game and get to the main screen where you are prompted to select an adventure slot
- Run `scan.ahk`
- Wait several minutes for the dump process to finish
- Finished dumps will show up in `completed/`
  - Known dumps that are defined in `master/hex_dict.csv` will show up in `completed/known/`
  - Unknown/new dumps that aren't defined will show up in `completed/unknown/`
  - Unknown/new dump INDX AOBs are saved to `add_to_master.csv` for further analysis on whether or not you want to use these and add them to master