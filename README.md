# OpenLane Guide for SoCET Intro II Students

This repository your starting point to learn how to use OpenLane for SoCET Intro II. The structure and contents of this repository facilitate the use of OpenLane 2 to harden a design. An overview of OpenLane, instructions on how to harden a design, and important Makefile targets are covered in this guide.

## OpenLane Overview
OpenLane is a powerful and versatile library that enables the implementation of digital ASIC designs using open-source and commercial EDA tools. OpenLane abstracts how each tool works by allowing the user to configure them. Once you’ve installed OpenLane, running a digital design through the flow requires the following:

- Verified RTL code (i.e., the Verilog/SystemVerilog of your design)
- The flow configuration file (`config.json`)
- A process design kit (PDK) – For us, SkyWater's open-source [Sky130A](https://www.skywatertechnology.com/sky130-open-source-pdk/) PDK

The `config.json` file provides all the variables to set the flow; if it doesn’t specify a value for a certain variable, the flow will use default values. The default PDK is the **SkyWater/Google 130nm** PDK, but any other PDKs can be specified in the `config.json`. The sky130 PDK automatically downloads when you run the flow for the first time. In the configuration file you can specify the HDL code of your design (in Verilog/SystemVerilog), the clock port, and the desired clock period. More information on OpenLane for beginners can be found [here](https://openlane2.readthedocs.io/en/latest/getting_started/newcomers/index.html).

## Instructions to Create Your Repository
1. Towards the top right of this repo's main page, click on the green "Use this template" button.

3. From there, click "Create anew repository"
   
5. Under your repository name, format it as ```{intro2_<season><year>_team<team_number>_tt}```. For example, for Spring 2026 team 1, the name should be ```intro2_S2026_team01_tt```
   
7. Under the description, add a description of your project in 1-2 sentences.
   
9. Leave everything else as default and click "Create repository"

## Instructions for Cloning to nanoHUB
1. Log into [nanoHUB](https://nanohub.org/) and find your "dashboard" page.
   
3. Under the "MY TOOLS" section, click on "All Tools" and search for "OpenLane 2".
   
5. Once you've clicked on the tool, you should see a "launch tool button". Click on it and wait for the tool to launch (it *can* take several minutes, so be patient)
   
7. If the tool loaded correctly, you should be able to see three windows - one called toolsession-XXXX, an Import/Export window, and an OpenLane window. Click on the toolsession window.
   
9. To clone anything from GitHub, you must first generate an SSH key and pair it to your account. To do this, type `ssh-keygen -t rsa -b 4096 -C "<your GitHub email here>"` into the terminal. Your public key can now be found in `~/.ssh/id_rsa.pub`.
    
11. To copy your public key (ctrl+C/V doesn't work on nanoHUB!), go to the Import/Export window, select Download, and in the file name, type `~/.ssh/id_rsa.pub`. Select "Open". On the window that pops up, select the text that appears and copy it with Ctrl+C.
    
13. In your GitHub account settings (click on your profile photo then settings), under the Access section, click "SSH and GPG keys". Click New SSH key and paste your key under the "Key" section. Title your key something descriptive like "SoCET nanoHUB key". Once you click "Add SSH Key", you should be able to clone any GitHub repo into nanoHUB. To clone this repo, click on the green "<> Code" button and coppy the SSH key.
    
15. To paste this into nanohub, first type `cd ~/` then `importfile paste.txt` into your toolsession terminal. Once the window pops up, select "Copy/paste text" and paste the SSH repo address in the text box. Click upload. Then, type `git clone $(cat paste.txt)` to clone this repo.
    
17. As a final note, whenever running makefile commands in nanoHUB, you must use the "OpenLane" window. Because nanoHub runs tools in a shell, you must modify line 16 of the `Makefile` to `NIX_MODE := in-shell` when running your design through the flow on nanoHUB.

## Instructions for Setting Up Tools Locally
The best package to install and use is [OSS Cad Suite](https://github.com/YosysHQ/oss-cad-suite-build/releases). These steps will walk through how to install and set up.

1. In your WSL root directory `cd ~/`, Install the compressed tar file with `curl -L -O https://github.com/YosysHQ/oss-cad-suite-build/releases/download/<version release date>/oss-cad-suite-linux-x64-<version number>.tgz`. The most recent version can be found at the link above.

2. Next, uncompress it with `tar xzf ./oss-cad-suite-linux-x64-<version number>.tgz`.

3. Add the OSS Cad Suite path to your bashrc with `echo 'export PATH="~/oss-cad-suite/bin:$PATH"' >> ~/.bashrc`

4. Re-run your bashrc with `source ~/.bashrc`.

5. Test that the tools exist by typing `verilator --version`. If a version number shows up, you're good to go!

## Important Constraints (no exceptions)
1. Area. Each tapeout slot is 160 by 100um. The config json has constrained this by default.
   
3. IO count. Each slot is allowed 8 inputs, 8 outputs, and 8 bidirectional IOs excluding clock and reset. These ports are listed in the `project.v` file in the `source` directory.
   
5. Documentation. Please fill each section out in detail in `docs/info.md`. This is absolutely required for your design to be taped out. Keep in mind you will be following this documentation once you get your chip back to validate it.

6. If you believe there will be an issue with any of these areas, please raise your concerns with your GTA.

## Instructions for RTL Development

- In your project directory, run `make setup_<design name>`, where design name is the name you would like your top-level to be called. This command will format the entire repo for your newly created design. What's relevent for RTL development is the newly created `verilog/dv/<design name>` and `verilog/rtl/<design name>` directories. The former will be used for your RTL code while the latter will be used for your testbench code.

- During this stage of your development, `verilog/dv/<design name>/top.sv` will be your top-level module, or the file where you will instantiate and connect any submodules. A submodule template is provided within the same directory called `src1.sv`. Copy this template for any submodules and feel free to give them relevent and descriptive names. Just make sure to follow the required naming conventions given my `make help`. DO NOT MODIFY `project.v` at this stage of your design.

- The most important part of this stage is verification, which is included in the `verilog/dv/<design name>` directory. After running the setup command, 3 sample testbenches will be generated which already follow the required Makefile naming standards. Similarly to the rtl directory, feel free to name submodules as relevent.

- The first stage of verification once your RTL is completed is "source" level verification, or running the testbench simulation directly from your verilog source code. To do this, run `make sim_<module name>_src`. This command will run your simulation and automatically open your waveforms in GTKWave.

- To view your waveforms, you must navigate to the design heirarchy window, click on which module you want to add waves from, and then select the waves you want that appear below. Make sure to zoom out so you can see your entire testbench. To save your GTKWave window format, press the three bars -> save format. Add `support/waves/<project name>/<module name>.gtkw` as the path to save as.

- Once your source-level has been verified, use `make sim<module name>_syn` to run your same testbench on your synthesized design instead. Make sure your DUT (Design Under Test) still behaves as expected.

## Instructions for FPGA Testing / Development

- Once you've verified your modules with source and synth level testing, it's time to test your design on real hardware! The only practical way to do this without a full tapeout is with a special device called an FPGA or "Field Programable Gate Array". This device can be configured to physically behave as any digital circuit we want.

- Inside the `fpga` directory, navigate to `<project name>/fpga_top.sv`. This file will act as a "wrapper" for your `top.sv` module and allow you to connect your module's ports to FPGA pins. With the help of a TA, wire up your top-level module to the FPGA wrapper.

- Now that everything is wired up, run `make cram` with an FPGA connected to flash your design onto your FPGA. Keep in mind there's actually more happening here, so if you're interested, look into how the FPGA design flow works specifically. Anyways, as long as you don't get any errors and your FPGA is connected correctly, your design should be on your FPGA!

- If you have any peripherals (which you all will), wire them up to the FPGA with jumper wires and a breadboard to verify your chip's integration with the rest of your design. Use `make help` to see the other FPGA-related targets not mentioned here.

## Connecting to the FPGA on Windows
We'll use a tool called USBIPD to forward USB devices to WSL. Follow [this guide](https://learn.microsoft.com/en-us/windows/wsl/connect-usb) to install it and make yourself familiar with the tool.
- Use USBIPD list both with the FPGA plugged in and unplugged. Whichever was there only when plugged in is the FPGA's serial converter.
- Bind it to WSL following the instructions above.

## Instructions to Harden a Design

1. If you're running this flow locally, Install OpenLane 2. Follow instructions on the [Nix-based Installation](https://openlane2.readthedocs.io/en/latest/getting_started/common/nix_installation/index.html). If you have Windows, use WSL (the OpenLane installation guide tells you how to setup WSL). Update the `OPENLANE2_ROOT` variable in the Makefile if your `openlane2` root is not in your home directory.

2. The sky130 PDK is built and cached using **Volare**, which is also installed when you install OpenLane. By default, Volare keeps the downloaded PDKs in the `.volare` folder in your home directory, unless you specify otherwise. If you wish to modify your PDK path (i.e., the location of sky130 PDK files), just modify variable `VOLARE_ROOT`. If not, continue to the next step.

3. When you ran `make setup_<design name>` before, it also created a `config.json` inside of the `openlane` directory and your project's top-level module + TinyTapeout verilog wrapper. The `config.json` is the file that will configure the flow and is set up by default to may your design to your allocated area. If you're curious what some of these variables do, the [OpenLane 2 website](https://openlane2.readthedocs.io/en/latest/) is a great resource!

4. Now, you are now ready to harden (i.e., create the physical layout) your design. Run `make <design name>` to harden your design. For example, if the top-level design name is `sample_proj`, then run `make sample_proj`. Make sure this design name matches the name of the folder that was added in the `openlane` directory. Try running some of the example designs before running yours to get an idea of how the flow works what to expect in the terminal output. You'll most likely get errors during synthesis, which are related to errors in your RTL code, so carefully read the reported errors in the terminal and log file to debug these.

5. For the design to harden successfully, there must be no DRC violations, no LVS violations, and minimal antenna violations. If you ever get any of these violations, reference the OpenLane docs to fix them. Ask a TA for helo if you're stuck.

## Reading Log Files (debugging, area, critical path, etc)
If your design failes to make it through the entire OpenLane flow, the only (and best) way to debug what may have went wrong is to look at your log files. These can always be found under `openlane/<design name>/runs/YY_MM_DD_TIME`. Your latest run should always appear at the bottom, but to double check, make sure the time and date ligns up with what you expectet. Inside this directory is a separate directory for every one of the ~75 flow stages - each with log files, reports, or other files. Whichever step the flow failed at corresponds to the last stage that you see in that particular run directory.

Once your design has been hardened, reading and understanding the run's log files is one of the most important aspects to characterizing your design's performance. The two key characteristics Intro II will focus on in this flow are 1) your area, and 2) your timing. These two metrics are a direct indicator if your design will fail. 

1. To find area, look near step 30 for a stage named `openroad-detailedplacement`. In a nutshell, this stage is where all parts of your design will be placed exactly on the die before routing, and at this point, OpenLane knows exactly how much area will be dedicated to each kind of cell and your design overall. Look for a table in the `openroad-detailedplacement.log` titled "Cell type report". Each cell type will have a count and an area in um^2, and your total area and cell count will be visible at the bottom.
   
3. To find your design's timing results, look for ~step 55 called `openroad-stapostpnr`. This stage performs a very important analysis of your design called Static Timing Analysys, or STA for short. All timing information will be located in `summary.rpt` like hold, setup, and total slack. If all numbers are positive in this table, your design has met timing. Otherwise, look into why it may be failing.

## Other Makefile Targets

- `make gdsview_%_klayout` - This command will open a view of the GDS file (i.e., the complete physical layout of your design) in KLayout. Replace `%` with the name of your design. If your design name is `sample_proj`, then you can open the GDS file by running `make gdsview_sample_proj_klayout`.

- `make clean_openlane` - This command will remove the `runs` directory from all the folders in the `openlane` directory. This folder gets created and stores all the log files and temporary design outputs through every step of the flow for each run.

- More Makefile targets comming soon!
