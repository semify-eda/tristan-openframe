# Tristan Openframe

 The ASIC design for the Tristan project based on openframe. It uses the `cv32e40x` RISC-V core and RAM blocks from OpenRAM.

## Setup

Make sure to clone the repository recursively:

	git submodule update --init --recursive

To install all necessary repositories, install the PDK and download the docker images, run:

	make setup

# Hardening Process

First, harden the SoC:

	make sky130_top

Next, harden the wrapper:

	make openframe_project_wrapper

## openlane

An interactive script is used to harden the `openframe_project_wrapper` in order to do a custom step to copy the power pins from the template def.

# Precheck

To install the precheck, run:

	make precheck

To start the precheck, run:

	make run-precheck

* TODO: needs to be tested